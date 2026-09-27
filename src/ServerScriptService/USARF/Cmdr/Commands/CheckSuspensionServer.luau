local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local SuspensionService = require(Services:WaitForChild("SuspensionService"))

local function formatExpires(record)
	if record.permanent == true or record.expiresAt == nil then
		return "Permanent"
	end

	return os.date("%b %d, %Y %I:%M %p", record.expiresAt)
end

return function(context, player)
	local records = SuspensionService.GetActiveSuspensions(player.UserId)

	if #records <= 0 then
		return player.Name .. " has no active suspensions."
	end

	local lines = {
		player.Name .. " active suspension(s):",
		"",
	}

	for _, record in ipairs(records) do
		table.insert(lines, string.format(
			"%s | Status: %s | Expires: %s | Case: %s | Reason: %s",
			tostring(record.targetName or record.scope),
			tostring(record.status or "Active"),
			formatExpires(record),
			tostring(record.caseId),
			tostring(record.reason)
			))
	end

	table.insert(lines, "")
	table.insert(lines, "Use: unsuspend <caseId>")

	return table.concat(lines, "\n")
end
