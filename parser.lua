local lpeg = require("lpeg")

local M = {}

local P, C, Ct, Cg, Cp, V, S = lpeg.P, lpeg.C, lpeg.Ct, lpeg.Cg, lpeg.Cp, lpeg.V, lpeg.S

local function add_positions(pattern)
	return Cp()
		* pattern
		* Cp()
		/ function(start_pos, node, end_pos)
			node.range = { start_pos, end_pos - 1 }
			return node
		end
end

local function generate_command_table(command_name, named_parameters, positional_parameters)
	return { command = command_name, named_parameters = named_parameters, positional_parameters = positional_parameters }
end

local RULES = (function()
	local _ = {}

	setmetatable(_, {
		__index = function(t, key)
			return V(key)
		end,
	})

	_.WHITESPACE = S(" \t\n\r")
	_.BACK_SLASH = P("\\")
	_.L_BRACE = P("{")
	_.R_BRACE = P("}")
	_.L_BRACKET = P("[")
	_.R_BRACKET = P("]")
	_.PIPE = P("|")
	_.PRESERVED = _.L_BRACE + _.R_BRACE + _.BACK_SLASH + _.L_BRACKET + _.R_BRACKET + _.PIPE

	_.Command = add_positions(_.UserCommand + _.BracedBlock + _.Text)

	_.Text = Ct(C((1 - _.PRESERVED) ^ 1)) / function(s)
		return generate_command_table("__TEXT__", nil, s)
	end

	_.UserCommand = Ct(
		_.BACK_SLASH
			* Cg(_.CommandName, "name")
			* Cg(Ct(_.NamedParameter ^ 0), "named_parameters")
			* Cg(Ct((_.WHITESPACE ^ 0 * _.BracedBlock) ^ 0), "positional_parameters")
	) / function(contents)
		return generate_command_table(contents.name, contents.named_parameters, contents.positional_parameters)
	end

	_.CommandName = C((1 - (_.WHITESPACE + _.PRESERVED)) ^ 1)

	_.NamedParameterKeyValue = add_positions(
		Ct(
			_.WHITESPACE ^ 0
				* _.L_BRACKET
				* _.WHITESPACE ^ 0
				* Cg(_.Command + _.WHITESPACE ^ 0 / function()
					return ""
				end, "key")
				* _.WHITESPACE ^ 0
				* _.PIPE
				* _.WHITESPACE ^ 0
				* Cg(_.Command + _.WHITESPACE ^ 0, "value")
				* _.WHITESPACE ^ 0
				* _.R_BRACKET
		)
	)

	_.NamedParameterFlag = add_positions(
		Ct(_.WHITESPACE ^ 0 * _.L_BRACKET * _.WHITESPACE ^ 0 * Cg(_.Command, "key") * _.WHITESPACE ^ 0 * _.R_BRACKET)
	)

	_.NamedParameter = add_positions(_.NamedParameterKeyValue + _.NamedParameterFlag / function(named_param)
		if named_param.key and named_param.value then
			return { key = named_param.key, value = named_param.value }
		elseif named_param.key then
			return { key = named_param.key, value = true }
		else
			return nil
		end
	end)

	_.BracedBlock = Ct(_.L_BRACE * _.Block * _.R_BRACE)
		/ function(contents)
			return generate_command_table("__BLOCK__", nil, contents)
		end

	_.Block = _.Command ^ 0

	_[1] = Ct(_.Block) / function(contents)
		return generate_command_table("__BLOCK__", nil, contents)
	end

	return _
end)()

local grammar = P(RULES)

local function simplify(node)
	if type(node) ~= "table" then
		return node
	end

	if node.command == "__TEXT__" then
		local first_param = node.positional_parameters and node.positional_parameters[1]
		if type(first_param) == "table" then
			return first_param[1]
		else
			return first_param or ""
		end
	end

	if node.command == "__BLOCK__" then
		local result = {}
		if node.positional_parameters then
			for _, param in ipairs(node.positional_parameters) do
				table.insert(result, simplify(param))
			end
		end
		return result
	end

	local simplified = {}

	for k, v in pairs(node) do
		if k ~= "range" then
			if k == "named_parameters" and type(v) == "table" then
				-- flatten named_parameters array into dictionary
				local flat_named = {}
				for _, pair in ipairs(v) do
					local key = simplify(pair.key)
					local value = simplify(pair.value)
					flat_named[key] = value
				end
				simplified[k] = flat_named
			elseif type(v) == "table" then
				simplified[k] = simplify(v)
			else
				simplified[k] = v
			end
		end
	end

	return simplified
end

function M:parse(text, options)
	options = options or {}
	local result = grammar:match(text)
	if options.simplified then
		return simplify(result)
	end
	return result
end

return M
