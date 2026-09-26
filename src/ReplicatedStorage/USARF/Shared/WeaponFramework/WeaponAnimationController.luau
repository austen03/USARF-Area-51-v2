local WeaponAnimationController = {}

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local context = nil
local animationTracks = {}

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getHumanoid()
	local character = getCharacter()
	return character:FindFirstChildOfClass("Humanoid")
end

local function getAnimator()
	local humanoid = getHumanoid()
	if not humanoid then
		return nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return animator
end

local function loadAnimation(name, looped, priority)
	local tool = context.Tool
	local folder = tool:FindFirstChild("Animations")
	if not folder then
		return nil
	end

	local animation = folder:FindFirstChild(name)
	if not animation or not animation:IsA("Animation") or animation.AnimationId == "" then
		return nil
	end

	local animator = getAnimator()
	if not animator then
		return nil
	end

	local success, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not success or not track then
		warn("[WeaponAnimationController] Failed to load animation:", name)
		return nil
	end

	track.Looped = looped == true
	track.Priority = priority or Enum.AnimationPriority.Action

	return track
end

function WeaponAnimationController.Load()
	animationTracks = {
		Idle = loadAnimation("Idle", true, Enum.AnimationPriority.Action),
		Reload = loadAnimation("Reload", false, Enum.AnimationPriority.Action2),
		Sprint = loadAnimation("Sprint", true, Enum.AnimationPriority.Action),
		Crouch = loadAnimation("Crouch", true, Enum.AnimationPriority.Action),
	}
end

function WeaponAnimationController.StopTrack(name, fadeTime)
	local track = animationTracks[name]
	if track then
		track:Stop(fadeTime or 0.15)
	end
end

function WeaponAnimationController.PlayTrack(name, fadeTime)
	local track = animationTracks[name]
	if track and not track.IsPlaying then
		track:Play(fadeTime or 0.15)
	end
end

function WeaponAnimationController.PlayIdle()
	local state = context.State

	if not state.Equipped or state.Reloading or state.Sprinting or state.Crouching then
		return
	end

	WeaponAnimationController.StopTrack("Sprint", 0.15)
	WeaponAnimationController.StopTrack("Crouch", 0.15)
	WeaponAnimationController.PlayTrack("Idle", 0.15)
end

function WeaponAnimationController.StopAll()
	for _, track in pairs(animationTracks) do
		if track then
			track:Stop(0.15)
		end
	end
end

function WeaponAnimationController.Start(newContext)
	context = newContext
	WeaponAnimationController.Load()
end

function WeaponAnimationController.Stop()
	WeaponAnimationController.StopAll()
	animationTracks = {}
	context = nil
end

return WeaponAnimationController