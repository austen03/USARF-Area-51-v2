local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ModerationUtilityService = {}

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local UTILITY_REMOTE_NAME = "ModerationUtilityRemote"

local Started = false

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local SuspensionService = require(Services:WaitForChild("SuspensionService"))

local TeamAccessService = require(Services:WaitForChild("TeamAccessService"))

local NotificationService = nil

pcall(function()
	NotificationService = require(Services:WaitForChild("NotificationService"))
end)

local DiscordBotBridge = nil

pcall(function()
	local bridgeModule = Services:FindFirstChild("DiscordBotBridge")

	if bridgeModule then
		DiscordBotBridge = require(bridgeModule)
	end
end)

local AREA_TARGET_MAP = {
	["Civil Departments"] = "civil",
	["Combative Departments"] = "combative",
	["Intelligence Departments"] = "intelligence",
	["Protection Departments"] = "protection",
	["Facility Wide"] = "facility",
	["Entire Facility"] = "facility",
}

local function getOrCreate(parent, className, name)
	local object = parent:FindFirstChild(name)

	if not object then
		object = Instance.new(className)
		object.Name = name
		object.Parent = parent
	end

	return object
end

local RemoteFolder = getOrCreate(ReplicatedStorage, "Folder", REMOTE_FOLDER_NAME)

local UtilityRemote = getOrCreate(RemoteFolder, "RemoteEvent", UTILITY_REMOTE_NAME)

