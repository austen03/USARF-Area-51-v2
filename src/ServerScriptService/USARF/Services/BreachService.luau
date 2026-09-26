local ServerScriptService = game:GetService("ServerScriptService")

local BreachService = {}

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityAnnouncementService = require(Services:WaitForChild("FacilityAnnouncementService"))
local FacilityLockdownService = require(Services:WaitForChild("FacilityLockdownService"))
local FacilityStatusService = require(Services:WaitForChild("FacilityStatusService"))
local DepartmentAlertService = require(Services:WaitForChild("DepartmentAlertService"))

local activeBreach = nil

local BREACH_LEVEL_LOCKDOWNS = {
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
}

function BreachService.IsActive()
	return activeBreach ~= nil
end

function BreachService.GetActiveBreach()
	return activeBreach
end

function BreachService.StartBreach(sectorName, severity, actor)
	sectorName = tostring(sectorName or "Unknown Sector")
	severity = math.clamp(math.floor(tonumber(severity) or 1), 1, 4)

	activeBreach = {
		Sector = sectorName,
		Severity = severity,
		StartedAt = os.time(),
		StartedBy = actor and actor.Name or "System",
	}

	local lockdownLevel = BREACH_LEVEL_LOCKDOWNS[severity] or 2

	FacilityStatusService.SetLastEvent(
		"Breach reported in " .. sectorName .. " | Severity " .. tostring(severity)
	)

	FacilityAnnouncementService.PlayEvent("Breach")

	DepartmentAlertService.ContainmentBreach(
		"Breach reported in " .. sectorName .. ". Severity " .. tostring(severity) .. "."
	)

	FacilityLockdownService.SetLevel(
		lockdownLevel,
		actor,
		"Breach reported in " .. sectorName
	)

	print(
		"[BreachService] Breach started:",
		sectorName,
		"Severity:",
		severity,
		"Lockdown:",
		lockdownLevel
	)

	return true, activeBreach
end

function BreachService.EndBreach(actor, reason)
	if not activeBreach then
		return false, "No active breach"
	end

	local oldSector = activeBreach.Sector
	activeBreach = nil

	FacilityStatusService.SetLastEvent(
		"Breach cleared in " .. oldSector
	)

	DepartmentAlertService.SecurityIncident(
		"Breach has been cleared in " .. oldSector .. ". " .. tostring(reason or "")
	)

	FacilityLockdownService.Clear(
		actor,
		reason or "Breach cleared"
	)

	print("[BreachService] Breach cleared:", oldSector)

	return true
end

return BreachService