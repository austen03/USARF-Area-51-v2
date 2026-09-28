local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local AccessService = {}

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local GamepassService = require(Services:WaitForChild("GamepassService"))
local CovertState = require(Services:WaitForChild("CovertState"))

local USARF = ReplicatedStorage:WaitForChild("USARF")
local USARFConfig = require(USARF.Config:WaitForChild("USARFConfig"))

local RiotService = nil
pcall(function()
	RiotService = require(Services:WaitForChild("RiotService"))
end)

local MAIN_GROUP_ID = 6033326
local MOD_GROUP_ID = 8647541
local DEV_GROUP_ID = 6773540

local HARD_BLOCKED_TEAMS = {
	["Test Subject"] = true,
}

local LIMITED_CLEARANCE_TEAMS = {
	["PMC"] = true,
}

local function listContains(list, value)
	if typeof(list) ~= "table" then
		return false
	end

	for _, item in ipairs(list) do
		if item == value then
			return true
		end
	end

	return false
end

-- A covert player is a Test Subject for doors unless they have switched their
-- clearance back on; then doors treat them as their home team.
local function getCovertHomeTeamKey(player)
	if CovertState.HasClearance(player) then
		return CovertState.GetHomeTeamKey(player)
	end

	return nil
end

local function getTeamKey(player)
	if not player then
		return nil
	end

	local covertHomeKey = getCovertHomeTeamKey(player)
	if covertHomeKey then
		return covertHomeKey
	end

	local key = player:GetAttribute("USARF_TeamKey")

	if key and key ~= "" then
		return key
	end

	if player.Team then
		return USARFConfig.GetTeamKeyFromName(player.Team.Name)
	end

	return nil
end

local function isRiotAuthorized(player)
	if not RiotService or typeof(RiotService.IsPlayerRiotAuthorized) ~= "function" then
		return false
	end

	local success, result = pcall(function()
		return RiotService.IsPlayerRiotAuthorized(player)
	end)

	return success and result == true
end

local function getRiotClearance(player)
	if not RiotService or typeof(RiotService.GetRiotClearanceForPlayer) ~= "function" then
		return nil
	end

	local success, result = pcall(function()
		return RiotService.GetRiotClearanceForPlayer(player)
	end)

	if success then
		return tonumber(result)
	end

	return nil
end

local function getTemporaryClearance(player)
	if not player then
		return nil
	end

	local value = tonumber(player:GetAttribute("USARF_TemporaryClearance"))

	if value and value > 0 then
		return value
	end

	return nil
end

local function getDoorTags(player)
	local tags = {}

	if not player then
		return tags
	end

	local team = player.Team
	local covertHomeKey = getCovertHomeTeamKey(player)

	if covertHomeKey then
		local homeTeamData = USARFConfig.Teams and USARFConfig.Teams[covertHomeKey]
		team = homeTeamData and Teams:FindFirstChild(homeTeamData.teamName)
	end

	if not team then
		return tags
	end

	for attributeName, value in pairs(team:GetAttributes()) do
		if string.sub(attributeName, 1, 4) == "door" and value == true then
			tags[attributeName] = true
		end
	end

	return tags
end

local function hasAnyDoorTag(player, list)
	if typeof(list) ~= "table" then
		return false
	end

	local tags = getDoorTags(player)

	for _, tag in ipairs(list) do
		if tags[tag] == true then
			return true
		end
	end

	return false
end

function AccessService.GetCanonicalTeamName(player)
	if not player or not player.Team then
		return nil
	end

	local teamKey = getTeamKey(player)
	local teamData = teamKey and USARFConfig.Teams and USARFConfig.Teams[teamKey]

	if teamData and teamData.teamName then
		return teamData.teamName
	end

	return player.Team.Name
end

function AccessService.GetMainRank(player)
	local rank = 0

	pcall(function()
		rank = player:GetRankInGroup(MAIN_GROUP_ID)
	end)

	return rank
end

function AccessService.IsStaffBypass(player)
	if not player then
		return false
	end

	local teamName = AccessService.GetCanonicalTeamName(player)

	if HARD_BLOCKED_TEAMS[teamName] or LIMITED_CLEARANCE_TEAMS[teamName] then
		return false
	end

	local modRank = 0
	local devRank = 0

	pcall(function()
		modRank = player:GetRankInGroup(MOD_GROUP_ID)
	end)

	pcall(function()
		devRank = player:GetRankInGroup(DEV_GROUP_ID)
	end)

	return modRank == 2
		or modRank >= 6
		or devRank >= 4
end

function AccessService.GetClearanceLevel(player)
	if not player then
		return 0
	end

	local teamName = AccessService.GetCanonicalTeamName(player)

	local riotClearance = getRiotClearance(player)
	if riotClearance then
		return riotClearance
	end

	local temporaryClearance = getTemporaryClearance(player)
	if temporaryClearance then
		return temporaryClearance
	end

	if HARD_BLOCKED_TEAMS[teamName] then
		return 0
	end

	local clearance = tonumber(
		player:GetAttribute("ClearanceLevel")
			or player:GetAttribute("SecurityClearance")
			or player:GetAttribute("SC")
			or 0
	) or 0

	if LIMITED_CLEARANCE_TEAMS[teamName] then
		clearance = 0
	end

	if GamepassService.Has(player, "StolenKeycard") then
		clearance = math.max(clearance, 4)
	end

	return clearance
