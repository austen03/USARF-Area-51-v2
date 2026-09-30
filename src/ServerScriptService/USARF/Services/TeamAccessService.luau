local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local PermissionService = require(Services:WaitForChild("PermissionService"))
local SuspensionService = require(Services:WaitForChild("SuspensionService"))
local RankService = require(Services:WaitForChild("RankService"))
local EventServerService = require(Services:WaitForChild("EventServerService"))

local TeamAccessService = {}

local TEAM_SORT_ORDER = {
	TestSubject = 1,
	PMC = 2,

	FacilityPersonnel = 10,
	EngineeringTechnical = 11,
	MedicalDivision = 12,
	ResearchDivision = 13,
	RulesRegulations = 14,
	UnitedStatesAirForce = 15,
	DepartmentOfDefense = 16,
	EXTECH = 17,

	Infantry108 = 20,
	MP137 = 21,
	SpecOpsAIG = 22,
	SecretService = 23,

	CentralIntelligenceAgency = 30,
	FederalBureauInvestigation = 31,
	FederalDefenseService = 32,

	FederalAdministration = 40,
	President = 41,
	VicePresident = 42,
	PresidentialCabinet = 43,
}

local AREA_DISPLAY_NAMES = {
	civil = "Civil Departments",
	combative = "Combative Departments",
	intelligence = "Intelligence Departments",
	protection = "Protection Departments",
	facility = "Facility Wide",
}

local SCOPE_ALIASES = {
	["facility"] = "facility",
	["facility wide"] = "facility",
	["entire facility"] = "facility",
	["facility access"] = "facility",

	["category"] = "category",
	["area"] = "category",

	["department"] = "department",
	["division"] = "department",

	["team"] = "team",
}

