local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local TeamConfig = require(
	USARF.Config:WaitForChild("TeamConfig")
)

local SuspensionService = {}

local SuspensionStore =
	DataStoreService:GetDataStore("USARF_Suspensions_v2")

local CaseIndexStore =
	DataStoreService:GetDataStore(
		"USARF_SuspensionCaseIndex_v1"
	)

local StaffAlertRadioService = nil

do
	local success, result = pcall(function()
		return require(
			Services:WaitForChild(
				"StaffAlertRadioService"
			)
		)
	end)

	if success then
		StaffAlertRadioService = result
	else
		warn(
			"[SuspensionService] StaffAlertRadioService failed to load:",
			result
		)
	end
end

local DiscordBotBridge = nil

do
	local success, result = pcall(function()
		local bridgeModule =
			Services:FindFirstChild("DiscordBotBridge")

		if not bridgeModule then
			return nil
		end

		return require(bridgeModule)
	end)

	if success then
		DiscordBotBridge = result
	else
		warn(
			"[SuspensionService] DiscordBotBridge failed to load:",
			result
		)
	end
end

local AREA_GROUPS = {
	civil = {
		"FacilityPersonnel",
		"EngineeringTechnical",
		"MedicalDivision",
		"ResearchDivision",
		"RulesRegulations",
		"UnitedStatesAirForce",
		"DepartmentOfDefense",
		"EXTECH",
	},

	combative = {
		"Infantry108",
		"MP137",
		"SpecOpsAIG",
		"SecretService",
	},

	intelligence = {
		"FederalDefenseService",
		"CentralIntelligenceAgency",
		"FederalBureauInvestigation",
	},

	protection = {
		"SecretService",
	},
}

local AREA_DISPLAY = {
	civil = "Civil Departments",
	combative = "Combative Departments",
	intelligence = "Intelligence Departments",
	protection = "Protection Departments",
	facility = "Facility Wide",
}

local function now()
	return os.time()
end

local function getUserKey(userId)
	return "user_" .. tostring(userId)
end

local function getCaseKey(caseId)
	return "case_" .. tostring(caseId)
end

local function generateCaseId()
	local guid = HttpService:GenerateGUID(false)
	local short = string.upper(string.sub(guid, 1, 8))

	return "USARF-S-" .. short
end

local function callStaffAlert(methodName, ...)
	if not StaffAlertRadioService then
		return false
	end

	local method = StaffAlertRadioService[methodName]

	if typeof(method) ~= "function" then
		warn(
			"[SuspensionService] StaffAlertRadioService method missing:",
			methodName
		)

		return false
	end

	local success, result = pcall(
		method,
		...
	)

	if not success then
		warn(
			"[SuspensionService] Staff radio alert failed:",
			methodName,
			result
		)

		return false
	end

	return result ~= false
end

local function normalizeData(data)
	if type(data) ~= "table" then
		data = {}
	end

	data.departments = data.departments or {}
	data.areas = data.areas or {}
	data.facility = data.facility or nil
	data.history = data.history or {}

	return data
end

local function safeGet(userId)
	local success, result = pcall(function()
		return SuspensionStore:GetAsync(
			getUserKey(userId)
		)
	end)

	if not success then
		warn(
			"[SuspensionService] Failed to get suspensions:",
			userId,
			result
		)

		return normalizeData(nil)
	end

	return normalizeData(result)
end

local function safeSet(userId, data)
	data = normalizeData(data)

	local success, result = pcall(function()
		SuspensionStore:SetAsync(
			getUserKey(userId),
			data
		)
	end)

	if not success then
		warn(
			"[SuspensionService] Failed to save suspensions:",
			userId,
			result
		)

		return false
	end

	return true
end

local function writeCaseIndex(
	caseId,
	userId,
	scope,
	target
)
	if not caseId then
		return
	end

	local success, result = pcall(function()
		CaseIndexStore:SetAsync(
			getCaseKey(caseId),
			{
				userId = userId,
				scope = scope,
				target = target,
				createdAt = now(),
			}
		)
	end)

	if not success then
		warn(
			"[SuspensionService] Failed to write case index:",
			caseId,
			result
		)
	end
end

