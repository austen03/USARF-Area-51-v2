local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local RankService = require(Services:WaitForChild("RankService"))

local USARF = ReplicatedStorage:WaitForChild("USARF")
local TeamConfig = require(USARF:WaitForChild("Config"):WaitForChild("TeamConfig"))

local InventoryService = nil
pcall(function()
	InventoryService = require(Services:WaitForChild("InventoryService"))
end)

local EconomyConfig = nil
pcall(function()
	EconomyConfig = require(ReplicatedStorage.USARF.Config:WaitForChild("EconomyConfig"))
end)

local NameTagService = {}

local MAIN_GROUP_ID = 6033326
local MOD_GROUP_ID = 8647541
local DEV_GROUP_ID = 6773540

local NAME_TAG_HEIGHT = 2.85
local MAX_DISTANCE = 175
local CACHE_SECONDS = 300

local NAME_TAG_NAME = "USARFNameTag"

local BADGES_ATTRIBUTE = "USARF_BadgesEnabled"
local DEFAULT_BADGES_ENABLED = false

local GOLD_NAMETAG_ATTRIBUTE = "USARF_GoldNametag"
local GOLD_COLOR = Color3.fromRGB(255, 215, 90)
local GOLD_SOFT_COLOR = Color3.fromRGB(255, 230, 140)

local ATTR_CLOAKED = "USARF_Cloaked"
local ATTR_SCRAMBLED = "USARF_Scrambled"

local ATTR_NAME_OVERRIDE = "USARF_NameTagNameOverride"
local ATTR_RANK_OVERRIDE = "USARF_NameTagRankOverride"
local ATTR_COLOR_OVERRIDE = "USARF_NameTagColorOverride"

local PROFILE_SHEET_URL = "https://script.google.com/macros/s/AKfycbxLBXO-xrQSH-lkl_zsyMKtvv2pXHivaXR_ikCHJJhaexuVk1gq0Dljy6OF3lJD2o0u0g/exec?sheet=medals"

local DEPARTMENT_RANK_SHEET_URLS = {
	EngineeringTechnical = "",
	MedicalDivision = "",
	ResearchDivision = "",
	RulesRegulations = "",

	UnitedStatesAirForce = "",
	DepartmentOfDefense = "",

	Infantry108 = "",
	MP137 = "",
	SpecOpsAIG = "",
	SecretService = "",

	FederalDefenseService = "",
	CentralIntelligenceAgency = "",
	FederalBureauInvestigation = "",

	PresidentialCabinet = "",
}

local ICONS = {
	Owner = { image = "rbxassetid://103438543769249", color = Color3.fromRGB(255, 225, 90), size = 38 },
	ExecutiveLeadership = { image = "rbxassetid://132862919961085", color = Color3.fromRGB(255, 225, 90), size = 34 },
	POTUSVPOTUS = { image = "rbxassetid://89415346353784", color = Color3.fromRGB(255, 220, 110), size = 34 },
	Moderator = { image = "rbxassetid://117579984124201", color = Color3.fromRGB(200, 200, 200), size = 34 },
	Developer = { image = "rbxassetid://134245549400974", color = Color3.fromRGB(200, 200, 200), size = 34 },
	Premium = { image = "rbxassetid://84150610905380", color = Color3.fromRGB(255, 255, 255), size = 34 },
	Cabinet = { image = "rbxassetid://138524796226557", color = Color3.fromRGB(220, 220, 220), size = 34 },
	Honor = { image = "rbxassetid://132007801726670", color = Color3.fromRGB(235, 235, 235), size = 20 },
	DistinguishedService = { image = "rbxassetid://107997180162683", color = Color3.fromRGB(255, 210, 80), size = 34 },
	Veteran = { image = "rbxassetid://111876202050842", color = Color3.fromRGB(235, 235, 235), size = 34 },
	Nitro = { image = "rbxassetid://5830296766", color = Color3.fromRGB(255, 105, 253), size = 22 },
	Verified = { image = "rbxassetid://90978860241325", color = Color3.fromRGB(0, 100, 218), size = 22 },
	GoldNametag = { image = "", color = GOLD_COLOR, size = 34 },
}

local ICON_PRIORITY = {
	"Owner",
	"Verified",
	"Developer",
	"Moderator",
	"POTUSVPOTUS",
	"ExecutiveLeadership",
	"Cabinet",
	"Honor",
	"DistinguishedService",
	"Veteran",
	"Premium",
	"Nitro",
}

