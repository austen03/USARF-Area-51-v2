local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local ModerationCaseService = require(Services:WaitForChild("ModerationCaseService"))

return function(context, player, duration, reason)
	reason = tostring(reason or "")

	if reason == "" then
		return "Reason cannot be empty."
	end

	local ok, result = ModerationCaseService.CreateBan(
		context.Executor,
		player,
		tostring(duration or "perm"),
		reason
	)

	if not ok then
		return tostring(result)
	end

	return "Banned " .. player.Name .. ". Case: " .. tostring(result.caseId)
end
