local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityAlertService = require(Services:WaitForChild("FacilityAlertService"))
local FacilityAnnouncementService = require(Services:WaitForChild("FacilityAnnouncementService"))

return function(context, message)
	message = tostring(message or "Code 1 has been declared.")

	FacilityAnnouncementService.PlayEvent("Code1")

	FacilityAlertService.SendAlert(
		"Facility",
		"Code 1",
		message,
		context.Executor.Name
	)

	return "Code 1 announcement triggered."
end
