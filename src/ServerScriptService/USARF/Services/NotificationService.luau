local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local NotificationService = {}

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local NotificationQueueService = require(Services:WaitForChild("NotificationQueueService"))

function NotificationService.Notify(player, data)
	if not player or not data then
		return false, "Missing player or data"
	end

	return NotificationQueueService.Queue(player, {
		Title = tostring(data.Title or "Notification"),
		Message = tostring(data.Message or ""),
		Type = tostring(data.Type or "Info"),
		Duration = tonumber(data.Duration) or 5,
		Size = tostring(data.Size or "Small"),
		Large = data.Large == true,

		Priority = tonumber(data.Priority) or 1,
		Gap = tonumber(data.Gap) or 0.35,
		Dedupe = data.Dedupe ~= false,
	})
end

function NotificationService.NotifyAll(data)
	return NotificationQueueService.QueueAll(data)
end

function NotificationService.NotifyTeam(teamName, data)
	return NotificationQueueService.QueueTeam(teamName, data)
end

function NotificationService.NotifyMany(playersList, data)
	return NotificationQueueService.QueueMany(playersList, data)
end

function NotificationService.Clear(player)
	return NotificationQueueService.Clear(player)
end

return NotificationService