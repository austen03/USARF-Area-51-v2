local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local GetAnnouncementsRemote = Remotes:WaitForChild("GetAnnouncements")

local Gui = PlayerGui:WaitForChild("USARFGui")
local Popups = Gui:WaitForChild("Popups")

Popups.Visible = true
local TopBar = Gui:WaitForChild("TopBar")

local AnnouncementPanel = Popups:WaitForChild("AnnouncementPanel")
local CloseButton = AnnouncementPanel:WaitForChild("CloseButton")
local ContentFrame = AnnouncementPanel:WaitForChild("ContentFrame")
local Template = ContentFrame:WaitForChild("AnnouncementTemplate")

local AnnouncementButton = TopBar:WaitForChild("AnnouncementButton")
local Badge = AnnouncementButton:WaitForChild("Badge")
local CountLabel = Badge:WaitForChild("CountLabel")

local CATEGORY_COLORS = {
	General = Color3.fromRGB(70, 70, 70),
	Facility = Color3.fromRGB(40, 90, 180),
	Update = Color3.fromRGB(200, 140, 20),
	Department = Color3.fromRGB(120, 60, 180),
	Emergency = Color3.fromRGB(180, 40, 40),
}

local ANNOUNCEMENTS = {}
local readAnnouncements = {}

local EXPIRY_CHECK_SECONDS = 15

local function withExpiry(announcement, expiresIn)
	if announcement.pinned ~= true and tonumber(expiresIn) then
		announcement.expiresAt = os.clock() + tonumber(expiresIn)
	end

	return announcement
end

local function sortAnnouncements()
	for index, announcement in ipairs(ANNOUNCEMENTS) do
		announcement.sortIndex = index
	end

	table.sort(ANNOUNCEMENTS, function(a, b)
		if (a.pinned == true) ~= (b.pinned == true) then
			return a.pinned == true
		end

		if a.pinned ~= true and (a.createdAt or 0) ~= (b.createdAt or 0) then
			return (a.createdAt or 0) > (b.createdAt or 0)
		end

		return a.sortIndex < b.sortIndex
	end)
end

local function pruneExpired()
	local now = os.clock()
	local removed = false

	for index = #ANNOUNCEMENTS, 1, -1 do
		local expiresAt = ANNOUNCEMENTS[index].expiresAt

		if expiresAt and now >= expiresAt then
			table.remove(ANNOUNCEMENTS, index)
			removed = true
		end
	end

	return removed
end

local panelScale = AnnouncementPanel:FindFirstChild("UIScale")
if not panelScale then
	panelScale = Instance.new("UIScale")
	panelScale.Parent = AnnouncementPanel
end

local function playMenuClick()
	if _G.USARFPlaySound then
		_G.USARFPlaySound("MenuClick", "MenuSounds")
	end
end

local function isRead(id)
	return readAnnouncements[id] == true
end

local function markRead(id)
	if id then
		readAnnouncements[id] = true
	end
end

local function getUnreadCount()
	local count = 0

	for _, announcement in ipairs(ANNOUNCEMENTS) do
		if not isRead(announcement.id) then
			count += 1
		end
	end

	return count
end

local function updateBadge()
	local settings = _G.USARFSettings

	if settings and settings.Announcements == false then
		Badge.Visible = false

		if _G.USARFSetAnnouncementTopbarBadge then
			_G.USARFSetAnnouncementTopbarBadge(0)
		end

		return
	end

	local unreadCount = getUnreadCount()

	Badge.Visible = unreadCount > 0
	CountLabel.Text = tostring(unreadCount)

	if _G.USARFSetAnnouncementTopbarBadge then
		_G.USARFSetAnnouncementTopbarBadge(unreadCount)
	end

	if _G.USARFUpdateTopbarVisibility then
		_G.USARFUpdateTopbarVisibility()
	end
end

local function applyPanelLayout()
	panelScale.Scale = 1

	AnnouncementPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	AnnouncementPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	AnnouncementPanel.Size = UDim2.new(0, 760, 0, 520)
	AnnouncementPanel.ZIndex = 700

	CloseButton.AnchorPoint = Vector2.new(1, 0)
	CloseButton.Position = UDim2.new(1, -14, 0, 14)
	CloseButton.Size = UDim2.new(0, 32, 0, 32)
	CloseButton.ZIndex = 750

	ContentFrame.ZIndex = 710
