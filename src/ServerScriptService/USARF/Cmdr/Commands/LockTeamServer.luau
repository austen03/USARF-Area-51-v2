local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService
	:WaitForChild("USARF")
	:WaitForChild("Services")

local EventServerService = require(
	Services:WaitForChild("EventServerService")
)

local TeamAccessService = require(
	Services:WaitForChild("TeamAccessService")
)

local function clean(value)
	return tostring(value or "")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
end

return function(context, teamText, action)
	teamText = clean(teamText)
	action = string.lower(clean(action))

	local lowerTeam = string.lower(teamText)

	if lowerTeam == "list" then
		local locked = EventServerService.GetLockedTeams()

		if #locked == 0 then
			return "No teams are currently event locked."
		end

		return "Event locked teams:\n    " .. table.concat(locked, "\n    ")
	end

	if lowerTeam == "clear" or lowerTeam == "all" then
		EventServerService.ClearTeamLocks()
		return "Cleared all event team locks."
	end

	if not EventServerService.IsEnabled() then
		return "This server is not currently an event server."
	end

	local teamKey = TeamAccessService.ResolveTeamKey(teamText)

	if not teamKey then
		return "Could not resolve team: " .. teamText
	end

	if action == "lock" or action == "on" then
		local success, result =
			EventServerService.SetTeamLocked(teamKey, true)

		if not success then
			return tostring(result)
		end

		return "Event locked " .. teamKey .. "."
	end

	if action == "unlock" or action == "off" then
		local success, result =
			EventServerService.SetTeamLocked(teamKey, false)

		if not success then
			return tostring(result)
		end

		return "Event unlocked " .. teamKey .. "."
	end

	return "Action must be lock or unlock."
end
