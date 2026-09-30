local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainGroupRanks = require(ReplicatedStorage:WaitForChild("USARF"):WaitForChild("Config"):WaitForChild("MainGroupRanks"))

local AuthorizationService = {}

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local REMOTE_FOLDER = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)

if not REMOTE_FOLDER then
	REMOTE_FOLDER = Instance.new("Folder")
	REMOTE_FOLDER.Name = REMOTE_FOLDER_NAME
	REMOTE_FOLDER.Parent = ReplicatedStorage
end

local AUTH_FOLDER = REMOTE_FOLDER:FindFirstChild("Authorization")

if not AUTH_FOLDER then
	AUTH_FOLDER = Instance.new("Folder")
	AUTH_FOLDER.Name = "Authorization"
	AUTH_FOLDER.Parent = REMOTE_FOLDER
end

local getSubjectsFunction = AUTH_FOLDER:FindFirstChild("GetTestSubjects")

if not getSubjectsFunction then
	getSubjectsFunction = Instance.new("RemoteFunction")
	getSubjectsFunction.Name = "GetTestSubjects"
	getSubjectsFunction.Parent = AUTH_FOLDER
end

local authorizeEvent = AUTH_FOLDER:FindFirstChild("AuthorizeSubjects")

if not authorizeEvent then
	authorizeEvent = Instance.new("RemoteEvent")
	authorizeEvent.Name = "AuthorizeSubjects"
	authorizeEvent.Parent = AUTH_FOLDER
end

local clearEvent = AUTH_FOLDER:FindFirstChild("ClearSubjects")

if not clearEvent then
	clearEvent = Instance.new("RemoteEvent")
	clearEvent.Name = "ClearSubjects"
	clearEvent.Parent = AUTH_FOLDER
end

local clickEvent = AUTH_FOLDER:FindFirstChild("ToggleSubjectByClick")

if not clickEvent then
	clickEvent = Instance.new("RemoteEvent")
	clickEvent.Name = "ToggleSubjectByClick"
	clickEvent.Parent = AUTH_FOLDER
end

local function isTestSubject(player)
	if not player then
		return false
	end

	local teamKey = player:GetAttribute("USARF_TeamKey")
	local teamName = player:GetAttribute("USARF_TeamName")

	if teamKey == "TestSubject" then
		return true
	end

	if teamName == "Test Subject" then
		return true
	end

	if player.Team and player.Team.Name == "Test Subject" then
		return true
	end

	return false
end

local function canAuthorize(player)
	if not player then
		return false
	end

	local teamKey = player:GetAttribute("USARF_TeamKey")
	local teamName = player:GetAttribute("USARF_TeamName")

	if teamKey == "Infantry108"
		or teamKey == "MP137"
		or teamKey == "SpecOpsAIG"
		or teamKey == "SecretService"
		or teamKey == "FederalAdministration"
		or teamKey == "President"
		or teamKey == "VicePresident"
	then
		return true
	end

	if teamName == "108th Infantry Regiment"
		or teamName == "137th Military Police Company"
		or teamName == "1st Spec. Ops. A.I.G"
		or teamName == "Secret Service"
		or teamName == "Federal Administration"
		or teamName == "President of the United States"
		or teamName == "Vice President of the United States"
	then
		return true
	end

	local rank = 0

	pcall(function()
		rank = player:GetRankInGroup(MainGroupRanks.GroupId)
	end)

	return MainGroupRanks.EffectiveRank(MainGroupRanks.GroupId, rank) >= 13
end

function AuthorizationService.IsTestSubject(player)
	return isTestSubject(player)
end

function AuthorizationService.CanAuthorize(player)
	return canAuthorize(player)
end

function AuthorizationService.SetAuthorized(targetPlayer, authorized)
	if not targetPlayer or not isTestSubject(targetPlayer) then
		return false, "Target must be a Test Subject."
	end

	if authorized == true then
		targetPlayer:SetAttribute("USARF_ContainmentStatus", "AUTHORIZED")
	else
		targetPlayer:SetAttribute("USARF_ContainmentStatus", nil)
	end

	return true
end

function AuthorizationService.SetTerminate(targetPlayer)
	if not targetPlayer or not isTestSubject(targetPlayer) then
		return false, "Target must be a Test Subject."
	end

	targetPlayer:SetAttribute("USARF_ContainmentStatus", "TERMINATE")
	return true
end

function AuthorizationService.ClearStatus(targetPlayer)
	if not targetPlayer then
		return false, "Missing target."
	end

	targetPlayer:SetAttribute("USARF_ContainmentStatus", nil)
	return true
end

function AuthorizationService.GetTestSubjectList()
	local list = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if isTestSubject(player) then
			table.insert(list, {
				userId = player.UserId,
				name = player.Name,
				displayName = player.DisplayName,
				status = player:GetAttribute("USARF_ContainmentStatus") or "",
			})
		end
	end

	table.sort(list, function(a, b)
		return string.lower(a.name) < string.lower(b.name)
	end)

	return list
end

getSubjectsFunction.OnServerInvoke = function(player)
	if not canAuthorize(player) then
		return {
			success = false,
			message = "Not authorized.",
			players = {},
		}
	end

	return {
		success = true,
		players = AuthorizationService.GetTestSubjectList(),
	}
end

authorizeEvent.OnServerEvent:Connect(function(player, userIds)
	if not canAuthorize(player) then
		return
	end

	if typeof(userIds) ~= "table" then
		return
	end

	for _, userId in ipairs(userIds) do
		local target = Players:GetPlayerByUserId(tonumber(userId) or 0)

		if target then
			AuthorizationService.SetAuthorized(target, true)
		end
	end
end)

clearEvent.OnServerEvent:Connect(function(player, userIds)
	if not canAuthorize(player) then
		return
	end

	if typeof(userIds) ~= "table" then
		return
	end

	for _, userId in ipairs(userIds) do
		local target = Players:GetPlayerByUserId(tonumber(userId) or 0)

		if target then
			AuthorizationService.ClearStatus(target)
		end
	end
end)

clickEvent.OnServerEvent:Connect(function(player, targetPlayer)
	if not canAuthorize(player) then
		return
	end

	if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then
		return
	end

	if not isTestSubject(targetPlayer) then
		return
	end

	local current = targetPlayer:GetAttribute("USARF_ContainmentStatus")

	if current == "AUTHORIZED" then
		AuthorizationService.ClearStatus(targetPlayer)
	else
		AuthorizationService.SetAuthorized(targetPlayer, true)
	end
end)

print("[AuthorizationService] Started")

return AuthorizationService