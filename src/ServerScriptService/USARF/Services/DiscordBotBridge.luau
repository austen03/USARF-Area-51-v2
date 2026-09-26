local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local BASE_URL = "https://admin.usarfutilities.org/roblox"

local SHARED_SECRET = "43fa20b4-92e3-43f4-b74c-a8f0204f2d28"

local DEBUG = false

local MAX_QUEUE_SIZE = 250
local MAX_ATTEMPTS = 6
local LIVE_CHECK_INTERVAL = 10

local OPEN_CASE_MAX_ATTEMPTS = 3
local OPEN_CASE_RETRY_DELAY = 1.5
local OPEN_CASE_DEBOUNCE_SECONDS = 8

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local MODERATION_REMOTE_NAME = "ModerationUtilityRemote"

local function getOrCreate(parent, className, name)
	local object = parent:FindFirstChild(name)

	if not object then
		object = Instance.new(className)
		object.Name = name
		object.Parent = parent
	end

	return object
end

local USARFRemotes = getOrCreate(
	ReplicatedStorage,
	"Folder",
	REMOTE_FOLDER_NAME
)

local ModerationRemote = getOrCreate(
	USARFRemotes,
	"RemoteEvent",
	MODERATION_REMOTE_NAME
)

local Queue = {}
local Processing = false

local OpenCaseRequests = {}

local function debugPrint(...)
	if DEBUG then
		print("[DiscordBotBridge]", ...)
	end
end

local function debugWarn(...)
	if DEBUG then
		warn("[DiscordBotBridge]", ...)
	end
end

local function clean(value)
	return tostring(value or "")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
end

local function copyTable(source)
	local result = {}

	for key, value in pairs(source or {}) do
		result[key] = value
	end

	return result
end

local function buildHeaders()
	return {
		["Content-Type"] = "application/json",
		["x-roblox-shared-secret"] = SHARED_SECRET,
	}
end

local function decodeResponseBody(body)
	if not body or body == "" then
		return nil
	end

	local success, decoded = pcall(function()
		return HttpService:JSONDecode(body)
	end)

	if success then
		return decoded
	end

	debugWarn("Failed to decode response body:", body)

	return nil
end

local function performRequest(path, method, payload)
	method = method or "POST"

	local requestOptions = {
		Url = BASE_URL .. path,
		Method = method,
		Headers = buildHeaders(),
	}

	if method ~= "GET" then
		requestOptions.Body = HttpService:JSONEncode(payload or {})
	end

	debugPrint(
		"Request",
		requestOptions.Method,
		requestOptions.Url
	)

	local response = HttpService:RequestAsync(requestOptions)
	local decoded = decodeResponseBody(response.Body)

	debugPrint(
		"Response",
		response.StatusCode,
		response.Success,
		response.Body
	)

	return {
		ok = response.Success == true,
		statusCode = response.StatusCode,
		statusMessage = response.StatusMessage,
		body = response.Body,
		data = decoded,
	}
end

local function requestQueueItem(item)
	return performRequest(
		item.path,
		item.method,
		item.payload
	)
end

local function enqueue(path, method, payload)
	if #Queue >= MAX_QUEUE_SIZE then
		table.remove(Queue, 1)
		debugWarn("Queue full; dropped oldest request.")
	end

	table.insert(Queue, {
		path = path,
		method = method or "POST",
		payload = payload or {},
		attempts = 0,
		nextAttempt = os.clock(),
	})
end

local function processQueue()
	if Processing then
		return
	end

	Processing = true

	task.spawn(function()
		while #Queue > 0 do
			local item = Queue[1]

			if os.clock() < item.nextAttempt then
				task.wait(
					math.max(
						0.5,
						item.nextAttempt - os.clock()
					)
				)
			else
				local success, result = pcall(
					requestQueueItem,
					item
				)

				if success and result and result.ok then
					table.remove(Queue, 1)
				else
					item.attempts += 1

					if item.attempts >= MAX_ATTEMPTS then
						debugWarn(
							"Dropping request after maximum attempts:",
							item.path,
							result
						)

						table.remove(Queue, 1)
					else
						item.nextAttempt =
							os.clock()
							+ math.min(
								60,
								2 ^ item.attempts
							)

						debugWarn(
							"Request failed; retry queued:",
							item.path,
							item.attempts
						)
					end
				end
			end
		end

		Processing = false
	end)
end

