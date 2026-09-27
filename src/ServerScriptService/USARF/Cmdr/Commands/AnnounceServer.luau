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
	teamName,
	sendToAlerts
)
	local ok, result = AnnouncementService.SendScoped(
		context.Executor,
		scope,
		message,
		systemMask == true,
		teamName,
		sendToAlerts == true
	)

	if not ok then
		return result
	end

	return "Server announcement sent."
end
