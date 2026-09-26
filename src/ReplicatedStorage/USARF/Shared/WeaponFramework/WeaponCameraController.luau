local WeaponCameraController = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local active = false
local tool = nil
local config = nil
local state = nil

local originalMouseIconEnabled = true
local originalMouseBehavior = Enum.MouseBehavior.Default
local originalCameraType = nil
local originalCameraSubject = nil
local originalAutoRotate = true
local originalFieldOfView = 70

local shoulderSide = 1

local yaw = 0
local pitch = 0

local currentCameraCFrame = nil
local recoilOffset = Vector2.new(0, 0)
local recoilTarget = Vector2.new(0, 0)

local renderConnection = nil
local inputConnection = nil

local MIN_PITCH = -70
local MAX_PITCH = 55

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getHumanoid()
	local character = getCharacter()
	return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local character = getCharacter()
	return character:FindFirstChild("HumanoidRootPart")
end

local function getCamera()
	return workspace.CurrentCamera
end

local function getThirdPersonConfig()
	return config and config.ThirdPerson or {}
end

local function getCameraConfigValue(name, fallback)
	local thirdPerson = getThirdPersonConfig()
	local value = thirdPerson[name]

	if value == nil then
		return fallback
	end

	return value
end

local function getTargetFOV()
	if state and state.Aiming and config and config.ADS then
		return config.ADS.FOV or 58
	end

	return originalFieldOfView
end

local function lockMouse()
	originalMouseIconEnabled = UserInputService.MouseIconEnabled
	originalMouseBehavior = UserInputService.MouseBehavior

	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local function unlockMouse()
	UserInputService.MouseIconEnabled = originalMouseIconEnabled
	UserInputService.MouseBehavior = originalMouseBehavior
end

local function setupCamera()
	local camera = getCamera()
	local humanoid = getHumanoid()

	if camera then
		originalCameraType = camera.CameraType
		originalCameraSubject = camera.CameraSubject
		originalFieldOfView = camera.FieldOfView
		camera.CameraType = Enum.CameraType.Scriptable
	end

	if humanoid then
		originalAutoRotate = humanoid.AutoRotate
		humanoid.AutoRotate = false
	end

	local root = getRoot()
	if root then
		local _, currentYaw = root.CFrame:ToOrientation()
		yaw = currentYaw
	else
		yaw = 0
	end

	pitch = 0
	currentCameraCFrame = camera and camera.CFrame or nil
end

local function restoreCamera()
	local camera = getCamera()
	local humanoid = getHumanoid()

	if camera then
		camera.CameraType = originalCameraType or Enum.CameraType.Custom
		camera.CameraSubject = originalCameraSubject
		camera.FieldOfView = originalFieldOfView
	end

	if humanoid then
		humanoid.AutoRotate = originalAutoRotate
	end
end

local function getShoulderOffset()
	local thirdPerson = getThirdPersonConfig()
	local offset = thirdPerson.CameraOffset or Vector3.new(2.25, 1.65, 7)

	if state and state.Aiming then
		offset = thirdPerson.AimCameraOffset or Vector3.new(1.35, 1.45, 5.25)
	end

	return Vector3.new(math.abs(offset.X) * shoulderSide, offset.Y, offset.Z)
end

local function getFocusOffset()
	local thirdPerson = getThirdPersonConfig()
	return thirdPerson.FocusOffset or Vector3.new(0, 1.45, 0)
end

local function getSensitivity()
	local baseSensitivity = getCameraConfigValue("Sensitivity", 0.22)

	if state and state.Aiming and config and config.ADS then
		baseSensitivity *= config.ADS.MouseSensitivity or 0.65
	end

	return baseSensitivity
end

