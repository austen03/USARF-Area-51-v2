local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Suppression = {}

local DEBUG = false

local BULLET_NEAR_SOUND_ID = "rbxassetid://72765322872570"
local BULLET_VERY_CLOSE_SOUND_ID = "rbxassetid://92059392403012"
local RINGING_SOUND_ID = "rbxassetid://85488739763824"

local EVENT_WINDOW = 3
local MAX_EVENTS = 8

local events = {}
local activeShake = false
local ringingSound
local nearSound
local veryCloseSound
local blur

local function debugPrint(...)
	if DEBUG then
		print("[WeaponSuppressionController]", ...)
	end
end

local function makeSound(name, soundId, volume)
	local sound = playerGui:FindFirstChild(name)
	
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = soundId
		sound.Volume = volume
		sound.Looped = false
		sound.Parent = playerGui
	end
	
	sound.Loaded:Connect(function()
		print("[SuppressionSound] Loaded:", name, sound.SoundId)
	end)

	sound:GetPropertyChangedSignal("IsLoaded"):Connect(function()
		print("[SuppressionSound] IsLoaded:", name, sound.IsLoaded)
	end)

	sound.Ended:Connect(function()
		print("[SuppressionSound] Ended:", name)
	end)
	return sound
end

local function ensureSounds()
	nearSound = makeSound("USARF_BulletWhiz_Near", BULLET_NEAR_SOUND_ID, 0.65)
	veryCloseSound = makeSound("USARF_BulletWhiz_VeryClose", BULLET_VERY_CLOSE_SOUND_ID, 0.95)
	ringingSound = makeSound("USARF_Suppression_Ringing", RINGING_SOUND_ID, 0.4)
end

local function ensureBlur()
	if blur and blur.Parent then
		return blur
	end

	blur = Instance.new("BlurEffect")
	blur.Name = "USARF_SuppressionBlur"
	blur.Size = 0
	blur.Parent = Lighting

	return blur
end

local function cleanupEvents()
	local now = os.clock()

	for i = #events, 1, -1 do
		if now - events[i] > EVENT_WINDOW then
			table.remove(events, i)
		end
	end

	while #events > MAX_EVENTS do
		table.remove(events, 1)
	end
end

local function addSuppressionEvent()
	table.insert(events, os.clock())
	cleanupEvents()
	return #events
end

local function playSound(sound, volume, pitchMin, pitchMax)
	if not sound then
		return
	end

	sound:Stop()
	sound.Volume = volume
	sound.PlaybackSpeed = pitchMin + math.random() * (pitchMax - pitchMin)
	sound:Play()
end

local function playRinging(count, intensity)
	if count < 4 then
		return
	end

	ensureSounds()

	local volume
	if count >= 6 then
		volume = 0.45
	else
		volume = 0.3 + (0.1 * intensity)
	end

	ringingSound:Stop()
	ringingSound.Volume = math.clamp(volume, 0.25, 0.45)
	ringingSound.PlaybackSpeed = 1
	ringingSound:Play()
end

local function cameraShake(count, intensity)
	if activeShake then
		return
	end

	activeShake = true

	local camera = Workspace.CurrentCamera
	if not camera then
		activeShake = false
		return
	end

	local originalFOV = camera.FieldOfView
	local shakeAmount = 1.5 * intensity

	if count >= 6 then
		shakeAmount = 4 * intensity
	elseif count >= 4 then
		shakeAmount = 3 * intensity
	elseif count >= 2 then
		shakeAmount = 2 * intensity
	end

	local expand = TweenService:Create(camera, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
		FieldOfView = originalFOV + shakeAmount,
	})

	local recover = TweenService:Create(camera, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
		FieldOfView = originalFOV,
	})

	expand:Play()
	expand.Completed:Wait()

	recover:Play()
	recover.Completed:Wait()

	activeShake = false
end

local function pulseBlur(count)
	if count < 6 then
		return
	end

	local blurEffect = ensureBlur()

	local blurIn = TweenService:Create(blurEffect, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
		Size = 8,
	})

	local blurOut = TweenService:Create(blurEffect, TweenInfo.new(0.65, Enum.EasingStyle.Quad), {
		Size = 0,
	})

	blurIn:Play()
	blurIn.Completed:Wait()

	blurOut:Play()
end

function Suppression.Play(position, intensity)
	intensity = math.clamp(tonumber(intensity) or 0.5, 0.25, 1)

	ensureSounds()

	local count = addSuppressionEvent()

	debugPrint("Suppression received", "Count:", count, "Intensity:", intensity)

	if count >= 3 or intensity >= 0.75 then
		playSound(veryCloseSound, 0.9 + (0.1 * intensity), 0.95, 1.08)
	else
		playSound(nearSound, 0.55 + (0.15 * intensity), 0.95, 1.08)
	end

	if count >= 2 then
		task.spawn(cameraShake, count, intensity)
	end

	if count >= 4 then
		playRinging(count, intensity)
	end

	if count >= 6 then
		task.spawn(pulseBlur, count)
	end
end

return Suppression