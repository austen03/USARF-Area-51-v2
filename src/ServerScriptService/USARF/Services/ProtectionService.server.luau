local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local USARFFolder = ReplicatedStorage:WaitForChild("USARF")
local ConfigFolder = USARFFolder:WaitForChild("Config")
local RemotesFolder = USARFFolder:WaitForChild("Remotes")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local Config = require(ConfigFolder:WaitForChild("ProtectionConfig"))
local AuditService = require(Services:WaitForChild("AuditService"))

local remote = RemotesFolder:FindFirstChild(Config.RemoteName)
if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = Config.RemoteName
	remote.Parent = RemotesFolder
end

local zoneFolder = Workspace:FindFirstChild(Config.ZoneFolderName)
if not zoneFolder then
	zoneFolder = Instance.new("Folder")
	zoneFolder.Name = Config.ZoneFolderName
	zoneFolder.Parent = Workspace
end

local trackerEnabled = {}
local lastTrackerToggle = {}
local activeZones = {}

local function getTeamName(player)
	local attributeTeamName = player:GetAttribute("USARF_TeamName")
	if attributeTeamName and attributeTeamName ~= "" then
		return attributeTeamName
	end

	return player.Team and player.Team.Name or "No Team"
end

local function getTeamKey(player)
	return player:GetAttribute("USARF_TeamKey")
end

local function getMainRank(player)
	local success, rank = pcall(function()
		return player:GetRankInGroup(Config.MainGroupId)
	end)

	return success and rank or 0
end

local function getSecretServiceRank(player)
	local success, rank = pcall(function()
		return player:GetRankInGroup(Config.SecretServiceGroupId)
	end)

	return success and rank or 0
end

local function hasProtectionAccess(player)
	if not player then
		return false
	end

	local teamName = getTeamName(player)
	local mainRank = getMainRank(player)

	if Config.AccessRules.SecretService.TeamNames[teamName]
		and getSecretServiceRank(player) >= Config.AccessRules.SecretService.MinimumRank then
		return true
	end

	if mainRank >= Config.AccessRules.Leadership.MainGroupMinimumRank then
		return true
	end

	return false
end

local function hasZoneManagementAccess(player)
	if not player then
		return false
	end

	local teamName = getTeamName(player)
	local mainRank = getMainRank(player)
	local ssRank = getSecretServiceRank(player)

	if Config.AccessRules.SecretService.TeamNames[teamName]
		and ssRank >= Config.ZoneManagement.SecretServiceMinimumRank then
		return true
	end

	if mainRank >= Config.ZoneManagement.LeadershipMinimumRank then
		return true
	end

	return false
end

local function getVIPLabel(player)
	local teamName = getTeamName(player)
	local teamKey = getTeamKey(player)
	local mainRank = getMainRank(player)

	local bestLabel = nil
	local bestPriority = -math.huge

	for _, rule in ipairs(Config.VIPRules) do
		local matched = false

		if rule.TeamKeys and teamKey and rule.TeamKeys[teamKey] then
			matched = true
		end

		if rule.TeamNames and teamName and rule.TeamNames[teamName] then
			matched = true
		end

		if rule.MainGroupRanks and rule.MainGroupRanks[mainRank] then
			matched = true
		end

		if matched and rule.Priority > bestPriority then
			bestPriority = rule.Priority
			bestLabel = rule.Label
		end
	end

	return bestLabel
end

local function getLocationPriority(part)
	local priority = part:GetAttribute("Priority")
	if typeof(priority) == "number" then
		return priority
	end

	return 0
end

local function getLocationNameForPosition(position)
	local folder = Workspace:FindFirstChild(Config.LocationFolderName)
	if not folder then
		return Config.UnknownLocationName
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	params.RespectCanCollide = false

	local checkSize = Vector3.new(5, 14, 5)
	local parts = Workspace:GetPartBoundsInBox(CFrame.new(position), checkSize, params)

	local bestPart = nil
	local bestPriority = -math.huge

	for _, part in ipairs(parts) do
		if part:IsA("BasePart") and part.CanQuery ~= false then
			local priority = getLocationPriority(part)

			if priority > bestPriority then
				bestPriority = priority
				bestPart = part
			end
		end
	end

	if bestPart then
		return bestPart.Name
	end

	return Config.UnknownLocationName
end

