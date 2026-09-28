local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityAlertService = require(Services:WaitForChild("FacilityAlertService"))
local FacilityAnnouncementService = require(Services:WaitForChild("FacilityAnnouncementService"))

return function(context, message)
	message = tostring(message or "Unidentified aerial activity detected.")

	FacilityAnnouncementService.PlayEvent("UFO")

	FacilityAlertService.SendAlert(
		"Facility",
		"UFO Activity",
		message,
		context.Executor.Name
	)

	return "UFO announcement triggered."
end
