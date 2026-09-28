local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local InitService = require(Services:WaitForChild("InitService"))

return function(context, action)
	local player = context.Executor

	action = string.lower(tostring(action or ""))

	if action == "edit" then
		InitService.OpenEditor(player)
		return "Opened init editor."
	elseif action == "run" then
		InitService.RunInit(player)
		return "Ran init script."
	end

	return "Usage: init edit OR init run"
end