local function getPlayerLocation(player)
	local character = player.Character
	if not character then
		return Config.UnknownLocationName
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return Config.UnknownLocationName
	end

	return getLocationNameForPosition(root.Position)
end

local function getVIPPayload()
	local payload = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local vipLabel = getVIPLabel(player)

		if vipLabel then
			table.insert(payload, {
				UserId = player.UserId,
				Name = player.Name,
				DisplayName = player.DisplayName,
				Label = vipLabel,
				TeamName = getTeamName(player),
				LocationName = getPlayerLocation(player),
			})
		end
	end

	table.sort(payload, function(a, b)
		if a.Label == b.Label then
			return a.Name < b.Name
		end

		return a.Label < b.Label
	end)

	return payload
end

local function logProtectionAction(actor, action, message, metadata)
	AuditService.Log({
		category = "Protection",
		action = action,
		actor = actor,
		target = nil,
		message = message,
		severity = "Info",
		metadata = metadata or {},
	})
end

local function getZoneKey(vipUserId, zoneType)
	return tostring(vipUserId) .. "_" .. tostring(zoneType)
end

local function getZoneSetting(zoneType)
	return Config.ZoneSettings[zoneType]
end

local function clampRadius(zoneType, radius)
	local settings = getZoneSetting(zoneType)
	if not settings then
		return nil
	end

	radius = tonumber(radius) or settings.DefaultRadius
	return math.clamp(radius, settings.MinRadius, settings.MaxRadius)
end

local function createZonePart(vipPlayer, zoneType, radius)
	local settings = getZoneSetting(zoneType)
	if not settings then
		return nil
	end

	local part = Instance.new("Part")
	part.Name = zoneType .. "_" .. vipPlayer.Name
	part.Shape = Enum.PartType.Cylinder
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = settings.Material
	part.Color = settings.Color
	part.Transparency = settings.Transparency
	part.Size = Vector3.new(settings.Height, radius * 2, radius * 2)
	part.Orientation = Vector3.new(0, 0, 90)
	part.Parent = zoneFolder

	return part
end

local function updateZonePosition(vipPlayer, zoneData)
	if not vipPlayer.Character then
		return
	end

	local root = vipPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	if zoneData.Part and zoneData.Part.Parent then
		zoneData.Part.Position = Vector3.new(root.Position.X, root.Position.Y - 2.8, root.Position.Z)
	end
end

local function removeZone(vipUserId, zoneType)
	local key = getZoneKey(vipUserId, zoneType)
	local zoneData = activeZones[key]

	if not zoneData then
		return false
	end

	if zoneData.Connection then
		zoneData.Connection:Disconnect()
	end

	if zoneData.Part then
		zoneData.Part:Destroy()
	end

	activeZones[key] = nil
	return true
end

local function createZone(actor, vipUserId, zoneType, radius)
	local vipPlayer = Players:GetPlayerByUserId(tonumber(vipUserId))
	if not vipPlayer then
		return false, "VIP not found."
	end

	local vipLabel = getVIPLabel(vipPlayer)
	if not vipLabel then
		return false, "Selected player is not a VIP."
	end

	local settings = getZoneSetting(zoneType)
	if not settings then
		return false, "Invalid zone type."
	end

	local finalRadius = clampRadius(zoneType, radius)
	local key = getZoneKey(vipPlayer.UserId, zoneType)

	removeZone(vipPlayer.UserId, zoneType)

	local part = createZonePart(vipPlayer, zoneType, finalRadius)
	if not part then
		return false, "Failed to create zone."
	end

	local zoneData = {
		Actor = actor,
		VIP = vipPlayer,
		VIPUserId = vipPlayer.UserId,
		VIPLabel = vipLabel,
		ZoneType = zoneType,
		Radius = finalRadius,
		Part = part,
		Connection = nil,
	}

	zoneData.Connection = RunService.Heartbeat:Connect(function()
		if not vipPlayer.Parent or not vipPlayer.Character then
			removeZone(vipPlayer.UserId, zoneType)
			return
		end

		updateZonePosition(vipPlayer, zoneData)
	end)

	activeZones[key] = zoneData
	updateZonePosition(vipPlayer, zoneData)

	logProtectionAction(actor, "Create" .. zoneType, zoneType .. " created around " .. vipLabel .. ".", {
		vipUserId = vipPlayer.UserId,
		vipName = vipPlayer.Name,
		vipLabel = vipLabel,
		zoneType = zoneType,
		radius = finalRadius,
	})

	return true, zoneType .. " created.", zoneData
