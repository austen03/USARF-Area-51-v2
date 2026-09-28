local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local DeveloperCommandBridge = Remotes:WaitForChild("DeveloperCommandBridge")

local Services = ServerScriptService
	:WaitForChild("USARF")
	:WaitForChild("Services")

local TeleportProtectionService = require(
	Services:WaitForChild("TeleportProtectionService")
)

local HEIGHT_OFFSET = 3.5

local function isFiniteNumber(value)
	return value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function isValidVector3(value)
	return typeof(value) == "Vector3"
		and isFiniteNumber(value.X)
		and isFiniteNumber(value.Y)
		and isFiniteNumber(value.Z)
end

return function(context)
	local executor = context.Executor

	if not executor or not executor.Parent then
		return "Unable to locate the command executor."
	end

	local success, result = pcall(function()
		return DeveloperCommandBridge:InvokeClient(executor, "GetMouseWorldPosition")
	end)

	if not success then
		return "Could not read your mouse position: " .. tostring(result)
	end

	if type(result) ~= "table" or result.success ~= true then
		return tostring(
			type(result) == "table" and result.message
				or "Your mouse is not hovering over a valid surface."
		)
	end

	local position = result.position

	if not isValidVector3(position) then
		return "The hovered world position was invalid."
	end

	local character = executor.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return "Your character is not ready."
	end

	local rotationOnly = root.CFrame - root.Position
	local targetCFrame = CFrame.new(position + Vector3.new(0, HEIGHT_OFFSET, 0))
		* rotationOnly

	local moved, message = TeleportProtectionService.PivotCharacter(
		executor,
		targetCFrame,
		5
	)

	if not moved then
		return "Blink failed: " .. tostring(message or "Unknown error")
	end

	return string.format(
		"Blinked to %.1f, %.1f, %.1f.",
		position.X,
		position.Y,
		position.Z
	)
end