local function readCaseIndex(caseId)
	local success, result = pcall(function()
		return CaseIndexStore:GetAsync(
			getCaseKey(caseId)
		)
	end)

	if success and type(result) == "table" then
		return result
	end

	return nil
end

local function removeCaseIndex(caseId)
	pcall(function()
		CaseIndexStore:RemoveAsync(
			getCaseKey(caseId)
		)
	end)
end

local function isActive(record)
	if not record then
		return false
	end

	if record.active == false then
		return false
	end

	if record.status == "Revoked"
		or record.status == "Expired"
		or record.status == "Void"
	then
		return false
	end

	if record.expiresAt
		and record.expiresAt <= now()
	then
		return false
	end

	return true
end

local function getTeamDisplayName(teamKey)
	local teamData = TeamConfig.Teams[teamKey]

	if teamData then
		return teamData.displayName
			or teamData.teamName
			or teamKey
	end

	return tostring(teamKey)
end

local function getScopeDisplayName(scope, target)
	if scope == "facility" then
		return "Facility Wide"
	end

	if scope == "area" then
		return AREA_DISPLAY[target]
			or tostring(target)
	end

	if scope == "department" then
		return getTeamDisplayName(target)
	end

	return tostring(target or scope)
end

local function sendSuspensionEvent(
	eventType,
	record,
	targetUserId
)
	if not DiscordBotBridge or not record then
		return
	end

	local payload = {
		caseId = record.caseId,

		targetUserId = tostring(targetUserId),

		scope = record.scope,
		target = record.target,
		targetName = record.targetName,

		reason = record.reason,
		status = record.status,

		issuerUserId =
			record.issuerUserId
			and tostring(record.issuerUserId)
			or nil,

		createdAt = record.createdAt,
		updatedAt = record.updatedAt,

		revokedAt = record.revokedAt,

		revokedBy =
			record.revokedBy
			and tostring(record.revokedBy)
			or nil,

		expiresAt = record.expiresAt,
		durationSeconds = record.durationSeconds,
		permanent = record.permanent,
	}

	if typeof(DiscordBotBridge.SendEvent) ~= "function" then
		warn(
			"[SuspensionService] DiscordBotBridge.SendEvent is missing."
		)

		return
	end

	local success, result = pcall(function()
		DiscordBotBridge.SendEvent(
			eventType,
			payload
		)
	end)

	if not success then
		warn(
			"[SuspensionService] Failed to send Discord suspension event:",
			eventType,
			result
		)
	end
end

local function addHistory(
	data,
	action,
	record,
	issuerUserId
)
	data.history = data.history or {}

	table.insert(data.history, 1, {
		action = action,
		caseId = record and record.caseId,
		scope = record and record.scope,
		target = record and record.target,
		reason = record and record.reason,
		issuerUserId =
			issuerUserId
			or (
				record
				and record.issuerUserId
			),
		createdAt = now(),
		record = record,
	})

	while #data.history > 75 do
		table.remove(data.history)
	end
end

local function expireRecord(
	data,
	action,
	record
)
	if not record then
		return
	end

	record.active = false
	record.status = "Expired"
	record.updatedAt = now()

	addHistory(
		data,
		action,
		record,
		nil
	)

	removeCaseIndex(record.caseId)
end

local function cleanExpired(data)
	local changed = false

	for teamKey, record in pairs(
		data.departments or {}
		) do
		if record.expiresAt
			and record.expiresAt <= now()
		then
			expireRecord(
				data,
				"ExpiredDepartmentSuspension",
				record
			)

			data.departments[teamKey] = nil
			changed = true
		end
	end

	for areaKey, record in pairs(
		data.areas or {}
		) do
		if record.expiresAt
			and record.expiresAt <= now()
		then
			expireRecord(
				data,
				"ExpiredAreaSuspension",
				record
			)

			data.areas[areaKey] = nil
			changed = true
		end
	end

	if data.facility
		and data.facility.expiresAt
		and data.facility.expiresAt <= now()
	then
		expireRecord(
			data,
			"ExpiredFacilitySuspension",
			data.facility
		)

		data.facility = nil
		changed = true
	end

	return changed
end

