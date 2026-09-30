local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")
local TextService = game:GetService("TextService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")
local Remotes = USARF:WaitForChild("Remotes")

local USARFConfig = require(Config:WaitForChild("USARFConfig"))
local RadioConfig = USARFConfig.Radio

local RadioMessageRemote = Remotes:WaitForChild("RadioMessage")
local RadioSendRemote = Remotes:WaitForChild("RadioSend")
local GetRadioPayloadRemote = Remotes:WaitForChild("GetRadioPayload")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local RadioAccessService = require(Services:WaitForChild("RadioAccessService"))
local CovertState = require(Services:WaitForChild("CovertState"))

local RadioLogService = nil
pcall(function()
	RadioLogService = require(Services:WaitForChild("RadioLogService"))
end)

local AuditService = nil
pcall(function()
	AuditService = require(Services:WaitForChild("AuditService"))
end)

local RadioService = {}

local buffers = {}
local lastSendAt = {}
local lastMessageByPlayer = {}

for _, channel in ipairs(RadioConfig.Channels) do
	buffers[channel.key] = {}
end

local function cloneTable(tbl)
	local copy = {}

	for key, value in pairs(tbl or {}) do
		if type(value) == "table" then
			local sub = {}

			for subKey, subValue in pairs(value) do
				sub[subKey] = subValue
			end

			copy[key] = sub
		else
			copy[key] = value
		end
	end

	return copy
end

local function trimText(text)
	return tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function sanitizeText(text)
	text = trimText(text)
	text = text:gsub("%s+", " ")

	local maxLength = tonumber(RadioConfig.MaxMessageLength) or 180

	if #text > maxLength then
		text = string.sub(text, 1, maxLength)
	end

	return text
end

local function filterText(text, userId)
	local success, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, userId, Enum.TextFilterContext.PublicChat)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)

	if not success or typeof(result) ~= "string" then
		return nil
	end

	return result
end

local function normalizeDuplicateText(text)
	return string.lower(trimText(text):gsub("%s+", " "))
end

local function isModMode(player)
	return player
		and (player:GetAttribute("USARF_ModMode") == true or player:GetAttribute("USARF_RadioModMode") == true)
end

local function isModeratorOrHigher(player)
	if not player then
		return false
	end

	local value = tonumber(player:GetAttribute("USARF_CmdrAdminLevelValue")) or 0
	local level = tostring(player:GetAttribute("USARF_CmdrAdminLevel") or "")

	return value >= 3 or level == "Moderator" or level == "Administrator" or level == "Developer" or level == "Owner"
end

local function getChannelByKey(channelKey)
	for _, channel in ipairs(RadioConfig.Channels) do
		if channel.key == channelKey then
			return channel
		end
	end

	return nil
end

local function getChannelName(channelKey)
	local channel = getChannelByKey(channelKey)

	if channel then
		return channel.name or channel.key
	end

	return tostring(channelKey or "Unknown")
end

local function getTeamKey(player)
	if not player then
		return nil
	end

	local covertHomeKey = CovertState.GetHomeTeamKey(player)
	if covertHomeKey then
		return covertHomeKey
	end

	local attrTeamKey = player:GetAttribute("USARF_TeamKey")
	if attrTeamKey and USARFConfig.Teams[attrTeamKey] then
		return attrTeamKey
	end

	if player.Team then
		return USARFConfig.GetTeamKeyFromName(player.Team.Name)
	end

	return nil
end

local function getTeamData(player)
	local teamKey = getTeamKey(player)

	if not teamKey then
		return nil, nil
	end

	return teamKey, USARFConfig.Teams[teamKey]
end

local function canReadChannel(player, channelKey)
	if isModMode(player) then
		return true
	end

	if channelKey == "moderation" and isModeratorOrHigher(player) then
		return true
	end

	return RadioAccessService.CanReadChannel(player, channelKey)
end

local function canSendChannel(player, channelKey)
	local channel = getChannelByKey(channelKey)

	if not channel then
		return false
	end

	if channel.readOnly then
		return false
	end

	if isModMode(player) then
		return true
	end

	if channelKey == "moderation" and isModeratorOrHigher(player) then
		return true
	end

	return RadioAccessService.CanSendChannel(player, channelKey)
end

local function canSeeRedacted(player)
	return isModMode(player) or RadioAccessService.CanSeeRedacted(player)
end