local function updateInput(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local sensitivity = getSensitivity()

	yaw -= math.rad(input.Delta.X * sensitivity)
	pitch = math.clamp(
		pitch - math.rad(input.Delta.Y * sensitivity),
		math.rad(MIN_PITCH),
		math.rad(MAX_PITCH)
	)
end

local function alignCharacterToCamera()
	local root = getRoot()
	if not root then
		return
	end

	root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
end

local function getDesiredCameraCFrame()
	local root = getRoot()
	if not root then
		return nil
	end

	local focusOffset = getFocusOffset()
	local shoulderOffset = getShoulderOffset()

	local focusPosition = root.Position + focusOffset
	local rotation = CFrame.fromOrientation(pitch, yaw, 0)

	local cameraPosition =
		focusPosition
		+ rotation.RightVector * shoulderOffset.X
		+ rotation.UpVector * shoulderOffset.Y
	- rotation.LookVector * shoulderOffset.Z

	return CFrame.lookAt(cameraPosition, focusPosition + rotation.LookVector * 100)
end

local function applyCameraCollision(focusPosition, desiredPosition)
	local character = getCharacter()

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	local direction = desiredPosition - focusPosition
	local result = workspace:Raycast(focusPosition, direction, params)

	if result then
		local safeDistance = math.max(result.Distance - 0.35, 0.5)
		return focusPosition + direction.Unit * safeDistance
	end

	return desiredPosition
end

local function applyFOV(deltaTime)
	local camera = getCamera()
	if not camera then
		return
	end

	local aimTime = 0.14

	if config and config.ADS then
		aimTime = config.ADS.AimTime or 0.14
	end

	local speed = 1 / math.max(aimTime, 0.01)
	local alpha = 1 - math.exp(-speed * deltaTime)

	camera.FieldOfView += (getTargetFOV() - camera.FieldOfView) * alpha
end

local function applyRecoil(deltaTime)
	local camera = getCamera()
	if not camera then
		return
	end

	local recoilConfig = config and config.Recoil or {}
	local recovery = recoilConfig.Recovery or 0.08

	recoilOffset = recoilOffset:Lerp(recoilTarget, math.clamp(deltaTime * 35, 0, 1))
	recoilTarget = recoilTarget:Lerp(Vector2.new(0, 0), math.clamp(deltaTime / recovery, 0, 1))

	camera.CFrame *= CFrame.Angles(
		math.rad(recoilOffset.Y),
		math.rad(recoilOffset.X),
		0
	)
end

function WeaponCameraController.ToggleShoulder()
	if not active or not config then
		return
	end

	local thirdPerson = getThirdPersonConfig()

	if thirdPerson.ShoulderSwapEnabled == false then
		return
	end

	shoulderSide *= -1
end

function WeaponCameraController.GetAimRay()
	local camera = getCamera()
	if not camera then
		return nil
	end

	local viewport = camera.ViewportSize
	return camera:ViewportPointToRay(viewport.X / 2, viewport.Y / 2)
end

function WeaponCameraController.AddRecoil()
	if not active or not config then
		return
	end

	local recoilConfig = config.Recoil or {}

	local multiplier = 1
	if state and state.Aiming and config.ADS then
		multiplier = config.ADS.RecoilMultiplier or 0.75
	end

	local vertical = (recoilConfig.Vertical or 0.35) * multiplier
	local horizontal = (recoilConfig.Horizontal or 0.08) * multiplier
	local horizontalKick = math.random(-horizontal * 100, horizontal * 100) / 100

	recoilTarget += Vector2.new(horizontalKick, vertical)
end

function WeaponCameraController.Start(startTool, weaponConfig, weaponState)
	tool = startTool
	config = weaponConfig
	state = weaponState
	active = true
	shoulderSide = 1

	lockMouse()
	setupCamera()

	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end

	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	inputConnection = UserInputService.InputChanged:Connect(updateInput)

	renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if not active then
			return
		end

		local camera = getCamera()
		local root = getRoot()

		if not camera or not root then
			return
		end

		alignCharacterToCamera()

		local desiredCFrame = getDesiredCameraCFrame()
		if not desiredCFrame then
			return
		end

		local focusPosition = root.Position + getFocusOffset()
		local safePosition = applyCameraCollision(focusPosition, desiredCFrame.Position)
		local safeCFrame = CFrame.lookAt(safePosition, focusPosition + desiredCFrame.LookVector * 100)

		local smoothSpeed = getCameraConfigValue("SmoothSpeed", 18)
		local alpha = 1 - math.exp(-smoothSpeed * deltaTime)

		if not currentCameraCFrame then
			currentCameraCFrame = safeCFrame
		end

		currentCameraCFrame = currentCameraCFrame:Lerp(safeCFrame, alpha)
		camera.CFrame = currentCameraCFrame

		applyFOV(deltaTime)
		applyRecoil(deltaTime)
	end)
end

function WeaponCameraController.Stop()
	active = false

	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end

	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	restoreCamera()
	unlockMouse()

	recoilOffset = Vector2.new(0, 0)
	recoilTarget = Vector2.new(0, 0)
	currentCameraCFrame = nil

	tool = nil
	config = nil
	state = nil
end

return WeaponCameraController