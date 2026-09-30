local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local FacilityAlertRemote = Remotes:WaitForChild("FacilityAlert")
local FacilityStatusRemote = Remotes:WaitForChild("FacilityStatus")
local GetAnnouncementsRemote = Remotes:WaitForChild("GetAnnouncements")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local AuditService = require(Services:WaitForChild("AuditService"))
local RadioService = require(Services:WaitForChild("RadioService"))

local FacilityAlertService = {}

local MAX_ANNOUNCEMENTS = 50

local announcementHistory = {}

local VALID_CATEGORIES = {
	General = true,
	Facility = true,
	Department = true,
	Update = true,
	Emergency = true,
}

local CATEGORY_PRIORITY = {
	General = "Normal",
	Facility = "Normal",
	Department = "Normal",
	Update = "Normal",
	Emergency = "Emergency",
}

local CATEGORY_STATUS = {
	General = nil,
	Facility = nil,
	Department = nil,
	Update = nil,
	Emergency = "LOCKDOWN",
}

local RADIO_ALERT_CATEGORIES = {
	Facility = true,
	Emergency = true,
}

local DEFAULT_ANNOUNCEMENTS = {
	{
		id = "welcome_v2",
		category = "General",
		priority = "Normal",
		title = "Welcome to AREA-51 v2",
		body = "The new deployment interface is now active. Select your authorized department to begin.",
		date = "System Notice",
		sender = "System",
		createdAt = os.time(),
	},
	{
		id = "return_menu",
		category = "Update",
		priority = "Normal",
		title = "Return To Menu",
		body = "Returning to the menu requires a 7 second countdown. Movement will cancel the return.",
		date = "Deployment System",
		sender = "System",
		createdAt = os.time(),
	},
}

local function cloneTable(tbl)
	local copy = {}

	for key, value in pairs(tbl) do
		copy[key] = value
	end

	return copy
end

local function addAnnouncement(payload)
	table.insert(announcementHistory, 1, payload)

	while #announcementHistory > MAX_ANNOUNCEMENTS do
		table.remove(announcementHistory)
	end
end

local function seedDefaults()
	for i = #DEFAULT_ANNOUNCEMENTS, 1, -1 do
		addAnnouncement(cloneTable(DEFAULT_ANNOUNCEMENTS[i]))
	end
end

local function buildRadioAlertMessage(title, message)
	title = tostring(title or "Facility Alert")
	message = tostring(message or "")

	if message == "" then
		return title
	end

	return title .. " - " .. message
end

function FacilityAlertService.GetAnnouncements()
	local results = {}

	for index, announcement in ipairs(announcementHistory) do
		results[index] = cloneTable(announcement)
	end

	return results
end

function FacilityAlertService.SetStatus(status, subtitle)
	status = string.upper(tostring(status or "NORMAL"))
	subtitle = subtitle or ""

	FacilityStatusRemote:FireAllClients(status, subtitle)

	AuditService.Log({
		category = "Facility",
		action = "StatusChanged",
		message = status .. (subtitle ~= "" and (" - " .. subtitle) or ""),
		severity = status == "NORMAL" and "Info" or "Warning",
		metadata = {
			status = status,
			subtitle = subtitle,
		},
	})

	print("[FacilityAlertService] Facility status changed:", status, subtitle)
end

function FacilityAlertService.SendAlert(category, title, message, sender)
	category = category or "Facility"
	title = title or "Facility Alert"
	message = message or "No message provided."

	if not VALID_CATEGORIES[category] then
		category = "Facility"
	end

	local priority = CATEGORY_PRIORITY[category] or "Normal"

	local payload = {
		id = "alert_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
		category = category,
		priority = priority,
		title = title,
		body = message,
		date = "Facility Alert",
		sender = sender or "System",
		createdAt = os.time(),
		read = false,
	}

	addAnnouncement(payload)

	FacilityAlertRemote:FireAllClients(payload)

	AuditService.Log({
		category = "Facility",
		action = "AlertSent",
		message = title .. " - " .. message,
		severity = priority == "Emergency" and "Emergency" or "Info",
		metadata = {
			alertId = payload.id,
			category = category,
			priority = priority,
			title = title,
			body = message,
			sender = sender or "System",
		},
	})

	if RADIO_ALERT_CATEGORIES[category] then
		RadioService.System("alerts", buildRadioAlertMessage(title, message))
	end

	local status = CATEGORY_STATUS[category]
	if status then
		FacilityAlertService.SetStatus(status, title)
	end

	print("[FacilityAlertService]", priority, category, title, message)

	return payload
end

seedDefaults()

GetAnnouncementsRemote.OnServerInvoke = function(player)
	return FacilityAlertService.GetAnnouncements()
end

return FacilityAlertService
