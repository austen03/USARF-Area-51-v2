-- USARF Clans: player-created clans with ranks, join requests, an audit log and name tag tags.
--
-- DataStore "USARF_Clans_v1" keys:
--   clan_<id>   full clan record (members, requests, log)
--   user_<id>   { ClanId = id } - which clan a player is in (source of truth for membership)
--   name_<norm> / tag_<TAG>  -> clan id, reserving unique names and tags
--   index       list of clan summaries for the Browse list
-- Every change goes through UpdateAsync and re-checks permissions against the fresh record,
-- so two servers acting at once can't corrupt a clan. Servers tell each other about changes
-- over MessagingService so name tags and open menus update everywhere.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local ClanConfig = require(USARF:WaitForChild("Config"):WaitForChild("ClanConfig"))
local Remotes = USARF:WaitForChild("Remotes")
local ClanRequest = Remotes:WaitForChild("ClanRequest")
local ClanUpdated = Remotes:WaitForChild("ClanUpdated")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local ClanService = {}

local STORE_NAME = "USARF_Clans_v1"
local MESSAGE_TOPIC = "USARF_Clans"
local INDEX_KEY = "index"
local CLAN_CACHE_SECONDS = 30
local INDEX_CACHE_SECONDS = 20
local ACTION_COOLDOWN_SECONDS = 0.35
local MAX_BROWSE_RESULTS = 100

local ATTR = {
	Id = "USARF_ClanId",
	Name = "USARF_ClanName",
	Tag = "USARF_ClanTag",
	Rank = "USARF_ClanRank",
	Logo = "USARF_ClanLogo",
	Color = "USARF_ClanColor",
}

local store = DataStoreService:GetDataStore(STORE_NAME)

local started = false
local clanCache = {} -- [clanId] = { Data = record?, FetchedAt = clock }
local indexCache = { Data = nil, FetchedAt = -math.huge }
local passOwners = {} -- [userId] = true once they own the create gamepass
local lastActionAt = {} -- [player] = clock

--// DataStore helpers

local function withRetry(callback)
	local lastError

	for attempt = 1, 3 do
		local success, result = pcall(callback)

		if success then
			return true, result
		end

		lastError = result
		task.wait(attempt)
	end

	warn("[ClanService] DataStore request failed:", lastError)
	return false, lastError
end

local function getAsync(key)
	return withRetry(function()
		return store:GetAsync(key)
	end)
end

local function updateAsync(key, transform)
	return withRetry(function()
		return store:UpdateAsync(key, transform)
	end)
end

local function removeAsync(key)
	return withRetry(function()
		return store:RemoveAsync(key)
	end)
end

local function clanKey(clanId)
	return "clan_" .. clanId
end

local function userKey(userId)
	return "user_" .. tostring(userId)
end

--// Text rules

local function trim(text)
	return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizeName(name)
	return (string.lower(name):gsub("[^%w]", ""))
end

local function nameKey(name)
	return "name_" .. normalizeName(name)
end

local function tagKey(tag)
	return "tag_" .. string.upper(tag)
end

local function containsBlacklisted(text)
	local compact = string.upper((text:gsub("[^%w]", "")))

	for _, word in ipairs(ClanConfig.BlacklistedNames) do
		if word ~= "" and string.find(compact, string.upper(word), 1, true) then
			return true
		end
	end

	return false
end

local function validateName(name)
	if typeof(name) ~= "string" then
		return nil, "Enter a clan name."
	end

	name = trim(name):gsub("%s+", " ")

	if #name < ClanConfig.Name.MinLength or #name > ClanConfig.Name.MaxLength then
		return nil, `Clan names must be {ClanConfig.Name.MinLength}-{ClanConfig.Name.MaxLength} characters.`
	end

	if not name:match("^[%w ]+$") then
		return nil, "Clan names can only use letters, numbers and spaces."
	end

	if containsBlacklisted(name) then
		return nil, "That clan name isn't allowed."
	end

	return name
end

local function validateTag(tag)
	if typeof(tag) ~= "string" then
		return nil, "Enter a clan tag."
	end

	tag = string.upper(trim(tag))

	if #tag < ClanConfig.Tag.MinLength or #tag > ClanConfig.Tag.MaxLength or not tag:match("^%w+$") then
		return nil, `Tags must be {ClanConfig.Tag.MinLength}-{ClanConfig.Tag.MaxLength} letters or numbers.`
	end

	for _, blocked in ipairs(ClanConfig.BlacklistedTags) do
		if blocked ~= "" and string.upper(blocked) == tag then
			return nil, "That tag isn't allowed."
		end
	end

	if containsBlacklisted(tag) then
		return nil, "That tag isn't allowed."
	end

	return tag
end

