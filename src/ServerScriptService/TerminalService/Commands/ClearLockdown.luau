local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local FacilityLockdownService = require(Services:WaitForChild("FacilityLockdownService"))
local FacilityStatusService = require(Services:WaitForChild("FacilityStatusService"))

return {
	Name = "clearlockdown",
	Aliases = { "unlockdown", "clearld", "normal" },
	Description = "Clears facility lockdown and returns the facility to normal operations.",
	Usage = "clearlockdown",
	Category = "Facility",
	MinRank = 11,

	Run = function(context)
		local state = FacilityLockdownService.Clear(context.Player, "Cleared from terminal.")

		if FacilityStatusService and typeof(FacilityStatusService.SetLastEvent) == "function" then
			FacilityStatusService.SetLastEvent("Terminal cleared facility lockdown.")
		end

		return {
			Type = "Success",
			Message = "Lockdown cleared. Active: " .. tostring(state.Active),
		}
	end,
}