local Core = {}

local function normalize_whitespaces(str)
	-- Normalize CRLF to LF
	str = str:gsub("\r\n", "\n")

	-- Pattern to match paragraphs separated by blank lines (2+ newlines)
	local PARAGRAPH_PATTERN = "([^%s][^\n]*[^%s]?)%s*\n*\n*"

	local paragraphs = {}

	for para in str:gmatch(PARAGRAPH_PATTERN) do
		-- Collapse all whitespace inside paragraph to a single space
		para = para:gsub("%s+", " ")
		table.insert(paragraphs, para)
	end

	-- If no paragraphs matched (e.g., all whitespace), collapse entire string
	if #paragraphs == 0 then
		return str:gsub("%s+", " ")
	end

	-- Join paragraphs with a single newline
	return table.concat(paragraphs, "\n")
end

Core[""] = function(context, _, p)
	local resolve = context.helpers.utils.resolve
	local result = {}

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
