local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugStateService = {}

local USARF = ReplicatedStorage:WaitForChild("USARF")
local State = USARF:FindFirstChild("State")

if not State then
	State = Instance.new("Folder")
	State.Name = "State"
	State.Parent = USARF
end

local GAME_DEBUG_ATTRIBUTE = "USARF_GameDebug"
local DEV_MODE_ATTRIBUTE = "USARF_DevMode"
local startedAt = os.clock()
local diagnosticGeneration = 0

local function setGameDebug(enabled, executor)
	enabled = enabled == true

	State:SetAttribute(GAME_DEBUG_ATTRIBUTE, enabled)
	workspace:SetAttribute(GAME_DEBUG_ATTRIBUTE, enabled)

	State:SetAttribute(
		"USARF_GameDebugChangedBy",
		executor and executor.Name or "SYSTEM"
	)

	State:SetAttribute(
		"USARF_GameDebugChangedAt",
		os.time()
	)

	diagnosticGeneration += 1
	local generation = diagnosticGeneration

	if enabled then
		task.spawn(function()
			while State:GetAttribute(GAME_DEBUG_ATTRIBUTE) == true
				and diagnosticGeneration == generation
			do
				print(string.format(
					"[GameDebug] Uptime=%ds Players=%d/%d JobId=%s PlaceId=%d LuaMemoryKB=%d",
					math.floor(os.clock() - startedAt),
					#Players:GetPlayers(),
					Players.MaxPlayers,
					game.JobId ~= "" and game.JobId or "Studio",
					game.PlaceId,
					math.floor(gcinfo())
					))

				task.wait(30)
			end
		end)
	end
end

function DebugStateService.IsGameDebugEnabled()
	return State:GetAttribute(GAME_DEBUG_ATTRIBUTE) == true
end

function DebugStateService.SetGameDebug(enabled, executor)
	setGameDebug(enabled, executor)
	return DebugStateService.IsGameDebugEnabled()
end

function DebugStateService.ToggleGameDebug(executor)
	return DebugStateService.SetGameDebug(
		not DebugStateService.IsGameDebugEnabled(),
		executor
	)
end

function DebugStateService.IsDevModeEnabled(player)
	return player
		and player:GetAttribute(DEV_MODE_ATTRIBUTE) == true
end

function DebugStateService.SetDevMode(player, enabled)
	if not player then
		return false
	end

	player:SetAttribute(DEV_MODE_ATTRIBUTE, enabled == true)
	return DebugStateService.IsDevModeEnabled(player)
end

function DebugStateService.ToggleDevMode(player)
	return DebugStateService.SetDevMode(
		player,
		not DebugStateService.IsDevModeEnabled(player)
	)
end

function DebugStateService.GetStateFolder()
	return State
end

if State:GetAttribute(GAME_DEBUG_ATTRIBUTE) == nil then
	State:SetAttribute(GAME_DEBUG_ATTRIBUTE, false)
end

if workspace:GetAttribute(GAME_DEBUG_ATTRIBUTE) == nil then
	workspace:SetAttribute(GAME_DEBUG_ATTRIBUTE, false)
end

Players.PlayerAdded:Connect(function(player)
	if player:GetAttribute(DEV_MODE_ATTRIBUTE) == nil then
		player:SetAttribute(DEV_MODE_ATTRIBUTE, false)
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player:GetAttribute(DEV_MODE_ATTRIBUTE) == nil then
		player:SetAttribute(DEV_MODE_ATTRIBUTE, false)
	end
end

return DebugStateService