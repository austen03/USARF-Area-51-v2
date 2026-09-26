local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local SuspensionService = require(
	Services:WaitForChild("SuspensionService")
)

local DiscordBotBridge = require(
	Services:WaitForChild("DiscordBotBridge")
)

local BanService = nil

pcall(function()
	BanService = require(
		Services:WaitForChild("BanService")
	)
end)

local ModerationCaseService = {}

local MAIN_GROUP_ID = 6033326
local MOD_GROUP_ID = 8647541

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local MODERATION_FOLDER_NAME = "Moderation"
local MOD_UTILITY_REMOTE_NAME = "ModerationUtilityRemote"

local CASE_STORE_NAME = "USARF_Cases_v1"
local WARNING_STORE_NAME = "USARF_Warnings_v1"
local SUSPENSION_STORE_NAME = "USARF_Suspensions_v1"
local BAN_STORE_NAME = "USARF_Bans_v1"
local PROFILE_STORE_NAME = "USARF_ModerationProfile_v1"
local CASE_INDEX_STORE_NAME = "USARF_CaseIndex_v1"

local MAX_RECORDS_PER_USER = 100

local STATUS_ACTIVE = "Active"
local STATUS_VOID = "Void"
local STATUS_REVOKED = "Revoked"
local STATUS_EXPIRED = "Expired"

local started = false

local CaseStore = DataStoreService:GetDataStore(
	CASE_STORE_NAME
)

local WarningStore = DataStoreService:GetDataStore(
	WARNING_STORE_NAME
)

local SuspensionRecordStore = DataStoreService:GetDataStore(
	SUSPENSION_STORE_NAME
)

local BanStore = DataStoreService:GetDataStore(
	BAN_STORE_NAME
)

local ProfileStore = DataStoreService:GetDataStore(
	PROFILE_STORE_NAME
)

local CaseIndexStore = DataStoreService:GetDataStore(
	CASE_INDEX_STORE_NAME
)

local TEAM_NAME_TO_KEY = {
	["Facility Personnel"] = "FacilityPersonnel",
	["Engineering & Technical"] = "EngineeringTechnical",
	["Medical Division"] = "MedicalDivision",
	["Research Division"] = "ResearchDivision",
	["Rules & Regulations"] = "RulesRegulations",
	["United States Air Force"] = "UnitedStatesAirForce",
	["Department of Defense"] = "DepartmentOfDefense",

	["108th Infantry Regiment"] = "Infantry108",
	["137th Military Police Company"] = "MP137",
	["1st Spec. Ops. A.I.G"] = "SpecOpsAIG",
	["Secret Service"] = "SecretService",

	["Central Intelligence Agency"] = "CentralIntelligenceAgency",
	["Federal Bureau of Investigation"] = "FederalBureauInvestigation",
	["Federal Defense Service"] = "FederalDefenseService",

	["Federal Administration"] = "FederalAdministration",
	["President of the United States"] = "President",
	["Vice President of the United States"] = "VicePresident",
	["Presidential Cabinet"] = "PresidentialCabinet",
}

local AREA_NAME_TO_KEY = {
	["Civil Departments"] = "civil",
	["Combative Departments"] = "combative",
	["Intelligence Departments"] = "intelligence",
	["Protection Departments"] = "facility",
	["Leadership Departments"] = "facility",
}

local DURATION_SECONDS = {
	["1h"] = 3600,
	["6h"] = 21600,
	["12h"] = 43200,
	["1d"] = 86400,
	["3d"] = 259200,
	["7d"] = 604800,
	["14d"] = 1209600,
	["30d"] = 2592000,

	["Permanent"] = 0,
	["permanent"] = 0,
	["perm"] = 0,
	["0"] = 0,
}

local function now()
	return os.time()
end

local function clean(value)
	return tostring(value or "")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
end

local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end

	return folder
end

local function getOrCreateRemoteEvent(parent, name)
	local remote = parent:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = parent
	end

	return remote
end

local function getOrCreateRemoteFunction(parent, name)
	local remote = parent:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = parent
	end

	return remote
end

local RemotesFolder = getOrCreateFolder(
	ReplicatedStorage,
	REMOTE_FOLDER_NAME
)

local ModerationFolder = getOrCreateFolder(
	RemotesFolder,
	MODERATION_FOLDER_NAME
)

