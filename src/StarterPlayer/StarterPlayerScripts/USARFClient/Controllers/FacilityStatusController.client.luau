local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Gui = Player.PlayerGui:WaitForChild("USARFGui")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Shared = USARF:WaitForChild("Shared")
local FacilityState = Shared:WaitForChild("FacilityState")
local Remotes = USARF:WaitForChild("Remotes")

local FacilityStatusRemote = Remotes:FindFirstChild("FacilityStatus")

local LockdownLevelValue = FacilityState:WaitForChild("LockdownLevel")
local LockdownActiveValue = FacilityState:WaitForChild("LockdownActive")
local AlertLevelValue = FacilityState:WaitForChild("AlertLevel")

local RiotActiveValue = FacilityState:WaitForChild("RiotActive")
local RiotStageValue = FacilityState:WaitForChild("RiotStage")
local RiotEndsAtValue = FacilityState:WaitForChild("RiotEndsAt")

local TopBar = Gui:WaitForChild("TopBar")
local Banner = TopBar:WaitForChild("FacilityStatusBanner")
local Label = Banner:WaitForChild("StatusLabel")
local SubtitleLabel = Banner:WaitForChild("SubtitleLabel")
local Stroke = Banner:FindFirstChildWhichIsA("UIStroke")

local MainMenu = Gui:FindFirstChild("MainMenu")

local flashing = false
local countdownToken = 0

local STATUS_STYLES = {
	NORMAL = {
		text = "NORMAL OPERATIONS",
		subtitle = "Facility status normal.",
		color = Color3.fromRGB(60, 180, 75),
		stroke = Color3.fromRGB(60, 180, 75),
		flash = false,
	},

	YELLOW = {
		text = "YELLOW ALERT",
		subtitle = "Elevated security posture.",
		color = Color3.fromRGB(255, 200, 0),
		stroke = Color3.fromRGB(255, 200, 0),
		flash = false,
	},

	LOCKDOWN = {
		text = "LOCKDOWN",
		subtitle = "Security lockdown active.",
		color = Color3.fromRGB(220, 60, 60),
		stroke = Color3.fromRGB(220, 60, 60),
		flash = false,
	},

	BREACH = {
		text = "CONTAINMENT BREACH",
		subtitle = "Containment failure detected.",
		color = Color3.fromRGB(255, 40, 40),
		stroke = Color3.fromRGB(255, 40, 40),
		flash = true,
	},

	RIOT = {
		text = "RIOT ACTIVE",
		subtitle = "Test Subject riot in progress.",
		color = Color3.fromRGB(255, 80, 80),
		stroke = Color3.fromRGB(255, 60, 60),
		flash = true,
	},

	MAJORRIOT = {
		text = "MAJOR RIOT",
		subtitle = "Major Test Subject riot in progress.",
		color = Color3.fromRGB(180, 0, 255),
		stroke = Color3.fromRGB(180, 0, 255),
		flash = true,
	},

	EVACUATION = {
		text = "SITE EVACUATION",
		subtitle = "Evacuation procedures active.",
		color = Color3.fromRGB(255, 120, 40),
		stroke = Color3.fromRGB(255, 120, 40),
		flash = false,
	},
}

local function formatTime(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))

	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60

	return string.format("%02d:%02d", minutes, secs)
end

local function isGuiObjectVisible(obj)
	return obj and obj:IsA("GuiObject") and obj.Visible == true
end

local function getLoadingVisible()
	local loadingScreen = Gui:FindFirstChild("LoadingScreen")

	if isGuiObjectVisible(loadingScreen) then
		return true
	end

	return Player:GetAttribute("USARF_Loading") == true
end

local function getMainMenuVisible()
	MainMenu = MainMenu or Gui:FindFirstChild("MainMenu")

	if isGuiObjectVisible(MainMenu) then
		return true
	end

	return Player:GetAttribute("USARF_InMenu") ~= false
end

local function updateBannerVisibility()
	local inMenu = Player:GetAttribute("USARF_InMenu")

	if inMenu == nil then
		inMenu = true
	end

	local loadingVisible = getLoadingVisible()
	local menuVisible = getMainMenuVisible()

	Banner.Visible = not loadingVisible and not menuVisible and inMenu == false
end

local function stopFlash()
	flashing = false

	Label.TextTransparency = 0
	SubtitleLabel.TextTransparency = 0
	Banner.BackgroundTransparency = 0.15
end

