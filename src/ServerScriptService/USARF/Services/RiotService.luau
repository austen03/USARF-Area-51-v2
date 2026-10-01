local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")

local RiotService = {}

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")
local Shared = USARF:WaitForChild("Shared")
local Remotes = USARF:WaitForChild("Remotes")

local RiotConfig = require(Config:WaitForChild("RiotConfig"))

local FacilityState = Shared:WaitForChild("FacilityState")

local function getOrCreateValue(className, name, defaultValue)
	local value = FacilityState:FindFirstChild(name)

	if not value then
		value = Instance.new(className)
		value.Name = name
		value.Parent = FacilityState
	end

	if defaultValue ~= nil then
		value.Value = defaultValue
	end

	return value
end

local function getOrCreateRemoteFunction(name)
	local remote = Remotes:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = Remotes
	end

	return remote
end

local RiotActiveValue = getOrCreateValue("BoolValue", "RiotActive", false)
local RiotStageValue = getOrCreateValue("IntValue", "RiotStage", 0)
local RiotEndsAtValue = getOrCreateValue("IntValue", "RiotEndsAt", 0)

local CheckRiotPurchaseRemote = getOrCreateRemoteFunction("CheckRiotPurchase")
local PurchaseRiotWithGoldRemote = getOrCreateRemoteFunction("PurchaseRiotWithGold")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local NotificationService = require(Services:WaitForChild("NotificationService"))
local CurrencyService = require(Services:WaitForChild("CurrencyService"))

local FacilityAnnouncementService = nil
pcall(function()
	FacilityAnnouncementService = require(Services:WaitForChild("FacilityAnnouncementService"))
end)

local FacilityStatusService = nil
pcall(function()
	FacilityStatusService = require(Services:WaitForChild("FacilityStatusService"))
end)

local DepartmentAlertService = nil
pcall(function()
	DepartmentAlertService = require(Services:WaitForChild("DepartmentAlertService"))
end)

local RIOT_GOLD_COST = RiotConfig.PurchaseGoldCost or 2500
local RIOT_WEAPON_ATTRIBUTE = "USARF_RiotWeapon"

local state = {
	Active = false,
	Stage = 0,
	StartedAt = 0,
	EndsAt = 0,
	StartedBy = "System",
	Reason = nil,
	LastPurchaseStartAt = 0,
}

local armedPlayers = {}
local characterConnections = {}
local started = false
local endToken = 0

-- AccessService reads "door*" attributes off the player's Team as door tags, so flipping this
-- one on the Test Subject team(s) lets DoorSettings AllowedList/DeniedList react to the riot.
local function setRiotDoorTag(active)
	local tagName = RiotConfig.RiotDoorTag or "doorRiot"

	for teamName in pairs(RiotConfig.TestSubjectTeams or {}) do
		local team = Teams:FindFirstChild(teamName)

		if team and team:IsA("Team") then
			team:SetAttribute(tagName, active)
		end
	end
end

local function replicateRiotState()
	RiotActiveValue.Value = state.Active == true
	RiotStageValue.Value = tonumber(state.Stage) or 0
	RiotEndsAtValue.Value = tonumber(state.EndsAt) or 0

	setRiotDoorTag(state.Active == true and state.Stage >= (RiotConfig.MinimumStageForClearance or 3))
end

local function getStageInfo(stage)
	return RiotConfig.Stages[stage] or RiotConfig.Stages[0]
end

local function isTestSubject(player)
	if not player or not player.Team then
		return false
	end

	return RiotConfig.TestSubjectTeams[player.Team.Name] == true
end

local function getToolsFolder()
	return ServerStorage:FindFirstChild(RiotConfig.ToolsFolderName or "Tools")
end

local function hasTool(player, toolName)
	if player.Backpack and player.Backpack:FindFirstChild(toolName) then
		return true
	end

	if player.Character and player.Character:FindFirstChild(toolName) then
		return true
	end

	return false
end

