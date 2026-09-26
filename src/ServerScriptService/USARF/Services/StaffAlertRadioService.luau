local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local StaffAlertRadioService = {}

local RadioService = nil

local function clean(value)
	return tostring(value or "")
		:gsub("%s+", " ")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
end

local function getRadioService()
	if RadioService then
		return RadioService
	end

	local success, result = pcall(function()
		return require(Services:WaitForChild("RadioService"))
	end)

	if not success then
		warn(
			"[StaffAlertRadioService] Failed to load RadioService:",
			result
		)

		return nil
	end

	RadioService = result
	return RadioService
end

local function callRadioSystem(channelKey, message, priority)
	local radio = getRadioService()

	if not radio then
		warn("[StaffAlertRadioService] RadioService unavailable.")
		return false
	end

	if typeof(radio.System) ~= "function" then
		warn(
			"[StaffAlertRadioService] RadioService.System is missing."
		)

		return false
	end

	local success, result = pcall(function()
		return radio.System(
			channelKey,
			message,
			priority
		)
	end)

	if not success then
		warn(
			"[StaffAlertRadioService] Failed to send radio message:",
			result
		)

		return false
	end

	return result ~= false
end

function StaffAlertRadioService.Send(category, message, priority)
	category = string.upper(
		clean(category ~= nil and category or "STAFF")
	)

	message = clean(message)

	if message == "" then
		return false
	end

	return callRadioSystem(
		"staffalerts",
		"[" .. category .. "] " .. message,
		priority or 5
	)
end

function StaffAlertRadioService.System(message, priority)
	return StaffAlertRadioService.Send(
		"SYSTEM",
		message,
		priority or 5
	)
end

function StaffAlertRadioService.GameWarn(player, reason, caseId)
	local username = player and player.Name or "Unknown"

	local message =
		username
		.. " - "
		.. tostring(reason or "No reason provided.")

	if caseId then
		message ..= " - Case: " .. tostring(caseId)
	end

	return StaffAlertRadioService.Send(
		"GAME WARN",
		message,
		5
	)
end

function StaffAlertRadioService.GameBan(
	userIdOrPlayer,
	reason,
	caseId
)
	local username = "Unknown"

	if typeof(userIdOrPlayer) == "Instance" then
		username = userIdOrPlayer.Name
	else
		username = tostring(
			userIdOrPlayer or "Unknown"
		)
	end

	local message =
		username
		.. " - "
		.. tostring(reason or "No reason provided.")

	if caseId then
		message ..= " - Case: " .. tostring(caseId)
	end

	return StaffAlertRadioService.Send(
		"GAME BAN",
		message,
		5
	)
end

function StaffAlertRadioService.TeamSuspension(
	usernameOrUserId,
	scopeName,
	reason,
	caseId
)
	local message =
		tostring(usernameOrUserId or "Unknown")
		.. " - "
		.. tostring(scopeName or "Unknown Scope")
		.. " - "
		.. tostring(reason or "No reason provided.")

	if caseId then
		message ..= " - Case: " .. tostring(caseId)
	end

	return StaffAlertRadioService.Send(
		"TEAM SUSPENSION",
		message,
		5
	)
end

function StaffAlertRadioService.DepartmentSuspension(
	usernameOrUserId,
	departmentName,
	reason,
	caseId
)
	return StaffAlertRadioService.TeamSuspension(
		usernameOrUserId,
		departmentName,
		reason,
		caseId
	)
end

function StaffAlertRadioService.AreaSuspension(
	usernameOrUserId,
	areaName,
	reason,
	caseId
)
	local message =
		tostring(usernameOrUserId or "Unknown")
		.. " - "
		.. tostring(areaName or "Unknown Area")
		.. " - "
		.. tostring(reason or "No reason provided.")

	if caseId then
		message ..= " - Case: " .. tostring(caseId)
	end

	return StaffAlertRadioService.Send(
		"AREA SUSPENSION",
		message,
		5
	)
end

function StaffAlertRadioService.FacilitySuspension(
	usernameOrUserId,
	reason,
	caseId
)
	local message =
		tostring(usernameOrUserId or "Unknown")
		.. " - Facility Wide - "
		.. tostring(reason or "No reason provided.")

	if caseId then
		message ..= " - Case: " .. tostring(caseId)
	end

	return StaffAlertRadioService.Send(
		"FACILITY SUSPENSION",
		message,
		5
	)
end

function StaffAlertRadioService.SuspensionRemoved(
	usernameOrUserId,
	scopeName,
	caseId
)
	local message =
		tostring(usernameOrUserId or "Unknown")
		.. " - "
		.. tostring(scopeName or "Unknown Scope")

	if caseId then
		message ..= " - Case: " .. tostring(caseId)
	end

	return StaffAlertRadioService.Send(
		"SUSPENSION REMOVED",
		message,
		5
	)
end

function StaffAlertRadioService.ExploitDetected(
	player,
	detection,
	severity
)
	local username = player and player.Name or "Unknown"

	return StaffAlertRadioService.Send(
		"EXPLOIT",
		username
			.. " - "
			.. tostring(detection or "Unknown Detection")
			.. " - Severity: "
			.. tostring(severity or "Info"),
		5
	)
end

return StaffAlertRadioService