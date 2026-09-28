local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local RadioLogService = require(Services:WaitForChild("RadioLogService"))

local function formatTime(timestamp)
	return os.date("%H:%M:%S", tonumber(timestamp) or os.time())
end

local function formatEntry(entry)
	return string.format(
		"[%s]\n\nChannel:\n%s\n\nTransmission:\n%s",
		formatTime(entry.timestamp),
		tostring(entry.channelName or entry.channel or "Unknown"),
		tostring(entry.transmission or entry.message or "")
	)
end

return function(context, query, count)
	local logs

	if tonumber(query) and not count then
		logs = RadioLogService.GetRecent(tonumber(query))
	elseif query and query ~= "" then
		logs = RadioLogService.GetForQuery(query, count or 25)
	else
		logs = RadioLogService.GetRecent(count or 25)
	end

	if #logs <= 0 then
		return "No radio logs found."
	end

	local lines = {
		"Recent Radio Logs:",
		"",
	}

	for _, entry in ipairs(logs) do
		table.insert(lines, formatEntry(entry))
		table.insert(lines, "----------------------------")
	end

	return table.concat(lines, "\n")
end
