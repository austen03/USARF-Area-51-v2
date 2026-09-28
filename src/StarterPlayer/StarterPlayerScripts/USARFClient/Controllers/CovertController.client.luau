-- Covert mode on the client: shows covert players' fake names in the chat
-- window, and the covert panel for certified players (topbar button or /covert).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local CovertConfig = require(USARF:WaitForChild("Config"):WaitForChild("CovertConfig"))

local CovertRequest = Remotes:WaitForChild("CovertRequest")
local CovertUpdated = Remotes:WaitForChild("CovertUpdated")

local COVERT_NAME_ATTRIBUTE = "USARF_CovertName"

--// Chat window names

local function escapePattern(text)
	return (string.gsub(text, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

TextChatService.OnIncomingMessage = function(message)
	local properties = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	local sender = source and Players:GetPlayerByUserId(source.UserId)
	local covertName = sender and sender:GetAttribute(COVERT_NAME_ATTRIBUTE)

	if typeof(covertName) == "string" and covertName ~= "" and message.PrefixText ~= "" then
		local prefix = string.gsub(message.PrefixText, escapePattern(sender.DisplayName), function()
			return covertName
		end, 1)

		properties.PrefixText = prefix
	end

	return properties
end

--// Panel

local state = nil
local pendingOrg = nil
local pendingGold = false
local orgResults = {}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CovertUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 55
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function makeStroke(parent, color, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1
	stroke.Transparency = transparency or 0.2
	stroke.Parent = parent
	return stroke
end

local function makeLabel(parent, text, height, font, size, color, order)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, height)
	label.Font = font or Enum.Font.Gotham
	label.Text = text
	label.TextSize = size or 13
	label.TextColor3 = color or Color3.fromRGB(210, 210, 215)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.LayoutOrder = order or 0
	label.Parent = parent
	return label
end

local function makeButton(parent, text, size, color)
	local button = Instance.new("TextButton")
	button.Size = size
	button.BackgroundColor3 = color or Color3.fromRGB(45, 45, 52)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 13
	button.AutoButtonColor = true
	button.Parent = parent
	makeCorner(button, 8)
	return button
end

local function makeTextBox(parent, placeholder, order)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 32)
	box.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.Gotham
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Color3.fromRGB(120, 120, 128)
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(240, 240, 240)
	box.TextSize = 13
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.LayoutOrder = order
	box.Parent = parent
	makeCorner(box, 8)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.Parent = box

	return box
end

local frame = Instance.new("Frame")
frame.Name = "CovertMain"
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.fromOffset(380, 470)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui
makeCorner(frame, 14)
makeStroke(frame, Color3.fromRGB(90, 90, 110), 0.12)

local title = makeLabel(frame, "COVERT OPERATIONS", 32, Enum.Font.GothamBold, 18, Color3.fromRGB(235, 235, 240))
title.Position = UDim2.fromOffset(18, 12)
title.Size = UDim2.new(1, -70, 0, 32)

local closeButton = makeButton(frame, "X", UDim2.fromOffset(32, 32))
closeButton.Position = UDim2.new(1, -46, 0, 12)

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.fromOffset(18, 52)
content.Size = UDim2.new(1, -36, 1, -64)
content.Parent = frame

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = content

local statusLabel = makeLabel(content, "", 34, Enum.Font.GothamMedium, 13, Color3.fromRGB(200, 200, 205), 1)

makeLabel(content, "Covert name", 16, Enum.Font.GothamBold, 12, Color3.fromRGB(160, 160, 170), 2)
local nameBox = makeTextBox(content, `{CovertConfig.Name.MinLength}-{CovertConfig.Name.MaxLength} characters`, 3)

makeLabel(content, "Organization", 16, Enum.Font.GothamBold, 12, Color3.fromRGB(160, 160, 170), 4)
local orgLabel = makeLabel(content, "None", 16, Enum.Font.Gotham, 13, Color3.fromRGB(230, 230, 235), 5)
local orgSearchBox = makeTextBox(content, "Search organizations...", 6)

local orgList = Instance.new("ScrollingFrame")
orgList.Size = UDim2.new(1, 0, 0, 104)
orgList.BackgroundColor3 = Color3.fromRGB(26, 26, 31)
orgList.BorderSizePixel = 0
orgList.ScrollBarThickness = 4
orgList.AutomaticCanvasSize = Enum.AutomaticSize.Y
orgList.CanvasSize = UDim2.new()
orgList.LayoutOrder = 7
orgList.Parent = content
makeCorner(orgList, 8)

local orgListLayout = Instance.new("UIListLayout")
orgListLayout.SortOrder = Enum.SortOrder.LayoutOrder
orgListLayout.Padding = UDim.new(0, 2)
orgListLayout.Parent = orgList

local function makeToggleRow(text, order)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 28)
	row.LayoutOrder = order
	row.Parent = content

	local label = makeLabel(row, text, 28, Enum.Font.GothamMedium, 13)
	label.Size = UDim2.new(1, -80, 1, 0)

	local button = makeButton(row, "OFF", UDim2.fromOffset(70, 26))
	button.Position = UDim2.new(1, -70, 0, 1)

	return row, button
end

local _, goldButton = makeToggleRow("Gold nametag stars", 8)
local clearanceRow, clearanceButton = makeToggleRow("Door clearance", 9)

local actionRow = Instance.new("Frame")
actionRow.BackgroundTransparency = 1
actionRow.Size = UDim2.new(1, 0, 0, 34)
actionRow.LayoutOrder = 10
actionRow.Parent = content

