local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")

local USARFConfig = require(Config:WaitForChild("USARFConfig"))

local PermissionService = {}

local rankCache = {}
local roleCache = {}
local gamepassCache = {}

local function getUserCache(cache, player)
	if not player then
		return nil
	end

	cache[player.UserId] = cache[player.UserId] or {}
	return cache[player.UserId]
end

local function getPlayerRankInGroup(player, groupId)
	if not player or not groupId then
		return 0
	end

	local userCache = getUserCache(rankCache, player)

	if userCache[groupId] ~= nil then
		return userCache[groupId]
	end

	local success, result = pcall(function()
		return player:GetRankInGroup(groupId)
	end)

	if not success then
		warn("[PermissionService] Failed to get rank in group:", player.Name, groupId, result)
		userCache[groupId] = 0
		return 0
	end

	userCache[groupId] = result or 0
	return userCache[groupId]
end

local function getPlayerRoleInGroup(player, groupId)
	if not player or not groupId then
		return nil
	end

	local userCache = getUserCache(roleCache, player)

	if userCache[groupId] ~= nil then
		return userCache[groupId]
	end

	local success, result = pcall(function()
		return player:GetRoleInGroup(groupId)
	end)

	if not success then
		warn("[PermissionService] Failed to get role in group:", player.Name, groupId, result)
		userCache[groupId] = false
		return nil
	end

	if result == "" then
		userCache[groupId] = false
		return nil
	end

	userCache[groupId] = result
	return result
end

local function ownsGamepass(player, gamepassId)
	if not player or not gamepassId then
		return false
	end

	local userCache = getUserCache(gamepassCache, player)

	if userCache[gamepassId] ~= nil then
		return userCache[gamepassId]
	end

	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)

	if not success then
		warn("[PermissionService] Failed to check gamepass:", player.Name, gamepassId, result)
		userCache[gamepassId] = false
		return false
	end

	userCache[gamepassId] = result == true
	return userCache[gamepassId]
end

local function checkGroupRule(player, rule)
	local rank = getPlayerRankInGroup(player, rule.groupId)

	if rule.exactRank then
		return rank == rule.exactRank, rank
	end

	if rule.minRank then
		return rank >= rule.minRank, rank
	end

	if rule.maxRank then
		return rank <= rule.maxRank, rank
	end

	return false, rank
end

local function getRequirementText(requirements)
	if not requirements then
		return "No requirement configured"
	end

	if requirements.type == "open" then
		return "Open Access"
	end

	if requirements.type == "gamepass" then
		return "Required: Gamepass"
	end

	if requirements.type == "group" then
		if requirements.minRank then
			return "Required: Group Rank " .. tostring(requirements.minRank) .. "+"
		end

		if requirements.exactRank then
			return "Required: Group Rank " .. tostring(requirements.exactRank)
		end
	end

	if requirements.type == "groupAny" then
		return "Required: One valid group rank condition"
	end

	return "Requirement not recognized"
end

local function getBestRankName(player, teamData)
	local requirements = teamData and teamData.requirements

	if not requirements then
		return "Unknown"
	end

	if requirements.type == "group" then
		local role = getPlayerRoleInGroup(player, requirements.groupId)
		return role or "Unknown"
	end

	if requirements.type == "groupAny" then
		for _, rule in ipairs(requirements.rules or {}) do
			local passed = checkGroupRule(player, rule)

			if passed then
				local role = getPlayerRoleInGroup(player, rule.groupId)
				return role or "Unknown"
			end
		end
	end

	if requirements.type == "open" then
		return "Guest"
	end

	if requirements.type == "gamepass" then
		return "Contractor"
	end

	return "Unknown"
end

local function normalizeAdminLevelName(levelName)
	levelName = tostring(levelName or ""):gsub("^%s+", ""):gsub("%s+$", "")

	if levelName == "" then
		return "None"
	end

	local compact = string.lower(levelName:gsub("%s+", ""):gsub("_", ""))

	if compact == "training" then
		return "Training"
	elseif compact == "vpotuspotus" or compact == "potus" or compact == "vpotus" then
		return "VPOTUS_POTUS"
	elseif compact == "moderator" or compact == "mod" then
		return "Moderator"
	elseif compact == "administrator" or compact == "admin" then
		return "Administrator"
	elseif compact == "developer" or compact == "dev" then
		return "Developer"
	elseif compact == "owner" then
		return "Owner"
	end

	return "None"
