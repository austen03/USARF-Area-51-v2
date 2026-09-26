local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local MedicalStateService = require(Services:WaitForChild("MedicalStateService"))
local DeathStateService = require(Services:WaitForChild("DeathStateService"))

local MedicalTreatmentService = {}

local started = false

local REMOTE_ROOT_NAME = "USARF"
local REMOTE_FOLDER_NAME = "Remotes"
local MEDICAL_FOLDER_NAME = "Medical"

local REQUEST_TARGET_NAME = "RequestMedicalTarget"
local APPLY_TREATMENT_NAME = "ApplyMedicalTreatment"

local MAX_TARGET_DISTANCE = 10

local TOOL_HEAL_AMOUNTS = {
	Medkit = 20,
	["Advanced Medkit"] = 35,
}

local TREATMENTS = {
	Bandage = {
		StopBleeding = true,
		RequiresBleeding = true,
		RequiresNotBleeding = false,
		Cooldown = 2.5,
	},

	Medkit = {
		StopBleeding = false,
		RequiresBleeding = false,
		RequiresNotBleeding = true,
		Cooldown = 4,
	},

	Revival = {
		StopBleeding = false,
		RequiresBleeding = false,
		RequiresNotBleeding = false,
		Cooldown = 6,
		RequiresDeadTarget = true,
	},
}

local playerCooldowns = {}

local RequestMedicalTarget
local ApplyMedicalTreatment

local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end

	return folder
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
	local medicalFolder = getOrCreateFolder(remotesFolder, MEDICAL_FOLDER_NAME)

	RequestMedicalTarget = getOrCreateRemoteFunction(medicalFolder, REQUEST_TARGET_NAME)
	ApplyMedicalTreatment = getOrCreateRemoteFunction(medicalFolder, APPLY_TREATMENT_NAME)
end

local function getRoot(player)
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getDistance(playerA, playerB)
	local rootA = getRoot(playerA)
	local rootB = getRoot(playerB)

	if not rootA or not rootB then
		return math.huge
	end

	return (rootA.Position - rootB.Position).Magnitude
end

local function getEquippedMedicalTool(player)
	local character = player.Character

	if not character then
		return nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and TOOL_HEAL_AMOUNTS[child.Name] then
			return child
		end
	end

	return nil
end

local function getHealAmountForPlayer(player)
	local tool = getEquippedMedicalTool(player)

	if not tool then
		return 20, "Medkit"
	end

	return TOOL_HEAL_AMOUNTS[tool.Name] or 20, tool.Name
end

local function canBeMedicalTarget(player)
	if not player.Character then
		return false
	end

	local root = getRoot(player)

	if not root then
		return false
	end

	local humanoid = getHumanoid(player)

	if player:GetAttribute("USARF_Dead") == true then
		return true
	end

	return humanoid and humanoid.Health > 0
end

local function getClosestTarget(player)
	local root = getRoot(player)

	if not root then
		return player, 0, true
	end

	local closestPlayer = nil
	local closestDistance = MAX_TARGET_DISTANCE

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and canBeMedicalTarget(otherPlayer) then
			local otherRoot = getRoot(otherPlayer)

			if otherRoot then
				local distance = (root.Position - otherRoot.Position).Magnitude

				if distance <= closestDistance then
					closestDistance = distance
					closestPlayer = otherPlayer
				end
			end
		end
	end

	if closestPlayer then
		return closestPlayer, closestDistance, false
	end

	return player, 0, true
end

