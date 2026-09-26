local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local RadioLogService = {}

local STORE_NAME = "USARF_RadioLogs_v1"
local MAX_GLOBAL_LOGS = 300
local MAX_PLAYER_LOGS = 100

local BatchedLogWriter = require(script.Parent:WaitForChild("BatchedLogWriter"))

local store = DataStoreService:GetDataStore(STORE_NAME)
local writer = BatchedLogWriter.new(store, "RadioLogService")
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

function RadioLogService.Log(player, data)
	if not player then
		return
	end

	data = type(data) == "table" and data or {}

	local channel = tostring(data.channel or "Unknown")

	if channel == "alerts" then
		return
	end

	local message = tostring(data.message or data.text or "")

	if message == "" then
		return
	end

	local prefix = tostring(data.prefix or "")
	local transmissionName = tostring(data.transmissionName or player.Name)

	local transmission = ""

	if prefix ~= "" then
		transmission = "[" .. prefix .. "] " .. transmissionName .. ":\n" .. message
	else
		transmission = transmissionName .. ":\n" .. message
	end

	local entry = {
		id = HttpService:GenerateGUID(false),
		type = "Radio",

		userId = player.UserId,
		username = player.Name,
		displayName = player.DisplayName,

		teamName = player:GetAttribute("USARF_TeamName") or (player.Team and player.Team.Name) or "Unknown",

		channel = channel,
		channelName = tostring(data.channelName or channel),
		prefix = prefix,
		message = message,
		transmission = transmission,

		timestamp = now(),
	}

	table.insert(memoryLogs, 1, entry)

	while #memoryLogs > MAX_GLOBAL_LOGS do
		table.remove(memoryLogs)
	end

	writer:Add(getGlobalKey(), entry, MAX_GLOBAL_LOGS)
	writer:Add(getPlayerKey(player.UserId), entry, MAX_PLAYER_LOGS)

	return entry
end

function RadioLogService.GetRecent(count)
	count = math.clamp(tonumber(count) or 25, 1, 100)

	local success, result = pcall(function()
		return store:GetAsync(getGlobalKey())
	end)

	local logs = memoryLogs

	if success and type(result) == "table" then
		-- Entries still waiting to be saved are newer than anything in the store.
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

function RadioLogService.GetForQuery(query, count)
	query = string.lower(tostring(query or ""))
	count = math.clamp(tonumber(count) or 25, 1, 100)

	local logs = RadioLogService.GetRecent(100)
	local output = {}

	for _, entry in ipairs(logs) do
		local haystack = string.lower(table.concat({
			tostring(entry.username or ""),
			tostring(entry.displayName or ""),
			tostring(entry.userId or ""),
			tostring(entry.teamName or ""),
			tostring(entry.channel or ""),
			tostring(entry.channelName or ""),
			tostring(entry.prefix or ""),
			tostring(entry.message or ""),
			tostring(entry.transmission or ""),
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

function RadioLogService.Start()
	if started then
		return
	end

	started = true
	print("[RadioLogService] Started")
end

return RadioLogService