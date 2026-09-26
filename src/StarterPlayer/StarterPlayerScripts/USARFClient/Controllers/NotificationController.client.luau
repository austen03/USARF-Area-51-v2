local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local NotifyRemote = Remotes:WaitForChild("Notify")

local DEFAULT_BOTTOM_PADDING = 24
local RIGHT_PADDING = 24
local UI_GAP = 12

local CONTAINER_SIZE = UDim2.new(0, 320, 0, 260)
local NOTIFICATION_SIZE = UDim2.new(0, 300, 0, 64)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100000
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Name = "Container"
container.AnchorPoint = Vector2.new(1, 1)
container.Position = UDim2.new(1, -RIGHT_PADDING, 1, -DEFAULT_BOTTOM_PADDING)
container.Size = CONTAINER_SIZE
container.BackgroundTransparency = 1
container.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.Parent = container

local typeStyles = {
	Success = { Color = Color3.fromRGB(70, 170, 90) },
	Error = { Color = Color3.fromRGB(190, 70, 70) },
	Warning = { Color = Color3.fromRGB(220, 165, 55) },
	Info = { Color = Color3.fromRGB(85, 140, 220) },
	Normal = { Color = Color3.fromRGB(85, 140, 220) },
	Currency = { Color = Color3.fromRGB(95, 220, 120) },
	Daily = { Color = Color3.fromRGB(255, 205, 75) },
	Shop = { Color = Color3.fromRGB(130, 95, 210) },
	Emergency = { Color = Color3.fromRGB(255, 65, 65) },
	ProtectionAlert = { Color = Color3.fromRGB(255, 205, 75) },
}

local function getStyle(notificationType)
	return typeStyles[notificationType] or typeStyles.Info
end

local function getRadioPanel()
	local usarfgui = playerGui:FindFirstChild("USARFGui")
	local popups = usarfgui and usarfgui:FindFirstChild("Popups")
	local radioPanel = popups and popups:FindFirstChild("RadioPanel")

	if radioPanel and radioPanel.Visible then
		return radioPanel
	end

	return nil
end

local function getBottomOffsetAbove(guiObject)
	if not guiObject then
		return DEFAULT_BOTTOM_PADDING
	end

	local camera = workspace.CurrentCamera
	local viewportHeight = camera and camera.ViewportSize.Y or 720

	local topY = guiObject.AbsolutePosition.Y
	return math.max(DEFAULT_BOTTOM_PADDING, viewportHeight - topY + UI_GAP)
end

local function applyNotificationLayout()
	if player:GetAttribute("USARF_ProtectionSystemOpen") == true then
		container.AnchorPoint = Vector2.new(1, 0)
		container.Position = UDim2.new(1, -RIGHT_PADDING, 0, 110)
		container.Size = CONTAINER_SIZE

		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		return
	end

	local radioPanel = getRadioPanel()
	local bottomOffset = radioPanel and getBottomOffsetAbove(radioPanel) or DEFAULT_BOTTOM_PADDING

	container.AnchorPoint = Vector2.new(1, 1)
	container.Position = UDim2.new(1, -RIGHT_PADDING, 1, -bottomOffset)
	container.Size = CONTAINER_SIZE

	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
end

local function createNotification(data)
	data = data or {}
	applyNotificationLayout()

	local style = getStyle(data.Type)

	local frame = Instance.new("Frame")
	frame.Name = "Notification"
	frame.Size = NOTIFICATION_SIZE
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.LayoutOrder = os.clock() * 1000
	frame.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(95, 95, 105)
	stroke.Thickness = 1
	stroke.Transparency = 1
	stroke.Parent = frame

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.BackgroundColor3 = style.Color
	accent.BackgroundTransparency = 1
	accent.BorderSizePixel = 0
	accent.Position = UDim2.new(0, 0, 0, 0)
	accent.Size = UDim2.new(0, 4, 1, 0)
	accent.Parent = frame

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 12)
	accentCorner.Parent = accent

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = tostring(data.Title or "Notification")
	title.TextTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Position = UDim2.new(0, 18, 0, 9)
	title.Size = UDim2.new(1, -32, 0, 20)
	title.TextSize = 13
	title.Parent = frame

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.BackgroundTransparency = 1
	message.Font = Enum.Font.Gotham
	message.Text = tostring(data.Message or "")
	message.TextTransparency = 1
	message.TextColor3 = Color3.fromRGB(170, 170, 175)
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Top
	message.TextWrapped = true
	message.Position = UDim2.new(0, 18, 0, 31)
	message.Size = UDim2.new(1, -32, 0, 26)
	message.TextSize = 11
	message.Parent = frame

	local startPosition = frame.Position
	frame.Position = UDim2.new(0, 40, 0, 0)

	local fadeIn = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeOut = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	TweenService:Create(frame, fadeIn, {
		BackgroundTransparency = 0.05,
		Position = startPosition,
	}):Play()

	TweenService:Create(stroke, fadeIn, { Transparency = 0.65 }):Play()
	TweenService:Create(accent, fadeIn, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(title, fadeIn, { TextTransparency = 0 }):Play()
	TweenService:Create(message, fadeIn, { TextTransparency = 0 }):Play()

	task.delay(tonumber(data.Duration) or 5, function()
		if not frame.Parent then
			return
		end

		TweenService:Create(frame, fadeOut, {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 40, 0, 0),
		}):Play()

		TweenService:Create(stroke, fadeOut, { Transparency = 1 }):Play()
		TweenService:Create(accent, fadeOut, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(title, fadeOut, { TextTransparency = 1 }):Play()
		TweenService:Create(message, fadeOut, { TextTransparency = 1 }):Play()

		task.wait(0.3)

		if frame and frame.Parent then
			frame:Destroy()
		end
	end)
end

local function showNotification(title, message, duration, notificationType)
	createNotification({
		Title = title or "Notification",
		Message = message or "",
		Duration = duration or 5,
		Type = notificationType or "Normal",
	})
end

_G.USARFNotify = showNotification

NotifyRemote.OnClientEvent:Connect(function(data)
	createNotification(data or {})
end)

player:GetAttributeChangedSignal("USARF_ProtectionSystemOpen"):Connect(function()
	task.wait(0.05)
	applyNotificationLayout()
end)

task.spawn(function()
	while true do
		applyNotificationLayout()
		task.wait(0.25)
	end
end)

applyNotificationLayout()

print("USARF NotificationController initialized")