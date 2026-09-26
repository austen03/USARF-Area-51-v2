local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local StaffAlertRemote = Remotes:WaitForChild("StaffAlert")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local AuditService = require(Services:WaitForChild("AuditService"))
local CaseIdService = require(Services:WaitForChild("CaseIdService"))
local RadioConfig = require(USARF.Config.RadioConfig)

local StaffAlertService = {}

local MAX_RECENT_ALERTS = 100
local recentAlerts = {}

local function safeGetRank(player, groupId)
	local success, result = pcall(function()
		return player:GetRankInGroup(groupId)
	end)

	if not success then
		return 0
	end

	return result or 0
end

local function canReceiveStaffAlert(player)
	local mainRank = safeGetRank(player, RadioConfig.MainGroupId)
	local modRank = safeGetRank(player, RadioConfig.ModGroupId)

	return mainRank >= 18
		or modRank == 2
		or modRank >= 7
end

local function trimRecentAlerts()
	while #recentAlerts > MAX_RECENT_ALERTS do
		table.remove(recentAlerts, 1)
	end
end

function StaffAlertService.CanReceive(player)
	return canReceiveStaffAlert(player)
end

function StaffAlertService.Send(data)
	data = data or {}

	local caseId = data.caseId or CaseIdService.Generate()

	local payload = {
		caseId = caseId,
		title = data.title or "Staff Alert",
		message = data.message or "No message provided.",
		severity = data.severity or "Info",
		category = data.category or "Staff",
		createdAt = os.time(),

		targetUserId = data.target and data.target.UserId or data.targetUserId,
		targetName = data.target and data.target.Name or data.targetName,
	}

	table.insert(recentAlerts, 1, payload)
	trimRecentAlerts()

	AuditService.Log({
		caseId = caseId,
		category = payload.category,
		action = "StaffAlert",
		target = data.target,
		message = payload.title .. " - " .. payload.message,
		severity = payload.severity,
		metadata = payload,
	})

	for _, player in ipairs(Players:GetPlayers()) do
		if canReceiveStaffAlert(player) then
			StaffAlertRemote:FireClient(player, payload)
		end
	end

	print("[StaffAlertService]", payload.severity, payload.title, payload.message, payload.caseId)

	return payload
end

function StaffAlertService.GetRecentAlerts(player)
	if player and not canReceiveStaffAlert(player) then
		return {}
	end

	local copy = {}

	for index, alert in ipairs(recentAlerts) do
		copy[index] = alert
	end

	return copy
end

return StaffAlertService