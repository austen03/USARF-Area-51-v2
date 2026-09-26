local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityStatusService = require(Services:WaitForChild("FacilityStatusService"))
local FacilityLockdownService = require(Services:WaitForChild("FacilityLockdownService"))

return {
	Name = "status",
	Aliases = { "facility", "state" },
	Description = "Displays current facility status.",
	Usage = "status",
	Category = "Facility",
	MinRank = 3,

	Run = function()
		local status = FacilityStatusService.GetStatus()
		local lockdown = FacilityLockdownService.GetState()

		return {
			Type = "Info",
			Message = table.concat({
				"Facility Status",
				"Players: " .. tostring(status.PlayerCount),
				"Alert: " .. tostring(status.AlertLevel),
				"Lockdown: " .. tostring(lockdown.Active),
				"Level: " .. tostring(lockdown.Level),
				"Riot: " .. tostring(status.RiotActive),
				"Last Event: " .. tostring(status.LastFacilityEvent),
			}, " | "),
		}
	end,
}