local function giveTool(player, toolName)
	local toolsFolder = getToolsFolder()

	if not toolsFolder then
		warn("[RiotService] Missing ServerStorage." .. tostring(RiotConfig.ToolsFolderName or "Tools"))
		return
	end

	local template = toolsFolder:FindFirstChild(toolName)

	if not template then
		warn("[RiotService] Missing riot weapon:", toolName)
		return
	end

	if not template:IsA("Tool") then
		warn("[RiotService] Riot weapon is not a Tool:", toolName)
		return
	end

	if hasTool(player, toolName) then
		return
	end

	local clone = template:Clone()
	-- The riot weapons share names with Black Market tools; this tag keeps LoadoutService's
	-- Black Market cleanup from deleting them and lets the riot remove only its own copies.
	clone:SetAttribute(RIOT_WEAPON_ATTRIBUTE, true)
	clone.Parent = player.Backpack
end

local function giveRiotWeapons(player)
	if not player or not player.Parent then
		return
	end

	if not isTestSubject(player) then
		return
	end

	for _, toolName in ipairs(RiotConfig.RiotWeapons or {}) do
		giveTool(player, toolName)
	end

	armedPlayers[player] = true
	player:SetAttribute("USARF_RiotArmed", true)
end

local function removeRiotWeapons(player)
	if not player then
		return
	end

	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		for _, child in ipairs(container and container:GetChildren() or {}) do
			if child:IsA("Tool") and child:GetAttribute(RIOT_WEAPON_ATTRIBUTE) == true then
				child:Destroy()
			end
		end
	end

	armedPlayers[player] = nil
	player:SetAttribute("USARF_RiotArmed", false)
end

local function notifyAll(title, message, notificationType)
	if RiotConfig.NotifyPlayers ~= true then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		NotificationService.Notify(player, {
			Title = title,
			Message = message,
			Type = notificationType or "Info",
			Duration = 8,
		})
	end
end

local function alertDepartments(message)
	if RiotConfig.SendDepartmentAlerts ~= true then
		return
	end

	if not DepartmentAlertService then
		return
	end

	if typeof(DepartmentAlertService.SecurityIncident) == "function" then
		DepartmentAlertService.SecurityIncident(message)
	end

	if typeof(DepartmentAlertService.MedicalEmergency) == "function" then
		DepartmentAlertService.MedicalEmergency(
			"Riot conditions active. Prepare for possible mass casualty response."
		)
	end

	if typeof(DepartmentAlertService.IntelligenceAlert) == "function" then
		DepartmentAlertService.IntelligenceAlert(
			"Riot conditions active. Monitor Test Subject activity."
		)
	end
end

local function setLastEvent(message)
	if FacilityStatusService and typeof(FacilityStatusService.SetLastEvent) == "function" then
		FacilityStatusService.SetLastEvent(message)
	end
end

local function playRiotAnnouncement()
	if RiotConfig.PlayAnnouncement ~= true then
		return
	end

	if not FacilityAnnouncementService then
		return
	end

	if typeof(FacilityAnnouncementService.PlayEvent) == "function" then
		FacilityAnnouncementService.PlayEvent("Code1")
	end
end

local function armAllTestSubjects()
	for _, player in ipairs(Players:GetPlayers()) do
		if isTestSubject(player) then
			giveRiotWeapons(player)
		end
	end
end

local function clearFutureRiotAccess()
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("USARF_RiotClearance", false)
		player:SetAttribute("USARF_RiotClearanceLevel", nil)
	end
end

local function grantRiotClearance()
	for _, player in ipairs(Players:GetPlayers()) do
		if isTestSubject(player) then
			player:SetAttribute("USARF_RiotClearance", true)
			player:SetAttribute("USARF_RiotClearanceLevel", RiotConfig.RiotClearanceLevel or 3)
		else
			player:SetAttribute("USARF_RiotClearance", false)
			player:SetAttribute("USARF_RiotClearanceLevel", nil)
		end
	end
end

local function setupCharacter(player, character)
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)

	if humanoid then
		characterConnections[player] = humanoid.Died:Connect(function()
			if not state.Active then
				removeRiotWeapons(player)
			end
		end)
	end

	task.delay(1, function()
		if not player.Parent then
			return
		end

		if state.Active and isTestSubject(player) and state.Stage >= (RiotConfig.MinimumStageForWeapons or 3) then
			giveRiotWeapons(player)
		end
	end)
end

