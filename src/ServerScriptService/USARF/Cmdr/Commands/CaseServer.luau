local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local ModerationCaseService = require(Services:WaitForChild("ModerationCaseService"))

local function formatTime(value)
	value = tonumber(value)

	if not value then
		return "N/A"
	end

	return os.date("%b %d, %Y %I:%M %p", value)
end

return function(context, caseId)
	local record = ModerationCaseService.GetCase(caseId)

	if not record then
		return "Case not found."
	end

	local lines = {
		"Case ID: " .. tostring(record.caseId),
		"Type: " .. tostring(record.type or "Unknown"),
		"Status: " .. tostring(record.status or "Unknown"),
		"Target: " .. tostring(record.targetUsername or "Unknown") .. " (" .. tostring(record.targetUserId or "N/A") .. ")",
		"Moderator: " .. tostring(record.moderator or "Unknown"),
		"Reason: " .. tostring(record.reason or "N/A"),
		"Created: " .. formatTime(record.createdAt),
	}

	if record.expiresAt then
		table.insert(lines, "Expires: " .. formatTime(record.expiresAt))
	elseif record.duration then
		table.insert(lines, "Duration: " .. tostring(record.duration))
	end

	if record.voided then
		table.insert(lines, "Voided By: " .. tostring(record.voidedBy or "Unknown"))
		table.insert(lines, "Void Reason: " .. tostring(record.voidReason or "N/A"))
	end

	return table.concat(lines, "\n")
end