local function makeRecord(
	issuerUserId,
	reason,
	durationSeconds,
	scope,
	target
)
	local createdAt = now()

	local expiresAt = nil

	if durationSeconds
		and durationSeconds > 0
	then
		expiresAt = createdAt + durationSeconds
	end

	return {
		active = true,
		status = "Active",

		caseId = generateCaseId(),

		scope = scope,
		target = target,

		targetName =
			getScopeDisplayName(
				scope,
				target
			),

		reason =
			reason
			or "No reason provided",

		issuerUserId = issuerUserId,

		createdAt = createdAt,
		updatedAt = createdAt,

		expiresAt = expiresAt,
		durationSeconds = durationSeconds,

		permanent = expiresAt == nil,
	}
end

function SuspensionService.GetSuspensionData(userId)
	local data = safeGet(userId)
	local changed = cleanExpired(data)

	if changed then
		safeSet(userId, data)
	end

	return data
end

function SuspensionService.IsTeamSuspendable(teamKey)
	local teamData = TeamConfig.Teams[teamKey]

	if not teamData then
		return false
	end

	if teamData.suspendable == false then
		return false
	end

	if teamKey == "TestSubject"
		or teamKey == "PMC"
		or teamKey == "Loading"
	then
		return false
	end

	return true
end

function SuspensionService.IsSuspendedFromTeam(
	userId,
	teamKey
)
	local teamData = TeamConfig.Teams[teamKey]

	if not teamData then
		return {
			suspended = false,
			reason = "Team does not exist",
		}
	end

	if not SuspensionService.IsTeamSuspendable(
		teamKey
		) then
		return {
			suspended = false,
			reason = "Team cannot be suspended",
		}
	end

	local data =
		SuspensionService.GetSuspensionData(
			userId
		)

	if isActive(data.facility) then
		return {
			suspended = true,
			scope = "facility",
			scopeName = "Facility Wide",
			record = data.facility,
			reason = data.facility.reason,
			caseId = data.facility.caseId,
		}
	end

	local departmentRecord =
		data.departments[teamKey]

	if isActive(departmentRecord) then
		return {
			suspended = true,
			scope = "department",
			scopeName =
				getTeamDisplayName(teamKey),
			record = departmentRecord,
			reason = departmentRecord.reason,
			caseId = departmentRecord.caseId,
		}
	end

	local areaKey =
		teamData.suspensionGroup

	local areaRecord =
		areaKey
		and data.areas[areaKey]

	if isActive(areaRecord) then
		return {
			suspended = true,
			scope = "area",
			scopeName =
				AREA_DISPLAY[areaKey]
				or areaKey,
			record = areaRecord,
			reason = areaRecord.reason,
			caseId = areaRecord.caseId,
		}
	end

	return {
		suspended = false,
		reason = "Not suspended",
	}
end

function SuspensionService.GetActiveSuspensions(
	userId
)
	local data =
		SuspensionService.GetSuspensionData(
			userId
		)

	local results = {}

	if isActive(data.facility) then
		table.insert(results, data.facility)
	end

	for _, record in pairs(
		data.areas or {}
		) do
		if isActive(record) then
			table.insert(results, record)
		end
	end

	for _, record in pairs(
		data.departments or {}
		) do
		if isActive(record) then
			table.insert(results, record)
		end
	end

	return results
end

function SuspensionService.GetHistory(userId)
	local data =
		SuspensionService.GetSuspensionData(
			userId
		)

	return data.history or {}
end

function SuspensionService.FindCase(
	userId,
	caseId
)
	local data =
		SuspensionService.GetSuspensionData(
			userId
		)

	if data.facility
		and data.facility.caseId == caseId
	then
		return data.facility
	end

	for _, record in pairs(
		data.areas or {}
		) do
		if record.caseId == caseId then
			return record
		end
	end

	for _, record in pairs(
		data.departments or {}
		) do
		if record.caseId == caseId then
			return record
		end
	end

	for _, item in ipairs(
		data.history or {}
		) do
		if item.caseId == caseId then
			return item.record or item
		end
	end

	return nil
end

