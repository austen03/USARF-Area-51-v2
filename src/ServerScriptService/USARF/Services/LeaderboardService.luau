local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")
local USARFConfig = require(Config:WaitForChild("USARFConfig"))

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local NameTagService = require(Services:WaitForChild("NameTagService"))

local LeaderboardService = {}

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local REMOTE_NAME = "LeaderboardSync"

local MODERATOR_LEVEL_VALUE = 3
local started = false

local TEAM_KEY_ORDER = {
	"President",
	"VicePresident",
	"PresidentialCabinet",
	"FederalAdministration",

	"CentralIntelligenceAgency",
	"FederalBureauInvestigation",
	"FederalDefenseService",

	"Infantry108",
	"MP137",
	"SpecOpsAIG",
	"SecretService",

	"UnitedStatesAirForce",
	"DepartmentOfDefense",

	"EngineeringTechnical",
	"MedicalDivision",
	"ResearchDivision",
	"RulesRegulations",
	"FacilityPersonnel",

	"PMC",
	"TestSubject",
	"Loading",
}

local TEAM_COLORS = {
	TestSubject = Color3.fromRGB(255, 190, 80),
	PMC = Color3.fromRGB(72, 79, 59),
	Loading = Color3.fromRGB(90, 90, 90),

	FacilityPersonnel = Color3.fromRGB(190, 190, 190),
	EngineeringTechnical = Color3.fromRGB(255, 185, 70),
	MedicalDivision = Color3.fromRGB(100, 200, 255),
	ResearchDivision = Color3.fromRGB(150, 130, 255),
	RulesRegulations = Color3.fromRGB(255, 220, 90),
	UnitedStatesAirForce = Color3.fromRGB(90, 160, 255),
	DepartmentOfDefense = Color3.fromRGB(90, 110, 160),

	Infantry108 = Color3.fromRGB(85, 180, 95),
	MP137 = Color3.fromRGB(70, 130, 255),
	SpecOpsAIG = Color3.fromRGB(120, 80, 160),
	SecretService = Color3.fromRGB(45, 45, 45),

	FederalDefenseService = Color3.fromRGB(120, 120, 120),
	CentralIntelligenceAgency = Color3.fromRGB(40, 40, 40),
	FederalBureauInvestigation = Color3.fromRGB(30, 70, 150),

	FederalAdministration = Color3.fromRGB(255, 215, 100),
	PresidentialCabinet = Color3.fromRGB(255, 215, 100),
	VicePresident = Color3.fromRGB(255, 225, 130),
	President = Color3.fromRGB(255, 235, 150),

	NoDepartment = Color3.fromRGB(70, 70, 70),
}

local function getOrCreateRemote()
	local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = REMOTE_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	local remote = folder:FindFirstChild(REMOTE_NAME)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = REMOTE_NAME
		remote.Parent = folder
	end

	return remote
end

local remote = getOrCreateRemote()

local function colorToTable(color)
	return {
		r = math.floor(color.R * 255),
		g = math.floor(color.G * 255),
		b = math.floor(color.B * 255),
	}
end

local function getTeamKey(player)
	local teamKey = player:GetAttribute("USARF_TeamKey")

	if teamKey and USARFConfig.Teams[teamKey] then
		return teamKey
	end

	local teamName = player:GetAttribute("USARF_TeamName")

	if teamName and teamName ~= "" then
		local mapped = USARFConfig.GetTeamKeyFromName(teamName)

		if mapped then
			return mapped
		end
	end

	if player.Team then
		local mapped = USARFConfig.GetTeamKeyFromName(player.Team.Name)

		if mapped then
			return mapped
		end
	end

	return "NoDepartment"
end

local function getTeamDisplayName(teamKey)
	local teamData = USARFConfig.Teams[teamKey]

	if teamData then
		return teamData.displayName or teamData.teamName or teamKey
	end

	if teamKey == "NoDepartment" then
		return "No Department"
	end

	return tostring(teamKey)
end

local function getTeamColor(teamKey)
	return TEAM_COLORS[teamKey] or Color3.fromRGB(70, 70, 70)
end

local function getPlayerIcons(player)
	local success, icons = pcall(function()
		return NameTagService.GetIcons(player)
	end)

	if not success or type(icons) ~= "table" then
		return {}
	end

	local cleanIcons = {}

	for _, icon in ipairs(icons) do
		table.insert(cleanIcons, {
			name = icon.name,
			image = icon.image,
			color = colorToTable(
				icon.color or Color3.fromRGB(255, 255, 255)
			),
			size = icon.size or 22,
		})
	end

	return cleanIcons
end

local function createTeamEntry(teamKey, order)
	return {
		key = teamKey,
		name = getTeamDisplayName(teamKey),
		color = colorToTable(getTeamColor(teamKey)),
		players = {},
		order = order,
	}
end

