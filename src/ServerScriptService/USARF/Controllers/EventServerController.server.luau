local ServerScriptService = game:GetService("ServerScriptService")

local EventServerService = require(
	ServerScriptService:WaitForChild("USARF")
		:WaitForChild("Services")
		:WaitForChild("EventServerService")
)

EventServerService.Start()