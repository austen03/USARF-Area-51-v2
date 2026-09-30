local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local CertificationConfig = require(USARFServer:WaitForChild("Config"):WaitForChild("CertificationConfig"))
local DiscordBotBridge = require(Services:WaitForChild("DiscordBotBridge"))

local CertificationService = {}

type Entry = {
	List: { string },
	Set: { [string]: boolean },
	Source: string,
	FetchedAt: number,
}

local entries: { [Player]: Entry } = {}
local fetching: { [Player]: boolean } = {}

local sheetMap: { [number]: { string } }? = nil
local sheetFetchedAt = -math.huge

local changed = Instance.new("BindableEvent")

CertificationService.Changed = changed.Event

local started = false

local function normalize(name: string): string
	return string.lower((string.gsub(name, "%s+", "")))
end

local function normalizeKey(value: any): string
	return (string.gsub(string.lower(tostring(value)), "[%s:_]", ""))
end

local function parseList(value: any): { string }
	local list = {}

	if typeof(value) == "table" then
		for _, item in value do
			if typeof(item) == "string" and item ~= "" then
				table.insert(list, item)
			end
		end
	elseif typeof(value) == "string" then
		for item in string.gmatch(value, "([^,]+)") do
			item = string.gsub(item, "^%s+", ""):gsub("%s+$", "")

			if item ~= "" then
				table.insert(list, item)
			end
		end
	end

	return list
end

local function getRowValue(row: { [string]: any }, keys: { string }): any
	for rowKey, value in row do
		local normalizedRowKey = normalizeKey(rowKey)

		for _, wantedKey in keys do
			if normalizedRowKey == normalizeKey(wantedKey) then
				return value
			end
		end
	end

	return nil
end

local function fetchFromBot(userId: number): { string }?
	local result = DiscordBotBridge.Request(CertificationConfig.BotPath .. tostring(userId), "GET", nil)

	if not result or not result.ok or typeof(result.data) ~= "table" then
		return nil
	end

	local data = if typeof(result.data.data) == "table" then result.data.data else result.data
	local certifications = data.certifications or data.Certifications

	if typeof(certifications) ~= "table" then
		return nil
	end

	return parseList(certifications)
end

local function loadSheet(): { [number]: { string } }?
	if os.clock() - sheetFetchedAt < CertificationConfig.SheetCacheSeconds then
		return sheetMap
	end

	sheetFetchedAt = os.clock()

	local success, body = pcall(function()
		return HttpService:GetAsync(CertificationConfig.SheetUrl)
	end)

	if not success then
		warn("[CertificationService] Sheet request failed:", body)
		return sheetMap
	end

	local decoded, rows = pcall(function()
		return HttpService:JSONDecode(body)
	end)

	if not decoded or typeof(rows) ~= "table" then
		warn("[CertificationService] Sheet returned invalid JSON")
		return sheetMap
	end

	local map = {}

	for _, row in rows do
		if typeof(row) == "table" then
			local userId = tonumber(getRowValue(row, { "RobloxUserId", "UserId", "Roblox UserId" }))

			if userId then
				map[userId] = parseList(getRowValue(row, { "Certifications", "Certification" }))
			end
		end
	end

	sheetMap = map
	return sheetMap
end

local function makeEntry(list: { string }, source: string): Entry
	local set = {}

	for _, name in list do
		set[normalize(name)] = true
	end

	return { List = list, Set = set, Source = source, FetchedAt = os.clock() }
end

local function sameSet(a: Entry?, b: Entry): boolean
	if not a then
		return #b.List == 0
	end

	for key in a.Set do
		if not b.Set[key] then
			return false
		end
	end

	for key in b.Set do
		if not a.Set[key] then
			return false
		end
	end

	return true
end

function CertificationService.Refresh(player: Player): Entry?
	if fetching[player] then
		while fetching[player] and player.Parent do
			task.wait(0.1)
		end

		return entries[player]
	end

	fetching[player] = true

	local entry: Entry? = nil
	local botList = fetchFromBot(player.UserId)

	if botList then
		entry = makeEntry(botList, "Discord")
	else
		local map = loadSheet()

		if map then
			entry = makeEntry(map[player.UserId] or {}, "Sheet")
		end
	end

	fetching[player] = nil

	if not entry or not player.Parent then
		return entries[player]
	end

	local previous = entries[player]
	entries[player] = entry

	if not sameSet(previous, entry) then
		changed:Fire(player)
	end

	return entry
end

local function getEntry(player: Player): Entry?
	local entry = entries[player]

	if not entry or os.clock() - entry.FetchedAt >= CertificationConfig.RefreshSeconds then
		entry = CertificationService.Refresh(player)
	end

	return entry
end

function CertificationService.Has(player: Player, certification: string): boolean
	local entry = getEntry(player)
	return entry ~= nil and entry.Set[normalize(certification)] == true
end

function CertificationService.Get(player: Player): ({ string }, string)
	local entry = getEntry(player)

	if not entry then
		return {}, "Unavailable"
	end

	return table.clone(entry.List), entry.Source
end

function CertificationService.Start()
	if started then
		return
	end

	started = true

	Players.PlayerAdded:Connect(function(player)
		CertificationService.Refresh(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		entries[player] = nil
		fetching[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(CertificationService.Refresh, player)
	end

	task.spawn(function()
		while true do
			task.wait(CertificationConfig.RefreshSeconds)

			for _, player in Players:GetPlayers() do
				task.spawn(CertificationService.Refresh, player)
			end
		end
	end)

	print("[CertificationService] Started")
end

return CertificationService