local OpenCaseFunction = getOrCreateRemoteFunction(
	ModerationFolder,
	"OpenCase"
)

local SubmitGameWarnEvent = getOrCreateRemoteEvent(
	ModerationFolder,
	"SubmitGameWarn"
)

local SubmitTeamSuspensionEvent = getOrCreateRemoteEvent(
	ModerationFolder,
	"SubmitTeamSuspension"
)

local SubmitGameBanEvent = getOrCreateRemoteEvent(
	ModerationFolder,
	"SubmitGameBan"
)

local ModerationNotifyEvent = getOrCreateRemoteEvent(
	ModerationFolder,
	"ModerationNotify"
)

local MenuRefreshRemote = getOrCreateRemoteEvent(
	RemotesFolder,
	"ModerationMenuRefresh"
)

local ModerationUtilityRemote = RemotesFolder:FindFirstChild(
	MOD_UTILITY_REMOTE_NAME
)

local function isModerator(player)
	if not player then
		return false
	end

	local mainRank = 0
	local modRank = 0

	pcall(function()
		mainRank = player:GetRankInGroup(
			MAIN_GROUP_ID
		)
	end)

	pcall(function()
		modRank = player:GetRankInGroup(
			MOD_GROUP_ID
		)
	end)

	return mainRank >= 18 or modRank >= 2
end

local function getPlayerByUserId(userId)
	userId = tonumber(userId)

	if not userId then
		return nil
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == userId then
			return player
		end
	end

	return nil
end

local function generateLegacyCaseId(prefix)
	local guid = HttpService:GenerateGUID(false)
	local short = string.upper(
		string.sub(guid, 1, 8)
	)

	return "USARF-"
		.. tostring(prefix or "CASE")
		.. "-"
		.. short
end

local function getUserKey(userId)
	return "USER_" .. tostring(userId)
end

local function getCaseKey(caseId)
	return "CASE_" .. tostring(caseId)
end

local function readList(store, userId)
	local success, result = pcall(function()
		return store:GetAsync(
			getUserKey(userId)
		)
	end)

	if success and type(result) == "table" then
		return result
	end

	return {}
end

local function writeList(store, userId, list)
	local success, result = pcall(function()
		store:SetAsync(
			getUserKey(userId),
			list
		)
	end)

	if not success then
		warn(
			"[ModerationCaseService] Failed to write list:",
			result
		)
	end

	return success
end

local function addToStore(store, userId, data)
	local success, result = pcall(function()
		return store:UpdateAsync(
			getUserKey(userId),
			function(old)
				old = type(old) == "table"
					and old
					or {}

				table.insert(old, 1, data)

				while #old > MAX_RECORDS_PER_USER do
					table.remove(old)
				end

				return old
			end
		)
	end)

	if not success then
		warn(
			"[ModerationCaseService] Failed to save record:",
			result
		)
	end

	return success
end

local function readProfile(userId)
	local success, result = pcall(function()
		return ProfileStore:GetAsync(
			getUserKey(userId)
		)
	end)

	if success and type(result) == "table" then
		return result
	end

	return {
		totalWarnings = 0,
		totalSuspensions = 0,
		totalBans = 0,
		totalCases = 0,
		lastAction = 0,
		activeSuspensions = {},
		activeCases = {},
	}
end

local function indexCase(caseData)
	if not caseData or not caseData.caseId then
		return false
	end

	local success, result = pcall(function()
		CaseIndexStore:SetAsync(
			getCaseKey(caseData.caseId),
			{
				caseId = caseData.caseId,
				targetUserId = caseData.targetUserId,
				type = caseData.type,
				store = caseData.type,
				createdAt = caseData.createdAt or now(),
			}
		)
	end)

	if not success then
		warn(
			"[ModerationCaseService] Failed to index case:",
			result
		)
	end

	return success
end