local function clean(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function parseDuration(text)
	text = string.lower(clean(text)):gsub("%s+", "")

	if text == "0" or text == "perm" or text == "permanent" then
		return 0
	end

	local number, unit = string.match(text, "^(%d+)([mhdw])$")

	number = tonumber(number)

	if not number or not unit then
		return nil
	end

	if unit == "m" then
		return number * 60
	elseif unit == "h" then
		return number * 3600
	elseif unit == "d" then
		return number * 86400
	elseif unit == "w" then
		return number * 604800
	end

	return nil
end

local function makeWarnCaseId()
	local HttpService = game:GetService("HttpService")

	local guid = HttpService:GenerateGUID(false)
	local short = string.upper(string.sub(guid, 1, 8))

	return "USARF-WARN-" .. short
end

local function initializePlayerAttributes(player)
	if not player then
		return
	end

	if player:GetAttribute("USARF_ModMode") == nil then
		player:SetAttribute("USARF_ModMode", false)
	end

	if player:GetAttribute("USARF_RadioModMode") == nil then
		player:SetAttribute("USARF_RadioModMode", false)
	end
end

local function resolveAreaKey(targetName)
	targetName = clean(targetName)

	if targetName == "" then
		return nil
	end

	local direct = AREA_TARGET_MAP[targetName]

	if direct then
		return direct
	end

	local lowered = string.lower(targetName)

	if lowered == "civil" or lowered == "civil departments" then
		return "civil"
	elseif lowered == "combative" or lowered == "combative departments" then
		return "combative"
	elseif lowered == "intelligence" or lowered == "intelligence departments" then
		return "intelligence"
	elseif lowered == "protection" or lowered == "protection departments" then
		return "protection"
	elseif lowered == "facility" or lowered == "facility wide" or lowered == "entire facility" then
		return "facility"
	end

	return nil
end

function ModerationUtilityService.SetModMode(player, enabled)
	if not player then
		return false, "Missing player."
	end

	local state = enabled == true

	player:SetAttribute("USARF_ModMode", state)

	player:SetAttribute("USARF_RadioModMode", state)

	return true, state
end

function ModerationUtilityService.ToggleModMode(player)
	if not player then
		return false, "Missing player."
	end

	local newState = player:GetAttribute("USARF_ModMode") ~= true

	return ModerationUtilityService.SetModMode(player, newState)
end

function ModerationUtilityService.View(executor, target)
	if not executor or not target then
		return false, "Missing player."
	end

	UtilityRemote:FireClient(executor, "View", {
		targetUserId = target.UserId,
		targetName = target.Name,
	})

	return true
end

function ModerationUtilityService.Unview(executor)
	if not executor then
		return false, "Missing player."
	end

	UtilityRemote:FireClient(executor, "Unview", {})

	return true
end

function ModerationUtilityService.Track(executor, target)
	if not executor or not target then
		return false, "Missing player."
	end

	UtilityRemote:FireClient(executor, "Track", {
		targetUserId = target.UserId,
		targetName = target.Name,
	})

	return true
end

function ModerationUtilityService.Untrack(executor)
	if not executor then
		return false, "Missing player."
	end

	UtilityRemote:FireClient(executor, "Untrack", {})

	return true
end

function ModerationUtilityService.WarnPlayer(executor, target, reason, caseId, options)
	if not target then
		return false, "Missing target."
	end

	options = options or {}

	reason = clean(reason)

	if reason == "" then
		reason = "No reason provided."
	end

	caseId = clean(caseId)

	if caseId == "" then
		caseId = makeWarnCaseId()
	end

	local issuerName = executor and executor.Name or clean(options.issuer)

	if issuerName == "" then
		issuerName = "SYSTEM"
	end

	UtilityRemote:FireClient(target, "WarnPopup", {
		title = options.title or "GAME WARNING",

		time = os.time(),
		reason = reason,
		caseId = caseId,
		issuer = issuerName,
	})

	if options.skipBridge ~= true and DiscordBotBridge then
		local bridgeSuccess, bridgeError = DiscordBotBridge.SubmitModeration(
			"warn",
			target,
			executor,
			reason,
			nil,
			options.parentCaseNumber or caseId,
			{
				evidence = options.evidence,
				internalNotes = options.internalNotes,

				notifyPlayer = false,
			}
		)

		if not bridgeSuccess then
			warn("[ModerationUtilityService] Failed to queue warning bridge:", bridgeError)
		end
	end

	return true, caseId
end

function ModerationUtilityService.SuspendTarget(
	executor,
	targetPlayer,
	suspensionType,
	targetList,
	durationText,
	reason,
	options
)
	if not executor then
		return false, "Missing executor."
	end

	if not targetPlayer then
		return false, "Target player is not online."
	end

	if typeof(targetList) ~= "table" then
		return false, "Missing target list."
	end

	options = options or {}

	suspensionType = clean(suspensionType)

	if suspensionType == "" then
		suspensionType = "Team"
	end

	reason = clean(reason)

	if reason == "" then
		reason = "No reason provided."
	end

	local durationSeconds = parseDuration(durationText)

	if durationSeconds == nil then
		return false, "Invalid duration."
	end

	local created = {}
	local failures = {}

	for _, targetNameValue in ipairs(targetList) do
		local targetName = clean(targetNameValue)

		if targetName ~= "" then
			local success
			local result

			if suspensionType == "Facility" then
				success, result =
					SuspensionService.SuspendFacility(targetPlayer.UserId, executor.UserId, reason, durationSeconds)
			elseif suspensionType == "Area" or suspensionType == "Category" then
				local areaKey = resolveAreaKey(targetName)

				if areaKey == "facility" then
					success, result =
						SuspensionService.SuspendFacility(targetPlayer.UserId, executor.UserId, reason, durationSeconds)
				elseif areaKey then
					success, result = SuspensionService.SuspendArea(
						targetPlayer.UserId,
						areaKey,
						executor.UserId,
						reason,
						durationSeconds
					)
				else
					success = false
					result = "Unknown area target: " .. targetName
				end
			elseif suspensionType == "Team" or suspensionType == "Department" then
				local teamKey = TeamAccessService.ResolveTeamKey(targetName)

				if teamKey then
					success, result = SuspensionService.SuspendDepartment(
						targetPlayer.UserId,
						teamKey,
						executor.UserId,
						reason,
						durationSeconds
					)
				else
					success = false
					result = "Could not resolve team: " .. targetName
				end
			else
				success = false
				result = "Invalid suspension type."
			end

			if success and result then
				table.insert(created, result)

				if options.skipBridge ~= true and DiscordBotBridge then
					local scopeType = "team"

					if suspensionType == "Area" or suspensionType == "Category" then
						scopeType = "category"
					elseif suspensionType == "Facility" then
						scopeType = "facility"
					elseif suspensionType == "Department" then
						scopeType = "department"
					end

					local bridgeSuccess, bridgeError = DiscordBotBridge.SubmitSuspension(
						targetPlayer,
						executor,
						targetName,
						reason,
						durationText,
						options.parentCaseNumber,
						{
							suspensionType = scopeType,

							scopeType = scopeType,

							scopeValue = targetName,

							scopeDisplay = targetName,

							evidence = options.evidence,

							internalNotes = options.internalNotes,

							notifyPlayer = options.notifyPlayer ~= false,
						}
					)

					if not bridgeSuccess then
						warn("[ModerationUtilityService] Failed to queue suspension bridge:", targetName, bridgeError)
					end
				end
			else
				table.insert(failures, {
					target = targetName,
					error = tostring(result),
				})

				warn("[ModerationUtilityService] Suspension failed:", targetName, result)
			end
		end
	end

	TeamAccessService.EnforcePlayerSuspensions(targetPlayer)

	if #created <= 0 then
		local message = "No suspensions were created."

		if #failures > 0 then
			message = tostring(failures[1].error or message)
		end

		return false, message
	end

	return true, created, failures
end

function ModerationUtilityService.ClearSuspensions(executor, targetPlayer)
	if not executor then
		return false, "Missing executor."
	end

	if not targetPlayer then
		return false, "Target player is not online."
	end

	local activeBefore = SuspensionService.GetActiveSuspensions(targetPlayer.UserId)

	local count = #activeBefore

	local success, result = SuspensionService.ClearAllSuspensions(targetPlayer.UserId, executor.UserId)

	if not success then
		return false, tostring(result)
	end

	TeamAccessService.EnforcePlayerSuspensions(targetPlayer)

	return true, count
end

function ModerationUtilityService.GetSuspensions(targetPlayer)
	if not targetPlayer then
		return {}
	end

	return SuspensionService.GetActiveSuspensions(targetPlayer.UserId)
end

function ModerationUtilityService.GetSuspensionHistory(targetPlayerOrUserId)
	local userId = nil

	if typeof(targetPlayerOrUserId) == "Instance" and targetPlayerOrUserId:IsA("Player") then
		userId = targetPlayerOrUserId.UserId
	else
		userId = tonumber(targetPlayerOrUserId)
	end

	if not userId then
		return {}
	end

	return SuspensionService.GetHistory(userId)
end

function ModerationUtilityService.Notify(player, title, message, notificationType)
	if not player then
		return false, "Missing player."
	end

	title = clean(title)
	message = clean(message)

	if NotificationService and typeof(NotificationService.Notify) == "function" then
		NotificationService.Notify(player, {
			Title = title ~= "" and title or "Moderation",

			Message = message,

			Type = clean(notificationType) ~= "" and notificationType or "Info",

			Duration = 6,
		})

		return true
	end

	return false, "NotificationService unavailable."
end

function ModerationUtilityService.Start()
	if Started then
		return
	end

	Started = true

	Players.PlayerAdded:Connect(initializePlayerAttributes)

	for _, player in ipairs(Players:GetPlayers()) do
		initializePlayerAttributes(player)
	end

	print("[ModerationUtilityService] Started")
end

return ModerationUtilityService
