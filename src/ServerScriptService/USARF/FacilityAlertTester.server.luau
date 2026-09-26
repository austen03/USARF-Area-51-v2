local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local FacilityAlertService = require(
	Services:WaitForChild("FacilityAlertService")
)

task.wait(10)

FacilityAlertService.SendAlert(
	"Emergency",
	"Security Lockdown",
	"Sector B has entered lockdown.",
	"System"
)

task.wait(10)

FacilityAlertService.SendAlert(
	"Site Evac",
	"Evacuation",
	"Test.",
	"System"
)