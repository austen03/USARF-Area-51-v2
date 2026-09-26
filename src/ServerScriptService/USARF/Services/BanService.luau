local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local AuditService = require(Services:WaitForChild("AuditService"))
local CaseIdService = require(Services:WaitForChild("CaseIdService"))

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

local BanStore = DataStoreService:GetDataStore("USARF_Bans_v1")

local BanService = {}

local function parseDuration(duration)
	if typeof(duration) == "number" then
		if duration == 0 then
			return -1
		end

		return math.floor(duration)
	end

	duration = string.lower(tostring(duration or "perm")):gsub("%s+", "")

	if duration == "0" or duration == "perm" or duration == "permanent" then
		return -1
	end

	local number, unit = string.match(duration, "^(%d+)([mhdw])$")
	number = tonumber(number)

	if not number or not unit then
		return -1
	end

	if unit == "m" then
		return number * 60
	elseif unit == "h" then
		return number * 3600
	elseif unit == "d" then
		return number * 86400
	elseif unit == "w" then
		return number * 604800
	end

	return -1
end

local function getDurationText(durationSeconds)
	if durationSeconds == -1 then
		return "Permanent"
	end

	if durationSeconds % 604800 == 0 then
		return tostring(durationSeconds / 604800) .. " week(s)"
	elseif durationSeconds % 86400 == 0 then
		return tostring(durationSeconds / 86400) .. " day(s)"
	elseif durationSeconds % 3600 == 0 then
		return tostring(durationSeconds / 3600) .. " hour(s)"
	elseif durationSeconds % 60 == 0 then
		return tostring(durationSeconds / 60) .. " minute(s)"
	end

	return tostring(durationSeconds) .. " second(s)"
end

local function getExpiresAt(durationSeconds)
	if durationSeconds == -1 then
		return nil
	end

	return os.time() + durationSeconds
end

local function buildKickMessage(reason, caseId, durationText)
	return "You have been banned from USARF Area-51.\n\n"
		.. "Reason: "
		.. tostring(reason)
		.. "\nDuration: "
		.. tostring(durationText)
		.. "\nCase: "
		.. tostring(caseId)
end

local function sendStaffBanAlert(userId, player, reason, durationText, caseId)
	if not StaffAlertRadioService then
		return
	end

	local label = player and player.Name or tostring(userId or "Unknown")

	pcall(function()
		StaffAlertRadioService.GameBan(
			label,
			tostring(reason or "No reason provided.") .. " | Duration: " .. tostring(durationText or "Unknown") .. " | Case: " .. tostring(caseId or "N/A")
		)
	end)
end

local function sendBotBanEvent(record, player)
	if not DiscordBotBridge then
		return
	end

	pcall(function()
		DiscordBotBridge.SendEvent("game.ban", {
			caseId = record.caseId,
			createdAt = record.createdAt,

			robloxUserId = tostring(record.userId),
			robloxUsername = player and player.Name or nil,
			displayName = player and player.DisplayName or nil,
			teamName = player and player.Team and player.Team.Name or nil,

			reason = record.reason,
			duration = record.duration,
			durationText = record.durationText,
			permanent = record.permanent,
			expiresAt = record.expiresAt,

			source = record.source,
			moderatorUserId = tostring(record.moderatorUserId or 0),
			moderatorName = record.moderatorName,

			robloxBanSuccess = record.robloxBanSuccess,
			robloxBanError = record.robloxBanError,
		})
	end)

	pcall(function()
		if player then
			DiscordBotBridge.SubmitModeration(
				"ban",
				player,
				nil,
				record.reason,
				record.durationText
			)
		end
	end)
end

function BanService.BanUser(data)
	data = data or {}

	local userId = tonumber(data.userId or (data.player and data.player.UserId))

	if not userId then
		return false, "Missing userId"
	end

	local caseId = data.caseId or CaseIdService.Generate()
	local reason = tostring(data.reason or "No reason provided.")
	local durationSeconds = parseDuration(data.duration)
	local durationText = getDurationText(durationSeconds)
	local moderator = data.moderator

	local displayReason = reason
	if #displayReason > 400 then
		displayReason = string.sub(displayReason, 1, 400)
	end

	local privateReason = "[" .. tostring(caseId) .. "] " .. reason
	if #privateReason > 1000 then
		privateReason = string.sub(privateReason, 1, 1000)
	end

	local record = {
		userId = userId,
		caseId = caseId,
		reason = reason,
		duration = durationSeconds,
		durationText = durationText,
		permanent = durationSeconds == -1,
		expiresAt = getExpiresAt(durationSeconds),
		source = data.source or "System",
		createdAt = os.time(),
		moderatorUserId = moderator and moderator.UserId or tonumber(data.moderatorUserId) or 0,
		moderatorName = moderator and moderator.Name or tostring(data.moderatorName or "System"),
		active = true,

		robloxBanApi = true,
		applyToUniverse = data.applyToUniverse ~= false,
		excludeAltAccounts = data.excludeAltAccounts == true,
		applyDeviceBlock = data.applyDeviceBlock ~= false,
	}

	local saveSuccess, saveError = pcall(function()
		BanStore:SetAsync(tostring(userId), record)
	end)

	if not saveSuccess then
		warn("[BanService] DataStore save failed:", saveError)
		return false, saveError
	end

	local banSuccess, banError = pcall(function()
		Players:BanAsync({
			UserIds = { userId },
			Duration = durationSeconds,
			DisplayReason = displayReason,
			PrivateReason = privateReason,

			ApplyToUniverse = record.applyToUniverse,
			ExcludeAltAccounts = record.excludeAltAccounts,
			ApplyDeviceBlock = record.applyDeviceBlock,
		})
	end)

	record.robloxBanSuccess = banSuccess == true
	record.robloxBanError = if banSuccess then nil else tostring(banError)

	pcall(function()
		BanStore:SetAsync(tostring(userId), record)
	end)

	if not banSuccess then
		warn("[BanService] Roblox BanAsync failed:", banError)
	end

	AuditService.Log({
		caseId = caseId,
		category = "Moderation",
		action = "Ban",
		actor = moderator,
		target = data.player,
		message = "User banned: " .. tostring(userId),
		reason = reason,
		severity = "Critical",
		external = data.external == true,
		metadata = record,
	})

	sendStaffBanAlert(userId, data.player, reason, durationText, caseId)
	sendBotBanEvent(record, data.player)

	if data.player then
		data.player:Kick(buildKickMessage(reason, caseId, durationText))
	end

	return true, record
