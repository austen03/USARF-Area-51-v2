local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local RiotService = require(Services:WaitForChild("RiotService"))

local FacilityAnnouncementService = nil
pcall(function()
	FacilityAnnouncementService = require(Services:WaitForChild("FacilityAnnouncementService"))
end)

local FacilityState = ReplicatedStorage:WaitForChild("USARF"):WaitForChild("Shared"):WaitForChild("FacilityState")
local LockdownLevelValue = FacilityState:FindFirstChild("LockdownLevel")

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

		if LockdownLevelValue then
			LockdownLevelValue.Value = math.max(LockdownLevelValue.Value, 2)
		end

		return "Riot started."
	end

	local ok, result = RiotService.EndRiot(context.Executor, "Cmdr riot command")

	if FacilityAnnouncementService and typeof(FacilityAnnouncementService.StopAll) == "function" then
		FacilityAnnouncementService.StopAll()
	end

	if LockdownLevelValue then
		LockdownLevelValue.Value = 0
	end

	if not ok then
		return tostring(result)
	end

	return "Riot ended."
end
