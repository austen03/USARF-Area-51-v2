-- Covert mode: a certified player respawns as a Test Subject under a fake name,
-- while keeping their home team's radio (and, when they switch it on, its door
-- access). The state lives in CovertState; this service moves players in and
-- out, validates their choices and serves the covert panel and chat commands.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local ConfigFolder = USARF:WaitForChild("Config")
local Remotes = USARF:WaitForChild("Remotes")

local CovertConfig = require(ConfigFolder:WaitForChild("CovertConfig"))
local USARFConfig = require(ConfigFolder:WaitForChild("USARFConfig"))
local ClanConfig = require(ConfigFolder:WaitForChild("ClanConfig"))

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local CovertState = require(Services:WaitForChild("CovertState"))
local CertificationService = require(Services:WaitForChild("CertificationService"))
local SpawnService = require(Services:WaitForChild("SpawnService"))
local TeamAccessService = require(Services:WaitForChild("TeamAccessService"))
local NameTagService = require(Services:WaitForChild("NameTagService"))
local ClanService = require(Services:WaitForChild("ClanService"))
local RadioService = require(Services:WaitForChild("RadioService"))
local RadioAccessService = require(Services:WaitForChild("RadioAccessService"))
local PermissionService = require(Services:WaitForChild("PermissionService"))
local NotificationService = require(Services:WaitForChild("NotificationService"))
local AuditService = require(Services:WaitForChild("AuditService"))

local AntiExploitService = nil
pcall(function()
	AntiExploitService = require(Services:WaitForChild("AntiExploitService"))
end)

local CovertService = {}

local ACTION_COOLDOWN_SECONDS = 0.5
local MAX_ORG_SEARCH_LENGTH = 30

local started = false

local busy: {[Player]: boolean} = {}
-- Set while covert moves a player between teams, so that move isn't mistaken
-- for the player leaving the Test Subject team.
local transitioning: {[Player]: boolean} = {}
local lastToggleAt: {[Player]: number} = {}
local lastActionAt: {[Player]: number} = {}

local function getOrCreateRemote(className: string, name: string): Instance
	local remote = Remotes:FindFirstChild(name)

	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = Remotes
	end

	return remote
end

local CovertRequest = getOrCreateRemote("RemoteFunction", "CovertRequest") :: RemoteFunction
local CovertUpdated = getOrCreateRemote("RemoteEvent", "CovertUpdated") :: RemoteEvent

local function isCertified(player: Player): boolean
	return CertificationService.Has(player, CovertConfig.Certification)
end

local function notify(player: Player, message: string, notificationType: string?)
	NotificationService.Notify(player, {
		Title = "Covert",
		Message = message,
		Type = notificationType or "Info",
		Duration = 5,
	})
end

local function log(player: Player, action: string, message: string, metadata: {[string]: any}?)
	AuditService.Log({
		category = "Covert",
		action = action,
		actor = player,
		target = player,
		message = message,
		severity = "Info",
		metadata = metadata or {},
	})
end

local function buildClientState(player: Player)
	local state = CovertState.Get(player)

	return {
		Certified = isCertified(player),
		Active = state ~= nil,
		Name = state and state.Name,
		SubjectNumber = state and state.SubjectNumber,
		Gold = state ~= nil and state.Gold == true,
		Clearance = state ~= nil and state.Clearance == true,
		Org = if state and state.Org then { Id = state.Org.Id, Tag = state.Org.Tag } else nil,
		HomeTeam = state and state.HomeTeamName,
	}
end

local function pushState(player: Player, openPanel: boolean?)
	if player.Parent == Players then
		CovertUpdated:FireClient(player, buildClientState(player), openPanel == true)
	end
end

--// Validation

local function trim(text: string): string
	return (string.gsub(string.gsub(text, "^%s+", ""), "%s+$", ""))
end

-- Returns the cleaned name, or nil and a reason. Yields (text filter).
local function validateName(player: Player, rawName: any): (string?, string?)
	if typeof(rawName) ~= "string" then
		return nil, "Enter a name."
	end

	local name = string.gsub(trim(rawName), "%s+", " ")
	local limits = CovertConfig.Name

	if #name < limits.MinLength or #name > limits.MaxLength then
		return nil, `Names must be {limits.MinLength}-{limits.MaxLength} characters.`
	end

	if not string.match(name, "^[%w_ ]+$") then
		return nil, "Names can only use letters, numbers, spaces and _."
	end

	local lowered = string.lower(name)

	for _, other in Players:GetPlayers() do
		if other ~= player then
			if string.lower(other.Name) == lowered or string.lower(other.DisplayName) == lowered then
				return nil, "That name belongs to a player in this server."
			end

			local otherState = CovertState.Get(other)

			if otherState and string.lower(otherState.Name) == lowered then
				return nil, "That name is already in use."
			end
		end
	end

	-- Names are shown to everyone, so they go through Roblox's text filter.
	local success, filtered = pcall(function()
		local result = TextService:FilterStringAsync(name, player.UserId, Enum.TextFilterContext.PublicChat)
		return result:GetNonChatStringForBroadcastAsync()
	end)

	if not success then
		return nil, "Couldn't check that name right now. Try again."
	end

	if filtered ~= name then
		return nil, "That name isn't allowed."
	end

	return name