local function updateProfile(
	userId,
	actionType,
	caseData
)
	local success, result = pcall(function()
		return ProfileStore:UpdateAsync(
			getUserKey(userId),
			function(old)
				old = type(old) == "table"
					and old
					or {}

				old.totalWarnings =
					tonumber(old.totalWarnings) or 0

				old.totalSuspensions =
					tonumber(old.totalSuspensions) or 0

				old.totalBans =
					tonumber(old.totalBans) or 0

				old.totalCases =
					tonumber(old.totalCases) or 0

				old.activeSuspensions =
					type(old.activeSuspensions) == "table"
					and old.activeSuspensions
					or {}

				old.activeCases =
					type(old.activeCases) == "table"
					and old.activeCases
					or {}

				if actionType == "Game Warn" then
					old.totalWarnings += 1
					old.totalCases += 1

				elseif actionType == "Team Suspension" then
					old.totalSuspensions += 1
					old.totalCases += 1

					table.insert(
						old.activeSuspensions,
						1,
						{
							caseId = caseData.caseId,
							status = caseData.status,
							duration = caseData.duration,
							affectedTargets =
								caseData.affectedTargets,
							createdAt = caseData.createdAt,
							expiresAt = caseData.expiresAt,
						}
					)

				elseif actionType == "Game Ban" then
					old.totalBans += 1
					old.totalCases += 1
				end

				while #old.activeSuspensions > 25 do
					table.remove(old.activeSuspensions)
				end

				while #old.activeCases > 25 do
					table.remove(old.activeCases)
				end

				old.lastAction = now()

				return old
			end
		)
	end)

	if not success then
		warn(
			"[ModerationCaseService] Failed to update profile:",
			result
		)
	end
end

local function notifyStaff(
	player,
	title,
	message
)
	if not player then
		return
	end

	ModerationNotifyEvent:FireClient(
		player,
		{
			title = title,
			message = message,
		}
	)
end

local function refreshMenu(player, openMenu)
	if not player then
		return
	end

	MenuRefreshRemote:FireClient(
		player,
		{
			action = openMenu
				and "OpenMenu"
				or "RefreshMenu",

			reason = "ModerationUpdated",
		}
	)
end

local function forcePlayerToMenu(player)
	if not player then
		return
	end

	local loadingTeam = Teams:FindFirstChild(
		"Loading"
	)

	if loadingTeam then
		player.Team = loadingTeam
	end

	player:SetAttribute(
		"USARF_InMenu",
		true
	)

	player:SetAttribute(
		"USARF_TeamKey",
		nil
	)

	player:SetAttribute(
		"USARF_TeamName",
		""
	)

	player:SetAttribute(
		"USARF_SpawnKey",
		nil
	)

	refreshMenu(player, true)
end

local function sendWarnPopup(
	targetPlayer,
	payload
)
	if not targetPlayer then
		return
	end

	if ModerationUtilityRemote then
		ModerationUtilityRemote:FireClient(
			targetPlayer,
			"WarnPopup",
			payload
		)
	else
		ModerationNotifyEvent:FireClient(
			targetPlayer,
			{
				title = "Game Warning",

				message =
					"Reason: "
					.. tostring(
						payload.reason
						or "No reason provided."
					)
					.. "\nCase ID: "
					.. tostring(
						payload.caseId
						or "N/A"
					),
			}
		)
	end
end

local function parseDuration(duration)
	duration = clean(duration)

	if duration == "" then
		return nil
	end

	if DURATION_SECONDS[duration] ~= nil then
		return DURATION_SECONDS[duration]
	end

	local lowered = string.lower(duration)
		:gsub("%s+", "")

	if lowered == "permanent"
		or lowered == "perm"
		or lowered == "0"
	then
		return 0
	end

	local number, unit = string.match(
		lowered,
		"^(%d+)([mhdw])$"
	)

	number = tonumber(number)

	if not number or not unit then
		return nil
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

	return nil
end

local function getExpiresAt(
	createdAt,
	duration
)
	local seconds = parseDuration(duration)

	if not seconds or seconds <= 0 then
		return nil
	end

	return createdAt + seconds
end

local function getModerationHistory(userId)
	return {
		profile = readProfile(userId),
		warnings = readList(
			WarningStore,
			userId
		),
		teamSuspensions = SuspensionService.GetHistory(
			userId
		),
		activeSuspensions = SuspensionService.GetActiveSuspensions(
			userId
		),
		gameBans = readList(
			BanStore,
			userId
		),
		cases = readList(
			CaseStore,
			userId
		),
	}
end