local function getOpenCaseRequestKey(
	targetUserId,
	openedByUserId
)
	return string.format(
		"%s:%s",
		tostring(openedByUserId or 0),
		tostring(targetUserId or 0)
	)
end

local function makeOpenCaseIdempotencyKey(
	targetPlayer,
	openedByPlayer
)
	local timeBucket = math.floor(
		os.time() / OPEN_CASE_DEBOUNCE_SECONDS
	)

	return table.concat({
		"roblox",
		clean(game.JobId) ~= "" and game.JobId or "studio",
		tostring(
			openedByPlayer
				and openedByPlayer.UserId
				or 0
		),
		tostring(targetPlayer.UserId),
		tostring(timeBucket),
	}, ":")
end

local function normalizeOpenCaseResponse(result)
	if not result then
		return false, {
			success = false,
			message = "No response was received from the backend.",
		}
	end

	if not result.ok then
		local responseBody = result.data or {}

		return false, {
			success = false,
			statusCode = result.statusCode,
			error = responseBody.error
				or "request_failed",
			message = responseBody.message
				or result.statusMessage
				or "The backend rejected the case request.",
		}
	end

	local outerPayload = result.data or {}

	if outerPayload.ok == false then
		return false, {
			success = false,
			statusCode = result.statusCode,
			error = outerPayload.error
				or "request_failed",
			message = outerPayload.message
				or "The backend rejected the case request.",
		}
	end

	local data = outerPayload.data or outerPayload

	if data.success == false then
		return false, {
			success = false,
			statusCode = result.statusCode,
			error = data.error
				or outerPayload.error
				or "case_creation_failed",
			message = data.message
				or outerPayload.message
				or "The moderation case could not be created.",
		}
	end

	local caseNumber = clean(
		data.caseNumber
			or data.caseId
	)

	local caseReference = clean(
		data.caseReference
			or data.caseRef
	)

	if caseNumber == "" then
		return false, {
			success = false,
			statusCode = result.statusCode,
			error = "missing_case_number",
			message = "The backend created a case but did not return a case number.",
		}
	end

	return true, {
		success = true,

		created = data.created == true,
		duplicate = data.duplicate == true,

		gameCaseId = data.gameCaseId,
		caseId = caseNumber,
		caseNumber = caseNumber,
		caseReference = caseReference,

		discordChannelId = data.discordChannelId,
		discordGuildId = data.discordGuildId,

		message = clean(data.message) ~= ""
			and data.message
			or (
				"Case "
				.. caseNumber
				.. " was opened successfully."
			),
	}
end

local function requestOpenCase(payload)
	local latestFailure = nil

	for attempt = 1, OPEN_CASE_MAX_ATTEMPTS do
		local requestSuccess, result = pcall(function()
			return performRequest(
				"/cases/open",
				"POST",
				payload
			)
		end)

		if requestSuccess then
			local normalizedSuccess, normalized =
				normalizeOpenCaseResponse(result)

			if normalizedSuccess then
				return true, normalized
			end

			latestFailure = normalized

			local statusCode =
				tonumber(normalized.statusCode)
				or 0

			local shouldRetry =
				statusCode == 0
				or statusCode == 408
				or statusCode == 425
				or statusCode == 429
				or statusCode >= 500

			if not shouldRetry then
				return false, normalized
			end
		else
			latestFailure = {
				success = false,
				error = "request_error",
				message = tostring(result),
			}
		end

		if attempt < OPEN_CASE_MAX_ATTEMPTS then
			task.wait(
				OPEN_CASE_RETRY_DELAY * attempt
			)
		end
	end

	return false, latestFailure or {
		success = false,
		error = "case_request_failed",
		message = "The case request failed after multiple attempts.",
	}
end

local Bridge = {}

function Bridge.SendEvent(eventType, payload)
	enqueue("/events", "POST", {
		eventType = eventType,
		payload = payload or {},
	})

	processQueue()
end

