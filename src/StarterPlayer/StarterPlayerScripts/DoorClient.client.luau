local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local DoorEvent = Remotes:WaitForChild("DoorEvent")

local USARFGui = PlayerGui:WaitForChild("USARFGui")
local Popups = USARFGui:FindFirstChild("Popups")
local RadioPanel = Popups and Popups:FindFirstChild("RadioPanel")

local SCAN_INTERVAL = 0.2
local MAX_DISTANCE = 8

local ATTR_IN_MENU = "USARF_InMenu"
local ATTR_LOADING_COMPLETE = "USARF_LoadingComplete"
local ATTR_MEDKIT_EQUIPPED = "USARF_MedkitEquipped"

local selectedDoor = nil
local cooldown = false

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorInteractionUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false
screenGui.DisplayOrder = 75
screenGui.Parent = PlayerGui

local uiScale = Instance.new("UIScale")
uiScale.Parent = screenGui

local container = Instance.new("Frame")
container.Name = "Container"
container.AnchorPoint = Vector2.new(0.5, 1)
container.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
container.BackgroundTransparency = 0.08
container.BorderSizePixel = 0
container.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = container

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 70, 80)
stroke.Thickness = 1
stroke.Transparency = 0.25
stroke.Parent = container

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 14, 0, 8)
title.Size = UDim2.new(1, -28, 0, 20)
title.Font = Enum.Font.GothamBold
title.Text = "DOOR ACCESS"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = container

local status = Instance.new("TextLabel")
status.Name = "Status"
status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 14, 0, 30)
status.Size = UDim2.new(1, -28, 0, 20)
status.Font = Enum.Font.Gotham
status.Text = "AWAITING INPUT"
status.TextColor3 = Color3.fromRGB(210, 210, 215)
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = container

local openHint = Instance.new("TextButton")
openHint.Name = "OpenHint"
openHint.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
openHint.BorderSizePixel = 0
openHint.Position = UDim2.new(0, 14, 0, 54)
openHint.Size = UDim2.new(0, 132, 0, 26)
openHint.Font = Enum.Font.GothamBold
openHint.Text = isMobile and "OPEN" or "[E] OPEN"
openHint.TextColor3 = Color3.fromRGB(255, 255, 255)
openHint.TextSize = 11
openHint.AutoButtonColor = true
openHint.Parent = container

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 6)
openCorner.Parent = openHint

local lockHint = Instance.new("TextButton")
lockHint.Name = "LockHint"
lockHint.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
lockHint.BorderSizePixel = 0
lockHint.Position = UDim2.new(0, 158, 0, 54)
lockHint.Size = UDim2.new(0, 132, 0, 26)
lockHint.Font = Enum.Font.GothamBold
lockHint.Text = isMobile and "LOCK" or "[L] LOCK"
lockHint.TextColor3 = Color3.fromRGB(255, 255, 255)
lockHint.TextSize = 11
lockHint.AutoButtonColor = true
lockHint.Parent = container

local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(0, 6)
lockCorner.Parent = lockHint

local function waitForLoadingComplete()
	if player:GetAttribute(ATTR_LOADING_COMPLETE) == true then
		return
	end

	local clientSignalsFolder = USARF:FindFirstChild("ClientSignals")
	local loadingCompleteEvent = clientSignalsFolder and clientSignalsFolder:FindFirstChild("LoadingComplete")

	if loadingCompleteEvent and loadingCompleteEvent:IsA("BindableEvent") then
		loadingCompleteEvent.Event:Wait()
	else
		local startTime = os.clock()

		while player:GetAttribute(ATTR_LOADING_COMPLETE) ~= true and os.clock() - startTime < 15 do
			task.wait(0.1)
		end
	end
end

local function getScale()
	local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)

	if isMobile then
		return 1
	end

	if viewport.X < 1000 then
		return 0.78
	elseif viewport.X < 1200 then
		return 0.88
	end

	return 1
end

local function isRadioOpen()
	return RadioPanel and RadioPanel.Visible == true
end

local function applyLayout()
	local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)

	uiScale.Scale = getScale()

	if isMobile then
		container.Size = UDim2.new(0, 250, 0, 72)
		container.Position = UDim2.new(0.5, 0, 1, -92)

		title.Position = UDim2.new(0, 12, 0, 6)
		title.Size = UDim2.new(1, -24, 0, 18)
		title.TextSize = 11

		status.Position = UDim2.new(0, 12, 0, 25)
		status.Size = UDim2.new(1, -24, 0, 16)
		status.TextSize = 10

		openHint.Position = UDim2.new(0, 12, 1, -28)
		openHint.Size = UDim2.new(0.5, -16, 0, 22)
		openHint.TextSize = 10

		lockHint.Position = UDim2.new(0.5, 4, 1, -28)
		lockHint.Size = UDim2.new(0.5, -16, 0, 22)
		lockHint.TextSize = 10

		return
	end

	container.Size = UDim2.new(0, 310, 0, 84)

	if isRadioOpen() then
		if viewport.X < 1350 then
			container.Position = UDim2.new(0.43, 0, 1, -100)
		else
			container.Position = UDim2.new(0.5, -130, 1, -100)
		end
	else
		container.Position = UDim2.new(0.5, 0, 1, -100)
	end
