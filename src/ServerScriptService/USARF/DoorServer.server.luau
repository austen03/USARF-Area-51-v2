local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARFReplicated = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARFReplicated:WaitForChild("Remotes")
local DoorEvent = Remotes:WaitForChild("DoorEvent")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local DoorAccessService = require(Services:WaitForChild("DoorAccessService"))

local MAX_DOOR_DISTANCE = 12

local function isValidDoor(door)
	if typeof(door) ~= "Instance" then
		return false
	end

	if not door:IsDescendantOf(workspace) then
		return false
	end

	if not door:FindFirstChild("DoorSettings") then
		return false
	end

	return true
end

local function getDoorPoint(door)
	local point = door:FindFirstChild("Point", true)

	if point and point:IsA("BasePart") then
		return point
	end

	local moving = door:FindFirstChild("Moving")
	if moving and moving:IsA("Model") then
		if moving.PrimaryPart then
			return moving.PrimaryPart
		end

		local movingPart = moving:FindFirstChildWhichIsA("BasePart", true)
		if movingPart then
			return movingPart
		end
	end

	local doorPart = door:FindFirstChild("Door", true)
	if doorPart and doorPart:IsA("BasePart") then
		return doorPart
	end

	local door1 = door:FindFirstChild("Door1", true)
	if door1 and door1:IsA("BasePart") then
		return door1
	end

	return door.PrimaryPart
end

local function isPlayerNearDoor(player, door)
	local character = player.Character

	if not character then
		return false
	end

	local root = character:FindFirstChild("HumanoidRootPart")

	if not root then
		return false
	end

	local point = getDoorPoint(door)

	if not point then
		return false
	end

	return (root.Position - point.Position).Magnitude <= MAX_DOOR_DISTANCE
end

DoorAccessService.Start(DoorEvent)

DoorEvent.OnServerEvent:Connect(function(player, door, action)
	if not isValidDoor(door) then
		return
	end

	if not isPlayerNearDoor(player, door) then
		return
	end

	if action == "ToggleOpen" then
		DoorAccessService.ToggleOpen(player, door)
	elseif action == "ToggleLock" then
		DoorAccessService.ToggleLock(player, door)
	end
end)

print("[DoorServer] Initialized")