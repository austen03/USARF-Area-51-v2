local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local SpawnService = require(Services:WaitForChild("SpawnService"))

local AntiExploitService = nil
pcall(function()
	AntiExploitService = require(Services:WaitForChild("AntiExploitService"))
end)

local DeathStateService = {}

local started = false
local characterConnections = {}

local REMOTE_ROOT_NAME = "USARF"
local REMOTE_FOLDER_NAME = "Remotes"
local DEATH_FOLDER_NAME = "Death"

local DEATH_EVENT_NAME = "DeathStateEvent"
local REQUEST_RESPAWN_NAME = "RequestRespawn"
local REQUEST_REVIVE_WAIT_NAME = "RequestReviveWait"

local ATTR_DEAD = "USARF_Dead"
local ATTR_DEATH_READY = "USARF_DeathRespawnReady"
local ATTR_LAST_KILLER = "USARF_LastKiller"
local ATTR_LAST_WEAPON = "USARF_LastWeapon"
local ATTR_WAITING_FOR_REVIVE = "USARF_WaitingForRevive"
local ATTR_LAST_DEATH_TEAM = "USARF_LastDeathTeam"
local ATTR_CONTAINMENT_STATUS = "USARF_ContainmentStatus"

local DEFAULT_RESPAWN_DELAY = 7
local MEDICAL_RESPAWN_DELAY = 15
local REVIVE_HEALTH = 50

local MEDICAL_TEAM_NAMES = {
	["Medical Division"] = true,
}

local playerDeathData = {}

local DeathEvent
local RequestRespawn
local RequestReviveWait

local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end

	return folder
end

local function getOrCreateRemoteEvent(parent, name)
	local remote = parent:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = parent
	end

	return remote
end

local function getOrCreateRemoteFunction(parent, name)
	local remote = parent:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = parent
	end

	return remote
end

local function setupRemotes()
	local usarfFolder = getOrCreateFolder(ReplicatedStorage, REMOTE_ROOT_NAME)
	local remotesFolder = getOrCreateFolder(usarfFolder, REMOTE_FOLDER_NAME)
	local deathFolder = getOrCreateFolder(remotesFolder, DEATH_FOLDER_NAME)

	DeathEvent = getOrCreateRemoteEvent(deathFolder, DEATH_EVENT_NAME)
	RequestRespawn = getOrCreateRemoteFunction(deathFolder, REQUEST_RESPAWN_NAME)
	RequestReviveWait = getOrCreateRemoteEvent(deathFolder, REQUEST_REVIVE_WAIT_NAME)
end

local function giveTeleportGrace(player, seconds, reason)
	if AntiExploitService and typeof(AntiExploitService.GiveGrace) == "function" then
		AntiExploitService.GiveGrace(player, seconds or 5, reason or "DeathStateTeleport")
	else
		player:SetAttribute("USARF_TeleportGraceUntil", os.clock() + (seconds or 5))
		player:SetAttribute("USARF_TeleportGraceReason", reason or "DeathStateTeleport")
	end
end

local function isMedicalPlayer(player)
	if not player.Team then
		return false
	end

	return MEDICAL_TEAM_NAMES[player.Team.Name] == true
end

local function getMedicalOnlineCount()
	local count = 0

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if isMedicalPlayer(otherPlayer) then
			local character = otherPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if humanoid and humanoid.Health > 0 then
				count += 1
			end
		end
	end

	return count
end

local function getRespawnDelay()
	if getMedicalOnlineCount() > 0 then
		return MEDICAL_RESPAWN_DELAY
	end

	return DEFAULT_RESPAWN_DELAY
end

local function setDefaultAttributes(player)
	player:SetAttribute(ATTR_DEAD, false)
	player:SetAttribute(ATTR_DEATH_READY, false)
	player:SetAttribute(ATTR_WAITING_FOR_REVIVE, false)

	if player:GetAttribute(ATTR_LAST_KILLER) == nil then
		player:SetAttribute(ATTR_LAST_KILLER, "")
	end

	if player:GetAttribute(ATTR_LAST_WEAPON) == nil then
		player:SetAttribute(ATTR_LAST_WEAPON, "")
	end
end

local function disconnectPlayer(player)
	local connections = characterConnections[player]

	if connections then
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end

	characterConnections[player] = nil
end

local function getDeathMessage(player)
	local killer = player:GetAttribute(ATTR_LAST_KILLER)
	local weapon = player:GetAttribute(ATTR_LAST_WEAPON)

	if weapon == "Nuclear Missile" then
		return "You died by a nuclear missile."
	end

	if killer and killer ~= "" and weapon and weapon ~= "" then
		return "You were killed by " .. tostring(killer) .. " with " .. tostring(weapon) .. "."
	end

	if killer and killer ~= "" then
		return "You were killed by " .. tostring(killer) .. "."
	end

	return "You were killed."
