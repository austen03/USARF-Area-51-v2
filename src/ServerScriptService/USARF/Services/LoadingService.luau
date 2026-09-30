local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LoadingService = {}

local MainGroupRanks = require(ReplicatedStorage:WaitForChild("USARF"):WaitForChild("Config"):WaitForChild("MainGroupRanks"))

local MAIN_GROUP_ID = MainGroupRanks.GroupId

local TEAM_TEST_SUBJECT = "Test Subject"
local TEAM_PMC = "Private Military Company"

local REMOTE_ROOT_NAME = "USARF"
local REMOTE_FOLDER_NAME = "Remotes"
local LOADING_FOLDER_NAME = "Loading"
local REQUEST_PROFILE_REMOTE_NAME = "RequestLoadingProfile"

local started = false

local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end

	return folder
end

local function getOrCreateRemoteFunction(parent, name)
	local remote = parent:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = parent
	end

	return remote
end

local function getClearanceLevel(player)
	local rank = 0

	local success, result = pcall(function()
		return player:GetRankInGroup(MAIN_GROUP_ID)
	end)

	if success then
		rank = MainGroupRanks.EffectiveRank(MAIN_GROUP_ID, result)
	end

	if MainGroupRanks.IsFederalLeadership(rank) then
		return 10
	end

	if MainGroupRanks.IsDeveloper(rank) then
		return 9
	end
	
	if rank == 17 then
		return 10
	end
	
	if rank == 16 then
		return 10
	end
	
	if rank == 15 then
		return 9
	end
	
	if rank == 13 then
		return 8
	end

	if rank == 11 then
		return 7
	end

	if rank == 10 then
		return 6
	end

	if rank == 8 then
		return 5
	end

	if rank == 7 then
		return 4
	end

	if rank == 5 then
		return 3
	end

	if rank == 4 then
		return 2
	end

	if rank == 3 then
		return 1
	end

	return 0
end

local function getTestSubjectId(player)
	local userIdString = tostring(player.UserId)
	local lastDigits = string.sub(userIdString, -4)

	while #lastDigits < 4 do
		lastDigits = "0" .. lastDigits
	end

	return "TS-" .. lastDigits
end

local function getTeamName(player)
	if player.Team then
		return player.Team.Name
	end

	return "Loading"
end

local function getProfileType(player)
	local teamName = getTeamName(player)

	if teamName == TEAM_TEST_SUBJECT then
		return "TestSubject"
	end

	if teamName == TEAM_PMC then
		return "Contractor"
	end

	return "Personnel"
end

local function buildProfile(player)
	local teamName = getTeamName(player)
	local profileType = getProfileType(player)
	local clearanceLevel = getClearanceLevel(player)

	local identifier = "SC-" .. tostring(clearanceLevel)
	local status = "AUTHORIZED"
	local displayRole = "Personnel"

	if profileType == "TestSubject" then
		identifier = getTestSubjectId(player)
		displayRole = "Test Subject"
		status = "MONITORED"
	elseif profileType == "Contractor" then
		identifier = "Contractor"
		displayRole = "Private Military Contractor"
		status = "CONTRACTOR ACCESS"
	end

	return {
		username = player.Name,
		displayName = player.DisplayName,
		userId = player.UserId,
		teamName = teamName,
		profileType = profileType,
		displayRole = displayRole,
		identifier = identifier,
		clearanceLevel = clearanceLevel,
		status = status,
	}
end

function LoadingService.Start()
	if started then
		return
	end

	started = true

	local usarfFolder = getOrCreateFolder(ReplicatedStorage, REMOTE_ROOT_NAME)
	local remotesFolder = getOrCreateFolder(usarfFolder, REMOTE_FOLDER_NAME)
	local loadingFolder = getOrCreateFolder(remotesFolder, LOADING_FOLDER_NAME)

	local requestProfileRemote = getOrCreateRemoteFunction(loadingFolder, REQUEST_PROFILE_REMOTE_NAME)

	requestProfileRemote.OnServerInvoke = function(player)
		return buildProfile(player)
	end

	print("[LoadingService] Started")
end

return LoadingService