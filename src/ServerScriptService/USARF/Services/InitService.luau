local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local InitService = {}

local DATASTORE_NAME = "USARF_InitScripts_v1"
local REMOTE_FOLDER_NAME = "USARF_Remotes"
local REMOTE_NAME = "InitRemote"

local store = DataStoreService:GetDataStore(DATASTORE_NAME)
local started = false
local initCache = {}

local DEFAULT_INIT = [[-- Example:
-- bind Home badges
-- bind Delete modmode]]

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

local function getKey(player)
	return "Init_" .. tostring(player.UserId)
end

local function cleanText(text)
	text = tostring(text or "")
	text = text:gsub("\r\n", "\n")
	text = text:gsub("\r", "\n")

	if #text > 6000 then
		text = string.sub(text, 1, 6000)
	end

	return text
end

function InitService.GetScript(player)
	if not player then
		return DEFAULT_INIT
	end

	return initCache[player.UserId] or DEFAULT_INIT
end

function InitService.SetScript(player, text)
	if not player then
		return false, "Missing player."
	end

	text = cleanText(text)
	initCache[player.UserId] = text

	task.spawn(function()
		local success, result = pcall(function()
			store:SetAsync(getKey(player), text)
		end)

		if not success then
			warn("[InitService] Failed to save init for", player.Name, result)
		end
	end)

	return true
end

function InitService.OpenEditor(player)
	if not player then
		return
	end

	remote:FireClient(player, "OpenEditor", InitService.GetScript(player))
end

function InitService.RunInit(player)
	if not player then
		return
	end

	remote:FireClient(player, "RunInit", InitService.GetScript(player))
end

local function loadPlayer(player)
	local success, result = pcall(function()
		return store:GetAsync(getKey(player))
	end)

	if success and type(result) == "string" and result ~= "" then
		initCache[player.UserId] = cleanText(result)
	else
		initCache[player.UserId] = DEFAULT_INIT
	end

	task.delay(4, function()
		if player.Parent then
			InitService.RunInit(player)
		end
	end)
end

local function savePlayer(player)
	if not player then
		return
	end

	local text = initCache[player.UserId]

	if type(text) ~= "string" then
		return
	end

	pcall(function()
		store:SetAsync(getKey(player), text)
	end)

	initCache[player.UserId] = nil
end

function InitService.Start()
	if started then
		return
	end

	started = true

	remote.OnServerEvent:Connect(function(player, action, text)
		if action == "SaveInit" then
			InitService.SetScript(player, text)
		elseif action == "RunInit" then
			InitService.RunInit(player)
		end
	end)

	Players.PlayerAdded:Connect(loadPlayer)
	Players.PlayerRemoving:Connect(savePlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(loadPlayer, player)
	end

	print("[InitService] Started")
end

return InitService