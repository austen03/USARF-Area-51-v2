local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local ModerationUtilityService = require(Services:WaitForChild("ModerationUtilityService"))

return function(context)
	ModerationUtilityService.Unview(context.Executor)
	return "Stopped viewing."
end
