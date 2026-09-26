local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local REMOTE_ROOT_NAME = "USARF"
local REMOTE_FOLDER_NAME = "Remotes"
local LOADING_FOLDER_NAME = "Loading"
local REQUEST_PROFILE_REMOTE_NAME = "RequestLoadingProfile"

local CLIENT_SIGNALS_FOLDER_NAME = "ClientSignals"
local LOADING_COMPLETE_EVENT_NAME = "LoadingComplete"

local SCREEN_GUI_NAME = "USARF_LoadingUI"

local HAS_PLAYED_LOADING_ATTRIBUTE = "USARF_LoadingPlayed"
local LOADING_COMPLETE_ATTRIBUTE = "USARF_LoadingComplete"

local TYPE_SPEED = 0.025
local LINE_DELAY = 0.18
local BOOT_HOLD_TIME = 0.75
local FADE_TIME = 0.65

local BACKGROUND_COLOR = Color3.fromRGB(6, 8, 10)
local PANEL_COLOR = Color3.fromRGB(12, 16, 20)
local BORDER_COLOR = Color3.fromRGB(85, 255, 160)
local TEXT_COLOR = Color3.fromRGB(210, 255, 225)
local DIM_TEXT_COLOR = Color3.fromRGB(130, 170, 145)
local WARNING_COLOR = Color3.fromRGB(255, 195, 80)
local DANGER_COLOR = Color3.fromRGB(255, 95, 95)

local loadingProfile = nil
local gui = nil
local mainFrame = nil
local terminalText = nil
local headerLabel = nil
local subHeaderLabel = nil
local profileFrame = nil
local nameLabel = nil
local roleLabel = nil
local idLabel = nil
local statusLabel = nil

local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end

	return folder
end

local function getOrCreateBindableEvent(parent, name)
	local event = parent:FindFirstChild(name)

	if not event then
		event = Instance.new("BindableEvent")
		event.Name = name
		event.Parent = parent
	end

	return event
end

local function getLoadingCompleteEvent()
	local usarfFolder = getOrCreateFolder(ReplicatedStorage, REMOTE_ROOT_NAME)
	local clientSignalsFolder = getOrCreateFolder(usarfFolder, CLIENT_SIGNALS_FOLDER_NAME)

	return getOrCreateBindableEvent(clientSignalsFolder, LOADING_COMPLETE_EVENT_NAME)
end

local function fireLoadingComplete()
	player:SetAttribute(LOADING_COMPLETE_ATTRIBUTE, true)
end

local function waitForRemote()
	local usarfFolder = ReplicatedStorage:WaitForChild(REMOTE_ROOT_NAME)
	local remotesFolder = usarfFolder:WaitForChild(REMOTE_FOLDER_NAME)
	local loadingFolder = remotesFolder:WaitForChild(LOADING_FOLDER_NAME)

	return loadingFolder:WaitForChild(REQUEST_PROFILE_REMOTE_NAME)
end

local function safeDisableCoreGui()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
	end)

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)
end

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent

	return corner
end

local function createStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.Parent = parent

	return stroke
end

local function createPadding(parent, left, right, top, bottom)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left)
	padding.PaddingRight = UDim.new(0, right)
	padding.PaddingTop = UDim.new(0, top)
	padding.PaddingBottom = UDim.new(0, bottom)
	padding.Parent = parent

	return padding
end

local function makeLabel(parent, name, text, size, color, font, alignment)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Text = text or ""
	label.TextColor3 = color or TEXT_COLOR
	label.TextSize = size or 18
	label.Font = font or Enum.Font.Code
	label.TextXAlignment = alignment or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Parent = parent

	return label
end

