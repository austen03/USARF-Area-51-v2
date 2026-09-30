local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local USARFFolder = ReplicatedStorage:WaitForChild("USARF")
local ConfigFolder = USARFFolder:WaitForChild("Config")
local RemotesFolder = USARFFolder:WaitForChild("Remotes")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local Config = require(ConfigFolder:WaitForChild("ScramblerConfig"))
local MainGroupRanks = require(ConfigFolder:WaitForChild("MainGroupRanks"))
local AuditService = require(Services:WaitForChild("AuditService"))
local NameTagService = require(Services:WaitForChild("NameTagService"))

local remote = RemotesFolder:FindFirstChild(Config.RemoteName)
if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = Config.RemoteName
	remote.Parent = RemotesFolder
end

local activeScramblers = {}
local lastToggle = {}
local hiddenGuis = {}

local function getTeamName(player)
	return player.Team and player.Team.Name or nil
end

local function setScramblerAttribute(player, enabled)
	player:SetAttribute("USARF_Scrambled", enabled == true)

	if player.Character then
		player.Character:SetAttribute("USARF_Scrambled", enabled == true)
	end
end

local function isCloaked(player)
	return player.Character and CollectionService:HasTag(player.Character, "USARF_Cloaked")
end

local function hasScramblerAccess(player)
	if not player then
		return false, "Missing player."
	end

	local teamName = getTeamName(player)
	if not teamName then
		return false, "You must be on an authorized team."
	end

	local teamRule = Config.AllowedTeams[teamName]
	if not teamRule then
		return false
	end

	local mainRank = MainGroupRanks.EffectiveRank(Config.MainGroupId, player:GetRankInGroup(Config.MainGroupId))

	if mainRank >= Config.MainGroupMinimumRank then
		return true, "Main group override."
	end

	if player:GetRankInGroup(teamRule.GroupId) >= teamRule.MinimumRank then
		return true, "Department authorized."
	end

	return false, "Insufficient department rank."
end

local function logScramblerAction(actor, action, message, metadata)
	AuditService.Log({
		category = "ScramblerSystem",
		action = action,
		actor = actor,
		target = actor,
		message = message,
		severity = "Info",
		metadata = metadata or {},
	})
end

local function canToggle(player)
	local now = os.clock()
	local last = lastToggle[player] or 0

	if now - last < Config.CooldownSeconds then
		return false
	end

	lastToggle[player] = now
	return true
end

local function isNameTagGui(instance)
	if not instance:IsA("BillboardGui") and not instance:IsA("SurfaceGui") then
		return false
	end

	if instance.Name == Config.BillboardName then
		return false
	end

	local loweredName = string.lower(instance.Name)

	return string.find(loweredName, "nametag", 1, true)
		or string.find(loweredName, "rank", 1, true)
		or string.find(loweredName, "overhead", 1, true)
		or instance.Name == "USARFNameTag"
end

local function hideExistingNameTags(player)
	if not Config.HideNameTags then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	hiddenGuis[player] = hiddenGuis[player] or {}

	for _, descendant in ipairs(character:GetDescendants()) do
		if isNameTagGui(descendant) then
			if hiddenGuis[player][descendant] == nil then
				hiddenGuis[player][descendant] = descendant.Enabled
			end

			descendant.Enabled = false
		end
	end
end

local function restoreExistingNameTags(player)
	local saved = hiddenGuis[player]

	if saved then
		for guiObject, wasEnabled in pairs(saved) do
			if guiObject and guiObject.Parent then
				guiObject.Enabled = wasEnabled
			end
		end
	end

	hiddenGuis[player] = nil

	task.defer(function()
		task.wait(0.15)

		if player and player.Parent and player.Character and not activeScramblers[player] and not isCloaked(player) then
			NameTagService.Refresh(player)
		end
	end)
end

local function createScramblerBillboard(player)
	local character = player.Character
	if not character then
		return false, "Character not ready."
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return false, "Head not ready."
	end

	local existing = head:FindFirstChild(Config.BillboardName)
	if existing then
		existing.Enabled = true
		return true
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = Config.BillboardName
	billboard.Adornee = head
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(180, 62)
	billboard.StudsOffset = Vector3.new(0, 3.05, 0)
	billboard.LightInfluence = 0
	billboard.MaxDistance = 140
	billboard.Parent = head

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = billboard

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, -1)
	layout.Parent = container

	local top = Instance.new("TextLabel")
	top.Name = "Top"
	top.Size = UDim2.new(1, 0, 0, 14)
	top.BackgroundTransparency = 1
	top.Text = Config.BillboardTextTop
	top.TextColor3 = Color3.fromRGB(155, 155, 155)
	top.TextStrokeTransparency = 0.65
	top.TextScaled = true
	top.Font = Enum.Font.Code
	top.LayoutOrder = 1
	top.Parent = container

	local main = Instance.new("TextLabel")
	main.Name = "Main"
	main.Size = UDim2.new(1, 0, 0, 26)
	main.BackgroundTransparency = 1
	main.Text = Config.BillboardTextMain
	main.TextColor3 = Color3.fromRGB(245, 245, 245)
	main.TextStrokeTransparency = 0.25
	main.TextScaled = true
	main.Font = Enum.Font.GothamBlack
	main.LayoutOrder = 2
	main.Parent = container

	local bottom = Instance.new("TextLabel")
	bottom.Name = "Bottom"
	bottom.Size = UDim2.new(1, 0, 0, 16)
	bottom.BackgroundTransparency = 1
	bottom.Text = Config.BillboardTextBottom
	bottom.TextColor3 = Color3.fromRGB(185, 185, 185)
	bottom.TextStrokeTransparency = 0.55
	bottom.TextScaled = true
	bottom.Font = Enum.Font.GothamBold
	bottom.LayoutOrder = 3
	bottom.Parent = container

	return true
