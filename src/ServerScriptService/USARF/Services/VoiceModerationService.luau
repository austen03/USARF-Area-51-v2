local Players = game:GetService("Players")

local VoiceModerationService = {}
local mutedUserIds = {}
local started = false

local function isInputForPlayer(instance, player)
	if not instance:IsA("AudioDeviceInput") then return false end
	local success, inputPlayer = pcall(function() return instance.Player end)
	return success and inputPlayer == player
end

local function getInputsForPlayer(player)
	local inputs = {}
	for _, descendant in ipairs(game:GetDescendants()) do
		if isInputForPlayer(descendant, player) then table.insert(inputs, descendant) end
	end
	return inputs
end

local function applyMuteState(player)
	local muted = mutedUserIds[player.UserId] == true
	local changed = 0
	for _, input in ipairs(getInputsForPlayer(player)) do
		if pcall(function() input.Muted = muted end) then changed += 1 end
	end
	player:SetAttribute("USARF_VoiceMuted", muted)
	return changed
end

function VoiceModerationService.IsMuted(player)
	return player and mutedUserIds[player.UserId] == true
end

function VoiceModerationService.SetMuted(player, muted)
	if not player or not player.Parent then return false, "Player is unavailable." end
	if muted then mutedUserIds[player.UserId] = true else mutedUserIds[player.UserId] = nil end
	return true, { muted = muted == true, inputsChanged = applyMuteState(player) }
end

function VoiceModerationService.Start()
	if started then return end
	started = true
	game.DescendantAdded:Connect(function(descendant)
		if not descendant:IsA("AudioDeviceInput") then return end
		task.defer(function()
			for _, player in ipairs(Players:GetPlayers()) do
				if mutedUserIds[player.UserId] and isInputForPlayer(descendant, player) then
					pcall(function() descendant.Muted = true end)
					break
				end
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player) mutedUserIds[player.UserId] = nil end)
	print("[VoiceModerationService] Started")
end

return VoiceModerationService