local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotificationQueueService = {}

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local NotifyRemote = Remotes:WaitForChild("Notify")

local DEFAULT_DURATION = 5
local DEFAULT_GAP = 0.35
local MAX_QUEUE_PER_PLAYER = 25
local DUPLICATE_WINDOW = 4

local queues = {}
local processing = {}
local lastSent = {}

local function getPlayerKey(player)
	return tostring(player.UserId)
end

local function makeDuplicateKey(data)
	return table.concat({
		tostring(data.Title or ""),
		tostring(data.Message or ""),
		tostring(data.Type or "Info"),
	}, "|")
end

local function normalizeData(data)
	data = data or {}

	return {
		Id = data.Id,
		Title = tostring(data.Title or "Notification"),
		Message = tostring(data.Message or ""),
		Type = tostring(data.Type or "Info"),
		Duration = tonumber(data.Duration) or DEFAULT_DURATION,
		Size = tostring(data.Size or "Small"),
		Large = data.Large == true,

		Priority = tonumber(data.Priority) or 1,
		Gap = tonumber(data.Gap) or DEFAULT_GAP,
		Dedupe = data.Dedupe ~= false,
		CreatedAt = os.clock(),
	}
end

local function shouldDropDuplicate(player, data)
	if data.Dedupe == false then
		return false
	end

	local key = getPlayerKey(player)
	local duplicateKey = makeDuplicateKey(data)

	lastSent[key] = lastSent[key] or {}

	local previous = lastSent[key][duplicateKey]
	local now = os.clock()

	if previous and now - previous < DUPLICATE_WINDOW then
		return true
	end

	lastSent[key][duplicateKey] = now
	return false
end

local function sortQueue(player)
	local key = getPlayerKey(player)
	local queue = queues[key]

	if not queue then
		return
	end

	table.sort(queue, function(a, b)
		if a.Priority == b.Priority then
			return a.CreatedAt < b.CreatedAt
		end

		return a.Priority > b.Priority
	end)
end

local function trimQueue(player)
	local key = getPlayerKey(player)
	local queue = queues[key]

	if not queue then
		return
	end

	while #queue > MAX_QUEUE_PER_PLAYER do
		table.remove(queue)
	end
end

local function processPlayer(player)
	if not player or not player.Parent then
		return
	end

	local key = getPlayerKey(player)

	if processing[key] then
		return
	end

	processing[key] = true

	task.spawn(function()
		while player.Parent and queues[key] and #queues[key] > 0 do
			sortQueue(player)

			local data = table.remove(queues[key], 1)

			if data then
				NotifyRemote:FireClient(player, {
					Title = data.Title,
					Message = data.Message,
					Type = data.Type,
					Duration = data.Duration,
					Size = data.Size,
					Large = data.Large,
				})

				task.wait(math.max(0.05, data.Gap))
			end
		end

		processing[key] = nil
	end)
end

function NotificationQueueService.Queue(player, data)
	if not player or not player.Parent then
		return false, "Missing player"
	end

	data = normalizeData(data)

	if shouldDropDuplicate(player, data) then
		return false, "Duplicate notification suppressed"
	end

	local key = getPlayerKey(player)

	queues[key] = queues[key] or {}
	table.insert(queues[key], data)
	trimQueue(player)

	processPlayer(player)

	return true
end

function NotificationQueueService.QueueMany(playersList, data)
	for _, player in ipairs(playersList or {}) do
		NotificationQueueService.Queue(player, data)
	end
end

function NotificationQueueService.QueueAll(data)
	for _, player in ipairs(Players:GetPlayers()) do
		NotificationQueueService.Queue(player, data)
	end
end

function NotificationQueueService.QueueTeam(teamName, data)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == teamName then
			NotificationQueueService.Queue(player, data)
		end
	end
end

function NotificationQueueService.Clear(player)
	if not player then
		return
	end

	local key = getPlayerKey(player)
	queues[key] = {}
end

Players.PlayerRemoving:Connect(function(player)
	local key = getPlayerKey(player)

	queues[key] = nil
	processing[key] = nil
	lastSent[key] = nil
end)

return NotificationQueueService