function Bridge.OpenCase(
	targetPlayer,
	openedByPlayer,
	teamName,
	notes
)
	if not targetPlayer then
		return false, {
			success = false,
			message = "Missing target player.",
		}
	end

	if not targetPlayer:IsA("Player") then
		return false, {
			success = false,
			message = "The case target is invalid.",
		}
	end

	if openedByPlayer and not openedByPlayer:IsA("Player") then
		return false, {
			success = false,
			message = "The case opener is invalid.",
		}
	end

	local requestKey = getOpenCaseRequestKey(
		targetPlayer.UserId,
		openedByPlayer and openedByPlayer.UserId
	)

	local existingRequest = OpenCaseRequests[requestKey]
	local currentTime = os.clock()

	if existingRequest then
		if existingRequest.completedResponse then
			if (
				currentTime
				- existingRequest.startedAt
				) <= OPEN_CASE_DEBOUNCE_SECONDS then
				local cached =
					copyTable(
						existingRequest.completedResponse
					)

				cached.duplicate = true

				return true, cached
			end

			OpenCaseRequests[requestKey] = nil
		elseif existingRequest.inProgress then
			local waitStartedAt = os.clock()

			while existingRequest.inProgress do
				if os.clock() - waitStartedAt > 20 then
					return false, {
						success = false,
						message = "The existing case request timed out.",
					}
				end

				task.wait(0.1)
			end

			if existingRequest.completedResponse then
				local cached =
					copyTable(
						existingRequest.completedResponse
					)

				cached.duplicate = true

				return true, cached
			end

			return false, {
				success = false,
				message = existingRequest.errorMessage
					or "The existing case request failed.",
			}
		end
	end

	local requestState = {
		inProgress = true,
		startedAt = currentTime,
		completedResponse = nil,
		errorMessage = nil,
	}

	OpenCaseRequests[requestKey] = requestState

	local payload = {
		robloxUserId = tostring(targetPlayer.UserId),
		robloxUsername = targetPlayer.Name,
		robloxDisplayName = targetPlayer.DisplayName,

		openedByRobloxUserId = openedByPlayer
			and tostring(openedByPlayer.UserId)
			or nil,

		openedByRobloxUsername = openedByPlayer
			and openedByPlayer.Name
			or nil,

		currentTeam = teamName
			or (
				targetPlayer.Team
				and targetPlayer.Team.Name
			)
			or "Unknown",

		currentPlaceId = tostring(game.PlaceId),
		currentJobId = clean(game.JobId),

		initialNotes = clean(notes) ~= ""
			and notes
			or nil,

		idempotencyKey = makeOpenCaseIdempotencyKey(
			targetPlayer,
			openedByPlayer
		),
	}

	local success, result = requestOpenCase(payload)

	requestState.inProgress = false

	if success then
		requestState.completedResponse =
			copyTable(result)

		task.delay(
			OPEN_CASE_DEBOUNCE_SECONDS + 2,
			function()
				if OpenCaseRequests[requestKey]
					== requestState
				then
					OpenCaseRequests[requestKey] = nil
				end
			end
		)

		return true, result
	end

	requestState.errorMessage =
		result and result.message
		or "The moderation case could not be opened."

	task.delay(2, function()
		if OpenCaseRequests[requestKey]
			== requestState
		then
			OpenCaseRequests[requestKey] = nil
		end
	end)

	return false, result
end

function Bridge.SubmitModeration(
	actionType,
	targetPlayer,
	actorPlayer,
	reason,
	duration,
	caseRef,
	options
)
	if not targetPlayer then
		warn(
			"[DiscordBotBridge] SubmitModeration failed: missing target player."
		)

		return false, "Missing target player."
	end

	options = options or {}

	debugPrint(
		"Queue moderation action:",
		actionType,
		targetPlayer.Name,
		caseRef
	)

	enqueue("/moderation/action", "POST", {
		caseRef = caseRef,

		actionType = actionType,

		robloxUsername = targetPlayer.Name,
		robloxDisplayName = targetPlayer.DisplayName,
		robloxUserId = tostring(targetPlayer.UserId),

		teamName = targetPlayer.Team
			and targetPlayer.Team.Name
			or "Unknown",

		currentPlaceId = tostring(game.PlaceId),
		currentJobId = clean(game.JobId),

		actorRobloxUserId = actorPlayer
			and tostring(actorPlayer.UserId)
			or nil,

		actorRobloxUsername = actorPlayer
			and actorPlayer.Name
			or "System",

		actorDisplayName = actorPlayer
			and actorPlayer.DisplayName
			or "System",

		reason = reason
			or "No reason provided.",

		duration = duration,

		evidence = options.evidence,
		internalNotes = options.internalNotes,

		notifyPlayer =
			options.notifyPlayer ~= false,

		immediateRemoval =
			options.immediateRemoval ~= false,

		source = "roblox",
	})

	processQueue()

	return true
end

