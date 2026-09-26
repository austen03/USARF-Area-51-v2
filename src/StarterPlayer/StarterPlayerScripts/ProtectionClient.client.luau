local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local USARFFolder = ReplicatedStorage:WaitForChild("USARF")
local ConfigFolder = USARFFolder:WaitForChild("Config")
local RemotesFolder = USARFFolder:WaitForChild("Remotes")

local Config = require(ConfigFolder:WaitForChild("ProtectionConfig"))
local Remote = RemotesFolder:WaitForChild(Config.RemoteName)

local screenGui
local mainFrame
local uiScale
local trackerButton
local zonesButton
local trackerPage
local zonesPage
local vipListFrame
local zonesListFrame
local vipDropdown
local selectedVIPUserId
local dzBox
local kzBox
local noZoneAccessLabel

local trackerOpen = false
local currentTab = "Tracker"
local refreshThread = nil
local busy = false
local canManageZones = false
local lastVIPs = {}
local lastZones = {}

local BASE_WIDTH = 410
-- Kept compact so the radio HUD fits above it; both pages scroll.
local BASE_HEIGHT = 320
local RIGHT_PADDING = 24
local BOTTOM_PADDING = 24

-- Pixels from the bottom of the screen to the top of the open panel. RadioController reads
-- this to stack the radio above the panel instead of the two overlapping.
local PANEL_TOP_ATTRIBUTE = "USARF_ProtectionPanelTopOffset"

local function notify(message)
	if message == nil or message == "" then
		return
	end

	if _G.USARFNotify then
		_G.USARFNotify("Protection", message, 4, "Info", "Small")
	end
end

local function safeInvoke(action, data)
	local success, result = pcall(function()
		return Remote:InvokeServer(action, data or {})
	end)

	if not success then
		warn("[ProtectionClient] Remote failed:", result)
		return nil
	end

	return result
end

local function publishPanelTop()
	if trackerOpen and mainFrame then
		LocalPlayer:SetAttribute(PANEL_TOP_ATTRIBUTE, BOTTOM_PADDING + mainFrame.AbsoluteSize.Y)
	else
		LocalPlayer:SetAttribute(PANEL_TOP_ATTRIBUTE, nil)
	end
end

local function updateResponsiveLayout()
	if not mainFrame then
		return
	end

	local viewport = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
	local widthScale = viewport.X / 1920
	local heightScale = viewport.Y / 1080
	local scale = math.clamp(math.min(widthScale, heightScale), 0.72, 1)

	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Name = "ResponsiveScale"
		uiScale.Parent = mainFrame
	end

	uiScale.Scale = scale

	mainFrame.AnchorPoint = Vector2.new(1, 1)
	mainFrame.Position = UDim2.new(1, -RIGHT_PADDING, 1, -BOTTOM_PADDING)
	mainFrame.Size = UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT)
end

local function clearFrames(frame)
	if not frame then
		return
	end

	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function setTab(tabName)
	currentTab = tabName

	if trackerPage then
		trackerPage.Visible = tabName == "Tracker"
	end

	if zonesPage then
		zonesPage.Visible = tabName == "Zones"
	end

	if trackerButton then
		trackerButton.BackgroundColor3 = tabName == "Tracker" and Color3.fromRGB(255, 215, 90) or Color3.fromRGB(44, 44, 44)
		trackerButton.TextColor3 = tabName == "Tracker" and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(255, 255, 255)
	end

	if zonesButton then
		zonesButton.BackgroundColor3 = tabName == "Zones" and Color3.fromRGB(255, 215, 90) or Color3.fromRGB(44, 44, 44)
		zonesButton.TextColor3 = tabName == "Zones" and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(255, 255, 255)
	end
end

