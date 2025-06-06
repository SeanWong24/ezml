local Basic = {}

Basic.cp = function(context, _, p)
	local default_handler = context.helpers.utils.get_handler("")
	return '<span style="text-transform: capitalize;">' .. default_handler(context, _, p) .. "</span>"
end

Basic.pg = function()
	return '<div style="break-before: page;"></div>'
end

Basic.br = function()
	return "<br/>"
end

Basic.hr = function()
	return "<hr/>"
end

local tag_map = {
	doc = {
		"body",
		{ margin = 0 },
		function(content)
			return '<style>@page {@top-center {content: ""} @bottom-center {content: "Page " counter(page); font-family: Arial;}}</style>'
			.. content
		end,
	},
	h1 = "h1",
	h2 = "h2",
	h3 = "h3",
	h4 = "h4",
	h5 = "h5",
	h6 = "h6",
	p = "p",
	text = "span",
	strong = "strong",
	em = "em",
	b = "b",
	i = "i",
	code = "code",
	pre = "pre",
	blockquote = "blockquote",
	ol = "ol",
	ul = "ul",
	li = "li",
	section = "section",
}

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

local function handle_tag_map(key)
	local entry = tag_map[key]
	if not entry then
		return nil
	end

	local tag, default_css = nil, {}

	if type(entry) == "string" then
		tag = entry
	elseif type(entry) == "table" then
		tag = entry[1]
		default_css = entry[2] or {}
	else
		return nil
	end

	return function(context, named_params, positional_params)
		local default_handler = context.helpers.utils.get_handler("")
		local content = default_handler(context, nil, positional_params)
		if tag_map[key] and tag_map[key][3] then
			content = tag_map[key][3](content)
		end

		local css_props = context.helpers.utils.flatten_named_parameters(named_params)

		local final_css = {}
		for k, v in pairs(default_css) do
			final_css[k] = v
		end
		for k, v in pairs(css_props) do
			k = tostring(k):match("^%s*(.-)%s*$")
			v = tostring(v):match("^%s*(.-)%s*$")
			final_css[k] = v
		end

		local style_parts = {}
		for k, v in pairs(final_css) do
			table.insert(style_parts, k .. ": " .. v .. ";")
		end

		local style_attr = ""
		if #style_parts > 0 then
			style_attr = ' style="' .. table.concat(style_parts, " ") .. '"'
		end

		return ("<%s%s>%s</%s>"):format(tag, style_attr, content, tag)
	end
end

setmetatable(Basic, {
	__index = function(_, key)
		-- Handle semantic HTML tags
		local tag_handler = handle_tag_map(key)
		if tag_handler then
			return tag_handler
		end

		return nil
	end,
})

return Basic