end

local function isInMenuOrLoading()
	if player:GetAttribute(ATTR_LOADING_COMPLETE) ~= true then
		return true
	end

	if player:GetAttribute(ATTR_IN_MENU) ~= false then
		return true
	end

	if player:GetAttribute(ATTR_MEDKIT_EQUIPPED) == true then
		return true
	end

	return false
end

local function setStatus(text, color)
	status.Text = text
	status.TextColor3 = color or Color3.fromRGB(210, 210, 215)
end

local function setUiVisible(visible)
	if isInMenuOrLoading() then
		screenGui.Enabled = false
		return
	end

	screenGui.Enabled = visible == true
end

local function getRoot()
	if isInMenuOrLoading() then
		return nil
	end

	local character = player.Character

	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getDoorPoint(door)
	local point = door:FindFirstChild("Point", true)

	if point and point:IsA("BasePart") then
		return point
	end

	local moving = door:FindFirstChild("Moving")

	if moving and moving:IsA("Model") then
		if moving.PrimaryPart then
			return moving.PrimaryPart
		end

		local movingPart = moving:FindFirstChildWhichIsA("BasePart", true)

		if movingPart then
			return movingPart
		end
	end

	local doorPart = door:FindFirstChild("Door", true)

	if doorPart and doorPart:IsA("BasePart") then
		return doorPart
	end

	local door1 = door:FindFirstChild("Door1", true)

	if door1 and door1:IsA("BasePart") then
		return door1
	end

	return door.PrimaryPart
end

local function getAllDoors()
	local results = {}

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("ModuleScript") and descendant.Name == "DoorSettings" then
			table.insert(results, descendant.Parent)
		end
	end

	return results
end

local function getClosestDoor()
	local root = getRoot()

	if not root then
		return nil
	end

	local closest = nil
	local closestDistance = MAX_DISTANCE

	for _, door in ipairs(getAllDoors()) do
		local point = getDoorPoint(door)

		if point then
			local distance = (root.Position - point.Position).Magnitude

			if distance < closestDistance then
				closestDistance = distance
				closest = door
			end
		end
	end

	return closest
end

local function requestDoorAction(actionName)
	if cooldown or not selectedDoor then
		return
	end

	if isInMenuOrLoading() then
		selectedDoor = nil
		setUiVisible(false)
		return
	end

	cooldown = true
	setStatus("PROCESSING REQUEST", Color3.fromRGB(255, 200, 0))
	DoorEvent:FireServer(selectedDoor, actionName)

	task.delay(1, function()
		cooldown = false
	end)
end

openHint.MouseButton1Click:Connect(function()
	requestDoorAction("ToggleOpen")
end)

lockHint.MouseButton1Click:Connect(function()
	requestDoorAction("ToggleLock")
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if isInMenuOrLoading() then
		selectedDoor = nil
		setUiVisible(false)
		return
	end

	if input.KeyCode == Enum.KeyCode.E then
		requestDoorAction("ToggleOpen")
	elseif input.KeyCode == Enum.KeyCode.L then
		requestDoorAction("ToggleLock")
	end
end)

DoorEvent.OnClientEvent:Connect(function(state)
	if isInMenuOrLoading() then
		return
	end

	if state == "idle" then
		setStatus("AWAITING INPUT", Color3.fromRGB(210, 210, 215))
	elseif state == "granted" then
		setStatus("ACCESS GRANTED", Color3.fromRGB(95, 220, 120))
	elseif state == "denied" then
		setStatus("ACCESS DENIED", Color3.fromRGB(220, 80, 80))
	end
end)

if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
		applyLayout()
	end
end)

if RadioPanel then
	RadioPanel:GetPropertyChangedSignal("Visible"):Connect(applyLayout)
end

player:GetAttributeChangedSignal(ATTR_IN_MENU):Connect(function()
	if isInMenuOrLoading() then
		selectedDoor = nil
		setUiVisible(false)
	end
end)

player:GetAttributeChangedSignal(ATTR_LOADING_COMPLETE):Connect(function()
	applyLayout()
end)

player:GetAttributeChangedSignal(ATTR_MEDKIT_EQUIPPED):Connect(function()
	if player:GetAttribute(ATTR_MEDKIT_EQUIPPED) == true then
		selectedDoor = nil
		setUiVisible(false)
	else
		applyLayout()
	end
end)

applyLayout()

task.spawn(function()
	waitForLoadingComplete()

	while true do
		applyLayout()

		if isInMenuOrLoading() then
			selectedDoor = nil
			setUiVisible(false)
		else
			selectedDoor = getClosestDoor()

			if selectedDoor then
				setUiVisible(true)

				local open = selectedDoor:GetAttribute("Open") == true
				local locked = selectedDoor:GetAttribute("Locked") == true

				if isMobile then
					openHint.Text = open and "CLOSE" or "OPEN"
					lockHint.Text = locked and "UNLOCK" or "LOCK"
				else
					openHint.Text = open and "[E] CLOSE" or "[E] OPEN"
					lockHint.Text = locked and "[L] UNLOCK" or "[L] LOCK"
				end
			else
				setUiVisible(false)
			end
		end

		task.wait(SCAN_INTERVAL)
	end
end)

print("[DoorClient] Loaded")