local BADGE_TOGGLE_CONTROLLED = {
	Owner = true,
	ExecutiveLeadership = true,
	POTUSVPOTUS = true,
	Cabinet = true,
	Developer = true,
	Moderator = true,
}

local TEAM_COLORS = {
	["Test Subject"] = Color3.fromRGB(220, 220, 60),
	["PMC"] = Color3.fromRGB(255, 190, 80),

	["Facility Personnel"] = Color3.fromRGB(190, 190, 190),
	["Engineering & Technical"] = Color3.fromRGB(255, 185, 70),
	["Medical Division"] = Color3.fromRGB(100, 200, 255),
	["Research Division"] = Color3.fromRGB(150, 130, 255),
	["Rules & Regulations"] = Color3.fromRGB(255, 220, 90),
	["United States Air Force"] = Color3.fromRGB(90, 160, 255),
	["Department of Defense"] = Color3.fromRGB(90, 110, 160),
	["EXTECH"] = Color3.fromRGB(180, 110, 255),

	["108th Infantry Regiment"] = Color3.fromRGB(85, 180, 95),
	["137th Military Police Company"] = Color3.fromRGB(70, 130, 255),
	["1st Spec. Ops. A.I.G"] = Color3.fromRGB(120, 80, 160),
	["Secret Service"] = Color3.fromRGB(45, 45, 45),

	["Federal Defense Service"] = Color3.fromRGB(120, 120, 120),
	["Central Intelligence Agency"] = Color3.fromRGB(40, 40, 40),
	["Federal Bureau of Investigation"] = Color3.fromRGB(30, 70, 150),

	["Federal Administration"] = Color3.fromRGB(255, 215, 100),
	["Presidential Cabinet"] = Color3.fromRGB(255, 215, 100),
	["Vice President of the United States"] = Color3.fromRGB(255, 225, 130),
	["President of the United States"] = Color3.fromRGB(255, 235, 150),
}

local CUSTOM_TITLES = {}
local TEAM_RANK_OVERRIDES = {}

local profileCache = {}
local profileLastFetch = 0

local departmentRankCaches = {}
local departmentRankLastFetch = {}

local testSubjectNumbers = {}
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

local function normalizeKey(value)
	return string.lower(trimText(value):gsub("%s+", ""):gsub(":", ""))
end

local function getNameOverride(player)
	local value = trimText(player:GetAttribute(ATTR_NAME_OVERRIDE))
	return value ~= "" and value or nil
end

local function getRankOverride(player)
	local value = trimText(player:GetAttribute(ATTR_RANK_OVERRIDE))
	return value ~= "" and value or nil
end

local function getColorOverride(player)
	local value = player:GetAttribute(ATTR_COLOR_OVERRIDE)
	return typeof(value) == "Color3" and value or nil
end

local function getTeamRankOverride(player, teamKey)
	local overrides = TEAM_RANK_OVERRIDES[player.UserId]
	return overrides and teamKey and overrides[teamKey] or nil
end

local function fetchJson(url)
	if url == nil or url == "" then
		return nil
	end

	local success, result = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if not success then
		warn("[NameTagService] Failed HTTP request:", result)
		return nil
	end

	local decodedSuccess, decoded = pcall(function()
		return HttpService:JSONDecode(result)
	end)

	if not decodedSuccess or type(decoded) ~= "table" then
		warn("[NameTagService] Invalid JSON from sheet")
		return nil
	end

	return decoded
end

local function getRowValue(row, keys)
	for _, key in ipairs(keys) do
		if row[key] ~= nil then
			return row[key]
		end
	end

	for rowKey, value in pairs(row) do
		local normalizedRowKey = normalizeKey(rowKey)

		for _, wantedKey in ipairs(keys) do
			if normalizedRowKey == normalizeKey(wantedKey) then
				return value
			end
		end
	end

	return nil
end