local function validateDescription(description)
	description = trim(description)

	if #description > ClanConfig.Description.MaxLength then
		return nil, `Descriptions can be up to {ClanConfig.Description.MaxLength} characters.`
	end

	return description
end

-- Runs player-created text through Roblox's filter (required for text other players see).
local function filterText(text, userId)
	if text == "" then
		return text
	end

	local success, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, userId, Enum.TextFilterContext.PublicChat)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)

	if not success then
		return nil, "Couldn't check that text right now. Try again in a moment."
	end

	return result
end

-- Names and tags must pass the filter unchanged; descriptions are stored filtered.
local function filterExact(text, userId, label)
	local filtered, filterError = filterText(text, userId)

	if not filtered then
		return nil, filterError
	end

	if filtered ~= text then
		return nil, `That {label} isn't allowed.`
	end

	return text
end

--// Clan record helpers

local function now()
	return os.time()
end

local function countEntries(map)
	local count = 0

	for _ in pairs(map or {}) do
		count += 1
	end

	return count
end

local function addLog(clan, text)
	clan.Log = clan.Log or {}
	table.insert(clan.Log, 1, { Time = now(), Text = text })

	while #clan.Log > ClanConfig.MaxLogEntries do
		table.remove(clan.Log)
	end
end

local function getMember(clan, userId)
	return clan and clan.Members and clan.Members[tostring(userId)]
end

local function getRankIndex(clan, userId)
	local member = getMember(clan, userId)
	return member and ClanConfig.GetRankIndex(member.Rank) or 0
end

local function summarize(clan)
	local leader = getMember(clan, clan.LeaderUserId)

	return {
		Id = clan.Id,
		Name = clan.Name,
		Tag = clan.Tag,
		LogoId = clan.LogoId,
		ColorId = clan.ColorId,
		LeaderName = leader and leader.Name or "?",
		MemberCount = countEntries(clan.Members),
	}
end

local function sortedMembers(clan)
	local list = {}

	for userIdText, member in pairs(clan.Members or {}) do
		table.insert(list, {
			UserId = tonumber(userIdText),
			Name = member.Name,
			Rank = member.Rank,
			JoinedAt = member.JoinedAt,
		})
	end

	table.sort(list, function(a, b)
		local rankA, rankB = ClanConfig.GetRankIndex(a.Rank), ClanConfig.GetRankIndex(b.Rank)

		if rankA == rankB then
			return (a.JoinedAt or 0) < (b.JoinedAt or 0)
		end

		return rankA > rankB
	end)

	return list
end

local function sortedRequests(clan)
	local list = {}

	for userIdText, request in pairs(clan.Requests or {}) do
		table.insert(list, { UserId = tonumber(userIdText), Name = request.Name, RequestedAt = request.RequestedAt })
	end

	table.sort(list, function(a, b)
		return (a.RequestedAt or 0) < (b.RequestedAt or 0)
	end)

	return list
end

--// Caches

local function cacheClan(clanId, clan)
	clanCache[clanId] = { Data = clan, FetchedAt = os.clock() }
end

local function loadClan(clanId, fresh)
	if typeof(clanId) ~= "string" or clanId == "" then
		return nil
	end

	local cached = clanCache[clanId]

	if not fresh and cached and os.clock() - cached.FetchedAt < CLAN_CACHE_SECONDS then
		return cached.Data
	end

	local success, clan = getAsync(clanKey(clanId))

	if success then
		cacheClan(clanId, clan)
		return clan
	end

	return cached and cached.Data
end

local function loadIndex()
	if indexCache.Data and os.clock() - indexCache.FetchedAt < INDEX_CACHE_SECONDS then
		return indexCache.Data
	end

	local success, index = getAsync(INDEX_KEY)

	if success then
		indexCache.Data = type(index) == "table" and index or {}
		indexCache.FetchedAt = os.clock()
	end

	return indexCache.Data or {}
end

local function writeIndexEntry(clanId, summary)
	updateAsync(INDEX_KEY, function(index)
		index = type(index) == "table" and index or {}

		for position = #index, 1, -1 do
			if index[position].Id == clanId then
				table.remove(index, position)
			end
		end

		if summary then
			table.insert(index, summary)
		end

		return index
	end)

	indexCache.FetchedAt = -math.huge
end

--// Player membership

local NameTagService = nil

local function refreshNameTag(player)
	if not NameTagService then
		local success, module = pcall(require, Services:WaitForChild("NameTagService"))
		NameTagService = success and module or false
	end

	if NameTagService and NameTagService.Refresh then
		pcall(NameTagService.Refresh, player)
	end
end