local function setupPlayer(player)
	player:SetAttribute("USARF_RiotArmed", false)
	player:SetAttribute("USARF_RiotClearance", false)
	player:SetAttribute("USARF_RiotClearanceLevel", nil)

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		if state.Active and isTestSubject(player) then
			if state.Stage >= (RiotConfig.MinimumStageForWeapons or 3) then
				task.delay(0.5, function()
					if player.Parent and state.Active and isTestSubject(player) then
						giveRiotWeapons(player)
					end
				end)
			end

			if state.Stage >= (RiotConfig.MinimumStageForClearance or 3) then
				player:SetAttribute("USARF_RiotClearance", true)
				player:SetAttribute("USARF_RiotClearanceLevel", RiotConfig.RiotClearanceLevel or 3)
			end
		else
			player:SetAttribute("USARF_RiotClearance", false)
			player:SetAttribute("USARF_RiotClearanceLevel", nil)

			removeRiotWeapons(player)
		end
	end)

	if player.Character then
		setupCharacter(player, player.Character)
	end
end

function RiotService.IsActive()
	return state.Active
end

function RiotService.GetState()
	return {
		Active = state.Active,
		Stage = state.Stage,
		StartedAt = state.StartedAt,
		EndsAt = state.EndsAt,
		StartedBy = state.StartedBy,
		Reason = state.Reason,
		LastPurchaseStartAt = state.LastPurchaseStartAt,
	}
end

function RiotService.GetStage()
	return state.Stage
end

function RiotService.GetCooldownEndsAt()
	if not state.LastPurchaseStartAt or state.LastPurchaseStartAt <= 0 then
		return 0
	end

	return state.LastPurchaseStartAt + (RiotConfig.PurchaseCooldownSeconds or 900)
end

function RiotService.IsPurchaseOnCooldown()
	local cooldownEndsAt = RiotService.GetCooldownEndsAt()

	if cooldownEndsAt <= 0 then
		return false, 0
	end

	local now = os.time()

	if now < cooldownEndsAt then
		return true, cooldownEndsAt
	end

	return false, 0
end

function RiotService.CanPurchaseRiot()
	if RiotConfig.Enabled ~= true then
		return false, "Riot system is disabled."
	end

	if state.Active then
		return false, RiotConfig.ActivePurchaseMessage or "A riot is already active."
	end

	local onCooldown, cooldownEndsAt = RiotService.IsPurchaseOnCooldown()

	if onCooldown then
		local timeText = os.date("%I:%M %p", cooldownEndsAt)

		local cooldownMessage = string.format(
			RiotConfig.CooldownMessage or "Riot is on cooldown until %s.",
			timeText
		)

		return false, cooldownMessage, cooldownEndsAt
	end

	return true, "Riot available."
end

function RiotService.StartRiot(durationSeconds, actor, reason, source)
	if RiotConfig.Enabled ~= true then
		return false, "Riot system disabled"
	end

	if state.Active and RiotConfig.AllowStacking ~= true then
		return false, "Riot already active"
	end

	durationSeconds = math.max(
		30,
		tonumber(durationSeconds) or RiotConfig.DefaultManualDurationSeconds or 600
	)

	local now = os.time()
	local stage = 3
	local stageInfo = getStageInfo(stage)

	state.Active = true
	state.Stage = stage
	state.StartedAt = now
	state.EndsAt = now + durationSeconds
	state.StartedBy = actor and actor.Name or "System"
	state.Reason = reason or "Riot initiated"

	if source == "DeveloperProduct" or source == "GoldPurchase" then
		state.LastPurchaseStartAt = now
	end

	replicateRiotState()

	endToken += 1
	local token = endToken

	grantRiotClearance()
	armAllTestSubjects()

	notifyAll(
		stageInfo.Name,
		RiotConfig.StartMessage or "A Test Subject riot has begun.",
		stageInfo.NotificationType or "Error"
	)

	alertDepartments(RiotConfig.StartMessage or "A Test Subject riot has begun.")
	playRiotAnnouncement()
	setLastEvent("Riot started: " .. tostring(state.Reason))

	task.delay(durationSeconds, function()
		if token == endToken and state.Active then
			RiotService.EndRiot(nil, "Riot timer expired")
		end
	end)

	print(
		"[RiotService] Riot started",
		"Duration:",
		durationSeconds,
		"By:",
		state.StartedBy,
		"Reason:",
		state.Reason
	)

	return true, RiotService.GetState()
end

function RiotService.StartPurchasedRiot(player)
	local canPurchase, message = RiotService.CanPurchaseRiot()

	if not canPurchase then
		if player then
			NotificationService.Notify(player, {
				Title = "Riot Unavailable",
				Message = message,
				Type = "Error",
				Duration = 6,
			})
		end

		return false, message
	end

	return RiotService.StartRiot(
		RiotConfig.PurchaseDurationSeconds or 600,
		player,
		"10 minute riot purchased",
		"DeveloperProduct"
	)