end

local function getRootCFrame(player)
	local character = player.Character

	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")

	if not root then
		return nil
	end

	return root.CFrame
end

local function markRespawnReady(player)
	local data = playerDeathData[player]

	if not data then
		return
	end

	player:SetAttribute(ATTR_DEATH_READY, true)

	if DeathEvent then
		DeathEvent:FireClient(player, {
			action = "RespawnReady",
		})
	end
end

local function handleDeath(player)
	local delaySeconds = getRespawnDelay()
	local deathMessage = getDeathMessage(player)
	local medicalOnline = getMedicalOnlineCount()
	local deathTeam = player.Team
	local deathCFrame = getRootCFrame(player)
	local containmentStatus = player:GetAttribute(ATTR_CONTAINMENT_STATUS)

	playerDeathData[player] = {
		deadAt = os.clock(),
		delaySeconds = delaySeconds,
		respawnReadyAt = os.clock() + delaySeconds,
		team = deathTeam,
		teamName = deathTeam and deathTeam.Name or nil,
		teamKey = player:GetAttribute("USARF_TeamKey"),
		teamNameAttribute = player:GetAttribute("USARF_TeamName"),
		deathCFrame = deathCFrame,
		containmentStatus = containmentStatus,
	}

	if deathTeam then
		player:SetAttribute(ATTR_LAST_DEATH_TEAM, deathTeam.Name)
	else
		player:SetAttribute(ATTR_LAST_DEATH_TEAM, "")
	end

	player:SetAttribute(ATTR_DEAD, true)
	player:SetAttribute(ATTR_DEATH_READY, false)
	player:SetAttribute(ATTR_WAITING_FOR_REVIVE, false)

	if DeathEvent then
		DeathEvent:FireClient(player, {
			action = "ShowDeathScreen",
			message = deathMessage,
			delaySeconds = delaySeconds,
			medicalOnline = medicalOnline,
			killer = player:GetAttribute(ATTR_LAST_KILLER) or "",
			weapon = player:GetAttribute(ATTR_LAST_WEAPON) or "",
		})
	end

	task.delay(delaySeconds, function()
		if player.Parent == Players and player:GetAttribute(ATTR_DEAD) == true then
			markRespawnReady(player)
		end
	end)
end

local function setupCharacter(player, character)
	disconnectPlayer(player)

	local connections = {}
	characterConnections[player] = connections

	player:SetAttribute(ATTR_DEAD, false)
	player:SetAttribute(ATTR_DEATH_READY, false)
	player:SetAttribute(ATTR_WAITING_FOR_REVIVE, false)

	local humanoid = character:WaitForChild("Humanoid", 10)

	if not humanoid then
		return
	end

	table.insert(connections, humanoid.Died:Connect(function()
		handleDeath(player)
	end))
end

local function restoreDeathTeam(player)
	local data = playerDeathData[player]

	if data and data.team and data.team.Parent then
		player.Team = data.team
		player.Neutral = false
	end
end

local function waitForCharacterReady(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)

	if not root or not humanoid then
		return nil, nil, nil
	end

	return character, root, humanoid
end

local function clearDeathAttributes(player)
	player:SetAttribute(ATTR_DEAD, false)
	player:SetAttribute(ATTR_DEATH_READY, false)
	player:SetAttribute(ATTR_WAITING_FOR_REVIVE, false)
	player:SetAttribute(ATTR_LAST_KILLER, "")
	player:SetAttribute(ATTR_LAST_WEAPON, "")
end

local function hideDeathScreen(player)
	if DeathEvent then
		DeathEvent:FireClient(player, {
			action = "HideDeathScreen",
		})
	end
end

local function restoreContainmentStatus(player, deathData)
	if not deathData then
		return
	end

	local status = deathData.containmentStatus

	if status == nil or status == "" or status == "None" then
		return
	end

	player:SetAttribute(ATTR_CONTAINMENT_STATUS, status)

	task.delay(0.25, function()
		if player.Parent == Players then
			player:SetAttribute(ATTR_CONTAINMENT_STATUS, status)
		end
	end)

	task.delay(1, function()
		if player.Parent == Players then
			player:SetAttribute(ATTR_CONTAINMENT_STATUS, status)
		end
	end)
end