local function fetchProfileCache()
	if PROFILE_SHEET_URL == "" then
		return
	end

	if os.time() - profileLastFetch < CACHE_SECONDS then
		return
	end

	profileLastFetch = os.time()

	local decoded = fetchJson(PROFILE_SHEET_URL)
	if not decoded then
		return
	end

	local newCache = {}

	for _, row in ipairs(decoded) do
		local userId = tonumber(getRowValue(row, {
			"RobloxUserId",
			"robloxUserId",
			"Roblox UserId",
			"Roblox UserID",
			"UserId",
			"userId",
			"UserID",
		}))

		if userId then
			local awards = {}
			local awardsText = tostring(getRowValue(row, {
				"Awards",
				"awards",
				"Medals",
				"medals",
				"MedalsEarned",
				"medalsEarned",
				"Medals Earned",
				"Medals Earned:",
			}) or "")

			for award in string.gmatch(awardsText, "([^,]+)") do
				local key = string.lower(trimText(award):gsub("%s+", ""))

				if key == "nitro" or key == "nitrosupporter" then
					awards.Nitro = true
				elseif key == "veteran" or key == "serviceveteran" then
					awards.Veteran = true
				elseif key == "distinguishedservice" or key == "distinguished" then
					awards.DistinguishedService = true
				elseif key == "honor" or key == "honorable" then
					awards.Honor = true
				end
			end

			newCache[userId] = {
				awards = awards,
			}
		end
	end

	profileCache = newCache
end

local function getProfile(player)
	fetchProfileCache()
	return profileCache[player.UserId]
end

local function fetchDepartmentRankCache(teamKey)
	local url = DEPARTMENT_RANK_SHEET_URLS[teamKey]

	if url == nil or url == "" then
		return
	end

	local lastFetch = departmentRankLastFetch[teamKey] or 0

	if os.time() - lastFetch < CACHE_SECONDS then
		return
	end

	departmentRankLastFetch[teamKey] = os.time()

	local decoded = fetchJson(url)
	if not decoded then
		return
	end

	local newCache = {}

	for _, row in ipairs(decoded) do
		local userId = tonumber(getRowValue(row, {
			"RobloxUserId",
			"robloxUserId",
			"Roblox UserId",
			"UserId",
			"userId",
		}))

		if userId then
			local rank = trimText(getRowValue(row, {
				"DepartmentalRank",
				"departmentalRank",
				"DepartmentRank",
				"departmentRank",
				"Departmental Rank",
				"Rank",
				"rank",
			}))

			if rank ~= "" then
				newCache[userId] = rank
			end
		end
	end

	departmentRankCaches[teamKey] = newCache
end

local function getDepartmentRankFromSheet(player, teamKey)
	if not teamKey then
		return nil
	end

	fetchDepartmentRankCache(teamKey)

	local cache = departmentRankCaches[teamKey]
	if not cache then
		return nil
	end

	return cache[player.UserId]
end

local function getTeamName(player)
	local teamName = player:GetAttribute("USARF_TeamName")

	if teamName and teamName ~= "" then
		return teamName
	end

	if player.Team then
		return player.Team.Name
	end

	return "No Department"
end

local function getTeamColor(teamName)
	return TEAM_COLORS[teamName] or Color3.fromRGB(230, 230, 230)
end

local function isTestSubject(player)
	return getTeamName(player) == "Test Subject" or player:GetAttribute("USARF_TeamKey") == "TestSubject"
end

local function isPMC(player)
	return getTeamName(player) == "PMC" or player:GetAttribute("USARF_TeamKey") == "PMC"
end

local function getTestSubjectNumber(player)
	if not testSubjectNumbers[player.UserId] then
		local number = ((player.UserId * 37) % 90000) + 10000
		testSubjectNumbers[player.UserId] = string.format("TS-%05d", number)
	end

	return testSubjectNumbers[player.UserId]
end

local function ownsPremium(player)
	return player.MembershipType == Enum.MembershipType.Premium
end

local function areBadgesEnabled(player)
	return player:GetAttribute(BADGES_ATTRIBUTE) == true
end

local function getGoldNametagItemIds()
	local ids = {}

	if not EconomyConfig or type(EconomyConfig.ShopItems) ~= "table" then
		return ids
	end

	for _, item in ipairs(EconomyConfig.ShopItems) do
		if item and item.Effect == "GoldNametag" then
			table.insert(ids, item.Id)
		end
	end

	return ids
end

local function playerOwnsGoldNametag(player)
	if not player then
		return false
	end

	if player:GetAttribute(GOLD_NAMETAG_ATTRIBUTE) == true then
		return true
	end

	if not InventoryService then
		return false
	end

	for _, itemId in ipairs(getGoldNametagItemIds()) do
		local success, owns = pcall(function()
			return InventoryService.HasItem(player, itemId)
		end)

		if success and owns == true then
			player:SetAttribute(GOLD_NAMETAG_ATTRIBUTE, true)
			return true
		end
	end

	return false
