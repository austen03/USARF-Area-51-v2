local ServerScriptService = game:GetService("ServerScriptService")
local Service = require(ServerScriptService:WaitForChild("USARF"):WaitForChild("Services"):WaitForChild("VoiceModerationService"))
local function clean(value) return string.lower(tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
return function(context, player, mode)
	if not player or not player.Parent then return "Player is unavailable." end
	mode = clean(mode)
	local current = Service.IsMuted(player)
	if mode == "status" then return string.format("%s's voice is %s.", player.Name, current and "MUTED" or "UNMUTED") end
	local shouldMute
	if mode == "" or mode == "toggle" then shouldMute = not current
	elseif mode == "on" or mode == "true" or mode == "mute" then shouldMute = true
	elseif mode == "off" or mode == "false" or mode == "unmute" then shouldMute = false
	else return "Mode must be on, off, toggle, or status." end
	local success, result = Service.SetMuted(player, shouldMute)
	if not success then return tostring(result) end
	return string.format("%s's voice is now %s. Audio inputs updated: %d.", player.Name, result.muted and "MUTED" or "UNMUTED", result.inputsChanged)
end