end

function PermissionService.ClearPlayerCache(player)
	if not player then
		return
	end

	rankCache[player.UserId] = nil
	roleCache[player.UserId] = nil
	gamepassCache[player.UserId] = nil
end

function PermissionService.GetRank(player, groupId)
	return getPlayerRankInGroup(player, groupId)
end

function PermissionService.GetRole(player, groupId)
	return getPlayerRoleInGroup(player, groupId)
end

function PermissionService.HasGamepass(player, gamepassIdOrName)
	local gamepassId = gamepassIdOrName

	if typeof(gamepassIdOrName) == "string" then
		gamepassId = USARFConfig.Gamepasses[gamepassIdOrName]
	end

	return ownsGamepass(player, gamepassId)
end

function PermissionService.GetMainRank(player)
	return getPlayerRankInGroup(player, USARFConfig.Groups.Main)
end

function PermissionService.GetModRank(player)
	return getPlayerRankInGroup(player, USARFConfig.Groups.Moderation)
end

function PermissionService.GetDevRank(player)
	return getPlayerRankInGroup(player, USARFConfig.Groups.Developer)
end

function PermissionService.GetTeamKey(player)
	if not player or not player.Team then
		return nil
	end

	return USARFConfig.GetTeamKeyFromName(player.Team.Name)
end

function PermissionService.GetTeam(playerOrTeamKey)
	if typeof(playerOrTeamKey) == "Instance" then
		local teamKey = PermissionService.GetTeamKey(playerOrTeamKey)
		return teamKey and USARFConfig.Teams[teamKey] or nil
	end

	return USARFConfig.Teams[playerOrTeamKey]
end

function PermissionService.GetAllTeams()
	return USARFConfig.Teams
end

function PermissionService.GetCategories()
	return USARFConfig.Categories
end

function PermissionService.GetClearance(player)
	if not player then
		return 0
	end

	local teamKey = PermissionService.GetTeamKey(player)

	if teamKey and USARFConfig.Clearance.TeamOverride[teamKey] then
		return USARFConfig.Clearance.TeamOverride[teamKey]
	end

	local rank = PermissionService.GetMainRank(player)

	for _, rule in ipairs(USARFConfig.Clearance.RankMap or {}) do
		if rule.exactRank and rank == rule.exactRank then
			return rule.clearance or 0
		end

		if rule.minRank and rank >= rule.minRank then
			return rule.clearance or 0
		end
	end

	return 0
end

function PermissionService.GetAdminLevelValue(levelName)
	levelName = normalizeAdminLevelName(levelName)
	return USARFConfig.Admin.Levels[levelName] or 0
end

function PermissionService.GetAdminLevelNameFromValue(levelValue)
	return USARFConfig.Admin.LevelLabels[levelValue] or "None"
end

function PermissionService.GetGroupAdminLevel(player)
	if not player then
		return "None", 0
	end

	local bestLevelName = "None"
	local bestLevelValue = 0

	local function applyLevel(levelName)
		levelName = normalizeAdminLevelName(levelName)
		local levelValue = PermissionService.GetAdminLevelValue(levelName)

		if levelValue > bestLevelValue then
			bestLevelName = levelName
			bestLevelValue = levelValue
		end
	end

	local mainConfig = USARFConfig.Admin.MainServerRanks.MainGroup
	if mainConfig then
		local rank = getPlayerRankInGroup(player, mainConfig.GroupId)
		local exactLevel = mainConfig.ExactRanks and mainConfig.ExactRanks[rank]

		if exactLevel then
			applyLevel(exactLevel)
		end
	end

	local modConfig = USARFConfig.Admin.MainServerRanks.ModerationGroup
	if modConfig then
		local rank = getPlayerRankInGroup(player, modConfig.GroupId)
		local exactLevel = modConfig.ExactRanks and modConfig.ExactRanks[rank]

		if exactLevel then
			applyLevel(exactLevel)
		end
	end

	local devConfig = USARFConfig.Admin.MainServerRanks.DeveloperGroup
	if devConfig then
		local rank = getPlayerRankInGroup(player, devConfig.GroupId)

		for _, minimumRule in ipairs(devConfig.MinimumRanks or {}) do
			if rank >= minimumRule.Rank then
				applyLevel(minimumRule.Level)
			end
		end
	end

	return bestLevelName, bestLevelValue
