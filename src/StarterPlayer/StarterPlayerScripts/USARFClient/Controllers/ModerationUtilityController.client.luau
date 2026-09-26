local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local REMOTE_NAME = "ModerationUtilityRemote"

local remote = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME):WaitForChild(REMOTE_NAME)

local viewingTarget = nil
local trackingTarget = nil

local trackConnection = nil
local trackFolder = nil
local trackBeam = nil
local selfAttachment = nil
local targetAttachment = nil
local trackBillboard = nil

local TRACK_COLOR = Color3.fromRGB(255, 215, 80)

local function getPlayerByUserId(userId)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == userId then
			return player
		end
	end

	return nil
end

local function getCharacterHumanoid(player)
	if not player or not player.Character then
		return nil
	end

	return player.Character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(player)
	if not player or not player.Character then
		return nil
	end

	return player.Character:FindFirstChild("HumanoidRootPart")
end

local function viewPlayer(target)
	local humanoid = getCharacterHumanoid(target)

	if not humanoid then
		return
	end

	viewingTarget = target
	camera.CameraSubject = humanoid
end

local function unview()
	viewingTarget = nil

	local humanoid = getCharacterHumanoid(localPlayer)

	if humanoid then
		camera.CameraSubject = humanoid
	end
end

local function clearTrackObjects()
	if trackConnection then
		trackConnection:Disconnect()
		trackConnection = nil
	end

	if trackFolder then
		trackFolder:Destroy()
		trackFolder = nil
	end

	if selfAttachment then
		selfAttachment:Destroy()
		selfAttachment = nil
	end

	if targetAttachment then
		targetAttachment:Destroy()
		targetAttachment = nil
	end

	trackBeam = nil
	trackBillboard = nil
end

local function stopTracking()
	trackingTarget = nil
	clearTrackObjects()
end

local function createTrackObjects(target)
	clearTrackObjects()

	local myRoot = getRoot(localPlayer)
	local targetRoot = getRoot(target)

	if not myRoot or not targetRoot then
		return false
	end

	trackFolder = Instance.new("Folder")
	trackFolder.Name = "USARFTrackObjects"
	trackFolder.Parent = workspace

	selfAttachment = Instance.new("Attachment")
	selfAttachment.Name = "USARFTrackSelfAttachment"
	selfAttachment.Position = Vector3.new(0, 1.5, 0)
	selfAttachment.Parent = myRoot

	targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = "USARFTrackTargetAttachment"
	targetAttachment.Position = Vector3.new(0, 1.5, 0)
	targetAttachment.Parent = targetRoot

	trackBeam = Instance.new("Beam")
	trackBeam.Name = "USARFTrackBeam"
	trackBeam.Attachment0 = selfAttachment
	trackBeam.Attachment1 = targetAttachment
	trackBeam.Width0 = 0.18
	trackBeam.Width1 = 0.06
	trackBeam.FaceCamera = true
	trackBeam.LightEmission = 0.55
	trackBeam.LightInfluence = 0
	trackBeam.Color = ColorSequence.new(TRACK_COLOR)
	trackBeam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.65, 0.2),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	trackBeam.Parent = trackFolder

	trackBillboard = Instance.new("BillboardGui")
	trackBillboard.Name = "USARFTrackBillboard"
	trackBillboard.Adornee = targetRoot
	trackBillboard.Size = UDim2.new(0, 220, 0, 34)
	trackBillboard.StudsOffsetWorldSpace = Vector3.new(0, 5.25, 0)
	trackBillboard.AlwaysOnTop = true
	trackBillboard.LightInfluence = 0
	trackBillboard.MaxDistance = 10000
	trackBillboard.Parent = trackFolder

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	label.BackgroundTransparency = 0.15
	label.BorderSizePixel = 0
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = TRACK_COLOR
	label.TextStrokeTransparency = 0.35
	label.TextSize = 15
	label.TextWrapped = true
	label.Text = target.Name
	label.Parent = trackBillboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.Color = TRACK_COLOR
	stroke.Transparency = 0.25
	stroke.Thickness = 1
	stroke.Parent = label

	return true
end

