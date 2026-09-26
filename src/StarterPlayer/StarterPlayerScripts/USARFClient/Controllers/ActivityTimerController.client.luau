local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local GetActivitySessionRemote = Remotes:WaitForChild("GetActivitySession")

local Gui = PlayerGui:WaitForChild("USARFGui")

local MIN_SESSION_SECONDS = 30

local INCOMPLETE_COLOR = Color3.fromRGB(80, 0, 35)
local COMPLETE_COLOR = Color3.fromRGB(25, 25, 25)

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Name = "ActivityTimer"
TimerLabel.AnchorPoint = Vector2.new(1, 0)

TimerLabel.Position = UDim2.new(1, -120, 0, 20)
TimerLabel.Size = UDim2.new(0, 90, 0, 32)

TimerLabel.BackgroundColor3 = INCOMPLETE_COLOR
TimerLabel.BackgroundTransparency = 0.15
TimerLabel.BorderSizePixel = 0

TimerLabel.Text = "00m 00s"
TimerLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
TimerLabel.TextSize = 13
TimerLabel.Font = Enum.Font.GothamMedium

TimerLabel.Visible = false
TimerLabel.Parent = Gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = TimerLabel



local currentSession = nil

local function formatDuration(seconds)
	seconds = math.max(0, math.floor(seconds))

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	if hours > 0 then
		return string.format("%02dh %02dm", hours, minutes)
	end

	return string.format("%02dm %02ds", minutes, secs)
end

local function loadSession()
	local success, result = pcall(function()
		return GetActivitySessionRemote:InvokeServer()
	end)

	if not success then
		currentSession = nil
		TimerLabel.Visible = false
		return
	end

	if not result then
		currentSession = nil
		TimerLabel.Visible = false
		return
	end

	if result.tracking ~= true then
		currentSession = nil
		TimerLabel.Visible = false
		return
	end

	currentSession = result
	TimerLabel.Visible = true
end

Player:GetAttributeChangedSignal("USARF_TeamKey"):Connect(function()
	task.wait(0.25)
	loadSession()
end)

Player:GetAttributeChangedSignal("USARF_TeamName"):Connect(function()
	task.wait(0.25)
	loadSession()
end)

task.spawn(function()
	while true do
		task.wait(1)

		if currentSession and currentSession.startedAt then
			local elapsed = os.time() - currentSession.startedAt

			TimerLabel.Text = formatDuration(elapsed)
			TimerLabel.Visible = true

			if elapsed >= MIN_SESSION_SECONDS then
				TimerLabel.BackgroundColor3 = COMPLETE_COLOR
			else
				TimerLabel.BackgroundColor3 = INCOMPLETE_COLOR
			end
		else
			TimerLabel.Visible = false
		end
	end
end)

task.delay(2, loadSession)

print("USARF ActivityTimerController initialized")