end

function PermissionService.CanAccessTeam(player, teamKey)
	local teamData = USARFConfig.Teams[teamKey]

	if not teamData then
		return {
			canAccess = false,
			status = "denied",
			reason = "Team does not exist",
			requiredText = "Invalid team",
			rankName = "Unknown",
			teamKey = teamKey,
		}
	end

	if teamData.hidden == true then
		return {
			canAccess = false,
			status = "hidden",
			reason = "Team is hidden",
			requiredText = "Hidden team",
			rankName = "Unknown",
			teamKey = teamKey,
			teamData = teamData,
		}
	end

	local requirements = teamData.requirements

	if not requirements then
		return {
			canAccess = false,
			status = "denied",
			reason = "No requirements configured",
			requiredText = "No requirements configured",
			rankName = "Unknown",
			teamKey = teamKey,
			teamData = teamData,
		}
	end

	if requirements.type == "open" then
		return {
			canAccess = true,
			status = "granted",
			reason = "Access Granted",
			requiredText = "Open Access",
			rankName = getBestRankName(player, teamData),
			teamKey = teamKey,
			teamData = teamData,
		}
	end

	if requirements.type == "gamepass" then
		local hasPass = ownsGamepass(player, requirements.gamepassId)

		return {
			canAccess = hasPass,
			status = hasPass and "granted" or "denied",
			reason = hasPass and "Access Granted" or "Access Denied",
			requiredText = hasPass and "Gamepass Owned" or "Required: Gamepass",
			rankName = getBestRankName(player, teamData),
			teamKey = teamKey,
			teamData = teamData,
		}
	end

	if requirements.type == "group" then
		local passed, rank = checkGroupRule(player, requirements)

		return {
			canAccess = passed,
			status = passed and "granted" or "denied",
			reason = passed and "Access Granted" or "Access Denied",
			requiredText = passed and "Requirement Met" or getRequirementText(requirements),
			rankName = passed and getBestRankName(player, teamData) or "No Access",
			groupRank = rank,
			teamKey = teamKey,
			teamData = teamData,
		}
	end

	if requirements.type == "groupAny" then
		for _, rule in ipairs(requirements.rules or {}) do
			local passed, rank = checkGroupRule(player, rule)

			if passed then
				return {
					canAccess = true,
					status = "granted",
					reason = "Access Granted",
					requiredText = "Requirement Met",
					rankName = getBestRankName(player, teamData),
					groupRank = rank,
					teamKey = teamKey,
					teamData = teamData,
				}
			end
		end

		return {
			canAccess = false,
			status = "denied",
			reason = "Access Denied",
			requiredText = getRequirementText(requirements),
			rankName = "No Access",
			teamKey = teamKey,
			teamData = teamData,
		}
	end

	return {
		canAccess = false,
		status = "denied",
		reason = "Unknown requirement type",
		requiredText = "Requirement not recognized",
		rankName = "Unknown",
		teamKey = teamKey,
		teamData = teamData,
	}
end

function PermissionService.GetTeamAccessList(player)
	local accessList = {}

	for teamKey, teamData in pairs(USARFConfig.Teams) do
		if teamData.hidden ~= true then
			accessList[teamKey] = PermissionService.CanAccessTeam(player, teamKey)
		end
	end

	return accessList
end