local primaryButton = makeButton(actionRow, "GO COVERT", UDim2.new(0.5, -4, 1, 0), Color3.fromRGB(60, 110, 70))
local saveNameButton = makeButton(actionRow, "SAVE NAME", UDim2.new(0.5, -4, 1, 0))
saveNameButton.Position = UDim2.new(0.5, 4, 0, 0)

local messageLabel = makeLabel(content, "", 30, Enum.Font.Gotham, 12, Color3.fromRGB(230, 190, 110), 11)

local function setToggle(button, enabled)
	button.Text = if enabled then "ON" else "OFF"
	button.BackgroundColor3 = if enabled then Color3.fromRGB(60, 110, 70) else Color3.fromRGB(45, 45, 52)
end

local function currentOrgTag()
	if state and state.Active then
		return state.Org and state.Org.Tag
	end

	return pendingOrg and pendingOrg.Tag
end

local function render()
	local active = state ~= nil and state.Active == true

	if active then
		statusLabel.Text = `Active as {state.Name} ({state.SubjectNumber}). Radio: {state.HomeTeam}. Use {CovertConfig.RadioCommand} to transmit.`
		primaryButton.Text = "EXIT COVERT"
		primaryButton.BackgroundColor3 = Color3.fromRGB(130, 55, 55)
	else
		statusLabel.Text = "Inactive. You'll respawn as a Test Subject and keep your department's radio."
		primaryButton.Text = "GO COVERT"
		primaryButton.BackgroundColor3 = Color3.fromRGB(60, 110, 70)
	end

	saveNameButton.Visible = active
	primaryButton.Size = if active then UDim2.new(0.5, -4, 1, 0) else UDim2.new(1, 0, 1, 0)
	clearanceRow.Visible = active

	local tag = currentOrgTag()
	orgLabel.Text = if tag then `[{tag}]` else "None"

	setToggle(goldButton, if active then state.Gold else pendingGold)
	setToggle(clearanceButton, active and state.Clearance)
end

local function applyState(newState)
	state = newState

	if state and state.Active and not nameBox:IsFocused() then
		nameBox.Text = state.Name or ""
	end

	_G.USARFCovertCertified = state ~= nil and state.Certified == true

	if typeof(_G.USARFUpdateTopbarVisibility) == "function" then
		_G.USARFUpdateTopbarVisibility()
	end

	if not _G.USARFCovertCertified then
		frame.Visible = false
	end

	render()
end

local function request(action, payload)
	local success, result = pcall(function()
		return CovertRequest:InvokeServer(action, payload)
	end)

	if not success or typeof(result) ~= "table" then
		messageLabel.Text = "Request failed. Try again."
		return nil
	end

	if result.State then
		applyState(result.State)
	end

	messageLabel.Text = result.Message or ""

	return result
end

local function renderOrgs()
	for _, child in orgList:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end

	local entries = { { Id = "", Tag = nil, Name = "None" } }

	for _, org in orgResults do
		table.insert(entries, org)
	end

	for index, org in entries do
		local text = if org.Tag then `[{org.Tag}] {org.Name}` else org.Name
		local button = makeButton(orgList, text, UDim2.new(1, -6, 0, 24), Color3.fromRGB(34, 34, 40))
		button.Font = Enum.Font.Gotham
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.LayoutOrder = index

		button.MouseButton1Click:Connect(function()
			if state and state.Active then
				request("SetOrg", { OrgId = org.Id })
			else
				pendingOrg = if org.Id ~= "" then org else nil
				render()
			end
		end)
	end
end

local function searchOrgs()
	local result = request("ListOrgs", { Search = orgSearchBox.Text })

	if result and result.Success then
		orgResults = result.Orgs or {}
		renderOrgs()
	end
end

local function openPanel()
	if not _G.USARFCovertCertified then
		return
	end

	frame.Visible = true
	messageLabel.Text = ""
	searchOrgs()
end

local function togglePanel()
	if frame.Visible then
		frame.Visible = false
	else
		openPanel()
	end
end

_G.USARFToggleCovert = togglePanel

closeButton.MouseButton1Click:Connect(function()
	frame.Visible = false
end)

orgSearchBox.FocusLost:Connect(searchOrgs)

goldButton.MouseButton1Click:Connect(function()
	if state and state.Active then
		request("SetGold", { Enabled = not state.Gold })
	else
		pendingGold = not pendingGold
		render()
	end
end)

clearanceButton.MouseButton1Click:Connect(function()
	if state and state.Active then
		request("SetClearance", { Enabled = not state.Clearance })
	end
end)

saveNameButton.MouseButton1Click:Connect(function()
	request("SetName", { Name = nameBox.Text })
end)

primaryButton.MouseButton1Click:Connect(function()
	if state and state.Active then
		request("Exit")
		return
	end

	messageLabel.Text = "Going covert..."

	local result = request("Enter", {
		Name = nameBox.Text,
		OrgId = pendingOrg and pendingOrg.Id,
		Gold = pendingGold,
	})

	if result and result.Success then
		pendingOrg = nil
		pendingGold = false
		render()
	end
end)

CovertUpdated.OnClientEvent:Connect(function(newState, open)
	applyState(newState)

	if open then
		openPanel()
	end
end)

-- Certifications load a moment after joining, so ask again shortly after.
task.spawn(function()
	request("GetState")
	task.wait(8)
	request("GetState")
end)
