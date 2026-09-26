local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local RadioMessageRemote = Remotes:WaitForChild("RadioMessage")
local RadioSendRemote = Remotes:WaitForChild("RadioSend")
local GetRadioPayloadRemote = Remotes:WaitForChild("GetRadioPayload")

local Gui = PlayerGui:WaitForChild("USARFGui")

local TopBar = Gui:WaitForChild("TopBar")
local RadioButton = TopBar:WaitForChild("RadioButton")

local LoadingScreen = Gui:FindFirstChild("LoadingScreen")
local MainMenu = Gui:FindFirstChild("MainMenu")

local Popups = Gui:WaitForChild("Popups")
-- Popups is a transparent, non-interactive container; if it is hidden none of its panels can show.
Popups.Visible = true
local RadioPanel = Popups:WaitForChild("RadioPanel")

local CloseButton = RadioPanel:WaitForChild("CloseButton")
local ChannelTabs = RadioPanel:WaitForChild("ChannelTabs")
local MessagesFrame = RadioPanel:WaitForChild("MessagesFrame")
local InputBox = RadioPanel:WaitForChild("InputBox")
local SendButton = RadioPanel:WaitForChild("SendButton")

local ChannelTabTemplate = ChannelTabs:WaitForChild("ChannelTabTemplate")
local MessageTemplate = MessagesFrame:WaitForChild("MessageTemplate")

local SEND_PURPLE = Color3.fromRGB(108, 99, 255)
local DISABLED_GRAY = Color3.fromRGB(70, 70, 75)
local UNREAD_YELLOW = Color3.fromRGB(255, 207, 64)

local CHANNEL_COLORS = {
	alerts = Color3.fromRGB(255, 207, 64),
	staffalerts = Color3.fromRGB(255, 95, 95),
	general = Color3.fromRGB(180, 180, 190),
	combative = Color3.fromRGB(255, 90, 90),
	intelligence = Color3.fromRGB(155, 110, 255),
	protection = Color3.fromRGB(80, 160, 255),
	command = Color3.fromRGB(255, 180, 80),
	leadership = Color3.fromRGB(255, 220, 120),
	moderation = Color3.fromRGB(90, 200, 120),
}

local TAB_DISPLAY_NAMES = {
	alerts = "ALERTS",
	staffalerts = "STAFF ALERTS",
	general = "GENERAL",
	combative = "COMBAT",
	intelligence = "INTEL",
	protection = "PROTECTION",
	command = "COMMAND",
	leadership = "LEADERSHIP",
	moderation = "MODERATION",
}

local ALL_CHANNELS = {
	{ key = "alerts", name = "ALERTS", readOnly = true },
	{ key = "staffalerts", name = "STAFF ALERTS", readOnly = true },
	{ key = "general", name = "GENERAL", readOnly = false },
	{ key = "combative", name = "COMBATIVE", readOnly = false },
	{ key = "intelligence", name = "INTELLIGENCE", readOnly = false },
	{ key = "protection", name = "PROTECTION", readOnly = false },
	{ key = "command", name = "COMMAND", readOnly = false },
	{ key = "leadership", name = "LEADERSHIP", readOnly = false },
	{ key = "moderation", name = "MODERATION", readOnly = false },
}

local state = {
	activeChannel = nil,
	channels = {},
	messages = {},
	canSeeRedacted = false,
	tabRefs = {},
	unread = {},
	knownMessageIds = {},
	desiredOpen = false,
}

local headerFrame
local headerTitle
local headerSubtext
local headerAccent

local flashingAlerts = false
local flashingStaffAlerts = false

local function playMenuClick()
	if _G.USARFPlaySound then
		_G.USARFPlaySound("MenuClick", "MenuSounds")
	end
end

local function makeCorner(parent, radius)
	local corner = parent:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function makeStroke(parent, color, transparency)
	local stroke = parent:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1
	stroke.Transparency = transparency or 0.25
	stroke.Parent = parent
	return stroke
end

local function isModMode()
	return Player:GetAttribute("USARF_RadioModMode") == true
		or Player:GetAttribute("USARF_ModMode") == true
end