local function viewerCanSeeHiddenPlayer(viewer, target)
	if not target:GetAttribute("USARF_HideFromLeaderboard") then
		return true
	end

	if viewer == target then
		return true
	end

	local levelValue = tonumber(
		viewer and viewer:GetAttribute("USARF_CmdrAdminLevelValue")
	) or 0

	return levelValue >= MODERATOR_LEVEL_VALUE
end

local function buildPayload(viewer)
	local teams = {}
	local teamMap = {}

	for _, teamKey in ipairs(TEAM_KEY_ORDER) do
		local entry = createTeamEntry(teamKey, #teams + 1)
		teamMap[teamKey] = entry
		table.insert(teams, entry)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if viewerCanSeeHiddenPlayer(viewer, player) then
			local teamKey = getTeamKey(player)

			if not teamMap[teamKey] then
				local entry = createTeamEntry(teamKey, #teams + 1)
				teamMap[teamKey] = entry
				table.insert(teams, entry)
			end

			table.insert(teamMap[teamKey].players, {
				userId = player.UserId,
				name = player.Name,
				displayName = player.DisplayName,
				teamKey = teamKey,
				teamName = getTeamDisplayName(teamKey),
				icons = getPlayerIcons(player),
				badgesEnabled = player:GetAttribute("USARF_BadgesEnabled") == true,
				isAFK = player:GetAttribute("USARF_AFK") == true,
				isSuspiciousIdle = player:GetAttribute("USARF_SuspiciousIdle") == true,
				containmentStatus = player:GetAttribute("USARF_ContainmentStatus"),
				isCloaked = player:GetAttribute("USARF_Cloaked") == true,
				isScrambled = player:GetAttribute("USARF_Scrambled") == true,
				isHiddenFromLeaderboard = player:GetAttribute("USARF_HideFromLeaderboard") == true,
			})
		end
	end

	for _, teamEntry in ipairs(teams) do
		table.sort(teamEntry.players, function(a, b)
			return string.lower(a.name) < string.lower(b.name)
		end)
	end

	local filteredTeams = {}

	for _, teamEntry in ipairs(teams) do
		if #teamEntry.players > 0 and teamEntry.key ~= "Loading" then
			table.insert(filteredTeams, teamEntry)
		end
	end

	return {
		teams = filteredTeams,
		updatedAt = os.time(),
	}
end

function LeaderboardService.Broadcast()
	for _, viewer in ipairs(Players:GetPlayers()) do
		remote:FireClient(viewer, buildPayload(viewer))
	end
end

function LeaderboardService.SendTo(player)
	if not player or not player.Parent then
		return
	end

	remote:FireClient(player, buildPayload(player))
end

local function hookPlayer(player)
	if player:GetAttribute("USARF_HideFromLeaderboard") == nil then
		player:SetAttribute("USARF_HideFromLeaderboard", false)
	end

	local function refreshSoon()
		task.delay(0.15, function()
			LeaderboardService.Broadcast()
		end)
	end

	player:GetAttributeChangedSignal("USARF_TeamName"):Connect(refreshSoon)
	player:GetAttributeChangedSignal("USARF_TeamKey"):Connect(refreshSoon)
	player:GetAttributeChangedSignal("USARF_BadgesEnabled"):Connect(refreshSoon)
	player:GetAttributeChangedSignal("USARF_AFK"):Connect(refreshSoon)
	player:GetAttributeChangedSignal("USARF_SuspiciousIdle"):Connect(refreshSoon)
	player:GetAttributeChangedSignal("USARF_ContainmentStatus"):Connect(refreshSoon)
	player:GetAttributeChangedSignal("USARF_Cloaked"):Connect(refreshSoon)
	player:GetAttributeChangedSignal("USARF_Scrambled"):Connect(refreshSoon)
	player:GetAttributeChangedSignal("USARF_HideFromLeaderboard"):Connect(refreshSoon)
	player:GetAttributeChangedSignal("USARF_CmdrAdminLevelValue"):Connect(refreshSoon)

	player:GetPropertyChangedSignal("Team"):Connect(refreshSoon)
	player:GetPropertyChangedSignal("DisplayName"):Connect(refreshSoon)

	task.delay(1, function()
		LeaderboardService.Broadcast()
	end)
end

function LeaderboardService.Start()
	if started then
		return
	end

	started = true

	Players.PlayerAdded:Connect(function(player)
		hookPlayer(player)

		task.delay(1, function()
			LeaderboardService.SendTo(player)
			LeaderboardService.Broadcast()
		end)
	end)

	Players.PlayerRemoving:Connect(function()
		task.delay(0.2, function()
			LeaderboardService.Broadcast()
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		hookPlayer(player)
	end

	task.spawn(function()
		while started do
			LeaderboardService.Broadcast()
			task.wait(10)
		end
	end)

	print("USARF LeaderboardService initialized")
end

task.defer(function()
	LeaderboardService.Start()
end)

return LeaderboardService
