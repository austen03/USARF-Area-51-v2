local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local AdminMovementRemote = Remotes:WaitForChild("AdminMovement")

return function(context, target)
	target:SetAttribute("USARF_AuthorizedNoclip", false)

	if target:GetAttribute("USARF_AuthorizedFly") ~= true then
		target:SetAttribute("USARF_AntiExploitBypass", false)
		target:SetAttribute("USARF_AdminMovement", false)
	end

	AdminMovementRemote:FireClient(target, "Clip", {
		Executor = context.Executor and context.Executor.Name or "Unknown",
	})

	return "Disabled admin noclip for " .. target.Name .. "."
end