function SuspensionService.SuspendDepartment(
	targetUserId,
	teamKey,
	issuerUserId,
	reason,
	durationSeconds
)
	if not SuspensionService.IsTeamSuspendable(
		teamKey
		) then
		return false, "This team cannot be suspended"
	end

	local data =
		SuspensionService.GetSuspensionData(
			targetUserId
		)

	local record = makeRecord(
		issuerUserId,
		reason,
		durationSeconds,
		"department",
		teamKey
	)

	data.departments[teamKey] = record

	addHistory(
		data,
		"CreatedDepartmentSuspension",
		record,
		issuerUserId
	)

	if not safeSet(targetUserId, data) then
		return false, "Failed to save suspension"
	end

	writeCaseIndex(
		record.caseId,
		targetUserId,
		"department",
		teamKey
	)

	callStaffAlert(
		"DepartmentSuspension",
		targetUserId,
		getTeamDisplayName(teamKey),
		record.reason,
		record.caseId
	)

	sendSuspensionEvent(
		"suspension.department.created",
		record,
		targetUserId
	)

	return true, record
end

function SuspensionService.SuspendArea(
	targetUserId,
	areaKey,
	issuerUserId,
	reason,
	durationSeconds
)
	if not AREA_GROUPS[areaKey] then
		return false, "Invalid suspension area"
	end

	local data =
		SuspensionService.GetSuspensionData(
			targetUserId
		)

	local record = makeRecord(
		issuerUserId,
		reason,
		durationSeconds,
		"area",
		areaKey
	)

	data.areas[areaKey] = record

	addHistory(
		data,
		"CreatedAreaSuspension",
		record,
		issuerUserId
	)

	if not safeSet(targetUserId, data) then
		return false, "Failed to save area suspension"
	end

	writeCaseIndex(
		record.caseId,
		targetUserId,
		"area",
		areaKey
	)

	callStaffAlert(
		"AreaSuspension",
		targetUserId,
		SuspensionService.GetAreaDisplayName(
			areaKey
		),
		record.reason,
		record.caseId
	)

	sendSuspensionEvent(
		"suspension.area.created",
		record,
		targetUserId
	)

	return true, record
end

function SuspensionService.SuspendFacility(
	targetUserId,
	issuerUserId,
	reason,
	durationSeconds
)
	local data =
		SuspensionService.GetSuspensionData(
			targetUserId
		)

	local record = makeRecord(
		issuerUserId,
		reason,
		durationSeconds,
		"facility",
		"facility"
	)

	data.facility = record

	addHistory(
		data,
		"CreatedFacilitySuspension",
		record,
		issuerUserId
	)

	if not safeSet(targetUserId, data) then
		return false, "Failed to save facility suspension"
	end

	writeCaseIndex(
		record.caseId,
		targetUserId,
		"facility",
		"facility"
	)

	callStaffAlert(
		"FacilitySuspension",
		targetUserId,
		record.reason,
		record.caseId
	)

	sendSuspensionEvent(
		"suspension.facility.created",
		record,
		targetUserId
	)

	return true, record
end

local function revokeRecord(
	record,
	issuerUserId
)
	record.active = false
	record.status = "Revoked"
	record.revokedAt = now()
	record.revokedBy = issuerUserId
	record.updatedAt = now()
end

function SuspensionService.RemoveDepartmentSuspension(
	targetUserId,
	teamKey,
	issuerUserId
)
	local data =
		SuspensionService.GetSuspensionData(
			targetUserId
		)

	local record = data.departments[teamKey]

	if not record then
		return false, "No department suspension found"
	end

	revokeRecord(record, issuerUserId)

	addHistory(
		data,
		"RemovedDepartmentSuspension",
		record,
		issuerUserId
	)

	data.departments[teamKey] = nil

	if not safeSet(targetUserId, data) then
		return false, "Failed to remove department suspension"
	end

	removeCaseIndex(record.caseId)

	callStaffAlert(
		"SuspensionRemoved",
		targetUserId,
		getTeamDisplayName(teamKey),
		record.caseId
	)

	sendSuspensionEvent(
		"suspension.department.removed",
		record,
		targetUserId
	)

	return true, record
end

function SuspensionService.RemoveAreaSuspension(
	targetUserId,
	areaKey,
	issuerUserId
)
	local data =
		SuspensionService.GetSuspensionData(
			targetUserId
		)

	local record = data.areas[areaKey]

	if not record then
		return false, "No area suspension found"
	end

	revokeRecord(record, issuerUserId)

	addHistory(
		data,
		"RemovedAreaSuspension",
		record,
		issuerUserId
	)

	data.areas[areaKey] = nil

	if not safeSet(targetUserId, data) then
		return false, "Failed to remove area suspension"
	end

	removeCaseIndex(record.caseId)

	callStaffAlert(
		"SuspensionRemoved",
		targetUserId,
		SuspensionService.GetAreaDisplayName(
			areaKey
		),
		record.caseId
	)

	sendSuspensionEvent(
		"suspension.area.removed",
		record,
		targetUserId
	)

	return true, record