end

-- A random TS-##### that no one in the server is showing (including the
-- player's own normal number, which would give them away).
local function randomSubjectNumber(): string
	local used = {}

	for _, other in Players:GetPlayers() do
		used[NameTagService.GetTestSubjectNumber(other)] = true
	end

	local candidate

	repeat
		candidate = string.format("TS-%05d", math.random(10000, 99999))
	until not used[candidate]

	return candidate
end

-- Returns the org for a clan id (nil when the id is empty), or false and a reason.
local function resolveOrg(orgId: any): (any, string?)
	if orgId == nil or orgId == "" then
		return nil
	end

	if typeof(orgId) ~= "string" then
		return false, "Invalid organization."
	end

	local summary = ClanService.GetClanSummary(orgId)

	if not summary then
		return false, "That organization no longer exists."
	end

	local logo = ClanConfig.GetLogo(summary.LogoId)
	local color = ClanConfig.GetColor(summary.ColorId)

	return {
		Id = summary.Id,
		Tag = summary.Tag,
		Logo = if logo then logo.Image else "",
		Color = if color then color.Color else Color3.new(1, 1, 1),
	}
end

--// Moving between teams

local function giveTeleportGrace(player: Player)
	if AntiExploitService and typeof(AntiExploitService.AuthorizeTeleport) == "function" then
		AntiExploitService.AuthorizeTeleport(player, 8, "Covert")
	end

	player:SetAttribute("USARF_TeleportGraceUntil", os.clock() + 8)
	player:SetAttribute("USARF_TeleportGraceReason", "Covert")
end

-- Respawns the player on a team, the same way the refresh command does.
local function respawnOnTeam(player: Player, teamKey: string): (boolean, string?)
	local teamData = USARFConfig.Teams[teamKey]

	if not teamData then
		return false, "Unknown team."
	end

	transitioning[player] = true
	giveTeleportGrace(player)

	player:SetAttribute("USARF_SuppressMenuOpen", true)
	player:SetAttribute("USARF_InMenu", false)
	player:SetAttribute("USARF_TeamKey", teamKey)
	player:SetAttribute("USARF_TeamName", teamData.teamName)
	player:SetAttribute("USARF_SpawnKey", teamData.spawnKey)

	player:LoadCharacter()

	local character = player.Character
	if character then
		character:WaitForChild("HumanoidRootPart", 10)
	end

	local success, message = SpawnService.SendPlayerToTeamSpawn(player, teamKey)

	transitioning[player] = nil

	task.delay(1.5, function()
		if player.Parent == Players then
			player:SetAttribute("USARF_InMenu", false)
			player:SetAttribute("USARF_SuppressMenuOpen", false)
		end
	end)

	return success, message
end

--// Actions

function CovertService.Enter(player: Player, request: {[string]: any}): (boolean, string?)
	if not isCertified(player) then
		return false, "You are not certified for covert operations."
	end

	if CovertState.IsCovert(player) then
		return false, "You are already covert."
	end

	local cooldown = CovertConfig.ToggleCooldownSeconds
	if lastToggleAt[player] and os.clock() - lastToggleAt[player] < cooldown then
		return false, "Wait a moment before going covert again."
	end

	local homeKey = player:GetAttribute("USARF_TeamKey")
	local homeData = homeKey and USARFConfig.Teams[homeKey]

	if not homeData or CovertConfig.BlockedHomeTeams[homeKey] then
		return false, "Join your department before going covert."
	end

	local name, nameError = validateName(player, request.Name)
	if not name then
		return false, nameError
	end

	local org, orgError = resolveOrg(request.OrgId)
	if org == false then
		return false, orgError
	end

	local access = TeamAccessService.CanPlayerUseTeam(player, CovertConfig.TeamKey)
	if not access.canAccess then
		return false, access.reason or "The Test Subject team is unavailable."
	end

	-- Set before the move so uniforms, loadouts and nametags see the covert player.
	CovertState.Set(player, {
		HomeTeamKey = homeKey,
		HomeTeamName = homeData.teamName,
		Name = name,
		SubjectNumber = randomSubjectNumber(),
		Gold = request.Gold == true,
		Clearance = false,
		Org = org :: CovertState.Org?,
	})

	local moved, moveError = respawnOnTeam(player, CovertConfig.TeamKey)

	if not moved then
		CovertState.Set(player, nil)
		respawnOnTeam(player, homeKey)
		return false, `Couldn't go covert: {tostring(moveError)}`
	end

	lastToggleAt[player] = os.clock()
	log(player, "Enter", `{player.Name} went covert as {name}.`, { homeTeam = homeKey, covertName = name })

	return true, `You are now covert as {name}.`
