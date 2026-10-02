local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ServerScriptService = game:GetService("ServerScriptService")

local returnRequests = {}
local RETURN_DELAY = 7

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local GetMenuPayloadRemote = Remotes:WaitForChild("GetMenuPayload")
local SelectTeamRemote = Remotes:WaitForChild("SelectTeam")
local ReturnToMenuRemote = Remotes:WaitForChild("ReturnToMenu")

local function getOrCreate(parent, className, name)
	local existing = parent:FindFirstChild(name)

	if existing then
		return existing
	end

	local object = Instance.new(className)
	object.Name = name
	object.Parent = parent

	return object
end

local MenuPayloadChangedRemote = getOrCreate(Remotes, "RemoteEvent", "MenuPayloadChanged")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local TeamAccessService = require(Services:WaitForChild("TeamAccessService"))
local SpawnService = require(Services:WaitForChild("SpawnService"))
local RankService = require(Services:WaitForChild("RankService"))

local TeamController = {}

local function setPlayerMenuState(player, inMenu)
	if not player then
		return
	end

	player:SetAttribute("USARF_InMenu", inMenu == true)
end

local function clearReturnRequest(player)
	if player then
		returnRequests[player.UserId] = nil
	end
end

local function clearDeployedAttributes(player)
	if not player then
		return
	end

	player:SetAttribute("USARF_TeamKey", nil)
	player:SetAttribute("USARF_TeamName", "")
	player:SetAttribute("USARF_SpawnKey", nil)
	player:SetAttribute("USARF_RankName", RankService.GetMainGroupRank(player))
end

local function notifyMenuPayloadChanged(player, reason)
	if not player or not player.Parent then
		return
	end

	MenuPayloadChangedRemote:FireClient(player, {
		reason = reason or "updated",
		timestamp = os.time(),
	})
end

local function applyDeployedAttributes(player, access, spawnAccess, teamKey)
	local finalAccess = spawnAccess or access or {}
	local originalAccess = access or {}
	local teamData = finalAccess.teamData or originalAccess.teamData or {}

	setPlayerMenuState(player, false)
	clearReturnRequest(player)

	player:SetAttribute("USARF_TeamKey", teamKey)
	player:SetAttribute("USARF_TeamName", teamData.teamName or teamData.displayName or "")
	player:SetAttribute("USARF_SpawnKey", teamData.spawnKey or teamKey)
	player:SetAttribute(
		"USARF_RankName",
		finalAccess.rankName or originalAccess.rankName or RankService.GetMainGroupRank(player)
	)
end

local function movePlayerToLoadingTeam(player)
	local loadingTeam = Teams:FindFirstChild("Loading")

	if loadingTeam then
		player.Team = loadingTeam
		player.Neutral = false
		return
	end

	local testSubjectTeam = Teams:FindFirstChild("Test Subject")

	if testSubjectTeam then
		player.Team = testSubjectTeam
		player.Neutral = false
	end
end

function TeamController.SendPlayerToMenu(player, reason, options)
	if not player or not player.Parent then
		return false, "Missing player"
	end

	options = options or {}

	clearReturnRequest(player)
	movePlayerToLoadingTeam(player)
	setPlayerMenuState(player, true)
	clearDeployedAttributes(player)

	player:SetAttribute("USARF_MenuReturnReason", tostring(reason or "Returned to menu"))

	local success, message = SpawnService.SendPlayerToDefaultSpawn(player)

	if not success and options.forceReload ~= false then
		local reloadSuccess, reloadError = pcall(function()
			player:LoadCharacter()
		end)

		if not reloadSuccess then
			warn(
				"[TeamController] Failed to reload character while returning player to menu:",
				player.Name,
				reloadError
			)
		end
	end

	notifyMenuPayloadChanged(player, options.refreshReason or "returned_to_menu")

	return success, message or reason or "Returned to menu"
end

function TeamController.RefreshPlayerMenu(player, reason)
	if not player or not player.Parent then
		return false
	end

	notifyMenuPayloadChanged(player, reason or "manual_refresh")
	return true
