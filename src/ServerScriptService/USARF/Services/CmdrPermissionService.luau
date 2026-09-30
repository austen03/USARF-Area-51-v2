local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Config = USARFServer:WaitForChild("Config")

local CmdrAdminConfig = require(Config:WaitForChild("CmdrAdminConfig"))

local CmdrPermissionService = {}

local sheetCache = {}
local sheetLastFetch = 0
local started = false

local function safeRank(player, groupId)
	local success, result = pcall(function()
		return player:GetRankInGroup(groupId)
	end)

	if not success then
		return 0
	end

	return result or 0
end

local function trimText(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeUsername(value)
	return string.lower(trimText(value))
end

local function normalizeLevelName(levelName)
	levelName = trimText(levelName)

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

local function getLevelValue(levelName)
	local normalized = normalizeLevelName(levelName)
	return CmdrAdminConfig.Levels[normalized] or 0
end

local function getLevelNameFromValue(levelValue)
	return CmdrAdminConfig.LevelLabels[levelValue] or "None"
end

local function getHigherLevel(levelA, levelB)
	local valueA = getLevelValue(levelA)
	local valueB = getLevelValue(levelB)

	if valueA >= valueB then
		return normalizeLevelName(levelA), valueA
	end

	return normalizeLevelName(levelB), valueB
end

local function fetchSheetCache()
	local sheetConfig = CmdrAdminConfig.GoogleSheet

	if not sheetConfig or sheetConfig.Enabled ~= true then
		return
	end

	if not sheetConfig.Url or sheetConfig.Url == "" then
		return
	end

	local cacheSeconds = sheetConfig.CacheSeconds or 300

	if os.time() - sheetLastFetch < cacheSeconds then
		return
	end

	sheetLastFetch = os.time()

	local success, result = pcall(function()
		return HttpService:GetAsync(sheetConfig.Url)
	end)

	if not success then
		warn("[CmdrPermissionService] Failed to fetch admin sheet:", result)
		return
	end

	local decodedSuccess, decoded = pcall(function()
		return HttpService:JSONDecode(result)
	end)

	if not decodedSuccess or type(decoded) ~= "table" then
		warn("[CmdrPermissionService] Invalid admin sheet JSON.")
		return
	end

	local newCache = {
		byUserId = {},
		byUsername = {},
	}

	for _, row in ipairs(decoded) do
		local enabledRaw = row.Enabled or row.enabled or row.Active or row.active
		local enabled = enabledRaw == true
			or string.lower(tostring(enabledRaw)) == "true"
			or tostring(enabledRaw) == "1"
			or string.lower(tostring(enabledRaw)) == "yes"

		if enabled then
			local userId = tonumber(row.RobloxUserId or row.robloxUserId or row.UserId or row.userId)
			local username = normalizeUsername(row.Username or row.username or row.RobloxUsername or row.robloxUsername)
			local levelName = normalizeLevelName(row.AdminLevel or row.adminLevel or row.Level or row.level)

			local entry = {
				userId = userId,
				username = username,
				levelName = levelName,
				levelValue = getLevelValue(levelName),
				source = "GoogleSheet",
				notes = tostring(row.Notes or row.notes or ""),
			}

			if entry.levelValue > 0 then
				if userId then
					newCache.byUserId[userId] = entry
				end

				if username ~= "" then
					newCache.byUsername[username] = entry
				end
			end
		end
	end

	sheetCache = newCache
end

local function getSheetOverride(player)
	fetchSheetCache()

	if sheetCache.byUserId and sheetCache.byUserId[player.UserId] then
		return sheetCache.byUserId[player.UserId]
	end

	local username = normalizeUsername(player.Name)

	if sheetCache.byUsername and sheetCache.byUsername[username] then
		return sheetCache.byUsername[username]
	end

	return nil
end

-- True when the player holds a QA role and this server is in one of the QA games.
function CmdrPermissionService.IsQA(player)
	local qaConfig = CmdrAdminConfig.QA

	if not player or not qaConfig or qaConfig.Enabled ~= true then
		return false
	end

	if not (qaConfig.GameIds and qaConfig.GameIds[game.GameId]) then
		return false
	end

	if qaConfig.UserIds and qaConfig.UserIds[player.UserId] then
		return true
	end

	if qaConfig.Ranks and qaConfig.Ranks[safeRank(player, qaConfig.GroupId)] then
		return true
	end

	if qaConfig.RoleNames and #qaConfig.RoleNames > 0 then
		local success, roleName = pcall(function()
			return player:GetRoleInGroup(qaConfig.GroupId)
		end)

		if success and table.find(qaConfig.RoleNames, roleName) then
			return true
		end
	end

	return false
end

function CmdrPermissionService.IsReserveServer()
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

function CmdrPermissionService.GetReserveDepartmentKey()
	return game:GetAttribute("USARF_ReserveDepartmentKey")
end

function CmdrPermissionService.SetReserveDepartmentKey(departmentKey)
	game:SetAttribute("USARF_ReserveDepartmentKey", departmentKey)
end

function CmdrPermissionService.GetReserveTrainingLevel(player)
	if not CmdrAdminConfig.ReserveServers.Enabled then
		return "None", 0, nil
	end

	if not CmdrPermissionService.IsReserveServer() then
		return "None", 0, nil
	end

	local reserveDepartmentKey = CmdrPermissionService.GetReserveDepartmentKey()
	local departmentConfig = nil

	if reserveDepartmentKey then
		departmentConfig = CmdrAdminConfig.ReserveServers.Departments[reserveDepartmentKey]
	end

	if not departmentConfig then
		for key, config in pairs(CmdrAdminConfig.ReserveServers.Departments) do
			local rank = safeRank(player, config.GroupId)

			if rank >= config.MinimumRank then
				local levelName = normalizeLevelName(config.GrantedLevel)
				return levelName, getLevelValue(levelName), key
			end
		end

		return "None", 0, nil
	end

	local rank = safeRank(player, departmentConfig.GroupId)

	if rank >= departmentConfig.MinimumRank then
		local levelName = normalizeLevelName(departmentConfig.GrantedLevel)
		return levelName, getLevelValue(levelName), reserveDepartmentKey
	end

	return "None", 0, reserveDepartmentKey
end

function CmdrPermissionService.GetGroupAdminLevel(player)
	local bestLevelName = "None"
	local bestLevelValue = 0

	local mainConfig = CmdrAdminConfig.MainServerRanks.MainGroup
	if mainConfig then
		local rank = safeRank(player, mainConfig.GroupId)
		local exactLevel = mainConfig.ExactRanks and mainConfig.ExactRanks[rank]

		if exactLevel then
			bestLevelName, bestLevelValue = getHigherLevel(bestLevelName, exactLevel)
		end
	end

	local modConfig = CmdrAdminConfig.MainServerRanks.ModerationGroup
	if modConfig then
		local rank = safeRank(player, modConfig.GroupId)
		local exactLevel = modConfig.ExactRanks and modConfig.ExactRanks[rank]

		if exactLevel then
			bestLevelName, bestLevelValue = getHigherLevel(bestLevelName, exactLevel)
		end
	end

	local devConfig = CmdrAdminConfig.MainServerRanks.DeveloperGroup
	if devConfig then
		local rank = safeRank(player, devConfig.GroupId)

		for _, minimumRule in ipairs(devConfig.MinimumRanks or {}) do
			if rank >= minimumRule.Rank then
				bestLevelName, bestLevelValue = getHigherLevel(bestLevelName, minimumRule.Level)
			end
		end
	end

	return bestLevelName, bestLevelValue
end

function CmdrPermissionService.GetAdminLevel(player)
	if not player then
		return "None", 0, "None", nil
	end

	local sheetOverride = getSheetOverride(player)

	if sheetOverride then
		player:SetAttribute("USARF_CmdrAdminLevel", sheetOverride.levelName)
		player:SetAttribute("USARF_CmdrAdminLevelValue", sheetOverride.levelValue)
		player:SetAttribute("USARF_CmdrAdminSource", "GoogleSheet")
		player:SetAttribute("USARF_CmdrQA", CmdrPermissionService.IsQA(player))

		return sheetOverride.levelName, sheetOverride.levelValue, "GoogleSheet", nil
	end

	local groupLevelName, groupLevelValue = CmdrPermissionService.GetGroupAdminLevel(player)
	local reserveLevelName, reserveLevelValue, reserveDepartmentKey = CmdrPermissionService.GetReserveTrainingLevel(player)

	local finalLevelName = groupLevelName
	local finalLevelValue = groupLevelValue
	local source = "GroupRank"

	if reserveLevelValue > finalLevelValue then
		finalLevelName = reserveLevelName
		finalLevelValue = reserveLevelValue
		source = "ReserveTraining"
	end

	player:SetAttribute("USARF_CmdrAdminLevel", finalLevelName)
	player:SetAttribute("USARF_CmdrAdminLevelValue", finalLevelValue)
	player:SetAttribute("USARF_CmdrAdminSource", source)
	-- Lets the top bar show the Cmdr button to QA testers, who have no admin level.
	player:SetAttribute("USARF_CmdrQA", CmdrPermissionService.IsQA(player))

	if reserveDepartmentKey then
		player:SetAttribute("USARF_CmdrReserveDepartmentKey", reserveDepartmentKey)
	end

	return finalLevelName, finalLevelValue, source, reserveDepartmentKey
end

function CmdrPermissionService.HasLevel(player, requiredLevel)
	local _, playerLevelValue = CmdrPermissionService.GetAdminLevel(player)
	return playerLevelValue >= getLevelValue(requiredLevel)
end

function CmdrPermissionService.CanRun(player, commandName)
	if not player then
		return false, "Missing player."
	end

	commandName = string.lower(tostring(commandName or ""))
	local commandConfig = CmdrAdminConfig.Commands[commandName] or CmdrAdminConfig.Commands.Default

	local levelName, levelValue, source = CmdrPermissionService.GetAdminLevel(player)

	if levelValue >= getLevelValue(commandConfig.MainServerLevel) then
		return true, nil, {
			levelName = levelName,
			levelValue = levelValue,
			source = source,
			path = "MainServerLevel",
			commandConfig = commandConfig,
		}
	end

	if CmdrPermissionService.IsReserveServer()
		and commandConfig.ReserveOnlyTraining == true
		and commandConfig.TrainingReserveLevel
	then
		local reserveLevelName, reserveLevelValue, reserveDepartmentKey = CmdrPermissionService.GetReserveTrainingLevel(player)

		if reserveLevelValue >= getLevelValue(commandConfig.TrainingReserveLevel) then
			return true, nil, {
				levelName = reserveLevelName,
				levelValue = reserveLevelValue,
				source = "ReserveTraining",
				path = "TrainingReserveLevel",
				reserveDepartmentKey = reserveDepartmentKey,
				commandConfig = commandConfig,
			}
		end
	end

	if CmdrAdminConfig.QA and CmdrAdminConfig.QA.Commands[commandName] and CmdrPermissionService.IsQA(player) then
		return true, nil, {
			levelName = "QA",
			levelValue = levelValue,
			source = "QA",
			path = "QA",
			commandConfig = commandConfig,
		}
	end

	return false, "You do not have permission to run this command.", {
		levelName = levelName,
		levelValue = levelValue,
		source = source,
		commandConfig = commandConfig,
	}
end

function CmdrPermissionService.RefreshPlayer(player)
	return CmdrPermissionService.GetAdminLevel(player)
end

function CmdrPermissionService.RefreshAll()
	for _, player in ipairs(Players:GetPlayers()) do
		CmdrPermissionService.RefreshPlayer(player)
	end
end

function CmdrPermissionService.Start()
	if started then
		return
	end

	started = true

	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			task.wait(2)
			CmdrPermissionService.RefreshPlayer(player)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.defer(function()
			CmdrPermissionService.RefreshPlayer(player)
		end)
	end

	task.spawn(function()
		while started do
			CmdrPermissionService.RefreshAll()
			task.wait(120)
		end
	end)

	print("[CmdrPermissionService] Started")
end

return CmdrPermissionService