local function getVisibleChannels(player)
	if isModMode(player) then
		local channels = {}

		for _, channel in ipairs(RadioConfig.Channels) do
			table.insert(channels, {
				key = channel.key,
				name = channel.name,
				readOnly = channel.readOnly == true,
			})
		end

		return channels
	end

	local visibleChannels = RadioAccessService.GetVisibleChannels(player)
	local hasModeration = false

	for _, channel in ipairs(visibleChannels) do
		if channel.key == "moderation" then
			hasModeration = true
			break
		end
	end

	if isModeratorOrHigher(player) and not hasModeration then
		local moderationChannel = getChannelByKey("moderation")

		table.insert(visibleChannels, {
			key = "moderation",
			name = moderationChannel and moderationChannel.name or "MODERATION",
			readOnly = false,
		})
	end

	return visibleChannels
end

local function getTeamInfo(player)
	local teamKey, teamData = getTeamData(player)

	local teamName = "System"
	local teamColor = Color3.fromRGB(170, 170, 170)

	local team = player and player.Team

	if CovertState.IsCovert(player) and teamData then
		team = Teams:FindFirstChild(teamData.teamName) or team
	end

	if team then
		teamName = team.Name
		teamColor = team.TeamColor.Color
	end

	if teamData then
		teamName = teamData.teamName or teamData.displayName or teamName
	end

	local info = teamKey and RadioConfig.TeamAbbreviations[teamKey]

	if not info then
		info = {
			abv = teamKey or "SYS",
			redacted = false,
		}
	end

	return teamName, teamColor, teamKey, info
end

local function canPassCooldown(sender, channelKey, text)
	if not sender then
		return true
	end

	if isModMode(sender) then
		return true
	end

	local nowClock = os.clock()
	local userId = sender.UserId
	local cooldown = tonumber(RadioConfig.SendCooldownSeconds) or 1.25
	local duplicateCooldown = tonumber(RadioConfig.DuplicateCooldownSeconds) or 6

	lastSendAt[userId] = lastSendAt[userId] or {}
	lastMessageByPlayer[userId] = lastMessageByPlayer[userId] or {}

	local lastTime = lastSendAt[userId][channelKey]

	if lastTime and nowClock - lastTime < cooldown then
		return false, "Radio cooldown"
	end

	local duplicateText = normalizeDuplicateText(text)
	local lastMessage = lastMessageByPlayer[userId][channelKey]

	if lastMessage and lastMessage.Text == duplicateText and nowClock - lastMessage.At < duplicateCooldown then
		return false, "Duplicate radio message"
	end

	lastSendAt[userId][channelKey] = nowClock
	lastMessageByPlayer[userId][channelKey] = {
		Text = duplicateText,
		At = nowClock,
	}

	return true
end

local function formatPacket(channelKey, sender, text, isSystem)
	local teamName, teamColor, teamKey, info = getTeamInfo(sender)

	return {
		id = "radio_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
		channel = channelKey,
		when = os.time(),
		isSystem = isSystem == true,
		text = tostring(text or ""),

		fromUserId = sender and sender.UserId or 0,
		fromName = sender and sender.Name or "SYSTEM",
		fromDisplayName = sender and sender.DisplayName or "SYSTEM",

		fromTeam = teamName,
		fromTeamKey = teamKey,

		teamAbv = if isSystem then "SYS" else info.abv,
		teamColor = {
			teamColor.R,
			teamColor.G,
			teamColor.B,
		},

		redacted = if isSystem then false else info.redacted == true,
	}
end

local function pushBuffer(channelKey, packet)
	local buffer = buffers[channelKey]

	if not buffer then
		buffers[channelKey] = {}
		buffer = buffers[channelKey]
	end

	table.insert(buffer, packet)

	while #buffer > (tonumber(RadioConfig.MaxMessagesPerChannel) or 75) do
		table.remove(buffer, 1)
	end
end

local function sendPacketToEligiblePlayers(packet)
	for _, player in ipairs(Players:GetPlayers()) do
		if canReadChannel(player, packet.channel) then
			RadioMessageRemote:FireClient(player, packet)
		end
	end
end

local function logRadioMessage(packet, sender)
	if not RadioLogService then
		return
	end

	if not sender then
		return
	end

	if packet.channel == "alerts" then
		return
	end

	pcall(function()
		RadioLogService.Log(sender, {
			channel = packet.channel,
			channelName = getChannelName(packet.channel),
			prefix = packet.teamAbv,
			message = packet.text,
			transmissionName = packet.fromName,
		})
	end)
end

local function auditRadioMessage(packet, sender)
	if not AuditService then
		return
	end

	pcall(function()
		AuditService.Log({
			category = "Radio",
			action = packet.isSystem and "SystemMessage" or "Message",
			actor = sender,
			message = "[" .. tostring(packet.channel) .. "] " .. tostring(packet.text),
			severity = packet.isSystem and "Info" or "Normal",
			metadata = {
				channel = packet.channel,
				text = packet.text,
				fromUserId = packet.fromUserId,
				fromName = packet.fromName,
				fromTeam = packet.fromTeam,
				fromTeamKey = packet.fromTeamKey,
				redacted = packet.redacted,
				isSystem = packet.isSystem,
			},
		})
	end)
