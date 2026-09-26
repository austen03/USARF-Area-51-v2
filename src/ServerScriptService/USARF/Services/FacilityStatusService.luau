local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FacilityStatusService = {}

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")
local Shared = USARF:WaitForChild("Shared")

local FacilityStatusConfig = require(Config:WaitForChild("FacilityStatusConfig"))

local FacilityState = Shared:WaitForChild("FacilityState")

local function getOrCreateValue(className, name, defaultValue)
	local value = FacilityState:FindFirstChild(name)

	if not value then
		value = Instance.new(className)
		value.Name = name
		value.Parent = FacilityState
	end

	if defaultValue ~= nil then
		value.Value = defaultValue
	end

	return value
end

local LockdownLevelValue = getOrCreateValue("IntValue", "LockdownLevel", 0)
local LockdownActiveValue = getOrCreateValue("BoolValue", "LockdownActive", false)
local AlertLevelValue = getOrCreateValue("StringValue", "AlertLevel", "Normal")

local RiotActiveValue = getOrCreateValue("BoolValue", "RiotActive", false)
local RiotStageValue = getOrCreateValue("IntValue", "RiotStage", 0)
local RiotEndsAtValue = getOrCreateValue("IntValue", "RiotEndsAt", 0)

local PlayerCountValue = getOrCreateValue("IntValue", "PlayerCount", 0)
local TestSubjectsOnlineValue = getOrCreateValue("IntValue", "TestSubjectsOnline", 0)
local PMCOnlineValue = getOrCreateValue("IntValue", "PMCOnline", 0)
local CivilOnlineValue = getOrCreateValue("IntValue", "CivilOnline", 0)
local CombativeOnlineValue = getOrCreateValue("IntValue", "CombativeOnline", 0)
local IntelligenceOnlineValue = getOrCreateValue("IntValue", "IntelligenceOnline", 0)
local ProtectionOnlineValue = getOrCreateValue("IntValue", "ProtectionOnline", 0)
local LeadershipOnlineValue = getOrCreateValue("IntValue", "LeadershipOnline", 0)

local LastFacilityEventValue = getOrCreateValue(
	"StringValue",
	"LastFacilityEvent",
	FacilityStatusConfig.DefaultValues.LastFacilityEvent or "Facility systems online."
)

local LastFacilityEventTimeValue = getOrCreateValue(
	"IntValue",
	"LastFacilityEventTime",
	0
)

local started = false
local listeners = {}

local currentStatus = {
	PlayerCount = 0,
	TestSubjectsOnline = 0,
	PMCOnline = 0,
	CivilOnline = 0,
	CombativeOnline = 0,
	IntelligenceOnline = 0,
	ProtectionOnline = 0,
	LeadershipOnline = 0,

	LockdownLevel = 0,
	LockdownActive = false,
	AlertLevel = FacilityStatusConfig.DefaultValues.AlertLevel or "Normal",

	RiotActive = false,
	RiotStage = 0,
	RiotEndsAt = 0,

	LastFacilityEvent = FacilityStatusConfig.DefaultValues.LastFacilityEvent or "Facility systems online.",
	LastFacilityEventTime = 0,
}

local function copyStatus()
	local copy = {}

	for key, value in pairs(currentStatus) do
		copy[key] = value
	end

	return copy
end

local function fireChanged()
	local snapshot = copyStatus()

	for _, callback in ipairs(listeners) do
		task.spawn(function()
			callback(snapshot)
		end)
	end
end

local function resetCounts()
	currentStatus.PlayerCount = #Players:GetPlayers()
	currentStatus.TestSubjectsOnline = 0
	currentStatus.PMCOnline = 0
	currentStatus.CivilOnline = 0
	currentStatus.CombativeOnline = 0
	currentStatus.IntelligenceOnline = 0
	currentStatus.ProtectionOnline = 0
	currentStatus.LeadershipOnline = 0
end

