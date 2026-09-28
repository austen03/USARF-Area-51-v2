local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local RadioService = require(Services:WaitForChild("RadioService"))

return function(context, text, channel)
	text = tostring(text or "")
	channel = string.lower(tostring(channel or "all"))

	if text == "" then
		return "Message cannot be empty."
	end

	if channel == "all" then
		RadioService.SystemAll(text)
		return "Sent SYSTEM radio message to all channels."
	end

	RadioService.System(channel, text)
	return "Sent SYSTEM radio message to " .. channel .. "."
end