function Bridge.SubmitSuspension(
	targetPlayer,
	actorPlayer,
	scope,
	reason,
	duration,
	caseRef,
	options
)
	if not targetPlayer then
		return false, "Missing target player."
	end

	options = options or {}

	enqueue("/suspensions/team", "POST", {
		caseRef = caseRef,

		robloxUsername = targetPlayer.Name,
		robloxDisplayName = targetPlayer.DisplayName,
		robloxUserId = tostring(targetPlayer.UserId),

		teamName = targetPlayer.Team
			and targetPlayer.Team.Name
			or "Unknown",

		currentPlaceId = tostring(game.PlaceId),
		currentJobId = clean(game.JobId),

		actorRobloxUserId = actorPlayer
			and tostring(actorPlayer.UserId)
			or nil,

		actorRobloxUsername = actorPlayer
			and actorPlayer.Name
			or "System",

		actorDisplayName = actorPlayer
			and actorPlayer.DisplayName
			or "System",

		suspensionType = options.suspensionType
			or options.scopeType
			or "team",

		scopeType = options.scopeType
			or options.suspensionType
			or "team",

		scope = scope,
		scopeValue = options.scopeValue
			or scope,

		scopeDisplay = options.scopeDisplay
			or scope,

		reason = reason
			or "No reason provided.",

		duration = duration
			or "permanent",

		evidence = options.evidence,
		internalNotes = options.internalNotes,

		notifyPlayer =
			options.notifyPlayer ~= false,

		source = "roblox",
	})

	processQueue()

	return true
end

local function showGameWarning(
	player,
	reason,
	caseRef,
	issuer
)
	if not player or not player.Parent then
		return
	end

	ModerationRemote:FireClient(
		player,
		"WarnPopup",
		{
			title = "GAME WARNING",
			time = os.time(),
			reason = reason
				or "A moderation action was issued.",
			caseId = caseRef
				or "N/A",
			issuer = issuer
				or "SYSTEM",
		}
	)
end

local function markNotificationDelivered(
	player,
	notification
)
	if not notification or not notification.id then
		return
	end

	enqueue(
		"/moderation/notification-delivered",
		"POST",
		{
			notificationId = notification.id,
			robloxUserId = tostring(player.UserId),
			deliveredAt = os.time(),
		}
	)

	processQueue()
end

local function fireExternalSuspensionChanged(player)
	local event = Services:FindFirstChild(
		"ExternalSuspensionChanged"
	)

	if event and event:IsA("BindableEvent") then
		event:Fire(player)
	else
		warn(
			"[DiscordBotBridge] ExternalSuspensionChanged BindableEvent missing."
		)
	end
end

local function normalizeUnixTimestamp(value)
	if value == nil then
		return nil
	end

	if typeof(value) == "number" then
		if value > 100000000000 then
			return math.floor(value / 1000)
		end

		return value > 0 and math.floor(value) or nil
	end

	local numericValue = tonumber(value)

	if numericValue then
		if numericValue > 100000000000 then
			return math.floor(numericValue / 1000)
		end

		return numericValue > 0 and math.floor(numericValue) or nil
	end

	if typeof(value) == "string" and value ~= "" then
		local success, dateTime = pcall(function()
			return DateTime.fromIsoDate(value)
		end)

		if success and dateTime then
			return math.floor(dateTime.UnixTimestamp)
		end
	end

	return nil
end

