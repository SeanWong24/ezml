local Short = {}

local escape_map = {
	pipe = "pipe",
	pp = "pipe",
	lbrace = "lbrace",
	lb = "lbrace",
	rbrace = "rbrace",
	rb = "rbrace",
	lbracket = "lbracket",
	lbr = "lbracket",
	rbracket = "rbracket",
	rbr = "rbracket",
	backslash = "backslash",
	bs = "backslash",
}

local function handle_escape_map(key)
	local target = escape_map[key]
	if not target then
		return nil
	end

	return function(context)
		local escape_handler = context.helpers.utils.get_handler("~")
		return escape_handler(context, nil, { target })
	end
end

setmetatable(Short, {
	__index = function(_, key)
		-- Handle escape shortcuts like \pp, \pipe
		local escape_handler = handle_escape_map(key)
		if escape_handler then
			return escape_handler
		end

		return nil
	end,
})

return Short
