local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local ModerationCaseService = require(Services:WaitForChild("ModerationCaseService"))

local PER_PAGE = 10

local VISIBLE_TYPES = {
	["Game Warn"] = true,
	["Game Ban"] = true,
	["Team Suspension"] = true,
}

local function formatTime(value)
	value = tonumber(value)

	if not value then
		return "N/A"
	end

	return os.date("%m/%d/%Y", value)
end

return function(context, player, page)
	page = math.max(1, tonumber(page) or 1)

	local allRecords = ModerationCaseService.GetPlayerCases(player.UserId)
	local records = {}

	for _, record in ipairs(allRecords) do
		if VISIBLE_TYPES[record.type] == true then
			table.insert(records, record)
		end
	end

	if #records <= 0 then
		return player.Name .. " has no disciplinary cases."
	end

	local startIndex = ((page - 1) * PER_PAGE) + 1
	local endIndex = math.min(#records, startIndex + PER_PAGE - 1)

	if startIndex > #records then
		return "No cases on page " .. tostring(page) .. "."
	end

	local lines = {
		player.Name .. " disciplinary cases - Page " .. tostring(page),
	}

	for index = startIndex, endIndex do
		local record = records[index]

		table.insert(lines, string.format(
			"%s | %s | %s | %s",
			tostring(record.caseId or "N/A"),
			tostring(record.type or "Case"),
			tostring(record.status or "Unknown"),
			formatTime(record.createdAt)
			))
	end

	return table.concat(lines, "\n")
end