local function makeButton(parent, name, text, size, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 10
	button.AutoButtonColor = true
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button

	return button
end

local function makeTextBox(parent, name, placeholder, size, position)
	local box = Instance.new("TextBox")
	box.Name = name
	box.PlaceholderText = placeholder
	box.Text = ""
	box.Size = size
	box.Position = position
	box.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	box.BorderSizePixel = 0
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.ClearTextOnFocus = false
	box.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = box

	return box
end

local function addVIPRow(vip)
	local row = Instance.new("Frame")
	row.Name = "VIP_" .. tostring(vip.UserId)
	row.Size = UDim2.new(1, -8, 0, 42)
	row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	row.BorderSizePixel = 0
	row.Parent = vipListFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = row

	local accent = Instance.new("Frame")
	accent.Position = UDim2.fromOffset(8, 8)
	accent.Size = UDim2.fromOffset(4, 26)
	accent.BackgroundColor3 = Color3.fromRGB(255, 215, 100)
	accent.BorderSizePixel = 0
	accent.Parent = row

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(20, 5)
	title.Size = UDim2.new(1, -34, 0, 18)
	title.BackgroundTransparency = 1
	title.Text = tostring(vip.Label or "VIP") .. " | " .. tostring(vip.LocationName or "Unknown Location")
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.Parent = row

	local subtitle = Instance.new("TextLabel")
	subtitle.Position = UDim2.fromOffset(20, 23)
	subtitle.Size = UDim2.new(1, -34, 0, 15)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = tostring(vip.Name or "Unknown") .. " • " .. tostring(vip.TeamName or "No Team")
	subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 10
	subtitle.Parent = row
end

local function addZoneRow(zone)
	local row = Instance.new("Frame")
	row.Name = "Zone_" .. tostring(zone.VIPUserId) .. "_" .. tostring(zone.ZoneType)
	row.Size = UDim2.new(1, -8, 0, 42)
	row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	row.BorderSizePixel = 0
	row.Parent = zonesListFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = row

	local accent = Instance.new("Frame")
	accent.Position = UDim2.fromOffset(8, 8)
	accent.Size = UDim2.fromOffset(4, 26)
	accent.BackgroundColor3 = zone.ZoneType == "KZ" and Color3.fromRGB(255, 45, 45) or Color3.fromRGB(255, 165, 40)
	accent.BorderSizePixel = 0
	accent.Parent = row

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(20, 5)
	title.Size = UDim2.new(1, -34, 0, 18)
	title.BackgroundTransparency = 1
	title.Text = tostring(zone.ZoneType) .. " | " .. tostring(zone.VIPLabel)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.Parent = row

	local subtitle = Instance.new("TextLabel")
	subtitle.Position = UDim2.fromOffset(20, 23)
	subtitle.Size = UDim2.new(1, -34, 0, 15)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = tostring(zone.VIPName) .. " • Radius " .. tostring(zone.Radius)
	subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 10
	subtitle.Parent = row
end

local function updateVIPDropdown(vips)
	if not vipDropdown then
		return
	end

	local selectedStillExists = false

	for _, vip in ipairs(vips or {}) do
		if selectedVIPUserId == vip.UserId then
			selectedStillExists = true
			break
		end
	end

	if not selectedStillExists then
		selectedVIPUserId = nil
	end

	if not selectedVIPUserId and vips and #vips > 0 then
		selectedVIPUserId = vips[1].UserId
	end

	if not selectedVIPUserId then
		vipDropdown.Text = "No VIP Available"
		return
	end

	for _, vip in ipairs(vips or {}) do
		if vip.UserId == selectedVIPUserId then
			vipDropdown.Text = tostring(vip.Label) .. " | " .. tostring(vip.Name)
			return
		end
	end
end

local function cycleSelectedVIP()
	if not lastVIPs or #lastVIPs == 0 then
		selectedVIPUserId = nil
		updateVIPDropdown(lastVIPs)
		return
	end

	local currentIndex = 0

	for index, vip in ipairs(lastVIPs) do
		if vip.UserId == selectedVIPUserId then
			currentIndex = index
			break
		end
	end

	local nextIndex = currentIndex + 1
	if nextIndex > #lastVIPs then
		nextIndex = 1
	end

	selectedVIPUserId = lastVIPs[nextIndex].UserId
	updateVIPDropdown(lastVIPs)
end

local function updateTracker(vips)
	clearFrames(vipListFrame)

	if not vips or #vips == 0 then
		local empty = Instance.new("TextLabel")
		empty.Name = "Empty"
		empty.Size = UDim2.new(1, -8, 0, 42)
		empty.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
		empty.BorderSizePixel = 0
		empty.Text = "No active VIPs detected."
		empty.TextColor3 = Color3.fromRGB(170, 170, 170)
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 11
		empty.Parent = vipListFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = empty

		return
	end

	for _, vip in ipairs(vips) do
		addVIPRow(vip)
	end
end

local function updateZones(zones)
	clearFrames(zonesListFrame)

	if not zones or #zones == 0 then
		local empty = Instance.new("TextLabel")
		empty.Name = "Empty"
		empty.Size = UDim2.new(1, -8, 0, 42)
		empty.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
		empty.BorderSizePixel = 0
		empty.Text = "No active protection zones."
		empty.TextColor3 = Color3.fromRGB(170, 170, 170)
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 11
		empty.Parent = zonesListFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = empty

		return
	end

	for _, zone in ipairs(zones) do
		addZoneRow(zone)
	end
end

local function applyPayload(result)
	lastVIPs = result.VIPs or {}
	lastZones = result.Zones or {}
	canManageZones = result.CanManageZones == true

	updateTracker(lastVIPs)
	updateZones(lastZones)
	updateVIPDropdown(lastVIPs)

	if noZoneAccessLabel then
		noZoneAccessLabel.Visible = not canManageZones
	end
end

local function createGui()
	if screenGui then
		return
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "USARF_ProtectionSystem"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 9998
	screenGui.Enabled = false
	screenGui.Parent = PlayerGui

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "Main"
	mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 14)
	mainCorner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(176, 176, 176)
	stroke.Transparency = 0.68
	stroke.Thickness = 1
	stroke.Parent = mainFrame

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 58)
	header.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 14)
	headerCorner.Parent = header

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(16, 7)
	title.Size = UDim2.new(1, -32, 0, 26)
	title.BackgroundTransparency = 1
	title.Text = "PROTECTION SYSTEM"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Position = UDim2.fromOffset(16, 32)
	subtitle.Size = UDim2.new(1, -32, 0, 18)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Y to close | VIP monitoring and zone management"
	subtitle.TextColor3 = Color3.fromRGB(190, 190, 190)
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 10
	subtitle.Parent = header

	local tabFrame = Instance.new("Frame")
	tabFrame.Name = "Tabs"
	tabFrame.Position = UDim2.fromOffset(14, 70)
	tabFrame.Size = UDim2.new(1, -28, 0, 34)
	tabFrame.BackgroundTransparency = 1
	tabFrame.Parent = mainFrame

	trackerButton = makeButton(tabFrame, "TrackerTab", "TRACKER", UDim2.new(0.5, -4, 1, 0), UDim2.fromOffset(0, 0))
	zonesButton = makeButton(tabFrame, "ZonesTab", "ZONES", UDim2.new(0.5, -4, 1, 0), UDim2.new(0.5, 4, 0, 0))

	trackerPage = Instance.new("Frame")
	trackerPage.Name = "TrackerPage"
	trackerPage.Position = UDim2.fromOffset(14, 116)
	trackerPage.Size = UDim2.new(1, -28, 1, -130)
	trackerPage.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	trackerPage.BorderSizePixel = 0
	trackerPage.Parent = mainFrame

	local trackerCorner = Instance.new("UICorner")
	trackerCorner.CornerRadius = UDim.new(0, 12)
	trackerCorner.Parent = trackerPage

	vipListFrame = Instance.new("ScrollingFrame")
	vipListFrame.Name = "VIPList"
	vipListFrame.Position = UDim2.fromOffset(8, 8)
	vipListFrame.Size = UDim2.new(1, -16, 1, -16)
	vipListFrame.BackgroundTransparency = 1
	vipListFrame.BorderSizePixel = 0
	vipListFrame.ScrollBarThickness = 5
	vipListFrame.CanvasSize = UDim2.fromOffset(0, 0)
	vipListFrame.Parent = trackerPage

	local vipLayout = Instance.new("UIListLayout")
	vipLayout.Padding = UDim.new(0, 7)
	vipLayout.SortOrder = Enum.SortOrder.LayoutOrder
	vipLayout.Parent = vipListFrame

	vipLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		vipListFrame.CanvasSize = UDim2.fromOffset(0, vipLayout.AbsoluteContentSize.Y + 12)
	end)

	-- The whole Zones page scrolls (controls + zone list) so it still works in the compact panel.
	zonesPage = Instance.new("ScrollingFrame")
	zonesPage.Name = "ZonesPage"
	zonesPage.Position = UDim2.fromOffset(14, 116)
	zonesPage.Size = UDim2.new(1, -28, 1, -130)
	zonesPage.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	zonesPage.BorderSizePixel = 0
	zonesPage.ScrollBarThickness = 5
	zonesPage.ScrollingDirection = Enum.ScrollingDirection.Y
	zonesPage.CanvasSize = UDim2.fromOffset(0, 0)
	zonesPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
	zonesPage.Visible = false
	zonesPage.Parent = mainFrame

	local zonesCorner = Instance.new("UICorner")
	zonesCorner.CornerRadius = UDim.new(0, 12)
	zonesCorner.Parent = zonesPage

	vipDropdown = makeButton(zonesPage, "VIPDropdown", "No VIP Available", UDim2.new(1, -16, 0, 32), UDim2.fromOffset(8, 8))

	dzBox = makeTextBox(zonesPage, "DZRadius", "DZ Radius", UDim2.new(0.5, -12, 0, 32), UDim2.fromOffset(8, 48))
	kzBox = makeTextBox(zonesPage, "KZRadius", "KZ Radius", UDim2.new(0.5, -12, 0, 32), UDim2.new(0.5, 4, 0, 48))

	dzBox.Text = "25"
	kzBox.Text = "10"

	local createDZ = makeButton(zonesPage, "CreateDZ", "CREATE DZ", UDim2.new(0.5, -12, 0, 32), UDim2.fromOffset(8, 88))
	local removeDZ = makeButton(zonesPage, "RemoveDZ", "REMOVE DZ", UDim2.new(0.5, -12, 0, 32), UDim2.new(0.5, 4, 0, 88))
	local createKZ = makeButton(zonesPage, "CreateKZ", "CREATE KZ", UDim2.new(0.5, -12, 0, 32), UDim2.fromOffset(8, 128))
	local removeKZ = makeButton(zonesPage, "RemoveKZ", "REMOVE KZ", UDim2.new(0.5, -12, 0, 32), UDim2.new(0.5, 4, 0, 128))

	noZoneAccessLabel = Instance.new("TextLabel")
	noZoneAccessLabel.Name = "NoZoneAccess"
	noZoneAccessLabel.Position = UDim2.fromOffset(8, 166)
	noZoneAccessLabel.Size = UDim2.new(1, -16, 0, 24)
	noZoneAccessLabel.BackgroundTransparency = 1
	noZoneAccessLabel.Text = "Zone management restricted."
	noZoneAccessLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	noZoneAccessLabel.Font = Enum.Font.GothamBold
	noZoneAccessLabel.TextSize = 11
	noZoneAccessLabel.Visible = false
	noZoneAccessLabel.Parent = zonesPage

	-- Grows with its rows; ZonesPage does the scrolling.
	zonesListFrame = Instance.new("Frame")
	zonesListFrame.Name = "ZonesList"
	zonesListFrame.Position = UDim2.fromOffset(8, 196)
	zonesListFrame.Size = UDim2.new(1, -16, 0, 0)
	zonesListFrame.AutomaticSize = Enum.AutomaticSize.Y
	zonesListFrame.BackgroundTransparency = 1
	zonesListFrame.BorderSizePixel = 0
	zonesListFrame.Parent = zonesPage

	local zonesLayout = Instance.new("UIListLayout")
	zonesLayout.Padding = UDim.new(0, 7)
	zonesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	zonesLayout.Parent = zonesListFrame

	local zonesPadding = Instance.new("UIPadding")
	zonesPadding.PaddingBottom = UDim.new(0, 12)
	zonesPadding.Parent = zonesListFrame

	trackerButton.MouseButton1Click:Connect(function()
		setTab("Tracker")
	end)

	zonesButton.MouseButton1Click:Connect(function()
		setTab("Zones")
	end)

	vipDropdown.MouseButton1Click:Connect(cycleSelectedVIP)

	local function zoneAction(action, zoneType, radius)
		if not canManageZones then
			notify("Zone management restricted.")
			return
		end

		if not selectedVIPUserId then
			notify("No VIP selected.")
			return
		end

		local result = safeInvoke(action, {
			VIPUserId = selectedVIPUserId,
			ZoneType = zoneType,
			Radius = radius,
		})

		if result then
			if result.Message then
				notify(result.Message)
			end

			if result.Success then
				applyPayload(result)
			end
		end
	end

	createDZ.MouseButton1Click:Connect(function()
		zoneAction("CreateZone", "DZ", dzBox.Text)
	end)

	removeDZ.MouseButton1Click:Connect(function()
		zoneAction("RemoveZone", "DZ", dzBox.Text)
	end)

	createKZ.MouseButton1Click:Connect(function()
		zoneAction("CreateZone", "KZ", kzBox.Text)
	end)

	removeKZ.MouseButton1Click:Connect(function()
		zoneAction("RemoveZone", "KZ", kzBox.Text)
	end)

	-- The panel's on-screen height changes with the responsive UIScale.
	mainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(publishPanelTop)

	setTab("Tracker")
	updateResponsiveLayout()
