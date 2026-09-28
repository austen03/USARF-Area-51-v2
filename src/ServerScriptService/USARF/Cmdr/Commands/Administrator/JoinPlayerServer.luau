local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local function clean(value)
	return tostring(value or "")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
end

local function resolveUserId(username)
	local success, result = pcall(function()
		return Players:GetUserIdFromNameAsync(username)
	end)

	if not success then
		return nil, tostring(result)
	end

	return result
end

local function resolvePlayerServer(userId)
	local success, currentInstance, errorMessage, placeId, jobIdOrError =
		pcall(function()
			return TeleportService:GetPlayerPlaceInstanceAsync(userId)
		end)

	if not success then
		return nil, nil, tostring(jobIdOrError or errorMessage)
	end

	if typeof(placeId) ~= "number" or placeId <= 0 then
		return nil, nil, errorMessage ~= "" and tostring(errorMessage) or "The player's place could not be determined."	end

	if typeof(jobIdOrError) ~= "string" or jobIdOrError == "" then
		return nil, nil, errorMessage ~= "" and tostring(errorMessage) or "The player's server instance could not be determined." end

	return placeId, jobIdOrError, currentInstance
end

return function(context, username)
	local executor = context.Executor
	username = clean(username)

	if not executor or not executor.Parent then
		return "Unable to locate the command executor."
	end

	if username == "" then
		return "A Roblox username is required."
	end

	local userId, userError = resolveUserId(username)

	if not userId then
		return "Could not resolve username: " .. tostring(userError)
	end

	if userId == executor.UserId then
		return "You are already in your own server."
	end

	local playerInCurrentServer = Players:GetPlayerByUserId(userId)

	if playerInCurrentServer then
		return playerInCurrentServer.Name
			.. " is already in this server."
	end

	local placeId, jobId, locationError =
		resolvePlayerServer(userId)

	if not placeId or not jobId then
		return "Unable to locate that player's server: "
			.. tostring(locationError)
	end

	if jobId == game.JobId then
		return username .. " is already in this server."
	end

	local teleportSuccess, teleportError = pcall(function()
		TeleportService:TeleportToPlaceInstance(
			placeId,
			jobId,
			executor
		)
	end)

	if not teleportSuccess then
		return "Unable to join that server: "
			.. tostring(teleportError)
	end

	return "Joining " .. username .. "'s server..."
end
