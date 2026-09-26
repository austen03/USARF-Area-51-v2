local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local DeathFolder = Remotes:WaitForChild("Death")

local DeathEvent = DeathFolder:WaitForChild("DeathStateEvent")
local RequestRespawn = DeathFolder:WaitForChild("RequestRespawn")
local RequestReviveWait = DeathFolder:WaitForChild("RequestReviveWait")

local SCREEN_GUI_NAME = "USARF_DeathScreen"
local BLUR_NAME = "USARF_DeathBlur"

local ATTR_DEAD = "USARF_Dead"
local ATTR_DEATH_READY = "USARF_DeathRespawnReady"

local gui
local background
local panel
local scaleObject
local titleLabel
local messageLabel
local timerLabel
local medicalLabel
local respawnButton
local waitButton
local progressBack
local progressFill
local blur

local activeCountdownId = 0
local respawnReady = false
local hiddenGuis = {}

local colors = {
	background = Color3.fromRGB(20, 5, 5),
	panel = Color3.fromRGB(16, 16, 22),
	card = Color3.fromRGB(24, 24, 32),
	stroke = Color3.fromRGB(90, 90, 105),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(180, 180, 190),
	danger = Color3.fromRGB(230, 65, 65),
	success = Color3.fromRGB(55, 214, 104),
	warning = Color3.fromRGB(255, 170, 0),
}

local function setCoreGuiVisible(visible)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, visible)
	end)

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)
end

local function disableResetButton()
	for _ = 1, 10 do
		local success = pcall(function()
			StarterGui:SetCore("ResetButtonCallback", false)
		end)

		if success then
			return
		end

		task.wait(0.25)
	end
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
	stroke.Transparency = transparency or 0.3
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
	label.TextSize = size or 16
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function makeButton(parent, text, backgroundColor)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = backgroundColor or colors.card
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = colors.text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.AutoButtonColor = true
	button.Parent = parent

	makeCorner(button, 10)
	makeStroke(button, colors.stroke, 0.35)

	return button
end

local function tweenObject(object, duration, goal)
	local createdTween = TweenService:Create(
		object,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		goal
	)

	createdTween:Play()
	return createdTween
end

local function getViewportScale()
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)

	if viewport.X <= 900 then
		return 0.82
	end

	if viewport.X <= 1200 then
		return 0.9
	end

	return 1
end

local function applyResponsiveLayout()
	if scaleObject then
		scaleObject.Scale = getViewportScale()
	end
end

local function getOrCreateBlur()
	local existing = Lighting:FindFirstChild(BLUR_NAME)

	if existing and existing:IsA("BlurEffect") then
		return existing
	end

	local newBlur = Instance.new("BlurEffect")
	newBlur.Name = BLUR_NAME
	newBlur.Size = 0
	newBlur.Parent = Lighting

	return newBlur
end

local function hideOtherHud()
	hiddenGuis = {}

	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") and child.Name ~= SCREEN_GUI_NAME then
			if child.Enabled == true then
				hiddenGuis[child] = true
				child.Enabled = false
			end
		end
	end
end