end

local function requestTrackerData()
	if busy or not trackerOpen then
		return
	end

	busy = true

	local result = safeInvoke("GetTrackerData")

	if result and result.Success then
		applyPayload(result)
	elseif result and result.Message then
		notify(result.Message)
	end

	busy = false
end

local function startRefreshLoop()
	if refreshThread then
		return
	end

	refreshThread = task.spawn(function()
		while trackerOpen do
			requestTrackerData()
			task.wait(Config.RefreshSeconds or 1.5)
		end

		refreshThread = nil
	end)
end

local function openTracker(result)
	createGui()

	trackerOpen = true
	screenGui.Enabled = true
	LocalPlayer:SetAttribute("USARF_ProtectionSystemOpen", true)

	applyPayload(result or {
		VIPs = {},
		Zones = {},
		CanManageZones = false,
	})

	updateResponsiveLayout()
	publishPanelTop()
	startRefreshLoop()
end

local function closeTracker()
	trackerOpen = false
	LocalPlayer:SetAttribute("USARF_ProtectionSystemOpen", false)
	publishPanelTop()

	if screenGui then
		screenGui.Enabled = false
	end
end

local function toggleTracker()
	local result = safeInvoke("ToggleTracker")

	if not result then
		return
	end

	if not result.Success then
		return
	end

	if result.Message then
		notify(result.Message)
	end

	if result.TrackerEnabled then
		openTracker(result)
	else
		closeTracker()
	end
end

local function trackerAction(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		toggleTracker()
	end

	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction(
	"USARF_ToggleProtectionSystem",
	trackerAction,
	false,
	Config.ToggleKey or Enum.KeyCode.Y
)

if Camera then
	Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveLayout)
end

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
	closeTracker()
end)

LocalPlayer.CharacterAdded:Connect(function()
	closeTracker()
end)

createGui()

print("[ProtectionClient] Loaded.")