local function applySuspension(
	targetUserId,
	actorUserId,
	suspensionType,
	affectedTargets,
	reason,
	duration
)
	local durationSeconds = parseDuration(duration)

	if durationSeconds == nil then
		return {}
	end

	local results = {}

	if suspensionType == "Team" then
		for _, targetName in ipairs(affectedTargets) do
			local teamKey =
				TEAM_NAME_TO_KEY[targetName]
				or targetName

			local success, result =
				SuspensionService.SuspendDepartment(
					targetUserId,
					teamKey,
					actorUserId,
					reason,
					durationSeconds
				)

			table.insert(results, {
				target = targetName,
				teamKey = teamKey,
				success = success,
				caseId = type(result) == "table"
					and result.caseId
					or nil,
				result = result,
			})
		end

	elseif suspensionType == "Area" then
		for _, targetName in ipairs(affectedTargets) do
			local areaKey =
				AREA_NAME_TO_KEY[targetName]

			local success
			local result

			if areaKey == "facility" then
				success, result =
					SuspensionService.SuspendFacility(
						targetUserId,
						actorUserId,
						reason,
						durationSeconds
					)
			elseif areaKey then
				success, result =
					SuspensionService.SuspendArea(
						targetUserId,
						areaKey,
						actorUserId,
						reason,
						durationSeconds
					)
			else
				success = false
				result = "Unknown area target."
			end

			table.insert(results, {
				target = targetName,
				areaKey = areaKey,
				success = success,
				caseId = type(result) == "table"
					and result.caseId
					or nil,
				result = result,
			})
		end

	elseif suspensionType == "Facility" then
		local success, result =
			SuspensionService.SuspendFacility(
				targetUserId,
				actorUserId,
				reason,
				durationSeconds
			)

		table.insert(results, {
			target = "Entire Facility",
			success = success,
			caseId = type(result) == "table"
				and result.caseId
				or nil,
			result = result,
		})
	end

	return results
end

local function anySuspensionSucceeded(results)
	for _, item in ipairs(results or {}) do
		if item.success == true then
			return true
		end
	end

	return false
end

local function getFirstSuccessfulSuspensionCaseId(
	results
)
	for _, item in ipairs(results or {}) do
		if item.success == true and item.caseId then
			return item.caseId
		end
	end

	return nil
end

local function shouldForceTargetToMenu(
	targetPlayer
)
	if not targetPlayer then
		return false
	end

	local currentTeamKey = targetPlayer:GetAttribute(
		"USARF_TeamKey"
	)

	if not currentTeamKey then
		return true
	end

	local check =
		SuspensionService.IsSuspendedFromTeam(
			targetPlayer.UserId,
			currentTeamKey
		)

	return check and check.suspended == true
end

function ModerationCaseService.GenerateCaseId(prefix)
	return generateLegacyCaseId(
		prefix or "CASE"
	)
end

function ModerationCaseService.GetModerationHistory(
	userId
)
	return getModerationHistory(userId)
end

function ModerationCaseService.GetPlayerCases(userId)
	userId = tonumber(userId)

	if not userId then
		return {}
	end

	return readList(
		CaseStore,
		userId
	)
end

function ModerationCaseService.CreateWarning(
	actor,
	targetPlayer,
	reason,
	parentCaseNumber
)
	if not actor or not targetPlayer then
		return false, "Missing actor or target."
	end

	reason = clean(reason)

	if reason == "" then
		return false, "Reason cannot be empty."
	end

	local legacyCaseId =
		generateLegacyCaseId("WARN")

	local createdAt = now()

	local caseData = {
		caseId = legacyCaseId,
		parentCaseNumber = parentCaseNumber,

		type = "Game Warn",

		targetUsername = targetPlayer.Name,
		targetUserId = targetPlayer.UserId,

		moderator = actor.Name,
		moderatorUserId = actor.UserId,

		reason = reason,
		status = STATUS_ACTIVE,

		createdAt = createdAt,
		updatedAt = createdAt,
		timestamp = createdAt,
	}

	addToStore(
		WarningStore,
		targetPlayer.UserId,
		caseData
	)

	addToStore(
		CaseStore,
		targetPlayer.UserId,
		caseData
	)

	indexCase(caseData)

	updateProfile(
		targetPlayer.UserId,
		"Game Warn",
		caseData
	)

	sendWarnPopup(
		targetPlayer,
		{
			title = "⚠ GAME WARNING",
			time = createdAt,
			reason = reason,
			caseId = parentCaseNumber
				or legacyCaseId,
			issuer = actor.Name,
		}
	)

	local bridgeSuccess, bridgeError =
		DiscordBotBridge.SubmitModeration(
			"warn",
			targetPlayer,
			actor,
			reason,
			nil,
			parentCaseNumber,
			{
				notifyPlayer = false,
			}
		)

	if not bridgeSuccess then
		warn(
			"[ModerationCaseService] Failed to queue warning bridge:",
			bridgeError
		)
	end

	return true, caseData
