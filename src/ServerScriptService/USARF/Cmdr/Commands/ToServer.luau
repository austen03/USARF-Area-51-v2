local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local TeleportProtectionService = require(Services:WaitForChild("TeleportProtectionService"))

return function(context, target)
	local executor = context.Executor

	if not executor.Character or not target.Character then
		return "Missing character."
	end

	local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")

	if not targetRoot then
		return "Missing HumanoidRootPart."
	end

	local targetCFrame = targetRoot.CFrame * CFrame.new(0, 0, -4)

	local success, result = TeleportProtectionService.PivotCharacter(
		executor,
		targetCFrame,
		5
	)

	if not success then
		return result or "Teleport failed."
	end

	return "Teleported to " .. target.Name .. "."
end
