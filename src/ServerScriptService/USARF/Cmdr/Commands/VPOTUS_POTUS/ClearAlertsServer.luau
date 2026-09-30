local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityAlertService = require(Services:WaitForChild("FacilityAlertService"))

return function(context)
	local removed = FacilityAlertService.ClearAlerts()

	return "Cleared " .. tostring(removed) .. " alert(s)."
end
