local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local TerminalEvent = Remotes:FindFirstChild("TerminalEvent")
if not TerminalEvent then
	TerminalEvent = Instance.new("RemoteEvent")
	TerminalEvent.Name = "TerminalEvent"
	TerminalEvent.Parent = Remotes
end

local GetTerminalCommands = Remotes:FindFirstChild("GetTerminalCommands")
if not GetTerminalCommands then
	GetTerminalCommands = Instance.new("RemoteFunction")
	GetTerminalCommands.Name = "GetTerminalCommands"
	GetTerminalCommands.Parent = Remotes
end

local Registry = require(script.Parent:WaitForChild("TerminalRegistry"))
local Logger = require(script.Parent:WaitForChild("TerminalLogger"))

local TerminalService = {}

local activeSessions = {}

local function splitCommand(text)
	local parts = {}

	for word in tostring(text or ""):gmatch("%S+") do
		table.insert(parts, word)
	end

	return parts
end

local function send(player, payload)
	TerminalEvent:FireClient(player, payload)
end

local function clearSession(player)
	activeSessions[player.UserId] = nil
end

local function setSession(player, session)
	activeSessions[player.UserId] = session
end

local function buildContext(player, rawText)
	return {
		Player = player,
		RawText = rawText,
		Registry = Registry,
		Logger = Logger,

		SetSession = function(session)
			setSession(player, session)
		end,

		ClearSession = function()
			clearSession(player)
		end,
	}
end

local function getSuggestions(input, player)
	input = string.lower(tostring(input or ""))

	local results = {}

	for _, command in ipairs(Registry.GetAll()) do
		local canRun = Registry.CanRun(player, command)

		if canRun then
			if input == "" or string.sub(command.Name, 1, #input) == input then
				table.insert(results, command.Name)
			end

			for _, alias in ipairs(command.Aliases or {}) do
				if input == "" or string.sub(string.lower(alias), 1, #input) == input then
					table.insert(results, alias)
				end
			end
		end
	end

	table.sort(results)
	return results
end

function TerminalService.Run(player, rawText)
	rawText = tostring(rawText or "")

	local accessAllowed, accessReason = Registry.CanAccessTerminal(player)

	if not accessAllowed then
		send(player, {
			Type = "Error",
			Message = accessReason or "Terminal access denied.",
		})

		Logger.LogTerminal(player, rawText, "Denied: " .. tostring(accessReason or "Terminal access denied"))
		return
	end

	local session = activeSessions[player.UserId]

	if session and session.Command and typeof(session.Command.HandleSession) == "function" then
		local context = buildContext(player, rawText)

		local success, result = pcall(function()
			return session.Command.HandleSession(context, session, rawText)
		end)

		if not success then
			clearSession(player)

			send(player, {
				Type = "Error",
				Message = "Session error: " .. tostring(result),
			})

			Logger.LogTerminal(player, rawText, "Session error: " .. tostring(result))
			return
		end

		result = type(result) == "table" and result or {
			Type = "Info",
			Message = tostring(result or ""),
		}

		send(player, result)
		Logger.LogTerminal(player, "[SESSION] " .. rawText, result.Message or "Session updated")
		return
	end

	local parts = splitCommand(rawText)
	local commandName = string.lower(parts[1] or "")

	if commandName == "" then
		send(player, {
			Type = "Error",
			Message = "No command entered.",
		})

		return
	end

	local command = Registry.Get(commandName)

	if not command then
		send(player, {
			Type = "Error",
			Message = "Unknown command.",
			Suggestions = getSuggestions(commandName, player),
		})

		Logger.LogTerminal(player, rawText, "Failed: Unknown command")
		return
	end

	local allowed, reason = Registry.CanRun(player, command)

	if not allowed then
		send(player, {
			Type = "Error",
			Message = reason or "Access denied.",
		})

		Logger.LogTerminal(player, rawText, "Denied: " .. tostring(reason or "Access denied"))
		return
	end

	local context = buildContext(player, rawText)

	local success, result = pcall(function()
		return command.Run(context, parts)
	end)

	if not success then
		send(player, {
			Type = "Error",
			Message = "Command error: " .. tostring(result),
		})

		Logger.LogTerminal(player, rawText, "Error: " .. tostring(result))
		return
	end

	result = type(result) == "table" and result or {
		Type = "Success",
		Message = tostring(result or "Command completed."),
	}

	send(player, result)
	Logger.LogTerminal(player, rawText, result.Message or "Completed")
end

function TerminalService.Start()
	Registry.Load(script.Parent:WaitForChild("Commands"))

	TerminalEvent.OnServerEvent:Connect(function(player, rawText)
		TerminalService.Run(player, rawText)
	end)

	GetTerminalCommands.OnServerInvoke = function(player)
		local accessAllowed, accessReason = Registry.CanAccessTerminal(player)

		if not accessAllowed then
			return {
				AccessDenied = true,
				Reason = accessReason or "Terminal access denied.",
				Commands = {},
			}
		end

		return {
			AccessDenied = false,
			Commands = Registry.GetClientList(player),
		}
	end

	print("[TerminalService] Started")
end

TerminalService.Start()