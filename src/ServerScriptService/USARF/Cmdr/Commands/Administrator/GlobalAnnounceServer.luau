local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService
	:WaitForChild("USARF")
	:WaitForChild("Services")

local AnnouncementService = require(
	Services:WaitForChild("AnnouncementService")
)

return function(
	context,
	scope,
	message,
	systemMask,
	sendToAlerts
)
	if string.lower(tostring(scope or "")) ~= "global" then
		return "Scope must be global."
	end

	local ok, result = AnnouncementService.SendGlobal(
		context.Executor,
		message,
		systemMask == true,
		sendToAlerts == true
	)

	if not ok then
		return result
	end

	return "Global announcement published to all active servers."
end