end

local function removeScramblerBillboard(player)
	local character = player.Character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	local existing = head:FindFirstChild(Config.BillboardName)
	if existing then
		existing:Destroy()
	end
end

local function setScrambler(player, enabled)
	local character = player.Character
	if not character then
		return false, "Character not ready."
	end

	if enabled then
		if isCloaked(player) then
			return false, "Scrambler cannot be enabled while cloaked."
		end

		local success, reason = createScramblerBillboard(player)
		if not success then
			return false, reason
		end

		activeScramblers[player] = true
		setScramblerAttribute(player, true)
		CollectionService:AddTag(character, Config.CharacterTag)
		hideExistingNameTags(player)
	else
		activeScramblers[player] = nil
		setScramblerAttribute(player, false)
		CollectionService:RemoveTag(character, Config.CharacterTag)
		removeScramblerBillboard(player)
		restoreExistingNameTags(player)
	end

	return true
end

local function forceDisableScrambler(player, reason)
	if not activeScramblers[player] then
		return false
	end

	setScrambler(player, false)

	logScramblerAction(player, "ForceDisabled", reason or "Scrambler was force-disabled.", {
		teamName = getTeamName(player),
	})

	return true
end

local function setupCharacter(player, character)
	activeScramblers[player] = nil
	hiddenGuis[player] = nil
	setScramblerAttribute(player, false)

	character.DescendantAdded:Connect(function(descendant)
		if activeScramblers[player] and isNameTagGui(descendant) then
			task.defer(function()
				if descendant and descendant.Parent then
					hiddenGuis[player] = hiddenGuis[player] or {}
					hiddenGuis[player][descendant] = descendant.Enabled
					descendant.Enabled = false
				end
			end)
		end
	end)

	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Died:Connect(function()
			forceDisableScrambler(player, "Scrambler removed due to death.")
		end)
	end
end

local function setupPlayer(player)
	player:SetAttribute("USARF_Scrambled", false)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		forceDisableScrambler(player, "Scrambler removed due to team change.")
	end)

	player.CharacterRemoving:Connect(function()
		forceDisableScrambler(player, "Scrambler removed due to character removal.")
	end)

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)

	if player.Character then
		setupCharacter(player, player.Character)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	activeScramblers[player] = nil
	lastToggle[player] = nil
	hiddenGuis[player] = nil
end)

remote.OnServerInvoke = function(player, action)
	if action ~= "Toggle" and action ~= "GetState" and action ~= "ForceDisable" then
		return {
			Success = false,
			Message = "Unknown action.",
		}
	end

	if action == "ForceDisable" then
		local removed = forceDisableScrambler(player, "Scrambler removed.")

		return {
			Success = true,
			Message = removed and "Scrambler disabled." or "",
			IsScrambled = false,
		}
	end

	local allowed, denyReason = hasScramblerAccess(player)
	if not allowed then
		logScramblerAction(player, "UnauthorizedAccess", "Unauthorized scrambler request blocked.", {
			teamName = getTeamName(player),
			requestedAction = tostring(action),
			denyReason = denyReason,
			mainRank = player:GetRankInGroup(Config.MainGroupId),
		})

		return {
			Success = false,
			Message = denyReason,
			IsScrambled = false,
		}
	end

	if action == "GetState" then
		return {
			Success = true,
			IsScrambled = activeScramblers[player] == true,
		}
	end

	if isCloaked(player) then
		return {
			Success = false,
			Message = "Scrambler cannot be toggled while cloaked.",
			IsScrambled = false,
		}
	end

	if not canToggle(player) then
		return {
			Success = false,
			Message = "Scrambler cooldown active.",
			IsScrambled = activeScramblers[player] == true,
		}
	end

	local newState = activeScramblers[player] ~= true
	local success, failReason = setScrambler(player, newState)

	if not success then
		return {
			Success = false,
			Message = failReason or "Character not ready.",
			IsScrambled = false,
		}
	end

	logScramblerAction(player, newState and "Enabled" or "Disabled", newState and "Player enabled scrambler." or "Player disabled scrambler.", {
		teamName = getTeamName(player),
		enabled = newState,
		mainRank = player:GetRankInGroup(Config.MainGroupId),
	})

	return {
		Success = true,
		Message = newState and "Scrambler enabled." or "Scrambler disabled.",
		IsScrambled = newState,
	}
end

print("[ScramblerService] Loaded.")