end

GetMenuPayloadRemote.OnServerInvoke = function(player)
	return TeamAccessService.GetMenuPayload(player)
end

SelectTeamRemote.OnServerInvoke = function(player, teamKey)
	if typeof(teamKey) ~= "string" then
		return {
			success = false,
			message = "Invalid team key",
		}
	end

	local access = TeamAccessService.CanPlayerUseTeam(player, teamKey)

	if not access.canAccess then
		setPlayerMenuState(player, true)
		notifyMenuPayloadChanged(player, "deployment_denied")

		return {
			success = false,
			message = access.requiredText or access.reason or "You cannot deploy to this team.",
			access = access,
		}
	end

	local success, message, spawnAccess = SpawnService.SendPlayerToTeamSpawn(player, teamKey)

	if success then
		applyDeployedAttributes(player, access, spawnAccess, teamKey)
	else
		setPlayerMenuState(player, true)
		notifyMenuPayloadChanged(player, "deployment_failed")
	end

	return {
		success = success,
		message = message,
		access = spawnAccess or access,
	}
end

ReturnToMenuRemote.OnServerInvoke = function(player, action)
	local userId = player.UserId
	local currentTime = os.clock()

	if action == "cancel" then
		returnRequests[userId] = nil

		return {
			success = false,
			cancelled = true,
			message = "Return cancelled",
		}
	end

	if action == "start" then
		returnRequests[userId] = currentTime

		return {
			success = false,
			countdownStarted = true,
			waitTime = RETURN_DELAY,
			message = "Return countdown started",
		}
	end

	if action == "complete" then
		local startedAt = returnRequests[userId]

		if not startedAt then
			return {
				success = false,
				message = "No active return request",
			}
		end

		local elapsed = currentTime - startedAt

		if elapsed < RETURN_DELAY then
			return {
				success = false,
				countdownStarted = true,
				waitTime = math.ceil(RETURN_DELAY - elapsed),
				message = "Return countdown still active",
			}
		end

		returnRequests[userId] = nil

		local success, message = TeamController.SendPlayerToMenu(player, "Returned to menu", {
			refreshReason = "player_requested_return",
		})

		return {
			success = success,
			message = message or "Returned to menu",
		}
	end

	return {
		success = false,
		message = "Invalid return action",
	}
end

local externalSuspensionEvent = Services:FindFirstChild("ExternalSuspensionChanged")

if not externalSuspensionEvent then
	externalSuspensionEvent = Instance.new("BindableEvent")
	externalSuspensionEvent.Name = "ExternalSuspensionChanged"
	externalSuspensionEvent.Parent = Services
end

externalSuspensionEvent.Event:Connect(function(player)
	if not player or not player.Parent then
		return
	end

	local currentTeamKey = nil

	if player.Team then
		currentTeamKey = TeamAccessService.ResolveTeamKey(player.Team.Name)
	end

	local mustReturnToMenu = false
	local access = nil

	if currentTeamKey then
		access = TeamAccessService.CanPlayerUseTeam(player, currentTeamKey)

		mustReturnToMenu = access.status == "suspended"
	end

	if mustReturnToMenu then
		local suspensionMessage = access.requiredText
			or "An active suspension prevents you from remaining on this team."

		TeamController.SendPlayerToMenu(player, suspensionMessage, {
			refreshReason = "external_suspension_enforced",
			forceReload = true,
		})
	else
		notifyMenuPayloadChanged(player, "external_suspension_updated")
	end
end)

Players.PlayerAdded:Connect(function(player)
	setPlayerMenuState(player, true)

	player:SetAttribute("USARF_RankName", RankService.GetMainGroupRank(player))

	player:SetAttribute("USARF_TeamName", "")
	player:SetAttribute("USARF_MenuReturnReason", nil)

	task.defer(function()
		if player and player.Parent then
			notifyMenuPayloadChanged(player, "player_joined")
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	returnRequests[player.UserId] = nil
end)

return TeamController
