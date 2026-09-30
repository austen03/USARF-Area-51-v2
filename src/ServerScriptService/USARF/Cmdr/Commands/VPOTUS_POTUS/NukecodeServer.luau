local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local MainGroupRanks = require(ReplicatedStorage:WaitForChild("USARF"):WaitForChild("Config"):WaitForChild("MainGroupRanks"))

local function getMainRank(player)
	local rank = 0

	pcall(function()
		rank = player:GetRankInGroup(MainGroupRanks.GroupId)
	end)

	return MainGroupRanks.EffectiveRank(MainGroupRanks.GroupId, rank)
end

local function canViewCode(player)
	if not player then
		return false
	end

	if getMainRank(player) >= 15 then
		return true
	end

	if player.Team then
		return player.Team.Name == "President of the United States"
			or player.Team.Name == "Vice President of the United States"
			or player.Team.Name == "Federal Administration"
	end

	return false
end

return function(context)
	local executor = context.Executor

	if not canViewCode(executor) then
		return "You are not authorized to view the nuclear activation code."
	end

	local code = tostring(ReplicatedStorage:GetAttribute("USARF_NuclearActivationCode") or "")

	if code == "" then
		local usarfFolder = ReplicatedStorage:FindFirstChild("USARF")
		local stateFolder = usarfFolder and usarfFolder:FindFirstChild("State")
		local value = stateFolder and stateFolder:FindFirstChild("NuclearActivationCode")

		if value then
			code = tostring(value.Value or ""):gsub("Current nuclear activation code:%s*", "")
		end
	end

	if code == "" then
		return "No nuclear activation code has been generated for this server."
	end

	return "Current nuclear activation code: " .. code
end
