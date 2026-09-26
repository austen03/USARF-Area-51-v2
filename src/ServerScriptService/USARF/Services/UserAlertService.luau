local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local CaseIdService = require(Services:WaitForChild("CaseIdService"))
local AuditService = require(Services:WaitForChild("AuditService"))
local StaffAlertService = require(Services:WaitForChild("StaffAlertService"))
local WebhookService = require(Services:WaitForChild("WebhookService"))
local UserAlertHistoryService = require(Services:WaitForChild("UserAlertHistoryService"))

local StaffAlertRadioService = nil
pcall(function()
	StaffAlertRadioService = require(Services:WaitForChild("StaffAlertRadioService"))
end)

local DiscordBotBridge = nil

pcall(function()
	local bridgeModule = Services:FindFirstChild("DiscordBotBridge")

	if bridgeModule then
		DiscordBotBridge = require(bridgeModule)
	else
		warn("[SuspensionService] DiscordBotBridge not found. Bot events disabled.")
	end
end)

local UserAlertService = {}

local MAX_RECENT_ALERTS = 150
local recentAlerts = {}

local function getPlayerInfo(player)
	if not player then
		return nil
	end

	return {
		userId = player.UserId,
		username = player.Name,
		displayName = player.DisplayName,
		teamName = player.Team and player.Team.Name or nil,
	}
end

local function trimRecentAlerts()
	while #recentAlerts > MAX_RECENT_ALERTS do
		table.remove(recentAlerts, 1)
	end
end

local function buildExploitWebhook(alert)
	local playerInfo = alert.player or {}

	return {
		embeds = {
			{
				title = "User Alert / Exploit Detection",
				color = 15158332,
				fields = {
					{
						name = "User",
						value = string.format(
							"%s (%s)",
							playerInfo.username or "Unknown",
							tostring(playerInfo.userId or "N/A")
						),
						inline = true,
					},
					{
						name = "Detection",
						value = tostring(alert.alertType or "Unknown"),
						inline = true,
					},
					{
						name = "Severity",
						value = tostring(alert.severity or "Info"),
						inline = true,
					},
					{
						name = "Source",
						value = tostring(alert.source or "System"),
						inline = true,
					},
					{
						name = "Case ID",
						value = tostring(alert.caseId or "N/A"),
						inline = true,
					},
					{
						name = "Team",
						value = tostring(playerInfo.teamName or "N/A"),
						inline = true,
					},
					{
						name = "Message",
						value = tostring(alert.message or "No message provided."),
						inline = false,
					},
				},
				timestamp = DateTime.now():ToIsoDate(),
			},
		},
	}
end

local function shouldPostToStaffAlerts(alert)
	local alertType = string.lower(tostring(alert.alertType or ""))
	local source = string.lower(tostring(alert.source or ""))
	local message = string.lower(tostring(alert.message or ""))

	if alert.external == true then
		return true
	end

	if string.find(alertType, "exploit") then
		return true
	end

	if string.find(source, "exploit") then
		return true
	end

	if string.find(message, "exploit") then
		return true
	end

	return false
end

local function getBotEventType(alert)
	local alertType = string.lower(tostring(alert.alertType or ""))
	local source = string.lower(tostring(alert.source or ""))
	local message = string.lower(tostring(alert.message or ""))

	if string.find(alertType, "exploit")
		or string.find(source, "exploit")
		or string.find(message, "exploit")
		or source == "antiexploit"
	then
		return "exploit.detected"
	end

	if string.find(alertType, "warn")
		or string.find(alertType, "warning")
		or string.find(message, "warn")
		or string.find(message, "warning")
	then
		return "game.warning"
	end

	return nil
end

local function sendBotEvent(alert)
	if not DiscordBotBridge then
		return
	end

	local eventType = getBotEventType(alert)
	if not eventType then
		return
	end

	local playerInfo = alert.player or {}

	pcall(function()
		DiscordBotBridge.SendEvent(eventType, {
			caseId = alert.caseId,
			createdAt = alert.createdAt,

			alertType = alert.alertType,
			severity = alert.severity,
			source = alert.source,
			message = alert.message,

			robloxUserId = playerInfo.userId and tostring(playerInfo.userId) or nil,
			robloxUsername = playerInfo.username,
			displayName = playerInfo.displayName,
			teamName = playerInfo.teamName,

			metadata = alert.metadata or {},
		})
	end)
end

function UserAlertService.Create(data)
	data = data or {}

	local caseId = data.caseId or CaseIdService.Generate()

	local alert = {
		caseId = caseId,
		createdAt = os.time(),

		alertType = data.alertType or "General",
		severity = data.severity or "Info",
		source = data.source or "System",
		message = data.message or "No message provided.",

		player = getPlayerInfo(data.player),
		external = data.external == true,

		metadata = data.metadata or {},
	}

	table.insert(recentAlerts, 1, alert)
	trimRecentAlerts()

	UserAlertHistoryService.Record(alert)

	AuditService.Log({
		caseId = caseId,
		category = "UserAlert",
		action = alert.alertType,
		target = data.player,
		message = alert.message,
		severity = alert.severity,
		external = alert.external,
		metadata = alert,
	})

	StaffAlertService.Send({
		caseId = caseId,
		title = "User Alert",
		message = alert.message,
		severity = alert.severity,
		category = "UserAlert",
		target = data.player,
	})

	if shouldPostToStaffAlerts(alert) and StaffAlertRadioService then
		StaffAlertRadioService.ExploitDetected(data.player, alert.alertType, alert.severity)
	end

	sendBotEvent(alert)

	if alert.external == true then
		WebhookService.Queue("Exploit", buildExploitWebhook(alert))
	end

	print(
		string.format(
			"[UserAlertService] [%s] [%s] %s",
			alert.severity,
			alert.caseId,
			alert.message
		)
	)

	return alert
end

function UserAlertService.GetRecentAlerts()
	local copy = {}

	for index, alert in ipairs(recentAlerts) do
		copy[index] = alert
	end

	return copy
end

function UserAlertService.FindByCaseId(caseId)
	for _, alert in ipairs(recentAlerts) do
		if alert.caseId == caseId then
			return alert
		end
	end

	return nil
end

return UserAlertService