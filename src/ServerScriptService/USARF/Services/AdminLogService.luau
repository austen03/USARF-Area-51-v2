local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AdminLogService = {}

local STORE_NAME = "USARF_AdminLogs_v1"
local MAX_GLOBAL_LOGS = 300

local BatchedLogWriter = require(script.Parent:WaitForChild("BatchedLogWriter"))

local store = DataStoreService:GetDataStore(STORE_NAME)
local writer = BatchedLogWriter.new(store, "AdminLogService")
local memoryLogs = {}
local started = false

local function getGlobalKey()
	return "GLOBAL"
end

local function now()
	return os.time()
end

function AdminLogService.Log(data)
	data = type(data) == "table" and data or {}

	local entry = {
		id = HttpService:GenerateGUID(false),
		source = data.source or "Unknown",
		action = data.action or "Unknown",
		command = data.command,
		result = data.result,
		caseId = data.caseId,
		reason = data.reason,

		moderatorUserId = data.moderatorUserId,
		moderatorUsername = data.moderatorUsername,

		targetUserId = data.targetUserId,
		targetUsername = data.targetUsername,

		timestamp = now(),
	}

	table.insert(memoryLogs, 1, entry)

	while #memoryLogs > MAX_GLOBAL_LOGS do
		table.remove(memoryLogs)
	end

	writer:Add(getGlobalKey(), entry, MAX_GLOBAL_LOGS)

	return entry
end

function AdminLogService.GetRecent(count)
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

function AdminLogService.GetForQuery(query, count)
	query = string.lower(tostring(query or ""))
	count = math.clamp(tonumber(count) or 25, 1, 100)

	local logs = AdminLogService.GetRecent(100)
	local output = {}

	for _, entry in ipairs(logs) do
		local haystack = string.lower(table.concat({
			tostring(entry.source or ""),
			tostring(entry.action or ""),
			tostring(entry.command or ""),
			tostring(entry.result or ""),
			tostring(entry.caseId or ""),
			tostring(entry.reason or ""),
			tostring(entry.moderatorUsername or ""),
			tostring(entry.moderatorUserId or ""),
			tostring(entry.targetUsername or ""),
			tostring(entry.targetUserId or ""),
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

local function tryHookCmdr()
	local possibleCmdr =
		ReplicatedStorage:FindFirstChild("Cmdr")
		or ServerScriptService:FindFirstChild("Cmdr")

	if not possibleCmdr then
		return
	end

	local success, cmdr = pcall(require, possibleCmdr)

	if not success or not cmdr or not cmdr.Registry then
		return
	end

	pcall(function()
		cmdr.Registry:RegisterHook("BeforeRun", function(context)
			local executor = context.Executor

			AdminLogService.Log({
				source = "Cmdr",
				action = "Command",
				command = context.RawText or context.Name or "Unknown Command",
				moderatorUserId = executor and executor.UserId or nil,
				moderatorUsername = executor and executor.Name or "Unknown",
			})
		end)
	end)

	print("[AdminLogService] Cmdr hook registered")
end

function AdminLogService.Start()
	if started then
		return
	end

	started = true
	task.defer(tryHookCmdr)

	print("[AdminLogService] Started")
end

return AdminLogService