local function applyPlayerAttributes(player, clan)
	local member = clan and getMember(clan, player.UserId)

	if member then
		local logo = ClanConfig.GetLogo(clan.LogoId)
		local color = ClanConfig.GetColor(clan.ColorId)

		player:SetAttribute(ATTR.Id, clan.Id)
		player:SetAttribute(ATTR.Name, clan.Name)
		player:SetAttribute(ATTR.Tag, clan.Tag)
		player:SetAttribute(ATTR.Rank, member.Rank)
		player:SetAttribute(ATTR.Logo, logo and logo.Image or "")
		player:SetAttribute(ATTR.Color, color and color.Color or Color3.new(1, 1, 1))
	else
		for _, attribute in pairs(ATTR) do
			player:SetAttribute(attribute, nil)
		end
	end

	refreshNameTag(player)
end

-- Clears user_<id> only if it still points at clanId.
local function clearPointer(userId, clanId)
	updateAsync(userKey(userId), function(pointer)
		if type(pointer) == "table" and pointer.ClanId == clanId then
			return {}
		end

		return nil
	end)
end

-- Loads which clan the player is in, repairing a pointer to a clan they're no longer in.
local function refreshPlayer(player)
	local success, pointer = getAsync(userKey(player.UserId))

	if not success or player.Parent ~= Players then
		return
	end

	local clanId = type(pointer) == "table" and pointer.ClanId or nil
	local clan = nil

	if clanId then
		local loaded, record = getAsync(clanKey(clanId))

		if not loaded then
			-- Storage is unavailable; keep whatever we already know rather than dropping them.
			return
		end

		cacheClan(clanId, record)

		if getMember(record, player.UserId) then
			clan = record
		else
			clearPointer(player.UserId, clanId)
		end
	end

	if player.Parent == Players then
		applyPlayerAttributes(player, clan)
	end
end

local function getPlayerClanId(player)
	return player:GetAttribute(ATTR.Id)
end

--// Change propagation

local function notifyClients()
	ClanUpdated:FireAllClients()
end

-- Re-sync local players in the clan (or listed) after a change, here or in another server.
local function onClanChanged(clanId, userIds)
	userIds = userIds or {}

	for _, player in ipairs(Players:GetPlayers()) do
		if getPlayerClanId(player) == clanId or table.find(userIds, player.UserId) then
			task.spawn(refreshPlayer, player)
		end
	end

	indexCache.FetchedAt = -math.huge
	notifyClients()
end

local function broadcastChange(clanId, userIds)
	onClanChanged(clanId, userIds)

	task.spawn(function()
		pcall(function()
			MessagingService:PublishAsync(MESSAGE_TOPIC, {
				ClanId = clanId,
				UserIds = userIds or {},
				JobId = game.JobId,
			})
		end)
	end)
end

--// Gamepass

local function ownsCreatePass(player)
	local gamepassId = ClanConfig.CreateGamepassId

	if not gamepassId or gamepassId == 0 then
		return false
	end

	if passOwners[player.UserId] then
		return true
	end

	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)

	if success and owns then
		passOwners[player.UserId] = true
		return true
	end

	return false
end

--// Actions (each returns a result table for the client)

local function fail(message, extra)
	local result = { Success = false, Message = message }

	for key, value in pairs(extra or {}) do
		result[key] = value
	end

	return result
end

local function ok(message)
	return { Success = true, Message = message }
end

-- Runs transform on the fresh clan record; transform returns (newRecord) or (nil, errorMessage).
local function mutateClan(clanId, transform)
	if typeof(clanId) ~= "string" or clanId == "" then
		return nil, "That clan no longer exists."
	end

	local transformError = nil
	local saved = nil

	local success = updateAsync(clanKey(clanId), function(clan)
		if type(clan) ~= "table" then
			transformError = "That clan no longer exists."
			return nil
		end

		local newClan, message = transform(clan)

		if not newClan then
			transformError = message or "Couldn't update the clan."
			return nil
		end

		saved = newClan
		return newClan
	end)

	if not success then
		return nil, "Couldn't reach clan storage. Try again in a moment."
	end

	if transformError then
		return nil, transformError
	end

	cacheClan(clanId, saved)
	return saved
end

local Actions = {}

function Actions.GetState(player)
	local clanId = getPlayerClanId(player)
	local clan = clanId and loadClan(clanId, true) or nil
	local member = getMember(clan, player.UserId)
	local result = {
		Success = true,
		CanCreate = ownsCreatePass(player),
		CreateAvailable = ClanConfig.CreateGamepassId ~= 0,
		UserId = player.UserId,
	}

	if member then
		result.MyClan = {
			Id = clan.Id,
			Name = clan.Name,
			Tag = clan.Tag,
			LogoId = clan.LogoId,
			ColorId = clan.ColorId,
			Description = clan.Description or "",
			LeaderUserId = clan.LeaderUserId,
			MyRank = member.Rank,
			Members = sortedMembers(clan),
			Requests = ClanConfig.HasPermission(member.Rank, "ManageRequests") and sortedRequests(clan) or {},
			Log = clan.Log or {},
		}
	end

	return result
