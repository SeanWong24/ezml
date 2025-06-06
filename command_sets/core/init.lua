local Core = {}

local function normalize_whitespaces(str)
	-- Check if original string ends with whitespace
	local ends_with_space = str:match("%s$") ~= nil

	-- Check if string is only whitespace
	local only_whitespace = str:match("^%s*$") ~= nil

	-- Normalize CRLF to LF
	str = str:gsub("\r\n", "\n")

	-- Mark paragraph breaks (2 or more newlines)
	str = str:gsub("\n\n+", "<PARA>")

	-- Collapse all whitespace (spaces, tabs, newlines) to a single space
	str = str:gsub("%s+", " ")

	-- Restore paragraph breaks as newlines
	str = str:gsub("<PARA>", "\n")

	-- Trim leading and trailing whitespace
	str = str:gsub("^%s+", ""):gsub("%s+$", "")

	-- If original was only whitespace, return single space
	if only_whitespace then
		return " "
	end

	-- If original ended with whitespace, add one trailing space
	if ends_with_space then
		return str .. " "
	else
		return str
	end
end

Core[""] = function(context, _, p)
	local resolve = context.helpers.utils.resolve
	local result = {}
	-- local last_was_whitespace = false

	for _, item in ipairs(p or {}) do
		local str = type(item) == "string" and item or resolve(item)
		str = normalize_whitespaces(str)
		table.insert(result, str)
	end

	return table.concat(result)
end

Core.__TEXT__ = Core[""]
Core.__BLOCK__ = Core[""]

Core["#"] = function()
	return ""
end

Core["~"] = function(context, _, p)
	local map = {
		pipe = "|",
		lbrace = "{",
		rbrace = "}",
		lbracket = "[",
		rbracket = "]",
		backslash = "\\",
	}
	if not p or #p < 1 then
		return ""
	end
	local resolve = context.helpers.utils.resolve
	local key = resolve(p[1])
	if not key or type(key) ~= "string" then
		return ""
	end
	key = key:match("^%s*(.-)%s*$") -- trim whitespace
	return map[key] or ""
end

Core["&"] = function(context, _, p)
	local resolve = context.helpers.utils.resolve
	local name = resolve(p[1])
	local body = p[2]
	local handler = function(context, n, p)
		n = context.helpers.utils.flatten_named_parameters(n)
		context.n = n or {}
		context.p = p or {}
		local resolved_body = resolve(body or "", context)
		return resolved_body or ""
	end
	context.helpers.utils.set_handler(name, handler)
	return ""
end

Core["$"] = function(context, n, p)
	local resolve = context.helpers.utils.resolve
	local name = context.helpers.utils.flatten_named_parameters(n)
	for k in pairs(name) do
		return context.n and resolve(context.n[resolve(k)]) or ""
	end
	local position = tonumber(resolve(p[1])) or 1
	if position then
		return context.p and resolve(context.p[position]) or ""
	end
	return ""
end

return Core