end

function SuspensionService.RemoveFacilitySuspension(
	targetUserId,
	issuerUserId
)
	local data =
		SuspensionService.GetSuspensionData(
			targetUserId
		)

	local record = data.facility

	if not record then
		return false, "No facility suspension found"
	end

	revokeRecord(record, issuerUserId)

	addHistory(
		data,
		"RemovedFacilitySuspension",
		record,
		issuerUserId
	)

	data.facility = nil

	if not safeSet(targetUserId, data) then
		return false, "Failed to remove facility suspension"
	end

	removeCaseIndex(record.caseId)

	callStaffAlert(
		"SuspensionRemoved",
		targetUserId,
		"Facility Wide",
		record.caseId
	)

	sendSuspensionEvent(
		"suspension.facility.removed",
		record,
		targetUserId
	)

	return true, record
end

function SuspensionService.RemoveSuspensionByCaseId(
	caseId,
	issuerUserId
)
	caseId = tostring(caseId or "")

	if caseId == "" then
		return false, "Missing case ID"
	end

	local index = readCaseIndex(caseId)

	if not index then
		return false, "Suspension case not found"
	end

	local targetUserId =
		tonumber(index.userId)

	local scope =
		tostring(index.scope or "")

	local target = index.target

	if not targetUserId then
		return false, "Suspension case has invalid user ID"
	end

	if scope == "department" then
		return SuspensionService.RemoveDepartmentSuspension(
			targetUserId,
			target,
			issuerUserId
		)
	end

	if scope == "area" then
		return SuspensionService.RemoveAreaSuspension(
			targetUserId,
			target,
			issuerUserId
		)
	end

	if scope == "facility" then
		return SuspensionService.RemoveFacilitySuspension(
			targetUserId,
			issuerUserId
		)
	end

	return false, "Unknown suspension scope"
end

function SuspensionService.ClearAllSuspensions(
	targetUserId,
	issuerUserId
)
	local data =
		SuspensionService.GetSuspensionData(
			targetUserId
		)

	if data.facility then
		revokeRecord(
			data.facility,
			issuerUserId
		)

		addHistory(
			data,
			"ClearedFacilitySuspension",
			data.facility,
			issuerUserId
		)

		removeCaseIndex(
			data.facility.caseId
		)

		sendSuspensionEvent(
			"suspension.facility.removed",
			data.facility,
			targetUserId
		)
	end

	for _, record in pairs(
		data.areas or {}
		) do
		revokeRecord(
			record,
			issuerUserId
		)

		addHistory(
			data,
			"ClearedAreaSuspension",
			record,
			issuerUserId
		)

		removeCaseIndex(record.caseId)

		sendSuspensionEvent(
			"suspension.area.removed",
			record,
			targetUserId
		)
	end

	for _, record in pairs(
		data.departments or {}
		) do
		revokeRecord(
			record,
			issuerUserId
		)

		addHistory(
			data,
			"ClearedDepartmentSuspension",
			record,
			issuerUserId
		)

		removeCaseIndex(record.caseId)

		sendSuspensionEvent(
			"suspension.department.removed",
			record,
			targetUserId
		)
	end

	data.facility = nil
	data.areas = {}
	data.departments = {}

	if not safeSet(targetUserId, data) then
		return false, "Failed to clear suspensions"
	end

	callStaffAlert(
		"System",
		string.format(
			"All suspensions cleared for UserId:%s",
			tostring(targetUserId)
		)
	)

	return true
end

function SuspensionService.GetAreaTeams(areaKey)
	return AREA_GROUPS[areaKey]
end

function SuspensionService.GetAreas()
	return AREA_GROUPS
end

function SuspensionService.GetAreaDisplayName(areaKey)
	return AREA_DISPLAY[areaKey]
		or tostring(areaKey)
end

function SuspensionService.GetTeamDisplayName(teamKey)
	return getTeamDisplayName(teamKey)
end

return SuspensionService