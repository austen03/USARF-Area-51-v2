local WeaponFireController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local Shared = USARF:WaitForChild("Shared")
local WeaponFramework = Shared:WaitForChild("WeaponFramework")

local WeaponCameraController = require(WeaponFramework:WaitForChild("WeaponCameraController"))
local WeaponEffectsController = require(WeaponFramework:WaitForChild("WeaponEffectsController"))

local WeaponFire = Remotes:WaitForChild("WeaponFire")
local WeaponReload = Remotes:WaitForChild("WeaponReload")

local context = nil

local function getBulletPointFromTool(targetTool)
	targetTool = targetTool or context.Tool
	if not targetTool then
		return nil
	end

	local bulletPoint = targetTool:FindFirstChild("BulletPoint", true)
	if bulletPoint and bulletPoint:IsA("BasePart") then
		return bulletPoint
	end

	local handle = targetTool:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		return handle
	end

	return nil
end

local function getSpread()
	local config = context.Config
	local state = context.State

	local spread = config.Spread or 0

	if state.Aiming and config.ADS then
		spread *= config.ADS.SpreadMultiplier or 0.55
	end

	if state.Crouching then
		spread *= 0.8
	end

	return spread
end

local function getShotDirection()
	local bulletPoint = getBulletPointFromTool(context.Tool)
	if not bulletPoint then
		return nil, nil
	end

	local aimRay = WeaponCameraController.GetAimRay()
	if not aimRay then
		return nil, nil
	end

	local origin = bulletPoint.Position
	local target = aimRay.Origin + aimRay.Direction * (context.Config.Range or 650)

	local spread = getSpread()
	local spreadX = math.rad(math.random(-spread * 100, spread * 100) / 100)
	local spreadY = math.rad(math.random(-spread * 100, spread * 100) / 100)

	local direction = (target - origin).Unit
	direction = CFrame.fromOrientation(spreadX, spreadY, 0):VectorToWorldSpace(direction)

	return origin, direction
end

local function canFire()
	local state = context.State

	if not state.Equipped or state.Reloading or state.Sprinting then
		return false
	end

	if context.Ammo <= 0 then
		WeaponEffectsController.PlaySound(context.Config.EmptySoundName or "Empty")
		context.UpdateHud()
		return false
	end

	return true
end

function WeaponFireController.FireOnce()
	if not canFire() then
		return false
	end

	local origin, direction = getShotDirection()
	if not origin or not direction then
		return false
	end

	context.Ammo -= 1
	context.UpdateHud()

	local localEnd = origin + direction.Unit * (context.Config.Range or 650)

	WeaponEffectsController.PlaySound(context.Config.FireSoundName or "Fire")
	WeaponEffectsController.PlayMuzzleFX(context.Tool, origin, localEnd)
	WeaponEffectsController.EjectShell(context.Tool)
	WeaponCameraController.AddRecoil()

	WeaponFire:FireServer(origin, direction)

	return true
end

local function fireAuto()
	while context.State.Firing and context.State.Equipped do
		WeaponFireController.FireOnce()
		task.wait(60 / (context.Config.FireRate or 600))
	end
end

local function fireSemi()
	WeaponFireController.FireOnce()
end

local function fireBurst()
	local burstCount = context.Config.BurstCount or 3
	local burstDelay = context.Config.BurstDelay or 0.06

	for _ = 1, burstCount do
		if not context.State.Equipped or context.State.Reloading or context.State.Sprinting then
			break
		end

		if not WeaponFireController.FireOnce() then
			break
		end

		task.wait(burstDelay)
	end
end

function WeaponFireController.StartFiring()
	if context.State.Firing then
		return
	end

	context.State.Firing = true

	local mode = context.CurrentFireMode or "SEMI"

	if mode == "AUTO" then
		fireAuto()
	elseif mode == "BURST" then
		fireBurst()
	else
		fireSemi()
	end
end

function WeaponFireController.StopFiring()
	if not context then
		return
	end

	context.State.Firing = false
end

function WeaponFireController.Reload()
	local state = context.State
	local config = context.Config

	if state.Reloading or context.Ammo >= config.MagazineSize or context.Reserve <= 0 then
		return
	end

	state.Reloading = true
	state.Firing = false
	state.Sprinting = false
	state.Crouching = false
	state.Aiming = false

	context.UpdateHud()
	context.StopTrack("Idle", 0.1)
	context.StopTrack("Sprint", 0.1)
	context.StopTrack("Crouch", 0.1)

	WeaponEffectsController.PlaySound(config.ReloadSoundName or "Reload")
	context.PlayTrack("Reload", 0.08)

	WeaponReload:FireServer()

	task.delay(config.ReloadTime or 2.35, function()
		if not context or not context.State.Equipped then
			return
		end

		context.State.Reloading = false
		context.UpdateHud()
		context.PlayIdle()
	end)
end

function WeaponFireController.ToggleFireMode()
	local modes = context.FireModes
	if not modes or #modes <= 1 then
		return
	end

	local currentIndex = 1

	for index, mode in ipairs(modes) do
		if mode == context.CurrentFireMode then
			currentIndex = index
			break
		end
	end

	local nextIndex = currentIndex + 1
	if nextIndex > #modes then
		nextIndex = 1
	end

	context.CurrentFireMode = modes[nextIndex]

	WeaponEffectsController.PlaySound(context.Config.FireModeSoundName or "FireMode")
	context.UpdateHud()
end

function WeaponFireController.Start(newContext)
	context = newContext
end

function WeaponFireController.Stop()
	context = nil
end

return WeaponFireController