local function restoreOtherHud()
	for screenGui in pairs(hiddenGuis) do
		if screenGui and screenGui.Parent then
			screenGui.Enabled = true
		end
	end

	hiddenGuis = {}
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
	gui.DisplayOrder = 99995
	gui.Enabled = false
	gui.Parent = playerGui

	background = Instance.new("Frame")
	background.Name = "Background"
	background.BackgroundColor3 = colors.background
	background.BackgroundTransparency = 1
	background.BorderSizePixel = 0
	background.Size = UDim2.fromScale(1, 1)
	background.Parent = gui

	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0, 560, 0, 350)
	panel.BackgroundColor3 = colors.panel
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel = 0
	panel.Parent = background

	makeCorner(panel, 16)
	makeStroke(panel, colors.stroke, 1, 1)

	scaleObject = Instance.new("UIScale")
	scaleObject.Name = "ResponsiveScale"
	scaleObject.Scale = 1
	scaleObject.Parent = panel

	titleLabel = makeText(panel, "YOU ARE DEAD", 28, true, colors.danger)
	titleLabel.Position = UDim2.new(0, 34, 0, 28)
	titleLabel.Size = UDim2.new(1, -68, 0, 38)
	titleLabel.TextTransparency = 1

	messageLabel = makeText(panel, "You were killed.", 18, false, colors.text)
	messageLabel.Position = UDim2.new(0, 54, 0, 82)
	messageLabel.Size = UDim2.new(1, -108, 0, 96)
	messageLabel.TextTransparency = 1
	messageLabel.LineHeight = 1.08

	timerLabel = makeText(panel, "Waiting to respawn: 7s", 15, true, colors.warning)
	timerLabel.Position = UDim2.new(0, 44, 0, 186)
	timerLabel.Size = UDim2.new(1, -88, 0, 28)
	timerLabel.TextTransparency = 1

	medicalLabel = makeText(panel, "Medical personnel may revive you before respawn.", 12, false, colors.muted)
	medicalLabel.Position = UDim2.new(0, 44, 0, 214)
	medicalLabel.Size = UDim2.new(1, -88, 0, 24)
	medicalLabel.TextTransparency = 1

	progressBack = Instance.new("Frame")
	progressBack.Name = "ProgressBack"
	progressBack.BackgroundColor3 = Color3.fromRGB(35, 35, 44)
	progressBack.BackgroundTransparency = 1
	progressBack.BorderSizePixel = 0
	progressBack.Position = UDim2.new(0, 54, 0, 252)
	progressBack.Size = UDim2.new(1, -108, 0, 8)
	progressBack.Parent = panel
	makeCorner(progressBack, 8)

	progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.BackgroundColor3 = colors.warning
	progressFill.BackgroundTransparency = 1
	progressFill.BorderSizePixel = 0
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.Parent = progressBack
	makeCorner(progressFill, 8)

	respawnButton = makeButton(panel, "RESPAWN", colors.success)
	respawnButton.Position = UDim2.new(0.5, -190, 1, -58)
	respawnButton.Size = UDim2.new(0, 180, 0, 42)
	respawnButton.Visible = false
	respawnButton.Active = false
	respawnButton.TextTransparency = 1
	respawnButton.BackgroundTransparency = 1

	waitButton = makeButton(panel, "WAIT TO BE REVIVED", colors.card)
	waitButton.Position = UDim2.new(0.5, 10, 1, -58)
	waitButton.Size = UDim2.new(0, 180, 0, 42)
	waitButton.Visible = false
	waitButton.Active = false
	waitButton.TextTransparency = 1
	waitButton.BackgroundTransparency = 1

	respawnButton.MouseButton1Click:Connect(function()
		if not respawnReady then
			return
		end

		respawnButton.Text = "RESPAWNING..."
		respawnButton.Active = false

		local success, result = pcall(function()
			return RequestRespawn:InvokeServer()
		end)

		if not success or not result or result.success ~= true then
			respawnButton.Text = "RESPAWN"
			respawnButton.Active = true
		end
	end)

	waitButton.MouseButton1Click:Connect(function()
		waitButton.Text = "WAITING FOR MEDICAL..."
		waitButton.Active = false
		RequestReviveWait:FireServer()
	end)

	applyResponsiveLayout()
end

local function fadeIn()
	hideOtherHud()
	setCoreGuiVisible(false)

	blur = getOrCreateBlur()
	gui.Enabled = true

	tweenObject(blur, 0.25, {
		Size = 24,
	})

	tweenObject(background, 0.25, {
		BackgroundTransparency = 0.18,
	})

	tweenObject(panel, 0.25, {
		BackgroundTransparency = 0,
	})

	local stroke = panel:FindFirstChildOfClass("UIStroke")
	if stroke then
		tweenObject(stroke, 0.25, {
			Transparency = 0.25,
		})
	end

	for _, object in ipairs({ titleLabel, messageLabel, timerLabel, medicalLabel }) do
		tweenObject(object, 0.25, {
			TextTransparency = 0,
		})
	end

	tweenObject(progressBack, 0.25, {
		BackgroundTransparency = 0,
	})

	tweenObject(progressFill, 0.25, {
		BackgroundTransparency = 0,
	})
end

