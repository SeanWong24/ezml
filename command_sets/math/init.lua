local Math = {}

-- Helper to detect if param is a simple text node (possibly nested inside exactly one __BLOCK__)
local function is_wrapped_text_node(param)
	if not param then
		return false
	end

	if param.command == "__TEXT__" then
		return true
	end

	if param.command == "__BLOCK__" and param.positional_parameters and #param.positional_parameters == 1 then
		return is_wrapped_text_node(param.positional_parameters[1])
	end

	return false
end

-- Helper to resolve and wrap in <mn> if param is simple text node
local function resolve_and_wrap_mn(context, param)
	local resolve = context.helpers.utils.resolve
	local resolved = resolve(param or "")
	if is_wrapped_text_node(param) then
		return "<mn>" .. resolved .. "</mn>"
	end
	return resolved
end

Math["="] = function(context, _, p)
	return "<math>" .. context.helpers.utils.resolve(p and p[1] or "") .. "</math>"
end

Math["sqrt"] = function(context, _, p)
	return "<msqrt>" .. resolve_and_wrap_mn(context, p and p[1]) .. "</msqrt>"
end

Math["frac"] = function(context, _, p)
	local numerator = resolve_and_wrap_mn(context, p[1])
	local denominator = resolve_and_wrap_mn(context, p[2])
	return "<mfrac>" .. numerator .. denominator .. "</mfrac>"
end

return Math
