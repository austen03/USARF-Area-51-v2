local MODES = {
	default = true,
	unrestricted = true,
	status = true,
}

local ORDERED = {
	"default",
	"unrestricted",
	"status",
}

local function clean(value)
	return string.lower(
		tostring(value or "")
			:gsub("^%s+", "")
			:gsub("%s+$", "")
	)
end

return function(registry)
	registry:RegisterType("teamKillMode", {
		Transform = function(text)
			return clean(text)
		end,

		Validate = function(value)
			value = clean(value)

			if MODES[value] then
				return true
			end

			return false,
			"Mode must be default, unrestricted, or status."
		end,

		Autocomplete = function(text)
			text = clean(text)
			local matches = {}

			for _, mode in ipairs(ORDERED) do
				if text == ""
					or string.sub(mode, 1, #text) == text
				then
					table.insert(matches, mode)
				end
			end

			return matches
		end,

		Parse = function(value)
			return clean(value)
		end,
	})
end