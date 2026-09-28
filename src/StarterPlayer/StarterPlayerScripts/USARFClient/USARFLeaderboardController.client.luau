local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local REMOTE_NAME = "LeaderboardSync"

local TOGGLE_KEY = Enum.KeyCode.Tab

local ROW_HEIGHT = 26
local HEADER_HEIGHT = 22
local ICON_SIZE = 18
local BOARD_WIDTH = 260
local BOARD_MAX_HEIGHT = 500
local BOARD_POSITION = UDim2.new(1, -16, 0, 76)

local PANEL_WIDTH = 460
local PANEL_HEIGHT = 500

local MAIN_GROUP_ID = 6033326
local MOD_GROUP_ID = 8647541

local visible = true
local selectedPlayer = nil

local selectedSuspensionType = "Team"
local selectedDuration = "1d"
local selectedTargets = {}

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local remoteFolder = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME)
local remote = remoteFolder:WaitForChild(REMOTE_NAME)

local moderationFolder = remoteFolder:WaitForChild("Moderation")
local openCaseFunction = moderationFolder:WaitForChild("OpenCase")
local submitGameWarnEvent = moderationFolder:WaitForChild("SubmitGameWarn")
local submitTeamSuspensionEvent = moderationFolder:WaitForChild("SubmitTeamSuspension")
local submitGameBanEvent = moderationFolder:WaitForChild("SubmitGameBan")
local moderationNotifyEvent = moderationFolder:WaitForChild("ModerationNotify")

local TEAM_TARGETS = {
	"Facility Personnel",
	"Engineering & Technical",
	"Medical Division",
	"Research Division",
	"Rules & Regulations",
	"United States Air Force",
	"Department of Defense",
	"108th Infantry Regiment",
	"137th Military Police Company",
	"1st Spec. Ops. A.I.G",
	"Secret Service",
	"Central Intelligence Agency",
	"Federal Bureau of Investigation",
	"Federal Defense Service",
}

local AREA_TARGETS = {
	"Civil Departments",
	"Combative Departments",
	"Intelligence Departments",
	"Protection Departments",
}

local FACILITY_TARGETS = {
	"Entire Facility",
}

