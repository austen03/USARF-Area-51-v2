local SCOPES = {
	server = true,
	moderation = true,
	developer = true,
	event = true,
	team = true,
	facility = true,
	security = true,
}

local ORDERED = {
	"server",
	"moderation",
	"developer",
	"event",
	"team",
	"facility",
	"security",
}

local function clean(value)
	return string.lower(
		tostring(value or "")
			:gsub("^%s+", "")
			:gsub("%s+$", "")
	)
end

local function getMatches(text)
	text = clean(text)

	local results = {}

	for _, scope in ipairs(ORDERED) do
		if text == ""
			or string.sub(scope, 1, #text) == text
		then
			table.insert(results, scope)
		end
	end

	return results
end

return function(registry)
	registry:RegisterType("announcementScope", {
		Transform = function(text)
			return clean(text)
		end,

		Validate = function(text)
			text = clean(text)

			if SCOPES[text] then
				return true
			end

			return false, "Invalid announcement scope."
		end,

		Autocomplete = function(text)
			return getMatches(text)
		end,

		Parse = function(text)
			return clean(text)
		end,
	})
end