end

function RiotService.EndRiot(actor, reason)
	if not state.Active then
		return false, "No active riot"
	end

	state.Active = false
	state.Stage = 0
	state.EndsAt = os.time()
	state.Reason = reason or "Riot ended"
	state.StartedBy = actor and actor.Name or state.StartedBy

	replicateRiotState()

	endToken += 1

	clearFutureRiotAccess()

	notifyAll(
		"Riot Ended",
		RiotConfig.EndMessage or "The riot has ended.",
		"Success"
	)

	setLastEvent("Riot ended: " .. tostring(state.Reason))

	print(
		"[RiotService] Riot ended",
		"By:",
		actor and actor.Name or "System",
		"Reason:",
		state.Reason
	)

	return true, RiotService.GetState()
end

function RiotService.IsPlayerRiotAuthorized(player)
	if not state.Active then
		return false
	end

	if state.Stage < (RiotConfig.MinimumStageForClearance or 3) then
		return false
	end

	if not isTestSubject(player) then
		return false
	end

	return true
end

function RiotService.GetRiotClearanceForPlayer(player)
	if RiotService.IsPlayerRiotAuthorized(player) then
		return RiotConfig.RiotClearanceLevel or 3
	end

	return nil
end

CheckRiotPurchaseRemote.OnServerInvoke = function(player)
	local canPurchase, message, cooldownEndsAt = RiotService.CanPurchaseRiot()

	return {
		CanPurchase = canPurchase == true,
		Message = message,
		CooldownEndsAt = cooldownEndsAt or 0,
		Cost = RIOT_GOLD_COST,
	}
end

PurchaseRiotWithGoldRemote.OnServerInvoke = function(player)
	local canPurchase, message, cooldownEndsAt = RiotService.CanPurchaseRiot()

	if not canPurchase then
		return {
			Success = false,
			Message = message or "Riot purchase unavailable.",
			CooldownEndsAt = cooldownEndsAt or 0,
		}
	end

	local balance = CurrencyService.GetBalance(player)
	local gold = tonumber(balance and balance.Gold) or 0

	if gold < RIOT_GOLD_COST then
		return {
			Success = false,
			Message = "You need " .. tostring(RIOT_GOLD_COST) .. " Gold to start a riot.",
			Gold = gold,
			Cost = RIOT_GOLD_COST,
		}
	end

	local removed, removeResult = CurrencyService.Remove(
		player,
		"Gold",
		RIOT_GOLD_COST,
		"RIOT_PURCHASE",
		{
			ItemId = "test_subject_riot",
			ItemName = "10 Minute Test Subject Riot",
			Source = "GoldPurchase",
			Cost = RIOT_GOLD_COST,
		}
	)

	if not removed then
		return {
			Success = false,
			Message = tostring(removeResult or "Could not remove Gold."),
		}
	end

	local startedRiot, riotResult = RiotService.StartRiot(
		RiotConfig.PurchaseDurationSeconds or 600,
		player,
		"10 minute riot purchased with Gold",
		"GoldPurchase"
	)

	if not startedRiot then
		CurrencyService.Add(
			player,
			"Gold",
			RIOT_GOLD_COST,
			"RIOT_REFUND",
			{
				ItemId = "test_subject_riot",
				Reason = tostring(riotResult or "Riot failed to start"),
			}
		)

		return {
			Success = false,
			Message = tostring(riotResult or "Riot failed to start. Gold refunded."),
		}
	end

	NotificationService.Notify(player, {
		Title = "Riot Purchased",
		Message = "You purchased a 10 minute Test Subject riot for " .. tostring(RIOT_GOLD_COST) .. " Gold.",
		Type = "Emergency",
		Duration = 6,
	})

	return {
		Success = true,
		Message = "Riot purchased successfully.",
		State = riotResult,
		Cost = RIOT_GOLD_COST,
	}
end

function RiotService.Start()
	if started then
		return
	end

	started = true

	replicateRiotState()

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		if characterConnections[player] then
			characterConnections[player]:Disconnect()
			characterConnections[player] = nil
		end

		armedPlayers[player] = nil
	end)

	print("[RiotService] Started")
end

return RiotService