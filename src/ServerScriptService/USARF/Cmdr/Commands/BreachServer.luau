local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityAlertService = require(Services:WaitForChild("FacilityAlertService"))
local FacilityAnnouncementService = require(Services:WaitForChild("FacilityAnnouncementService"))

return function(context, message)
	message = tostring(message or "Containment breach detected.")

	FacilityAnnouncementService.PlayEvent("Breach")

	FacilityAlertService.SendAlert(
		"Emergency",
		"Containment Breach",
		message,
		context.Executor.Name
	)

	return "Breach announcement triggered."
end
