local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local NameTagService = require(Services:WaitForChild("NameTagService"))

return function(context)
	local player = context.Executor

	if not player then
		return "Unable to find command executor."
	end

	local currentlyEnabled = NameTagService.AreBadgesEnabled(player)
	local newState = not currentlyEnabled

	NameTagService.SetBadgesEnabled(player, newState)

	return string.format(
		"Your badges are now %s.",
		newState and "ON" or "OFF"
	)
end
