local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local RiotService = require(Services:WaitForChild("RiotService"))
local FacilityLockdownService = require(Services:WaitForChild("FacilityLockdownService"))

local FacilityAnnouncementService = nil
pcall(function()
	FacilityAnnouncementService = require(Services:WaitForChild("FacilityAnnouncementService"))
end)

local RIOT_LOCKDOWN_LEVEL = 2

-- Lockdown goes through FacilityLockdownService (not the LockdownLevel value directly) so
-- doors follow it and the change is posted to the alerts channel.
return function(context, enabled)
	local active = RiotService.IsActive()

	if enabled == nil then
		enabled = not active
	end

	if enabled == true then
		local ok, result = RiotService.StartRiot(600, context.Executor, "Cmdr riot command", "Cmdr")

		if not ok then
			return tostring(result)
		end

		if FacilityLockdownService.GetLevel() < RIOT_LOCKDOWN_LEVEL then
			FacilityLockdownService.SetLevel(RIOT_LOCKDOWN_LEVEL, context.Executor, "Test Subject riot")
		end

		return "Riot started."
	end

	local ok, result = RiotService.EndRiot(context.Executor, "Cmdr riot command")

	if FacilityAnnouncementService and typeof(FacilityAnnouncementService.StopAll) == "function" then
		FacilityAnnouncementService.StopAll()
	end

	FacilityLockdownService.Clear(context.Executor, "Riot ended")

	if not ok then
		return tostring(result)
	end

	return "Riot ended."
end
