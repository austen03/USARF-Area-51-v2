local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local WeaponService = {}

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local Shared = USARF:WaitForChild("Shared")
local WeaponFramework = Shared:WaitForChild("WeaponFramework")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local WeaponAttachmentResolver = require(WeaponFramework:WaitForChild("WeaponAttachmentResolver"))
local GlassService = require(Services:WaitForChild("GlassService"))
local CombatRulesService = require(Services:WaitForChild("CombatRulesService"))

local WeaponFire = Remotes:WaitForChild("WeaponFire")
local WeaponReload = Remotes:WaitForChild("WeaponReload")
local WeaponHit = Remotes:WaitForChild("WeaponHit")
local WeaponGetAmmo = Remotes:WaitForChild("WeaponGetAmmo")
local WeaponAmmoSync = Remotes:WaitForChild("WeaponAmmoSync")
local WeaponImpact = Remotes:WaitForChild("WeaponImpact")
local WeaponSuppression = Remotes:WaitForChild("WeaponSuppression")

local playerWeaponState = {}

local WEAPON_ID_ATTRIBUTE = "USARF_WeaponId"

local ATTR_LAST_KILLER = "USARF_LastKiller"
local ATTR_LAST_WEAPON = "USARF_LastWeapon"

local SUPPRESSION_DISTANCE = 7
local SUPPRESSION_RANGE = 650
local SUPPRESSION_MIN_INTENSITY = 0.25

local function getEquippedTool(player)
	local character = player.Character
	if not character then
		return nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return child
		end
	end

	return nil
end

local function getConfig(tool)
	local configModule = tool and tool:FindFirstChild("Config")
	if not configModule or not configModule:IsA("ModuleScript") then
		return nil
	end

	local success, baseConfig = pcall(require, configModule)
	if not success then
		warn("[WeaponService] Failed to load config:", baseConfig)
		return nil
	end

	return WeaponAttachmentResolver.Resolve(baseConfig)
end

local function getWeaponName(tool, config)
	if config and config.Name and config.Name ~= "" then
		return tostring(config.Name)
	end

	if tool and tool.Name and tool.Name ~= "" then
		return tostring(tool.Name)
	end

	return "Unknown Weapon"
end

local function getWeaponKey(tool)
	local existingId = tool:GetAttribute(WEAPON_ID_ATTRIBUTE)

	if existingId then
		return existingId
	end

	local newId = HttpService:GenerateGUID(false)
	tool:SetAttribute(WEAPON_ID_ATTRIBUTE, newId)

	return newId
end

local function getState(player, tool, config)
	playerWeaponState[player] = playerWeaponState[player] or {}

	local weaponKey = getWeaponKey(tool)

	if not playerWeaponState[player][weaponKey] then
		playerWeaponState[player][weaponKey] = {
			Ammo = config.MagazineSize or 0,
			Reserve = config.ReserveAmmo or 0,
			LastFire = 0,
			Reloading = false,
		}
	end

	return playerWeaponState[player][weaponKey]
end

local function syncAmmo(player, state)
	WeaponAmmoSync:FireClient(player, state.Ammo, state.Reserve)
end

local function isWeaponTool(tool)
	return tool and tool:IsA("Tool") and tool:FindFirstChild("Config") ~= nil
end

local function getPlayerTools(player)
	local tools = {}
	local seen = {}

	local function scan(container)
		if not container then
			return
		end

		for _, child in ipairs(container:GetChildren()) do
			if isWeaponTool(child) and not seen[child] then
				seen[child] = true
				table.insert(tools, child)
			end
		end
	end

	scan(player:FindFirstChild("Backpack"))
	scan(player.Character)

	return tools
end

local function isValidShot(config, state)
	if state.Reloading then
		return false
	end

	if state.Ammo <= 0 then
		return false
	end

	local now = os.clock()
	local fireDelay = 60 / (config.FireRate or 600)

	if now - state.LastFire < fireDelay then
		return false
	end

	state.LastFire = now
	state.Ammo -= 1

	return true
end

local function makeRaycastParams(excludeList)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excludeList
	params.IgnoreWater = true
	return params
end