end

local function isSpecialTitleRank(player)
	local mainRank = safeRank(player, MAIN_GROUP_ID)
	local devRank = safeRank(player, DEV_GROUP_ID)
	local teamKey = player:GetAttribute("USARF_TeamKey")

	if teamKey == "President" or teamKey == "VicePresident" then
		return true
	end

	if teamKey == "FederalAdministration" then
		return true
	end

	if devRank >= 3 then
		return true
	end

	if mainRank >= 19 then
		return true
	end

	return false
end

local function getCustomTitle(player)
	local teamKey = player:GetAttribute("USARF_TeamKey")
	local teamRankOverride = getTeamRankOverride(player, teamKey)

	-- The rank command owns the primary rank/title position.
	-- For special-title users, this replaces titles such as
	-- "Federal Overseer" with the configured team override.
	if teamRankOverride then
		return teamRankOverride
	end

	if CUSTOM_TITLES[player.UserId] then
		return CUSTOM_TITLES[player.UserId]
	end

	if not isSpecialTitleRank(player) then
		return nil
	end

	if teamKey then
		return RankService.GetDisplayRankForTeam(player, teamKey)
	end

	return RankService.GetMainGroupRank(player)
end

local function getClearanceLevel(player)
	local teamKey = player:GetAttribute("USARF_TeamKey")

	if teamKey == "President" or teamKey == "VicePresident" then
		return 10
	end

	local mainRank = safeRank(player, MAIN_GROUP_ID)

	if mainRank >= 19 then
		return 10
	elseif mainRank == 18 then
		return 9
	elseif mainRank >= 16 then
		return 10
	elseif mainRank >= 13 then
		return 9
	elseif mainRank >= 11 then
		return 7
	elseif mainRank >= 10 then
		return 6
	elseif mainRank >= 8 then
		return 5
	elseif mainRank >= 7 then
		return 4
	elseif mainRank >= 5 then
		return 3
	elseif mainRank >= 4 then
		return 2
	elseif mainRank >= 3 then
		return 1
	end

	return 0
end

local function getDepartmentalRank(player)
	local directOverride = getRankOverride(player)
	if directOverride then
		return directOverride
	end

	local teamKey = player:GetAttribute("USARF_TeamKey")
	local teamOverride = getTeamRankOverride(player, teamKey)

	if teamOverride then
		return teamOverride
	end

	local sheetRank = getDepartmentRankFromSheet(player, teamKey)
	if sheetRank and sheetRank ~= "" then
		return sheetRank
	end

	if teamKey then
		return RankService.GetDisplayRankForTeam(player, teamKey)
	end

	return RankService.GetMainGroupRank(player)
end

local function getBadgeMap(player)
	local badges = {}

	local mainRank = safeRank(player, MAIN_GROUP_ID)
	local modRank = safeRank(player, MOD_GROUP_ID)
	local devRank = safeRank(player, DEV_GROUP_ID)
	local teamKey = player:GetAttribute("USARF_TeamKey")
	local profile = getProfile(player)

	if mainRank == 255 then
		badges.Owner = true
	end

	if mainRank == 19 or mainRank == 20 then
		badges.ExecutiveLeadership = true
	end

	if mainRank == 18 or devRank >= 3 then
		badges.Developer = true
	end

	if modRank == 2 or modRank >= 7 then
		badges.Moderator = true
	end

	if teamKey == "President" or teamKey == "VicePresident" then
		badges.POTUSVPOTUS = true
	end

	if teamKey == "PresidentialCabinet" then
		badges.Cabinet = true
	end

	if ownsPremium(player) then
		badges.Premium = true
	end

	if player.HasVerifiedBadge == true then
		badges.Verified = true
	end

	if profile and profile.awards then
		if profile.awards.Nitro then
			badges.Nitro = true
		end

		if profile.awards.Veteran then
			badges.Veteran = true
		end

		if profile.awards.DistinguishedService then
			badges.DistinguishedService = true
		end
		if profile.awards.Honor then
			badges.Honor = true
		end
	end

	return badges
end

local function getIcons(player)
	local badgeMap = getBadgeMap(player)
	local icons = {}
	local badgesEnabled = areBadgesEnabled(player)

	for _, badgeName in ipairs(ICON_PRIORITY) do
		if badgeMap[badgeName] and ICONS[badgeName] then
			if badgesEnabled or not BADGE_TOGGLE_CONTROLLED[badgeName] then
				table.insert(icons, {
					name = badgeName,
					image = ICONS[badgeName].image,
					color = ICONS[badgeName].color,
					size = ICONS[badgeName].size or 34,
				})
			end
		end
	end

	return icons
