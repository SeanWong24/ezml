local Context = require("utils.context")
local Sandbox = require("utils.sandbox")

local Renderer = {}

Renderer.__index = Renderer

-- Helper to merge multiple command handler tables into one
local function merge_handlers(handler_modules)
	local fallback_chain = {}

	for _, mod in ipairs(handler_modules) do
		table.insert(fallback_chain, mod)
	end

	-- Use a proxy table that checks each module in order
	return setmetatable({}, {
		__index = function(_, key)
			for _, mod in ipairs(fallback_chain) do
				local val = mod[key]
				if val ~= nil then
					return val
				end
			end
			return nil
		end,
	})
end

-- Fallback handler returns NOTHING
-- TODO should return content as is
local function default_handler(context, named_params, positional_params)
	return ""
end

-- Constructor: receives a list of command module paths, loads them, merges handlers
function Renderer.new(command_modules)
	assert(type(command_modules) == "table", "command_modules must be a table")

	local loaded_modules = {}
	for _, module_path in ipairs(command_modules) do
		local ok, mod = pcall(Sandbox.require, module_path)
		if not ok then
			error(("Failed to load command module %q: %s"):format(module_path, tostring(mod)))
		end

		table.insert(loaded_modules, mod)
	end

	local self = setmetatable({}, Renderer)
	self.handlers = merge_handlers(loaded_modules)
	return self
end

-- Get handler for command, fallback to default handler
function Renderer:get_handler(command_name)
	return self.handlers[command_name] or self.handlers[""] or default_handler
end

function Renderer:render_html(ast)
	local context -- declare early so resolve can capture it

	local function resolve(node, c)
		if node == nil then
			return nil
		end
		if type(node) ~= "table" then
			return tostring(node)
		end

		local cmd = node.command
		local handler = self:get_handler(cmd)

		-- Pass named and positional parameters as raw AST nodes (or strings)
		local named = node.named_parameters or {}
		local positional = node.positional_parameters or {}

		-- Handler uses context.helpers.utils.resolve to render nested nodes as needed
		return handler(c or context, named, positional)
	end

	context = Context.new({
		helpers = {
			utils = {
				get_handler = function(name)
					return self:get_handler(name)
				end,
				set_handler = function(name, handler)
					if type(name) ~= "string" or type(handler) ~= "function" then
						error("Invalid arguments to set_handler")
					end
					self.handlers[name] = handler
				end,
				resolve = resolve,
				flatten_named_parameters = function(named_params)
					local flat = {}
					for _, pair in ipairs(named_params or {}) do
						local key_node, value_node = pair.key, pair.value
						if key_node and value_node then
							local key_str = resolve(key_node)
							local value_str = resolve(value_node)
							if key_str and value_str then
								flat[key_str] = value_str
							end
						end
					end
					return flat
				end,
			},
		},
	})

	return resolve(ast)
end

return Renderer