end

function ModerationCaseService.CreateBan(
	actor,
	targetPlayer,
	duration,
	reason,
	parentCaseNumber
)
	if not actor or not targetPlayer then
		return false, "Missing actor or target."
	end

	duration = clean(duration)
	reason = clean(reason)

	if duration == "" or reason == "" then
		return false, "Duration and reason are required."
	end

	local durationSeconds = parseDuration(duration)

	if durationSeconds == nil then
		return false, "Invalid duration."
	end

	local legacyCaseId =
		generateLegacyCaseId("BAN")

	local createdAt = now()
	local expiresAt = getExpiresAt(
		createdAt,
		duration
	)

	local caseData = {
		caseId = legacyCaseId,
		parentCaseNumber = parentCaseNumber,

		type = "Game Ban",

		targetUsername = targetPlayer.Name,
		targetUserId = targetPlayer.UserId,

		moderator = actor.Name,
		moderatorUserId = actor.UserId,

		duration = duration,
		durationSeconds = durationSeconds,

		reason = reason,
		status = STATUS_ACTIVE,

		createdAt = createdAt,
		updatedAt = createdAt,
		timestamp = createdAt,
		expiresAt = expiresAt,
	}

	addToStore(
		BanStore,
		targetPlayer.UserId,
		caseData
	)

	addToStore(
		CaseStore,
		targetPlayer.UserId,
		caseData
	)

	indexCase(caseData)

	updateProfile(
		targetPlayer.UserId,
		"Game Ban",
		caseData
	)

	local bridgeSuccess, bridgeError =
		DiscordBotBridge.SubmitModeration(
			"ban",
			targetPlayer,
			actor,
			reason,
			duration,
			parentCaseNumber,
			{
				notifyPlayer = false,
				immediateRemoval = false,
			}
		)

	if not bridgeSuccess then
		warn(
			"[ModerationCaseService] Failed to queue ban bridge:",
			bridgeError
		)
	end

	if BanService then
		if typeof(BanService.BanPlayer) == "function" then
			pcall(function()
				BanService.BanPlayer(
					targetPlayer.UserId,
					reason,
					duration,
					actor.UserId,
					parentCaseNumber
						or legacyCaseId
				)
			end)
		elseif typeof(BanService.Ban) == "function" then
			pcall(function()
				BanService.Ban(
					targetPlayer.UserId,
					reason,
					duration,
					actor.UserId,
					parentCaseNumber
						or legacyCaseId
				)
			end)
		end
	end

	targetPlayer:Kick(
		"You have been banned from USARF.\n\nDuration: "
			.. duration
			.. "\nReason: "
			.. reason
			.. "\nCase ID: "
			.. tostring(
				parentCaseNumber
				or legacyCaseId
			)
	)

	return true, caseData
end

function ModerationCaseService.UnbanUser(
	actor,
	userId,
	reason
)
	userId = tonumber(userId)

	if not userId then
		return false, "Invalid user ID."
	end

	reason = clean(
		reason ~= nil
			and reason
			or "Unbanned by administrator."
	)

	if BanService then
		if typeof(BanService.UnbanPlayer) == "function" then
			pcall(function()
				BanService.UnbanPlayer(
					userId,
					actor and actor.UserId or 0,
					reason
				)
			end)
		elseif typeof(BanService.Unban) == "function" then
			pcall(function()
				BanService.Unban(
					userId,
					actor and actor.UserId or 0,
					reason
				)
			end)
		end
	end

	local caseRecords = readList(
		CaseStore,
		userId
	)

	for index, record in ipairs(caseRecords) do
		if record.type == "Game Ban"
			and record.status == STATUS_ACTIVE
		then
			record.status = STATUS_REVOKED
			record.revoked = true
			record.revokedAt = now()
			record.revokedBy =
				actor and actor.Name or "System"
			record.revokedByUserId =
				actor and actor.UserId or 0
			record.revocationReason = reason
			record.updatedAt = now()

			caseRecords[index] = record
		end
	end

	writeList(
		CaseStore,
		userId,
		caseRecords
	)

	local banRecords = readList(
		BanStore,
		userId
	)

	for index, record in ipairs(banRecords) do
		if record.status == STATUS_ACTIVE then
			record.status = STATUS_REVOKED
			record.revoked = true
			record.revokedAt = now()
			record.revokedBy =
				actor and actor.Name or "System"
			record.revokedByUserId =
				actor and actor.UserId or 0
			record.revocationReason = reason
			record.updatedAt = now()

			banRecords[index] = record
		end
	end

	writeList(
		BanStore,
		userId,
		banRecords
	)

	return true, "Unban processed."
