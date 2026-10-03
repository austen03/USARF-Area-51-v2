local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Gui = PlayerGui:WaitForChild("USARFGui")
local TopBar = Gui:WaitForChild("TopBar")

local Icon = require(ReplicatedStorage:WaitForChild("TopbarPlus"))

local CMDR_ICON_IMAGE = "rbxassetid://83689392665917"

local OLD_BUTTONS = {
	"AnnouncementButton",
	"SettingsButton",
	"RadioButton",
	"ReturnToMenuButton",
}

local function hideOldButtons()
	for _, name in ipairs(OLD_BUTTONS) do
		local button = TopBar:FindFirstChild(name)

		if button and button:IsA("GuiObject") then
			button.Visible = false
			button.Active = false
			button.Selectable = false
		end
	end
end

hideOldButtons()
RunService.RenderStepped:Connect(hideOldButtons)

local function isInMenuOrLoading()
	local loading = Gui:FindFirstChild("LoadingScreen")
	local menu = Gui:FindFirstChild("MainMenu")

	return (loading and loading.Visible)
		or (menu and menu.Visible)
		or Player:GetAttribute("USARF_Loading") == true
		or Player:GetAttribute("USARF_InMenu") ~= false
end

local function hasCmdrAccess()
	local value = tonumber(Player:GetAttribute("USARF_CmdrAdminLevelValue")) or 0

	local level = tostring(Player:GetAttribute("USARF_CmdrAdminLevel") or "None")

	return value >= 1
		or Player:GetAttribute("USARF_CmdrQA") == true
		or level == "Training"
		or level == "VPOTUS_POTUS"
		or level == "Moderator"
		or level == "Administrator"
		or level == "Developer"
		or level == "Owner"
end

local announcementsIcon = Icon.new()
	:setName("USARF_Announcements")
	:setLabel("🔔")
	:setCaption("Announcements")
	:setOrder(1)
	:autoDeselect(false)

local settingsIcon =
	Icon.new():setName("USARF_Settings"):setLabel("⚙"):setCaption("Settings"):setOrder(2):autoDeselect(false)

local radioIcon = Icon.new():setName("USARF_Radio"):setLabel("▦"):setCaption("Radio"):setOrder(3):autoDeselect(false)

local clansIcon =
	Icon.new():setName("USARF_Clans"):setLabel("Clans"):setCaption("Clans"):setOrder(4):autoDeselect(false)

local cmdrIcon = Icon.new()
	:setName("USARF_Cmdr")
	:setImage(CMDR_ICON_IMAGE)
	:setLabel("Cmdr")
	:setCaption("Open Cmdr")
	:setOrder(5)
	:autoDeselect(false)

local devModeIcon = Icon.new()
	:setName("USARF_DevMode")
	:setLabel("DEV")
	:setCaption("Toggle Developer Diagnostics")
	:setOrder(6)
	:autoDeselect(false)

local covertIcon = Icon.new()
	:setName("USARF_Covert")
	:setLabel("Covert")
	:setCaption("Covert Operations")
	:setOrder(7)
	:autoDeselect(false)

local menuIcon = Icon.new()
	:setName("USARF_Menu")
	:setLabel("Menu")
	:setCaption("Return to Menu")
	:setOrder(99)
	:align("Right")
	:oneClick(true)

local function updateTopbarVisibility()
	hideOldButtons()

	local hidden = isInMenuOrLoading()
	local settings = _G.USARFSettings

	announcementsIcon:setEnabled(not hidden and (not settings or settings.Announcements ~= false))

	settingsIcon:setEnabled(not hidden)

	radioIcon:setEnabled(not hidden and Player:GetAttribute("USARF_RadioHidden") ~= true)

	clansIcon:setEnabled(not hidden)

	cmdrIcon:setEnabled(not hidden and hasCmdrAccess())

	devModeIcon:setEnabled(not hidden and Player:GetAttribute("USARF_DevMode") == true)

	covertIcon:setEnabled(not hidden and _G.USARFCovertAvailable == true)

	menuIcon:setEnabled(not hidden)
end

local function updateAnnouncementBadge(count)
	count = tonumber(count) or 0

	if count > 0 then
		announcementsIcon:setLabel("🔔 " .. tostring(count))
	else
		announcementsIcon:setLabel("🔔")
	end
end

local function safeCall(globalName)
	local callback = _G[globalName]

	if typeof(callback) == "function" then
		callback()
	else
		warn("[USARFTopbarController] Missing global:", globalName)
	end
end

announcementsIcon.selected:Connect(function()
	if _G.USARFToggleAnnouncements then
		_G.USARFToggleAnnouncements()
	else
		safeCall("USARFOpenAnnouncements")
	end

	announcementsIcon:deselect()
end)

settingsIcon.selected:Connect(function()
	if _G.USARFToggleSettings then
		_G.USARFToggleSettings()
	else
		safeCall("USARFOpenSettings")
	end

	settingsIcon:deselect()
end)

radioIcon.selected:Connect(function()
	safeCall("USARFToggleRadio")
	radioIcon:deselect()
end)

clansIcon.selected:Connect(function()
	safeCall("USARFToggleClans")
	clansIcon:deselect()
end)

cmdrIcon.selected:Connect(function()
	safeCall("USARFToggleCmdr")
	cmdrIcon:deselect()
end)

devModeIcon.selected:Connect(function()
	safeCall("USARFToggleDeveloperDiagnostics")
	devModeIcon:deselect()
end)

covertIcon.selected:Connect(function()
	safeCall("USARFToggleCovert")
	covertIcon:deselect()
end)

menuIcon.selected:Connect(function()
	safeCall("USARFStartReturnToMenu")
	menuIcon:deselect()
end)

_G.USARFUpdateTopbarVisibility = updateTopbarVisibility
_G.USARFSetAnnouncementTopbarBadge = updateAnnouncementBadge

_G.USARFSetMenuTopbarLabel = function(text)
	menuIcon:setLabel(text or "Menu")
end

Player:GetAttributeChangedSignal("USARF_InMenu"):Connect(updateTopbarVisibility)

Player:GetAttributeChangedSignal("USARF_Loading"):Connect(updateTopbarVisibility)

Player:GetAttributeChangedSignal("USARF_RadioHidden"):Connect(updateTopbarVisibility)

Player:GetAttributeChangedSignal("USARF_CmdrAdminLevel"):Connect(updateTopbarVisibility)

Player:GetAttributeChangedSignal("USARF_CmdrAdminLevelValue"):Connect(updateTopbarVisibility)

Player:GetAttributeChangedSignal("USARF_CmdrQA"):Connect(updateTopbarVisibility)

Player:GetAttributeChangedSignal("USARF_DevMode"):Connect(updateTopbarVisibility)

local mainMenu = Gui:FindFirstChild("MainMenu")

if mainMenu then
	mainMenu:GetPropertyChangedSignal("Visible"):Connect(updateTopbarVisibility)
end

local loadingScreen = Gui:FindFirstChild("LoadingScreen")

if loadingScreen then
	loadingScreen:GetPropertyChangedSignal("Visible"):Connect(updateTopbarVisibility)
end

task.defer(updateTopbarVisibility)

print("USARF TopbarController initialized")