local function isModeratorOrHigher()
	local value = tonumber(Player:GetAttribute("USARF_CmdrAdminLevelValue")) or 0
	local level = tostring(Player:GetAttribute("USARF_CmdrAdminLevel") or "")

	return value >= 3
		or level == "Moderator"
		or level == "Administrator"
		or level == "Developer"
		or level == "Owner"
end

local function applyClientAccessOverrides(serverChannels, serverMessages, serverCanSeeRedacted)
	serverMessages = serverMessages or {}

	local finalChannels = {}
	local channelMap = {}

	local modModeEnabled = Player:GetAttribute("USARF_ModMode") == true
		or Player:GetAttribute("USARF_RadioModMode") == true

	if modModeEnabled then
		for _, channel in ipairs(ALL_CHANNELS) do
			channelMap[channel.key] = true
			table.insert(finalChannels, {
				key = channel.key,
				name = channel.name,
				readOnly = channel.readOnly == true,
			})

			serverMessages[channel.key] = serverMessages[channel.key] or {}
		end

		return finalChannels, serverMessages, true
	end

	for _, channel in ipairs(serverChannels or {}) do
		if channel and channel.key then
			channelMap[channel.key] = true
			table.insert(finalChannels, channel)
			serverMessages[channel.key] = serverMessages[channel.key] or {}
		end
	end

	if isModeratorOrHigher() then
		if not channelMap.moderation then
			table.insert(finalChannels, {
				key = "moderation",
				name = "MODERATION",
				readOnly = false,
			})
			serverMessages.moderation = serverMessages.moderation or {}
		end

		if not channelMap.staffalerts then
			table.insert(finalChannels, {
				key = "staffalerts",
				name = "STAFF ALERTS",
				readOnly = true,
			})
			serverMessages.staffalerts = serverMessages.staffalerts or {}
		end
	end

	return finalChannels, serverMessages, serverCanSeeRedacted == true
end

local function getViewport()
	return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
end

local function isMobileLayout()
	local viewport = getViewport()
	return viewport.X <= 950 or viewport.Y <= 520
end

local function getHudScale()
	local viewport = getViewport()

	if isMobileLayout() then
		return 0.72
	end

	if viewport.X < 1000 then
		return 0.78
	elseif viewport.X < 1200 then
		return 0.88
	end

	return 1
end

local function ensureHeader()
	if headerFrame then
		return
	end

	headerFrame = Instance.new("Frame")
	headerFrame.Name = "RadioHeader"
	headerFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = RadioPanel
	makeCorner(headerFrame, 8)

	headerAccent = Instance.new("Frame")
	headerAccent.Name = "Accent"
	headerAccent.BackgroundColor3 = SEND_PURPLE
	headerAccent.BorderSizePixel = 0
	headerAccent.Parent = headerFrame
	makeCorner(headerAccent, 8)

	headerTitle = Instance.new("TextLabel")
	headerTitle.Name = "Title"
	headerTitle.BackgroundTransparency = 1
	headerTitle.Font = Enum.Font.GothamBold
	headerTitle.Text = "RADIO"
	headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	headerTitle.TextSize = 13
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Parent = headerFrame

	headerSubtext = Instance.new("TextLabel")
	headerSubtext.Name = "Subtext"
	headerSubtext.BackgroundTransparency = 1
	headerSubtext.Font = Enum.Font.Gotham
	headerSubtext.Text = "Awaiting channel..."
	headerSubtext.TextColor3 = Color3.fromRGB(160, 160, 170)
	headerSubtext.TextSize = 11
	headerSubtext.TextXAlignment = Enum.TextXAlignment.Left
	headerSubtext.Parent = headerFrame
end