end

function ModerationCaseService.CreateSystemBan(
	targetPlayer,
	duration,
	reason,
	source,
	metadata
)
	if not targetPlayer then
		return false, "Missing target."
	end

	duration = clean(
		duration ~= nil
			and duration
			or "Permanent"
	)

	reason = clean(
		reason ~= nil
			and reason
			or "No reason provided."
	)

	source = clean(
		source ~= nil
			and source
			or "System"
	)

	local caseId =
		generateLegacyCaseId("BAN")

	local createdAt = now()
	local expiresAt = getExpiresAt(
		createdAt,
		duration
	)

	local caseData = {
		caseId = caseId,
		type = "Game Ban",

		targetUsername = targetPlayer.Name,
		targetUserId = targetPlayer.UserId,

		moderator = source,
		moderatorUserId = 0,

		duration = duration,
		reason = reason,

		status = STATUS_ACTIVE,

		createdAt = createdAt,
		updatedAt = createdAt,
		timestamp = createdAt,
		expiresAt = expiresAt,

		source = source,
		systemGenerated = true,
		metadata = metadata or {},
	}

	addToStore(
		BanStore,
		targetPlayer.UserId,
		caseData
	)

	addToStore(
		CaseStore,
		targetPlayer.UserId,
		caseData
	)

	indexCase(caseData)

	updateProfile(
		targetPlayer.UserId,
		"Game Ban",
		caseData
	)

	DiscordBotBridge.SubmitModeration(
		"ban",
		targetPlayer,
		nil,
		reason,
		duration,
		nil,
		{
			notifyPlayer = false,
			immediateRemoval = false,
			internalNotes = source,
		}
	)

	if BanService then
		pcall(function()
			if typeof(BanService.BanUser) == "function" then
				BanService.BanUser({
					userId = targetPlayer.UserId,
					player = targetPlayer,
					reason = reason,
					duration = duration,
					caseId = caseId,
					moderatorName = source,
					moderatorUserId = 0,
					source = source,
					external = true,
					applyToUniverse = true,
					excludeAltAccounts = false,
					applyDeviceBlock = true,
				})
			end
		end)
	end

	return true, caseData
end

function ModerationCaseService.CreateSystemWarning(
	targetUserId,
	targetUsername,
	reason,
	source
)
	targetUserId = tonumber(targetUserId)

	if not targetUserId then
		return false, "Invalid target user ID."
	end

	targetUsername = clean(
		targetUsername ~= nil
			and targetUsername
			or "Unknown"
	)

	reason = clean(
		reason ~= nil
			and reason
			or "No reason provided."
	)

	source = clean(
		source ~= nil
			and source
			or "System"
	)

	local caseId =
		generateLegacyCaseId("WARN")

	local createdAt = now()

	local caseData = {
		caseId = caseId,
		type = "Game Warn",

		targetUsername = targetUsername,
		targetUserId = targetUserId,

		moderator = source,
		moderatorUserId = 0,

		reason = reason,
		status = STATUS_ACTIVE,

		createdAt = createdAt,
		updatedAt = createdAt,
		timestamp = createdAt,

		source = source,
		systemGenerated = true,
	}

	addToStore(
		WarningStore,
		targetUserId,
		caseData
	)

	addToStore(
		CaseStore,
		targetUserId,
		caseData
	)

	indexCase(caseData)

	updateProfile(
		targetUserId,
		"Game Warn",
		caseData
	)

	return true, caseData
end

