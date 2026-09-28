local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local AdminLogService = require(Services:WaitForChild("AdminLogService"))

local function formatTime(timestamp)
	return os.date("%I:%M:%S %p", tonumber(timestamp) or os.time())
end

local function formatEntry(entry)
	local lines = {
		"[" .. formatTime(entry.timestamp) .. "]",
		"Source: " .. tostring(entry.source or "Unknown"),
		"Action: " .. tostring(entry.action or "Unknown"),
	}

	if entry.command then
		table.insert(lines, "Command: " .. tostring(entry.command))
	end

	if entry.result then
		table.insert(lines, "Result: " .. tostring(entry.result))
	end

	if entry.caseId then
		table.insert(lines, "Case: " .. tostring(entry.caseId))
	end

	if entry.moderatorUsername then
		table.insert(lines, "Moderator: " .. tostring(entry.moderatorUsername))
	end

	if entry.targetUsername then
		table.insert(lines, "Target: " .. tostring(entry.targetUsername))
	end

	if entry.reason then
		table.insert(lines, "Reason: " .. tostring(entry.reason))
	end

	return table.concat(lines, "\n")
end

return function(context, query, count)
	local logs

	if tonumber(query) and not count then
		logs = AdminLogService.GetRecent(tonumber(query))
	elseif query and query ~= "" then
		logs = AdminLogService.GetForQuery(query, count or 25)
	else
		logs = AdminLogService.GetRecent(count or 25)
	end

	if #logs <= 0 then
		return "No admin logs found."
	end

	local lines = {
		"Recent Admin Logs:",
		"",
	}

	for _, entry in ipairs(logs) do
		table.insert(lines, formatEntry(entry))
		table.insert(lines, "----------------------------")
	end

	return table.concat(lines, "\n")
end
