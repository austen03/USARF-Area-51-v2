-- Keep in step with STATUS_DISPLAY in Commands/VPOTUS_POTUS/FacilityStatusServer.
local ORDERED = {
	"normal",
	"secure",
	"alert",
	"lockdown",
	"breach",
	"riot",
	"hostileforces",
	"ufo",
	"code1",
	"maintenance",
	"evacuation",
}

local VALID = {}
for _, status in ipairs(ORDERED) do
	VALID[status] = true
end

local function clean(value)
	return string.lower((tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")))
end

return function(registry)
	registry:RegisterType("facilityStatus", {
		Transform = function(text)
			return clean(text)
		end,

		Validate = function(value)
			if VALID[value] then
				return true
			end

			return false, "Status must be one of: " .. table.concat(ORDERED, ", ") .. "."
		end,

		Autocomplete = function(text)
			local matches = {}

			for _, status in ipairs(ORDERED) do
				if text == "" or string.sub(status, 1, #text) == text then
					table.insert(matches, status)
				end
			end

			return matches
		end,

		Parse = function(value)
			return value
		end,
	})
end
