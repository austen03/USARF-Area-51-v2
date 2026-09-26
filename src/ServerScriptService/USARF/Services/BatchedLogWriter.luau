-- Buffers log entries per DataStore key and writes each key at most once per FLUSH_SECONDS.
--
-- A single DataStore key only accepts about one write every 6 seconds. Writing every chat,
-- radio or admin log entry straight to a shared "GLOBAL" key overflowed the request queue
-- ("DataStore request was added to queue ... Key = GLOBAL") and entries could be dropped.

local BatchedLogWriter = {}
BatchedLogWriter.__index = BatchedLogWriter

-- Keeps each key's write rate well under the per-key limit and the per-server write budget.
local FLUSH_SECONDS = 15

function BatchedLogWriter.new(store: DataStore, name: string)
	local self = setmetatable({
		_store = store,
		_name = name,
		_pending = {}, -- [key] = { entries, oldest first }
		_maxCounts = {}, -- [key] = max entries kept for that key
	}, BatchedLogWriter)

	task.spawn(function()
		while true do
			task.wait(FLUSH_SECONDS)
			self:Flush()
		end
	end)

	game:BindToClose(function()
		self:Flush()
	end)

	return self
end

local function trimOldest(entries, maxCount)
	while #entries > maxCount do
		table.remove(entries, 1)
	end
end

function BatchedLogWriter:Add(key: string, entry: any, maxCount: number)
	local pending = self._pending[key]

	if not pending then
		pending = {}
		self._pending[key] = pending
	end

	table.insert(pending, entry)
	self._maxCounts[key] = maxCount

	trimOldest(pending, maxCount)
end

-- Entries for key that have not been written yet, newest first (the order logs are stored in).
function BatchedLogWriter:GetPending(key: string): { any }
	local pending = self._pending[key]
	local newestFirst = {}

	if pending then
		for index = #pending, 1, -1 do
			table.insert(newestFirst, pending[index])
		end
	end

	return newestFirst
end

function BatchedLogWriter:Flush()
	local batches = self._pending
	self._pending = {}

	for key, entries in pairs(batches) do
		local maxCount = self._maxCounts[key]

		local success, result = pcall(function()
			self._store:UpdateAsync(key, function(old)
				old = type(old) == "table" and old or {}

				for _, entry in ipairs(entries) do
					table.insert(old, 1, entry)
				end

				while #old > maxCount do
					table.remove(old)
				end

				return old
			end)
		end)

		if not success then
			-- Put the batch back in front of anything logged since, so it is retried next flush.
			local pending = self._pending[key] or {}

			for index, entry in ipairs(entries) do
				table.insert(pending, index, entry)
			end

			self._pending[key] = pending
			trimOldest(pending, maxCount)

			warn(`[{self._name}] Failed to save {#entries} log entries for {key}, will retry: {tostring(result)}`)
		end
	end
end

return BatchedLogWriter