local function buildTargetPayload(targetPlayer, distance, isSelfTarget)
	if not targetPlayer then
		return {
			hasTarget = false,
			isSelfTarget = false,
			targetName = "No target",
			status = "No target available.",
			health = 0,
			maxHealth = 0,
			bleeding = false,
			bleedingSeverity = "None",
			injuryType = "None",
			dead = false,
		}
	end

	local dead = targetPlayer:GetAttribute("USARF_Dead") == true
	local humanoid = getHumanoid(targetPlayer)

	if not dead and (not humanoid or humanoid.Health <= 0) then
		return {
			hasTarget = false,
			isSelfTarget = false,
			targetName = "No target",
			status = "Target unavailable.",
			health = 0,
			maxHealth = 0,
			bleeding = false,
			bleedingSeverity = "None",
			injuryType = "None",
			dead = false,
		}
	end

	local health = 0
	local maxHealth = 100

	if humanoid then
		health = math.floor(math.max(0, humanoid.Health) + 0.5)
		maxHealth = math.floor(humanoid.MaxHealth + 0.5)
	end

	local bleeding = targetPlayer:GetAttribute("USARF_Bleeding") == true
	local severity = targetPlayer:GetAttribute("USARF_BleedingSeverity") or "None"
	local injuryType = targetPlayer:GetAttribute("USARF_InjuryType") or "None"

	local status = "Stable"

	if dead then
		status = "Deceased"
	elseif bleeding then
		status = "Bleeding: " .. tostring(severity)
	elseif injuryType ~= "None" then
		status = tostring(injuryType)
	elseif health < maxHealth then
		status = "Injured"
	end

	return {
		hasTarget = true,
		isSelfTarget = isSelfTarget == true,
		targetUserId = targetPlayer.UserId,
		targetName = isSelfTarget and "Yourself" or targetPlayer.Name,
		displayName = isSelfTarget and "Yourself" or targetPlayer.DisplayName,
		distance = math.floor((distance or 0) + 0.5),
		status = status,
		health = health,
		maxHealth = maxHealth,
		bleeding = bleeding,
		bleedingSeverity = severity,
		injuryType = injuryType,
		dead = dead,
	}
end

local function getTargetByUserId(userId)
	userId = tonumber(userId)

	if not userId then
		return nil
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == userId then
			return player
		end
	end

	return nil
end

local function getCooldownRemaining(player, treatmentName)
	local key = tostring(player.UserId) .. ":" .. tostring(treatmentName)
	local untilTime = playerCooldowns[key] or 0

	return math.max(0, untilTime - os.clock())
end

local function isOnCooldown(player, treatmentName)
	return getCooldownRemaining(player, treatmentName) > 0
end

local function setCooldown(player, treatmentName, seconds)
	local key = tostring(player.UserId) .. ":" .. tostring(treatmentName)
	playerCooldowns[key] = os.clock() + seconds
end

local function notify(player, title, message)
	if _G.USARFNotifyPlayer then
		_G.USARFNotifyPlayer(player, title, message, 4)
	end
end

