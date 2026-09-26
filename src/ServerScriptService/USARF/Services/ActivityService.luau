local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local TeamConfig = require(USARF.Config.TeamConfig)

local GetActivitySessionRemote = Remotes:WaitForChild("GetActivitySession")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local AuditService = require(Services:WaitForChild("AuditService"))

local ActivityService = {}

local ActivityExportService = require(Services:WaitForChild("ActivityExportService"))

local MIN_SESSION_SECONDS = 30

local activeSessions = {}
local completedSessions = {}

local function now()
	return os.time()
end

local function shouldTrackTeam(teamKey)
	if not teamKey or teamKey == "" then
		return false
	end

	local teamData = TeamConfig.Teams[teamKey]

	if not teamData then
		return false
	end

	return teamData.trackActivity == true
end

local function getTeamInfo(player)
	return {
		teamKey = player:GetAttribute("USARF_TeamKey"),
		teamName = player and player:GetAttribute("USARF_TeamName")
			or (player.Team and player.Team.Name)
			or "Unknown",
	}
end

local function startSession(player)
	local teamInfo = getTeamInfo(player)

	if not shouldTrackTeam(teamInfo.teamKey) then
		activeSessions[player] = nil
		return
	end

	activeSessions[player] = {
		userId = player.UserId,
		username = player.Name,
		displayName = player.DisplayName,

		teamKey = teamInfo.teamKey,
		teamName = teamInfo.teamName,

		startedAt = now(),
	}
end

local function endSession(player, reason)
	local session = activeSessions[player]

	if not session then
		return nil
	end

	activeSessions[player] = nil

	session.endedAt = now()
	session.duration = session.endedAt - session.startedAt
	session.reason = reason or "Unknown"

	if session.duration < MIN_SESSION_SECONDS then
		return nil
	end

	table.insert(completedSessions, session)
	ActivityExportService.QueueSession(session)
	
	AuditService.Log({
		category = "Activity",
		action = "TeamSessionEnded",
		actor = player,
		message = string.format(
			"%s served on %s for %d seconds.",
			player.Name,
			session.teamName,
			session.duration
		),
		severity = "Info",
		external = false,
		metadata = session,
	})

	print(
		string.format(
			"[ActivityService] %s | %s | %ds | %s",
			session.username,
			session.teamName,
			session.duration,
			session.reason
		)
	)

	return session
end

function ActivityService.RefreshPlayer(player, reason)
	endSession(player, reason or "Refresh")
	startSession(player)
end

function ActivityService.GetActiveSession(player)
	return activeSessions[player]
end

function ActivityService.GetCompletedSessions()
	local copy = {}

	for index, session in ipairs(completedSessions) do
		copy[index] = session
	end

	return copy
end

function ActivityService.GetPlayerCompletedSessions(userId)
	local results = {}

	for _, session in ipairs(completedSessions) do
		if session.userId == userId then
			table.insert(results, session)
		end
	end

	return results
end

function ActivityService.GetMinimumSessionSeconds()
	return MIN_SESSION_SECONDS
end

GetActivitySessionRemote.OnServerInvoke = function(player)
	local session = ActivityService.GetActiveSession(player)

	if not session then
		return {
			tracking = false,
			minSessionSeconds = MIN_SESSION_SECONDS,
		}
	end

	return {
		tracking = true,
		startedAt = session.startedAt,
		teamKey = session.teamKey,
		teamName = session.teamName,
		minSessionSeconds = MIN_SESSION_SECONDS,
	}
end

Players.PlayerAdded:Connect(function(player)
	player:GetAttributeChangedSignal("USARF_TeamKey"):Connect(function()
		ActivityService.RefreshPlayer(player, "TeamKeyChanged")
	end)

	player:GetAttributeChangedSignal("USARF_TeamName"):Connect(function()
		ActivityService.RefreshPlayer(player, "TeamNameChanged")
	end)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		task.wait(0.2)
		ActivityService.RefreshPlayer(player, "RobloxTeamChanged")
	end)

	task.delay(2, function()
		if player.Parent then
			startSession(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	endSession(player, "PlayerLeft")
	activeSessions[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.defer(function()
		startSession(player)
	end)
end

print("USARF ActivityService initialized")

return ActivityService