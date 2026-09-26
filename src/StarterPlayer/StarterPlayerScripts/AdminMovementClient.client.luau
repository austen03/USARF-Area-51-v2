local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local AdminMovementRemote = Remotes:WaitForChild("AdminMovement")

local flying = false
local noclip = false
local speed = 70

local bodyVelocity = nil
local bodyGyro = nil
local renderConnection = nil
local noclipConnection = nil

local function getCharacter()
	return Player.Character
end

local function getRoot()
	local character = getCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
	local character = getCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function cleanupFly()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end

	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end

	local humanoid = getHumanoid()

	if humanoid then
		humanoid.PlatformStand = false
	end
end

local function setCharacterNoclip(enabled)
	local character = getCharacter()

	if not character then
		return
	end

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = not enabled
		end
	end
end

local function stopNoclip()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end

	noclip = false
	setCharacterNoclip(false)
end

local function startNoclip()
	stopNoclip()

	noclip = true
	setCharacterNoclip(true)

	noclipConnection = RunService.Stepped:Connect(function()
		if not noclip then
			return
		end

		setCharacterNoclip(true)
	end)
end

local function getMoveVector()
	local move = Vector3.zero

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		move += Camera.CFrame.LookVector
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		move -= Camera.CFrame.LookVector
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		move -= Camera.CFrame.RightVector
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		move += Camera.CFrame.RightVector
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		move += Vector3.yAxis
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		move -= Vector3.yAxis
	end

	if move.Magnitude > 0 then
		return move.Unit
	end

	return Vector3.zero
end

local function startFly(newSpeed)
	cleanupFly()

	speed = tonumber(newSpeed) or speed
	flying = true

	local root = getRoot()
	local humanoid = getHumanoid()

	if not root or not humanoid then
		return
	end

	humanoid.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "USARF_AdminFlyVelocity"
	bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = root

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.Name = "USARF_AdminFlyGyro"
	bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bodyGyro.P = 9000
	bodyGyro.CFrame = root.CFrame
	bodyGyro.Parent = root

	renderConnection = RunService.RenderStepped:Connect(function()
		if not flying then
			return
		end

		local currentRoot = getRoot()
		local currentHumanoid = getHumanoid()

		if not currentRoot or not currentHumanoid or not bodyVelocity or not bodyGyro then
			cleanupFly()
			return
		end

		currentHumanoid.PlatformStand = true

		local moveVector = getMoveVector()

		bodyVelocity.Velocity = moveVector * speed
		bodyGyro.CFrame = Camera.CFrame
	end)
end

local function stopFly()
	flying = false
	cleanupFly()
end

AdminMovementRemote.OnClientEvent:Connect(function(action, data)
	data = typeof(data) == "table" and data or {}

	if action == "Fly" then
		startFly(data.Speed)
	elseif action == "Unfly" then
		stopFly()
	elseif action == "Noclip" then
		startNoclip()
	elseif action == "Clip" then
		stopNoclip()
	elseif action == "StopAll" then
		stopFly()
		stopNoclip()
	end
end)

Player.CharacterAdded:Connect(function()
	task.wait(0.5)

	if flying then
		startFly(speed)
	end

	if noclip then
		startNoclip()
	end
end)