local function findGlassRoot(instance, material)
	local glassRoot = GlassService.FindGlassRoot(instance)

	if glassRoot then
		return glassRoot
	end

	if material == Enum.Material.Glass then
		return instance
	end

	return nil
end

local function fireImpact(result, hitInfo)
	if not result then
		return
	end

	WeaponImpact:FireAllClients({
		Position = result.Position,
		Normal = result.Normal,
		Material = tostring(result.Material),
		HitPart = result.Instance,
		IsHumanoid = hitInfo ~= nil,
		Headshot = hitInfo and hitInfo.Headshot or false,
	})
end

local function breakGlass(glassRoot)
	GlassService.BreakGlass(glassRoot)
end

local function handleSuppression(shooter, origin, direction, range)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end

	local unitDirection = direction.Unit
	local maxRange = range or SUPPRESSION_RANGE

	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= shooter then
			local character = targetPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")

			if humanoid and humanoid.Health > 0 and root then
				local rootOffset = root.Position - origin
				local projection = rootOffset:Dot(unitDirection)

				if projection > 0 and projection <= maxRange then
					local closestPoint = origin + unitDirection * projection
					local missDistance = (root.Position - closestPoint).Magnitude

					if missDistance <= SUPPRESSION_DISTANCE then
						local intensity = math.clamp(
							1 - (missDistance / SUPPRESSION_DISTANCE),
							SUPPRESSION_MIN_INTENSITY,
							1
						)

						WeaponSuppression:FireClient(targetPlayer, closestPoint, intensity)
					end
				end
			end
		end
	end
end

local function raycastShot(player, origin, direction, config)
	local character = player.Character
	if not character then
		return nil, nil
	end

	local range = config.Range or 650
	local params = makeRaycastParams({ character })

	local firstResult = Workspace:Raycast(origin, direction.Unit * range, params)
	if not firstResult then
		return nil, nil
	end

	local glassConfig = config.GlassPenetration or {}
	if glassConfig.Enabled ~= true then
		return firstResult, nil
	end

	local glassRoot = findGlassRoot(firstResult.Instance, firstResult.Material)
	if not glassRoot then
		return firstResult, nil
	end

	fireImpact(firstResult, nil)
	breakGlass(glassRoot)

	local exitOffset = glassConfig.ExitOffset or 0.2
	local remainingDistance = glassConfig.ContinueDistance or range

	local secondOrigin = firstResult.Position + direction.Unit * exitOffset
	local secondParams = makeRaycastParams({ character, glassRoot })

	local secondResult = Workspace:Raycast(secondOrigin, direction.Unit * remainingDistance, secondParams)

	return secondResult, {
		GlassResult = firstResult,
		DamageMultiplier = glassConfig.DamageMultiplier or 0.65,
	}
end

local function applyDamage(player, tool, result, config, damageMultiplier)
	if not result or not result.Instance then
		return nil
	end

	local hitPart = result.Instance
	local targetModel = hitPart:FindFirstAncestorOfClass("Model")
	if not targetModel then
		return nil
	end

	local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return nil
	end

	if player.Character and targetModel == player.Character then
		return nil
	end

	local headshot = hitPart.Name == "Head"
	local damage = config.Damage or 25

	if headshot then
		damage *= config.HeadshotMultiplier or 2
	end

	damage *= damageMultiplier or 1

	local targetPlayer = Players:GetPlayerFromCharacter(targetModel)

	if targetPlayer then
		local canDamage = CombatRulesService.CanDamage(player, targetPlayer)
		if not canDamage then
			return nil
		end
	end

	local weaponName = getWeaponName(tool, config)
	local willKill = targetHumanoid.Health - damage <= 0

	if targetPlayer and willKill then
		targetPlayer:SetAttribute(ATTR_LAST_KILLER, player.Name)
		targetPlayer:SetAttribute(ATTR_LAST_WEAPON, weaponName)
	end

	targetHumanoid:TakeDamage(damage)

	return {
		Damage = damage,
		Headshot = headshot,
		TargetName = targetModel.Name,
		HitPartName = hitPart.Name,
		HitPosition = result.Position,
		WeaponName = weaponName,
		KillerName = player.Name,
	}