local function createGui()
	local oldGui = playerGui:FindFirstChild(SCREEN_GUI_NAME)

	if oldGui then
		oldGui:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = SCREEN_GUI_NAME
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999999
	gui.Parent = playerGui

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.BackgroundColor3 = BACKGROUND_COLOR
	background.BorderSizePixel = 0
	background.Size = UDim2.fromScale(1, 1)
	background.Parent = gui

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "Terminal"
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.fromScale(0.5, 0.5)

	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize

	if viewport and viewport.X < 1000 then
		mainFrame.Size = UDim2.new(0.92, 0, 0.72, 0)
	else
		mainFrame.Size = UDim2.fromScale(0.62, 0.62)
	end
	mainFrame.BackgroundColor3 = PANEL_COLOR
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = background

	createCorner(mainFrame, 10)
	createStroke(mainFrame, BORDER_COLOR, 1, 0.15)
	createPadding(mainFrame, 24, 24, 20, 20)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = mainFrame

	local mobile = viewport and viewport.X < 1000

	headerLabel = makeLabel(
		mainFrame,
		"Header",
		"USARF SECURE NETWORK",
		mobile and 20 or 28,
		TEXT_COLOR, Enum.Font.Code, Enum.TextXAlignment.Left)
	headerLabel.Size = UDim2.new(1, 0, 0, 36)
	headerLabel.LayoutOrder = 1

	subHeaderLabel = makeLabel(mainFrame, "SubHeader", "AREA-51 PERSONNEL VERIFICATION TERMINAL", mobile and 11 or 15, DIM_TEXT_COLOR, Enum.Font.Code, Enum.TextXAlignment.Left)
	subHeaderLabel.Size = UDim2.new(1, 0, 0, 24)
	subHeaderLabel.LayoutOrder = 2

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.BackgroundColor3 = BORDER_COLOR
	divider.BackgroundTransparency = 0.25
	divider.BorderSizePixel = 0
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.LayoutOrder = 3
	divider.Parent = mainFrame

	terminalText = makeLabel(mainFrame, "TerminalText", "", mobile and 12 or 16, TEXT_COLOR, Enum.Font.Code, Enum.TextXAlignment.Left)
	terminalText.Size = UDim2.new(1, 0, 0, 220)
	terminalText.TextYAlignment = Enum.TextYAlignment.Top
	terminalText.LayoutOrder = 4

	profileFrame = Instance.new("Frame")
	profileFrame.Name = "ProfileFrame"
	profileFrame.BackgroundColor3 = Color3.fromRGB(8, 12, 14)
	profileFrame.BorderSizePixel = 0
	profileFrame.Size = UDim2.new(1, 0, 0, 132)
	profileFrame.LayoutOrder = 5
	profileFrame.Visible = false
	profileFrame.Parent = mainFrame

	createCorner(profileFrame, 8)
	createStroke(profileFrame, BORDER_COLOR, 1, 0.35)
	createPadding(profileFrame, 16, 16, 12, 12)

	local profileLayout = Instance.new("UIListLayout")
	profileLayout.FillDirection = Enum.FillDirection.Vertical
	profileLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	profileLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	profileLayout.Padding = UDim.new(0, 6)
	profileLayout.SortOrder = Enum.SortOrder.LayoutOrder
	profileLayout.Parent = profileFrame

	nameLabel = makeLabel(profileFrame, "Name", "", 18, TEXT_COLOR, Enum.Font.Code, Enum.TextXAlignment.Left)
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.LayoutOrder = 1

	roleLabel = makeLabel(profileFrame, "Role", "", 16, DIM_TEXT_COLOR, Enum.Font.Code, Enum.TextXAlignment.Left)
	roleLabel.Size = UDim2.new(1, 0, 0, 22)
	roleLabel.LayoutOrder = 2

	idLabel = makeLabel(profileFrame, "Identifier", "", 18, WARNING_COLOR, Enum.Font.Code, Enum.TextXAlignment.Left)
	idLabel.Size = UDim2.new(1, 0, 0, 24)
	idLabel.LayoutOrder = 3

	statusLabel = makeLabel(profileFrame, "Status", "", 16, TEXT_COLOR, Enum.Font.Code, Enum.TextXAlignment.Left)
	statusLabel.Size = UDim2.new(1, 0, 0, 22)
	statusLabel.LayoutOrder = 4
end

local function appendLine(line)
	terminalText.Text = terminalText.Text .. line .. "\n"
end

local function typeLine(line)
	for i = 1, #line do
		terminalText.Text = terminalText.Text .. string.sub(line, i, i)
		task.wait(TYPE_SPEED)
	end

	terminalText.Text = terminalText.Text .. "\n"
	task.wait(LINE_DELAY)
end