local function respawnPlayer(player)
	restoreDeathTeam(player)

	local deathData = playerDeathData[player]
	local teamKey = deathData and deathData.teamKey or player:GetAttribute("USARF_TeamKey")
	local teamNameAttribute = deathData and deathData.teamNameAttribute or player:GetAttribute("USARF_TeamName")

	clearDeathAttributes(player)

	if teamKey then
		player:SetAttribute("USARF_TeamKey", teamKey)
	end

	if teamNameAttribute then
		player:SetAttribute("USARF_TeamName", teamNameAttribute)
	end

	giveTeleportGrace(player, 6, "DeathRespawn")
	player:LoadCharacter()

	local character, root = waitForCharacterReady(player)

	if character and root then
		if teamKey then
			player:SetAttribute("USARF_TeamKey", teamKey)
		end

		if teamNameAttribute then
			player:SetAttribute("USARF_TeamName", teamNameAttribute)
		end

		local moved, message = SpawnService.RespawnPlayerAtCurrentTeam(player)

		if not moved then
			warn("[DeathStateService] RespawnPlayerAtCurrentTeam failed:", message)

			local fallbackMoved, fallbackMessage = SpawnService.SendPlayerToDefaultSpawn(player)

			if not fallbackMoved then
				warn("[DeathStateService] Default respawn failed:", fallbackMessage)
			end
		end
	end

	playerDeathData[player] = nil
	hideDeathScreen(player)

	return {
		success = true,
	}
end

function DeathStateService.RevivePlayer(player, revivedBy)
	if not player then
		return false, "Missing player"
	end

	if player:GetAttribute(ATTR_DEAD) ~= true then
		return false, "Target is not dead"
	end

	local deathData = playerDeathData[player]

	if not deathData then
		return false, "Death data missing"
	end

	restoreDeathTeam(player)

	local teamKey = deathData.teamKey or player:GetAttribute("USARF_TeamKey")
	local teamNameAttribute = deathData.teamNameAttribute or player:GetAttribute("USARF_TeamName")
	local deathCFrame = deathData.deathCFrame
	local containmentStatus = deathData.containmentStatus or player:GetAttribute(ATTR_CONTAINMENT_STATUS)

	clearDeathAttributes(player)

	if teamKey then
		player:SetAttribute("USARF_TeamKey", teamKey)
	end

	if teamNameAttribute then
		player:SetAttribute("USARF_TeamName", teamNameAttribute)
	end

	if containmentStatus and containmentStatus ~= "" and containmentStatus ~= "None" then
		player:SetAttribute(ATTR_CONTAINMENT_STATUS, containmentStatus)
	end

	giveTeleportGrace(player, 8, "MedicalRevive")
	player:LoadCharacter()

	local character, root, humanoid = waitForCharacterReady(player)

	if not character or not root or not humanoid then
		return false, "Character failed to load"
	end

	if teamKey then
		player:SetAttribute("USARF_TeamKey", teamKey)
	end

	if teamNameAttribute then
		player:SetAttribute("USARF_TeamName", teamNameAttribute)
	end

	if deathCFrame then
		root.CFrame = deathCFrame * CFrame.new(0, 3, 0)
	else
		SpawnService.RespawnPlayerAtCurrentTeam(player)
	end

	humanoid.Health = math.clamp(REVIVE_HEALTH, 1, humanoid.MaxHealth)

	player:SetAttribute("USARF_Bleeding", false)
	player:SetAttribute("USARF_BleedingSeverity", "None")
	player:SetAttribute("USARF_InjuryType", "None")
	player:SetAttribute("USARF_Injury", "Injured")

	restoreContainmentStatus(player, {
		containmentStatus = containmentStatus,
	})

	playerDeathData[player] = nil
	hideDeathScreen(player)

	if _G.USARFNotifyPlayer then
		_G.USARFNotifyPlayer(player, "Medical", "You were revived by " .. (revivedBy and revivedBy.Name or "Medical") .. ".", 5)

		if revivedBy then
			_G.USARFNotifyPlayer(revivedBy, "Medical", "Revived " .. player.Name .. ".", 5)
		end
	end

	return true, "Revived successfully"
end

local function setupPlayer(player)
	setDefaultAttributes(player)

	if player.Character then
		setupCharacter(player, player.Character)
	else
		task.defer(function()
			if player.Parent == Players and not player.Character then
				player:LoadCharacter()
			end
		end)
	end

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
end

function DeathStateService.Start()
	if started then
		return
	end

	started = true
	Players.CharacterAutoLoads = false

	setupRemotes()

	RequestRespawn.OnServerInvoke = function(player)
		if player:GetAttribute(ATTR_DEAD) ~= true then
			return {
				success = false,
				message = "You are not dead.",
			}
		end

		if player:GetAttribute(ATTR_DEATH_READY) ~= true then
			return {
				success = false,
				message = "Respawn is not ready yet.",
			}
		end

		return respawnPlayer(player)
	end

	RequestReviveWait.OnServerEvent:Connect(function(player)
		if player:GetAttribute(ATTR_DEAD) ~= true then
			return
		end

		player:SetAttribute(ATTR_WAITING_FOR_REVIVE, true)

		if DeathEvent then
			DeathEvent:FireClient(player, {
				action = "WaitingForRevive",
			})
		end
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		disconnectPlayer(player)
		playerDeathData[player] = nil
	end)

	print("[DeathStateService] Started")
end

return DeathStateService