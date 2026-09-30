-- DEFCON 5 is normal operations, DEFCON 1 the most severe.
local ORDERED = { "5", "4", "3", "2", "1" }

local function clean(value)
	return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

return function(registry)
	registry:RegisterType("defconLevel", {
		Transform = function(text)
			return clean(text)
		end,

		Validate = function(value)
			local level = tonumber(value)

			if level and level >= 1 and level <= 5 and level % 1 == 0 then
				return true
			end

			return false, "DEFCON level must be 1-5."
		end,

		Autocomplete = function(text)
			local matches = {}

			for _, level in ipairs(ORDERED) do
				if text == "" or string.sub(level, 1, #text) == text then
					table.insert(matches, level)
				end
			end

			return matches
		end,

		Parse = function(value)
			return tonumber(value)
		end,
	})
end
