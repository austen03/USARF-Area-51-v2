local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Gui = PlayerGui:WaitForChild("USARFGui")

local TopBar = Gui:WaitForChild("TopBar")
local SettingsButton = TopBar:WaitForChild("SettingsButton")
local AnnouncementButton = TopBar:WaitForChild("AnnouncementButton")

local Popups = Gui:WaitForChild("Popups")
-- Popups is a transparent, non-interactive container; if it is hidden none of its panels can show.
Popups.Visible = true
local SettingsPanel = Popups:WaitForChild("SettingsPanel")
local CloseButton = SettingsPanel:WaitForChild("CloseButton")

local ContentFrame = SettingsPanel:WaitForChild("ContentFrame")

local NotificationsSection = ContentFrame:WaitForChild("NotificationsSection")
local AudioSection = ContentFrame:WaitForChild("AudioSection")
local InterfaceSection = ContentFrame:WaitForChild("InterfaceSection")

local SETTINGS = {
	Announcements = true,
	DeploymentNotifications = true,
	PopupNotifications = true,
	RadioVisible = true,

	MenuSounds = true,
	NotificationSounds = true,
	AmbientAudio = true,

	CompactUI = false,
	ShowTutorials = true,
	DepartmentTips = true,
}

_G.USARFSettings = SETTINGS

local settingsScale = SettingsPanel:FindFirstChild("UIScale")
if not settingsScale then
	settingsScale = Instance.new("UIScale")
	settingsScale.Parent = SettingsPanel
end

local function applyIconLayout()
	AnnouncementButton.AnchorPoint = Vector2.new(0, 0)
	AnnouncementButton.Position = UDim2.new(0, 160, 0, 14)
	AnnouncementButton.Size = UDim2.new(0, 42, 0, 42)

	SettingsButton.AnchorPoint = Vector2.new(0, 0)
	SettingsButton.Position = UDim2.new(0, 210, 0, 14)
	SettingsButton.Size = UDim2.new(0, 42, 0, 42)
end

local function applyLayout()
	settingsScale.Scale = 1

	SettingsPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	SettingsPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	SettingsPanel.Size = UDim2.new(0, 680, 0, 480)

	applyIconLayout()
end

local function playMenuClick()
	if _G.USARFPlaySound then
		_G.USARFPlaySound("MenuClick", "MenuSounds")
	end
end

local function updateToggle(button, enabled)
	local displayName = button:GetAttribute("DisplayName") or button.Name
	button.Text = (enabled and "☑ " or "☐ ") .. displayName
end

local function applySettings()
	_G.USARFSettings = SETTINGS

	if _G.USARFUpdateAnnouncementBadge then
		_G.USARFUpdateAnnouncementBadge()
	end

	if _G.USARFApplyCompactUI then
		_G.USARFApplyCompactUI(SETTINGS.CompactUI)
	end

	Player:SetAttribute("USARF_RadioHidden", not SETTINGS.RadioVisible)

	if _G.USARFUpdateTopbarVisibility then
		_G.USARFUpdateTopbarVisibility()
	end

	applyIconLayout()
end

local function registerToggle(button, key, displayName)
	button:SetAttribute("DisplayName", displayName)
	updateToggle(button, SETTINGS[key])

	button.MouseButton1Click:Connect(function()
		playMenuClick()

		SETTINGS[key] = not SETTINGS[key]

		updateToggle(button, SETTINGS[key])
		applySettings()

		print("[USARF Settings]", key, SETTINGS[key])
	end)
end

registerToggle(NotificationsSection.AlertToggle, "Announcements", "Announcements")
registerToggle(NotificationsSection.DeploymentToggle, "DeploymentNotifications", "Deployment Notifications")
registerToggle(NotificationsSection.PopupToggle, "PopupNotifications", "Popup Notifications")

registerToggle(AudioSection.MenuSoundsToggle, "MenuSounds", "Menu Sounds")
registerToggle(AudioSection.NotificationSoundsToggle, "NotificationSounds", "Notification Sounds")
registerToggle(AudioSection.AmbientAudioToggle, "AmbientAudio", "Ambient Audio")

registerToggle(InterfaceSection.CompactUIToggle, "CompactUI", "Compact UI")
registerToggle(InterfaceSection.ShowTutorialsToggle, "ShowTutorials", "Show Tutorials")
registerToggle(InterfaceSection.DepartmentTipsToggle, "DepartmentTips", "Department Tips")
registerToggle(InterfaceSection.RadioToggle, "RadioVisible", "Radio HUD")

local function closePanel(playSound)
	if playSound ~= false then
		playMenuClick()
	end

	SettingsPanel.Visible = false
end

local function openPanel()
	playMenuClick()

	if SettingsPanel.Visible then
		closePanel(false)
		return
	end

	if _G.USARFCloseAnnouncements then
		_G.USARFCloseAnnouncements(false)
	end

	applyLayout()
	SettingsPanel.Visible = true
end

local function togglePanel()
	if SettingsPanel.Visible then
		closePanel()
	else
		openPanel()
	end
end

SettingsButton.MouseButton1Click:Connect(togglePanel)

CloseButton.MouseButton1Click:Connect(function()
	closePanel()
end)

_G.USARFToggleSettings = togglePanel
_G.USARFOpenSettings = openPanel
_G.USARFCloseSettings = closePanel

SettingsPanel.Visible = false

applyLayout()
applySettings()

print("USARF SettingsController initialized")