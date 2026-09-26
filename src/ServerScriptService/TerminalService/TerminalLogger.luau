local ServerScriptService = game:GetService("ServerScriptService")

local TerminalLogger = {}

local AdminLogService = nil

pcall(function()
	local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
	AdminLogService = require(Services:WaitForChild("AdminLogService"))
end)

function TerminalLogger.LogTerminal(player, command, result)
	if AdminLogService and typeof(AdminLogService.Log) == "function" then
		AdminLogService.Log({
			source = "Terminal",
			action = "Command",
			command = command,
			result = result,
			moderatorUserId = player and player.UserId or nil,
			moderatorUsername = player and player.Name or "Unknown",
		})
	end

	print(
		"[Terminal]",
		player and player.Name or "Unknown",
		command,
		result
	)
end

return TerminalLogger