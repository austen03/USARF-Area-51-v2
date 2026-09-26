local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARFFolder = ReplicatedStorage:WaitForChild("USARF")
local ConfigFolder = USARFFolder:WaitForChild("Config")
local RemotesFolder = USARFFolder:WaitForChild("Remotes")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local Config = require(ConfigFolder:WaitForChild("ClassifiedUtilityConfig"))
local AuditService = require(Services:WaitForChild("AuditService"))
local NotificationService = require(Services:WaitForChild("NotificationService"))

local remote = RemotesFolder:FindFirstChild(Config.BlackbagRemoteName)
if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = Config.BlackbagRemoteName
	remote.Parent = RemotesFolder
end

local blindedPlayers = {}
local markedPlayers = {}

local function getTeamName(player)
	return player.Team and player.Team.Name or nil
end

local function isModMode(player)
	return player
		and (
			player:GetAttribute("USARF_ModMode") == true
			or player:GetAttribute("USARF_RadioModMode") == true
		)
end

local function isCloaked(player)
	return player
		and (
			player:GetAttribute("USARF_Cloaked") == true
			or (player.Character and player.Character:GetAttribute("USARF_Cloaked") == true)
		)
end

local function isScrambled(player)
	return player
		and (
			player:GetAttribute("USARF_Scrambled") == true
			or (player.Character and player.Character:GetAttribute("USARF_Scrambled") == true)
		)
end

local function notify(player, title, message, style)
	NotificationService.Notify(player, {
		Title = title,
		Message = message,
		Type = style or "Normal",
		Duration = 4,
	})
end

local function hasUtilityAccess(player)
	if not player then
		return false
	end

	if isModMode(player) then
		return true
	end

	local teamName = getTeamName(player)
	if not teamName then
		return false
	end

	local teamRule = Config.AllowedTeams[teamName]
	if not teamRule then
		return false
	end

	if player:GetRankInGroup(Config.MainGroupId) >= Config.MainGroupMinimumRank then
		return true
	end

	return player:GetRankInGroup(teamRule.GroupId) >= teamRule.MinimumRank
end

local function isProtectedTarget(target)
	local teamName = getTeamName(target)
	return teamName and Config.ProtectedTargetTeams and Config.ProtectedTargetTeams[teamName] == true
end

local function canBypassTargetProtection(actor)
	return isModMode(actor)
end

local function shouldRedactTargetForActor(actor, target)
	if isModMode(actor) then
		return false
	end

	if isProtectedTarget(target) then
		return true
	end

	if isCloaked(target) then
		return true
	end

	if isScrambled(target) then
		return true
	end

	return false
end

local function logUtilityAction(actor, target, action, message, metadata)
	AuditService.Log({
		category = "ClassifiedUtility",
		action = action,
		actor = actor,
		target = target,
		message = message,
		severity = "Info",
		metadata = metadata or {},
	})
end

local function getPublicPlayerInfo(target, actor)
	local groupInfo = {}
	local protectedTarget = isProtectedTarget(target)
	local cloaked = isCloaked(target)
	local scrambled = isScrambled(target)
	local redacted = shouldRedactTargetForActor(actor, target)

	if not redacted then
		for _, groupData in ipairs(Config.GroupLabels) do
			local rank = 0
			local role = "Guest"

			local success = pcall(function()
				rank = target:GetRankInGroup(groupData.GroupId)
				role = target:GetRoleInGroup(groupData.GroupId)
			end)

			if success and rank > 0 then
				table.insert(groupInfo, {
					Label = groupData.Label,
					GroupId = groupData.GroupId,
					Rank = rank,
					Role = role,
				})
			end
		end
	end

	local displayName = target.Name
	local displayDisplayName = target.DisplayName
	local accountAge = target.AccountAge
	local isBlinded = blindedPlayers[target.UserId] == true
	local isMarked = markedPlayers[target.UserId] == true
	local teamName = target.Team and target.Team.Name or "No Team"

	if redacted then
		displayName = "CLASSIFIED"
		displayDisplayName = "CLASSIFIED"
		accountAge = 0
		isBlinded = false
		isMarked = false

		if cloaked then
			teamName = "CLOAKED PERSONNEL"
		elseif scrambled then
			teamName = "SCRAMBLED PERSONNEL"
		else
			teamName = "CLASSIFIED"
		end
	end

	return {
		Name = displayName,
		DisplayName = displayDisplayName,
		UserId = target.UserId,
		AccountAge = accountAge,
		Team = teamName,
		TeamColor = target.TeamColor.Color,

		IsBlinded = isBlinded,
		IsMarked = isMarked,
		IsProtected = protectedTarget,
		IsCloaked = cloaked,
		IsScrambled = scrambled,
		IsRedacted = redacted,

		Groups = groupInfo,
	}
