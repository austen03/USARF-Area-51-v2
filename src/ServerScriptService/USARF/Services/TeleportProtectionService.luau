local TeleportProtectionService = {}

local DEFAULT_DURATION = 5

function TeleportProtectionService.Authorize(player, duration)
	if not player then
		return
	end

	duration = duration or DEFAULT_DURATION

	player:SetAttribute("USARF_AuthorizedTeleport", true)

	task.delay(duration, function()
		if player and player.Parent then
			player:SetAttribute("USARF_AuthorizedTeleport", false)
		end
	end)
end

function TeleportProtectionService.PivotCharacter(player, targetCFrame, duration)
	if not player or not targetCFrame then
		return false, "Missing player or targetCFrame"
	end

	local character = player.Character

	if not character then
		return false, "Missing character"
	end

	TeleportProtectionService.Authorize(player, duration or DEFAULT_DURATION)

	character:PivotTo(targetCFrame)

	return true
end

function TeleportProtectionService.SetBypass(player, enabled)
	if not player then
		return
	end

	player:SetAttribute("USARF_AntiExploitBypass", enabled == true)
end

return TeleportProtectionService