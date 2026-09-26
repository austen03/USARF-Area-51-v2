local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")

local EventServerService = {}

local REGISTRY_NAME = "USARF_EventServerRegistry_v3"
local BOOTSTRAP_NAME = "USARF_EventServerBootstrap_v3"
local CONTROL_TOPIC = "USARF_EventServerControl_v3"

local REGISTRY_KEY = "active"
local ACTIVE_TTL = 120
local PENDING_TTL = 21600
local BOOTSTRAP_TTL = 21600
local HEARTBEAT_INTERVAL = 25
local DEFAULT_EVENT_NAME = "Event Server"

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local State = USARF:FindFirstChild("State")

if not State then
	State = Instance.new("Folder")
	State.Name = "State"
	State.Parent = USARF
end

local Services = ServerScriptService
	:WaitForChild("USARF")
	:WaitForChild("Services")

local CmdrPermissionService = require(
	Services:WaitForChild("CmdrPermissionService")
)

local registry = MemoryStoreService:GetSortedMap(REGISTRY_NAME)
local bootstrapMap = MemoryStoreService:GetSortedMap(BOOTSTRAP_NAME)

local started = false
local heartbeatGeneration = 0
local controlSubscription = nil

local isEventHost = false
local enabled = false
local displayName = DEFAULT_EVENT_NAME
local accessCode = nil
local privateServerId = nil
local enabledAt = nil
local enabledBy = nil
local lockedTeams = {}

local function getOrCreate(parent, className, name)
	local existing = parent:FindFirstChild(name)

	if existing then
		return existing
	end

	local object = Instance.new(className)
	object.Name = name
	object.Parent = parent
	return object
end

local GetEventServerStatus = getOrCreate(
	Remotes,
	"RemoteFunction",
	"GetEventServerStatus"
)

local EventServerStatusChanged = getOrCreate(
	Remotes,
	"RemoteEvent",
	"EventServerStatusChanged"
)

local MenuPayloadChanged = getOrCreate(
	Remotes,
	"RemoteEvent",
	"MenuPayloadChanged"
)

local function clean(value)
	return tostring(value or "")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
end

local function updateReplicatedState()
	State:SetAttribute("USARF_EventServerHost", isEventHost)
	State:SetAttribute("USARF_EventServerEnabled", enabled)
	State:SetAttribute("USARF_EventServerName", displayName)
	State:SetAttribute("USARF_EventServerEnabledAt", enabledAt)
	State:SetAttribute("USARF_EventServerEnabledBy", enabledBy)
end

local function buildHostRecord()
	return {
		enabled = enabled,
		state = "active",
		name = displayName,
		jobId = game.JobId,
		placeId = game.PlaceId,
		playerCount = #Players:GetPlayers(),
		maxPlayers = Players.MaxPlayers,
		enabledAt = enabledAt,
		enabledBy = enabledBy,
		updatedAt = os.time(),
		expiresAt = os.time() + ACTIVE_TTL,
		privateServerId = privateServerId or game.PrivateServerId,
		accessCode = accessCode,
	}
end

local function publicPacket(record)
	record = record or {}

	local recordPrivateId = tostring(record.privateServerId or "")
	local currentPrivateId = tostring(game.PrivateServerId or "")

	local currentEventServer = record.enabled == true
		and recordPrivateId ~= ""
		and currentPrivateId ~= ""
		and recordPrivateId == currentPrivateId

	return {
		enabled = record.enabled == true,
		state = record.state or "offline",
		name = record.name or DEFAULT_EVENT_NAME,
		placeId = tonumber(record.placeId) or game.PlaceId,
		playerCount = tonumber(record.playerCount) or 0,
		maxPlayers = tonumber(record.maxPlayers) or Players.MaxPlayers,
		enabledAt = record.enabledAt,
		enabledBy = record.enabledBy,

		-- These are calculated on the server. The client must not read
		-- DataModel.PrivateServerId directly.
		isCurrentServer = currentEventServer,
		isMainPublicServer = currentPrivateId == "",
	}
