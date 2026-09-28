local SERVER_STARTED_AT = os.clock()

local function formatDuration(totalSeconds)
	totalSeconds = math.max(0, math.floor(totalSeconds))

	local days = math.floor(totalSeconds / 86400)
	local hours = math.floor((totalSeconds % 86400) / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = totalSeconds % 60

	local parts = {}

	if days > 0 then
		table.insert(parts, string.format("%d day%s", days, days == 1 and "" or "s"))
	end

	if hours > 0 or days > 0 then
		table.insert(parts, string.format("%d hour%s", hours, hours == 1 and "" or "s"))
	end

	if minutes > 0 or hours > 0 or days > 0 then
		table.insert(parts, string.format("%d minute%s", minutes, minutes == 1 and "" or "s"))
	end

	table.insert(parts, string.format("%d second%s", seconds, seconds == 1 and "" or "s"))

	return table.concat(parts, ", ")
end

return function()
	local elapsed = os.clock() - SERVER_STARTED_AT

	return table.concat({
		"Server uptime: " .. formatDuration(elapsed) .. ".",
		"Job ID: " .. (game.JobId ~= "" and game.JobId or "Studio"),
		"Place ID: " .. tostring(game.PlaceId),
	}, "\n")
end
