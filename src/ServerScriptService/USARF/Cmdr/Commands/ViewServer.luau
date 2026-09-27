local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local ModerationUtilityService = require(Services:WaitForChild("ModerationUtilityService"))

return function(context, target)
	local ok, reason = ModerationUtilityService.View(context.Executor, target)

	if not ok then
		return reason
	end

	return "Now viewing " .. target.Name .. "."
end