end

local function clearTag(character)
	if not character then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant.Name == NAME_TAG_NAME then
			descendant:Destroy()
		end
	end
end

local function shouldSuppressNormalNameTag(player)
	if not player then
		return true
	end

	if player:GetAttribute(ATTR_CLOAKED) == true then
		return true
	end

	if player:GetAttribute(ATTR_SCRAMBLED) == true then
		return true
	end

	local character = player.Character
	if character then
		if character:GetAttribute(ATTR_CLOAKED) == true then
			return true
		end

		if character:GetAttribute(ATTR_SCRAMBLED) == true then
			return true
		end
	end

	return false
end

local function createTextLabel(parent, name, text, height, color, order, goldMode)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, height)
	label.LayoutOrder = order
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = goldMode and 0.2 or 0.35
	label.TextStrokeColor3 = goldMode and Color3.fromRGB(80, 55, 0) or Color3.fromRGB(0, 0, 0)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = parent

	return label
end

local function createIconRow(parent, icons)
	local row = Instance.new("Frame")
	row.Name = "IconRow"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 38)
	row.LayoutOrder = 1
	row.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.Parent = row

	for index, iconData in ipairs(icons) do
		if iconData.image and iconData.image ~= "" and iconData.image ~= "rbxassetid://0" then
			local iconSize = tonumber(iconData.size) or 34

			local icon = Instance.new("ImageLabel")
			icon.Name = iconData.name .. "_Icon"
			icon.BackgroundTransparency = 1
			icon.Size = UDim2.new(0, iconSize, 0, iconSize)
			icon.LayoutOrder = index
			icon.Image = iconData.image
			icon.ImageColor3 = iconData.color or Color3.fromRGB(255, 255, 255)
			icon.ScaleType = Enum.ScaleType.Fit
			icon.Parent = row
		end
	end

	return row
end

local function buildStandardDisplayLines(player)
	local customTitle = getCustomTitle(player)
	local clearance = getClearanceLevel(player)
	local departmentRank = getDepartmentalRank(player)
	local goldMode = playerOwnsGoldNametag(player)

	local forcedName = getNameOverride(player)
	local displayName = forcedName or tostring(player.Name)

	if goldMode then
		displayName = "★ " .. displayName .. " ★"
	end

	if forcedName then
		return displayName, "SC-" .. tostring(clearance) .. " | " .. tostring(departmentRank), false
	end

	if customTitle and customTitle ~= "" then
		return tostring(customTitle), "SC-" .. tostring(clearance) .. " | " .. displayName, true
	end

	return displayName, "SC-" .. tostring(clearance) .. " | " .. tostring(departmentRank), false
end

