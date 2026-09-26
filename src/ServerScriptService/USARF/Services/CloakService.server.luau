local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local USARFFolder = ReplicatedStorage:WaitForChild("USARF")
local ConfigFolder = USARFFolder:WaitForChild("Config")
local RemotesFolder = USARFFolder:WaitForChild("Remotes")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local Config = require(ConfigFolder:WaitForChild("CloakConfig"))
local AuditService = require(Services:WaitForChild("AuditService"))

local remote = RemotesFolder:FindFirstChild(Config.RemoteName)
if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = Config.RemoteName
	remote.Parent = RemotesFolder
end

local activeCloaks = {}
local lastToggle = {}
local originalValues = {}

local function getTeamName(player)
	return player.Team and player.Team.Name or nil
end

local function setCloakAttribute(player, enabled)
	player:SetAttribute("USARF_Cloaked", enabled == true)

	if player.Character then
		player.Character:SetAttribute("USARF_Cloaked", enabled == true)
	end
end

local function hasCloakAccess(player)
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

	if player:GetRankInGroup(Config.MainGroupId) >= Config.MainGroupMinimumRank then
		return true, "Main group override."
	end

	if player:GetRankInGroup(teamRule.GroupId) >= teamRule.MinimumRank then
		return true, "Department authorized."
	end

	return false, "Insufficient department rank."
end

local function logCloakAction(actor, action, message, metadata)
	AuditService.Log({
		category = "CloakSystem",
		action = action,
		actor = actor,
		target = actor,
		message = message,
		severity = "Info",
		metadata = metadata or {},
	})
end

local function saveOriginal(instance)
	if originalValues[instance] then
		return
	end

	if instance:IsA("BasePart") or instance:IsA("Decal") or instance:IsA("Texture") then
		originalValues[instance] = {
			Transparency = instance.Transparency,
		}
	elseif instance:IsA("SurfaceGui") or instance:IsA("BillboardGui") then
		originalValues[instance] = {
			Enabled = instance.Enabled,
		}
	end
end

local function restoreOriginal(instance)
	local saved = originalValues[instance]
	if not saved then
		return
	end

	if saved.Transparency ~= nil and (instance:IsA("BasePart") or instance:IsA("Decal") or instance:IsA("Texture")) then
		instance.Transparency = saved.Transparency
	end

	if saved.Enabled ~= nil and (instance:IsA("SurfaceGui") or instance:IsA("BillboardGui")) then
		instance.Enabled = saved.Enabled
	end

	originalValues[instance] = nil
end

local function shouldAffect(instance)
	if instance.Name == "HumanoidRootPart" then
		return false
	end

	if instance:IsA("BasePart") then
		return true
	end

	if instance:IsA("Decal") or instance:IsA("Texture") then
		return true
	end

	if Config.HideNameTags and (instance:IsA("SurfaceGui") or instance:IsA("BillboardGui")) then
		return true
	end

	return false
end

local function applyCloakToInstance(instance)
	if not shouldAffect(instance) then
		return
	end

	saveOriginal(instance)

	if instance:IsA("BasePart") or instance:IsA("Decal") or instance:IsA("Texture") then
		instance.Transparency = Config.FullyInvisibleTransparency
	elseif instance:IsA("SurfaceGui") or instance:IsA("BillboardGui") then
		instance.Enabled = false
	end
end

local function setCharacterCloaked(player, enabled)
	local character = player.Character
	if not character then
		return false, "Character not ready."
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false, "Humanoid not ready."
	end

	if enabled then
		activeCloaks[player] = true
		setCloakAttribute(player, true)
		CollectionService:AddTag(character, "USARF_Cloaked")

		for _, descendant in ipairs(character:GetDescendants()) do
			applyCloakToInstance(descendant)
		end

		if Config.AddInvisibleForceField and not character:FindFirstChild("USARF_CloakForceField") then
			local forceField = Instance.new("ForceField")
			forceField.Name = "USARF_CloakForceField"
			forceField.Visible = false
			forceField.Parent = character
		end

		humanoid.WalkSpeed = Config.CloakedWalkSpeed
	else
		activeCloaks[player] = nil
		setCloakAttribute(player, false)
		CollectionService:RemoveTag(character, "USARF_Cloaked")

		for _, descendant in ipairs(character:GetDescendants()) do
			restoreOriginal(descendant)
		end

		local forceField = character:FindFirstChild("USARF_CloakForceField")
		if forceField then
			forceField:Destroy()
		end

		humanoid.WalkSpeed = Config.DefaultWalkSpeed
	end

	return true
end

local function forceUncloak(player, reason)
	if not activeCloaks[player] then
		return false
	end

	setCharacterCloaked(player, false)

	logCloakAction(player, "ForceUncloak", reason or "Player was force-uncloaked.", {
		teamName = getTeamName(player),
	})

	return true
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

local function setupPlayer(player)
	player:SetAttribute("USARF_Cloaked", false)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		forceUncloak(player, "Cloak removed due to team change.")
	end)

	player.CharacterRemoving:Connect(function()
		forceUncloak(player, "Cloak removed due to character removal.")
	end)

	player.CharacterAdded:Connect(function(character)
		activeCloaks[player] = nil
		setCloakAttribute(player, false)

		character.DescendantAdded:Connect(function(descendant)
			if activeCloaks[player] then
				task.defer(function()
					applyCloakToInstance(descendant)
				end)
			end
		end)

		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.Died:Connect(function()
				forceUncloak(player, "Cloak removed due to death.")
			end)
		end
	end)
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	activeCloaks[player] = nil
	lastToggle[player] = nil
end)

remote.OnServerInvoke = function(player, action)
	if action ~= "Toggle" and action ~= "GetState" and action ~= "ForceUncloak" then
		return {
			Success = false,
			Message = "Unknown action.",
		}
	end

	if action == "ForceUncloak" then
		local removed = forceUncloak(player, "Cloak removed due to menu access.")

		return {
			Success = true,
			Message = removed and "Cloak removed." or "",
			IsCloaked = false,
		}
	end

	local allowed, denyReason = hasCloakAccess(player)
	if not allowed then
		logCloakAction(player, "UnauthorizedAccess", "Unauthorized cloak request blocked.", {
			teamName = getTeamName(player),
			requestedAction = tostring(action),
			denyReason = denyReason,
			mainRank = player:GetRankInGroup(Config.MainGroupId),
		})

		return {
			Success = false,
			Message = denyReason,
			IsCloaked = false,
		}
	end

	if action == "GetState" then
		return {
			Success = true,
			IsCloaked = activeCloaks[player] == true,
		}
	end

	if not canToggle(player) then
		return {
			Success = false,
			Message = "Cloak cooldown active.",
			IsCloaked = activeCloaks[player] == true,
		}
	end

	local newState = activeCloaks[player] ~= true
	local success, failReason = setCharacterCloaked(player, newState)

	if not success then
		return {
			Success = false,
			Message = failReason or "Character not ready.",
			IsCloaked = false,
		}
	end

	logCloakAction(player, newState and "CloakEnabled" or "CloakDisabled", newState and "Player enabled cloak." or "Player disabled cloak.", {
		teamName = getTeamName(player),
		enabled = newState,
		mainRank = player:GetRankInGroup(Config.MainGroupId),
	})

	return {
		Success = true,
		Message = newState and "Cloak enabled." or "Cloak disabled.",
		IsCloaked = newState,
	}
end

print("[CloakService] Loaded.")