local function startFlash()
	if flashing then
		return
	end

	flashing = true

	task.spawn(function()
		while flashing do
			TweenService:Create(Label, TweenInfo.new(0.35), {
				TextTransparency = 0.45,
			}):Play()

			TweenService:Create(SubtitleLabel, TweenInfo.new(0.35), {
				TextTransparency = 0.55,
			}):Play()

			TweenService:Create(Banner, TweenInfo.new(0.35), {
				BackgroundTransparency = 0.35,
			}):Play()

			task.wait(0.4)

			TweenService:Create(Label, TweenInfo.new(0.35), {
				TextTransparency = 0,
			}):Play()

			TweenService:Create(SubtitleLabel, TweenInfo.new(0.35), {
				TextTransparency = 0,
			}):Play()

			TweenService:Create(Banner, TweenInfo.new(0.35), {
				BackgroundTransparency = 0.05,
			}):Play()

			task.wait(0.4)
		end
	end)
end

local function applyStatusVisual(status, subtitleOverride)
	status = string.upper(tostring(status or "NORMAL"))

	local style = STATUS_STYLES[status] or STATUS_STYLES.NORMAL

	stopFlash()

	Label.Text = style.text
	Label.TextColor3 = style.color

	SubtitleLabel.Text = subtitleOverride or style.subtitle
	SubtitleLabel.TextColor3 = Color3.fromRGB(210, 210, 210)

	if Stroke then
		Stroke.Color = style.stroke
	end

	if style.flash then
		startFlash()
	end

	updateBannerVisibility()
end

local function setStatus(status, subtitleOverride)
	countdownToken += 1
	applyStatusVisual(status, subtitleOverride)
end

local function setRiotStatus()
	countdownToken += 1

	local token = countdownToken
	local stage = RiotStageValue.Value
	local endsAt = RiotEndsAtValue.Value
	local statusName = stage >= 4 and "MAJORRIOT" or "RIOT"

	local function updateText()
		local remaining = math.max(0, endsAt - os.time())

		if remaining > 0 then
			applyStatusVisual(
				statusName,
				"Test Subject riot active. Time remaining: " .. formatTime(remaining)
			)
		else
			applyStatusVisual(
				statusName,
				"Test Subject riot active."
			)
		end
	end

	updateText()

	task.spawn(function()
		while token == countdownToken and RiotActiveValue.Value == true do
			local remaining = math.max(0, endsAt - os.time())

			if remaining > 0 then
				SubtitleLabel.Text = "Test Subject riot active. Time remaining: " .. formatTime(remaining)
			else
				SubtitleLabel.Text = "Test Subject riot active."
			end

			task.wait(1)
		end
	end)
end

local function refreshFromFacilityState()
	if RiotActiveValue.Value == true then
		setRiotStatus()
		return
	end

	if LockdownActiveValue.Value == true then
		local level = LockdownLevelValue.Value

		if level >= 3 then
			setStatus("LOCKDOWN", "Full facility lockdown active.")
		elseif level >= 1 then
			setStatus("YELLOW", tostring(AlertLevelValue.Value or "Security alert active."))
		else
			setStatus("NORMAL")
		end

		return
	end

	setStatus("NORMAL")
end

_G.USARFSetFacilityStatus = setStatus

if FacilityStatusRemote then
	FacilityStatusRemote.OnClientEvent:Connect(function(status, subtitle)
		setStatus(status, subtitle)
	end)
end

RiotActiveValue.Changed:Connect(refreshFromFacilityState)
RiotStageValue.Changed:Connect(refreshFromFacilityState)
RiotEndsAtValue.Changed:Connect(refreshFromFacilityState)

LockdownLevelValue.Changed:Connect(refreshFromFacilityState)
LockdownActiveValue.Changed:Connect(refreshFromFacilityState)
AlertLevelValue.Changed:Connect(refreshFromFacilityState)

Player:GetAttributeChangedSignal("USARF_InMenu"):Connect(updateBannerVisibility)
Player:GetAttributeChangedSignal("USARF_Loading"):Connect(updateBannerVisibility)

if MainMenu and MainMenu:IsA("GuiObject") then
	MainMenu:GetPropertyChangedSignal("Visible"):Connect(updateBannerVisibility)
end

Gui.ChildAdded:Connect(function(child)
	if child.Name == "MainMenu" and child:IsA("GuiObject") then
		MainMenu = child
		child:GetPropertyChangedSignal("Visible"):Connect(updateBannerVisibility)
		updateBannerVisibility()
	elseif child.Name == "LoadingScreen" and child:IsA("GuiObject") then
		child:GetPropertyChangedSignal("Visible"):Connect(updateBannerVisibility)
		updateBannerVisibility()
	end
end)

local existingLoadingScreen = Gui:FindFirstChild("LoadingScreen")
if existingLoadingScreen and existingLoadingScreen:IsA("GuiObject") then
	existingLoadingScreen:GetPropertyChangedSignal("Visible"):Connect(updateBannerVisibility)
end

refreshFromFacilityState()
updateBannerVisibility()

print("USARF FacilityStatusController initialized")