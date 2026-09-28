local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityLockdownService = require(Services:WaitForChild("FacilityLockdownService"))

return function(context, level)
	level = math.clamp(math.floor(tonumber(level) or 0), 0, 4)

	local state = FacilityLockdownService.SetLevel(level, context.Executor)

	return "Lockdown level set to " .. tostring(state.Level) .. "."
end