end

function BanService.BanPlayer(userId, reason, duration, moderatorUserId, caseId)
	local player = Players:GetPlayerByUserId(tonumber(userId) or 0)

	return BanService.BanUser({
		userId = userId,
		player = player,
		reason = reason,
		duration = duration,
		caseId = caseId,
		moderatorUserId = moderatorUserId,
		moderatorName = "Cmdr",
		source = "Cmdr",
		applyToUniverse = true,
		excludeAltAccounts = false,
		applyDeviceBlock = true,
	})
end

function BanService.Ban(userId, reason, duration, moderatorUserId, caseId)
	return BanService.BanPlayer(userId, reason, duration, moderatorUserId, caseId)
end

function BanService.UnbanUser(data)
	data = data or {}

	local userId = tonumber(data.userId)

	if not userId then
		return false, "Missing userId"
	end

	local caseId = data.caseId or CaseIdService.Generate()
	local reason = tostring(data.reason or "Unbanned.")

	local record
	pcall(function()
		record = BanStore:GetAsync(tostring(userId))
	end)

	if record then
		record.active = false
		record.unbannedAt = os.time()
		record.unbanReason = reason
		record.unbannedByUserId = data.moderator and data.moderator.UserId or tonumber(data.moderatorUserId) or 0
		record.unbannedByName = data.moderator and data.moderator.Name or tostring(data.moderatorName or "System")
	end

	pcall(function()
		BanStore:SetAsync(tostring(userId), record or {
			userId = userId,
			caseId = caseId,
			active = false,
			unbannedAt = os.time(),
			unbanReason = reason,
			unbannedByUserId = data.moderator and data.moderator.UserId or tonumber(data.moderatorUserId) or 0,
			unbannedByName = data.moderator and data.moderator.Name or tostring(data.moderatorName or "System"),
		})
	end)

	local unbanSuccess, unbanError = pcall(function()
		Players:UnbanAsync({
			UserIds = { userId },
			ApplyToUniverse = data.applyToUniverse ~= false,
		})
	end)

	if not unbanSuccess then
		warn("[BanService] Roblox UnbanAsync failed:", unbanError)
	end

	AuditService.Log({
		caseId = caseId,
		category = "Moderation",
		action = "Unban",
		actor = data.moderator,
		message = "User unbanned: " .. tostring(userId),
		reason = reason,
		severity = "Info",
		metadata = {
			userId = userId,
			reason = reason,
			robloxUnbanSuccess = unbanSuccess == true,
			robloxUnbanError = if unbanSuccess then nil else tostring(unbanError),
		},
	})

	if DiscordBotBridge then
		pcall(function()
			DiscordBotBridge.SendEvent("game.unban", {
				caseId = caseId,
				robloxUserId = tostring(userId),
				reason = reason,
				robloxUnbanSuccess = unbanSuccess == true,
				robloxUnbanError = if unbanSuccess then nil else tostring(unbanError),
			})
		end)
	end

	return true, record
end

function BanService.UnbanPlayer(userId, moderatorUserId, reason)
	return BanService.UnbanUser({
		userId = userId,
		reason = reason,
		moderatorUserId = moderatorUserId,
		moderatorName = "Cmdr",
		applyToUniverse = true,
	})
end

function BanService.Unban(userId, moderatorUserId, reason)
	return BanService.UnbanPlayer(userId, moderatorUserId, reason)
end

function BanService.GetBanRecord(userId)
	local record

	local success, result = pcall(function()
		return BanStore:GetAsync(tostring(userId))
	end)

	if success then
		record = result
	end

	return record
end

local function isBanStillActive(record)
	if not record or record.active ~= true then
		return false
	end

	if record.expiresAt and record.expiresAt <= os.time() then
		return false
	end

	return true
end

Players.PlayerAdded:Connect(function(player)
	local record = BanService.GetBanRecord(player.UserId)

	if isBanStillActive(record) then
		player:Kick(buildKickMessage(
			record.reason or "You are banned from this experience.",
			record.caseId or "N/A",
			record.durationText or getDurationText(record.duration or -1)
			))
	end
end)

print("USARF BanService initialized")

return BanService