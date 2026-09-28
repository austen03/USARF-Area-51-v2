local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local FacilityAlertService = require(Services:WaitForChild("FacilityAlertService"))

local STATUS_DISPLAY = {
	normal = { status = "NORMAL", subtitle = "Facility systems operational." },
	secure = { status = "SECURE", subtitle = "Facility is secure." },
	alert = { status = "ALERT", subtitle = "Facility alert active." },
	lockdown = { status = "LOCKDOWN", subtitle = "Facility lockdown active." },
	breach = { status = "BREACH", subtitle = "Containment breach detected." },
	riot = { status = "RIOT", subtitle = "Riot conditions active." },
	hostileforces = { status = "HOSTILE FORCES", subtitle = "Hostile forces detected." },
	ufo = { status = "UFO", subtitle = "Unidentified aerial activity detected." },
	code1 = { status = "CODE 1", subtitle = "Code 1 declared." },
	maintenance = { status = "MAINTENANCE", subtitle = "Maintenance operations active." },
	evacuation = { status = "EVACUATION", subtitle = "Evacuation protocols active." },
}

return function(context, status)
	status = string.lower(tostring(status or "normal"))

	local data = STATUS_DISPLAY[status] or STATUS_DISPLAY.normal

	FacilityAlertService.SetStatus(data.status, data.subtitle)

	return "Facility status set to " .. data.status .. "."
end