local function normalizeSuspensionRecord(suspension)
	local metadata = suspension.metadataJson
		or suspension.metadata_json
		or {}

	local caseNumber = clean(
		suspension.caseNumber
			or suspension.case_number
			or suspension.caseId
			or suspension.case_id
			or suspension.caseRef
			or suspension.case_ref
			or metadata.caseNumber
			or metadata.case_number
	)

	local caseReference = clean(
		suspension.caseReference
			or suspension.case_reference
			or metadata.caseReference
			or metadata.case_reference
			or suspension.caseRef
			or suspension.case_ref
	)

	local sanctionId = clean(
		suspension.sanctionId
			or suspension.sanction_id
			or metadata.sanctionId
			or metadata.sanction_id
	)

	local scopeType = clean(
		suspension.scopeType
			or suspension.scope_type
			or metadata.scopeType
			or metadata.scope_type
			or suspension.suspensionType
			or suspension.suspension_type
			or "team"
	):lower()

	if scopeType == "area" then
		scopeType = "category"
	elseif scopeType == "division" then
		scopeType = "department"
	elseif scopeType == "facility wide" then
		scopeType = "facility"
	end

	local scopeValue = clean(
		suspension.scopeValue
			or suspension.scope_value
			or metadata.scopeValue
			or metadata.scope_value
			or suspension.scope
	)

	local scopeDisplay = clean(
		suspension.scopeDisplay
			or suspension.scope_display
			or metadata.scopeDisplay
			or metadata.scope_display
			or suspension.scope
			or scopeValue
			or "Unknown"
	)

	local state = clean(
		suspension.state
			or suspension.status
			or "active"
	):lower()

	if state == "voided" then
		state = "void"
	end

	local expiresAt = normalizeUnixTimestamp(
		suspension.expiresAt
			or suspension.expires_at
			or metadata.expiresAt
			or metadata.expires_at
	)

	if expiresAt and expiresAt <= os.time() then
		state = "expired"
	end

	return {
		caseId = caseNumber ~= "" and caseNumber or "N/A",
		caseNumber = caseNumber ~= "" and caseNumber or "N/A",
		caseReference = caseReference ~= "" and caseReference or nil,
		sanctionId = sanctionId ~= "" and sanctionId or nil,

		sanctionType = clean(
			suspension.type
				or suspension.actionType
				or suspension.action_type
				or metadata.type
				or "team_suspension"
		),

		scopeType = scopeType,
		scopeValue = scopeValue,
		scopeDisplay = scopeDisplay,

		reason = clean(
			suspension.reason
				or "External team suspension."
		),

		state = state,
		durationSeconds = tonumber(
			suspension.durationSeconds
				or suspension.duration_seconds
				or metadata.durationSeconds
				or metadata.duration_seconds
		),

		startsAt = normalizeUnixTimestamp(
			suspension.startsAt
				or suspension.starts_at
				or suspension.createdAt
				or suspension.created_at
		),

		expiresAt = expiresAt,
		external = true,
	}
end

local function buildExternalSuspensionPayload(liveSuspensions)
	local normalized = {}

	for _, suspension in ipairs(liveSuspensions or {}) do
		local record = normalizeSuspensionRecord(suspension)

		if record.state == "active" then
			table.insert(normalized, record)
		end
	end

	table.sort(normalized, function(left, right)
		local leftKey = tostring(left.sanctionId or left.caseId or "")
		local rightKey = tostring(right.sanctionId or right.caseId or "")
		return leftKey < rightKey
	end)

	return normalized
end

local function setLegacyExternalSuspensionAttributes(player, record)
	if not record then
		player:SetAttribute("USARF_ExternalSuspended", false)
		player:SetAttribute("USARF_ExternalSuspensionScope", nil)
		player:SetAttribute("USARF_ExternalSuspensionScopeType", nil)
		player:SetAttribute("USARF_ExternalSuspensionScopeValue", nil)
		player:SetAttribute("USARF_ExternalSuspensionScopeDisplay", nil)
		player:SetAttribute("USARF_ExternalSuspensionCase", nil)
		player:SetAttribute("USARF_ExternalSuspensionCaseReference", nil)
		player:SetAttribute("USARF_ExternalSuspensionSanction", nil)
		player:SetAttribute("USARF_ExternalSuspensionReason", nil)
		player:SetAttribute("USARF_ExternalSuspensionDurationSeconds", nil)
		player:SetAttribute("USARF_ExternalSuspensionStartsAt", nil)
		player:SetAttribute("USARF_ExternalSuspensionExpiresAt", nil)
		return
	end

	player:SetAttribute("USARF_ExternalSuspended", true)
	player:SetAttribute("USARF_ExternalSuspensionScope", record.scopeDisplay)
	player:SetAttribute("USARF_ExternalSuspensionScopeType", record.scopeType)
	player:SetAttribute("USARF_ExternalSuspensionScopeValue", record.scopeValue)
	player:SetAttribute("USARF_ExternalSuspensionScopeDisplay", record.scopeDisplay)
	player:SetAttribute("USARF_ExternalSuspensionCase", record.caseId)
	player:SetAttribute("USARF_ExternalSuspensionCaseReference", record.caseReference)
	player:SetAttribute("USARF_ExternalSuspensionSanction", record.sanctionId)
	player:SetAttribute("USARF_ExternalSuspensionReason", record.reason)
	player:SetAttribute("USARF_ExternalSuspensionDurationSeconds", record.durationSeconds)
	player:SetAttribute("USARF_ExternalSuspensionStartsAt", record.startsAt)
	player:SetAttribute("USARF_ExternalSuspensionExpiresAt", record.expiresAt)
end

