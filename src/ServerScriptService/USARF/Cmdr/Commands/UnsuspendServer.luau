local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local SuspensionService = require(Services:WaitForChild("SuspensionService"))

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local MENU_REFRESH_REMOTE_NAME = "ModerationMenuRefresh"

local function getOrCreateRemote()
	local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = REMOTE_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	local remote = folder:FindFirstChild(MENU_REFRESH_REMOTE_NAME)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = MENU_REFRESH_REMOTE_NAME
		remote.Parent = folder
	end

	return remote
end

local menuRefreshRemote = getOrCreateRemote()

local function clean(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function refreshPlayer(player)
	if not player then
		return
	end

	menuRefreshRemote:FireClient(player, {
		action = "RefreshMenu",
		reason = "SuspensionRevoked",
	})
end

local function refreshAllMenus()
	for _, player in ipairs(Players:GetPlayers()) do
		refreshPlayer(player)
	end
end

return function(context, caseId)
	caseId = clean(caseId)

	if caseId == "" then
		return "Missing suspension case ID."
	end

	local ok, result = SuspensionService.RemoveSuspensionByCaseId(caseId, context.Executor.UserId)

	if not ok then
		return tostring(result)
	end

	refreshAllMenus()

	return string.format(
		"Revoked suspension %s | Scope: %s | Target: %s",
		tostring(caseId),
		tostring(result.scope or "Unknown"),
		tostring(result.targetName or result.target or "Unknown")
	)
end