local function fadeOut()
	activeCountdownId += 1

	if not gui then
		return
	end

	tweenObject(background, 0.2, {
		BackgroundTransparency = 1,
	})

	tweenObject(panel, 0.2, {
		BackgroundTransparency = 1,
	})

	if blur then
		tweenObject(blur, 0.2, {
			Size = 0,
		})
	end

	for _, object in ipairs(panel:GetDescendants()) do
		if object:IsA("TextLabel") or object:IsA("TextButton") then
			tweenObject(object, 0.2, {
				TextTransparency = 1,
			})
		elseif object:IsA("Frame") then
			tweenObject(object, 0.2, {
				BackgroundTransparency = 1,
			})
		elseif object:IsA("UIStroke") then
			tweenObject(object, 0.2, {
				Transparency = 1,
			})
		end
	end

	task.delay(0.22, function()
		if gui then
			gui.Enabled = false
		end

		restoreOtherHud()
		setCoreGuiVisible(true)

		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		end)
	end)
end

local function showButtons()
	respawnButton.Visible = true
	waitButton.Visible = true

	respawnButton.BackgroundTransparency = 1
	waitButton.BackgroundTransparency = 1
	respawnButton.TextTransparency = 1
	waitButton.TextTransparency = 1

	tweenObject(respawnButton, 0.2, {
		BackgroundTransparency = 0,
		TextTransparency = 0,
	})

	tweenObject(waitButton, 0.2, {
		BackgroundTransparency = 0,
		TextTransparency = 0,
	})
end

local function setButtonsReady()
	respawnReady = true

	timerLabel.Text = "Respawn available."
	timerLabel.TextColor3 = colors.success

	progressFill.BackgroundColor3 = colors.success
	progressFill.Size = UDim2.new(1, 0, 1, 0)

	showButtons()

	respawnButton.Active = true
	respawnButton.Text = "RESPAWN"

	waitButton.Active = true
	waitButton.Text = "WAIT TO BE REVIVED"
end

local function setWaitingForRevive()
	waitButton.Text = "WAITING FOR MEDICAL..."
	waitButton.Active = false
	medicalLabel.Text = "Revive request sent. Medical personnel can respond when available."
	medicalLabel.TextColor3 = colors.success
end

local function startCountdown(seconds)
	activeCountdownId += 1

	local thisCountdownId = activeCountdownId
	respawnReady = false

	respawnButton.Visible = false
	respawnButton.Active = false
	waitButton.Visible = false
	waitButton.Active = false

	timerLabel.TextColor3 = colors.warning
	progressFill.BackgroundColor3 = colors.warning
	progressFill.Size = UDim2.new(0, 0, 1, 0)

	task.spawn(function()
		for remaining = seconds, 0, -1 do
			if thisCountdownId ~= activeCountdownId then
				return
			end

			local elapsed = seconds - remaining
			local percent = 0

			if seconds > 0 then
				percent = math.clamp(elapsed / seconds, 0, 1)
			end

			tweenObject(progressFill, 0.18, {
				Size = UDim2.new(percent, 0, 1, 0),
			})

			if remaining > 0 then
				timerLabel.Text = "Waiting to respawn: " .. tostring(remaining) .. "s"
			else
				setButtonsReady()
			end

			task.wait(1)
		end
	end)
end

local function showDeathScreen(payload)
	payload = payload or {}

	messageLabel.Text = payload.message or "You were killed."

	local medicalOnline = tonumber(payload.medicalOnline) or 0

	if medicalOnline > 0 then
		medicalLabel.Text = "Medical personnel online. You may wait to be revived."
	else
		medicalLabel.Text = "No medical personnel online. Respawn will be available shortly."
	end

	medicalLabel.TextColor3 = colors.muted

	fadeIn()
	startCountdown(tonumber(payload.delaySeconds) or 7)
end

local function hideDeathScreen()
	fadeOut()
end

local function handleDeathEvent(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.action == "ShowDeathScreen" then
		showDeathScreen(payload)
	elseif payload.action == "RespawnReady" then
		setButtonsReady()
	elseif payload.action == "WaitingForRevive" then
		setWaitingForRevive()
	elseif payload.action == "HideDeathScreen" then
		hideDeathScreen()
	end
end

local function start()
	createGui()

	task.spawn(disableResetButton)

	DeathEvent.OnClientEvent:Connect(handleDeathEvent)

	player:GetAttributeChangedSignal(ATTR_DEAD):Connect(function()
		if player:GetAttribute(ATTR_DEAD) ~= true then
			hideDeathScreen()
		end
	end)

	player:GetAttributeChangedSignal(ATTR_DEATH_READY):Connect(function()
		if player:GetAttribute(ATTR_DEATH_READY) == true and gui and gui.Enabled then
			setButtonsReady()
		end
	end)

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
end

task.defer(start)