local function handleOpenCase(
	actor,
	targetUserId,
	notes
)
	if not isModerator(actor) then
		return {
			success = false,
			message =
				"You do not have permission to open moderation cases.",
		}
	end

	targetUserId = tonumber(targetUserId)

	if not targetUserId then
		return {
			success = false,
			message = "Invalid target user.",
		}
	end

	local targetPlayer = getPlayerByUserId(
		targetUserId
	)

	if not targetPlayer then
		return {
			success = false,
			message =
				"The target player is no longer online.",
		}
	end

	if targetPlayer == actor then
		return {
			success = false,
			message =
				"You cannot open a moderation case against yourself.",
		}
	end

	local bridgeSuccess, bridgeResult =
		DiscordBotBridge.OpenCase(
			targetPlayer,
			actor,
			targetPlayer.Team
			and targetPlayer.Team.Name
			or "Unknown",
			notes
		)

	if not bridgeSuccess then
		local failureMessage =
			type(bridgeResult) == "table"
			and bridgeResult.message
			or tostring(
				bridgeResult
				or "The Discord case could not be opened."
			)

		warn(
			"[ModerationCaseService] Open case failed:",
			actor.Name,
			targetPlayer.Name,
			failureMessage
		)

		return {
			success = false,
			message = failureMessage,
		}
	end

	local caseNumber =
		bridgeResult.caseNumber
		or bridgeResult.caseId
		or "Unknown"

	return {
		success = true,

		created = bridgeResult.created == true,
		duplicate = bridgeResult.duplicate == true,

		gameCaseId = bridgeResult.gameCaseId,

		caseId = caseNumber,
		caseNumber = caseNumber,

		caseReference =
			bridgeResult.caseReference,

		discordChannelId =
			bridgeResult.discordChannelId,

		username = targetPlayer.Name,
		displayName = targetPlayer.DisplayName,
		userId = targetPlayer.UserId,

		message =
			bridgeResult.message
			or (
				"Case "
				.. tostring(caseNumber)
				.. " was opened successfully."
			),
	}
end

