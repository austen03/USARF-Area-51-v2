local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local PermissionService = require(Services:WaitForChild("PermissionService"))

local USARF = ReplicatedStorage:WaitForChild("USARF")
local USARFConfig = require(USARF.Config:WaitForChild("USARFConfig"))

local RadioAccessService = {}

local function cloneTable(tbl)
	local copy = {}

	for key, value in pairs(tbl) do
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

local function getChannelByKey(channelKey)
	local radioConfig = USARFConfig.Radio or {}

	for _, channel in ipairs(radioConfig.Channels or {}) do
		if channel.key == channelKey then
			return channel
		end
	end

	return nil
end

local function hasTemporaryRadioAccess(player)
	return player and player:GetAttribute("USARF_TemporaryRadioAccess") == true
end

function RadioAccessService.IsModMode(player)
	return player
		and (
			player:GetAttribute("USARF_ModMode") == true
			or player:GetAttribute("USARF_RadioModMode") == true
		)
end

function RadioAccessService.GetMainRank(player)
	return PermissionService.GetMainRank(player)
end

function RadioAccessService.GetModRank(player)
	return PermissionService.GetModRank(player)
end

function RadioAccessService.HasRadio(player)
	if hasTemporaryRadioAccess(player) then
		return true
	end

	return PermissionService.HasRadio(player)
end

function RadioAccessService.CanReadChannel(player, channelKey)
	if hasTemporaryRadioAccess(player) and channelKey == "general" then
		return true
	end

	return PermissionService.CanReadRadioChannel(player, channelKey)
end

function RadioAccessService.CanSendChannel(player, channelKey)
	if hasTemporaryRadioAccess(player) and channelKey == "general" then
		return false
	end

	return PermissionService.CanSendRadioChannel(player, channelKey)
end

function RadioAccessService.GetVisibleChannels(player)
	local channels = PermissionService.GetVisibleRadioChannels(player) or {}

	if hasTemporaryRadioAccess(player) then
		local hasGeneral = false

		for _, channel in ipairs(channels) do
			if channel.key == "general" then
				hasGeneral = true
				break
			end
		end

		if not hasGeneral then
			local generalChannel = getChannelByKey("general")

			if generalChannel then
				local cloned = cloneTable(generalChannel)
				cloned.readOnly = true
				cloned.temporaryAccess = true
				table.insert(channels, cloned)
			end
		end
	end

	return channels
end

function RadioAccessService.CanSeeRedacted(viewer)
	return PermissionService.CanSeeRedactedRadio(viewer)
end

return RadioAccessService