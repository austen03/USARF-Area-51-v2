local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local TeamConfig = require(USARF.Config.TeamConfig)
local MainGroupRanks = require(USARF.Config:WaitForChild("MainGroupRanks"))

local MAIN_GROUP_ID = MainGroupRanks.GroupId

local RankService = {}

local DEFAULT_RANK = "Guest"


local function safeGetRank(player, groupId)
	local success, result = pcall(function()
		return player:GetRankInGroup(groupId)
	end)

	if not success then
		warn("[RankService] Failed to get rank for group:", groupId, result)
		return 0
	end

	return MainGroupRanks.EffectiveRank(groupId, result or 0)
end

local function safeGetRole(player, groupId)
	local success, result = pcall(function()
		return player:GetRoleInGroup(groupId)
	end)

	if not success then
		warn("[RankService] Failed to get role for group:", groupId, result)
		return "Guest"
	end

	if result == nil or result == "" or result == "Guest" then
		return DEFAULT_RANK
	end

	return result
end

function RankService.GetMainGroupRank(player)
	local rank = safeGetRank(player, MAIN_GROUP_ID)

	if rank <= 0 then
		return "Guest"
	end

	return safeGetRole(player, MAIN_GROUP_ID)
end

local function getPrimaryGroupIdFromRequirements(requirements, player)
	if not requirements then
		return nil
	end

	if requirements.type == "group" then
		return requirements.groupId
	end

	if requirements.type == "groupAny" then
		for _, rule in ipairs(requirements.rules or {}) do
			local rank = safeGetRank(player, rule.groupId)

			if rule.exactRank and rank == rule.exactRank then
				return rule.groupId
			end

			if rule.minRank and rank >= rule.minRank then
				return rule.groupId
			end

			if rule.maxRank and rank <= rule.maxRank then
				return rule.groupId
			end
		end

		local firstRule = requirements.rules and requirements.rules[1]
		return firstRule and firstRule.groupId or nil
	end

	return nil
end

function RankService.GetRankForGroup(player, groupId)
	if not groupId then
		return DEFAULT_RANK
	end

	return safeGetRole(player, groupId)
end

function RankService.GetRankNumberForGroup(player, groupId)
	if not groupId then
		return 0
	end

	return safeGetRank(player, groupId)
end

function RankService.GetDisplayRankForTeam(player, teamKey)
	local teamData = TeamConfig.Teams[teamKey]

	if not teamData then
		return DEFAULT_RANK
	end

	if teamData.hidden then
		return DEFAULT_RANK
	end

	local requirements = teamData.requirements

	if not requirements then
		return DEFAULT_RANK
	end

	if requirements.type == "open" then
		return RankService.GetMainGroupRank(player)
	end

	if requirements.type == "gamepass" then
		return "Contractor"
	end

	local groupId = getPrimaryGroupIdFromRequirements(requirements, player)

	if not groupId then
		return DEFAULT_RANK
	end

	return safeGetRole(player, groupId)
end

function RankService.GetProfile(player)
	return {
		userId = player.UserId,
		username = player.Name,
		displayName = player.DisplayName,
		currentTeamKey = player:GetAttribute("USARF_TeamKey"),
		currentTeamName = player:GetAttribute("USARF_TeamName"),
		currentRank = player:GetAttribute("USARF_TeamKey")
			and RankService.GetDisplayRankForTeam(player, player:GetAttribute("USARF_TeamKey"))
			or DEFAULT_RANK,
	}
end

return RankService