local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local SCREEN_GUI_NAME = "USARF_HealthUI"

local ATTR_HEALTH = "USARF_Health"
local ATTR_MAX_HEALTH = "USARF_MaxHealth"
local ATTR_HEALTH_PERCENT = "USARF_HealthPercent"
local ATTR_BLEEDING = "USARF_Bleeding"
local ATTR_BLEEDING_SEVERITY = "USARF_BleedingSeverity"
local ATTR_INJURY = "USARF_Injury"
local ATTR_INJURY_TYPE = "USARF_InjuryType"
local ATTR_DEAD = "USARF_Dead"
local ATTR_IN_MENU = "USARF_InMenu"

local colors = {
	panel = Color3.fromRGB(18, 18, 24),
	stroke = Color3.fromRGB(80, 80, 95),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(175, 175, 185),
	healthy = Color3.fromRGB(55, 214, 104),
	warning = Color3.fromRGB(255, 170, 0),
	danger = Color3.fromRGB(220, 60, 60),
	critical = Color3.fromRGB(160, 40, 40),
}

local gui
local root
local scaleObject
local healthFill
local healthText
local statusText
local titleText

local isVisible = true

local function disableDefaultHealth()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)
end

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function makeStroke(parent, color, transparency, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency or 0.35
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
	return stroke
end

local function makeText(parent, text, size, bold, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text or ""
	label.TextColor3 = color or colors.text
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextSize = size or 14
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function getViewportSize()
	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(1920, 1080)
end

local function getResponsiveScale()
	local viewport = getViewportSize()

	if viewport.X <= 900 then
		return 0.8
	end

	if viewport.X <= 1200 then
		return 0.88
	end

	if viewport.X <= 1500 then
		return 0.94
	end

	return 1
end

-- The chat input bar sits under the top bar on the left, where this panel goes. Its
-- Absolute* values are measured below the top bar; 0 when the bar is hidden (e.g. Cmdr open).
local function getChatBarBottom()
	local success, bottom = pcall(function()
		local chatBar = TextChatService.ChatInputBarConfiguration

		if not chatBar.Enabled then
			return 0
		end

		return chatBar.AbsolutePosition.Y + chatBar.AbsoluteSize.Y
	end)

	return success and tonumber(bottom) or 0
end

local function applyResponsiveLayout()
	if not root then
		return
	end

	local viewport = getViewportSize()
	local scale = getResponsiveScale()

	if scaleObject then
		scaleObject.Scale = scale
	end

	-- Sits just below Roblox's top bar (its height varies by device), with the notification
	-- stack below it (NotificationController) so nothing lands on the bottom-right panels.
	local left = 24

	if viewport.X <= 900 then
		left = 14
	elseif viewport.X <= 1200 then
		left = 18
	end

	local topbarHeight = GuiService:GetGuiInset().Y
	root.Position = UDim2.new(0, left, 0, topbarHeight + math.max(14, getChatBarBottom() + 10))
end

local function setVisible(visible)
	if not gui or not root then
		return
	end

	if isVisible == visible then
		return
	end

	isVisible = visible

	if visible then
		gui.Enabled = true
		root.Visible = true

		TweenService:Create(root, TweenInfo.new(0.16), {
			BackgroundTransparency = 0.04,
		}):Play()
	else
		TweenService:Create(root, TweenInfo.new(0.12), {
			BackgroundTransparency = 1,
		}):Play()

		task.delay(0.13, function()
			if gui and not isVisible then
				gui.Enabled = false
			end
		end)
	end
end

local function updateVisibility()
	local inMenu = player:GetAttribute(ATTR_IN_MENU) == true
	local dead = player:GetAttribute(ATTR_DEAD) == true

	setVisible(not inMenu and not dead)
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
	gui.DisplayOrder = 50
	gui.Parent = playerGui

	root = Instance.new("Frame")
	root.Name = "HealthRoot"
	root.BackgroundColor3 = colors.panel
	root.BackgroundTransparency = 0.04
	root.BorderSizePixel = 0
	root.Size = UDim2.new(0, 285, 0, 78)
	root.Parent = gui
	makeCorner(root, 12)
	makeStroke(root, colors.stroke, 0.25)

	scaleObject = Instance.new("UIScale")
	scaleObject.Name = "ResponsiveScale"
	scaleObject.Scale = 1
	scaleObject.Parent = root

	titleText = makeText(root, "VITALS", 11, true, colors.muted)
	titleText.Position = UDim2.new(0, 14, 0, 7)
	titleText.Size = UDim2.new(0.42, -14, 0, 16)

	statusText = makeText(root, "STABLE", 11, true, colors.healthy)
	statusText.Position = UDim2.new(0.42, 0, 0, 7)
	statusText.Size = UDim2.new(0.58, -14, 0, 16)
	statusText.TextXAlignment = Enum.TextXAlignment.Right

	healthText = makeText(root, "HP 100 / 100", 15, true, colors.text)
	healthText.Position = UDim2.new(0, 14, 0, 29)
	healthText.Size = UDim2.new(1, -28, 0, 20)

	local barBack = Instance.new("Frame")
	barBack.Name = "HealthBarBack"
	barBack.BackgroundColor3 = Color3.fromRGB(35, 35, 44)
	barBack.BorderSizePixel = 0
	barBack.Position = UDim2.new(0, 14, 0, 58)
	barBack.Size = UDim2.new(1, -28, 0, 9)
	barBack.Parent = root
	makeCorner(barBack, 8)

	healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.BackgroundColor3 = colors.healthy
	healthFill.BorderSizePixel = 0
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.Parent = barBack
	makeCorner(healthFill, 8)

	applyResponsiveLayout()
end

local function getHealthColor(percent, injury, bleedingSeverity)
	if injury == "Dead" then
		return colors.critical
	end

	if bleedingSeverity == "Severe" then
		return colors.danger
	end

	if bleedingSeverity == "Moderate" then
		return colors.warning
	end

	if percent <= 0.25 then
		return colors.danger
	end

	if percent <= 0.5 then
		return colors.warning
	end

	return colors.healthy
end

local function getStatusLabel(percent, bleeding, bleedingSeverity, injury, injuryType)
	if bleeding then
		if bleedingSeverity == "Severe" then
			return "BLEEDING: SEVERE", colors.danger
		end

		if bleedingSeverity == "Moderate" then
			return "BLEEDING: MODERATE", colors.warning
		end

		return "BLEEDING: LIGHT", colors.warning
	end

	if injuryType and injuryType ~= "None" then
		return string.upper(tostring(injuryType)), colors.warning
	end

	if injury == "Dead" then
		return "DEAD", colors.critical
	end

	if injury == "Critical" then
		return "CRITICAL", colors.danger
	end

	if injury == "Injured" then
		return "INJURED", colors.warning
	end

	if percent <= 0.25 then
		return "CRITICAL", colors.danger
	end

	if percent <= 0.5 then
		return "INJURED", colors.warning
	end

	return "STABLE", colors.healthy
end

local function updateUi()
	if not gui or not root then
		return
	end

	local health = player:GetAttribute(ATTR_HEALTH) or 100
	local maxHealth = player:GetAttribute(ATTR_MAX_HEALTH) or 100
	local percent = player:GetAttribute(ATTR_HEALTH_PERCENT) or 1
	local bleeding = player:GetAttribute(ATTR_BLEEDING) == true
	local bleedingSeverity = player:GetAttribute(ATTR_BLEEDING_SEVERITY) or "None"
	local injury = player:GetAttribute(ATTR_INJURY) or "Stable"
	local injuryType = player:GetAttribute(ATTR_INJURY_TYPE) or "None"

	percent = math.clamp(percent, 0, 1)

	local healthColor = getHealthColor(percent, injury, bleedingSeverity)
	local statusLabel, statusColor = getStatusLabel(percent, bleeding, bleedingSeverity, injury, injuryType)

	healthText.Text = "HP " .. tostring(health) .. " / " .. tostring(maxHealth)
	statusText.Text = statusLabel
	statusText.TextColor3 = statusColor

	TweenService:Create(healthFill, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(percent, 0, 1, 0),
		BackgroundColor3 = healthColor,
	}):Play()
end

local function connectAttributes()
	local attributes = {
		ATTR_HEALTH,
		ATTR_MAX_HEALTH,
		ATTR_HEALTH_PERCENT,
		ATTR_BLEEDING,
		ATTR_BLEEDING_SEVERITY,
		ATTR_INJURY,
		ATTR_INJURY_TYPE,
		ATTR_DEAD,
		ATTR_IN_MENU,
	}

	for _, attributeName in ipairs(attributes) do
		player:GetAttributeChangedSignal(attributeName):Connect(function()
			updateUi()
			updateVisibility()
		end)
	end
end

local function connectViewport()
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
	end

	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		camera = Workspace.CurrentCamera

		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
			applyResponsiveLayout()
		end
	end)

	pcall(function()
		local chatBar = TextChatService.ChatInputBarConfiguration

		for _, property in ipairs({ "Enabled", "AbsolutePosition", "AbsoluteSize" }) do
			chatBar:GetPropertyChangedSignal(property):Connect(applyResponsiveLayout)
		end
	end)
end

local function start()
	disableDefaultHealth()
	createGui()
	connectAttributes()
	connectViewport()
	updateUi()
	updateVisibility()

	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		disableDefaultHealth()
		updateUi()
		updateVisibility()
	end)
end

task.defer(start)