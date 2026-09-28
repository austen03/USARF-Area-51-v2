local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityLockdownService = require(Services:WaitForChild("FacilityLockdownService"))

local DEFCON_TO_LOCKDOWN = {
	[5] = 0,
	[4] = 1,
	[3] = 2,
	[2] = 3,
	[1] = 4,
}

return function(context, level)
	level = math.clamp(math.floor(tonumber(level) or 5), 1, 5)

	local lockdownLevel = DEFCON_TO_LOCKDOWN[level] or 0

	FacilityLockdownService.SetLevel(
		lockdownLevel,
		context.Executor,
		"DEFCON " .. tostring(level) .. " triggered"
	)

	return "DEFCON set to " .. tostring(level) .. "."
end
