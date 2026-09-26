local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local ServerTeleportService = require(
	Services:WaitForChild("ServerTeleportService")
)

ServerTeleportService.Start()

print("[ServerTeleportController] Started")