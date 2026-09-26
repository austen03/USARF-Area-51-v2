local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")

local ServerTeleportService = {}

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")
local Remotes = USARF:WaitForChild("Remotes")

local MainMenuConfig = require(
	Config:WaitForChild("ServerConfig")
)

local Services = ServerScriptService
	:WaitForChild("USARF")
	:WaitForChild("Services")

local EventServerService = require(
	Services:WaitForChild("EventServerService")
)

local RequestServerJoin = Remotes:WaitForChild(
	"RequestServerJoin"
)

local started = false

local function clean(value)
	return tostring(value or "")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
end

local function normalize(value)
	return string.lower(clean(value))
		:gsub("%s+", "")
		:gsub("_", "")
		:gsub("-", "")
end

local MAIN_PUBLIC_ALIASES = {
	mainpublic = true,
	mainpublicserver = true,
	mainarea51operations = true,
	currentserver = true,
	publicserver = true,
}

local EVENT_SERVER_ALIASES = {
	eventserver = true,
	eventoperations = true,
	event = true,
}

local function hasGroupRank(player, groupId, minRank)
	local rank = 0

	pcall(function()
		rank = player:GetRankInGroup(groupId)
	end)

	return rank >= (tonumber(minRank) or 1)
end

local function canUseServer(player, server)
	if not server then
		return false, "Server does not exist."
	end

	if server.Locked == true then
		return false, server.Status or "This server is locked."
	end

	if server.Reserved ~= true then
		return true
	end

	local admin = MainMenuConfig.ReservedServerAdmin or {}

	if admin.MainGroupId
		and hasGroupRank(
			player,
			admin.MainGroupId,
			admin.MinRank or 19
		)
	then
		return true
	end

	if server.GroupId
		and hasGroupRank(
			player,
			server.GroupId,
			server.MinRank or 1
		)
	then
		return true
	end

	if typeof(server.Groups) == "table" then
		for _, rule in ipairs(server.Groups) do
			if rule.GroupId
				and hasGroupRank(
					player,
					rule.GroupId,
					rule.MinRank or 1
				)
			then
				return true
			end
		end
	end

	return false, "You do not have access to this reserved server."
end

local function findConfiguredServer(serverKey)
	local wanted = normalize(serverKey)

	for _, section in ipairs(
		MainMenuConfig.ServerSections or {}
		) do
		for _, server in ipairs(section.Servers or {}) do
			local key = normalize(server.Key)
			local name = normalize(server.Name)

			if wanted == key or wanted == name then
				return server
			end
		end
	end

	return nil
end

local function joinMainPublicServer(player)
	local options = Instance.new("TeleportOptions")

	options:SetTeleportData({
		ServerKey = "main_public",
		ServerName = "Main Area 51 Operations",
		Reserved = false,
		EventServer = false,
	})

	local success, result = pcall(function()
		TeleportService:TeleportAsync(
			game.PlaceId,
			{ player },
			options
		)
	end)

	if not success then
		return {
			Success = false,
			Message = "Unable to join the main public server: "
				.. tostring(result),
		}
	end

	return {
		Success = true,
		Message = "Joining the main public server...",
	}
end

local function joinEventServer(player)
	local active =
		EventServerService.GetActiveEventServerInternal()

	if not active or active.enabled ~= true then
		return {
			Success = false,
			Message = "The event server is currently locked.",
		}
	end

	if active.privateServerId == game.PrivateServerId
		and game.PrivateServerId ~= ""
	then
		return {
			Success = false,
			Message = "You are already in the active event server.",
		}
	end

	if type(active.accessCode) ~= "string"
		or active.accessCode == ""
	then
		return {
			Success = false,
			Message = "The event server access code is unavailable.",
		}
	end

	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = active.accessCode

	options:SetTeleportData({
		ServerKey = "event_server",
		ServerName = active.name or "Event Server",
		EventServer = true,
		Reserved = true,
	})

	local success, result = pcall(function()
		TeleportService:TeleportAsync(
			tonumber(active.placeId) or game.PlaceId,
			{ player },
			options
		)
	end)

	if not success then
		return {
			Success = false,
			Message = "Unable to join the event server: "
				.. tostring(result),
		}
	end

	return {
		Success = true,
		Message = "Joining event server...",
	}
end

local function joinConfiguredReservedServer(player, server)
	local allowed, reason = canUseServer(player, server)

	if not allowed then
		return {
			Success = false,
			Message = reason or "Access denied.",
		}
	end

	local placeId = tonumber(server.PlaceId) or game.PlaceId

	if server.Reserved == true then
		local reserveSuccess, reservedCode =
			pcall(function()
				return TeleportService:ReserveServerAsync(
					placeId
				)
			end)

		if not reserveSuccess then
			return {
				Success = false,
				Message = "Unable to reserve server: "
					.. tostring(reservedCode),
			}
		end

		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = reservedCode

		options:SetTeleportData({
			ServerKey = server.Key or server.Name,
			ServerName = server.Name,
			Reserved = true,
			EventServer = false,
		})

		local teleportSuccess, teleportError =
			pcall(function()
				TeleportService:TeleportAsync(
					placeId,
					{ player },
					options
				)
			end)

		if not teleportSuccess then
			return {
				Success = false,
				Message = "Unable to join reserved server: "
					.. tostring(teleportError),
			}
		end

		return {
			Success = true,
			Message = "Joining reserved server...",
		}
	end

	return joinMainPublicServer(player)
end

function ServerTeleportService.JoinServer(player, serverKey)
	local rawKey = clean(serverKey)
	local normalizedKey = normalize(rawKey)

	print(
		"[ServerTeleportService] Join request:",
		player.Name,
		rawKey,
		normalizedKey
	)

	if MAIN_PUBLIC_ALIASES[normalizedKey] then
		return joinMainPublicServer(player)
	end

	if EVENT_SERVER_ALIASES[normalizedKey] then
		return joinEventServer(player)
	end

	local server = findConfiguredServer(rawKey)

	if server then
		return joinConfiguredReservedServer(player, server)
	end

	return {
		Success = false,
		Message = "Server does not exist: "
			.. tostring(rawKey),
	}
end

function ServerTeleportService.Start()
	if started then
		return
	end

	started = true

	RequestServerJoin.OnServerInvoke = function(
		player,
		serverKey
	)
		return ServerTeleportService.JoinServer(
			player,
			serverKey
		)
	end

	print("[ServerTeleportService] Started and owns RequestServerJoin")
end

return ServerTeleportService