local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local SpawnService = require(Services:WaitForChild("SpawnService"))

local AntiExploitService = nil
pcall(function()
	AntiExploitService = require(Services:WaitForChild("AntiExploitService"))
end)

local function giveGrace(player, reason)
	if AntiExploitService and typeof(AntiExploitService.AuthorizeTeleport) == "function" then
		AntiExploitService.AuthorizeTeleport(player, 8, reason)
	end

	player:SetAttribute("USARF_TeleportGraceUntil", os.clock() + 8)
	player:SetAttribute("USARF_TeleportGraceReason", reason)
end

local function waitForCharacter(player)
	local character = player.Character or player.CharacterAdded:Wait()
	character:WaitForChild("HumanoidRootPart", 10)
	character:WaitForChild("Humanoid", 10)
	return character
end

return function(context, player)
	if not player or not player.Parent then
		return "Player not found."
	end

	local oldTeamKey = player:GetAttribute("USARF_TeamKey")
	local oldTeamName = player:GetAttribute("USARF_TeamName")
	local oldSpawnKey = player:GetAttribute("USARF_SpawnKey")
	local oldRankName = player:GetAttribute("USARF_RankName")

	giveGrace(player, "CmdrRespawn")

	player:SetAttribute("USARF_SuppressMenuOpen", true)
	player:SetAttribute("USARF_InMenu", false)
	player:SetAttribute("USARF_TeamKey", oldTeamKey)
	player:SetAttribute("USARF_TeamName", oldTeamName or "")
	player:SetAttribute("USARF_SpawnKey", oldSpawnKey)
	player:SetAttribute("USARF_RankName", oldRankName)

	player:LoadCharacter()

	task.spawn(function()
		if not player or not player.Parent then
			return
		end

		waitForCharacter(player)

		player:SetAttribute("USARF_InMenu", false)
		player:SetAttribute("USARF_TeamKey", oldTeamKey)
		player:SetAttribute("USARF_TeamName", oldTeamName or "")
		player:SetAttribute("USARF_SpawnKey", oldSpawnKey)
		player:SetAttribute("USARF_RankName", oldRankName)

		task.wait(0.15)

		if oldTeamKey then
			local moved, message = SpawnService.RespawnPlayerAtCurrentTeam(player)

			if not moved then
				warn("[CmdrRespawn] Failed to move player:", message)
			end
		end

		player:SetAttribute("USARF_InMenu", false)

		task.delay(1.5, function()
			if player and player.Parent then
				player:SetAttribute("USARF_InMenu", false)
				player:SetAttribute("USARF_SuppressMenuOpen", false)
			end
		end)
	end)

	return "Respawned " .. player.Name .. "."
end
