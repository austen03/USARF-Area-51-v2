local CURRENCIES = {
	"cash",
	"gold",
}

local function clean(value)
	return string.lower(tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function getMatches(text)
	text = clean(text)

	local results = {}

	for _, currency in ipairs(CURRENCIES) do
		if text == "" or string.sub(currency, 1, #text) == text then
			table.insert(results, currency)
		end
	end

	return results
end

return function(registry)
	registry:RegisterType("currency", {
		Transform = function(text)
			return clean(text)
		end,

		Validate = function(text)
			text = clean(text)

			if text == "cash" or text == "gold" then
				return true
			end

			return false, "Currency must be cash or gold."
		end,

		Autocomplete = function(text)
			return getMatches(text)
		end,

		Parse = function(text)
			return clean(text)
		end,
	})
end