end

local function getInternalRecord()
	if isEventHost and enabled then
		return buildHostRecord()
	end

	local success, result = pcall(function()
		return registry:GetAsync(REGISTRY_KEY)
	end)

	if not success then
		warn("[EventServerService] Registry lookup failed:", result)
		return nil
	end

	if type(result) ~= "table"
		or result.enabled ~= true
		or (tonumber(result.expiresAt) or 0) <= os.time()
	then
		return nil
	end

	return result
end

local function broadcastStatus()
	local status = EventServerService.GetPublicStatus()

	EventServerStatusChanged:FireAllClients(status)

	for _, player in ipairs(Players:GetPlayers()) do
		MenuPayloadChanged:FireClient(player, {
			reason = "event_server_updated",
			timestamp = os.time(),
		})
	end
end

local function writeRegistry(record, ttl)
	local success, result = pcall(function()
		registry:SetAsync(
			REGISTRY_KEY,
			record,
			ttl,
			tonumber(record.updatedAt) or os.time()
		)
	end)

	if not success then
		warn("[EventServerService] Registry write failed:", result)
		return false, result
	end

	return true
end

local function publishHeartbeat()
	if not (isEventHost and enabled and accessCode) then
		return false
	end

	local record = buildHostRecord()
	return writeRegistry(record, ACTIVE_TTL)
end

local function removeRegistryEntry(expectedPrivateServerId)
	local current = nil

	pcall(function()
		current = registry:GetAsync(REGISTRY_KEY)
	end)

	if type(current) == "table"
		and expectedPrivateServerId
		and expectedPrivateServerId ~= ""
		and tostring(current.privateServerId or "")
		~= tostring(expectedPrivateServerId)
	then
		return
	end

	local success, result = pcall(function()
		registry:RemoveAsync(REGISTRY_KEY)
	end)

	if not success then
		warn("[EventServerService] Registry removal failed:", result)
	end
end

local function startHeartbeat()
	heartbeatGeneration += 1
	local generation = heartbeatGeneration

	task.spawn(function()
		while enabled
			and isEventHost
			and heartbeatGeneration == generation
		do
			publishHeartbeat()
			task.wait(HEARTBEAT_INTERVAL)
		end
	end)
end

local function disableLocalHost()
	if not isEventHost then
		return
	end

	enabled = false
	heartbeatGeneration += 1

	removeRegistryEntry(privateServerId or game.PrivateServerId)

	table.clear(lockedTeams)
	updateReplicatedState()
	broadcastStatus()
end

local function handleControlMessage(message)
	local data = message and message.Data

	if type(data) ~= "table"
		or data.action ~= "disable"
		or not isEventHost
	then
		return
	end

	local targetPrivateId = tostring(data.privateServerId or "")

	if targetPrivateId ~= ""
		and targetPrivateId ~= tostring(game.PrivateServerId)
	then
		return
	end

	disableLocalHost()
end

local function tryBootstrapReservedHost()
	if game.PrivateServerId == ""
		or game.PrivateServerOwnerId ~= 0
	then
		return false
	end

	local success, bootstrap = pcall(function()
		return bootstrapMap:GetAsync(game.PrivateServerId)
	end)

	if not success then
		warn("[EventServerService] Bootstrap lookup failed:", bootstrap)
		return false
	end

	if type(bootstrap) ~= "table"
		or type(bootstrap.accessCode) ~= "string"
		or bootstrap.accessCode == ""
	then
		return false
	end

	isEventHost = true
	enabled = true
	accessCode = bootstrap.accessCode
	privateServerId = game.PrivateServerId
	displayName = clean(bootstrap.name)

	if displayName == "" then
		displayName = DEFAULT_EVENT_NAME
	end

	enabledAt = tonumber(bootstrap.enabledAt) or os.time()
	enabledBy = bootstrap.enabledBy or "SYSTEM"

	pcall(function()
		bootstrapMap:RemoveAsync(game.PrivateServerId)
	end)

	updateReplicatedState()
	publishHeartbeat()
	startHeartbeat()
	broadcastStatus()

	print(
		"[EventServerService] Reserved event host activated:",
		displayName
	)

	return true