end

function Actions.ListClans(_, payload)
	local search = string.lower(trim(payload and payload.Search or ""))
	local results = {}

	for _, summary in ipairs(loadIndex()) do
		if search == ""
			or string.find(string.lower(summary.Name or ""), search, 1, true)
			or string.find(string.lower(summary.Tag or ""), search, 1, true)
		then
			table.insert(results, summary)
		end
	end

	table.sort(results, function(a, b)
		if (a.MemberCount or 0) == (b.MemberCount or 0) then
			return (a.Name or "") < (b.Name or "")
		end

		return (a.MemberCount or 0) > (b.MemberCount or 0)
	end)

	while #results > MAX_BROWSE_RESULTS do
		table.remove(results)
	end

	return { Success = true, Clans = results }
end

function Actions.GetClan(player, payload)
	local clan = loadClan(payload and payload.ClanId)

	if not clan then
		return fail("That clan no longer exists.")
	end

	return {
		Success = true,
		Clan = {
			Id = clan.Id,
			Name = clan.Name,
			Tag = clan.Tag,
			LogoId = clan.LogoId,
			ColorId = clan.ColorId,
			Description = clan.Description or "",
			LeaderUserId = clan.LeaderUserId,
			Members = sortedMembers(clan),
			MemberCount = countEntries(clan.Members),
			HasRequested = clan.Requests ~= nil and clan.Requests[tostring(player.UserId)] ~= nil,
		},
	}
end

function Actions.Create(player, payload)
	payload = payload or {}

	refreshPlayer(player)

	if getPlayerClanId(player) then
		return fail("Leave your current clan before creating one.")
	end

	if ClanConfig.CreateGamepassId == 0 then
		return fail("Clan creation isn't available yet.")
	end

	if not ownsCreatePass(player) then
		return fail("Creating a clan needs the Clan Creator gamepass.", { NeedsGamepass = true })
	end

	local name, nameError = validateName(payload.Name)
	if not name then
		return fail(nameError)
	end

	local tag, tagError = validateTag(payload.Tag)
	if not tag then
		return fail(tagError)
	end

	local description, descriptionError = validateDescription(payload.Description)
	if not description then
		return fail(descriptionError)
	end

	if not ClanConfig.GetLogo(payload.LogoId) then
		return fail("Pick a logo.")
	end

	if not ClanConfig.GetColor(payload.ColorId) then
		return fail("Pick a logo color.")
	end

	local filterError
	name, filterError = filterExact(name, player.UserId, "clan name")
	if not name then
		return fail(filterError)
	end

	tag, filterError = filterExact(tag, player.UserId, "tag")
	if not tag then
		return fail(filterError)
	end

	description, filterError = filterText(description, player.UserId)
	if not description then
		return fail(filterError)
	end

	local clanId = string.sub((HttpService:GenerateGUID(false):gsub("-", "")), 1, 16)

	-- Reserve the name and tag so no other clan can take them.
	local function reserve(key)
		local taken = false

		local success = updateAsync(key, function(owner)
			if owner and owner ~= clanId then
				taken = true
				return nil
			end

			return clanId
		end)

		return success and not taken
	end

	local function release(key)
		updateAsync(key, function(owner)
			if owner == clanId then
				return false
			end

			return nil
		end)
	end

	if not reserve(nameKey(name)) then
		return fail("That clan name is already taken.")
	end

	if not reserve(tagKey(tag)) then
		release(nameKey(name))
		return fail("That tag is already taken.")
	end

	-- Claim the player's membership pointer.
	local alreadyInClan = false
	local claimed = updateAsync(userKey(player.UserId), function(pointer)
		if type(pointer) == "table" and pointer.ClanId then
			alreadyInClan = true
			return nil
		end

		return { ClanId = clanId }
	end)

	if not claimed or alreadyInClan then
		release(nameKey(name))
		release(tagKey(tag))
		return fail("Leave your current clan before creating one.")
	end

	local clan = {
		Id = clanId,
		Name = name,
		Tag = tag,
		LogoId = payload.LogoId,
		ColorId = payload.ColorId,
		Description = description,
		CreatedAt = now(),
		LeaderUserId = player.UserId,
		Members = {
			[tostring(player.UserId)] = { Name = player.Name, Rank = "Leader", JoinedAt = now() },
		},
		Requests = {},
		Log = {},
	}

	addLog(clan, `{player.Name} created the clan.`)

	local created = updateAsync(clanKey(clanId), function(existing)
		if existing then
			return nil
		end

		return clan
	end)

	if not created then
		clearPointer(player.UserId, clanId)
		release(nameKey(name))
		release(tagKey(tag))
		return fail("Couldn't create the clan. Try again in a moment.")
	end

	cacheClan(clanId, clan)
	writeIndexEntry(clanId, summarize(clan))
	applyPlayerAttributes(player, clan)
	broadcastChange(clanId, { player.UserId })

	return ok(`Created [{tag}] {name}.`)