end

local function getZonePayload()
	local zones = {}

	for _, zoneData in pairs(activeZones) do
		if zoneData.Part and zoneData.Part.Parent then
			table.insert(zones, {
				VIPUserId = zoneData.VIPUserId,
				VIPName = zoneData.VIP and zoneData.VIP.Name or "Unknown",
				VIPLabel = zoneData.VIPLabel,
				ZoneType = zoneData.ZoneType,
				Radius = zoneData.Radius,
			})
		end
	end

	table.sort(zones, function(a, b)
		if a.VIPLabel == b.VIPLabel then
			return a.ZoneType < b.ZoneType
		end

		return a.VIPLabel < b.VIPLabel
	end)

	return zones
end

remote.OnServerInvoke = function(player, action, data)
	data = data or {}

	if not hasProtectionAccess(player) then
		logProtectionAction(player, "UnauthorizedAccess", "Unauthorized protection request blocked.", {
			action = tostring(action),
			teamName = getTeamName(player),
			mainRank = getMainRank(player),
			secretServiceRank = getSecretServiceRank(player),
		})

		return {
			Success = false,
			Message = "",
		}
	end

	if action == "GetAccess" then
		return {
			Success = true,
			HasAccess = true,
		}
	end

	if action == "ToggleTracker" then
		local now = os.clock()
		local last = lastTrackerToggle[player] or 0

		if now - last < 1 then
			return {
				Success = false,
				Message = "Tracker cooldown active.",
				TrackerEnabled = trackerEnabled[player] == true,
			}
		end

		lastTrackerToggle[player] = now
		trackerEnabled[player] = not trackerEnabled[player]

		logProtectionAction(
			player,
			trackerEnabled[player] and "TrackerEnabled" or "TrackerDisabled",
			trackerEnabled[player] and "Protection system opened." or "Protection system closed.",
			{
				teamName = getTeamName(player),
			}
		)

		return {
			Success = true,
			Message = trackerEnabled[player] and "Protection system opened." or "Protection system closed.",
			TrackerEnabled = trackerEnabled[player],
			VIPs = getVIPPayload(),
			Zones = getZonePayload(),
			CanManageZones = hasZoneManagementAccess(player),
		}
	end

	if action == "GetTrackerData" then
		return {
			Success = true,
			TrackerEnabled = trackerEnabled[player] == true,
			VIPs = getVIPPayload(),
			Zones = getZonePayload(),
			CanManageZones = hasZoneManagementAccess(player),
		}
	end

	if action == "CreateZone" then
		if not hasZoneManagementAccess(player) then
			return {
				Success = false,
				Message = "Zone management restricted.",
			}
		end

		local success, message = createZone(player, data.VIPUserId, tostring(data.ZoneType), data.Radius)

		return {
			Success = success,
			Message = message,
			TrackerEnabled = trackerEnabled[player] == true,
			VIPs = getVIPPayload(),
			Zones = getZonePayload(),
			CanManageZones = true,
		}
	end

	if action == "RemoveZone" then
		if not hasZoneManagementAccess(player) then
			return {
				Success = false,
				Message = "Zone management restricted.",
			}
		end

		local vipUserId = tonumber(data.VIPUserId)
		local zoneType = tostring(data.ZoneType)

		local removed = removeZone(vipUserId, zoneType)

		logProtectionAction(player, "Remove" .. zoneType, zoneType .. " removed.", {
			vipUserId = vipUserId,
			zoneType = zoneType,
		})

		return {
			Success = true,
			Message = removed and zoneType .. " removed." or "No active " .. zoneType .. " found.",
			TrackerEnabled = trackerEnabled[player] == true,
			VIPs = getVIPPayload(),
			Zones = getZonePayload(),
			CanManageZones = true,
		}
	end

	return {
		Success = false,
		Message = "Unknown action.",
	}
end

Players.PlayerRemoving:Connect(function(player)
	trackerEnabled[player] = nil
	lastTrackerToggle[player] = nil

	for key, zoneData in pairs(activeZones) do
		if zoneData.VIPUserId == player.UserId then
			removeZone(zoneData.VIPUserId, zoneData.ZoneType)
		end
	end
end)

print("[ProtectionService] Loaded.")