local function applyTreatment(player, targetUserId, treatmentName)
	local config = TREATMENTS[treatmentName]

	if not config then
		return {
			success = false,
			message = "Invalid treatment.",
			holdMessage = true,
		}
	end

	if player:GetAttribute("USARF_Dead") == true then
		return {
			success = false,
			message = "You cannot treat while dead.",
			holdMessage = true,
		}
	end

	local equippedTool = getEquippedMedicalTool(player)

	if not equippedTool then
		return {
			success = false,
			message = "Equip a medkit first.",
			holdMessage = true,
		}
	end

	if isOnCooldown(player, treatmentName) then
		return {
			success = false,
			message = "Cooldown: " .. tostring(math.ceil(getCooldownRemaining(player, treatmentName))) .. "s remaining.",
			holdMessage = true,
		}
	end

	local targetPlayer = getTargetByUserId(targetUserId)

	if not targetPlayer then
		return {
			success = false,
			message = "Target not found.",
			holdMessage = true,
		}
	end

	local targetDead = targetPlayer:GetAttribute("USARF_Dead") == true

	local distance = getDistance(player, targetPlayer)
	local isSelfTarget = player == targetPlayer

	if not isSelfTarget and distance > MAX_TARGET_DISTANCE then
		return {
			success = false,
			message = "Target is too far away.",
			holdMessage = true,
		}
	end

	if treatmentName == "Revival" then
		if isSelfTarget then
			return {
				success = false,
				message = "You cannot revive yourself.",
				holdMessage = true,
			}
		end

		if not targetDead then
			return {
				success = false,
				message = "Target is not deceased.",
				holdMessage = true,
			}
		end

		local revived, reviveMessage = DeathStateService.RevivePlayer(targetPlayer, player)

		if not revived then
			return {
				success = false,
				message = reviveMessage or "Revival failed.",
				holdMessage = true,
			}
		end

		setCooldown(player, treatmentName, config.Cooldown or 6)

		return {
			success = true,
			message = "Revival successful.",
			target = buildTargetPayload(targetPlayer, distance, false),
		}
	end

	if targetDead then
		return {
			success = false,
			message = "Target is deceased. Use Revival.",
			holdMessage = true,
		}
	end

	local targetBleeding = targetPlayer:GetAttribute("USARF_Bleeding") == true

	if config.RequiresBleeding and not targetBleeding then
		return {
			success = false,
			message = isSelfTarget and "You are not bleeding." or "Target is not bleeding.",
			holdMessage = true,
		}
	end

	if config.RequiresNotBleeding and targetBleeding then
		return {
			success = false,
			message = isSelfTarget and "Bandage yourself before healing." or "Bandage target before healing.",
			holdMessage = true,
		}
	end

	local didSomething = false

	if config.StopBleeding then
		local stopped = MedicalStateService.StopBleeding(targetPlayer)

		if stopped then
			didSomething = true
		end
	end

	if treatmentName == "Medkit" then
		local healAmount, toolName = getHealAmountForPlayer(player)
		local healed = MedicalStateService.HealPlayer(targetPlayer, healAmount)

		if healed then
			didSomething = true
		end

		if not didSomething then
			return {
				success = false,
				message = "Treatment had no effect.",
				holdMessage = true,
			}
		end

		setCooldown(player, treatmentName, config.Cooldown or 3)

		if isSelfTarget then
			notify(player, "Medical", toolName .. " applied. +" .. tostring(healAmount) .. " HP.")
		else
			notify(player, "Medical", toolName .. " applied to " .. targetPlayer.Name .. ".")
			notify(targetPlayer, "Medical", player.Name .. " treated you.")
		end

		return {
			success = true,
			message = toolName .. " applied. +" .. tostring(healAmount) .. " HP.",
			target = buildTargetPayload(targetPlayer, distance, isSelfTarget),
		}
	end

	if not didSomething then
		return {
			success = false,
			message = "Treatment had no effect.",
			holdMessage = true,
		}
	end

	setCooldown(player, treatmentName, config.Cooldown or 3)

	if isSelfTarget then
		notify(player, "Medical", treatmentName .. " applied.")
	else
		notify(player, "Medical", treatmentName .. " applied to " .. targetPlayer.Name .. ".")
		notify(targetPlayer, "Medical", player.Name .. " treated you.")
	end

	return {
		success = true,
		message = treatmentName .. " applied.",
		target = buildTargetPayload(targetPlayer, distance, isSelfTarget),
	}
end

function MedicalTreatmentService.Start()
	if started then
		return
	end

	started = true

	setupRemotes()

	RequestMedicalTarget.OnServerInvoke = function(player)
		local targetPlayer, distance, isSelfTarget = getClosestTarget(player)
		return buildTargetPayload(targetPlayer, distance, isSelfTarget)
	end

	ApplyMedicalTreatment.OnServerInvoke = function(player, targetUserId, treatmentName)
		return applyTreatment(player, targetUserId, treatmentName)
	end

	Players.PlayerRemoving:Connect(function(player)
		for key in pairs(playerCooldowns) do
			if string.find(key, tostring(player.UserId) .. ":", 1, true) then
				playerCooldowns[key] = nil
			end
		end
	end)

	print("[MedicalTreatmentService] Started")
end

return MedicalTreatmentService