end

function CovertService.Exit(player: Player, reason: string?): (boolean, string?)
	local state = CovertState.Get(player)

	if not state then
		return false, "You are not covert."
	end

	CovertState.Set(player, nil)
	lastToggleAt[player] = os.clock()

	log(player, "Exit", `{player.Name} left covert ({reason or "requested"}).`, {
		homeTeam = state.HomeTeamKey,
		covertName = state.Name,
		reason = reason,
	})

	local moved, moveError = respawnOnTeam(player, state.HomeTeamKey)

	if not moved then
		return true, `Couldn't return you to {state.HomeTeamName}: {tostring(moveError)}. Pick a team from the menu.`
	end

	return true, `Returned to {state.HomeTeamName}.`
end

local function setName(player: Player, rawName: any): (boolean, string?)
	local name, nameError = validateName(player, rawName)

	if not name then
		return false, nameError
	end

	local oldName = CovertState.Get(player).Name

	CovertState.Update(player, function(state)
		state.Name = name
	end)

	log(player, "Rename", `{player.Name} changed covert name from {oldName} to {name}.`, { covertName = name })

	return true, `Name set to {name}.`
end

local function setOrg(player: Player, orgId: any): (boolean, string?)
	local org, orgError = resolveOrg(orgId)

	if org == false then
		return false, orgError
	end

	CovertState.Update(player, function(state)
		state.Org = org :: CovertState.Org?
	end)

	return true, if org then `Organization set to [{(org :: CovertState.Org).Tag}].` else "Organization cleared."
end

local function listOrgs(search: any)
	local query = if typeof(search) == "string" then string.sub(search, 1, MAX_ORG_SEARCH_LENGTH) else ""
	local orgs = {}

	for _, summary in ClanService.ListClans(query) do
		local logo = ClanConfig.GetLogo(summary.LogoId)
		local color = ClanConfig.GetColor(summary.ColorId)

		table.insert(orgs, {
			Id = summary.Id,
			Name = summary.Name,
			Tag = summary.Tag,
			Logo = if logo then logo.Image else "",
			Color = if color then color.Color else Color3.new(1, 1, 1),
		})
	end

	return orgs
end

local function dispatch(player: Player, action: string, payload: {[string]: any}): (boolean, string?)
	if action == "Enter" then
		return CovertService.Enter(player, payload)
	elseif action == "Exit" then
		return CovertService.Exit(player, "requested")
	elseif not CovertState.IsCovert(player) then
		return false, "Go covert first."
	elseif action == "SetName" then
		return setName(player, payload.Name)
	elseif action == "SetOrg" then
		return setOrg(player, payload.OrgId)
	elseif action == "SetGold" then
		CovertState.Update(player, function(state)
			state.Gold = payload.Enabled == true
		end)

		return true
	elseif action == "SetClearance" then
		local enabled = payload.Enabled == true

		CovertState.Update(player, function(state)
			state.Clearance = enabled
		end)

		log(player, "Clearance", `{player.Name} turned covert door clearance {if enabled then "on" else "off"}.`)
		return true, if enabled then "Door clearance on." else "Door clearance off."
	end

	return false, "Unknown action."
end

local function handleRequest(player: Player, action: any, payload: any)
	if typeof(action) ~= "string" then
		return { Success = false, Message = "Invalid request." }
	end

	payload = if typeof(payload) == "table" then payload else {}

	if action == "GetState" then
		return { Success = true, State = buildClientState(player) }
	end

	local now = os.clock()
	if lastActionAt[player] and now - lastActionAt[player] < ACTION_COOLDOWN_SECONDS then
		return { Success = false, Message = "Slow down." }
	end
	lastActionAt[player] = now

	if not isCertified(player) then
		return { Success = false, Message = "You are not certified for covert operations." }
	end

	if action == "ListOrgs" then
		return { Success = true, Orgs = listOrgs(payload.Search) }
	end

	if busy[player] then
		return { Success = false, Message = "Still working on your last request." }
	end

	busy[player] = true

	local ran, success, message = pcall(dispatch, player, action, payload)

	busy[player] = nil

	if not ran then
		warn("[CovertService] Request failed:", action, success)
		success, message = false, "Something went wrong. Try again."
	end

	return { Success = success == true, Message = message, State = buildClientState(player) }