local function incrementCategory(category)
	if category == "TestSubjects" then
		currentStatus.TestSubjectsOnline += 1
	elseif category == "PMC" then
		currentStatus.PMCOnline += 1
	elseif category == "Civil" then
		currentStatus.CivilOnline += 1
	elseif category == "Combative" then
		currentStatus.CombativeOnline += 1
	elseif category == "Intelligence" then
		currentStatus.IntelligenceOnline += 1
	elseif category == "Protection" then
		currentStatus.ProtectionOnline += 1
	elseif category == "Leadership" then
		currentStatus.LeadershipOnline += 1
	end
end

local function replicateStatus()
	PlayerCountValue.Value = currentStatus.PlayerCount
	TestSubjectsOnlineValue.Value = currentStatus.TestSubjectsOnline
	PMCOnlineValue.Value = currentStatus.PMCOnline
	CivilOnlineValue.Value = currentStatus.CivilOnline
	CombativeOnlineValue.Value = currentStatus.CombativeOnline
	IntelligenceOnlineValue.Value = currentStatus.IntelligenceOnline
	ProtectionOnlineValue.Value = currentStatus.ProtectionOnline
	LeadershipOnlineValue.Value = currentStatus.LeadershipOnline

	currentStatus.LockdownLevel = LockdownLevelValue.Value
	currentStatus.LockdownActive = LockdownActiveValue.Value
	currentStatus.AlertLevel = AlertLevelValue.Value

	currentStatus.RiotActive = RiotActiveValue.Value
	currentStatus.RiotStage = RiotStageValue.Value
	currentStatus.RiotEndsAt = RiotEndsAtValue.Value

	LastFacilityEventValue.Value = currentStatus.LastFacilityEvent
	LastFacilityEventTimeValue.Value = currentStatus.LastFacilityEventTime
end

function FacilityStatusService.Refresh()
	resetCounts()

	for _, player in ipairs(Players:GetPlayers()) do
		local teamName = player.Team and player.Team.Name

		if teamName then
			local category = FacilityStatusConfig.TeamCategories[teamName]
			incrementCategory(category)
		end
	end

	replicateStatus()
	fireChanged()

	return copyStatus()
end

function FacilityStatusService.SetLastEvent(message)
	currentStatus.LastFacilityEvent = tostring(message or "")
	currentStatus.LastFacilityEventTime = os.time()

	replicateStatus()
	fireChanged()

	print("[FacilityStatusService] Last event:", currentStatus.LastFacilityEvent)
end

function FacilityStatusService.GetStatus()
	return copyStatus()
end

function FacilityStatusService.OnChanged(callback)
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

local function setupPlayer(player)
	player:GetPropertyChangedSignal("Team"):Connect(function()
		task.defer(FacilityStatusService.Refresh)
	end)

	task.defer(FacilityStatusService.Refresh)
end

function FacilityStatusService.Start()
	if started then
		return
	end

	started = true

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function()
		task.defer(FacilityStatusService.Refresh)
	end)

	LockdownLevelValue.Changed:Connect(function()
		task.defer(FacilityStatusService.Refresh)
	end)

	LockdownActiveValue.Changed:Connect(function()
		task.defer(FacilityStatusService.Refresh)
	end)

	AlertLevelValue.Changed:Connect(function()
		task.defer(FacilityStatusService.Refresh)
	end)

	RiotActiveValue.Changed:Connect(function()
		task.defer(FacilityStatusService.Refresh)
	end)

	RiotStageValue.Changed:Connect(function()
		task.defer(FacilityStatusService.Refresh)
	end)

	RiotEndsAtValue.Changed:Connect(function()
		task.defer(FacilityStatusService.Refresh)
	end)

	FacilityStatusService.SetLastEvent(
		FacilityStatusConfig.DefaultValues.LastFacilityEvent or "Facility systems online."
	)

	FacilityStatusService.Refresh()

	print("[FacilityStatusService] Started")
end

return FacilityStatusService