end

local function rejectProtectedTarget(actor, target)
	if isProtectedTarget(target) and not canBypassTargetProtection(actor) then
		notify(actor, "Classified Utility", "Protected personnel cannot be targeted.", "Normal")

		logUtilityAction(actor, target, "ProtectedTargetBlocked", "Attempted to target protected classified personnel.", {
			targetTeam = getTeamName(target),
			targetCloaked = isCloaked(target),
			targetScrambled = isScrambled(target),
			actorModMode = isModMode(actor),
		})

		return {
			Success = false,
			Message = "Protected personnel cannot be targeted.",
		}
	end

	return nil
end

local function rejectHiddenTarget(actor, target)
	if isModMode(actor) then
		return nil
	end

	if isCloaked(target) then
		notify(actor, "Classified Utility", "Target signal unavailable.", "Normal")

		logUtilityAction(actor, target, "CloakedTargetBlocked", "Attempted to target cloaked personnel without ModMode.", {
			targetTeam = getTeamName(target),
			targetCloaked = true,
		})

		return {
			Success = false,
			Message = "Target signal unavailable.",
		}
	end

	if isScrambled(target) then
		notify(actor, "Classified Utility", "Target identity scrambled.", "Normal")

		logUtilityAction(actor, target, "ScrambledTargetBlocked", "Attempted to target scrambled personnel without ModMode.", {
			targetTeam = getTeamName(target),
			targetScrambled = true,
		})

		return {
			Success = false,
			Message = "Target identity scrambled.",
		}
	end

	return nil
end

local function validateTarget(actor, target)
	local protectedRejection = rejectProtectedTarget(actor, target)
	if protectedRejection then
		return protectedRejection
	end

	local hiddenRejection = rejectHiddenTarget(actor, target)
	if hiddenRejection then
		return hiddenRejection
	end

	return nil
end

local function setBlackbag(target, enabled)
	blindedPlayers[target.UserId] = enabled == true

	local playerGui = target:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end

	local existingGui = playerGui:FindFirstChild("USARF_BlackbagGui")

	if enabled then
		if existingGui then
			existingGui.Enabled = true
			return
		end

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "USARF_BlackbagGui"
		screenGui.IgnoreGuiInset = true
		screenGui.ResetOnSpawn = false
		screenGui.DisplayOrder = 999999
		screenGui.Parent = playerGui

		local frame = Instance.new("Frame")
		frame.Name = "BlackbagFrame"
		frame.Size = UDim2.fromScale(1, 1)
		frame.Position = UDim2.fromScale(0, 0)
		frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		frame.BorderSizePixel = 0
		frame.Parent = screenGui

		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5)
		label.Size = UDim2.fromOffset(520, 80)
		label.BackgroundTransparency = 1
		label.Text = "CLASSIFIED"
		label.TextColor3 = Color3.fromRGB(180, 180, 180)
		label.TextTransparency = 0.15
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = frame
	else
		if existingGui then
			existingGui.Enabled = false
		end
	end
end

local function setMark(target, enabled)
	markedPlayers[target.UserId] = enabled == true

	local character = target.Character
	if not character then
		return
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	local existing = head:FindFirstChild("USARF_HeadMark")

	if enabled then
		if existing then
			existing.Enabled = true
			return
		end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "USARF_HeadMark"
		billboard.Adornee = head
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.fromOffset(90, 28)
		billboard.StudsOffset = Vector3.new(0, 2.8, 0)
		billboard.Parent = head

		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromRGB(196, 40, 28)
		frame.BackgroundTransparency = 0.15
		frame.BorderSizePixel = 0
		frame.Parent = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = frame

		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = "MARKED"
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.TextScaled = true
		text.Font = Enum.Font.GothamBold
		text.Parent = frame
	else
		if existing then
			existing:Destroy()
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)

		if markedPlayers[player.UserId] and not isProtectedTarget(player) then
			setMark(player, true)
		end

		if blindedPlayers[player.UserId] and not isProtectedTarget(player) then
			setBlackbag(player, true)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	blindedPlayers[player.UserId] = nil
	markedPlayers[player.UserId] = nil
