local TerminalPermissions = {}

TerminalPermissions.MainGroupId = 6033326

TerminalPermissions.BlockedTeams = {
	["Test Subject"] = true,
	["PMC"] = true,
	["Private Military Company"] = true,
}

TerminalPermissions.Levels = {
	None = 0,
	Personnel = 3,
	Supervisor = 8,
	DepartmentCommand = 10,
	FacilityCommand = 11,
	ExecutiveCommand = 13,
	Cabinet = 15,
	VPOTUS = 16,
	POTUS = 17,
	Developer = 18,
	FederalAdministration = 19,
	Owner = 255,
}

function TerminalPermissions.IsBlockedTeam(player)
	local teamName = player and player.Team and player.Team.Name

	if not teamName then
		return false
	end

	return TerminalPermissions.BlockedTeams[teamName] == true
end

function TerminalPermissions.GetRank(player)
	if not player then
		return 0
	end

	local success, result = pcall(function()
		return player:GetRankInGroup(TerminalPermissions.MainGroupId)
	end)

	if success then
		return result
	end

	return 0
end

function TerminalPermissions.GetPermissionLevel(player)
	local rank = TerminalPermissions.GetRank(player)

	if rank >= 255 then
		return "Owner", rank
	elseif rank >= 19 then
		return "FederalAdministration", rank
	elseif rank >= 18 then
		return "Developer", rank
	elseif rank >= 17 then
		return "POTUS", rank
	elseif rank >= 16 then
		return "VPOTUS", rank
	elseif rank >= 15 then
		return "Cabinet", rank
	elseif rank >= 13 then
		return "ExecutiveCommand", rank
	elseif rank >= 11 then
		return "FacilityCommand", rank
	elseif rank >= 10 then
		return "DepartmentCommand", rank
	elseif rank >= 8 then
		return "Supervisor", rank
	elseif rank >= 3 then
		return "Personnel", rank
	end

	return "None", rank
end

function TerminalPermissions.CanAccessTerminal(player)
	if TerminalPermissions.IsBlockedTeam(player) then
		return false, "Terminal access denied for current deployment team."
	end

	local rank = TerminalPermissions.GetRank(player)

	if rank < 3 then
		return false, "Terminal access denied. Personnel clearance required."
	end

	return true
end

function TerminalPermissions.CanRun(player, command)
	local accessAllowed, accessReason = TerminalPermissions.CanAccessTerminal(player)

	if not accessAllowed then
		return false, accessReason
	end

	local rank = TerminalPermissions.GetRank(player)

	if command.MinRank and rank < command.MinRank then
		return false, "Access denied. Required group rank: " .. tostring(command.MinRank) .. "."
	end

	if command.PermissionLevel then
		local playerLevel = TerminalPermissions.GetPermissionLevel(player)
		local requiredValue = TerminalPermissions.Levels[command.PermissionLevel] or 0
		local playerValue = TerminalPermissions.Levels[playerLevel] or 0

		if playerValue < requiredValue then
			return false, "Access denied. Required clearance: " .. tostring(command.PermissionLevel) .. "."
		end
	end

	return true
end

return TerminalPermissions