local function applyHudLayout()
	ensureHeader()

	local viewport = getViewport()
	local mobile = isMobileLayout()

	local scale = RadioPanel:FindFirstChild("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = RadioPanel
	end

	scale.Scale = getHudScale()

	RadioPanel.AnchorPoint = Vector2.new(1, 1)

	if mobile then
		RadioPanel.Position = UDim2.new(1, -10, 1, -10)
		RadioPanel.Size = UDim2.new(0, math.clamp(viewport.X * 0.54, 300, 440), 0, math.clamp(viewport.Y * 0.44, 180, 235))
	else
		RadioPanel.Position = UDim2.new(1, -24, 1, -24)
		RadioPanel.Size = UDim2.new(0, 500, 0, 300)
	end

	RadioPanel.ClipsDescendants = true
	RadioPanel.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
	makeCorner(RadioPanel, 12)
	makeStroke(RadioPanel, Color3.fromRGB(75, 75, 90), 0.35)

	headerFrame.Position = UDim2.new(0, 8, 0, 8)
	headerFrame.Size = UDim2.new(1, -16, 0, mobile and 34 or 38)

	headerAccent.Position = UDim2.new(0, 0, 0, 0)
	headerAccent.Size = UDim2.new(0, 4, 1, 0)

	headerTitle.Position = UDim2.new(0, 12, 0, 3)
	headerTitle.Size = UDim2.new(1, -24, 0, 16)
	headerTitle.TextSize = mobile and 11 or 13

	headerSubtext.Position = UDim2.new(0, 12, 0, 18)
	headerSubtext.Size = UDim2.new(1, -24, 0, 13)
	headerSubtext.TextSize = mobile and 9 or 11

	ChannelTabs.Position = UDim2.new(0, 8, 0, mobile and 46 or 52)
	ChannelTabs.Size = UDim2.new(1, -16, 0, mobile and 28 or 30)
	ChannelTabs.BackgroundTransparency = 1
	ChannelTabs.ClipsDescendants = true

	local tabLayout = ChannelTabs:FindFirstChildOfClass("UIListLayout")
	if tabLayout then
		tabLayout.FillDirection = Enum.FillDirection.Horizontal
		tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tabLayout.Padding = UDim.new(0, mobile and 4 or 6)
		tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	end

	if ChannelTabs:IsA("ScrollingFrame") then
		ChannelTabs.AutomaticCanvasSize = Enum.AutomaticSize.X
		ChannelTabs.CanvasSize = UDim2.new(0, 0, 0, 0)
		ChannelTabs.ScrollingDirection = Enum.ScrollingDirection.X
		ChannelTabs.ScrollBarThickness = 0
	end

	MessagesFrame.Position = UDim2.new(0, 8, 0, mobile and 80 or 88)
	MessagesFrame.Size = UDim2.new(1, -16, 1, mobile and -120 or -132)
	MessagesFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	MessagesFrame.BorderSizePixel = 0
	makeCorner(MessagesFrame, 10)

	if MessagesFrame:IsA("ScrollingFrame") then
		MessagesFrame.ScrollBarThickness = mobile and 2 or 4
		MessagesFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		MessagesFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	end

	local messagesLayout = MessagesFrame:FindFirstChildOfClass("UIListLayout")
	if not messagesLayout then
		messagesLayout = Instance.new("UIListLayout")
		messagesLayout.SortOrder = Enum.SortOrder.LayoutOrder
		messagesLayout.Padding = UDim.new(0, 4)
		messagesLayout.Parent = MessagesFrame
	end

	local messagesPadding = MessagesFrame:FindFirstChildOfClass("UIPadding")
	if not messagesPadding then
		messagesPadding = Instance.new("UIPadding")
		messagesPadding.Parent = MessagesFrame
	end

	messagesPadding.PaddingTop = UDim.new(0, 6)
	messagesPadding.PaddingBottom = UDim.new(0, 6)
	messagesPadding.PaddingLeft = UDim.new(0, 6)
	messagesPadding.PaddingRight = UDim.new(0, 6)

	InputBox.Position = UDim2.new(0, 8, 1, -34)
	InputBox.Size = UDim2.new(1, mobile and -76 or -88, 0, 28)
	InputBox.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
	InputBox.TextColor3 = Color3.fromRGB(245, 245, 250)
	InputBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
	InputBox.TextSize = mobile and 10 or 12
	makeCorner(InputBox, 8)
	makeStroke(InputBox, Color3.fromRGB(70, 70, 85), 0.45)

	SendButton.Position = UDim2.new(1, mobile and -62 or -72, 1, -34)
	SendButton.Size = UDim2.new(0, mobile and 54 or 64, 0, 28)
	SendButton.TextSize = mobile and 9 or 11
	makeCorner(SendButton, 8)

	if CloseButton then
		CloseButton.Visible = true
		CloseButton.ZIndex = RadioPanel.ZIndex + 20
	end
end

local function isInMenuOrLoading()
	return (LoadingScreen and LoadingScreen.Visible)
		or (MainMenu and MainMenu.Visible)
end

local function shouldShowRadioHud()
	if isInMenuOrLoading() then
		return false
	end

	if Player:GetAttribute("USARF_RadioHidden") == true then
		return false
	end

	return #state.channels > 0
end

local function updateRadioVisibility()
	RadioButton.Visible = false

	if not shouldShowRadioHud() then
		RadioPanel.Visible = false
		state.desiredOpen = false
	end

	if _G.USARFUpdateTopbarVisibility then
		_G.USARFUpdateTopbarVisibility()
	end
end

local function toColor3(tbl)
	if type(tbl) ~= "table" then
		return Color3.fromRGB(170, 170, 170)
	end

	return Color3.new(tbl[1] or 0.7, tbl[2] or 0.7, tbl[3] or 0.7)
end

local function colorToHex(color)
	return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

local function escapeRichText(text)
	text = tostring(text or "")
	text = text:gsub("&", "&amp;")
	text = text:gsub("<", "&lt;")
	text = text:gsub(">", "&gt;")
	text = text:gsub('"', "&quot;")
	text = text:gsub("'", "&apos;")
	return text
end

local function formatTime(unixTime)
	local timeTable = os.date("*t", unixTime or os.time())
	return string.format("%02d:%02d", timeTable.hour, timeTable.min)
end

local function clearTabs()
	for _, child in ipairs(ChannelTabs:GetChildren()) do
		if child ~= ChannelTabTemplate and child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function clearMessages()
	for _, child in ipairs(MessagesFrame:GetChildren()) do
		if child ~= MessageTemplate and child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function getDisplayName(packet)
	if packet.isSystem then
		return "SYSTEM"
	end

	if packet.redacted and not state.canSeeRedacted then
		return "REDACTED"
	end

	if packet.redacted and state.canSeeRedacted then
		return "REDACTED - " .. tostring(packet.fromName or "Unknown")
	end

	return tostring(packet.fromName or "Unknown")
end

local function getSelectedChannel(channelKey)
	for _, channel in ipairs(state.channels) do
		if channel.key == channelKey then
			return channel
		end
	end

	return nil
end

local function updateFlashForChannel(channelKey)
	local tab = state.tabRefs[channelKey]
	if not tab then
		return
	end

	local unread = state.unread[channelKey] or 0
	local isStaff = channelKey == "staffalerts"

	if unread <= 0 then
		if isStaff then
			flashingStaffAlerts = false
		else
			flashingAlerts = false
		end

		local unreadDot = tab:FindFirstChild("UnreadDot")
		if unreadDot then
			unreadDot.BackgroundTransparency = 0
		end

		return
	end

	if isStaff then
		if flashingStaffAlerts then
			return
		end
		flashingStaffAlerts = true
	else
		if flashingAlerts then
			return
		end
		flashingAlerts = true
	end

	task.spawn(function()
		while (state.unread[channelKey] or 0) > 0 do
			local shouldContinue = isStaff and flashingStaffAlerts or flashingAlerts
			if not shouldContinue then
				break
			end

			local unreadDot = tab:FindFirstChild("UnreadDot")
			if unreadDot then
				unreadDot.BackgroundTransparency = 0
			end

			task.wait(0.5)

			if unreadDot then
				unreadDot.BackgroundTransparency = 0.55
			end

			task.wait(0.5)
		end

		local unreadDot = tab:FindFirstChild("UnreadDot")
		if unreadDot then
			unreadDot.BackgroundTransparency = 0
		end

		if isStaff then
			flashingStaffAlerts = false
		else
			flashingAlerts = false
		end
	end)
end

local function createMessage(packet)
	local line = MessageTemplate:Clone()
	line.Visible = true
	line.Name = "Message_" .. tostring(packet.id or math.random(1000, 9999))
	line.Parent = MessagesFrame
	line.BackgroundTransparency = 0
	line.BackgroundColor3 = packet.isSystem and Color3.fromRGB(35, 28, 14) or Color3.fromRGB(18, 18, 24)
	line.BorderSizePixel = 0
	line.Size = UDim2.new(1, -6, 0, 34)
	makeCorner(line, 8)

	local MessageLabel = line:FindFirstChild("MessageLabel")
	if not MessageLabel then
		MessageLabel = Instance.new("TextLabel")
		MessageLabel.Name = "MessageLabel"
		MessageLabel.Parent = line
	end

	for _, oldName in ipairs({ "PrefixLabel", "NameLabel", "BodyLabel", "TimeLabel" }) do
		local old = line:FindFirstChild(oldName)
		if old then
			old.Visible = false
		end
	end

	local prefixColor = packet.isSystem and (CHANNEL_COLORS[packet.channel] or Color3.fromRGB(255, 200, 60)) or toColor3(packet.teamColor)
	local prefixHex = colorToHex(prefixColor)
	local prefixText = packet.isSystem and "SYSTEM" or tostring(packet.teamAbv or "N/A")
	local nameText = getDisplayName(packet)
	local timeText = formatTime(packet.when)
	local bodyText = escapeRichText(packet.text or "")

	MessageLabel.BackgroundTransparency = 1
	MessageLabel.RichText = true
	MessageLabel.TextWrapped = true
	MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
	MessageLabel.TextYAlignment = Enum.TextYAlignment.Center
	MessageLabel.Font = Enum.Font.Gotham
	MessageLabel.TextSize = 12
	MessageLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
	MessageLabel.Position = UDim2.new(0, 8, 0, 3)
	MessageLabel.Size = UDim2.new(1, -16, 1, -6)

	if packet.isSystem then
		MessageLabel.Text =
			'<font color="' .. prefixHex .. '"><b>[SYSTEM]</b></font> ' ..
			'<font color="#888888">(' .. timeText .. '):</font> ' ..
			bodyText
	else
		local revealColor = packet.redacted and state.canSeeRedacted and "#C9A6FF" or "#FFFFFF"

		MessageLabel.Text =
			'<font color="' .. prefixHex .. '"><b>[' .. escapeRichText(prefixText) .. ']</b></font> ' ..
			'<font color="' .. revealColor .. '"><b>' .. escapeRichText(nameText) .. '</b></font> ' ..
			'<font color="#888888">(' .. timeText .. '):</font> ' ..
			bodyText
	end

	task.defer(function()
		local textBounds = MessageLabel.TextBounds.Y
		line.Size = UDim2.new(1, -6, 0, math.max(34, textBounds + 12))
	end)

	return line
end

local function scrollToBottom()
	task.defer(function()
		if MessagesFrame:IsA("ScrollingFrame") then
			MessagesFrame.CanvasPosition = Vector2.new(0, math.max(0, MessagesFrame.AbsoluteCanvasSize.Y))
		end
	end)
end

local function renderMessages(channelKey)
	clearMessages()

	for _, packet in ipairs(state.messages[channelKey] or {}) do
		createMessage(packet)
	end

	scrollToBottom()
end

local function updateTabUnread(channelKey)
	local tab = state.tabRefs[channelKey]
	if not tab then
		return
	end

	local channel = getSelectedChannel(channelKey)
	if not channel then
		return
	end

	local unreadCount = state.unread[channelKey] or 0
	tab.Text = TAB_DISPLAY_NAMES[channelKey] or channel.name

	local unreadDot = tab:FindFirstChild("UnreadDot")
	if unreadDot then
		unreadDot.Visible = unreadCount > 0
	end

	local unreadText = tab:FindFirstChild("UnreadText")
	if unreadText then
		unreadText.Visible = unreadCount > 0
		unreadText.Text = unreadCount > 9 and "9+" or tostring(unreadCount)
	end

	if channelKey == "alerts" or channelKey == "staffalerts" then
		updateFlashForChannel(channelKey)
	end
end

local function updateHeader(channelKey)
	ensureHeader()

	local channel = getSelectedChannel(channelKey)
	local color = CHANNEL_COLORS[channelKey] or SEND_PURPLE
	local displayName = TAB_DISPLAY_NAMES[channelKey] or (channel and channel.name) or "RADIO"

	headerAccent.BackgroundColor3 = color
	headerTitle.Text = "RADIO / " .. string.upper(displayName)

	if channelKey == "staffalerts" then
		headerSubtext.Text = "Moderator-only alert feed"
		headerSubtext.TextColor3 = Color3.fromRGB(255, 120, 120)
	elseif state.canSeeRedacted and isModMode() then
		headerSubtext.Text = "ModMode visibility enabled"
		headerSubtext.TextColor3 = Color3.fromRGB(190, 160, 255)
	elseif channel and channel.readOnly then
		headerSubtext.Text = "Read-only channel"
		headerSubtext.TextColor3 = Color3.fromRGB(255, 190, 80)
	else
		headerSubtext.Text = "Secure communications channel"
		headerSubtext.TextColor3 = Color3.fromRGB(160, 160, 170)
	end
end

local function selectChannel(channelKey)
	state.activeChannel = channelKey
	state.unread[channelKey] = 0

	updateTabUnread(channelKey)
	updateHeader(channelKey)

	for key, button in pairs(state.tabRefs) do
		local selected = key == channelKey
		local channelColor = CHANNEL_COLORS[key] or SEND_PURPLE

		button.TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(165, 165, 175)
		button.BackgroundColor3 = selected and channelColor:Lerp(Color3.new(1, 1, 1), 0.15) or Color3.fromRGB(32, 32, 40)
	end

	local selectedChannel = getSelectedChannel(channelKey)

	if selectedChannel and selectedChannel.readOnly then
		InputBox.Text = ""
		InputBox.TextEditable = false
		InputBox.PlaceholderText = "READ ONLY CHANNEL"
		InputBox.BackgroundColor3 = Color3.fromRGB(34, 34, 38)
		SendButton.Text = "LOCKED"
		SendButton.Active = false
		SendButton.AutoButtonColor = false
		SendButton.BackgroundColor3 = DISABLED_GRAY
	else
		InputBox.TextEditable = true
		InputBox.PlaceholderText = "Type radio message..."
		InputBox.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
		SendButton.Text = "SEND"
		SendButton.Active = true
		SendButton.AutoButtonColor = true
		SendButton.BackgroundColor3 = CHANNEL_COLORS[channelKey] or SEND_PURPLE
	end

	renderMessages(channelKey)
end

local function rebuildTabs()
	clearTabs()
	state.tabRefs = {}

	for index, channel in ipairs(state.channels) do
		local tab = ChannelTabTemplate:Clone()
		tab.Visible = true
		tab.Name = channel.key .. "Tab"
		tab.Text = TAB_DISPLAY_NAMES[channel.key] or channel.name
		tab.LayoutOrder = index
		tab.Parent = ChannelTabs

		tab.Size = UDim2.new(0, channel.key == "staffalerts" and 72 or 86, 0, 26)
		tab.TextSize = 9
		tab.TextScaled = false
		tab.TextWrapped = false
		tab.ClipsDescendants = true
		tab.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
		makeCorner(tab, 7)

		local oldUnderline = tab:FindFirstChild("SelectedUnderline")
		if oldUnderline then
			oldUnderline:Destroy()
		end

		local unreadDot = tab:FindFirstChild("UnreadDot")
		if not unreadDot then
			unreadDot = Instance.new("Frame")
			unreadDot.Name = "UnreadDot"
			unreadDot.AnchorPoint = Vector2.new(1, 0)
			unreadDot.Position = UDim2.new(1, -5, 0, 4)
			unreadDot.Size = UDim2.new(0, 14, 0, 14)
			unreadDot.BackgroundTransparency = 0
			unreadDot.BorderSizePixel = 0
			unreadDot.Visible = false
			unreadDot.ZIndex = tab.ZIndex + 2
			unreadDot.Parent = tab
			makeCorner(unreadDot, 7)
		end

		unreadDot.BackgroundColor3 = channel.key == "staffalerts" and Color3.fromRGB(255, 95, 95) or UNREAD_YELLOW

		local unreadText = tab:FindFirstChild("UnreadText")
		if not unreadText then
			unreadText = Instance.new("TextLabel")
			unreadText.Name = "UnreadText"
			unreadText.BackgroundTransparency = 1
			unreadText.Position = UDim2.new(1, -19, 0, 3)
			unreadText.Size = UDim2.new(0, 14, 0, 14)
			unreadText.Font = Enum.Font.GothamBold
			unreadText.TextColor3 = Color3.fromRGB(30, 30, 30)
			unreadText.TextSize = 8
			unreadText.Visible = false
			unreadText.ZIndex = tab.ZIndex + 3
			unreadText.Parent = tab
		end

		state.tabRefs[channel.key] = tab
		updateTabUnread(channel.key)

		tab.MouseButton1Click:Connect(function()
			playMenuClick()
			state.desiredOpen = true
			selectChannel(channel.key)
		end)
	end

	if #state.channels > 0 then
		if state.activeChannel and getSelectedChannel(state.activeChannel) then
			selectChannel(state.activeChannel)
		else
			selectChannel(state.channels[1].key)
		end
	end
end

local function makePacketKey(packet)
	if packet.id then
		return tostring(packet.id)
	end

	return tostring(packet.channel) .. "|" .. tostring(packet.fromUserId) .. "|" .. tostring(packet.when) .. "|" .. tostring(packet.text)
end

local function rebuildKnownMessageIds()
	state.knownMessageIds = {}

	for channelKey, list in pairs(state.messages) do
		state.knownMessageIds[channelKey] = {}

		for _, packet in ipairs(list) do
			state.knownMessageIds[channelKey][makePacketKey(packet)] = true
		end
	end
end

local function loadPayload(forceOpen)
	local wasOpen = RadioPanel.Visible

	local success, result = pcall(function()
		return GetRadioPayloadRemote:InvokeServer()
	end)

	if not success then
		warn("[RadioController] Failed to load payload:", result)
		state.channels = {}
		state.messages = {}
		updateRadioVisibility()
		return
	end

	local channels, messages, canSeeRedacted = applyClientAccessOverrides(
		result.channels or {},
		result.messages or {},
		result.canSeeRedacted == true
	)

	state.channels = channels
	state.messages = messages
	state.canSeeRedacted = canSeeRedacted

	state.unread = {}
	flashingAlerts = false
	flashingStaffAlerts = false

	for _, channel in ipairs(state.channels) do
		state.unread[channel.key] = 0
	end

	rebuildKnownMessageIds()
	rebuildTabs()
	updateRadioVisibility()

	if shouldShowRadioHud() and (forceOpen == true or wasOpen or state.desiredOpen) then
		state.desiredOpen = true
		RadioPanel.Visible = true
	end
end

local function sendMessage()
	if not state.activeChannel then
		return
	end

	local selectedChannel = getSelectedChannel(state.activeChannel)

	if selectedChannel and selectedChannel.readOnly then
		InputBox.Text = ""
		return
	end

	local text = InputBox.Text

	if text == nil or text == "" then
		return
	end

	if #text > 180 then
		text = string.sub(text, 1, 180)
	end

	RadioSendRemote:FireServer(state.activeChannel, text)
	InputBox.Text = ""
end

RadioMessageRemote.OnClientEvent:Connect(function(packet)
	if type(packet) ~= "table" then
		return
	end

	local channelKey = packet.channel
	if not channelKey then
		return
	end

	state.messages[channelKey] = state.messages[channelKey] or {}
	state.knownMessageIds[channelKey] = state.knownMessageIds[channelKey] or {}

	local packetKey = makePacketKey(packet)

	if state.knownMessageIds[channelKey][packetKey] then
		return
	end

	state.knownMessageIds[channelKey][packetKey] = true
	table.insert(state.messages[channelKey], packet)

	if #state.messages[channelKey] > 80 then
		table.remove(state.messages[channelKey], 1)
		rebuildKnownMessageIds()
	end

	if channelKey == state.activeChannel and RadioPanel.Visible then
		createMessage(packet)
		scrollToBottom()
	else
		state.unread[channelKey] = (state.unread[channelKey] or 0) + 1
		updateTabUnread(channelKey)
	end
end)

SendButton.MouseButton1Click:Connect(sendMessage)

InputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		sendMessage()
	end
end)

