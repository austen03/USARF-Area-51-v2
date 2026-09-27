local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local ModerationCaseService = require(Services:WaitForChild("ModerationCaseService"))

return function(context, caseId, reason)
	reason = tostring(reason)

	local ok, result = ModerationCaseService.VoidCase(
		caseId,
		context.Executor,
		reason
	)

	if not ok then
		return tostring(result)
	end

	if result.type == "Game Ban" then
		ModerationCaseService.UnbanUser(
			context.Executor,
			result.targetUserId,
			"Case voided: " .. reason
		)

		return "Voided case " .. tostring(result.caseId) .. " and processed unban."
	end

	return "Voided case " .. tostring(result.caseId) .. "."
end
