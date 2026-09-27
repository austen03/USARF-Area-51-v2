local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local FacilityStatusService = require(Services:WaitForChild("FacilityStatusService"))
local FacilityAlertService = require(Services:WaitForChild("FacilityAlertService"))

return function(context, message)
	message = tostring(message or "")

	if message == "" then
		return "Message cannot be empty."
	end

	FacilityStatusService.SetLastEvent(message)

	FacilityAlertService.SendAlert(
		"Facility",
		"Facility Message",
		message,
		context.Executor.Name
	)

	return "Facility message updated."
end