if CloseButton then
	CloseButton.MouseButton1Click:Connect(function()
		playMenuClick()
		state.desiredOpen = false
		RadioPanel.Visible = false
	end)
end

if LoadingScreen then
	LoadingScreen:GetPropertyChangedSignal("Visible"):Connect(updateRadioVisibility)
end

if MainMenu then
	MainMenu:GetPropertyChangedSignal("Visible"):Connect(updateRadioVisibility)
end

Player:GetAttributeChangedSignal("USARF_RadioHidden"):Connect(updateRadioVisibility)

local function forceOpenRadioSoon()
	task.spawn(function()
		for _ = 1, 12 do
			if shouldShowRadioHud() then
				state.desiredOpen = true
				RadioPanel.Visible = true
				return
			end

			task.wait(0.15)
		end
	end)
end

local function onModModeChanged()
	task.wait(0.25)

	local modModeEnabled = Player:GetAttribute("USARF_ModMode") == true
		or Player:GetAttribute("USARF_RadioModMode") == true

	state.desiredOpen = true

	loadPayload(true)

	task.delay(0.25, function()
		if shouldShowRadioHud() then
			state.desiredOpen = true
			RadioPanel.Visible = true
		end
	end)
end

Player:GetAttributeChangedSignal("USARF_RadioModMode"):Connect(onModModeChanged)
Player:GetAttributeChangedSignal("USARF_ModMode"):Connect(onModModeChanged)

