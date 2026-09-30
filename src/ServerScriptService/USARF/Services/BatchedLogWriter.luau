local BatchedLogWriter = {}
BatchedLogWriter.__index = BatchedLogWriter

local FLUSH_SECONDS = 15

function BatchedLogWriter.new(store: DataStore, name: string)
	local self = setmetatable({
		_store = store,
		_name = name,
		_pending = {},
		_maxCounts = {},
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
