local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local AdminMovementRemote = Remotes:WaitForChild("AdminMovement")

return function(context, target, speed)
	speed = math.clamp(tonumber(speed) or 70, 20, 250)

	target:SetAttribute("USARF_AntiExploitBypass", true)
	target:SetAttribute("USARF_AuthorizedFly", true)
	target:SetAttribute("USARF_AdminMovement", true)

	AdminMovementRemote:FireClient(target, "Fly", {
		Speed = speed,
		Executor = context.Executor and context.Executor.Name or "Unknown",
	})

	return "Enabled admin fly for " .. target.Name .. " at speed " .. tostring(speed) .. "."
end