Player:GetAttributeChangedSignal("USARF_CmdrAdminLevel"):Connect(function()
	task.wait(0.1)
	loadPayload(false)
end)

Player:GetAttributeChangedSignal("USARF_CmdrAdminLevelValue"):Connect(function()
	task.wait(0.1)
	loadPayload(false)
end)

Player:GetPropertyChangedSignal("Team"):Connect(function()
	task.wait(0.35)
	loadPayload(false)
end)

Player:GetAttributeChangedSignal("USARF_TeamKey"):Connect(function()
	task.wait(0.35)
	loadPayload(false)
end)

Player:GetAttributeChangedSignal("USARF_TemporaryRadioAccess"):Connect(function()
	task.wait(0.1)
	loadPayload(false)
end)

Player:GetAttributeChangedSignal("USARF_RadioAccessRefresh"):Connect(function()
	task.wait(0.1)
	loadPayload(false)
end)

Player:GetAttributeChangedSignal("USARF_RadioAccessRefreshClient"):Connect(function()
	task.wait(0.1)
	loadPayload(false)
end)

applyHudLayout()

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyHudLayout)
end

RadioPanel.Visible = false
RadioButton.Visible = false
InputBox.Text = ""

loadPayload(true)
updateRadioVisibility()

if shouldShowRadioHud() then
	state.desiredOpen = true
	RadioPanel.Visible = true
end

_G.USARFToggleRadio = function()
	if Player:GetAttribute("USARF_RadioHidden") == true then
		return
	end

	if not shouldShowRadioHud() then
		RadioPanel.Visible = false
		state.desiredOpen = false
		return
	end

	playMenuClick()

	state.desiredOpen = not RadioPanel.Visible
	RadioPanel.Visible = state.desiredOpen
end

_G.USARFOpenRadio = function(playSound)
	if playSound ~= false then
		playMenuClick()
	end

	if shouldShowRadioHud() then
		state.desiredOpen = true
		RadioPanel.Visible = true
	end
end

_G.USARFCloseRadio = function(playSound)
	if playSound ~= false then
		playMenuClick()
	end

	state.desiredOpen = false
	RadioPanel.Visible = false
end

print("USARF RadioController initialized")