local function buildSpecialDisplay(player, goldMode)
	local forcedName = getNameOverride(player)
	local forcedRank = getRankOverride(player)
	local forcedColor = getColorOverride(player)

	if forcedName or forcedRank or forcedColor then
		local displayName = forcedName or player.Name

		if goldMode then
			displayName = "★ " .. displayName .. " ★"
		end

		return {
			mode = "Override",
			lines = {
				{
					name = "IdentityLabel",
					text = displayName,
					height = 20,
					color = forcedColor or (goldMode and GOLD_SOFT_COLOR or Color3.fromRGB(255, 255, 255)),
					order = 2,
				},
				{
					name = "RankLabel",
					text = forcedRank or getDepartmentalRank(player),
					height = 20,
					color = forcedColor or (goldMode and GOLD_COLOR or Color3.fromRGB(120, 205, 255)),
					order = 3,
				},
			},
		}
	end

	if isTestSubject(player) then
		local status = player:GetAttribute("USARF_ContainmentStatus")
		local subjectNumber = getTestSubjectNumber(player)

		if status == "TERMINATE" then
			return {
				mode = "TestSubject",
				lines = {
					{ name = "StatusLabel", text = "[TERMINATE]", height = 22, color = Color3.fromRGB(255, 45, 45), order = 2 },
					{ name = "SubjectNumberLabel", text = subjectNumber, height = 20, color = Color3.fromRGB(255, 55, 55), order = 3 },
					{ name = "UsernameLabel", text = player.Name, height = 18, color = goldMode and GOLD_SOFT_COLOR or Color3.fromRGB(255, 255, 255), order = 4 },
				},
			}
		elseif status == "AUTHORIZED" then
			return {
				mode = "TestSubject",
				lines = {
					{ name = "StatusLabel", text = "[AUTHORIZED]", height = 22, color = Color3.fromRGB(90, 255, 115), order = 2 },
					{ name = "SubjectNumberLabel", text = subjectNumber, height = 20, color = Color3.fromRGB(90, 255, 115), order = 3 },
					{ name = "UsernameLabel", text = player.Name, height = 18, color = goldMode and GOLD_SOFT_COLOR or Color3.fromRGB(255, 255, 255), order = 4 },
				},
			}
		end

		return {
			mode = "TestSubject",
			lines = {
				{ name = "SubjectNumberLabel", text = subjectNumber, height = 20, color = goldMode and GOLD_COLOR or Color3.fromRGB(220, 220, 60), order = 2 },
				{ name = "UsernameLabel", text = goldMode and ("★ " .. player.Name .. " ★") or player.Name, height = 18, color = goldMode and GOLD_SOFT_COLOR or Color3.fromRGB(255, 255, 255), order = 3 },
			},
		}
	end

	if isPMC(player) then
		return {
			mode = "PMC",
			lines = {
				{ name = "HostileLabel", text = "[HOSTILE]", height = 22, color = Color3.fromRGB(255, 65, 65), order = 2 },
				{ name = "ContractorLabel", text = goldMode and ("Contractor ★ " .. player.Name .. " ★") or ("Contractor " .. player.Name), height = 20, color = goldMode and GOLD_SOFT_COLOR or Color3.fromRGB(255, 190, 80), order = 3 },
			},
		}
	end

	return nil
end

function NameTagService.Apply(player)
	if not player then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	clearTag(character)

	if shouldSuppressNormalNameTag(player) then
		return
	end

	local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 10)

	if not head then
		warn("[NameTagService] No head found for", player.Name)
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.NameDisplayDistance = 0
		humanoid.HealthDisplayDistance = 0
	end

	local goldMode = playerOwnsGoldNametag(player)
	local icons = getIcons(player)

	local isAFK = player:GetAttribute("USARF_AFK") == true
	local isSuspiciousIdle = player:GetAttribute("USARF_SuspiciousIdle") == true

	local specialDisplay = buildSpecialDisplay(player, goldMode)

	local height = 50

	if #icons > 0 then
		height += 38
	end

	if isAFK or isSuspiciousIdle then
		height += 15
	end

	if specialDisplay then
		for _, line in ipairs(specialDisplay.lines) do
			height += line.height
		end
	else
		height += 52
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = NAME_TAG_NAME
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 220, 0, height)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, NAME_TAG_HEIGHT, 0)
	billboard.AlwaysOnTop = false
	billboard.LightInfluence = 0
	billboard.MaxDistance = MAX_DISTANCE
	billboard.Enabled = true
	billboard.Parent = character

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 1, 0)
	container.Parent = billboard

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 0)
	layout.Parent = container

	if #icons > 0 then
		createIconRow(container, icons)
	end

	if isAFK or isSuspiciousIdle then
		createTextLabel(container, "AFKLabel", "AFK", 15, Color3.fromRGB(255, 190, 70), 2, false)
	end

	if specialDisplay then
		for _, line in ipairs(specialDisplay.lines) do
			createTextLabel(container, line.name, line.text, line.height, line.color, line.order, goldMode)
		end

		return
	end

	local teamName = getTeamName(player)
	local forcedColor = getColorOverride(player)
	local teamColor = forcedColor or (goldMode and GOLD_COLOR or getTeamColor(teamName))
	local identityLine, clearanceRankLine, hasCustomTitle = buildStandardDisplayLines(player)

	local identityColor = forcedColor
		or (
			goldMode
			and GOLD_SOFT_COLOR
			or (
				hasCustomTitle
				and Color3.fromRGB(255, 255, 255)
				or Color3.fromRGB(230, 230, 230)
			)
		)

	local clearanceColor = forcedColor
		or (goldMode and GOLD_COLOR or Color3.fromRGB(120, 205, 255))

	createTextLabel(container, "IdentityLabel", identityLine, 16, identityColor, 3, goldMode)
	createTextLabel(container, "ClearanceRankLabel", clearanceRankLine, 20, clearanceColor, 4, goldMode)
	createTextLabel(container, "TeamLabel", tostring(teamName), 16, teamColor, 5, goldMode)