end

function AccessService.GetRequiredClearance(doorSettings)
	return tonumber(doorSettings.Clearance or doorSettings.clearance or doorSettings.minCard or 0) or 0
end

function AccessService.IsTeamAllowed(teamName, doorSettings)
	if not teamName or not doorSettings then
		return false
	end

	if doorSettings.AllowedTeams and listContains(doorSettings.AllowedTeams, teamName) then
		return true
	end

	if doorSettings.allowedTeams and listContains(doorSettings.allowedTeams, teamName) then
		return true
	end

	if doorSettings.teams and doorSettings.teams[teamName] == true then
		return true
	end

	return false
end

function AccessService.IsDoorTagAllowed(player, doorSettings)
	if not player or not doorSettings then
		return false
	end

	return hasAnyDoorTag(player, doorSettings.AllowedList or doorSettings.allowedList)
end

function AccessService.IsDoorTagDenied(player, doorSettings)
	if not player or not doorSettings then
		return false
	end

	return hasAnyDoorTag(player, doorSettings.DeniedList or doorSettings.deniedList)
end

function AccessService.IsTeamDenied(teamName, doorSettings, player)
	if not teamName or not doorSettings then
		return false
	end

	if AccessService.IsDoorTagDenied(player, doorSettings) then
		return true
	end

	if HARD_BLOCKED_TEAMS[teamName]
		and not AccessService.IsDoorTagAllowed(player, doorSettings)
		and not isRiotAuthorized(player)
		and not getTemporaryClearance(player)
	then
		return true
	end

	if doorSettings.DeniedTeams and listContains(doorSettings.DeniedTeams, teamName) then
		return true
	end

	if doorSettings.deniedTeams and listContains(doorSettings.deniedTeams, teamName) then
		return true
	end

	if doorSettings.BlockedTeams and listContains(doorSettings.BlockedTeams, teamName) then
		return true
	end

	if doorSettings.blockedTeams and listContains(doorSettings.blockedTeams, teamName) then
		return true
	end

	return false
end

function AccessService.CanOpenDoor(player, doorSettings)
	if not player or not doorSettings then
		return false, "Access denied"
	end

	local teamName = AccessService.GetCanonicalTeamName(player)

	if AccessService.IsTeamDenied(teamName, doorSettings, player) then
		return false, "Your team is not authorized."
	end

	if teamName == "PMC" then
		if doorSettings.AllowPMC == true or doorSettings.allowPMC == true then
			return true, "PMC access accepted"
		end

		if AccessService.IsTeamAllowed(teamName, doorSettings) then
			return true, "PMC team access accepted"
		end

		if AccessService.IsDoorTagAllowed(player, doorSettings) then
			return true, "PMC access tag accepted"
		end

		local clearance = AccessService.GetClearanceLevel(player)
		local requiredClearance = AccessService.GetRequiredClearance(doorSettings)

		if clearance >= requiredClearance and clearance > 0 then
			return true, "Stolen keycard accepted"
		end

		return false, "PMC access denied."
	end

	if (doorSettings.AllowStaffBypass ~= false and doorSettings.allowStaffBypass ~= false)
		and AccessService.IsStaffBypass(player)
	then
		return true, "Staff bypass"
	end

	if AccessService.IsTeamAllowed(teamName, doorSettings) then
		return true, "Team accepted"
	end

	if AccessService.IsDoorTagAllowed(player, doorSettings) then
		return true, "Access tag accepted"
	end

	local clearance = AccessService.GetClearanceLevel(player)
	local requiredClearance = AccessService.GetRequiredClearance(doorSettings)

	if clearance >= requiredClearance then
		if getTemporaryClearance(player) then
			return true, "Temporary SC-" .. tostring(clearance) .. " access accepted"
		end

		if isRiotAuthorized(player) then
			return true, "Riot SC-4 access accepted"
		end

		return true, "Clearance accepted"
	end

	return false, "Requires SC-" .. tostring(requiredClearance) .. "+"
end

function AccessService.CanLockDoor(player, doorSettings)
	if not player or not doorSettings then
		return false, "Access denied"
	end

	local teamName = AccessService.GetCanonicalTeamName(player)

	if HARD_BLOCKED_TEAMS[teamName] or LIMITED_CLEARANCE_TEAMS[teamName] then
		return false, "This team cannot lock doors."
	end

	if (doorSettings.AllowStaffBypass ~= false and doorSettings.allowStaffBypass ~= false)
		and AccessService.IsStaffBypass(player)
	then
		return true, "Staff bypass"
	end

	local mainRank = AccessService.GetMainRank(player)
	local requiredRank = tonumber(doorSettings.LockRank or doorSettings.lockRank or doorSettings.minLock or 255) or 255

	if mainRank >= requiredRank then
		return true, "Rank accepted"
	end

	return false, "Requires rank " .. tostring(requiredRank) .. "+"
end

return AccessService