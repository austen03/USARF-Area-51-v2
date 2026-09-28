local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local ModerationUtilityService = require(Services:WaitForChild("ModerationUtilityService"))

return function(context)
	local player = context.Executor

	local success, enabled = ModerationUtilityService.ToggleModMode(player)

	if not success then
		return "Failed to toggle ModMode."
	end

	player:SetAttribute("USARF_RadioAccessRefresh", os.clock())
	player:SetAttribute("USARF_RadioAccessRefreshClient", os.clock())

	return "ModMode is now " .. (enabled and "ON." or "OFF.")
end
