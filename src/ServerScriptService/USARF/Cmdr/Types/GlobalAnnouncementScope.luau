local function clean(value)
	return string.lower(
		tostring(value or "")
			:gsub("^%s+", "")
			:gsub("%s+$", "")
	)
end

return function(registry)
	registry:RegisterType("globalAnnouncementScope", {
		Transform = function(text)
			return clean(text)
		end,

		Validate = function(text)
			return clean(text) == "global",
			"Scope must be global."
		end,

		Autocomplete = function()
			return { "global" }
		end,

		Parse = function()
			return "global"
		end,
	})
end
