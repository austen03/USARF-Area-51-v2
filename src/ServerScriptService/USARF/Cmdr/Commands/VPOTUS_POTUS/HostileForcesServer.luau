local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityAlertService = require(Services:WaitForChild("FacilityAlertService"))
local FacilityAnnouncementService = require(Services:WaitForChild("FacilityAnnouncementService"))

return function(context, message)
	message = tostring(message or "Hostile forces detected near the facility.")

	FacilityAnnouncementService.PlayEvent("HostileForces")

	FacilityAlertService.SendAlert(
		"Emergency",
		"Hostile Forces",
		message,
		context.Executor.Name
	)

	return "Hostile forces announcement triggered."
end