end

function Actions.RequestJoin(player, payload)
	local clanId = payload and payload.ClanId

	if getPlayerClanId(player) then
		return fail("You're already in a clan.")
	end

	local clan, errorMessage = mutateClan(clanId, function(clan)
		clan.Members = clan.Members or {}
		clan.Requests = clan.Requests or {}

		if getMember(clan, player.UserId) then
			return nil, "You're already in this clan."
		end

		if clan.Requests[tostring(player.UserId)] then
			return nil, "You've already requested to join."
		end

		if countEntries(clan.Members) >= ClanConfig.MaxMembers then
			return nil, "This clan is full."
		end

		if countEntries(clan.Requests) >= ClanConfig.MaxPendingRequests then
			return nil, "This clan has too many pending requests. Try again later."
		end

		clan.Requests[tostring(player.UserId)] = { Name = player.Name, RequestedAt = now() }
		return clan
	end)

	if not clan then
		return fail(errorMessage)
	end

	broadcastChange(clanId)
	return ok(`Request sent to [{clan.Tag}] {clan.Name}.`)
end

function Actions.CancelRequest(player, payload)
	local clanId = payload and payload.ClanId

	local clan, errorMessage = mutateClan(clanId, function(clan)
		if not (clan.Requests and clan.Requests[tostring(player.UserId)]) then
			return nil, "You don't have a pending request there."
		end

		clan.Requests[tostring(player.UserId)] = nil
		return clan
	end)

	if not clan then
		return fail(errorMessage)
	end

	broadcastChange(clanId)
	return ok("Request cancelled.")
end

local function requireActorClan(player)
	local clanId = getPlayerClanId(player)

	if not clanId then
		return nil, "You're not in a clan."
	end

	return clanId
end

function Actions.AcceptRequest(player, payload)
	local clanId, clanError = requireActorClan(player)
	if not clanId then
		return fail(clanError)
	end

	local targetId = tonumber(payload and payload.UserId)
	if not targetId then
		return fail("Pick a request.")
	end

	-- Claim the requester's membership pointer first, so they can't end up in two clans.
	local inOtherClan = false
	local claimed = updateAsync(userKey(targetId), function(pointer)
		if type(pointer) == "table" and pointer.ClanId and pointer.ClanId ~= clanId then
			inOtherClan = true
			return nil
		end

		return { ClanId = clanId }
	end)

	if not claimed then
		return fail("Couldn't reach clan storage. Try again in a moment.")
	end

	local clan, errorMessage = mutateClan(clanId, function(clan)
		clan.Members = clan.Members or {}
		clan.Requests = clan.Requests or {}

		local actor = getMember(clan, player.UserId)
		local request = clan.Requests[tostring(targetId)]

		if not actor or not ClanConfig.HasPermission(actor.Rank, "ManageRequests") then
			return nil, "You can't manage join requests."
		end

		if not request then
			return nil, "That request is no longer pending."
		end

		if inOtherClan then
			clan.Requests[tostring(targetId)] = nil
			return clan
		end

		if countEntries(clan.Members) >= ClanConfig.MaxMembers then
			return nil, "The clan is full."
		end

		clan.Requests[tostring(targetId)] = nil
		clan.Members[tostring(targetId)] = { Name = request.Name, Rank = ClanConfig.Ranks[1], JoinedAt = now() }
		addLog(clan, `{player.Name} accepted {request.Name}.`)
		return clan
	end)

	if not clan or inOtherClan then
		if not inOtherClan then
			clearPointer(targetId, clanId)
		end

		if clan then
			broadcastChange(clanId)
		end

		return fail(inOtherClan and "That player already joined another clan." or errorMessage)
	end

	writeIndexEntry(clanId, summarize(clan))
	broadcastChange(clanId, { targetId })
	return ok("Request accepted.")
end

