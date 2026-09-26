local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local CaseIdService = require(Services:WaitForChild("CaseIdService"))

local AuditService = {}

local MAX_RECENT_LOGS = 200
local recentLogs = {}

local function getActorInfo(player)
	if not player then
		return nil
	end

	return {
		userId = player.UserId,
		username = player.Name,
		displayName = player.DisplayName,
		teamName = player.Team and player.Team.Name or nil,
	}
end

local function trimRecentLogs()
	while #recentLogs > MAX_RECENT_LOGS do
		table.remove(recentLogs, 1)
	end
end

function AuditService.Log(data)
	data = data or {}

	local entry = {
		caseId = data.caseId or CaseIdService.Generate(),
		timestamp = os.time(),

		category = data.category or "General",
		action = data.action or "Unknown",

		actor = getActorInfo(data.actor),
		target = getActorInfo(data.target),

		message = data.message or "",
		reason = data.reason or "",

		metadata = data.metadata or {},
		external = data.external == true,
		severity = data.severity or "Info",
	}

	table.insert(recentLogs, entry)
	trimRecentLogs()

	return entry
end

function AuditService.GetRecentLogs()
	local copy = {}

	for index, entry in ipairs(recentLogs) do
		copy[index] = entry
	end

	return copy
end

function AuditService.FindByCaseId(caseId)
	for _, entry in ipairs(recentLogs) do
		if entry.caseId == caseId then
			return entry
		end
	end

	return nil
end

return AuditService