function PermissionService.GetTeamsByCategory(player)
	local grouped = {}

	for _, category in ipairs(USARFConfig.Categories) do
		grouped[category.key] = {
			category = category,
			teams = {},
		}
	end

	for teamKey, teamData in pairs(USARFConfig.Teams) do
		if teamData.hidden ~= true and teamData.category and grouped[teamData.category] then
			local access = PermissionService.CanAccessTeam(player, teamKey)

			table.insert(grouped[teamData.category].teams, {
				teamKey = teamKey,
				teamData = teamData,
				access = access,
			})
		end
	end

	for _, group in pairs(grouped) do
		table.sort(group.teams, function(a, b)
			return tostring(a.teamData.displayName or a.teamKey) < tostring(b.teamData.displayName or b.teamKey)
		end)
	end

	return grouped
end

function PermissionService.HasRadio(player)
	if not player then
		return false
	end

	if player:GetAttribute("USARF_ModMode") == true or player:GetAttribute("USARF_RadioModMode") == true then
		return true
	end

	local teamKey = PermissionService.GetTeamKey(player)

	if not teamKey then
		return false
	end

	if USARFConfig.Radio.BlockedTeams[teamKey] then
		return false
	end

	return true
end

function PermissionService.CanReadRadioChannel(player, channelKey)
	if not player then
		return false
	end

	if player:GetAttribute("USARF_ModMode") == true or player:GetAttribute("USARF_RadioModMode") == true then
		return true
	end

	if not PermissionService.HasRadio(player) then
		return false
	end

	local mainRank = PermissionService.GetMainRank(player)
	local modRank = PermissionService.GetModRank(player)
	local teamKey = PermissionService.GetTeamKey(player)

	for _, channel in ipairs(USARFConfig.Radio.Channels) do
		if channel.key == channelKey then
			if channel.everyoneWithRadio then
				return true
			end

			if channel.modRankExactly and modRank == channel.modRankExactly then
				return true
			end

			if channel.altMainRank and mainRank >= channel.altMainRank then
				return true
			end

			if channel.minMainRank and mainRank >= channel.minMainRank then
				return true
			end

			if channel.teamKeys and table.find(channel.teamKeys, teamKey) then
				return true
			end

			return false
		end
	end

	return false
end

function PermissionService.CanSendRadioChannel(player, channelKey)
	if not player then
		return false
	end

	for _, channel in ipairs(USARFConfig.Radio.Channels) do
		if channel.key == channelKey and channel.readOnly then
			return false
		end
	end

	if player:GetAttribute("USARF_ModMode") == true or player:GetAttribute("USARF_RadioModMode") == true then
		return true
	end

	return PermissionService.CanReadRadioChannel(player, channelKey)
end

function PermissionService.GetVisibleRadioChannels(player)
	local visible = {}

	for _, channel in ipairs(USARFConfig.Radio.Channels) do
		if PermissionService.CanReadRadioChannel(player, channel.key) then
			table.insert(visible, {
				key = channel.key,
				name = channel.name,
				readOnly = channel.readOnly == true,
			})
		end
	end

	return visible
end

function PermissionService.CanSeeRedactedRadio(player)
	if not player then
		return false
	end

	if player:GetAttribute("USARF_ModMode") == true or player:GetAttribute("USARF_RadioModMode") == true then
		return true
	end

	local mainRank = PermissionService.GetMainRank(player)
	local modRank = PermissionService.GetModRank(player)

	return mainRank >= USARFConfig.Radio.RedactedViewerMainRank
		or modRank == USARFConfig.Radio.RedactedViewerModRank
end

function PermissionService.Can(player, permissionName)
	permissionName = tostring(permissionName or "")

	if permissionName == "UseCmdr" then
		local _, levelValue = PermissionService.GetGroupAdminLevel(player)
		return levelValue >= USARFConfig.Admin.Levels.Moderator
	end

	if permissionName == "AccessRadioCommand" then
		return PermissionService.CanReadRadioChannel(player, "command")
	end

	if permissionName == "BypassLockdown" then
		local teamKey = PermissionService.GetTeamKey(player)
		return teamKey == "SpecOpsAIG"
			or teamKey == "SecretService"
			or teamKey == "President"
			or teamKey == "VicePresident"
			or teamKey == "FederalAdministration"
	end

	if permissionName == "CanSeeRedacted" then
		return PermissionService.CanSeeRedactedRadio(player)
	end

	return false
end

return PermissionService