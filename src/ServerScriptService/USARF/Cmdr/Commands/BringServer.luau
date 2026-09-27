local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local TeleportProtectionService = require(Services:WaitForChild("TeleportProtectionService"))

return function(context, target)
	local executor = context.Executor

	if not executor.Character or not target.Character then
		return "Missing character."
	end

	local executorRoot = executor.Character:FindFirstChild("HumanoidRootPart")

	if not executorRoot then
		return "Missing HumanoidRootPart."
	end

	local targetCFrame = executorRoot.CFrame * CFrame.new(0, 0, -4)

	local success, result = TeleportProtectionService.PivotCharacter(
		target,
		targetCFrame,
		5
	)

	if not success then
		return result or "Teleport failed."
	end

	return "Brought " .. target.Name .. " to you."
end
