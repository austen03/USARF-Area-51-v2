local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local ReturnToMenu = Remotes:WaitForChild("ReturnToMenu")

local Gui = PlayerGui:WaitForChild("USARFGui")
local TopBar = Gui:WaitForChild("TopBar")
local ReturnButton = TopBar:WaitForChild("ReturnToMenuButton")

local RETURN_DELAY = 7
local MOVE_CANCEL_THRESHOLD = 0.08

local isReturning = false
local cancelReturn = false
local movementConnection = nil

ReturnButton.AnchorPoint = Vector2.new(1, 0)
ReturnButton.Position = UDim2.new(1, -20, 0, 18)
ReturnButton.Size = UDim2.new(0, 90, 0, 32)
ReturnButton.Text = "Menu"
ReturnButton.TextSize = 24
ReturnButton.TextScaled = false
ReturnButton.TextWrapped = false

local movementKeys = {
	[Enum.KeyCode.W] = true,
	[Enum.KeyCode.A] = true,
	[Enum.KeyCode.S] = true,
	[Enum.KeyCode.D] = true,
	[Enum.KeyCode.Space] = true,
	[Enum.KeyCode.Up] = true,
	[Enum.KeyCode.Down] = true,
	[Enum.KeyCode.Left] = true,
	[Enum.KeyCode.Right] = true,
}

local function playMenuClick()
	if _G.USARFPlaySound then
		_G.USARFPlaySound("MenuClick", "MenuSounds")
	end
end

local function notify(title, message, duration)
	if _G.USARFNotify then
		_G.USARFNotify(title, message, duration or 4)
	end
end

local function isCuffed()
	return Player:GetAttribute("USARF_Cuffed") == true
		or Player:GetAttribute("Cuffed") == true
		or Player:GetAttribute("IsCuffed") == true
end

local function getHumanoid()
	local character = Player.Character

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getNewMainMenu()
	return PlayerGui:FindFirstChild("USARFMenu")
end

local function openNewMainMenu()
	local newMenu = getNewMainMenu()

	if _G.USARFOpenMainMenu then
		_G.USARFOpenMainMenu("Home")
		return
	end

	if newMenu then
		newMenu.Enabled = true
	end
end

local function updateMenuLabel(text)
	ReturnButton.Text = text

	if _G.USARFSetMenuTopbarLabel then
		_G.USARFSetMenuTopbarLabel(text)
	end
end

local function updateVisibility()
	local inMenu = Player:GetAttribute("USARF_InMenu")

	if inMenu == nil then
		inMenu = true
	end

	ReturnButton.Visible = inMenu == false

	if _G.USARFUpdateTopbarVisibility then
		_G.USARFUpdateTopbarVisibility()
	end
end

local function disconnectMovementWatcher()
	if movementConnection then
		movementConnection:Disconnect()
		movementConnection = nil
	end
end

local function startMovementWatcher()
	disconnectMovementWatcher()

	movementConnection = RunService.RenderStepped:Connect(function()
		if not isReturning then
			return
		end

		local humanoid = getHumanoid()

		if humanoid and humanoid.MoveDirection.Magnitude > MOVE_CANCEL_THRESHOLD then
			cancelReturn = true
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if isReturning and movementKeys[input.KeyCode] then
		cancelReturn = true
	end
end)

UserInputService.TouchMoved:Connect(function()
	if isReturning then
		local humanoid = getHumanoid()

		if humanoid and humanoid.MoveDirection.Magnitude > MOVE_CANCEL_THRESHOLD then
			cancelReturn = true
		end
	end
end)

local function invokeReturn(action)
	local success, result = pcall(function()
		return ReturnToMenu:InvokeServer(action)
	end)

	if not success then
		warn("[ReturnMenuController] Return failed:", result)
		return nil
	end

	return result
end

local function resetButton()
	disconnectMovementWatcher()

	updateMenuLabel("Menu")

	ReturnButton.Active = true
	ReturnButton.AutoButtonColor = true

	isReturning = false
	cancelReturn = false

	updateVisibility()
end

local function runCountdown()
	if isReturning then
		return
	end

	if Player:GetAttribute("USARF_InMenu") ~= false then
		updateVisibility()
		return
	end

	if isCuffed() then
		notify("Return Blocked", "You cannot return to menu while cuffed.", 4)
		resetButton()
		return
	end

	playMenuClick()

	isReturning = true
	cancelReturn = false

	ReturnButton.Active = false
	ReturnButton.AutoButtonColor = false

	startMovementWatcher()
	invokeReturn("start")

	for secondsLeft = RETURN_DELAY, 1, -1 do
		if isCuffed() then
			invokeReturn("cancel")
			notify("Return Cancelled", "You were cuffed.", 4)
			resetButton()
			return
		end

		if cancelReturn then
			invokeReturn("cancel")
			notify("Return Cancelled", "Movement detected.", 3)
			resetButton()
			return
		end

		updateMenuLabel(tostring(secondsLeft) .. "s")

		local elapsed = 0

		while elapsed < 1 do
			if isCuffed() then
				invokeReturn("cancel")
				notify("Return Cancelled", "You were cuffed.", 4)
				resetButton()
				return
			end

			if cancelReturn then
				invokeReturn("cancel")
				notify("Return Cancelled", "Movement detected.", 3)
				resetButton()
				return
			end

			task.wait(0.1)
			elapsed += 0.1
		end
	end

	local result = invokeReturn("complete")

	if result and result.success then
		Player:SetAttribute("USARF_InMenu", true)
		openNewMainMenu()
	else
		notify("Return Failed", result and result.message or "Unable to return to menu.", 4)
	end

	resetButton()
end

_G.USARFStartReturnToMenu = runCountdown

ReturnButton.MouseButton1Click:Connect(runCountdown)

Player:GetAttributeChangedSignal("USARF_InMenu"):Connect(updateVisibility)
Player:GetAttributeChangedSignal("USARF_Cuffed"):Connect(updateVisibility)
Player:GetAttributeChangedSignal("Cuffed"):Connect(updateVisibility)
Player:GetAttributeChangedSignal("IsCuffed"):Connect(updateVisibility)

Player.CharacterAdded:Connect(function()
	if isReturning then
		cancelReturn = true
	end
end)

resetButton()
updateVisibility()

print("USARF ReturnMenuController initialized")