function Actions.DenyRequest(player, payload)
	local clanId, clanError = requireActorClan(player)
	if not clanId then
		return fail(clanError)
	end

	local targetId = tonumber(payload and payload.UserId)

	local clan, errorMessage = mutateClan(clanId, function(clan)
		local actor = getMember(clan, player.UserId)
		local request = clan.Requests and clan.Requests[tostring(targetId)]

		if not actor or not ClanConfig.HasPermission(actor.Rank, "ManageRequests") then
			return nil, "You can't manage join requests."
		end

		if not request then
			return nil, "That request is no longer pending."
		end

		clan.Requests[tostring(targetId)] = nil
		addLog(clan, `{player.Name} denied {request.Name}.`)
		return clan
	end)

	if not clan then
		return fail(errorMessage)
	end

	broadcastChange(clanId)
	return ok("Request denied.")
end

function Actions.SetRank(player, payload)
	local clanId, clanError = requireActorClan(player)
	if not clanId then
		return fail(clanError)
	end

	local targetId = tonumber(payload and payload.UserId)
	local newRank = payload and payload.Rank
	local newIndex = ClanConfig.GetRankIndex(newRank)

	local clan, errorMessage = mutateClan(clanId, function(clan)
		local actor = getMember(clan, player.UserId)
		local target = getMember(clan, targetId)
		local actorIndex = getRankIndex(clan, player.UserId)
		local targetIndex = getRankIndex(clan, targetId)

		if not actor or not ClanConfig.HasPermission(actor.Rank, "RankMembers") then
			return nil, "You can't change ranks."
		end

		if not target then
			return nil, "That player isn't in the clan."
		end

		if targetIndex >= actorIndex then
			return nil, "You can only change the rank of members below you."
		end

		if newIndex < 1 or newIndex >= actorIndex or newRank == "Leader" then
			return nil, "You can only set ranks below your own."
		end

		if newIndex == targetIndex then
			return nil, `{target.Name} is already {newRank}.`
		end

		local verb = newIndex > targetIndex and "promoted" or "demoted"
		target.Rank = newRank
		addLog(clan, `{player.Name} {verb} {target.Name} to {newRank}.`)
		return clan
	end)

	if not clan then
		return fail(errorMessage)
	end

	broadcastChange(clanId, { targetId })
	return ok("Rank updated.")
end

function Actions.Kick(player, payload)
	local clanId, clanError = requireActorClan(player)
	if not clanId then
		return fail(clanError)
	end

	local targetId = tonumber(payload and payload.UserId)

	local clan, errorMessage = mutateClan(clanId, function(clan)
		local actor = getMember(clan, player.UserId)
		local target = getMember(clan, targetId)

		if not actor or not ClanConfig.HasPermission(actor.Rank, "KickMembers") then
			return nil, "You can't kick members."
		end

		if not target then
			return nil, "That player isn't in the clan."
		end

		if getRankIndex(clan, targetId) >= getRankIndex(clan, player.UserId) then
			return nil, "You can only kick members below you."
		end

		clan.Members[tostring(targetId)] = nil
		addLog(clan, `{player.Name} kicked {target.Name}.`)
		return clan
	end)

	if not clan then
		return fail(errorMessage)
	end

	clearPointer(targetId, clanId)
	writeIndexEntry(clanId, summarize(clan))
	broadcastChange(clanId, { targetId })
	return ok("Member kicked.")
end

function Actions.Leave(player)
	local clanId, clanError = requireActorClan(player)
	if not clanId then
		return fail(clanError)
	end

	local clan, errorMessage = mutateClan(clanId, function(clan)
		local member = getMember(clan, player.UserId)

		if not member then
			return nil, "You're not in this clan."
		end

		if member.Rank == "Leader" then
			return nil, "Transfer leadership or disband the clan before leaving."
		end

		clan.Members[tostring(player.UserId)] = nil
		addLog(clan, `{player.Name} left the clan.`)
		return clan
	end)

	if not clan then
		return fail(errorMessage)
	end

	clearPointer(player.UserId, clanId)
	writeIndexEntry(clanId, summarize(clan))
	applyPlayerAttributes(player, nil)
	broadcastChange(clanId, { player.UserId })
	return ok("You left the clan.")
end

function Actions.TransferLeadership(player, payload)
	local clanId, clanError = requireActorClan(player)
	if not clanId then
		return fail(clanError)
	end

	local targetId = tonumber(payload and payload.UserId)

	local clan, errorMessage = mutateClan(clanId, function(clan)
		local actor = getMember(clan, player.UserId)
		local target = getMember(clan, targetId)

		if not actor or not ClanConfig.HasPermission(actor.Rank, "TransferLeadership") then
			return nil, "Only the Leader can transfer leadership."
		end

		if not target or targetId == player.UserId then
			return nil, "Pick another clan member."
		end

		target.Rank = "Leader"
		actor.Rank = "Co-Leader"
		clan.LeaderUserId = targetId
		addLog(clan, `{player.Name} transferred leadership to {target.Name}.`)
		return clan
	end)

	if not clan then
		return fail(errorMessage)
	end

	writeIndexEntry(clanId, summarize(clan))
	broadcastChange(clanId, { targetId, player.UserId })
	return ok("Leadership transferred.")