end

function NameTagService.Refresh(player)
	NameTagService.Apply(player)
end

function NameTagService.RefreshAll()
	for _, player in ipairs(Players:GetPlayers()) do
		NameTagService.Refresh(player)
	end
end

function NameTagService.HideNormalTag(player)
	if player and player.Character then
		clearTag(player.Character)
	end
end

function NameTagService.ShowNormalTag(player)
	NameTagService.Refresh(player)
end

function NameTagService.SetBadgesEnabled(player, enabled)
	if not player then
		return
	end

	player:SetAttribute(BADGES_ATTRIBUTE, enabled == true)
	NameTagService.Refresh(player)
end

function NameTagService.AreBadgesEnabled(player)
	if not player then
		return false
	end

	return areBadgesEnabled(player)
end

function NameTagService.GetBadgeMap(player)
	return getBadgeMap(player)
end

function NameTagService.GetIcons(player)
	return getIcons(player)
end

function NameTagService.GetIconConfig()
	return ICONS
end

function NameTagService.PlayerHasGoldNametag(player)
	return playerOwnsGoldNametag(player)
end

function NameTagService.SetCustomTitle(userId, title)
	CUSTOM_TITLES[userId] = title
end

function NameTagService.ClearCustomTitle(userId)
	CUSTOM_TITLES[userId] = nil
end

function NameTagService.SetDisplayedNameOverride(player, value)
	if not player then
		return false
	end

	value = trimText(value)
	player:SetAttribute(ATTR_NAME_OVERRIDE, value ~= "" and value or nil)
	NameTagService.Refresh(player)
	return true
end

function NameTagService.SetDisplayedRankOverride(player, value)
	if not player then
		return false
	end

	value = trimText(value)
	player:SetAttribute(ATTR_RANK_OVERRIDE, value ~= "" and value or nil)
	NameTagService.Refresh(player)
	return true
end

function NameTagService.SetColorOverride(player, color)
	if not player or typeof(color) ~= "Color3" then
		return false
	end

	player:SetAttribute(ATTR_COLOR_OVERRIDE, color)
	NameTagService.Refresh(player)
	return true
end

function NameTagService.ClearNameTagOverrides(player)
	if not player then
		return false
	end

	player:SetAttribute(ATTR_NAME_OVERRIDE, nil)
	player:SetAttribute(ATTR_RANK_OVERRIDE, nil)
	player:SetAttribute(ATTR_COLOR_OVERRIDE, nil)
	NameTagService.Refresh(player)
	return true
end

function NameTagService.SetTeamRankOverride(player, teamKey, rankText)
	if not player or not teamKey then
		return false
	end

	rankText = trimText(rankText)
	if rankText == "" then
		return false
	end

	TEAM_RANK_OVERRIDES[player.UserId] = TEAM_RANK_OVERRIDES[player.UserId] or {}
	TEAM_RANK_OVERRIDES[player.UserId][teamKey] = rankText
	NameTagService.Refresh(player)
	return true
end

function NameTagService.ClearTeamRankOverride(player, teamKey)
	local overrides = player and TEAM_RANK_OVERRIDES[player.UserId]

	if not overrides or overrides[teamKey] == nil then
		return false
	end

	overrides[teamKey] = nil

	if next(overrides) == nil then
		TEAM_RANK_OVERRIDES[player.UserId] = nil
	end

	NameTagService.Refresh(player)
	return true
end

function NameTagService.ResolveTeamForOverride(player, teamText)
	teamText = trimText(teamText)

	if string.lower(teamText) == "current" then
		local currentKey = player:GetAttribute("USARF_TeamKey")
		local currentData = currentKey and TeamConfig.Teams[currentKey]

		if not currentKey then
			return nil
		end

		return currentKey, currentData and (currentData.displayName or currentData.teamName or currentKey) or currentKey
	end

	local wanted = normalizeKey(teamText)

	for teamKey, teamData in pairs(TeamConfig.Teams or {}) do
		local displayName = teamData.displayName or teamData.teamName or teamKey
		local teamName = teamData.teamName or displayName

		if normalizeKey(teamKey) == wanted
			or normalizeKey(displayName) == wanted
			or normalizeKey(teamName) == wanted
		then
			return teamKey, displayName
		end
	end

	return nil