end

local function clearAnnouncements()
	for _, child in ipairs(ContentFrame:GetChildren()) do
		if child ~= Template and child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function createAnnouncement(data, index)
	local card = Template:Clone()
	card.Name = "Announcement_" .. tostring(index)
	card.Visible = true
	card.LayoutOrder = index
	card.Parent = ContentFrame

	local category = data.category or "General"
	local categoryColor = CATEGORY_COLORS[category] or CATEGORY_COLORS.General

	card.CategoryLabel.Text = category
	card.CategoryLabel.BackgroundColor3 = categoryColor

	card.TitleLabel.Text = isRead(data.id) and data.title or "● " .. data.title
	card.BodyLabel.Text = data.body or ""
	card.DateLabel.Text = data.date or "Facility Notice"
end

local function populateAnnouncements()
	clearAnnouncements()

	for index, data in ipairs(ANNOUNCEMENTS) do
		createAnnouncement(data, index)
	end
end

local function markAllAsRead()
	for _, announcement in ipairs(ANNOUNCEMENTS) do
		markRead(announcement.id)
	end

	updateBadge()
end

local function loadAnnouncements()
	local success, result = pcall(function()
		return GetAnnouncementsRemote:InvokeServer()
	end)

	if not success then
		warn("[AnnouncementController] Failed to load announcements:", result)
		return
	end

	ANNOUNCEMENTS = {}

	for _, announcement in ipairs(result or {}) do
		table.insert(ANNOUNCEMENTS, withExpiry(announcement, announcement.expiresIn))
	end

	sortAnnouncements()
	updateBadge()
end

local function closePanel(playSound)
	if playSound ~= false then
		playMenuClick()
	end

	AnnouncementPanel.Visible = false
end

local function openPanel()
	playMenuClick()

	if AnnouncementPanel.Visible then
		closePanel(false)
		return
	end

	if _G.USARFCloseSettings then
		_G.USARFCloseSettings(false)
	end

	applyPanelLayout()

	populateAnnouncements()
	AnnouncementPanel.Visible = true

	markAllAsRead()
	populateAnnouncements()
end

local function togglePanel()
	if AnnouncementPanel.Visible then
		closePanel()
	else
		openPanel()
	end
end

function _G.USARFAddAnnouncement(payload)
	if type(payload) ~= "table" then
		return
	end

	local announcement = {
		id = payload.id or ("alert_" .. tostring(os.time())),
		category = payload.category or "Facility",
		priority = payload.priority or "Normal",
		title = payload.title or "Facility Alert",
		body = payload.body or "No message provided.",
		date = payload.date or "Facility Alert",
		sender = payload.sender or "System",
		createdAt = payload.createdAt or os.time(),
		pinned = payload.pinned == true,
	}

	table.insert(ANNOUNCEMENTS, 1, withExpiry(announcement, payload.expiresIn))
	sortAnnouncements()

	while #ANNOUNCEMENTS > 50 do
		table.remove(ANNOUNCEMENTS)
	end

	updateBadge()

	if AnnouncementPanel.Visible then
		populateAnnouncements()
	end
end

function _G.USARFRemoveAnnouncements(ids)
	if type(ids) ~= "table" then
		return
	end

	local remove = {}
	for _, id in ipairs(ids) do
		remove[id] = true
	end

	for index = #ANNOUNCEMENTS, 1, -1 do
		if remove[ANNOUNCEMENTS[index].id] then
			table.remove(ANNOUNCEMENTS, index)
		end
	end

	updateBadge()

	if AnnouncementPanel.Visible then
		populateAnnouncements()
	end
end

CloseButton.MouseButton1Click:Connect(function()
	closePanel()
end)

AnnouncementButton.MouseButton1Click:Connect(togglePanel)

_G.USARFToggleAnnouncements = togglePanel
_G.USARFOpenAnnouncements = openPanel
_G.USARFCloseAnnouncements = closePanel
_G.USARFUpdateAnnouncementBadge = updateBadge

applyPanelLayout()
AnnouncementPanel.Visible = false
loadAnnouncements()

task.spawn(function()
	while true do
		task.wait(EXPIRY_CHECK_SECONDS)

		if pruneExpired() then
			updateBadge()

			if AnnouncementPanel.Visible then
				populateAnnouncements()
			end
		end
	end
end)

print("USARF AnnouncementController initialized")