end

--// Chat commands

-- The home team's own radio channel (e.g. INTELLIGENCE for the FBI), else the fallback.
local function chooseRadioChannel(player: Player): string?
	local teamKey = CovertState.GetHomeTeamKey(player) or PermissionService.GetTeamKey(player)

	for _, channel in USARFConfig.Radio.Channels do
		if not channel.readOnly
			and channel.teamKeys
			and table.find(channel.teamKeys, teamKey)
			and RadioAccessService.CanSendChannel(player, channel.key)
		then
			return channel.key
		end
	end

	local fallback = CovertConfig.RadioFallbackChannel

	if RadioAccessService.CanSendChannel(player, fallback) then
		return fallback
	end

	return nil
end

local function getCommandText(text: string): string
	return trim((string.gsub(text, "^%S+", "", 1)))
end

local function setupChatCommands()
	local folder = Instance.new("Folder")
	folder.Name = "USARFCovertCommands"
	folder.Parent = TextChatService

	-- /c <message>: sends to the radio instead of public chat.
	local radioCommand = Instance.new("TextChatCommand")
	radioCommand.Name = "CovertRadio"
	radioCommand.PrimaryAlias = CovertConfig.RadioCommand
	radioCommand.Parent = folder

	radioCommand.Triggered:Connect(function(textSource, text)
		local player = Players:GetPlayerByUserId(textSource.UserId)
		local message = getCommandText(text)

		if not player or message == "" then
			return
		end

		local channelKey = chooseRadioChannel(player)

		if not channelKey then
			notify(player, "You don't have radio access.", "Warning")
			return
		end

		local sent, reason = RadioService.Send(channelKey, player, message)

		if not sent then
			notify(player, `Radio: {tostring(reason)}`, "Warning")
		end
	end)

	-- /covert: opens the covert panel for certified players.
	local panelCommand = Instance.new("TextChatCommand")
	panelCommand.Name = "CovertPanel"
	panelCommand.PrimaryAlias = CovertConfig.PanelCommand
	panelCommand.Parent = folder

	panelCommand.Triggered:Connect(function(textSource)
		local player = Players:GetPlayerByUserId(textSource.UserId)

		if player and isCertified(player) then
			pushState(player, true)
		end
	end)
end

--// Lifecycle

local function watchPlayer(player: Player)
	-- Leaving the Test Subject team any other way (menu, team command) ends covert.
	player:GetAttributeChangedSignal("USARF_TeamKey"):Connect(function()
		if transitioning[player] or not CovertState.IsCovert(player) then
			return
		end

		if player:GetAttribute("USARF_TeamKey") ~= CovertConfig.TeamKey then
			local state = CovertState.Get(player)
			CovertState.Set(player, nil)

			log(player, "Exit", `{player.Name} left covert by changing team.`, {
				homeTeam = state and state.HomeTeamKey,
				covertName = state and state.Name,
			})
		end
	end)
end

function CovertService.Start()
	if started then
		return
	end

	started = true

	CovertRequest.OnServerInvoke = handleRequest

	CovertState.Changed:Connect(function(player)
		pcall(NameTagService.Refresh, player)
		pushState(player)
	end)

	-- Certifications removed in Discord take effect in game.
	CertificationService.Changed:Connect(function(player)
		if CovertState.IsCovert(player) and not isCertified(player) and not busy[player] then
			busy[player] = true
			pcall(CovertService.Exit, player, "certification removed")
			busy[player] = nil
			notify(player, "Your covert certification was removed.", "Warning")
		end

		pushState(player)
	end)

	Players.PlayerAdded:Connect(watchPlayer)

	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local state = CovertState.Get(player)

		if state then
			log(player, "Exit", `{player.Name} left the server while covert.`, { covertName = state.Name })
			CovertState.Set(player, nil)
		end

		busy[player] = nil
		transitioning[player] = nil
		lastToggleAt[player] = nil
		lastActionAt[player] = nil
	end)

	setupChatCommands()

	print("[CovertService] Started")
end

return CovertService