end

local function refreshPlayerSoon(player, delayTime)
	task.delay(delayTime or 0.1, function()
		if player and player.Parent then
			NameTagService.Refresh(player)
		end
	end)
end

local function setupPlayer(player)
	if player:GetAttribute(BADGES_ATTRIBUTE) == nil then
		player:SetAttribute(BADGES_ATTRIBUTE, DEFAULT_BADGES_ENABLED)
	end

	if player:GetAttribute(ATTR_CLOAKED) == nil then
		player:SetAttribute(ATTR_CLOAKED, false)
	end

	if player:GetAttribute(ATTR_SCRAMBLED) == nil then
		player:SetAttribute(ATTR_SCRAMBLED, false)
	end

	task.defer(function()
		task.wait(2)
		playerOwnsGoldNametag(player)
		NameTagService.Refresh(player)

		task.wait(3)
		playerOwnsGoldNametag(player)
		NameTagService.Refresh(player)
	end)

	player.CharacterAdded:Connect(function(character)
		character:SetAttribute(ATTR_CLOAKED, player:GetAttribute(ATTR_CLOAKED) == true)
		character:SetAttribute(ATTR_SCRAMBLED, player:GetAttribute(ATTR_SCRAMBLED) == true)

		task.wait(1)
		playerOwnsGoldNametag(player)
		NameTagService.Apply(player)

		task.wait(2)
		playerOwnsGoldNametag(player)
		NameTagService.Apply(player)
	end)

	player:GetAttributeChangedSignal(BADGES_ATTRIBUTE):Connect(function()
		refreshPlayerSoon(player, 0.1)
	end)

	player:GetAttributeChangedSignal(GOLD_NAMETAG_ATTRIBUTE):Connect(function()
		refreshPlayerSoon(player, 0.1)
	end)

	player:GetAttributeChangedSignal(ATTR_CLOAKED):Connect(function()
		if player.Character then
			player.Character:SetAttribute(ATTR_CLOAKED, player:GetAttribute(ATTR_CLOAKED) == true)
		end

		refreshPlayerSoon(player, 0.05)
	end)

	player:GetAttributeChangedSignal(ATTR_SCRAMBLED):Connect(function()
		if player.Character then
			player.Character:SetAttribute(ATTR_SCRAMBLED, player:GetAttribute(ATTR_SCRAMBLED) == true)
		end

		refreshPlayerSoon(player, 0.05)
	end)

	player:GetAttributeChangedSignal(ATTR_NAME_OVERRIDE):Connect(function()
		refreshPlayerSoon(player, 0.05)
	end)

	player:GetAttributeChangedSignal(ATTR_RANK_OVERRIDE):Connect(function()
		refreshPlayerSoon(player, 0.05)
	end)

	player:GetAttributeChangedSignal(ATTR_COLOR_OVERRIDE):Connect(function()
		refreshPlayerSoon(player, 0.05)
	end)

	player:GetAttributeChangedSignal("USARF_TeamKey"):Connect(function()
		task.wait(0.25)

		if not isTestSubject(player) then
			player:SetAttribute("USARF_ContainmentStatus", nil)
		end

		NameTagService.Refresh(player)
	end)

	player:GetAttributeChangedSignal("USARF_TeamName"):Connect(function()
		task.wait(0.25)

		if not isTestSubject(player) then
			player:SetAttribute("USARF_ContainmentStatus", nil)
		end

		NameTagService.Refresh(player)
	end)

	player:GetAttributeChangedSignal("USARF_ContainmentStatus"):Connect(function()
		refreshPlayerSoon(player, 0.1)
	end)

	player:GetAttributeChangedSignal("USARF_AFK"):Connect(function()
		refreshPlayerSoon(player, 0.15)
	end)

	player:GetAttributeChangedSignal("USARF_SuspiciousIdle"):Connect(function()
		refreshPlayerSoon(player, 0.15)
	end)

	if player.Character then
		task.defer(function()
			task.wait(1)
			playerOwnsGoldNametag(player)
			NameTagService.Apply(player)
		end)
	end
end

function NameTagService.Start()
	if started then
		return
	end

	started = true

	Players.PlayerAdded:Connect(function(player)
		setupPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		TEAM_RANK_OVERRIDES[player.UserId] = nil
		testSubjectNumbers[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	print("USARF NameTagService initialized")
end

task.defer(function()
	NameTagService.Start()
end)

return NameTagService