local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local State = USARF:WaitForChild("State")

local UPDATE_INTERVAL = 0.2

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "USARFDeveloperDiagnostics"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 980
screenGui.Enabled = false
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Name = "DiagnosticsPanel"
frame.AnchorPoint = Vector2.new(1, 0.5)
frame.Position = UDim2.new(1, -18, 0.5, 60)
frame.Size = UDim2.new(0, 320, 0, 190)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
frame.BackgroundTransparency = 0.08
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(154, 108, 255)
stroke.Transparency = 0.35
stroke.Thickness = 1
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 14, 0, 10)
title.Size = UDim2.new(1, -28, 0, 24)
title.Font = Enum.Font.GothamBold
title.Text = "DEV MODE"
title.TextColor3 = Color3.fromRGB(190, 155, 255)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local statusDot = Instance.new("Frame")
statusDot.Name = "StatusDot"
statusDot.AnchorPoint = Vector2.new(1, 0.5)
statusDot.Position = UDim2.new(1, -14, 0, 22)
statusDot.Size = UDim2.new(0, 9, 0, 9)
statusDot.BackgroundColor3 = Color3.fromRGB(75, 220, 110)
statusDot.BorderSizePixel = 0
statusDot.Parent = frame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(1, 0)
statusCorner.Parent = statusDot

local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Position = UDim2.new(0, 14, 0, 37)
divider.Size = UDim2.new(1, -28, 0, 1)
divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
divider.BackgroundTransparency = 0.82
divider.BorderSizePixel = 0
divider.Parent = frame

local body = Instance.new("TextLabel")
body.Name = "Body"
body.BackgroundTransparency = 1
body.Position = UDim2.new(0, 14, 0, 46)
body.Size = UDim2.new(1, -28, 1, -58)
body.Font = Enum.Font.Code
body.TextColor3 = Color3.fromRGB(235, 235, 235)
body.TextSize = 13
body.TextXAlignment = Enum.TextXAlignment.Left
body.TextYAlignment = Enum.TextYAlignment.Top
body.TextWrapped = false
body.Parent = frame

local lastUpdate = 0
local framesThisSecond = 0
local fps = 0
local fpsWindowStarted = os.clock()

local function getCharacterPosition()
	local character = Player.Character

	if not character then
		return "Unavailable"
	end

	local root = character:FindFirstChild("HumanoidRootPart")

	if not root then
		return "Unavailable"
	end

	return string.format(
		"%.1f, %.1f, %.1f",
		root.Position.X,
		root.Position.Y,
		root.Position.Z
	)
end

local function getTeamName()
	local teamName = Player:GetAttribute("USARF_TeamName")

	if teamName and teamName ~= "" then
		return teamName
	end

	if Player.Team then
		return Player.Team.Name
	end

	return "No Team"
end

local function getAdminLevel()
	return tostring(
		Player:GetAttribute("USARF_CmdrAdminLevel")
			or "None"
	)
end

local function getPingMilliseconds()
	local success, result = pcall(function()
		return Player:GetNetworkPing()
	end)

	if not success then
		return 0
	end

	return math.floor((tonumber(result) or 0) * 1000)
end

local function isGameDebugEnabled()
	return State:GetAttribute("USARF_GameDebug") == true
end

local function updateEnabled()
	screenGui.Enabled =
		Player:GetAttribute("USARF_DevMode") == true
end

local function updatePanel()
	local gameDebugEnabled = isGameDebugEnabled()

	statusDot.BackgroundColor3 = gameDebugEnabled
		and Color3.fromRGB(255, 190, 70)
		or Color3.fromRGB(75, 220, 110)

	title.Text = gameDebugEnabled
		and "DEV MODE · GAME DEBUG"
		or "DEV MODE"

	body.Text = table.concat({
		"Position: " .. getCharacterPosition(),
		"Team: " .. getTeamName(),
		"Cmdr: " .. getAdminLevel(),
		"FPS: " .. tostring(fps),
		"Ping: " .. tostring(getPingMilliseconds()) .. " ms",
		"JobId: " .. (
			game.JobId ~= ""
				and game.JobId
				or "Studio"
		),
		"PlaceId: " .. tostring(game.PlaceId),
		"Game Debug: " .. (
			gameDebugEnabled
				and "ON"
				or "OFF"
		),
	}, "\n")
end

_G.USARFToggleDeveloperDiagnostics = function()
	if Player:GetAttribute("USARF_DevMode") ~= true then
		return
	end

	screenGui.Enabled = not screenGui.Enabled
end

Player:GetAttributeChangedSignal(
	"USARF_DevMode"
):Connect(updateEnabled)

State:GetAttributeChangedSignal(
	"USARF_GameDebug"
):Connect(updatePanel)

RunService.RenderStepped:Connect(function()
	framesThisSecond += 1

	local now = os.clock()

	if now - fpsWindowStarted >= 1 then
		fps = math.floor(
			framesThisSecond / (now - fpsWindowStarted)
		)

		framesThisSecond = 0
		fpsWindowStarted = now
	end

	if now - lastUpdate < UPDATE_INTERVAL then
		return
	end

	lastUpdate = now

	if screenGui.Enabled then
		updatePanel()
	end
end)

updateEnabled()
updatePanel()

print("[DeveloperDiagnosticsController] Loaded")