local function applyExternalSuspensions(player, liveSuspensions)
	local normalized = buildExternalSuspensionPayload(liveSuspensions)
	local encoded = HttpService:JSONEncode(normalized)
	local previous = player:GetAttribute("USARF_ExternalSuspensionsJson") or ""
	local changed = previous ~= encoded

	player:SetAttribute("USARF_ExternalSuspensionsJson", encoded)
	player:SetAttribute("USARF_ExternalSuspensionCount", #normalized)
	setLegacyExternalSuspensionAttributes(player, normalized[1])

	if changed then
		fireExternalSuspensionChanged(player)
	end

	return changed, normalized
end

local function clearExternalSuspensionAttributes(player)
	return applyExternalSuspensions(player, {})
end

local function checkModerationStatus(player)
	if not player or not player.Parent then
		return
	end

	debugPrint(
		"Checking moderation status for:",
		player.Name,
		player.UserId
	)

	local requestSuccess, result = pcall(function()
		return performRequest(
			"/moderation/status/"
				.. tostring(player.UserId),
			"GET",
			nil
		)
	end)

	if not requestSuccess then
		debugWarn(
			"Moderation status request errored:",
			result
		)

		return
	end

	if not result or not result.ok then
		debugWarn(
			"Moderation status request failed:",
			result and result.statusCode,
			result and result.body
		)

		return
	end

	local outerPayload = result.data or {}
	local data = outerPayload.data or outerPayload

	debugPrint(
		"Notifications found:",
		#(data.notifications or {})
	)

	debugPrint(
		"Actions found:",
		#(data.actions or {})
	)

	for _, notification in ipairs(
		data.notifications or {}
		) do
		local caseRef =
			notification.caseRef
			or notification.case_ref

		local payloadJson =
			notification.payloadJson
			or notification.payload_json
			or {}

		local reason =
			notification.body
			or notification.reason
			or payloadJson.reason
			or "A moderation action was issued."

		local notificationType = string.lower(
			tostring(
				notification.notificationType
					or notification.notification_type
					or ""
			)
		)

		if notificationType == "warn"
			or notificationType == "warning"
			or notificationType == "game_warning"
			or notificationType == "game warning"
		then
			showGameWarning(
				player,
				reason,
				caseRef
			)
		else
			-- Suspensions are enforced through the team/menu system and bans
			-- are enforced by the active action check below. Neither should
			-- display the game-warning acknowledgement popup.
			debugPrint(
				"Skipping WarnPopup for notification type:",
				notificationType,
				player.Name,
				caseRef
			)
		end

		markNotificationDelivered(
			player,
			notification
		)
	end

	local liveSuspensions = data.suspensions or {}
	local suspensionChanged, normalizedSuspensions =
		applyExternalSuspensions(player, liveSuspensions)

	debugPrint(
		"Active external suspensions:",
		player.Name,
		#normalizedSuspensions,
		"changed:",
		suspensionChanged
	)

	for _, action in ipairs(data.actions or {}) do
		local actionType = string.lower(
			tostring(
				action.actionType
					or action.action_type
					or ""
			)
		)

		if actionType == "ban" then
			local metadata =
				action.metadataJson
				or action.metadata_json
				or {}

			local immediateRemoval =
				metadata.immediateRemoval

			if immediateRemoval == nil then
				immediateRemoval = true
			end

			if immediateRemoval then
				player:Kick(
					string.format(
						"Banned: %s\nCase: %s",
						action.reason
							or "No reason provided.",
						action.caseRef
							or action.case_ref
							or "N/A"
					)
				)

				return
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("USARF_ExternalSuspensionsJson", "[]")
	player:SetAttribute("USARF_ExternalSuspensionCount", 0)
	setLegacyExternalSuspensionAttributes(player, nil)

	task.delay(8, function()
		checkModerationStatus(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)

	for requestKey, requestState in pairs(
		OpenCaseRequests
		) do
		if string.find(
			requestKey,
			":" .. tostring(player.UserId),
			1,
			true
			) then
			if not requestState.inProgress then
				OpenCaseRequests[requestKey] = nil
			end
		end
	end
end)

_G.USARFDiscordBotBridge = Bridge

print("[DiscordBotBridge] Loaded")

task.spawn(function()
	while true do
		task.wait(LIVE_CHECK_INTERVAL)

		for _, player in ipairs(
			Players:GetPlayers()
			) do
			task.spawn(function()
				checkModerationStatus(player)
			end)
		end
	end
end)

return Bridge