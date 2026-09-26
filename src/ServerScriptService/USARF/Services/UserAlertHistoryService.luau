local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local GetUserAlertHistoryRemote = Remotes:WaitForChild("GetUserAlertHistory")

local UserAlertHistoryService = {}

local MAX_HISTORY = 300
local MAX_PER_USER = 50

local history = {}

local function trimHistory()
	while #history > MAX_HISTORY do
		table.remove(history)
	end
end

function UserAlertHistoryService.Record(alert)
	if not alert then
		return nil
	end

	local playerInfo = alert.player or {}

	local record = {
		caseId = alert.caseId,
		createdAt = alert.createdAt or os.time(),

		userId = playerInfo.userId,
		username = playerInfo.username,
		displayName = playerInfo.displayName,
		teamName = playerInfo.teamName,

		alertType = alert.alertType,
		severity = alert.severity,
		source = alert.source,
		message = alert.message,

		external = alert.external == true,
		metadata = alert.metadata or {},
	}

	table.insert(history, 1, record)
	trimHistory()

	print(
		string.format(
			"[UserAlertHistoryService] Recorded | %s | %s | %s",
			tostring(record.caseId),
			tostring(record.username),
			tostring(record.alertType)
		)
	)

	return record
end

function UserAlertHistoryService.GetRecent(limit)
	limit = limit or 25

	local results = {}

	for index, record in ipairs(history) do
		if index > limit then
			break
		end

		table.insert(results, record)
	end

	return results
end

function UserAlertHistoryService.GetPlayerHistory(userId)
	local results = {}

	for _, record in ipairs(history) do
		if record.userId == userId then
			table.insert(results, record)

			if #results >= MAX_PER_USER then
				break
			end
		end
	end

	return results
end

function UserAlertHistoryService.FindByCaseId(caseId)
	for _, record in ipairs(history) do
		if record.caseId == caseId then
			return record
		end
	end

	return nil
end

GetUserAlertHistoryRemote.OnServerInvoke = function(player, mode, value)
	if mode == "player" then
		return UserAlertHistoryService.GetPlayerHistory(tonumber(value))
	end

	if mode == "case" then
		local record = UserAlertHistoryService.FindByCaseId(tostring(value))

		if record then
			return { record }
		end

		return {}
	end

	return UserAlertHistoryService.GetRecent(25)
end

return UserAlertHistoryService