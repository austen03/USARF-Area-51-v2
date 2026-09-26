local WeaponClient = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local Shared = USARF:WaitForChild("Shared")
local WeaponFramework = Shared:WaitForChild("WeaponFramework")

local WeaponCameraController = require(WeaponFramework:WaitForChild("WeaponCameraController"))
local WeaponHUDController = require(WeaponFramework:WaitForChild("WeaponHUDController"))
local WeaponEffectsController = require(WeaponFramework:WaitForChild("WeaponEffectsController"))
local WeaponAnimationController = require(WeaponFramework:WaitForChild("WeaponAnimationController"))
local WeaponFireController = require(WeaponFramework:WaitForChild("WeaponFireController"))
local WeaponAttachmentResolver = require(WeaponFramework:WaitForChild("WeaponAttachmentResolver"))
local WeaponSuppressionController = require(WeaponFramework:WaitForChild("WeaponSuppressionController"))

local WeaponImpact = Remotes:WaitForChild("WeaponImpact")
local WeaponReload = Remotes:WaitForChild("WeaponReload")
local WeaponHit = Remotes:WaitForChild("WeaponHit")
local WeaponFire = Remotes:WaitForChild("WeaponFire")
local WeaponGetAmmo = Remotes:WaitForChild("WeaponGetAmmo")
local WeaponAmmoSync = Remotes:WaitForChild("WeaponAmmoSync")
local WeaponSuppression = Remotes:WaitForChild("WeaponSuppression")

local registeredTools = {}
local context = nil

local function normalizeFireModes(config)
	if type(config.FireModes) == "table" and #config.FireModes > 0 then
		return config.FireModes
	end

	if config.Automatic then
		return { "AUTO", "SEMI" }
	end

	return { "SEMI" }
end

local function getDefaultFireMode(config, modes)
	if config.DefaultFireMode then
		for _, mode in ipairs(modes) do
			if mode == config.DefaultFireMode then
				return mode
			end
		end
	end

	return modes[1] or "SEMI"
end

local function syncAmmoFromServer()
	if not context then
		return
	end

	local success, serverAmmo, serverReserve = pcall(function()
		return WeaponGetAmmo:InvokeServer()
	end)

	if success then
		context.Ammo = serverAmmo or context.Ammo
		context.Reserve = serverReserve or context.Reserve
		context.UpdateHud()
	end
end

local function setSprinting(isSprinting)
	local state = context.State

	if not state.Equipped or state.Reloading then
		return
	end

	state.Sprinting = isSprinting

	if state.Sprinting then
		state.Crouching = false
		state.Aiming = false
		state.Firing = false

		context.StopTrack("Idle", 0.15)
		context.StopTrack("Crouch", 0.15)
		context.PlayTrack("Sprint", 0.15)
	else
		context.StopTrack("Sprint", 0.15)
		context.PlayIdle()
	end

	context.UpdateHud()
end

local function setCrouching(isCrouching)
	local state = context.State

	if not state.Equipped or state.Reloading then
		return
	end

	state.Crouching = isCrouching

	if state.Crouching then
		state.Sprinting = false
		state.Firing = false

		context.StopTrack("Idle", 0.15)
		context.StopTrack("Sprint", 0.15)
		context.PlayTrack("Crouch", 0.15)
	else
		context.StopTrack("Crouch", 0.15)
		context.PlayIdle()
	end

	context.UpdateHud()
end

local function setAiming(isAiming)
	local state = context.State
	local config = context.Config

	if not state.Equipped or state.Reloading or state.Sprinting then
		return
	end

	if not config.ADS or config.ADS.Enabled == false then
		return
	end

	state.Aiming = isAiming
	context.UpdateHud()
end

