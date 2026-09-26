local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AnnouncementService = {}

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")
local ServerConfig = USARFServer:WaitForChild("Config")

local FacilityStatusService = require(
	Services:WaitForChild("FacilityStatusService")
)

local AnnouncementCommandConfig = require(
	ServerConfig:WaitForChild("AnnouncementCommandConfig")
)

local CmdrPermissionService = nil
pcall(function()
	CmdrPermissionService = require(
		Services:WaitForChild("CmdrPermissionService")
	)
end)

local RadioService = nil
pcall(function()
	RadioService = require(Services:WaitForChild("RadioService"))
end)

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local REMOTE_NAME = "AnnouncementBannerRemote"

local profileCache = {}
local profileLastFetch = 0
local receivedGlobalIds = {}
local subscription = nil
local started = false

local function getOrCreateRemote()
	local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = REMOTE_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	local remote = folder:FindFirstChild(REMOTE_NAME)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = REMOTE_NAME
		remote.Parent = folder
	end

	return remote
end

local bannerRemote = getOrCreateRemote()

local function trimText(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeKey(value)
	return string.lower(trimText(value):gsub("%s+", ""):gsub(":", ""))
end

local function getRowValue(row, keys)
	for _, key in ipairs(keys) do
		if row[key] ~= nil then
			return row[key]
		end
	end

	for rowKey, value in pairs(row) do
		local normalizedRowKey = normalizeKey(rowKey)

		for _, wantedKey in ipairs(keys) do
			if normalizedRowKey == normalizeKey(wantedKey) then
				return value
			end
		end
	end

	return nil
end

local function safeRank(player, groupId)
	local success, result = pcall(function()
		return player:GetRankInGroup(groupId)
	end)

	if not success then
		return 0
	end

	return result or 0
end

local function fetchProfileCache()
	local sheetConfig = AnnouncementCommandConfig.GoogleSheets

	if not sheetConfig or sheetConfig.Enabled ~= true then
		return
	end

	if not sheetConfig.Url or sheetConfig.Url == "" then
		return
	end

	local cacheSeconds = sheetConfig.CacheSeconds or 60

	if os.time() - profileLastFetch < cacheSeconds then
		return
	end

	profileLastFetch = os.time()

	local success, result = pcall(function()
		return HttpService:GetAsync(sheetConfig.Url)
	end)

	if not success then
		warn("[AnnouncementService] Failed to fetch rank sheet:", result)
		return
	end

	local decodedSuccess, decoded = pcall(function()
		return HttpService:JSONDecode(result)
	end)

	if not decodedSuccess or type(decoded) ~= "table" then
		warn("[AnnouncementService] Invalid rank sheet JSON.")
		return
	end

	local newCache = {}

	for _, row in ipairs(decoded) do
		local userId = tonumber(getRowValue(row, {
			"RobloxUserId",
			"robloxUserId",
			"Roblox UserId",
			"Roblox UserID",
			"UserId",
			"userId",
			"UserID",
		}))

		if userId then
			newCache[userId] = {
				username = trimText(getRowValue(row, {
					"Username",
					"username",
					"RobloxUsername",
					"robloxUsername",
					"Roblox Username",
				})),

				global = trimText(getRowValue(row, {
					"GlobalRankTitle",
					"globalRankTitle",
					"Global Rank Title",
					"global rank title",
					"Global",
					"global",
				})),

				moderation = trimText(getRowValue(row, {
					"ModerationRankTitle",
					"moderationRankTitle",
					"Moderation Rank Title",
					"moderation rank title",
					"Moderation",
					"moderation",
				})),

				developer = trimText(getRowValue(row, {
					"DeveloperRankTitle",
					"developerRankTitle",
					"Developer Rank Title",
					"developer rank title",
					"Developer",
					"developer",
				})),

				enabled = getRowValue(row, {
					"Enabled",
					"enabled",
					"Active",
					"active",
				}),
			}
		end
	end

	profileCache = newCache
end

local function getSheetTitle(player, scope)
	fetchProfileCache()

	local profile = profileCache[player.UserId]

	if not profile then
		return nil
	end

	local enabledRaw = profile.enabled

	if enabledRaw ~= nil and enabledRaw ~= "" then
		local enabledText = string.lower(tostring(enabledRaw))

		if enabledRaw == false
			or enabledText == "false"
			or enabledText == "0"
			or enabledText == "no"
		then
			return nil
		end
	end

	if scope == "moderation" and profile.moderation ~= "" then
		return profile.moderation
	end

	if scope == "developer" and profile.developer ~= "" then
		return profile.developer
	end

	if profile.global ~= "" then
		return profile.global
	end

	return nil
end

local function getFallbackTitle(player)
	local attr = player:GetAttribute("USARF_RankName")

	if attr and attr ~= "" then
		return tostring(attr)
	end

	local success, result = pcall(function()
		return player:GetRoleInGroup(
			AnnouncementCommandConfig.GROUP_MAIN
		)
	end)

	if success and result and result ~= "" and result ~= "Guest" then
		return result
	end

	return "Personnel"
end

local function getSenderTitle(player, scope)
	if not player then
		return "SYSTEM"
	end

	local sheetTitle = getSheetTitle(player, scope)

	if sheetTitle and sheetTitle ~= "" then
		return sheetTitle
	end

	return getFallbackTitle(player)
end

local function hasExactRankAccess(player, scope)
	local scopeRanks = AnnouncementCommandConfig.AllowedRanks[scope]

	if not scopeRanks then
		return false
	end

	for groupId, ranks in pairs(scopeRanks) do
		local rank = safeRank(player, groupId)

		if ranks[rank] == true then
			return true
		end
	end

	return false
end

function AnnouncementService.CanSendScope(player, scope)
	scope = string.lower(tostring(scope or ""))

	if not player then
		return true
	end

	if hasExactRankAccess(player, scope) then
		return true
	end

	if CmdrPermissionService then
		local _, levelValue =
			CmdrPermissionService.GetAdminLevel(player)

		local required =
			AnnouncementCommandConfig.ScopeMinimumAdminLevel[scope]

		if required and levelValue >= required then
			return true
		end
	end

	return false, "You do not have permission to send this announcement scope."
end

function AnnouncementService.CanUseSystemMask(player)
	if not player then
		return true
	end

	local rank = safeRank(
		player,
		AnnouncementCommandConfig.GROUP_MAIN
	)

	return AnnouncementCommandConfig.MaskAllowedRanks[rank] == true
end

local function getRecipients(scope, teamName)
	local recipients = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local team = player.Team

		if scope == "team" then
			if team and team.Name == teamName then
				table.insert(recipients, player)
			end
		elseif scope == "facility" then
			if team and team:GetAttribute("isFacility") == true then
				table.insert(recipients, player)
			end
		elseif scope == "security" then
			if team and team:GetAttribute("isSecurity") == true then
				table.insert(recipients, player)
			end
		else
			table.insert(recipients, player)
		end
	end

	return recipients
end

local function sendBanner(playersList, payload)
	for _, player in ipairs(playersList) do
		bannerRemote:FireClient(player, payload)
	end
end

local function colorToArray(color)
	return { color.R, color.G, color.B }
end

local function buildPayload(scope, message, senderText, id)
	local style =
		AnnouncementCommandConfig.ScopeStyle[scope]
		or AnnouncementCommandConfig.ScopeStyle.server

	return {
		id = id
			or (
				"announcement_"
				.. tostring(os.time())
				.. "_"
				.. tostring(math.random(1000, 9999))
			),
		scope = scope,
		icon = style.Icon,
		title = style.DisplayName .. " from " .. senderText,
		body = message,
		sender = senderText,
		category = style.DisplayName,
		createdAt = os.time(),
		color = colorToArray(style.Color),
	}
end

local function postLocalSideEffects(payload, sendToAlerts, teamName)
	if sendToAlerts == true and RadioService then
		if payload.scope == "team" then
			RadioService.System(
				"alerts",
				"[TEAM: "
					.. tostring(teamName)
					.. "] "
					.. payload.title
					.. ": "
					.. payload.body
			)
		else
			RadioService.System(
				"alerts",
				payload.title .. ": " .. payload.body
			)
		end
	end

	FacilityStatusService.SetLastEvent(
		payload.title .. ": " .. payload.body
	)
end

function AnnouncementService.SendScoped(
	executor,
	scope,
	message,
	systemMask,
	teamName,
	sendToAlerts
)
	scope = string.lower(tostring(scope or "server"))
	message = trimText(message)

	if scope == "global" then
		return false, "Use the globalannounce command for cross-server announcements."
	end

	if message == "" then
		return false, "Message cannot be empty."
	end

	local allowed, reason =
		AnnouncementService.CanSendScope(executor, scope)

	if not allowed then
		return false, reason
	end

	if scope == "team" and (not teamName or teamName == "") then
		return false, "Team is required when scope is team."
	end

	local useSystem =
		systemMask == true
		and AnnouncementService.CanUseSystemMask(executor)

	local senderText = "SYSTEM"

	if not useSystem and executor then
		senderText =
			getSenderTitle(executor, scope)
			.. " "
			.. executor.Name
	end

	local payload =
		buildPayload(scope, message, senderText)

	sendBanner(getRecipients(scope, teamName), payload)
	postLocalSideEffects(payload, sendToAlerts, teamName)

	print("[Announcement]", scope, payload.title, message)

	return true, payload
end

local function cleanReceivedIds()
	local cutoff =
		os.time()
	- (
		AnnouncementCommandConfig.GlobalDedupeSeconds
			or 120
	)

	for messageId, receivedAt in pairs(receivedGlobalIds) do
		if receivedAt < cutoff then
			receivedGlobalIds[messageId] = nil
		end
	end
end

local function handleGlobalMessage(message)
	local data = message and message.Data

	if type(data) ~= "table" then
		return
	end

	if data.version
		~= AnnouncementCommandConfig.GlobalMessageVersion
	then
		return
	end

	if type(data.id) ~= "string"
		or type(data.body) ~= "string"
		or type(data.sender) ~= "string"
	then
		return
	end

	cleanReceivedIds()

	if receivedGlobalIds[data.id] then
		return
	end

	receivedGlobalIds[data.id] = os.time()

	local payload =
		buildPayload("global", data.body, data.sender, data.id)

	payload.createdAt = tonumber(data.createdAt) or os.time()

	sendBanner(Players:GetPlayers(), payload)
	postLocalSideEffects(payload, data.sendToAlerts == true, nil)

	print("[GlobalAnnouncement]", payload.title, payload.body)
end

function AnnouncementService.SendGlobal(
	executor,
	message,
	systemMask,
	sendToAlerts
)
	message = trimText(message)

	if message == "" then
		return false, "Message cannot be empty."
	end

	local allowed, reason =
		AnnouncementService.CanSendScope(executor, "global")

	if not allowed then
		return false, reason
	end

	local useSystem =
		systemMask == true
		and AnnouncementService.CanUseSystemMask(executor)

	local senderText = "SYSTEM"

	if not useSystem and executor then
		senderText =
			getSenderTitle(executor, "global")
			.. " "
			.. executor.Name
	end

	local messageId =
		"global_"
		.. tostring(os.time())
		.. "_"
		.. HttpService:GenerateGUID(false)

	local packet = {
		version =
			AnnouncementCommandConfig.GlobalMessageVersion,
		id = messageId,
		body = message,
		sender = senderText,
		sendToAlerts = sendToAlerts == true,
		createdAt = os.time(),
		originJobId = game.JobId,
	}

	local success, publishError = pcall(function()
		MessagingService:PublishAsync(
			AnnouncementCommandConfig.GlobalTopic,
			packet
		)
	end)

	if not success then
		warn(
			"[AnnouncementService] Global publish failed:",
			publishError
		)

		return false, "Global announcement could not be published: " .. tostring(publishError)
	end

	return true, packet
end

function AnnouncementService.Broadcast(data)
	data = data or {}

	return AnnouncementService.SendScoped(
		nil,
		"server",
		tostring(data.Message or ""),
		true,
		nil,
		false
	)
end

function AnnouncementService.SendToTeam(teamName, data)
	data = data or {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == teamName then
			bannerRemote:FireClient(player, {
				icon = "📣",
				title = data.Title or "Department Alert",
				body = data.Message or "",
				color = { 0, 0.78, 0.54 },
				scope = "team",
			})
		end
	end
end

function AnnouncementService.SendToTeams(teamNames, data)
	if typeof(teamNames) ~= "table" then
		return
	end

	local lookup = {}

	for _, name in ipairs(teamNames) do
		lookup[name] = true
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team and lookup[player.Team.Name] then
			bannerRemote:FireClient(player, {
				icon = "📣",
				title = data.Title or "Department Alert",
				body = data.Message or "",
				color = { 0, 0.78, 0.54 },
				scope = "team",
			})
		end
	end
end

function AnnouncementService.Start()
	if started then
		return true
	end

	local success, result = pcall(function()
		return MessagingService:SubscribeAsync(
			AnnouncementCommandConfig.GlobalTopic,
			handleGlobalMessage
		)
	end)

	if not success then
		warn(
			"[AnnouncementService] Global subscription failed:",
			result
		)

		return false
	end

	subscription = result
	started = true

	print("[AnnouncementService] Global subscription active")
	return true
end

function AnnouncementService.Stop()
	if subscription then
		subscription:Disconnect()
		subscription = nil
	end

	started = false
end

task.defer(function()
	AnnouncementService.Start()
end)

return AnnouncementService
