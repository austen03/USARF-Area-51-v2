local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local ModerationCaseService = require(Services:WaitForChild("ModerationCaseService"))

return function(context, userId, reason)
	local ok, result = ModerationCaseService.UnbanUser(
		context.Executor,
		userId,
		reason
	)

	if not ok then
		return tostring(result)
	end

	return "Unban processed for userId " .. tostring(userId) .. "."
end