end

function WeaponService.HandleFire(player, origin, direction)
	local tool = getEquippedTool(player)
	if not tool then
		return
	end

	local config = getConfig(tool)
	if not config then
		return
	end

	local state = getState(player, tool, config)

	if not isValidShot(config, state) then
		syncAmmo(player, state)
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end

	local bulletPoint = tool:FindFirstChild("BulletPoint", true)

	if bulletPoint and bulletPoint:IsA("BasePart") then
		if (origin - bulletPoint.Position).Magnitude > 8 then
			origin = bulletPoint.Position
		end
	end

	local result, penetrationInfo = raycastShot(player, origin, direction, config)
	local hitPosition = nil

	if result then
		hitPosition = result.Position

		local damageMultiplier = penetrationInfo and penetrationInfo.DamageMultiplier or 1
		local hitInfo = applyDamage(player, tool, result, config, damageMultiplier)

		if hitInfo then
			WeaponHit:FireClient(player, hitInfo)
		end

		fireImpact(result, hitInfo)
	elseif penetrationInfo and penetrationInfo.GlassResult then
		hitPosition = penetrationInfo.GlassResult.Position
	end

	syncAmmo(player, state)
	WeaponFire:FireAllClients(player, tool, origin, direction, hitPosition)
	handleSuppression(player, origin, direction, config.Range or SUPPRESSION_RANGE)
end

function WeaponService.HandleReload(player)
	local tool = getEquippedTool(player)
	if not tool then
		return
	end

	local config = getConfig(tool)
	if not config then
		return
	end

	local state = getState(player, tool, config)

	if state.Reloading then
		return
	end

	if state.Ammo >= config.MagazineSize then
		return
	end

	if state.Reserve <= 0 then
		return
	end

	state.Reloading = true
	syncAmmo(player, state)

	task.delay(config.ReloadTime or 2.35, function()
		if not player.Parent then
			return
		end

		if getEquippedTool(player) ~= tool then
			state.Reloading = false
			return
		end

		local needed = config.MagazineSize - state.Ammo
		local taken = math.min(needed, state.Reserve)

		state.Ammo += taken
		state.Reserve -= taken
		state.Reloading = false

		WeaponReload:FireClient(player, state.Ammo, state.Reserve)
		syncAmmo(player, state)
	end)
end

function WeaponService.GetEquippedAmmo(player)
	local tool = getEquippedTool(player)
	if not tool then
		return 0, 0
	end

	local config = getConfig(tool)
	if not config then
		return 0, 0
	end

	local state = getState(player, tool, config)
	return state.Ammo, state.Reserve
end

function WeaponService.RefillToolAmmo(player, tool)
	if not isWeaponTool(tool) then
		return false
	end

	local config = getConfig(tool)
	if not config then
		return false
	end

	local state = getState(player, tool, config)

	state.Ammo = config.MagazineSize or state.Ammo
	state.Reserve = config.ReserveAmmo or state.Reserve
	state.Reloading = false

	if getEquippedTool(player) == tool then
		syncAmmo(player, state)
		WeaponReload:FireClient(player, state.Ammo, state.Reserve)
	end

	return true
end

function WeaponService.RefillAllAmmo(player)
	local refilled = 0

	for _, tool in ipairs(getPlayerTools(player)) do
		if WeaponService.RefillToolAmmo(player, tool) then
			refilled += 1
		end
	end

	local equippedTool = getEquippedTool(player)
	if equippedTool then
		local config = getConfig(equippedTool)
		if config then
			local state = getState(player, equippedTool, config)
			syncAmmo(player, state)
		end
	end

	return refilled
end

function WeaponService.Start()
	WeaponFire.OnServerEvent:Connect(function(player, origin, direction)
		WeaponService.HandleFire(player, origin, direction)
	end)

	WeaponReload.OnServerEvent:Connect(function(player)
		WeaponService.HandleReload(player)
	end)

	WeaponGetAmmo.OnServerInvoke = function(player)
		return WeaponService.GetEquippedAmmo(player)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			playerWeaponState[player] = {}
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerWeaponState[player] = nil
	end)

	print("[WeaponService] Started")
end

return WeaponService