end)

remote.OnServerInvoke = function(player, action, data)
	data = data or {}

	if not hasUtilityAccess(player) then
		logUtilityAction(player, nil, "UnauthorizedAccess", "Unauthorized classified utility request blocked.", {
			requestedAction = tostring(action),
			actorTeam = getTeamName(player),
			actorModMode = isModMode(player),
		})

		return {
			Success = false,
			HasAccess = false,
			Message = "",
		}
	end

	if action == "GetAccess" then
		return {
			Success = true,
			HasAccess = true,
			ModMode = isModMode(player),
		}
	end

	if action == "GetPlayers" then
		local playerList = {}

		for _, target in ipairs(Players:GetPlayers()) do
			table.insert(playerList, getPublicPlayerInfo(target, player))
		end

		return {
			Success = true,
			Players = playerList,
			ModMode = isModMode(player),
		}
	end

	if action == "InspectPlayer" then
		local target = Players:GetPlayerByUserId(tonumber(data.UserId))
		if not target then
			notify(player, "Classified Utility", "No target selected.", "Normal")

			return {
				Success = false,
				Message = "Player not found.",
			}
		end

		local rejection = validateTarget(player, target)
		if rejection then
			return rejection
		end

		logUtilityAction(player, target, "Inspect", "Inspected target profile.", {
			targetTeam = getTeamName(target),
			targetCloaked = isCloaked(target),
			targetScrambled = isScrambled(target),
			actorModMode = isModMode(player),
		})

		notify(player, "Classified Utility", "Target profile opened.", "Normal")

		return {
			Success = true,
			Info = getPublicPlayerInfo(target, player),
		}
	end

	if action == "ToggleBlackbag" then
		local target = Players:GetPlayerByUserId(tonumber(data.UserId))
		if not target then
			notify(player, "Classified Utility", "No target selected.", "Normal")

			return {
				Success = false,
				Message = "Player not found.",
			}
		end

		local rejection = validateTarget(player, target)
		if rejection then
			return rejection
		end

		local newState = not blindedPlayers[target.UserId]
		setBlackbag(target, newState)

		logUtilityAction(player, target, newState and "BlackbagEnabled" or "BlackbagDisabled", newState and "Target blackbagged." or "Target blackbag removed.", {
			targetTeam = getTeamName(target),
			targetCloaked = isCloaked(target),
			targetScrambled = isScrambled(target),
			actorModMode = isModMode(player),
			enabled = newState,
		})

		notify(player, "Classified Utility", newState and "Target blackbagged." or "Target blackbag removed.", "Normal")

		return {
			Success = true,
			IsBlinded = newState,
		}
	end

	if action == "ToggleMark" then
		local target = Players:GetPlayerByUserId(tonumber(data.UserId))
		if not target then
			notify(player, "Classified Utility", "No target selected.", "Normal")

			return {
				Success = false,
				Message = "Player not found.",
			}
		end

		local rejection = validateTarget(player, target)
		if rejection then
			return rejection
		end

		local newState = not markedPlayers[target.UserId]
		setMark(target, newState)

		logUtilityAction(player, target, newState and "MarkEnabled" or "MarkDisabled", newState and "Target marked." or "Target mark removed.", {
			targetTeam = getTeamName(target),
			targetCloaked = isCloaked(target),
			targetScrambled = isScrambled(target),
			actorModMode = isModMode(player),
			enabled = newState,
		})

		notify(player, "Classified Utility", newState and "Target marked." or "Target mark removed.", "Normal")

		return {
			Success = true,
			IsMarked = newState,
		}
	end

	return {
		Success = false,
		Message = "Unknown action.",
	}
end

print("[ClassifiedUtilityService] Loaded.")