end

function Actions.EditAppearance(player, payload)
	payload = payload or {}

	local clanId, clanError = requireActorClan(player)
	if not clanId then
		return fail(clanError)
	end

	if not ClanConfig.GetLogo(payload.LogoId) then
		return fail("Pick a logo.")
	end

	if not ClanConfig.GetColor(payload.ColorId) then
		return fail("Pick a logo color.")
	end

	local description, descriptionError = validateDescription(payload.Description)
	if not description then
		return fail(descriptionError)
	end

	description, descriptionError = filterText(description, player.UserId)
	if not description then
		return fail(descriptionError)
	end

	local clan, errorMessage = mutateClan(clanId, function(clan)
		local actor = getMember(clan, player.UserId)

		if not actor or not ClanConfig.HasPermission(actor.Rank, "EditAppearance") then
			return nil, "Only the Leader can edit the clan's appearance."
		end

		clan.LogoId = payload.LogoId
		clan.ColorId = payload.ColorId
		clan.Description = description
		addLog(clan, `{player.Name} updated the clan's appearance.`)
		return clan
	end)

	if not clan then
		return fail(errorMessage)
	end

	writeIndexEntry(clanId, summarize(clan))
	broadcastChange(clanId)
	return ok("Clan updated.")
end

-- Deletes a clan and everything that points at it. Used by Disband and staff deletes.
local function deleteClan(clan)
	local memberIds = {}

	for userIdText in pairs(clan.Members or {}) do
		table.insert(memberIds, tonumber(userIdText))
	end

	removeAsync(clanKey(clan.Id))

	for _, key in ipairs({ nameKey(clan.Name), tagKey(clan.Tag) }) do
		local success, owner = getAsync(key)

		if success and owner == clan.Id then
			removeAsync(key)
		end
	end

	for _, userId in ipairs(memberIds) do
		clearPointer(userId, clan.Id)
	end

	cacheClan(clan.Id, nil)
	writeIndexEntry(clan.Id, nil)
	broadcastChange(clan.Id, memberIds)
end

function Actions.Disband(player)
	local clanId, clanError = requireActorClan(player)
	if not clanId then
		return fail(clanError)
	end

	local clan = loadClan(clanId, true)
	local actor = getMember(clan, player.UserId)

	if not actor or not ClanConfig.HasPermission(actor.Rank, "Disband") then
		return fail("Only the Leader can disband the clan.")
	end

	deleteClan(clan)
	return ok(`[{clan.Tag}] {clan.Name} was disbanded.`)
end

--// Staff moderation (used by the clan Cmdr commands)

local function findClanByTag(tag)
	tag = string.upper(trim(tag))

	local success, clanId = getAsync(tagKey(tag))

	if not success or type(clanId) ~= "string" then
		return nil
	end

	return loadClan(clanId, true)
end

function ClanService.StaffDelete(tag, staffName)
	local clan = findClanByTag(tag)

	if not clan then
		return false, `No clan with tag [{string.upper(tag)}].`
	end

	deleteClan(clan)
	return true, `Deleted [{clan.Tag}] {clan.Name} (by {staffName}).`
end

function ClanService.StaffRename(tag, newName, staffName)
	local clan = findClanByTag(tag)

	if not clan then
		return false, `No clan with tag [{string.upper(tag)}].`
	end

	local name, nameError = validateName(newName)
	if not name then
		return false, nameError
	end

	local oldName = clan.Name
	local taken = false

	updateAsync(nameKey(name), function(owner)
		if owner and owner ~= clan.Id then
			taken = true
			return nil
		end

		return clan.Id
	end)

	if taken then
		return false, "That clan name is already taken."
	end

	local updated, errorMessage = mutateClan(clan.Id, function(record)
		record.Name = name
		addLog(record, `Staff renamed the clan from {oldName} to {name}.`)
		return record
	end)

	if not updated then
		return false, errorMessage
	end

	if normalizeName(oldName) ~= normalizeName(name) then
		removeAsync(nameKey(oldName))
	end

	writeIndexEntry(clan.Id, summarize(updated))
	broadcastChange(clan.Id)
	return true, `Renamed [{updated.Tag}] {oldName} to {name} (by {staffName}).`
end