local function startTracking(target)
	if not target then
		return
	end

	trackingTarget = target

	if not createTrackObjects(target) then
		return
	end

	trackConnection = RunService.RenderStepped:Connect(function()
		if not trackingTarget or not trackingTarget.Parent then
			stopTracking()
			return
		end

		local myRoot = getRoot(localPlayer)
		local targetRoot = getRoot(trackingTarget)

		if not myRoot or not targetRoot then
			createTrackObjects(trackingTarget)
			return
		end

		if trackBillboard and trackBillboard:FindFirstChild("Label") then
			trackBillboard.Label.Text = trackingTarget.Name
		end
	end)
end

local function createWarnGui()
	local existing = playerGui:FindFirstChild("USARFWarnPopup")
	if existing then
		return existing
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "USARFWarnPopup"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0, 470, 0, 220)
	frame.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 210, 90)
	stroke.Transparency = 0.25
	stroke.Thickness = 1
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 34)
	title.Font = Enum.Font.GothamBold
	title.Text = "⚠ GAME WARNING"
	title.TextColor3 = Color3.fromRGB(255, 226, 120)
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTransparency = 1
	title.Parent = frame

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.new(0, 0, 0, 46)
	body.Size = UDim2.new(1, 0, 0, 94)
	body.Font = Enum.Font.Gotham
	body.TextColor3 = Color3.fromRGB(255, 255, 255)
	body.TextSize = 16
	body.TextWrapped = true
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.RichText = true
	body.TextTransparency = 1
	body.Parent = frame

	local button = Instance.new("TextButton")
	button.Name = "Acknowledge"
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, 0)
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BackgroundColor3 = Color3.fromRGB(255, 190, 70)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = "I ACKNOWLEDGE"
	button.TextColor3 = Color3.fromRGB(20, 20, 20)
	button.TextSize = 15
	button.TextTransparency = 1
	button.Parent = frame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = button

	button.MouseButton1Click:Connect(function()
		local tout = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		TweenService:Create(frame, tout, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(title, tout, { TextTransparency = 1 }):Play()
		TweenService:Create(body, tout, { TextTransparency = 1 }):Play()
		TweenService:Create(button, tout, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()

		task.wait(0.2)
		frame.Visible = false
	end)

	return gui
end

local function showWarning(payload)
	local gui = createWarnGui()
	local frame = gui.Frame
	local title = frame.Title
	local body = frame.Body
	local button = frame.Acknowledge

	local timestamp = tonumber(payload.time) or os.time()
	local timeText = os.date("%I:%M:%S %p", timestamp)

	title.Text = payload.title or "⚠ GAME WARNING"

	body.Text = string.format(
		"<b>Time:</b> %s\n<b>Reason:</b> %s\n<b>Case:</b> %s",
		timeText,
		tostring(payload.reason or "No reason provided."),
		tostring(payload.caseId or "N/A")
	)

	frame.Visible = true
	frame.BackgroundTransparency = 1
	title.TextTransparency = 1
	body.TextTransparency = 1
	button.BackgroundTransparency = 1
	button.TextTransparency = 1

	local tin = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	TweenService:Create(frame, tin, { BackgroundTransparency = 0.04 }):Play()
	TweenService:Create(title, tin, { TextTransparency = 0 }):Play()
	TweenService:Create(body, tin, { TextTransparency = 0 }):Play()
	TweenService:Create(button, tin, { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
end

remote.OnClientEvent:Connect(function(action, payload)
	payload = payload or {}

	if action == "View" then
		local target = getPlayerByUserId(payload.targetUserId)

		if target then
			viewPlayer(target)
		end
	elseif action == "Unview" then
		unview()
	elseif action == "Track" then
		local target = getPlayerByUserId(payload.targetUserId)

		if target then
			startTracking(target)
		end
	elseif action == "Untrack" then
		stopTracking()
	elseif action == "WarnPopup" then
		showWarning(payload)
	end
end)

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)

	if not viewingTarget then
		unview()
	end

	if trackingTarget then
		task.wait(0.5)
		createTrackObjects(trackingTarget)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if trackingTarget == player then
		stopTracking()
	end
end)

print("[ModerationUtilityController] Loaded")