local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local REMOTE_NAME = "InitRemote"

local remote = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME):WaitForChild(REMOTE_NAME)
local CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient"))

local keyBinds = {}
local editorOpen = false
local screenGui = nil
local textBox = nil

local KEY_ALIASES = {
	pageup = Enum.KeyCode.PageUp,
	pagedown = Enum.KeyCode.PageDown,
	delete = Enum.KeyCode.Delete,
	home = Enum.KeyCode.Home,
	insert = Enum.KeyCode.Insert,
	["end"] = Enum.KeyCode.End,
}

local function trim(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeKeyName(value)
	value = string.lower(trim(value))
	value = value:gsub("%s+", "")

	if KEY_ALIASES[value] then
		return KEY_ALIASES[value]
	end

	for _, keyCode in ipairs(Enum.KeyCode:GetEnumItems()) do
		if string.lower(keyCode.Name) == value then
			return keyCode
		end
	end

	return nil
end

local function runCmdrCommand(commandText)
	commandText = trim(commandText)

	if commandText == "" then
		return
	end

	local success, result = pcall(function()
		if typeof(CmdrClient.Run) == "function" then
			CmdrClient:Run(commandText)
		elseif CmdrClient.Dispatcher and typeof(CmdrClient.Dispatcher.EvaluateAndRun) == "function" then
			CmdrClient.Dispatcher:EvaluateAndRun(commandText)
		end
	end)

	if not success then
		warn("[InitController] Failed to run Cmdr command:", commandText, result)
	end
end

local function clearBinds()
	table.clear(keyBinds)
end

local function bindKey(keyName, commandText)
	local keyCode = normalizeKeyName(keyName)

	if not keyCode then
		warn("[InitController] Invalid bind key:", keyName)
		return
	end

	keyBinds[keyCode] = trim(commandText)
end

local function parseAndRunInit(text, runImmediateCommands)
	clearBinds()

	for line in string.gmatch(tostring(text or ""), "[^\n]+") do
		line = trim(line)

		if line ~= "" and not string.match(line, "^%-%-") then
			local bindKeyName, bindCommand = string.match(line, "^bind%s+(%S+)%s+(.+)$")

			if bindKeyName and bindCommand then
				bindKey(bindKeyName, bindCommand)
			elseif runImmediateCommands == true then
				runCmdrCommand(line)
			end
		end
	end
end

local function anyBlockingGuiOpen()
	local usarfgui = playerGui:FindFirstChild("USARFGui")
	if not usarfgui then
		return false
	end

	local popups = usarfgui:FindFirstChild("Popups")
	if not popups then
		return false
	end

	for _, child in ipairs(popups:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible then
			if child.Name ~= "RadioPanel" then
				return true
			end
		end
	end

	return false
end

local function shouldIgnoreKeybind(gameProcessed)
	if editorOpen then
		return true
	end

	if UserInputService:GetFocusedTextBox() then
		return true
	end

	if anyBlockingGuiOpen() then
		return true
	end

	return false
end

local function createEditor()
	if screenGui then
		return
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "USARFInitEditor"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 999
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "EditorFrame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0, 620, 0, 390)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	frame.BackgroundTransparency = 0.06
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 120, 255)
	stroke.Transparency = 0.25
	stroke.Thickness = 1
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 18, 0, 12)
	title.Size = UDim2.new(1, -36, 0, 26)
	title.Font = Enum.Font.GothamBold
	title.Text = "INIT EDITOR"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.new(0, 18, 0, 38)
	subtitle.Size = UDim2.new(1, -36, 0, 22)
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = "Right-click anywhere to save and stop editing."
	subtitle.TextColor3 = Color3.fromRGB(180, 180, 190)
	subtitle.TextSize = 13
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = frame

	textBox = Instance.new("TextBox")
	textBox.Name = "InitTextBox"
	textBox.Position = UDim2.new(0, 18, 0, 70)
	textBox.Size = UDim2.new(1, -36, 1, -88)
	textBox.BackgroundColor3 = Color3.fromRGB(7, 7, 9)
	textBox.BackgroundTransparency = 0.05
	textBox.BorderSizePixel = 0
	textBox.ClearTextOnFocus = false
	textBox.MultiLine = true
	textBox.TextWrapped = false
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.TextYAlignment = Enum.TextYAlignment.Top
	textBox.Font = Enum.Font.Code
	textBox.TextSize = 15
	textBox.TextColor3 = Color3.fromRGB(235, 235, 235)
	textBox.PlaceholderText = "-- bind Home badges\n-- bind Delete modmode"
	textBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
	textBox.Parent = frame

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 8)
	boxCorner.Parent = textBox

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = textBox
end

local function openEditor(text)
	createEditor()

	editorOpen = true
	screenGui.Enabled = true
	textBox.Text = tostring(text or "")
	textBox:CaptureFocus()
end

local function closeEditor()
	if not screenGui or not textBox then
		return
	end

	local text = textBox.Text

	editorOpen = false
	screenGui.Enabled = false
	textBox:ReleaseFocus()

	remote:FireServer("SaveInit", text)
	parseAndRunInit(text, false)
end

remote.OnClientEvent:Connect(function(action, text)
	if action == "OpenEditor" then
		openEditor(text)
	elseif action == "RunInit" then
		parseAndRunInit(text, true)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if editorOpen then
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			closeEditor()
		end

		return
	end

	if shouldIgnoreKeybind(gameProcessed) then
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		local commandText = keyBinds[input.KeyCode]

		if commandText then
			runCmdrCommand(commandText)
		end
	end
end)

print("[InitController] Loaded")