local function setProfileVisible(profile)
	nameLabel.Text = "NAME: " .. tostring(profile.username or player.Name)
	roleLabel.Text = "ROLE: " .. tostring(profile.displayRole or "Personnel")
	idLabel.Text = "IDENTIFIER: " .. tostring(profile.identifier or "SC-0")
	statusLabel.Text = "STATUS: " .. tostring(profile.status or "AUTHORIZED")

	if profile.profileType == "TestSubject" then
		idLabel.TextColor3 = DANGER_COLOR
		statusLabel.TextColor3 = WARNING_COLOR
	elseif profile.profileType == "Contractor" then
		idLabel.TextColor3 = WARNING_COLOR
		statusLabel.TextColor3 = WARNING_COLOR
	else
		idLabel.TextColor3 = BORDER_COLOR
		statusLabel.TextColor3 = TEXT_COLOR
	end

	profileFrame.Visible = true
	profileFrame.BackgroundTransparency = 1

	for _, descendant in ipairs(profileFrame:GetDescendants()) do
		if descendant:IsA("TextLabel") then
			descendant.TextTransparency = 1
		elseif descendant:IsA("UIStroke") then
			descendant.Transparency = 1
		end
	end

	TweenService:Create(profileFrame, TweenInfo.new(0.35), {
		BackgroundTransparency = 0,
	}):Play()

	for _, descendant in ipairs(profileFrame:GetDescendants()) do
		if descendant:IsA("TextLabel") then
			TweenService:Create(descendant, TweenInfo.new(0.35), {
				TextTransparency = 0,
			}):Play()
		elseif descendant:IsA("UIStroke") then
			TweenService:Create(descendant, TweenInfo.new(0.35), {
				Transparency = 0.35,
			}):Play()
		end
	end
end

local function fadeOutAndDestroy()
	if not gui then
		return
	end

	local tweens = {}

	for _, object in ipairs(gui:GetDescendants()) do
		if object:IsA("Frame") then
			table.insert(tweens, TweenService:Create(object, TweenInfo.new(FADE_TIME), {
				BackgroundTransparency = 1,
			}))
		elseif object:IsA("TextLabel") then
			table.insert(tweens, TweenService:Create(object, TweenInfo.new(FADE_TIME), {
				TextTransparency = 1,
			}))
		elseif object:IsA("UIStroke") then
			table.insert(tweens, TweenService:Create(object, TweenInfo.new(FADE_TIME), {
				Transparency = 1,
			}))
		end
	end

	for _, tween in ipairs(tweens) do
		tween:Play()
	end

	task.wait(FADE_TIME + 0.1)

	if gui then
		gui:Destroy()
		gui = nil
	end
end

local function playBootSequence(profile)
	typeLine("[BOOT] Initializing secure interface...")
	typeLine("[OK] Encryption channel established.")
	typeLine("[OK] Facility network handshake accepted.")
	typeLine("[OK] Personnel registry connected.")
	typeLine("[SCAN] Verifying Roblox identity...")
	typeLine("[SCAN] Reading assigned team...")
	typeLine("[SCAN] Resolving clearance credentials...")

	appendLine("")

	if profile.profileType == "TestSubject" then
		typeLine("[NOTICE] Test Subject profile detected.")
		typeLine("[ASSIGN] Subject identifier generated.")
	elseif profile.profileType == "Contractor" then
		typeLine("[NOTICE] Contractor profile detected.")
		typeLine("[ASSIGN] Temporary access classification applied.")
	else
		typeLine("[NOTICE] Personnel profile detected.")
		typeLine("[ASSIGN] Security clearance resolved.")
	end

	appendLine("")
	typeLine("[OK] Verification complete.")
	typeLine("[LOAD] Preparing team selection interface...")

	setProfileVisible(profile)

	task.wait(BOOT_HOLD_TIME)
end

local function shouldShowLoading()
	if player:GetAttribute(HAS_PLAYED_LOADING_ATTRIBUTE) == true then
		return false
	end

	return true
end

local function markLoadingPlayed()
	player:SetAttribute(HAS_PLAYED_LOADING_ATTRIBUTE, true)
end

local function requestProfile()
	local remote = waitForRemote()

	local success, result = pcall(function()
		return remote:InvokeServer()
	end)

	if success and typeof(result) == "table" then
		return result
	end

	return {
		username = player.Name,
		displayName = player.DisplayName,
		userId = player.UserId,
		teamName = player.Team and player.Team.Name or "Loading",
		profileType = "Personnel",
		displayRole = "Personnel",
		identifier = "SC-0",
		clearanceLevel = 0,
		status = "AUTHORIZED",
	}
end

local function start()
	safeDisableCoreGui()

	if not shouldShowLoading() then
		fireLoadingComplete()
		return
	end

	markLoadingPlayed()

	loadingProfile = requestProfile()

	createGui()
	playBootSequence(loadingProfile)
	fadeOutAndDestroy()

	fireLoadingComplete()
end

task.defer(start)