local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local AuditService = require(Services:WaitForChild("AuditService"))

local DiscordBotBridge = nil

pcall(function()
	local bridgeModule = Services:FindFirstChild("DiscordBotBridge")

	if bridgeModule then
		DiscordBotBridge = require(bridgeModule)
	else
		warn("[SuspensionService] DiscordBotBridge not found. Bot events disabled.")
	end
end)

local ActivityExportService = {}

local MAX_QUEUE_SIZE = 250
local exportQueue = {}

local TEAM_DISPLAY = {
	["137mp"] = "MP",
	["engineering"] = "E&M",
	["medical"] = "Medical",
	["research"] = "Research",
	["rnr"] = "R&R",
	["usaf"] = "USAF",
	["dod"] = "DoD",
	["cia"] = "CIA",
	["fbi"] = "FBI",
	["fds"] = "FDS",
	["secret_service"] = "USSS",
	["108th"] = "108th",
	["specops"] = "SPEC OPS",
}

local function trimQueue()
	while #exportQueue > MAX_QUEUE_SIZE do
		table.remove(exportQueue, 1)
	end
end

local function formatDuration(seconds)
	seconds = math.max(0, math.floor(seconds or 0))

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	if hours > 0 then
		if minutes > 0 then
			return string.format("%dh %dm", hours, minutes)
		end

		return string.format("%dh", hours)
	end

	if minutes > 0 then
		return string.format("%dm", minutes)
	end

	return string.format("%ds", seconds)
end

local function getDepartmentName(session)
	return TEAM_DISPLAY[session.teamKey] or session.teamName or "Unknown"
end

local function sendBotActivity(session, exportItem)
	if not DiscordBotBridge then
		return false
	end

	local ok = pcall(function()
		DiscordBotBridge.SendEvent("activity.session", {
			type = "TeamActivitySession",

			userId = session.userId and tostring(session.userId) or nil,
			username = session.username,
			displayName = session.displayName,

			teamKey = session.teamKey,
			teamName = session.teamName,
			departmentName = getDepartmentName(session),

			startedAt = session.startedAt,
			endedAt = session.endedAt,
			duration = session.duration,
			durationText = formatDuration(session.duration),
			reason = session.reason,

			queuedAt = exportItem.queuedAt,
		})
	end)

	return ok
end

function ActivityExportService.QueueSession(session)
	if not session then
		return false, "Missing session"
	end

	local exportItem = {
		type = "TeamActivitySession",

		userId = session.userId,
		username = session.username,
		displayName = session.displayName,

		teamKey = session.teamKey,
		teamName = session.teamName,

		startedAt = session.startedAt,
		endedAt = session.endedAt,
		duration = session.duration,
		reason = session.reason,

		queuedAt = os.time(),
		status = "Queued",
		attempts = 0,
	}

	table.insert(exportQueue, exportItem)
	trimQueue()

	AuditService.Log({
		category = "Activity",
		action = "SessionQueuedForExport",
		message = string.format(
			"%s activity queued for bot export: %s (%s)",
			session.username or "Unknown",
			session.teamName or "Unknown",
			formatDuration(session.duration)
		),
		severity = "Info",
		external = false,
		metadata = exportItem,
	})

	local sent = sendBotActivity(session, exportItem)
	exportItem.status = sent and "SentToBotBridge" or "BotBridgeUnavailable"

	print(
		string.format(
			"[ActivityExportService] Queued | %s | %s | %s | %s",
			session.username or "Unknown",
			session.teamName or "Unknown",
			formatDuration(session.duration),
			exportItem.status
		)
	)

	return true, exportItem
end

function ActivityExportService.GetQueue()
	local copy = {}

	for index, item in ipairs(exportQueue) do
		copy[index] = item
	end

	return copy
end

function ActivityExportService.ClearQueue()
	table.clear(exportQueue)
end

print("USARF ActivityExportService initialized")

return ActivityExportService