local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local ChatLogService = require(Services:WaitForChild("ChatLogService"))

local function formatTime(timestamp)
	return os.date("%I:%M:%S %p", tonumber(timestamp) or os.time())
end

local function formatEntry(entry)
	return string.format(
		"[%s] %s (%s) | %s\n%s",
		formatTime(entry.timestamp),
		tostring(entry.username or "Unknown"),
		tostring(entry.userId or "N/A"),
		tostring(entry.teamName or "Unknown"),
		tostring(entry.message or "")
	)
end

return function(context, query, count)
	local logs

	if tonumber(query) and not count then
		logs = ChatLogService.GetRecent(tonumber(query))
	elseif query and query ~= "" then
		logs = ChatLogService.GetForQuery(query, count or 25)
	else
		logs = ChatLogService.GetRecent(count or 25)
	end

	if #logs <= 0 then
		return "No chat logs found."
	end

	local lines = {
		"Recent Chat Logs:",
		"",
	}

	for _, entry in ipairs(logs) do
		table.insert(lines, formatEntry(entry))
		table.insert(lines, "----------------------------")
	end

	return table.concat(lines, "\n")
end