end

function RadioService.Send(channelKey, sender, text)
	channelKey = tostring(channelKey or "")
	text = sanitizeText(text)

	if text == "" then
		return false, "Empty message"
	end

	if not getChannelByKey(channelKey) then
		return false, "Invalid radio channel"
	end

	if not canSendChannel(sender, channelKey) then
		return false, "No radio access"
	end

	local cooldownOk, cooldownReason = canPassCooldown(sender, channelKey, text)

	if not cooldownOk then
		return false, cooldownReason
	end

	if typeof(sender) == "Instance" and sender:IsA("Player") then
		local filtered = filterText(text, sender.UserId)

		if not filtered then
			return false, "Filter unavailable"
		end

		text = filtered
	end

	local packet = formatPacket(channelKey, sender, text, false)

	pushBuffer(channelKey, packet)
	logRadioMessage(packet, sender)
	sendPacketToEligiblePlayers(packet)
	auditRadioMessage(packet, sender)

	return true, packet
end

function RadioService.System(channelKey, text, priority)
	channelKey = tostring(channelKey or "")
	text = sanitizeText(text)

	if text == "" then
		return false, "Empty system message"
	end

	if not getChannelByKey(channelKey) then
		return false, "Invalid radio channel"
	end

	local packet = formatPacket(channelKey, nil, text, true)
	packet.priority = tonumber(priority) or 3

	pushBuffer(channelKey, packet)
	sendPacketToEligiblePlayers(packet)
	auditRadioMessage(packet, nil)

	return true, packet
end

function RadioService.Alert(text, priority)
	return RadioService.System("alerts", text, priority or 5)
end

function RadioService.SystemAll(text, priority)
	local sent = 0

	for _, channel in ipairs(RadioConfig.Channels) do
		if channel.readOnly ~= true or channel.key == "alerts" then
			local success = RadioService.System(channel.key, text, priority)

			if success then
				sent += 1
			end
		end
	end

	return true, sent
end

function RadioService.GetPayload(player)
	local visibleChannels = getVisibleChannels(player)

	local payload = {
		channels = visibleChannels,
		messages = {},
		canSeeRedacted = canSeeRedacted(player),
	}

	for _, channel in ipairs(visibleChannels) do
		local source = buffers[channel.key] or {}
		payload.messages[channel.key] = {}

		for index, packet in ipairs(source) do
			payload.messages[channel.key][index] = cloneTable(packet)
		end
	end

	return payload
end

local function resendPayloadMessages(player)
	if not player or not player.Parent then
		return
	end

	local payload = RadioService.GetPayload(player)

	for _, channel in ipairs(payload.channels) do
		for _, packet in ipairs(payload.messages[channel.key] or {}) do
			RadioMessageRemote:FireClient(player, packet)
		end
	end
end

RadioSendRemote.OnServerEvent:Connect(function(player, channelKey, text)
	if typeof(channelKey) ~= "string" or typeof(text) ~= "string" then
		return
	end

	local success, reason = RadioService.Send(channelKey, player, text)

	if not success and reason ~= "Radio cooldown" and reason ~= "Duplicate radio message" then
		warn("[RadioService] Send denied:", player.Name, channelKey, reason)
	end
end)

GetRadioPayloadRemote.OnServerInvoke = function(player)
	return RadioService.GetPayload(player)
end

Players.PlayerAdded:Connect(function(player)
	player:GetPropertyChangedSignal("Team"):Connect(function()
		task.wait(0.2)
		resendPayloadMessages(player)
	end)

	player:GetAttributeChangedSignal("USARF_TeamKey"):Connect(function()
		task.wait(0.2)
		resendPayloadMessages(player)
	end)

	player:GetAttributeChangedSignal("USARF_ModMode"):Connect(function()
		task.wait(0.2)
		resendPayloadMessages(player)
	end)

	player:GetAttributeChangedSignal("USARF_RadioModMode"):Connect(function()
		task.wait(0.2)
		resendPayloadMessages(player)
	end)

	player:GetAttributeChangedSignal("USARF_CmdrAdminLevel"):Connect(function()
		task.wait(0.2)
		resendPayloadMessages(player)
	end)

	player:GetAttributeChangedSignal("USARF_CmdrAdminLevelValue"):Connect(function()
		task.wait(0.2)
		resendPayloadMessages(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	lastSendAt[player.UserId] = nil
	lastMessageByPlayer[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.defer(function()
		resendPayloadMessages(player)
	end)
end

print("USARF RadioService initialized")

return RadioService
