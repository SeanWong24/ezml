local Context = {}

function Context.new(options)
	local self = {
		helpers = options.helpers or {},
		env = options.env or {}, -- could be used for runtime flags or state
		meta = options.meta or {}, -- optional metadata
		type = "context",
	}

	setmetatable(self, {
		__index = function(tbl, key)
			-- Allow lazy access to helpers via `context.lpeg` if desired
			if tbl.helpers and tbl.helpers[key] then
				return tbl.helpers[key]
			end
			return rawget(tbl, key)
		end,
	})

	return self
end

return Context
