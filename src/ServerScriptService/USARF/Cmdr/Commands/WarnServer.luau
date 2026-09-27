local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local ModerationUtilityService = require(Services:WaitForChild("ModerationUtilityService"))

return function(context, player, reason)
	local ok, result = ModerationUtilityService.WarnPlayer(
		context.Executor,
		player,
		reason
	)

	if not ok then
		return "Warning failed: " .. tostring(result)
	end

	return string.format(
		"Warned %s. Case: %s",
		player.Name,
		tostring(result)
	)
end