local function clean(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function lower(value)
	return string.lower(clean(value))
end

local function getOnlineCount(teamData)
	if not teamData or not teamData.teamName then
		return 0
	end

	local count = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == teamData.teamName then
			count += 1
		end
	end

	return count
end

local function normalizeUnixTimestamp(value)
	if value == nil then
		return nil
	end

	if typeof(value) == "number" then
		if value > 0 then
			return math.floor(value)
		end

		return nil
	end

	local numericValue = tonumber(value)

	if numericValue and numericValue > 0 then
		return math.floor(numericValue)
	end

	return nil
end

local function decodeExternalSuspensions(player)
	if not player then
		return {}
	end

	local encoded = player:GetAttribute("USARF_ExternalSuspensionsJson")

	if typeof(encoded) == "string" and encoded ~= "" then
		local success, decoded = pcall(function()
			return HttpService:JSONDecode(encoded)
		end)

		if success and typeof(decoded) == "table" then
			return decoded
		end
	end

	-- Backward-compatible fallback for servers still using the
	-- original single-suspension attributes.
	if player:GetAttribute("USARF_ExternalSuspended") == true then
		return {
			{
				caseId = player:GetAttribute("USARF_ExternalSuspensionCase"),

				sanctionId = player:GetAttribute("USARF_ExternalSuspensionSanction"),

				scopeType = player:GetAttribute("USARF_ExternalSuspensionScopeType"),

				scopeValue = player:GetAttribute("USARF_ExternalSuspensionScopeValue"),

				scopeDisplay = player:GetAttribute("USARF_ExternalSuspensionScopeDisplay")
					or player:GetAttribute("USARF_ExternalSuspensionScope"),

				reason = player:GetAttribute("USARF_ExternalSuspensionReason"),

				durationSeconds = player:GetAttribute("USARF_ExternalSuspensionDurationSeconds"),

				expiresAt = player:GetAttribute("USARF_ExternalSuspensionExpiresAt"),

				state = "active",
				external = true,
			},
		}
	end

	return {}
end

local function normalizeScopeType(record)
	local scopeType = lower(record.scopeType or record.scope_type or record.type)

	if SCOPE_ALIASES[scopeType] then
		return SCOPE_ALIASES[scopeType]
	end

	local sanctionType = lower(record.sanctionType or record.sanction_type or record.actionType or record.action_type)

	if string.find(sanctionType, "facility", 1, true) then
		return "facility"
	end

	if string.find(sanctionType, "category", 1, true) or string.find(sanctionType, "area", 1, true) then
		return "category"
	end

	if string.find(sanctionType, "department", 1, true) or string.find(sanctionType, "division", 1, true) then
		return "department"
	end

	if string.find(sanctionType, "team", 1, true) then
		return "team"
	end

	local scopeValue = lower(record.scopeValue or record.scope_value or record.scope)

	if SCOPE_ALIASES[scopeValue] then
		return SCOPE_ALIASES[scopeValue]
	end

	return "team"
end

local function normalizeExternalRecord(rawRecord)
	local expiresAt = normalizeUnixTimestamp(rawRecord.expiresAt or rawRecord.expires_at)

	local startsAt =
		normalizeUnixTimestamp(rawRecord.startsAt or rawRecord.starts_at or rawRecord.createdAt or rawRecord.created_at)

	local durationSeconds = tonumber(rawRecord.durationSeconds or rawRecord.duration_seconds)

	local state = lower(rawRecord.state or rawRecord.status or "active")

	if state == "voided" then
		state = "void"
	end

	if expiresAt and expiresAt <= os.time() then
		state = "expired"
	end

	return {
		caseId = clean(
			rawRecord.caseNumber
				or rawRecord.case_number
				or rawRecord.caseId
				or rawRecord.case_id
				or rawRecord.caseRef
				or rawRecord.case_ref
		),

		caseReference = clean(
			rawRecord.caseReference or rawRecord.case_reference or rawRecord.caseRef or rawRecord.case_ref
		),

		sanctionId = clean(rawRecord.sanctionId or rawRecord.sanction_id),

		scopeType = normalizeScopeType(rawRecord),

		scopeValue = clean(rawRecord.scopeValue or rawRecord.scope_value or rawRecord.scope),

		scopeDisplay = clean(
			rawRecord.scopeDisplay
				or rawRecord.scope_display
				or rawRecord.targetName
				or rawRecord.target_name
				or rawRecord.scopeValue
				or rawRecord.scope_value
				or rawRecord.scope
		),

		reason = clean(rawRecord.reason or "External team suspension."),

		state = state,

		durationSeconds = durationSeconds,
		startsAt = startsAt,
		expiresAt = expiresAt,

		external = true,
	}
end

local function isRecordActive(record)
	if not record then
		return false
	end

	local state = lower(record.state)

	if state == "expired" or state == "revoked" or state == "void" or state == "inactive" then
		return false
	end

	if record.expiresAt and record.expiresAt <= os.time() then
		return false
	end

	return true
end

local function valuesMatch(left, right)
	left = lower(left)
	right = lower(right)

	return left ~= "" and right ~= "" and left == right
end

local function getTeamAliases(teamKey, teamData)
	local aliases = {
		lower(teamKey),
		lower(teamData and teamData.teamName),
		lower(teamData and teamData.displayName),
		lower(teamData and teamData.spawnKey),
	}

	return aliases
end

local function recordMatchesTeam(record, teamKey, teamData)
	if not record or not teamData then
		return false
	end

	if not SuspensionService.IsTeamSuspendable(teamKey) then
		return false
	end

	local scopeType = record.scopeType
	local scopeValue = record.scopeValue
	local scopeDisplay = record.scopeDisplay

	if scopeType == "facility" then
		return true
	end

	if scopeType == "category" then
		local category = clean(teamData.category)
		local suspensionGroup = clean(teamData.suspensionGroup)

		return valuesMatch(scopeValue, category)
			or valuesMatch(scopeDisplay, category)
			or valuesMatch(scopeValue, suspensionGroup)
			or valuesMatch(scopeDisplay, suspensionGroup)
			or valuesMatch(scopeDisplay, AREA_DISPLAY_NAMES[category])
			or valuesMatch(scopeDisplay, AREA_DISPLAY_NAMES[suspensionGroup])
	end

	local teamAliases = getTeamAliases(teamKey, teamData)

	for _, alias in ipairs(teamAliases) do
		if alias ~= "" then
			if alias == lower(scopeValue) or alias == lower(scopeDisplay) then
				return true
			end
		end
	end

	-- Some Discord suspensions may be labeled "department" even though
	-- they target one configured Roblox team.
	if scopeType == "department" or scopeType == "team" then
		local resolvedKey = TeamAccessService.ResolveTeamKey(scopeValue)

		if not resolvedKey then
			resolvedKey = TeamAccessService.ResolveTeamKey(scopeDisplay)
		end

		if resolvedKey and resolvedKey == teamKey then
			return true
		end
	end

	return false
end

local function getScopeDisplayName(record, teamKey, teamData)
	if record.scopeDisplay ~= "" then
		return record.scopeDisplay
	end

	if record.scopeType == "facility" then
		return "Facility Wide"
	end

	if record.scopeType == "category" then
		local category = lower(record.scopeValue)

		return AREA_DISPLAY_NAMES[category] or record.scopeValue or "Department Category"
	end

	if teamData then
		return teamData.displayName or teamData.teamName or teamKey
	end

	return record.scopeValue ~= "" and record.scopeValue or "External Suspension"
end

local function getExternalSuspensionResult(player, teamKey, teamData)
	local rawRecords = decodeExternalSuspensions(player)

	for _, rawRecord in ipairs(rawRecords) do
		local record = normalizeExternalRecord(rawRecord)

		if isRecordActive(record) and recordMatchesTeam(record, teamKey, teamData) then
			local scopeDisplay = getScopeDisplayName(record, teamKey, teamData)

			return {
				suspended = true,
				scope = record.scopeType,
				scopeName = scopeDisplay,

				caseId = record.caseId ~= "" and record.caseId or nil,

				caseReference = record.caseReference ~= "" and record.caseReference or nil,

				sanctionId = record.sanctionId ~= "" and record.sanctionId or nil,

				reason = record.reason,

				record = {
					caseId = record.caseId ~= "" and record.caseId or nil,

					caseReference = record.caseReference ~= "" and record.caseReference or nil,

					sanctionId = record.sanctionId ~= "" and record.sanctionId or nil,

					reason = record.reason,

					scope = record.scopeType,
					scopeType = record.scopeType,
					scopeValue = record.scopeValue,
					scopeDisplay = scopeDisplay,
					targetName = scopeDisplay,

					state = "Active",
					active = true,
					external = true,

					durationSeconds = record.durationSeconds,

					startsAt = record.startsAt,
					expiresAt = record.expiresAt,
				},
			}
		end
	end

	return nil
end

local function formatSuspensionText(suspensionResult)
	if not suspensionResult or not suspensionResult.suspended then
		return nil
	end

	local record = suspensionResult.record or {}
	local lines = {
		"Active " .. clean(suspensionResult.scopeName or "Suspension"),
	}

	if suspensionResult.caseId then
		table.insert(lines, "Case: " .. tostring(suspensionResult.caseId))
	end

	if suspensionResult.sanctionId then
		table.insert(lines, "Sanction: " .. tostring(suspensionResult.sanctionId))
	end

	if suspensionResult.reason then
		table.insert(lines, "Reason: " .. tostring(suspensionResult.reason))
	end

	if record.expiresAt then
		table.insert(lines, "Expires: " .. os.date("%m/%d/%Y %I:%M %p", record.expiresAt))
	else
		table.insert(lines, "Expires: Permanent")
	end

	return table.concat(lines, "\n")
end

function TeamAccessService.GetTeam(teamKey)
	return PermissionService.GetTeam(teamKey)
end

function TeamAccessService.ResolveTeamKey(teamNameOrKey)
	local value = clean(teamNameOrKey)

	if value == "" then
		return nil
	end

	local teams = PermissionService.GetAllTeams()

	if teams[value] then
		return value
	end

	local config = nil

	pcall(function()
		config = require(
			game:GetService("ReplicatedStorage")
				:WaitForChild("USARF")
				:WaitForChild("Config")
				:WaitForChild("USARFConfig")
		)
	end)

	if config and config.TeamAliases and config.TeamAliases[value] then
		return config.TeamAliases[value]
	end

	for teamKey, teamData in pairs(teams) do
		if
			valuesMatch(teamData.teamName, value)
			or valuesMatch(teamData.displayName, value)
			or valuesMatch(teamData.spawnKey, value)
		then
			return teamKey
		end
	end

	return nil
end

function TeamAccessService.GetExternalSuspensions(player)
	local results = {}

	for _, rawRecord in ipairs(decodeExternalSuspensions(player)) do
		local record = normalizeExternalRecord(rawRecord)

		if isRecordActive(record) then
			table.insert(results, record)
		end
	end

	return results
end

function TeamAccessService.GetExternalSuspensionForTeam(player, teamKey)
	local teamData = PermissionService.GetTeam(teamKey)

	if not teamData then
		return nil
	end

	return getExternalSuspensionResult(player, teamKey, teamData)
end

function TeamAccessService.CanPlayerUseTeam(player, teamKey)
	local permissionResult = PermissionService.CanAccessTeam(player, teamKey)

	local teamData = permissionResult.teamData or PermissionService.GetTeam(teamKey)

	local rankName = RankService.GetDisplayRankForTeam(player, teamKey)

	local onlineCount = getOnlineCount(teamData)
	local sortOrder = TEAM_SORT_ORDER[teamKey] or 999

	if not permissionResult.canAccess then
		return {
			canAccess = false,
			status = "denied",

			reason = permissionResult.reason,
			requiredText = permissionResult.requiredText,

			rankName = rankName,
			teamKey = teamKey,
			teamData = teamData,

			permission = permissionResult,
			suspension = nil,

			onlineCount = onlineCount,
			sortOrder = sortOrder,
		}
	end

	local eventLockAllowed, eventLockReason = EventServerService.GetTeamLockAccess(player, teamKey)

	if not eventLockAllowed then
		return {
			canAccess = false,
			status = "event_locked",

			reason = eventLockReason,
			requiredText = "EVENT LOCKED\nOnly Event Administrators, Developers, and Owners may deploy.",

			rankName = rankName,
			teamKey = teamKey,
			teamData = teamData,

			permission = permissionResult,
			suspension = nil,
			eventLocked = true,

			onlineCount = onlineCount,
			sortOrder = sortOrder,
		}
	end

	local suspensionResult = SuspensionService.IsSuspendedFromTeam(player.UserId, teamKey)

	if not suspensionResult.suspended then
		local externalSuspension = getExternalSuspensionResult(player, teamKey, teamData)

		if externalSuspension then
			suspensionResult = externalSuspension
		end
	end

	if suspensionResult.suspended then
		return {
			canAccess = false,
			status = "suspended",

			reason = suspensionResult.reason or "Suspended",

			requiredText = formatSuspensionText(suspensionResult),

			rankName = rankName,
			teamKey = teamKey,
			teamData = teamData,

			permission = permissionResult,
			suspension = suspensionResult,

			onlineCount = onlineCount,
			sortOrder = sortOrder,
		}
	end

	return {
		canAccess = true,
		status = "granted",

		reason = "Access Granted",
		requiredText = permissionResult.requiredText,

		rankName = rankName,
		teamKey = teamKey,
		teamData = teamData,

		permission = permissionResult,
		suspension = nil,

		onlineCount = onlineCount,
		sortOrder = sortOrder,
	}
end

function TeamAccessService.GetPlayerTeamAccessList(player)
	local teams = PermissionService.GetAllTeams()
	local accessList = {}

	for teamKey in pairs(teams) do
		accessList[teamKey] = TeamAccessService.CanPlayerUseTeam(player, teamKey)
	end

	return accessList
end

function TeamAccessService.GetPlayerTeamsByCategory(player)
	local categories = PermissionService.GetCategories()
	local teams = PermissionService.GetAllTeams()

	local grouped = {}

	for _, category in ipairs(categories) do
		grouped[category.key] = {
			category = category,
			teams = {},
		}
	end

	for teamKey, teamData in pairs(teams) do
		if not teamData.hidden then
			local access = TeamAccessService.CanPlayerUseTeam(player, teamKey)

			local categoryGroup = grouped[teamData.category]

			if categoryGroup then
				table.insert(categoryGroup.teams, {
					teamKey = teamKey,
					teamData = teamData,
					access = access,

					onlineCount = access.onlineCount or 0,

					sortOrder = access.sortOrder or TEAM_SORT_ORDER[teamKey] or 999,
				})
			end
		end
	end

	for _, group in pairs(grouped) do
		table.sort(group.teams, function(a, b)
			local aOrder = a.sortOrder or 999
			local bOrder = b.sortOrder or 999

			if aOrder ~= bOrder then
				return aOrder < bOrder
			end

			local aName = a.teamData and a.teamData.displayName or a.teamKey

			local bName = b.teamData and b.teamData.displayName or b.teamKey

			return tostring(aName) < tostring(bName)
		end)
	end

	return grouped
end

function TeamAccessService.GetMenuPayload(player)
	return {
		categories = PermissionService.GetCategories(),

		groupedTeams = TeamAccessService.GetPlayerTeamsByCategory(player),

		accessList = TeamAccessService.GetPlayerTeamAccessList(player),

		externalSuspensions = TeamAccessService.GetExternalSuspensions(player),

		generatedAt = os.time(),
	}
end

function TeamAccessService.EnforcePlayerSuspensions(player)
	if not player or not player.Parent then
		return false, "Missing player"
	end

	if not player.Team then
		return false, "Player has no team"
	end

	local currentTeamKey = TeamAccessService.ResolveTeamKey(player.Team.Name)

	if not currentTeamKey then
		return false, "Current team is not managed"
	end

	local access = TeamAccessService.CanPlayerUseTeam(player, currentTeamKey)

	if access.canAccess then
		return true, "No suspension enforcement needed"
	end

	if access.status ~= "suspended" then
		return true, "Access denied, but not suspension related"
	end

	return false, access
end

return TeamAccessService
