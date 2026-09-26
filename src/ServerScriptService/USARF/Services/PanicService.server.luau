local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local USARFFolder = ReplicatedStorage:WaitForChild("USARF")
local ConfigFolder = USARFFolder:WaitForChild("Config")
local RemotesFolder = USARFFolder:WaitForChild("Remotes")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local Config = require(ConfigFolder:WaitForChild("PanicConfig"))
local AuditService = require(Services:WaitForChild("AuditService"))
local NotificationService = require(Services:WaitForChild("NotificationService"))

local remote = RemotesFolder:FindFirstChild(Config.RemoteName)
if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = Config.RemoteName
	remote.Parent = RemotesFolder
end

local lastPanic = {}

local function getTeamName(player)
	local attributeTeamName = player:GetAttribute("USARF_TeamName")
	if attributeTeamName and attributeTeamName ~= "" then
		return attributeTeamName
	end

	return player.Team and player.Team.Name or "No Team"
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

local function getVIPLabel(player)
	local teamName = getTeamName(player)

	if Config.BlockedTeamNames[teamName] then
		return nil
	end

	for _, rule in ipairs(Config.VIPRules) do
		if rule.TeamNames and rule.TeamNames[teamName] then
			return rule.Label
		end
	end

	return nil
end

local function canReceivePanic(player)
	local teamName = getTeamName(player)
	local mainRank = getMainRank(player)
	local ssRank = getSecretServiceRank(player)

	if Config.ReceiverRules.SecretServiceTeamNames[teamName]
		and ssRank >= Config.ReceiverRules.SecretServiceMinimumRank then
		return true
	end

	if mainRank >= Config.ReceiverRules.LeadershipMainMinimumRank then
		return true
	end

	return false
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

	local parts = Workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(5, 14, 5), params)

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

	return bestPart and bestPart.Name or Config.UnknownLocationName
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

local function logPanic(actor, vipLabel, locationName)
	AuditService.Log({
		category = "Protection",
		action = "PanicActivated",
		actor = actor,
		target = actor,
		message = vipLabel .. " panic activated at " .. locationName .. ".",
		severity = "Warning",
		metadata = {
			vipLabel = vipLabel,
			locationName = locationName,
			teamName = getTeamName(actor),
		},
	})
end

local function activatePanic(player)
	local vipLabel = getVIPLabel(player)

	if not vipLabel then
		return {
			Success = false,
			Message = "",
		}
	end

	local now = os.clock()
	local last = lastPanic[player] or 0

	if now - last < Config.CooldownSeconds then
		return {
			Success = false,
			Message = "Panic cooldown active.",
		}
	end

	lastPanic[player] = now

	local locationName = getPlayerLocation(player)
	local alertTitle = vipLabel .. " Panic Activated"
	local alertMessage = "Location: " .. locationName

	logPanic(player, vipLabel, locationName)

	for _, receiver in ipairs(Players:GetPlayers()) do
		if receiver ~= player and canReceivePanic(receiver) then
			NotificationService.Notify(receiver, {
				Title = alertTitle,
				Message = alertMessage,
				Type = "ProtectionAlert",
				Size = "Large",
				Duration = 7,
			})
		end
	end

	NotificationService.Notify(player, {
		Title = alertTitle,
		Message = alertMessage,
		Type = "Warning",
		Size = "Small",
		Duration = 5,
	})

	return {
		Success = true,
		Message = "",
		LocationName = locationName,
		VIPLabel = vipLabel,
	}
end

remote.OnServerInvoke = function(player, action)
	if action == "ActivatePanic" then
		return activatePanic(player)
	end

	if action == "GetAccess" then
		return {
			Success = true,
			HasAccess = getVIPLabel(player) ~= nil,
		}
	end

	return {
		Success = false,
		Message = "Unknown action.",
	}
end

Players.PlayerRemoving:Connect(function(player)
	lastPanic[player] = nil
end)

print("[PanicService] Loaded.")