local DURATIONS = {
	"1h",
	"6h",
	"12h",
	"1d",
	"3d",
	"7d",
	"14d",
	"Permanent",
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "USARFLeaderboard"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 80
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(1, 0)
mainFrame.Position = BOARD_POSITION
mainFrame.Size = UDim2.new(0, BOARD_WIDTH, 0, BOARD_MAX_HEIGHT)
mainFrame.BackgroundTransparency = 1
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageTransparency = 0.25
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = scrollFrame

local actionMenu = Instance.new("Frame")
actionMenu.Name = "ActionMenu"
actionMenu.Size = UDim2.new(0, 170, 0, 156)
actionMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
actionMenu.BackgroundTransparency = 0.08
actionMenu.BorderSizePixel = 0
actionMenu.Visible = false
actionMenu.ZIndex = 200
actionMenu.Parent = screenGui

local casePanel = Instance.new("Frame")
casePanel.Name = "CasePanel"
casePanel.AnchorPoint = Vector2.new(0.5, 0.5)
casePanel.Position = UDim2.new(0.5, 0, 0.5, 0)
casePanel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
casePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
casePanel.BackgroundTransparency = 0.04
casePanel.BorderSizePixel = 0
casePanel.Visible = false
casePanel.ZIndex = 250
casePanel.Parent = screenGui

local function tableToColor3(colorTable)
	if type(colorTable) ~= "table" then
		return Color3.fromRGB(255, 255, 255)
	end

	return Color3.fromRGB(colorTable.r or 255, colorTable.g or 255, colorTable.b or 255)
end

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = transparency or 0.65
	stroke.Thickness = 1
	stroke.Parent = parent
	return stroke
end

createCorner(actionMenu, 8)
createStroke(actionMenu, 0.58)

createCorner(casePanel, 10)
createStroke(casePanel, 0.55)

local function isModerator()
	local mainRank = 0
	local modRank = 0

	pcall(function()
		mainRank = localPlayer:GetRankInGroup(MAIN_GROUP_ID)
	end)

	pcall(function()
		modRank = localPlayer:GetRankInGroup(MOD_GROUP_ID)
	end)

	return mainRank >= 18 or modRank >= 2
end

local function isMenuOpen()
	return localPlayer:GetAttribute("USARF_MenuOpen") == true
		or localPlayer:GetAttribute("USARF_InMenu") == true
		or localPlayer:GetAttribute("MenuOpen") == true
		or localPlayer:GetAttribute("InMenu") == true
end

local function isLoading()
	return localPlayer:GetAttribute("USARF_Loading") == true
		or localPlayer:GetAttribute("Loading") == true
		or localPlayer:GetAttribute("InLoading") == true
end

local function updateVisibility()
	mainFrame.Visible = visible and not isMenuOpen() and not isLoading()

	if not mainFrame.Visible then
		actionMenu.Visible = false
	end
end

local function clearBoard()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function clearPanel()
	for _, child in ipairs(casePanel:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end
end

local function createLabel(parent, text, size, position, textSize, bold)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize or 13
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.ZIndex = parent.ZIndex + 1
	label.Parent = parent

	return label
end

local function createButton(parent, text, size, position, callback)
	local button = Instance.new("TextButton")
	button.Name = text:gsub("%s+", "") .. "Button"
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 12
	button.ZIndex = parent.ZIndex + 1
	button.Parent = parent

	createCorner(button, 7)
	createStroke(button, 0.72)

	button.MouseButton1Click:Connect(function()
		if callback then
			callback(button)
		end
	end)

	return button
end

local function createSelectableButton(parent, text, size, position, selected, callback)
	local button = createButton(parent, text, size, position, callback)

	if selected then
		button.BackgroundColor3 = Color3.fromRGB(95, 85, 210)
		button.Font = Enum.Font.GothamBold
	else
		button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		button.Font = Enum.Font.GothamMedium
	end

	return button
end

local function createTextBox(parent, placeholder, size, position, multiLine)
	local box = Instance.new("TextBox")
	box.Size = size
	box.Position = position
	box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	box.BackgroundTransparency = 0.05
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.MultiLine = multiLine == true
	box.Font = Enum.Font.Gotham
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Color3.fromRGB(170, 170, 170)
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.TextSize = 12
	box.TextWrapped = true
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Top
	box.ZIndex = parent.ZIndex + 1
	box.Parent = parent

	createCorner(box, 7)
	createStroke(box, 0.72)

	return box
end

local function showSimpleNotice(title, message)
	clearPanel()
	casePanel.Size = UDim2.new(0, 360, 0, 220)
	casePanel.Visible = true

	createLabel(casePanel, title, UDim2.new(1, -40, 0, 30), UDim2.new(0, 18, 0, 14), 16, true)
	createLabel(casePanel, message, UDim2.new(1, -36, 0, 115), UDim2.new(0, 18, 0, 58), 13, false)

	createButton(casePanel, "Close", UDim2.new(0, 100, 0, 30), UDim2.new(1, -118, 1, -44), function()
		casePanel.Visible = false
		casePanel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
	end)
end

local function showOpenCase()
	if not selectedPlayer then
		return
	end

	actionMenu.Visible = false
	clearPanel()
	casePanel.Size = UDim2.new(0, 360, 0, 220)
	casePanel.Visible = true

	createLabel(casePanel, "Opening Case...", UDim2.new(1, -40, 0, 30), UDim2.new(0, 18, 0, 14), 16, true)
	createLabel(casePanel, "Requesting Discord moderation case for " .. selectedPlayer.name .. "...", UDim2.new(1, -36, 0, 100), UDim2.new(0, 18, 0, 58), 13, false)

	local success, data = pcall(function()
		return openCaseFunction:InvokeServer(selectedPlayer.userId)
	end)

	clearPanel()

	if not success or type(data) ~= "table" or data.success ~= true then
		createLabel(casePanel, "Case Failed", UDim2.new(1, -40, 0, 30), UDim2.new(0, 18, 0, 14), 16, true)
		createLabel(casePanel, "Unable to open a Discord moderation case.", UDim2.new(1, -36, 0, 100), UDim2.new(0, 18, 0, 58), 13, false)
	else
		createLabel(casePanel, "Case Opened", UDim2.new(1, -40, 0, 30), UDim2.new(0, 18, 0, 14), 16, true)
		createLabel(
			casePanel,
			"Case ID:\n" .. tostring(data.caseId or "Unknown") .. "\n\nA Discord moderation case has been requested.",
			UDim2.new(1, -36, 0, 120),
			UDim2.new(0, 18, 0, 58),
			13,
			false
		)
	end

	createButton(casePanel, "Close", UDim2.new(0, 100, 0, 30), UDim2.new(1, -118, 1, -44), function()
		casePanel.Visible = false
		casePanel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
	end)
end

local function showGameWarn()
	if not selectedPlayer then
		return
	end

	actionMenu.Visible = false
	clearPanel()
	casePanel.Size = UDim2.new(0, 390, 0, 300)
	casePanel.Visible = true

	createLabel(casePanel, "Game Warn: " .. selectedPlayer.name, UDim2.new(1, -40, 0, 28), UDim2.new(0, 18, 0, 14), 16, true)
	createLabel(casePanel, "Reason:", UDim2.new(1, -36, 0, 22), UDim2.new(0, 18, 0, 55), 13, true)

	local reasonBox = createTextBox(casePanel, "Enter warning reason...", UDim2.new(1, -36, 0, 135), UDim2.new(0, 18, 0, 82), true)

	createButton(casePanel, "Submit Warning", UDim2.new(0, 140, 0, 32), UDim2.new(0, 18, 1, -48), function()
		if reasonBox.Text == "" then
			return
		end

		submitGameWarnEvent:FireServer(selectedPlayer.userId, reasonBox.Text)
		casePanel.Visible = false
		casePanel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
	end)

	createButton(casePanel, "Cancel", UDim2.new(0, 100, 0, 32), UDim2.new(1, -118, 1, -48), function()
		casePanel.Visible = false
		casePanel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
	end)
end

local function getTargetsForSuspensionType()
	if selectedSuspensionType == "Team" then
		return TEAM_TARGETS
	elseif selectedSuspensionType == "Area" then
		return AREA_TARGETS
	elseif selectedSuspensionType == "Facility" then
		return FACILITY_TARGETS
	end

	return {}
end

local function resetSelectedTargets()
	selectedTargets = {}

	if selectedSuspensionType == "Facility" then
		selectedTargets["Entire Facility"] = true
	end
end

local function getSelectedTargetList()
	local list = {}

	for targetName, enabled in pairs(selectedTargets) do
		if enabled then
			table.insert(list, targetName)
		end
	end

	table.sort(list)
	return list
end

local function showTeamSuspension()
	if not selectedPlayer then
		return
	end

	actionMenu.Visible = false
	clearPanel()
	casePanel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
	casePanel.Visible = true

	selectedSuspensionType = "Team"
	selectedDuration = "1d"
	selectedTargets = {}

	local function redraw(reasonText)
		clearPanel()

		createLabel(casePanel, "Team Suspension: " .. selectedPlayer.name, UDim2.new(1, -40, 0, 28), UDim2.new(0, 18, 0, 14), 16, true)

		createLabel(casePanel, "Suspension Type", UDim2.new(1, -36, 0, 18), UDim2.new(0, 18, 0, 48), 12, true)

		local types = { "Team", "Area", "Facility" }

		for index, typeName in ipairs(types) do
			createSelectableButton(
				casePanel,
				typeName,
				UDim2.new(0, 120, 0, 28),
				UDim2.new(0, 18 + ((index - 1) * 130), 0, 70),
				selectedSuspensionType == typeName,
				function()
					selectedSuspensionType = typeName
					resetSelectedTargets()
					redraw(reasonText)
				end
			)
		end

		createLabel(casePanel, "Affected Targets", UDim2.new(1, -36, 0, 18), UDim2.new(0, 18, 0, 108), 12, true)

		local targetScroll = Instance.new("ScrollingFrame")
		targetScroll.Name = "TargetScroll"
		targetScroll.Position = UDim2.new(0, 18, 0, 130)
		targetScroll.Size = UDim2.new(1, -36, 0, 108)
		targetScroll.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
		targetScroll.BackgroundTransparency = 0.08
		targetScroll.BorderSizePixel = 0
		targetScroll.ScrollBarThickness = 3
		targetScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		targetScroll.ZIndex = casePanel.ZIndex + 1
		targetScroll.Parent = casePanel

		createCorner(targetScroll, 7)
		createStroke(targetScroll, 0.74)

		local targetLayout = Instance.new("UIGridLayout")
		targetLayout.CellSize = UDim2.new(0, 200, 0, 24)
		targetLayout.CellPadding = UDim2.new(0, 6, 0, 5)
		targetLayout.SortOrder = Enum.SortOrder.LayoutOrder
		targetLayout.Parent = targetScroll

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 6)
		padding.PaddingLeft = UDim.new(0, 6)
		padding.Parent = targetScroll

		local targets = getTargetsForSuspensionType()

		for index, targetName in ipairs(targets) do
			local isChecked = selectedTargets[targetName] == true

			local targetButton = Instance.new("TextButton")
			targetButton.Name = "Target_" .. targetName
			targetButton.BackgroundColor3 = isChecked and Color3.fromRGB(95, 85, 210) or Color3.fromRGB(35, 35, 35)
			targetButton.BackgroundTransparency = 0.05
			targetButton.BorderSizePixel = 0
			targetButton.Font = isChecked and Enum.Font.GothamBold or Enum.Font.Gotham
			targetButton.Text = (isChecked and "☑ " or "☐ ") .. targetName
			targetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			targetButton.TextSize = 11
			targetButton.TextXAlignment = Enum.TextXAlignment.Left
			targetButton.LayoutOrder = index
			targetButton.ZIndex = casePanel.ZIndex + 2
			targetButton.Parent = targetScroll

			createCorner(targetButton, 6)

			targetButton.MouseButton1Click:Connect(function()
				if selectedSuspensionType == "Facility" then
					selectedTargets = {
						["Entire Facility"] = true,
					}
				else
					selectedTargets[targetName] = not selectedTargets[targetName]
				end

				redraw(reasonText)
			end)
		end

		local rows = math.ceil(#targets / 2)
		targetScroll.CanvasSize = UDim2.new(0, 0, 0, rows * 29 + 12)

		createLabel(casePanel, "Duration", UDim2.new(1, -36, 0, 18), UDim2.new(0, 18, 0, 250), 12, true)

		for index, duration in ipairs(DURATIONS) do
			local row = math.floor((index - 1) / 4)
			local column = (index - 1) % 4

			createSelectableButton(
				casePanel,
				duration,
				UDim2.new(0, 96, 0, 26),
				UDim2.new(0, 18 + (column * 104), 0, 272 + (row * 31)),
				selectedDuration == duration,
				function()
					selectedDuration = duration
					redraw(reasonText)
				end
			)
		end

		createLabel(casePanel, "Reason", UDim2.new(1, -36, 0, 18), UDim2.new(0, 18, 0, 365), 12, true)

		local reasonBox = createTextBox(casePanel, "Enter suspension reason...", UDim2.new(1, -36, 0, 52), UDim2.new(0, 18, 0, 387), true)
		reasonBox.Text = reasonText or ""

		reasonBox:GetPropertyChangedSignal("Text"):Connect(function()
			reasonText = reasonBox.Text
		end)

		createButton(casePanel, "Create Suspension", UDim2.new(0, 150, 0, 32), UDim2.new(0, 18, 1, -48), function()
			local targetList = getSelectedTargetList()

			if #targetList <= 0 or reasonBox.Text == "" then
				return
			end

			submitTeamSuspensionEvent:FireServer(
				selectedPlayer.userId,
				selectedSuspensionType,
				targetList,
				selectedDuration,
				reasonBox.Text
			)

			casePanel.Visible = false
		end)

		createButton(casePanel, "Cancel", UDim2.new(0, 100, 0, 32), UDim2.new(1, -118, 1, -48), function()
			casePanel.Visible = false
		end)
	end

	redraw("")
end

local function showGameBan()
	if not selectedPlayer then
		return
	end

	actionMenu.Visible = false
	clearPanel()
	casePanel.Size = UDim2.new(0, 410, 0, 330)
	casePanel.Visible = true

	local selectedBanDuration = "Permanent"

	local function redraw(reasonText)
		clearPanel()

		createLabel(casePanel, "Game Ban: " .. selectedPlayer.name, UDim2.new(1, -40, 0, 28), UDim2.new(0, 18, 0, 14), 16, true)
		createLabel(casePanel, "Duration", UDim2.new(1, -36, 0, 18), UDim2.new(0, 18, 0, 52), 12, true)

		for index, duration in ipairs(DURATIONS) do
			local row = math.floor((index - 1) / 4)
			local column = (index - 1) % 4

			createSelectableButton(
				casePanel,
				duration,
				UDim2.new(0, 86, 0, 26),
				UDim2.new(0, 18 + (column * 94), 0, 75 + (row * 31)),
				selectedBanDuration == duration,
				function()
					selectedBanDuration = duration
					redraw(reasonText)
				end
			)
		end

		createLabel(casePanel, "Reason", UDim2.new(1, -36, 0, 18), UDim2.new(0, 18, 0, 152), 12, true)

		local reasonBox = createTextBox(casePanel, "Enter ban reason...", UDim2.new(1, -36, 0, 105), UDim2.new(0, 18, 0, 174), true)
		reasonBox.Text = reasonText or ""

		reasonBox:GetPropertyChangedSignal("Text"):Connect(function()
			reasonText = reasonBox.Text
		end)

		createButton(casePanel, "Submit Ban", UDim2.new(0, 120, 0, 32), UDim2.new(0, 18, 1, -44), function()
			if reasonBox.Text == "" then
				return
			end

			submitGameBanEvent:FireServer(selectedPlayer.userId, selectedBanDuration, reasonBox.Text)
			casePanel.Visible = false
			casePanel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
		end)

		createButton(casePanel, "Cancel", UDim2.new(0, 100, 0, 32), UDim2.new(1, -118, 1, -44), function()
			casePanel.Visible = false
			casePanel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
		end)
	end

	redraw("")
end

local function copyUsername()
	if not selectedPlayer then
		return
	end

	actionMenu.Visible = false
	clearPanel()
	casePanel.Size = UDim2.new(0, 360, 0, 190)
	casePanel.Visible = true

	createLabel(casePanel, "Copy Username", UDim2.new(1, -40, 0, 30), UDim2.new(0, 18, 0, 14), 16, true)
	createLabel(casePanel, "Select the text below and copy it manually.", UDim2.new(1, -36, 0, 30), UDim2.new(0, 18, 0, 52), 12, false)

	local usernameBox = createTextBox(casePanel, "", UDim2.new(1, -36, 0, 36), UDim2.new(0, 18, 0, 86), false)
	-- username is the real account name, even when the row shows a covert name.
	usernameBox.Text = selectedPlayer.username or selectedPlayer.name
	usernameBox.TextEditable = false
	usernameBox.TextXAlignment = Enum.TextXAlignment.Center
	usernameBox.TextYAlignment = Enum.TextYAlignment.Center

	createButton(casePanel, "Close", UDim2.new(0, 100, 0, 30), UDim2.new(1, -118, 1, -44), function()
		casePanel.Visible = false
		casePanel.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
	end)
end

local function rebuildActionMenu()
	for _, child in ipairs(actionMenu:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end

	local options = {
		{ text = "Open Case", callback = showOpenCase },
		{ text = "Game Warn", callback = showGameWarn },
		{ text = "Team Suspension", callback = showTeamSuspension },
		{ text = "Game Ban", callback = showGameBan },
		{ text = "Copy Username", callback = copyUsername },
	}

	for index, option in ipairs(options) do
		createButton(
			actionMenu,
			option.text,
			UDim2.new(1, -16, 0, 24),
			UDim2.new(0, 8, 0, 8 + ((index - 1) * 29)),
			option.callback
		)
	end
end

local function showActionMenu(playerEntry, absolutePosition)
	if not isModerator() then
		return
	end

	selectedPlayer = playerEntry
	rebuildActionMenu()

	actionMenu.Position = UDim2.fromOffset(absolutePosition.X - 178, absolutePosition.Y)
	actionMenu.Visible = true
end

local function createTeamHeader(teamEntry, order)
	local header = Instance.new("TextLabel")
	header.Name = "TeamHeader_" .. teamEntry.name
	header.Size = UDim2.new(1, -8, 0, HEADER_HEIGHT)
	header.BackgroundColor3 = tableToColor3(teamEntry.color)
	header.BackgroundTransparency = 0.12
	header.BorderSizePixel = 0
	header.LayoutOrder = order
	header.Font = Enum.Font.GothamBold
	header.Text = teamEntry.name
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.TextSize = 13
	header.TextStrokeTransparency = 0.75
	header.TextXAlignment = Enum.TextXAlignment.Center
	header.Parent = scrollFrame

	createCorner(header, 7)
	createStroke(header, 0.78)

	return header
end

local function createPlayerRow(playerEntry, order)
	local row = Instance.new("TextButton")
	row.Name = "PlayerRow_" .. playerEntry.name
	row.Size = UDim2.new(1, -8, 0, ROW_HEIGHT)
	row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	row.BackgroundTransparency = 0.25
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.AutoButtonColor = false
	row.Text = ""
	row.Parent = scrollFrame

	createCorner(row, 7)
	createStroke(row, 0.72)

	local iconHolder = Instance.new("Frame")
	iconHolder.Name = "IconHolder"
	iconHolder.BackgroundTransparency = 1
	iconHolder.Position = UDim2.new(0, 8, 0, 0)
	iconHolder.Size = UDim2.new(0, 90, 1, 0)
	iconHolder.Parent = row

	local iconLayout = Instance.new("UIListLayout")
	iconLayout.FillDirection = Enum.FillDirection.Horizontal
	iconLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	iconLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	iconLayout.SortOrder = Enum.SortOrder.LayoutOrder
	iconLayout.Padding = UDim.new(0, 2)
	iconLayout.Parent = iconHolder

	for index, iconData in ipairs(playerEntry.icons or {}) do
		if index > 3 then
			break
		end

		if iconData.image and iconData.image ~= "" then
			local rawIconSize = tonumber(iconData.size) or ICON_SIZE
			local finalIconSize = math.clamp(rawIconSize, 14, ICON_SIZE)

			-- rowSize lets a single icon (e.g. the covert icon) be larger, up to the row height.
			if tonumber(iconData.rowSize) then
				finalIconSize = math.clamp(tonumber(iconData.rowSize), 14, ROW_HEIGHT - 2)
			end

			local icon = Instance.new("ImageLabel")
			icon.Name = tostring(iconData.name or "Badge") .. "_Icon"
			icon.BackgroundTransparency = 1
			icon.Size = UDim2.new(0, finalIconSize, 0, finalIconSize)
			icon.LayoutOrder = index
			icon.Image = iconData.image
			icon.ImageColor3 = tableToColor3(iconData.color)
			icon.ScaleType = Enum.ScaleType.Fit
			icon.Parent = iconHolder
		end
	end

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.Text = playerEntry.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 12
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = row

	if playerEntry.userId == localPlayer.UserId then
		row.BackgroundTransparency = 0.05
		nameLabel.Font = Enum.Font.GothamBold
	end

	row.MouseButton1Click:Connect(function()
		showActionMenu(playerEntry, row.AbsolutePosition)
	end)

	return row
end

local function render(payload)
	if type(payload) ~= "table" then
		return
	end

	clearBoard()

	local order = 1
	local totalHeight = 0

	for _, teamEntry in ipairs(payload.teams or {}) do
		createTeamHeader(teamEntry, order)
		order += 1
		totalHeight += HEADER_HEIGHT + 4

		for _, playerEntry in ipairs(teamEntry.players or {}) do
			createPlayerRow(playerEntry, order)
			order += 1
			totalHeight += ROW_HEIGHT + 4
		end
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 8)
	updateVisibility()
end

remote.OnClientEvent:Connect(render)

moderationNotifyEvent.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end

	showSimpleNotice(tostring(data.title or "Moderation Notice"), tostring(data.message or ""))
end)

localPlayer:GetAttributeChangedSignal("USARF_MenuOpen"):Connect(updateVisibility)
localPlayer:GetAttributeChangedSignal("USARF_InMenu"):Connect(updateVisibility)
localPlayer:GetAttributeChangedSignal("MenuOpen"):Connect(updateVisibility)
localPlayer:GetAttributeChangedSignal("InMenu"):Connect(updateVisibility)
localPlayer:GetAttributeChangedSignal("USARF_Loading"):Connect(updateVisibility)
localPlayer:GetAttributeChangedSignal("Loading"):Connect(updateVisibility)
localPlayer:GetAttributeChangedSignal("InLoading"):Connect(updateVisibility)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == TOGGLE_KEY then
		visible = not visible
		updateVisibility()
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 and actionMenu.Visible then
		local mouseLocation = UserInputService:GetMouseLocation()
		local pos = actionMenu.AbsolutePosition
		local size = actionMenu.AbsoluteSize

		if mouseLocation.X < pos.X or mouseLocation.X > pos.X + size.X or mouseLocation.Y < pos.Y or mouseLocation.Y > pos.Y + size.Y then
			actionMenu.Visible = false
		end
	end
end)

task.defer(function()
	task.wait(1)
	updateVisibility()
end)