local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local TeamAccessService = require(Services:WaitForChild("TeamAccessService"))
local SpawnService = require(Services:WaitForChild("SpawnService"))

return function(context, players, teamName)
	local team = Teams:FindFirstChild(teamName)

	if not team then
		return "Team not found: " .. tostring(teamName)
	end

	local teamKey = TeamAccessService.ResolveTeamKey(team.Name)
	local moved = 0

	for _, player in ipairs(players) do
		if player and player.Parent then
			player:SetAttribute("USARF_InMenu", false)

			if teamKey then
				local success, message, access = SpawnService.SendPlayerToTeamSpawn(player, teamKey)

				if success then
					player:SetAttribute("USARF_TeamKey", teamKey)
					player:SetAttribute("USARF_TeamName", team.Name)
					player:SetAttribute("USARF_SpawnKey", access and access.teamData and access.teamData.spawnKey or teamKey)
					player:SetAttribute("USARF_InMenu", false)
					moved += 1
				else
					warn("[TeamServer] Failed:", player.Name, message)
				end
			else
				player.Team = team
				player.TeamColor = team.TeamColor
				player:SetAttribute("USARF_TeamName", team.Name)
				player:SetAttribute("USARF_InMenu", false)
				player:LoadCharacter()
				moved += 1
			end
		end
	end

	return string.format("Moved %d player(s) to %s.", moved, team.Name)
end
