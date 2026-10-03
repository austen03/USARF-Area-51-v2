local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local DeveloperCommandBridge = Remotes:WaitForChild("DeveloperCommandBridge")
local FreecamStateRemote = Remotes:WaitForChild("DeveloperFreecamState")

local BASE_SPEED = 45
local BOOST_MULTIPLIER = 3
local LOOK_SENSITIVITY = 0.0025

local freecamActive = false
local freecamConnection = nil
local inputBeganConnection = nil
local inputEndedConnection = nil
local inputChangedConnection = nil

local keyState = {}
local yaw = 0
local pitch = 0

local savedCameraState = nil
local savedMouseBehavior = nil
local savedMouseIconEnabled = nil

local function getCamera()
	return workspace.CurrentCamera
end

local function getCharacterFromInstance(instance)
	local current = instance

	while current and current ~= workspace do
		if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
			return current
		end

		current = current.Parent
	end

	return nil
end

local function getHoveredPlayer()
	local target = Mouse.Target

	if not target then
		return {
			success = false,
			message = "Your mouse is not hovering over a player.",
		}
	end

	local character = getCharacterFromInstance(target)
	local targetPlayer = character and Players:GetPlayerFromCharacter(character)

	if not targetPlayer then
		return {
			success = false,
			message = "Your mouse is not hovering over a player.",
		}
	end

	local localRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")

	local targetRoot = character and character:FindFirstChild("HumanoidRootPart")

	local distance = 0

	if localRoot and targetRoot then
		distance = (localRoot.Position - targetRoot.Position).Magnitude
	end

	local teamName = "No Team"

	if targetPlayer.Team then
		teamName = targetPlayer.Team.Name
	else
		local attributeTeam = targetPlayer:GetAttribute("USARF_TeamName")

		if attributeTeam and attributeTeam ~= "" then
			teamName = attributeTeam
		end
	end

	return {
		success = true,
		username = targetPlayer.Name,
		displayName = targetPlayer.DisplayName,
		userId = targetPlayer.UserId,
		team = teamName,
		distance = distance,
	}
end

local function getMouseWorldPosition()
	local camera = getCamera()

	if not camera then
		return {
			success = false,
			message = "The camera is unavailable.",
		}
	end

	local mousePosition = UserInputService:GetMouseLocation()

	local ray = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = false

	local excluded = {}

	if Player.Character then
		table.insert(excluded, Player.Character)
	end

	raycastParams.FilterDescendantsInstances = excluded

	local result = workspace:Raycast(ray.Origin, ray.Direction * 10000, raycastParams)

	if not result then
		return {
			success = false,
			message = "Your mouse is not hovering over a valid surface.",
		}
	end

	return {
		success = true,
		position = result.Position,
		normal = result.Normal,
		partName = result.Instance and result.Instance:GetFullName() or "Unknown",
	}
end

local function disconnectFreecamConnections()
	if freecamConnection then
		freecamConnection:Disconnect()
		freecamConnection = nil
	end

	if inputBeganConnection then
		inputBeganConnection:Disconnect()
		inputBeganConnection = nil
	end

	if inputEndedConnection then
		inputEndedConnection:Disconnect()
		inputEndedConnection = nil
	end

	if inputChangedConnection then
		inputChangedConnection:Disconnect()
		inputChangedConnection = nil
	end
end

local function disableFreecam()
	if not freecamActive then
		return
	end

	freecamActive = false
	disconnectFreecamConnections()
	table.clear(keyState)

	local camera = getCamera()

	if camera and savedCameraState then
		camera.CameraType = savedCameraState.cameraType
		camera.CameraSubject = savedCameraState.cameraSubject
		camera.CFrame = savedCameraState.cframe
		camera.FieldOfView = savedCameraState.fieldOfView
	end

	if savedMouseBehavior then
		UserInputService.MouseBehavior = savedMouseBehavior
	end

	if savedMouseIconEnabled ~= nil then
		UserInputService.MouseIconEnabled = savedMouseIconEnabled
	end

	savedCameraState = nil
	savedMouseBehavior = nil
	savedMouseIconEnabled = nil

	FreecamStateRemote:FireServer(false)
end

local function keyDown(keyCode)
	return keyState[keyCode] == true
end

local function enableFreecam()
	if freecamActive then
		return
	end

	local camera = getCamera()

	if not camera then
		return
	end

	freecamActive = true

	savedCameraState = {
		cameraType = camera.CameraType,
		cameraSubject = camera.CameraSubject,
		cframe = camera.CFrame,
		fieldOfView = camera.FieldOfView,
	}

	savedMouseBehavior = UserInputService.MouseBehavior
	savedMouseIconEnabled = UserInputService.MouseIconEnabled

	camera.CameraType = Enum.CameraType.Scriptable

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true

	local lookVector = camera.CFrame.LookVector
	yaw = math.atan2(-lookVector.X, -lookVector.Z)
	pitch = math.asin(math.clamp(lookVector.Y, -1, 1))

	inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed and input.KeyCode ~= Enum.KeyCode.X then
			return
		end

		if input.KeyCode == Enum.KeyCode.X then
			disableFreecam()
			return
		end

		keyState[input.KeyCode] = true
	end)

	inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
		keyState[input.KeyCode] = nil
	end)

	inputChangedConnection = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			yaw -= input.Delta.X * LOOK_SENSITIVITY

			pitch = math.clamp(pitch - input.Delta.Y * LOOK_SENSITIVITY, math.rad(-89), math.rad(89))
		end
	end)

	freecamConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if not freecamActive then
			return
		end

		local currentCamera = getCamera()

		if not currentCamera then
			disableFreecam()
			return
		end

		local rotation = CFrame.fromOrientation(pitch, yaw, 0)
		local move = Vector3.zero

		if keyDown(Enum.KeyCode.W) then
			move += Vector3.new(0, 0, -1)
		end

		if keyDown(Enum.KeyCode.S) then
			move += Vector3.new(0, 0, 1)
		end

		if keyDown(Enum.KeyCode.A) then
			move += Vector3.new(-1, 0, 0)
		end

		if keyDown(Enum.KeyCode.D) then
			move += Vector3.new(1, 0, 0)
		end

		if keyDown(Enum.KeyCode.E) then
			move += Vector3.new(0, 1, 0)
		end

		if keyDown(Enum.KeyCode.Q) then
			move += Vector3.new(0, -1, 0)
		end

		local speed = BASE_SPEED

		if keyDown(Enum.KeyCode.LeftShift) or keyDown(Enum.KeyCode.RightShift) then
			speed *= BOOST_MULTIPLIER
		end

		local position = currentCamera.CFrame.Position

		if move.Magnitude > 0 then
			move = move.Unit

			position += rotation:VectorToWorldSpace(move) * speed * deltaTime
		end

		currentCamera.CFrame = CFrame.new(position) * rotation
	end)

	FreecamStateRemote:FireServer(true)
end

local function toggleFreecam()
	if freecamActive then
		disableFreecam()
	else
		enableFreecam()
	end

	return {
		success = true,
		active = freecamActive,
	}
end

DeveloperCommandBridge.OnClientInvoke = function(action)
	if action == "GetHoveredPlayer" then
		return getHoveredPlayer()
	end

	if action == "GetMouseWorldPosition" then
		return getMouseWorldPosition()
	end

	if action == "ToggleFreecam" then
		return toggleFreecam()
	end

	return {
		success = false,
		message = "Unknown developer command action.",
	}
end

Player.CharacterAdded:Connect(function()
	if freecamActive then
		disableFreecam()
	end
end)

print("[USARFDeveloperController] Loaded")
