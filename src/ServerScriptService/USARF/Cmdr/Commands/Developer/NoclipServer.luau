local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local AdminMovementRemote = Remotes:WaitForChild("AdminMovement")

return function(context, target)
	target:SetAttribute("USARF_AntiExploitBypass", true)
	target:SetAttribute("USARF_AuthorizedNoclip", true)
	target:SetAttribute("USARF_AdminMovement", true)

	AdminMovementRemote:FireClient(target, "Noclip", {
		Executor = context.Executor and context.Executor.Name or "Unknown",
	})

	return "Enabled admin noclip for " .. target.Name .. "."
end