function ClanService.StaffRetag(tag, newTag, staffName)
	local clan = findClanByTag(tag)

	if not clan then
		return false, `No clan with tag [{string.upper(tag)}].`
	end

	local validTag, tagError = validateTag(newTag)
	if not validTag then
		return false, tagError
	end

	local oldTag = clan.Tag
	local taken = false

	updateAsync(tagKey(validTag), function(owner)
		if owner and owner ~= clan.Id then
			taken = true
			return nil
		end

		return clan.Id
	end)

	if taken then
		return false, "That tag is already taken."
	end

	local updated, errorMessage = mutateClan(clan.Id, function(record)
		record.Tag = validTag
		addLog(record, `Staff changed the tag from [{oldTag}] to [{validTag}].`)
		return record
	end)

	if not updated then
		return false, errorMessage
	end

	if oldTag ~= validTag then
		removeAsync(tagKey(oldTag))
	end

	writeIndexEntry(clan.Id, summarize(updated))
	broadcastChange(clan.Id)
	return true, `Changed [{oldTag}] to [{validTag}] (by {staffName}).`
end

-- Removes a player from whatever clan they're in. A Leader removed this way hands the clan
-- to its highest-ranked remaining member, or the clan is deleted if it would be empty.
function ClanService.StaffRemoveMember(userId, staffName)
	local success, pointer = getAsync(userKey(userId))
	local clanId = success and type(pointer) == "table" and pointer.ClanId or nil
	local clan = clanId and loadClan(clanId, true)

	if not getMember(clan, userId) then
		if clanId then
			clearPointer(userId, clanId)
		end

		return false, "That player isn't in a clan."
	end

	if countEntries(clan.Members) <= 1 then
		deleteClan(clan)
		return true, `Removed the last member, so [{clan.Tag}] {clan.Name} was deleted (by {staffName}).`
	end

	local removedName = getMember(clan, userId).Name

	local updated, errorMessage = mutateClan(clanId, function(record)
		local wasLeader = record.LeaderUserId == userId
		record.Members[tostring(userId)] = nil

		if wasLeader then
			local successor = sortedMembers(record)[1]
			record.Members[tostring(successor.UserId)].Rank = "Leader"
			record.LeaderUserId = successor.UserId
			addLog(record, `Staff removed {removedName}; {successor.Name} is now Leader.`)
		else
			addLog(record, `Staff removed {removedName}.`)
		end

		return record
	end)

	if not updated then
		return false, errorMessage
	end

	clearPointer(userId, clanId)
	writeIndexEntry(clanId, summarize(updated))
	broadcastChange(clanId, { userId, updated.LeaderUserId })
	return true, `Removed {removedName} from [{updated.Tag}] {updated.Name} (by {staffName}).`
end

function ClanService.StaffInfo(tag)
	local clan = findClanByTag(tag)

	if not clan then
		return false, `No clan with tag [{string.upper(tag)}].`
	end

	local leader = getMember(clan, clan.LeaderUserId)

	return true,
		`[{clan.Tag}] {clan.Name} | Id {clan.Id} | Leader {leader and leader.Name or "?"} ({clan.LeaderUserId}) | {countEntries(clan.Members)}/{ClanConfig.MaxMembers} members | {countEntries(clan.Requests)} pending`
end

--// Remote handling

local function handleRequest(player, action, payload)
	local handler = Actions[action]

	if typeof(action) ~= "string" or not handler then
		return fail("Unknown action.")
	end

	local readOnly = action == "GetState" or action == "ListClans" or action == "GetClan"

	if not readOnly then
		local last = lastActionAt[player]

		if last and os.clock() - last < ACTION_COOLDOWN_SECONDS then
			return fail("Slow down a little.")
		end

		lastActionAt[player] = os.clock()
	end

	local success, result = pcall(handler, player, type(payload) == "table" and payload or {})

	if not success then
		warn("[ClanService] " .. action .. " failed for " .. player.Name .. ":", result)
		return fail("Something went wrong. Try again.")
	end

	return result
end

function ClanService.Start()
	if started then
		return
	end

	started = true

	ClanRequest.OnServerInvoke = handleRequest

	Players.PlayerAdded:Connect(function(player)
		task.spawn(refreshPlayer, player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(refreshPlayer, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		lastActionAt[player] = nil
		passOwners[player.UserId] = nil
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, purchased)
		if purchased and gamepassId == ClanConfig.CreateGamepassId then
			passOwners[player.UserId] = true
			ClanUpdated:FireClient(player)
		end
	end)

	task.spawn(function()
		local success, subscribeError = pcall(function()
			MessagingService:SubscribeAsync(MESSAGE_TOPIC, function(message)
				local data = message and message.Data

				if type(data) == "table" and data.JobId ~= game.JobId and type(data.ClanId) == "string" then
					clanCache[data.ClanId] = nil
					onClanChanged(data.ClanId, type(data.UserIds) == "table" and data.UserIds or {})
				end
			end)
		end)

		if not success then
			warn("[ClanService] Cross-server updates unavailable:", subscribeError)
		end
	end)

	print("[ClanService] Started")
end

return ClanService