end

function EventServerService.IsEventHost()
	return isEventHost
end

function EventServerService.IsEnabled()
	return enabled
end

function EventServerService.GetDisplayName()
	local active = getInternalRecord()

	if active and active.name then
		return tostring(active.name)
	end

	return displayName
end

function EventServerService.GetActiveEventServerInternal()
	return getInternalRecord()
end

function EventServerService.GetPublicStatus()
	return publicPacket(getInternalRecord())
end

function EventServerService.CreateReservedEventServer(executor)
	if isEventHost then
		return false, "This server is already the event server."
	end

	local existing = getInternalRecord()

	if existing then
		return false, "An event server is already enabled: "
			.. tostring(existing.name or DEFAULT_EVENT_NAME)
	end

	local success, reservedCode, reservedPrivateServerId =
		pcall(function()
			return TeleportService:ReserveServerAsync(game.PlaceId)
		end)

	if not success then
		return false, "Unable to reserve an event server: "
			.. tostring(reservedCode)
	end

	local createdAt = os.time()

	local bootstrap = {
		accessCode = reservedCode,
		name = displayName,
		enabledAt = createdAt,
		enabledBy = executor and executor.Name or "SYSTEM",
		placeId = game.PlaceId,
		privateServerId = reservedPrivateServerId,
	}

	local storedBootstrap, bootstrapError = pcall(function()
		bootstrapMap:SetAsync(
			reservedPrivateServerId,
			bootstrap,
			BOOTSTRAP_TTL,
			createdAt
		)
	end)

	if not storedBootstrap then
		return false, "Unable to prepare the event server: "
			.. tostring(bootstrapError)
	end

	local pendingRecord = {
		enabled = true,
		state = "ready",
		name = displayName,
		jobId = nil,
		placeId = game.PlaceId,
		playerCount = 0,
		maxPlayers = Players.MaxPlayers,
		enabledAt = createdAt,
		enabledBy = executor and executor.Name or "SYSTEM",
		updatedAt = createdAt,
		expiresAt = createdAt + PENDING_TTL,
		privateServerId = reservedPrivateServerId,
		accessCode = reservedCode,
	}

	local storedRecord, recordError =
		writeRegistry(pendingRecord, PENDING_TTL)

	if not storedRecord then
		pcall(function()
			bootstrapMap:RemoveAsync(reservedPrivateServerId)
		end)

		return false, "Unable to publish the event server: "
			.. tostring(recordError)
	end

	broadcastStatus()

	return true, "Event server enabled and ready to join from the Servers page."
end

function EventServerService.DisableActiveEventServer(executor)
	local active = getInternalRecord()

	if not active then
		return true, "Event server is already disabled."
	end

	removeRegistryEntry(active.privateServerId)

	pcall(function()
		if active.privateServerId then
			bootstrapMap:RemoveAsync(active.privateServerId)
		end
	end)

	local published, publishError = pcall(function()
		MessagingService:PublishAsync(CONTROL_TOPIC, {
			action = "disable",
			privateServerId = active.privateServerId,
			disabledBy = executor and executor.Name or "SYSTEM",
			disabledAt = os.time(),
		})
	end)

	if not published then
		warn(
			"[EventServerService] Disable message failed:",
			publishError
		)
	end

	if isEventHost
		and tostring(active.privateServerId or "")
		== tostring(game.PrivateServerId)
	then
		disableLocalHost()
	else
		broadcastStatus()
	end

	return true, "Event server disabled and removed from the server list."
end

