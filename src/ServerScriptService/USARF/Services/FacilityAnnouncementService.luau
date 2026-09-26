local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FacilityAnnouncementService = {}

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")
local Shared = USARF:WaitForChild("Shared")

local FacilityAnnouncementConfig = require(Config:WaitForChild("FacilityAnnouncementConfig"))

local FacilityState = Shared:WaitForChild("FacilityState")
local LockdownLevelValue = FacilityState:WaitForChild("LockdownLevel")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityStatusService = nil
pcall(function()
	FacilityStatusService = require(Services:WaitForChild("FacilityStatusService"))
end)

local started = false
local lastPlayed = {}

local queue = {}
local processingQueue = false
local cancelQueueToken = 0

local function getAnnouncementsFolder()
	local current = Workspace

	for _, name in ipairs(FacilityAnnouncementConfig.AnnouncementsPath or {}) do
		current = current:FindFirstChild(name)

		if not current then
			return nil
		end
	end

	return current
end

local function getSound(soundName)
	if not soundName or soundName == "" then
		return nil
	end

	local announcements = getAnnouncementsFolder()

	if not announcements then
		warn("[FacilityAnnouncementService] Missing announcements folder.")
		return nil
	end

	local direct = announcements:FindFirstChild(soundName)

	if direct and direct:IsA("Sound") then
		return direct
	end

	local defconFolder = announcements:FindFirstChild(FacilityAnnouncementConfig.DefconFolderName or "defcon")

	if defconFolder then
		local defconSound = defconFolder:FindFirstChild(soundName)

		if defconSound and defconSound:IsA("Sound") then
			return defconSound
		end
	end

	local deep = announcements:FindFirstChild(soundName, true)

	if deep and deep:IsA("Sound") then
		return deep
	end

	warn("[FacilityAnnouncementService] Missing announcement sound:", soundName)
	return nil
end

local function getDuration(soundName, sound)
	local configured = FacilityAnnouncementConfig.SoundDurations
		and FacilityAnnouncementConfig.SoundDurations[soundName]

	if configured then
		return configured
	end

	if sound and sound.TimeLength and sound.TimeLength > 0 then
		return sound.TimeLength
	end

	return 3
end

local function canPlay(soundName, force)
	if force then
		return true
	end

	local now = os.clock()
	local minimumDelay = FacilityAnnouncementConfig.MinimumRepeatDelay or 3

	if lastPlayed[soundName] and now - lastPlayed[soundName] < minimumDelay then
		return false
	end

	lastPlayed[soundName] = now
	return true
end

local function stopAllSounds()
	local announcements = getAnnouncementsFolder()

	if not announcements then
		return
	end

	for _, descendant in ipairs(announcements:GetDescendants()) do
		if descendant:IsA("Sound") then
			descendant:Stop()
			descendant.TimePosition = 0
		end
	end
end

local function playSoundNow(soundName, force)
	if not soundName then
		return 0
	end

	if not canPlay(soundName, force) then
		return 0
	end

	local sound = getSound(soundName)

	if not sound then
		return 0
	end

	if sound.IsPlaying then
		sound:Stop()
	end

	sound.TimePosition = 0
	sound:Play()

	print("[FacilityAnnouncementService] Playing:", soundName)

	return getDuration(soundName, sound)
end

local function sortQueue()
	table.sort(queue, function(a, b)
		if a.Priority == b.Priority then
			return a.CreatedAt < b.CreatedAt
		end

		return a.Priority > b.Priority
	end)
end

local function processQueue()
	if processingQueue then
		return
	end

	processingQueue = true
	local token = cancelQueueToken

	task.spawn(function()
		while #queue > 0 do
			if token ~= cancelQueueToken then
				break
			end

			sortQueue()

			local item = table.remove(queue, 1)

			if item and item.SoundName then
				local duration = playSoundNow(item.SoundName, item.Force)

				if duration > 0 then
					task.wait(duration + (item.DelayAfter or FacilityAnnouncementConfig.DelayBetweenSounds or 0.75))
				else
					task.wait(0.1)
				end
			end
		end

		processingQueue = false
	end)
end

local function enqueueSound(soundName, force, priority, delayAfter)
	if not soundName then
		return
	end

	table.insert(queue, {
		SoundName = soundName,
		Force = force == true,
		Priority = tonumber(priority) or 1,
		DelayAfter = delayAfter,
		CreatedAt = os.clock(),
	})

	processQueue()
end

local function enqueueSequence(soundNames, force, priority)
	for index, soundName in ipairs(soundNames) do
		enqueueSound(soundName, force, priority, FacilityAnnouncementConfig.DelayBetweenSounds or 0.75)
	end
end

function FacilityAnnouncementService.Play(soundName, force, priority)
	enqueueSound(soundName, force == true, priority or 1)
	return true
end

function FacilityAnnouncementService.PlayEvent(eventName, priority)
	local soundName = FacilityAnnouncementConfig.EventAudio[eventName]

	if not soundName then
		warn("[FacilityAnnouncementService] Missing event audio config:", tostring(eventName))
		return false
	end

	if FacilityStatusService and typeof(FacilityStatusService.SetLastEvent) == "function" then
		FacilityStatusService.SetLastEvent("Facility announcement: " .. tostring(eventName))
	end

	enqueueSound(soundName, true, priority or 3)
	return true
end

function FacilityAnnouncementService.PlayLockdownLevel(level)
	level = tonumber(level) or 0

	local audioConfig = FacilityAnnouncementConfig.LockdownAudio[level]

	if not audioConfig then
		return false
	end

	local sounds = {}

	if FacilityAnnouncementConfig.PlayDefconBeforeAnnouncement ~= false then
		table.insert(sounds, audioConfig.DefconSound)
		table.insert(sounds, audioConfig.AnnouncementSound)
	else
		table.insert(sounds, audioConfig.AnnouncementSound)
		table.insert(sounds, audioConfig.DefconSound)
	end

	enqueueSequence(sounds, false, 2)

	if FacilityStatusService and typeof(FacilityStatusService.SetLastEvent) == "function" then
		FacilityStatusService.SetLastEvent("Facility announcement: lockdown level " .. tostring(level))
	end

	return true
end

function FacilityAnnouncementService.ClearQueue()
	table.clear(queue)
	cancelQueueToken += 1
	processingQueue = false
end

function FacilityAnnouncementService.StopAll()
	FacilityAnnouncementService.ClearQueue()
	stopAllSounds()
end

function FacilityAnnouncementService.Start()
	if started then
		return
	end

	started = true

	LockdownLevelValue.Changed:Connect(function()
		FacilityAnnouncementService.PlayLockdownLevel(LockdownLevelValue.Value)
	end)

	print("[FacilityAnnouncementService] Started")
end

return FacilityAnnouncementService