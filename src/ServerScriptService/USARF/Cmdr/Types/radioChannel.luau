local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local RadioConfig = require(USARF:WaitForChild("Config"):WaitForChild("RadioConfig"))

local function clean(value)
	return string.lower(tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function getChannels()
	local channels = { "all" }

	for _, channel in ipairs(RadioConfig.Channels or {}) do
		table.insert(channels, channel.key)
	end

	table.sort(channels)
	return channels
end

local function getMatches(text)
	text = clean(text)

	local results = {}

	for _, channel in ipairs(getChannels()) do
		local channelText = clean(channel)

		if text == "" or string.sub(channelText, 1, #text) == text then
			table.insert(results, channel)
		end
	end

	return results
end

return function(registry)
	registry:RegisterType("radioChannel", {
		Transform = function(text)
			return clean(text)
		end,

		Validate = function(text)
			text = clean(text)

			if text == "" or text == "all" then
				return true
			end

			for _, channel in ipairs(RadioConfig.Channels or {}) do
				if clean(channel.key) == text then
					return true
				end
			end

			return false, "Invalid radio channel."
		end,

		Autocomplete = function(text)
			return getMatches(text)
		end,

		Parse = function(text)
			text = clean(text)

			if text == "" then
				return "all"
			end

			return text
		end,
	})
end