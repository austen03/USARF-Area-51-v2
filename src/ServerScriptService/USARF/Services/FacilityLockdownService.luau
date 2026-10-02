local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FacilityLockdownService = {}

local USARFReplicated = ReplicatedStorage:WaitForChild("USARF")
local Config = USARFReplicated:WaitForChild("Config")
local Shared = USARFReplicated:WaitForChild("Shared")

local LockdownConfig = require(Config:WaitForChild("LockdownConfig"))

local FacilityState = Shared:WaitForChild("FacilityState")
local LockdownLevelValue = FacilityState:WaitForChild("LockdownLevel")
local LockdownActiveValue = FacilityState:WaitForChild("LockdownActive")
local AlertLevelValue = FacilityState:WaitForChild("AlertLevel")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local NotificationService = require(Services:WaitForChild("NotificationService"))

local RadioService = nil
pcall(function()
	RadioService = require(Services:WaitForChild("RadioService"))
end)

local FacilityAlertService = nil
pcall(function()
	FacilityAlertService = require(Services:WaitForChild("FacilityAlertService"))
end)

local state = {
	Active = false,
	Level = 0,
	Reason = nil,
	StartedBy = nil,
	StartedAt = nil,
}

local listeners = {}
local started = false

local function copyState()
	return {
		Active = state.Active,
		Level = state.Level,
		Reason = state.Reason,
		StartedBy = state.StartedBy,
		StartedAt = state.StartedAt,
	}
end

local function getLevelInfo(level)
	return LockdownConfig.Levels[level] or LockdownConfig.Levels[0]
end

local function replicateState()
	local levelInfo = getLevelInfo(state.Level)

	LockdownLevelValue.Value = state.Level
	LockdownActiveValue.Value = state.Active
	AlertLevelValue.Value = levelInfo.ShortName or "Normal"
end

local function notifyAll(title, message, notificationType)
	if LockdownConfig.NotifyPlayers ~= true then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		NotificationService.Notify(player, {
			Title = title,
			Message = message,
			Type = notificationType or "Info",
			Duration = 6,
		})
	end
end

local function sendRadioAlert(level, reason)
	if LockdownConfig.SendRadioAlert ~= true then
		return
	end

	if not RadioService then
		return
	end

	local levelInfo = getLevelInfo(level)
	-- Lockdown levels 0-4 are DEFCON 5-1, so every change is a DEFCON change too.
	local message = "DEFCON " .. tostring(5 - level) .. ": " .. (levelInfo.RadioMessage or levelInfo.Name)

	if reason and reason ~= "" then
		message = message .. " Reason: " .. reason
	end

	RadioService.Alert(message, if level > 0 then 5 else 3)
end

local function fireChanged()
	local current = copyState()

	for _, callback in ipairs(listeners) do
		task.spawn(function()
			callback(current)
		end)
	end
end

function FacilityLockdownService.GetState()
	return copyState()
end

function FacilityLockdownService.GetLevel()
	return state.Level
end

function FacilityLockdownService.IsActive()
	return state.Active
end

function FacilityLockdownService.OnChanged(callback)
	if typeof(callback) ~= "function" then
		return nil
	end

	table.insert(listeners, callback)

	return function()
		for index, existing in ipairs(listeners) do
			if existing == callback then
				table.remove(listeners, index)
				break
			end
		end
	end
end

function FacilityLockdownService.SetLevel(level, actor, reason)
	level = math.clamp(math.floor(tonumber(level) or 0), 0, 4)

	local oldLevel = state.Level
	local levelInfo = getLevelInfo(level)

	state.Level = level
	state.Active = level > 0
	state.Reason = reason or nil
	state.StartedBy = actor and actor.Name or "System"
	state.StartedAt = os.time()

	if level == 0 then
		state.Active = false
		state.Reason = nil
	end

	replicateState()

	-- Statuses set by command (e.g. "facilitystatus code1") aren't tied to the lockdown level,
	-- so clients only drop them when told to. Clearing the lockdown resets them too, even when
	-- the level was already 0.
	if level == 0 and FacilityAlertService then
		FacilityAlertService.SetStatus("NORMAL")
	end

	if level ~= oldLevel then
		if level == 0 then
			notifyAll(
				"Lockdown Lifted",
				"Facility has returned to normal operations.",
				"Success"
			)
		else
			notifyAll(
				levelInfo.Name,
				reason or "Facility lockdown state has changed.",
				levelInfo.NotificationType
			)
		end

		sendRadioAlert(level, reason)
		fireChanged()
	end

	print(
		"[FacilityLockdownService]",
		"Level:",
		level,
		"Active:",
		state.Active,
		"By:",
		state.StartedBy,
		"Reason:",
		state.Reason or "None"
	)

	return copyState()
end

function FacilityLockdownService.Clear(actor, reason)
	return FacilityLockdownService.SetLevel(
		0,
		actor,
		reason or "Lockdown cleared"
	)
end

function FacilityLockdownService.GetDoorBehavior(doorSettings)
	local level = state.Level

	if level <= 0 then
		return "Normal"
	end

	local behavior = nil

	if doorSettings then
		local lockdownBehavior =
			doorSettings.LockdownBehavior
			or doorSettings.lockdownBehavior

		if typeof(lockdownBehavior) == "table" then
			behavior =
				lockdownBehavior[level]
				or lockdownBehavior["Level" .. tostring(level)]
		elseif typeof(lockdownBehavior) == "string" then
			behavior = lockdownBehavior
		end
	end

	if not behavior then
		behavior = LockdownConfig.DefaultDoorBehavior[level] or "Normal"
	end

	return behavior
end

function FacilityLockdownService.IsTeamLockdownBypass(teamName)
	if not teamName then
		return false
	end

	for _, allowedTeam in ipairs(LockdownConfig.GlobalBypassTeams or {}) do
		if allowedTeam == teamName then
			return true
		end
	end

	return false
end

function FacilityLockdownService.Start()
	if started then
		return
	end

	started = true
	replicateState()

	print("[FacilityLockdownService] Started")
end

return FacilityLockdownService