function ModerationCaseService.Start()
	if started then
		return
	end

	started = true

	OpenCaseFunction.OnServerInvoke = function(
		actor,
		targetUserId,
		notes
	)
		return handleOpenCase(
			actor,
			targetUserId,
			notes
		)
	end

	SubmitGameWarnEvent.OnServerEvent:Connect(
		function(
			actor,
			targetUserId,
			reason,
			parentCaseNumber
		)
			if not isModerator(actor) then
				return
			end

			targetUserId = tonumber(targetUserId)
			reason = clean(reason)
			parentCaseNumber = clean(
				parentCaseNumber
			)

			if not targetUserId or reason == "" then
				return
			end

			local targetPlayer =
				getPlayerByUserId(
					targetUserId
				)

			if not targetPlayer then
				notifyStaff(
					actor,
					"Warning Failed",
					"Target player is no longer online."
				)

				return
			end

			local success, result =
				ModerationCaseService.CreateWarning(
					actor,
					targetPlayer,
					reason,
					parentCaseNumber ~= ""
					and parentCaseNumber
					or nil
				)

			if not success then
				notifyStaff(
					actor,
					"Warning Failed",
					tostring(result)
				)

				return
			end

			notifyStaff(
				actor,
				"Game Warning Sent",
				"Warning sent to "
					.. targetPlayer.Name
					.. ".\nCase ID: "
					.. tostring(
						parentCaseNumber ~= ""
						and parentCaseNumber
						or result.caseId
					)
			)
		end
	)

	SubmitTeamSuspensionEvent.OnServerEvent:Connect(
		function(
			actor,
			targetUserId,
			suspensionType,
			affectedTargets,
			duration,
			reason,
			parentCaseNumber
		)
			if not isModerator(actor) then
				return
			end

			targetUserId = tonumber(targetUserId)
			suspensionType = clean(suspensionType)
			duration = clean(duration)
			reason = clean(reason)
			parentCaseNumber = clean(
				parentCaseNumber
			)

			if type(affectedTargets) ~= "table" then
				affectedTargets = {}
			end

			if not targetUserId
				or suspensionType == ""
				or duration == ""
				or reason == ""
				or #affectedTargets <= 0
			then
				return
			end

			if parseDuration(duration) == nil then
				notifyStaff(
					actor,
					"Suspension Failed",
					"Invalid suspension duration."
				)

				return
			end

			local suspensionResults =
				applySuspension(
					targetUserId,
					actor.UserId,
					suspensionType,
					affectedTargets,
					reason,
					duration
				)

			if not anySuspensionSucceeded(
				suspensionResults
				) then
				notifyStaff(
					actor,
					"Suspension Failed",
					"No suspension targets were successfully applied."
				)

				return
			end

			local targetPlayer =
				getPlayerByUserId(
					targetUserId
				)

			local targetUsername =
				targetPlayer
				and targetPlayer.Name
				or "Unknown"

			local createdAt = now()
			local expiresAt = getExpiresAt(
				createdAt,
				duration
			)

			local localCaseId =
				getFirstSuccessfulSuspensionCaseId(
					suspensionResults
				)
				or generateLegacyCaseId("SUSP")

			local caseData = {
				caseId = localCaseId,
				parentCaseNumber =
					parentCaseNumber ~= ""
					and parentCaseNumber
					or nil,

				type = "Team Suspension",

				targetUsername = targetUsername,
				targetUserId = targetUserId,

				moderator = actor.Name,
				moderatorUserId = actor.UserId,

				suspensionType = suspensionType,
				affectedTargets = affectedTargets,

				duration = duration,
				reason = reason,

				status = STATUS_ACTIVE,

				createdAt = createdAt,
				updatedAt = createdAt,
				timestamp = createdAt,
				expiresAt = expiresAt,

				enforcementResults =
					suspensionResults,
			}

			addToStore(
				SuspensionRecordStore,
				targetUserId,
				caseData
			)

			addToStore(
				CaseStore,
				targetUserId,
				caseData
			)

			indexCase(caseData)

			updateProfile(
				targetUserId,
				"Team Suspension",
				caseData
			)

			if targetPlayer then
				for _, targetName in ipairs(
					affectedTargets
					) do
					local scopeType = "team"

					if suspensionType == "Area" then
						scopeType = "category"
					elseif suspensionType == "Facility" then
						scopeType = "facility"
					end

					DiscordBotBridge.SubmitSuspension(
						targetPlayer,
						actor,
						targetName,
						reason,
						duration,
						parentCaseNumber ~= ""
							and parentCaseNumber
							or nil,
						{
							suspensionType =
								scopeType,

							scopeType =
								scopeType,

							scopeValue =
								targetName,

							scopeDisplay =
								targetName,

							notifyPlayer = false,
						}
					)
				end

				ModerationNotifyEvent:FireClient(
					targetPlayer,
					{
						title = "Team Suspension",

						message =
							"Type: "
							.. suspensionType
							.. "\nDuration: "
							.. duration
							.. "\nReason: "
							.. reason
							.. "\nCase ID: "
							.. tostring(
								parentCaseNumber ~= ""
								and parentCaseNumber
								or localCaseId
							),
					}
				)

				if shouldForceTargetToMenu(
					targetPlayer
					) then
					forcePlayerToMenu(
						targetPlayer
					)
				else
					refreshMenu(
						targetPlayer,
						false
					)
				end
			end

			refreshMenu(actor, false)

			notifyStaff(
				actor,
				"Team Suspension Created",
				"Suspension created for "
					.. targetUsername
					.. ".\nCase ID: "
					.. tostring(
						parentCaseNumber ~= ""
						and parentCaseNumber
						or localCaseId
					)
			)
		end
	)

	SubmitGameBanEvent.OnServerEvent:Connect(
		function(
			actor,
			targetUserId,
			duration,
			reason,
			parentCaseNumber
		)
			if not isModerator(actor) then
				return
			end

			targetUserId = tonumber(targetUserId)
			duration = clean(duration)
			reason = clean(reason)
			parentCaseNumber = clean(
				parentCaseNumber
			)

			if not targetUserId
				or duration == ""
				or reason == ""
			then
				return
			end

			local targetPlayer =
				getPlayerByUserId(
					targetUserId
				)

			if not targetPlayer then
				notifyStaff(
					actor,
					"Game Ban Failed",
					"Target player is no longer online."
				)

				return
			end

			local success, result =
				ModerationCaseService.CreateBan(
					actor,
					targetPlayer,
					duration,
					reason,
					parentCaseNumber ~= ""
					and parentCaseNumber
					or nil
				)

			if not success then
				notifyStaff(
					actor,
					"Game Ban Failed",
					tostring(result)
				)

				return
			end

			notifyStaff(
				actor,
				"Game Ban Created",
				"Ban created for "
					.. targetPlayer.Name
					.. ".\nCase ID: "
					.. tostring(
						parentCaseNumber ~= ""
						and parentCaseNumber
						or result.caseId
					)
			)
		end
	)

	print(
		"[ModerationCaseService] Started"
	)
end

return ModerationCaseService