function EventServerService.SetActiveDisplayName(value)
	value = clean(value)

	if value == "" then
		return false, "Event server name cannot be empty."
	end

	value = string.sub(value, 1, 60)

	if isEventHost and enabled then
		displayName = value
		updateReplicatedState()
		publishHeartbeat()
		broadcastStatus()
		return true, displayName
	end

	local active = getInternalRecord()

	if not active then
		displayName = value
		updateReplicatedState()
		return true, displayName
	end

	active.name = value
	active.updatedAt = os.time()

	if active.state == "active" then
		active.expiresAt = os.time() + ACTIVE_TTL
		writeRegistry(active, ACTIVE_TTL)
	else
		active.expiresAt = os.time() + PENDING_TTL
		writeRegistry(active, PENDING_TTL)
	end

	if active.privateServerId then
		pcall(function()
			local bootstrap =
				bootstrapMap:GetAsync(active.privateServerId)

			if type(bootstrap) == "table" then
				bootstrap.name = value

				bootstrapMap:SetAsync(
					active.privateServerId,
					bootstrap,
					BOOTSTRAP_TTL,
					os.time()
				)
			end
		end)
	end

	displayName = value
	updateReplicatedState()
	broadcastStatus()

	return true, value
end

function EventServerService.ClearDisplayName()
	return EventServerService.SetActiveDisplayName(
		DEFAULT_EVENT_NAME
	)
end

function EventServerService.GetEventLink()
	local active = getInternalRecord()

	if not active then
		return nil, "No event server is currently active."
	end

	if type(active.accessCode) ~= "string"
		or active.accessCode == ""
	then
		return nil, "The event server access code is unavailable."
	end

	return string.format(
		"https://www.roblox.com/games/start?placeId=%d&accessCode=%s",
		tonumber(active.placeId) or game.PlaceId,
		HttpService:UrlEncode(active.accessCode)
	)
end

function EventServerService.CanBypassTeamLocks(player)
	if not player then
		return false
	end

	local _, levelValue =
		CmdrPermissionService.GetAdminLevel(player)

	return (tonumber(levelValue) or 0) >= 4
end

function EventServerService.IsTeamLocked(teamKey)
	return isEventHost
		and enabled
		and lockedTeams[teamKey] == true
end

function EventServerService.SetTeamLocked(teamKey, value)
	if not (isEventHost and enabled) then
		return false, "Team locks can only be changed from inside the active event server."
	end

	if value == true then
		lockedTeams[teamKey] = true
	else
		lockedTeams[teamKey] = nil
	end

	broadcastStatus()
	return true, lockedTeams[teamKey] == true
end

function EventServerService.ClearTeamLocks()
	table.clear(lockedTeams)
	broadcastStatus()
	return true
end

function EventServerService.GetLockedTeams()
	local results = {}

	for teamKey, locked in pairs(lockedTeams) do
		if locked == true then
			table.insert(results, teamKey)
		end
	end

	table.sort(results)
	return results
end

function EventServerService.GetTeamLockAccess(player, teamKey)
	if not EventServerService.IsTeamLocked(teamKey) then
		return true
	end

	if EventServerService.CanBypassTeamLocks(player) then
		return true
	end

	return false, "This team is locked for the current event."
end

function EventServerService.Start()
	if started then
		return
	end

	started = true
	updateReplicatedState()

	GetEventServerStatus.OnServerInvoke = function()
		return EventServerService.GetPublicStatus()
	end

	local subscribed, result = pcall(function()
		return MessagingService:SubscribeAsync(
			CONTROL_TOPIC,
			handleControlMessage
		)
	end)

	if subscribed then
		controlSubscription = result
	else
		warn(
			"[EventServerService] Control subscription failed:",
			result
		)
	end

	tryBootstrapReservedHost()

	Players.PlayerAdded:Connect(function()
		if isEventHost and enabled then
			task.defer(publishHeartbeat)
		end
	end)

	Players.PlayerRemoving:Connect(function()
		if isEventHost and enabled then
			task.delay(0.25, publishHeartbeat)
		end
	end)

	game:BindToClose(function()
		if isEventHost and enabled then
			removeRegistryEntry(
				privateServerId or game.PrivateServerId
			)
		end

		if controlSubscription then
			controlSubscription:Disconnect()
		end
	end)

	print("[EventServerService] Started")
end

return EventServerService
