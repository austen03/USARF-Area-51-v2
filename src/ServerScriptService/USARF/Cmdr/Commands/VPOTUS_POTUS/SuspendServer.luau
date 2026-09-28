local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local TeamConfig = require(USARF:WaitForChild("Config"):WaitForChild("TeamConfig"))

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local SuspensionService = require(Services:WaitForChild("SuspensionService"))

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local MENU_REFRESH_REMOTE_NAME = "ModerationMenuRefresh"

local VALID_SCOPES = {
	facility = true,
	civil = true,
	combative = true,
	intelligence = true,
	leadership = true,
	protection = true,
	team = true,
	current = true,
}

local function getOrCreateRemote()
	local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = REMOTE_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	local remote = folder:FindFirstChild(MENU_REFRESH_REMOTE_NAME)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = MENU_REFRESH_REMOTE_NAME
		remote.Parent = folder
	end

	return remote
end

local menuRefreshRemote = getOrCreateRemote()

local function clean(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function lower(value)
	return string.lower(clean(value))
end

local function parseDuration(text)
	text = lower(text):gsub("%s+", "")

	if text == "0" or text == "perm" or text == "permanent" then
		return 0
	end

	local number, unit = string.match(text, "^(%d+)([mhdw])$")
	number = tonumber(number)

	if not number or not unit then
		return nil
	end

	if unit == "m" then
		return number * 60
	elseif unit == "h" then
		return number * 3600
	elseif unit == "d" then
		return number * 86400
	elseif unit == "w" then
		return number * 604800
	end

	return nil
end

local function formatDuration(seconds)
	if seconds == 0 or seconds == nil then
		return "Permanent"
	end

	if seconds % 604800 == 0 then
		return tostring(seconds / 604800) .. " week(s)"
	elseif seconds % 86400 == 0 then
		return tostring(seconds / 86400) .. " day(s)"
	elseif seconds % 3600 == 0 then
		return tostring(seconds / 3600) .. " hour(s)"
	elseif seconds % 60 == 0 then
		return tostring(seconds / 60) .. " minute(s)"
	end

	return tostring(seconds) .. " seconds"
end

local function resolveTeamKey(teamText)
	teamText = clean(teamText)

	if teamText == "" then
		return nil
	end

	local wanted = lower(teamText)

	for teamKey, teamData in pairs(TeamConfig.Teams or {}) do
		local displayName = teamData.displayName or teamData.teamName or teamKey
		local teamName = teamData.teamName or displayName

		if lower(teamKey) == wanted
			or lower(displayName) == wanted
			or lower(teamName) == wanted
		then
			return teamKey
		end
	end

	for teamKey, teamData in pairs(TeamConfig.Teams or {}) do
		local displayName = teamData.displayName or teamData.teamName or teamKey
		local teamName = teamData.teamName or displayName

		if string.find(lower(displayName), wanted, 1, true)
			or string.find(lower(teamName), wanted, 1, true)
			or string.find(lower(teamKey), wanted, 1, true)
		then
			return teamKey
		end
	end

	return nil
end

local function refreshMenu(player, openMenu)
	if not player then
		return
	end

	menuRefreshRemote:FireClient(player, {
		action = openMenu and "OpenMenu" or "RefreshMenu",
		reason = "SuspensionUpdated",
	})
end

local function forcePlayerToMenu(player)
	if not player then
		return
	end

	local loadingTeam = Teams:FindFirstChild("Loading")

	if loadingTeam then
		player.Team = loadingTeam
	end

	player:SetAttribute("USARF_InMenu", true)
	player:SetAttribute("USARF_TeamKey", nil)
	player:SetAttribute("USARF_TeamName", "")
	player:SetAttribute("USARF_SpawnKey", nil)

	refreshMenu(player, true)
end

local function shouldForceTargetToMenu(player)
	if not player then
		return false
	end

	local currentTeamKey = player:GetAttribute("USARF_TeamKey")

	if not currentTeamKey or currentTeamKey == "" then
		return true
	end

	local check = SuspensionService.IsSuspendedFromTeam(player.UserId, currentTeamKey)
	return check and check.suspended == true
end

return function(context, player, scope, durationText, reason, teamText)
	scope = lower(scope)
	reason = clean(reason)

	if reason == "" then
		reason = "No reason provided."
	end

	if not VALID_SCOPES[scope] then
		return "Scope must be facility, civil, combative, intelligence, leadership, protection, team, or current."
	end

	local durationSeconds = parseDuration(durationText)

	if durationSeconds == nil then
		return "Duration must be like 30m, 2h, 7d, 1w, perm, or 0."
	end

	local issuer = context.Executor
	local ok, result

	if scope == "facility" then
		ok, result = SuspensionService.SuspendFacility(
			player.UserId,
			issuer.UserId,
			reason,
			durationSeconds
		)

	elseif scope == "civil"
		or scope == "combative"
		or scope == "intelligence"
		or scope == "leadership"
		or scope == "protection"
	then
		ok, result = SuspensionService.SuspendArea(
			player.UserId,
			scope,
			issuer.UserId,
			reason,
			durationSeconds
		)

	elseif scope == "team" then
		local teamKey = resolveTeamKey(teamText)

		if not teamKey then
			return "Could not resolve team. Use the team display name or TeamConfig key."
		end

		ok, result = SuspensionService.SuspendDepartment(
			player.UserId,
			teamKey,
			issuer.UserId,
			reason,
			durationSeconds
		)

	elseif scope == "current" then
		local teamKey = player:GetAttribute("USARF_TeamKey")

		if not teamKey or teamKey == "" then
			return "Target has no current USARF_TeamKey."
		end

		ok, result = SuspensionService.SuspendDepartment(
			player.UserId,
			teamKey,
			issuer.UserId,
			reason,
			durationSeconds
		)
	end

	if not ok then
		return tostring(result)
	end

	if shouldForceTargetToMenu(player) then
		forcePlayerToMenu(player)
	else
		refreshMenu(player, false)
	end

	refreshMenu(issuer, false)

	return string.format(
		"Suspended %s | Scope: %s | Duration: %s | Case: %s",
		player.Name,
		tostring(result.targetName or result.scope),
		formatDuration(durationSeconds),
		tostring(result.caseId)
	)
end
