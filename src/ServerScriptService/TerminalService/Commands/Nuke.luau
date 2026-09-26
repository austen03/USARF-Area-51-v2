local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Shared = USARF:WaitForChild("Shared")
local FacilityState = Shared:WaitForChild("FacilityState")

local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end

	return folder
end

local function getOrCreateValue(parent, className, name, defaultValue)
	local value = parent:FindFirstChild(name)

	if not value then
		value = Instance.new(className)
		value.Name = name
		value.Parent = parent
	end

	if defaultValue ~= nil then
		value.Value = defaultValue
	end

	return value
end

local USARFState = getOrCreateFolder(USARF, "State")
local StrategicWeapons = getOrCreateFolder(FacilityState, "StrategicWeapons")

local EnabledValue = getOrCreateValue(StrategicWeapons, "BoolValue", "Enabled", false)
local AuthorizedByValue = getOrCreateValue(StrategicWeapons, "StringValue", "AuthorizedBy", "")
local AuthorizedUserIdValue = getOrCreateValue(StrategicWeapons, "IntValue", "AuthorizedUserId", 0)
local AuthorizedAtValue = getOrCreateValue(StrategicWeapons, "IntValue", "AuthorizedAt", 0)
local AuthorizationExpiresValue = getOrCreateValue(StrategicWeapons, "IntValue", "AuthorizationExpires", 0)

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityStatusService = nil
pcall(function()
	FacilityStatusService = require(Services:WaitForChild("FacilityStatusService"))
end)

local FacilityAlertService = nil
pcall(function()
	FacilityAlertService = require(Services:WaitForChild("FacilityAlertService"))
end)

local AUTH_DURATION_SECONDS = 15 * 60

local RESERVED_TERMINAL_COMMANDS = {
	help = true,
	status = true,
	clear = true,
	clearlockdown = true,
	lockdown = true,
	alert = true,
	announce = true,
	breach = true,
	event = true,
	playannouncement = true,
	stopannouncements = true,
	nuke = true,
	exit = true,
}

local function normalize(value)
	return string.upper(tostring(value or "")):gsub("^%s+", ""):gsub("%s+$", "")
end

local function lowerClean(value)
	return string.lower(tostring(value or "")):gsub("^%s+", ""):gsub("%s+$", "")
end

local function getCurrentCode()
	local value = USARFState:FindFirstChild("NuclearActivationCode")

	if not value then
		return ""
	end

	if value:IsA("StringValue") or value:IsA("IntValue") or value:IsA("NumberValue") then
		return normalize(value.Value)
	end

	return ""
end

local function isTrue(value)
	value = lowerClean(value)

	return value == "true"
		or value == "yes"
		or value == "y"
		or value == "1"
end

local function isFalse(value)
	value = lowerClean(value)

	return value == "false"
		or value == "no"
		or value == "n"
		or value == "0"
end

local function abort(context, reason)
	context.ClearSession()

	return {
		Type = "Warning",
		Message = reason or "Strategic weapons authorization cancelled.",
	}
end

local function buildSessionModeMessage()
	return table.concat({
		"You are in Nuclear Command mode.",
		"Type CANCEL to exit this authorization session.",
		"",
		"Current prompt remains active.",
	}, "\n")
end

local function buildCodePrompt(messageType, message)
	return {
		Type = messageType or "Warning",
		Message = table.concat({
			message or "Authentication required.",
			"",
			"Authentication Code >",
			"",
			"Type CANCEL to exit Nuclear Command mode.",
		}, "\n"),
	}
end

local function buildTrueFalsePrompt(title)
	return table.concat({
		title,
		"TRUE / FALSE >",
		"",
		"Type CANCEL to exit Nuclear Command mode.",
	}, "\n")
end

local function enableNetwork(player)
	local now = os.time()

	EnabledValue.Value = true
	AuthorizedByValue.Value = player.Name
	AuthorizedUserIdValue.Value = player.UserId
	AuthorizedAtValue.Value = now
	AuthorizationExpiresValue.Value = now + AUTH_DURATION_SECONDS

	if FacilityStatusService and typeof(FacilityStatusService.SetLastEvent) == "function" then
		FacilityStatusService.SetLastEvent("Strategic Weapons Network enabled by " .. player.Name)
	end

	if FacilityAlertService and typeof(FacilityAlertService.SendAlert) == "function" then
		FacilityAlertService.SendAlert(
			"Emergency",
			"Strategic Weapons Network",
			"Missile stations are now accepting launch authorization commands.",
			player.Name
		)
	end