local function buildContext(tool)
	local baseConfig = require(tool:WaitForChild("Config"))
	local config = WeaponAttachmentResolver.Resolve(baseConfig)
	local fireModes = normalizeFireModes(config)

	local newContext = {
		Player = player,
		Tool = tool,
		Config = config,

		State = {
			Equipped = false,
			Firing = false,
			Reloading = false,
			Sprinting = false,
			Crouching = false,
			Aiming = false,
		},

		Ammo = config.MagazineSize,
		Reserve = config.ReserveAmmo,

		FireModes = fireModes,
		CurrentFireMode = getDefaultFireMode(config, fireModes),
	}

	newContext.UpdateHud = function()
		WeaponHUDController.Update()
	end

	newContext.PlayTrack = function(name, fadeTime)
		WeaponAnimationController.PlayTrack(name, fadeTime)
	end

	newContext.StopTrack = function(name, fadeTime)
		WeaponAnimationController.StopTrack(name, fadeTime)
	end

	newContext.PlayIdle = function()
		WeaponAnimationController.PlayIdle()
	end

	return newContext
end

local function onEquipped(tool)
	context = buildContext(tool)

	local state = context.State

	state.Equipped = true
	state.Firing = false
	state.Reloading = false
	state.Sprinting = false
	state.Crouching = false
	state.Aiming = false

	WeaponCameraController.Start(context.Tool, context.Config, context.State)
	WeaponHUDController.Start(context)
	WeaponEffectsController.Start(context)
	WeaponAnimationController.Start(context)
	WeaponFireController.Start(context)

	syncAmmoFromServer()

	WeaponAnimationController.PlayIdle()
	WeaponEffectsController.PlaySound(context.Config.EquipSoundName or "Equip")
	WeaponHUDController.Update()
end

local function onUnequipped(tool)
	if not context or context.Tool ~= tool then
		return
	end

	local state = context.State

	state.Equipped = false
	state.Firing = false
	state.Reloading = false
	state.Sprinting = false
	state.Crouching = false
	state.Aiming = false

	WeaponFireController.StopFiring()
	WeaponCameraController.Stop()
	WeaponHUDController.Stop()
	WeaponAnimationController.Stop()
	WeaponEffectsController.Stop()
	WeaponFireController.Stop()

	context = nil
end

function WeaponClient.Start(tool)
	if registeredTools[tool] then
		return
	end

	registeredTools[tool] = true

	tool.Equipped:Connect(function()
		onEquipped(tool)
	end)

	tool.Unequipped:Connect(function()
		onUnequipped(tool)
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not context or not context.State.Equipped then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		WeaponFireController.StartFiring()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		setAiming(true)
	elseif input.KeyCode == Enum.KeyCode.R then
		WeaponFireController.Reload()
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		setSprinting(true)
	elseif input.KeyCode == Enum.KeyCode.C then
		setCrouching(not context.State.Crouching)
	elseif input.KeyCode == Enum.KeyCode.T then
		WeaponCameraController.ToggleShoulder()
	elseif input.KeyCode == Enum.KeyCode.V then
		WeaponFireController.ToggleFireMode()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not context or not context.State.Equipped then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		WeaponFireController.StopFiring()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		setAiming(false)
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		setSprinting(false)
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	if context and context.State.Equipped then
		WeaponHUDController.RenderStep(deltaTime)
	end
end)

WeaponReload.OnClientEvent:Connect(function(newAmmo, newReserve)
	if not context then
		return
	end

	context.Ammo = newAmmo
	context.Reserve = newReserve
	context.State.Reloading = false

	WeaponHUDController.Update()

	if context.State.Equipped then
		WeaponAnimationController.PlayIdle()
	end
end)

WeaponAmmoSync.OnClientEvent:Connect(function(newAmmo, newReserve)
	if not context then
		return
	end

	context.Ammo = newAmmo
	context.Reserve = newReserve

	WeaponHUDController.Update()
end)

WeaponHit.OnClientEvent:Connect(function(payload)
	WeaponHUDController.ShowHitmarker(payload)
end)

WeaponImpact.OnClientEvent:Connect(function(payload)
	WeaponEffectsController.PlayImpact(payload)
end)


WeaponFire.OnClientEvent:Connect(function(shooter, firedTool, origin, direction, hitPosition)
	if not context then
		return
	end

	if shooter == player then
		return
	end

	if not firedTool or not firedTool.Parent then
		return
	end

	local endPosition = hitPosition

	if not endPosition and origin and direction then
		endPosition = origin + direction.Unit * (context.Config.Range or 650)
	end

	WeaponEffectsController.PlayMuzzleFX(firedTool, origin, endPosition)
end)

return WeaponClient