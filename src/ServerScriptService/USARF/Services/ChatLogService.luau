local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local ChatLogService = {}

local STORE_NAME = "USARF_ChatLogs_v1"
local MAX_GLOBAL_LOGS = 250
local MAX_PLAYER_LOGS = 100

local BatchedLogWriter = require(script.Parent:WaitForChild("BatchedLogWriter"))

local store = DataStoreService:GetDataStore(STORE_NAME)
local writer = BatchedLogWriter.new(store, "ChatLogService")
local memoryLogs = {}
local started = false

local function getGlobalKey()
	return "GLOBAL"
end

local function getPlayerKey(userId)
	return "PLAYER_" .. tostring(userId)
end

local function now()
	return os.time()
end

function ChatLogService.Log(player, message)
	if not player or not message or message == "" then
		return
	end

	local entry = {
		id = HttpService:GenerateGUID(false),
		type = "Chat",
		userId = player.UserId,
		username = player.Name,
		displayName = player.DisplayName,
		teamName = player:GetAttribute("USARF_TeamName") or (player.Team and player.Team.Name) or "Unknown",
		message = tostring(message),
		timestamp = now(),
	}

	table.insert(memoryLogs, 1, entry)

	while #memoryLogs > MAX_GLOBAL_LOGS do
		table.remove(memoryLogs)
	end

	writer:Add(getGlobalKey(), entry, MAX_GLOBAL_LOGS)
	writer:Add(getPlayerKey(player.UserId), entry, MAX_PLAYER_LOGS)
end

function ChatLogService.GetRecent(count)
	count = math.clamp(tonumber(count) or 25, 1, 100)

	local success, result = pcall(function()
		return store:GetAsync(getGlobalKey())
	end)

	local logs = memoryLogs

	if success and type(result) == "table" then
		logs = writer:GetPending(getGlobalKey())

		for _, entry in ipairs(result) do
			table.insert(logs, entry)
		end
	end
	local output = {}

	for index = 1, math.min(count, #logs) do
		table.insert(output, logs[index])
	end

	return output
end

function ChatLogService.GetForQuery(query, count)
	query = string.lower(tostring(query or ""))
	count = math.clamp(tonumber(count) or 25, 1, 100)

	local logs = ChatLogService.GetRecent(100)
	local output = {}

	for _, entry in ipairs(logs) do
		local haystack = string.lower(table.concat({
			tostring(entry.username or ""),
			tostring(entry.displayName or ""),
			tostring(entry.userId or ""),
			tostring(entry.teamName or ""),
			tostring(entry.message or ""),
		}, " "))

		if string.find(haystack, query, 1, true) then
			table.insert(output, entry)

			if #output >= count then
				break
			end
		end
	end

	return output
end

function ChatLogService.Start()
	if started then
		return
	end

	started = true

	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			ChatLogService.Log(player, message)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		player.Chatted:Connect(function(message)
			ChatLogService.Log(player, message)
		end)
	end

	print("[ChatLogService] Started")
end

return ChatLogService