end

local NukeCommand = {
	Name = "nuke",
	Aliases = { "nuclear", "missile", "strategic" },
	Description = "Enters Strategic Weapons Command authorization mode.",
	Usage = "nuke",
	Category = "Nuclear Command",
	MinRank = 17,
	PermissionLevel = "POTUS",
	Examples = {
		"nuke",
	},
}

function NukeCommand.Run(context)
	context.SetSession({
		Command = NukeCommand,
		Step = "Code",
		StartedAt = os.time(),
		Attempts = 0,
	})

	return {
		Type = "Warning",
		Message = table.concat({
			"=================================================",
			"USARF Strategic Weapons Command",
			"Missile Control Network",
			"Status",
			EnabledValue.Value and "ONLINE" or "OFFLINE",
			"=================================================",
			"",
			"Authentication Code >",
			"",
			"Type CANCEL to exit Nuclear Command mode.",
		}, "\n"),
	}
end

function NukeCommand.HandleSession(context, session, rawText)
	local input = tostring(rawText or "")
	local lowerInput = lowerClean(input)

	if lowerInput == "cancel" or lowerInput == "exit" then
		return abort(context, "Strategic weapons authorization cancelled.")
	end

	if RESERVED_TERMINAL_COMMANDS[lowerInput] then
		return {
			Type = "Warning",
			Message = buildSessionModeMessage(),
		}
	end

	if session.Step == "Code" then
		session.Attempts += 1

		local currentCode = getCurrentCode()

		if currentCode == "" then
			return buildCodePrompt(
				"Error",
				"Nuclear activation code is unavailable. Try again after the missile station finishes initializing."
			)
		end

		if normalize(input) ~= currentCode then
			if session.Attempts >= 3 then
				context.ClearSession()

				return {
					Type = "Error",
					Message = "Authentication failed. Maximum attempts exceeded.",
				}
			end

			return buildCodePrompt("Error", "Authentication rejected.")
		end

		session.Step = "EnableNetwork"

		return {
			Type = "Success",
			Message = table.concat({
				"Authentication Accepted",
				"",
				buildTrueFalsePrompt("Enable Missile Control Network?"),
			}, "\n"),
		}
	end

	if session.Step == "EnableNetwork" then
		if isFalse(input) then
			return abort(context)
		end

		if not isTrue(input) then
			return {
				Type = "Error",
				Message = buildTrueFalsePrompt("Invalid response. Enable Missile Control Network?"),
			}
		end

		session.Step = "LaunchKey"

		return {
			Type = "Warning",
			Message = buildTrueFalsePrompt("Verify Launch Key"),
		}
	end

	if session.Step == "LaunchKey" then
		if isFalse(input) then
			return abort(context)
		end

		if not isTrue(input) then
			return {
				Type = "Error",
				Message = buildTrueFalsePrompt("Invalid response. Verify Launch Key"),
			}
		end

		session.Step = "Target"

		return {
			Type = "Warning",
			Message = buildTrueFalsePrompt("Confirm Target Coordinates"),
		}
	end

	if session.Step == "Target" then
		if isFalse(input) then
			return abort(context)
		end

		if not isTrue(input) then
			return {
				Type = "Error",
				Message = buildTrueFalsePrompt("Invalid response. Confirm Target Coordinates"),
			}
		end

		session.Step = "Confirm"

		return {
			Type = "Warning",
			Message = table.concat({
				"Target coordinates confirmed.",
				"",
				"FINAL AUTHORIZATION",
				"Type CONFIRM",
				">",
				"",
				"Type CANCEL to exit Nuclear Command mode.",
			}, "\n"),
		}
	end

	if session.Step == "Confirm" then
		if normalize(input) ~= "CONFIRM" then
			return {
				Type = "Error",
				Message = table.concat({
					"Final authorization rejected.",
					"Type CONFIRM to enable the Strategic Missile Network.",
					"Type CANCEL to exit Nuclear Command mode.",
				}, "\n"),
			}
		end

		enableNetwork(context.Player)
		context.ClearSession()

		return {
			Type = "Success",
			Message = table.concat({
				"Strategic Missile Network Enabled.",
				"Missile Stations are now accepting launch commands.",
				"",
				"Authorization expires in " .. tostring(math.floor(AUTH_DURATION_SECONDS / 60)) .. " minutes.",
			}, "\n"),
		}
	end

	context.ClearSession()

	return {
		Type = "Error",
		Message = "Invalid nuclear authorization session. Session cleared.",
	}
end

return NukeCommand