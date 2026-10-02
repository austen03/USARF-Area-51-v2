local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer

local TAG_NAME = "USARFNameTag"

local CHECK_INTERVAL = 0.12
local MAX_VISIBLE_DISTANCE_DESKTOP = 175
local MAX_VISIBLE_DISTANCE_MOBILE = 130
local ALWAYS_SHOW_CLOSE_DISTANCE = 18

-- Tags are built in pixels, so without this they stay the same size on screen at any range.
-- Full size up to SCALE_FULL_SIZE_DISTANCE, then shrink with distance like the character does.
local SCALE_NAME = "DistanceScale"
local SCALE_FULL_SIZE_DISTANCE = 20
local SCALE_MIN = 0.35

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local lastCheck = 0

local function getCamera()
	return Workspace.CurrentCamera
end

local function getCharacter(player)
	return player.Character
end

local function getHead(player)
	local character = getCharacter(player)
	if not character then
		return nil
	end

	return character:FindFirstChild("Head")
end

local function getNameTag(player)
	local character = getCharacter(player)
	if not character then
		return nil
	end

	return character:FindFirstChild(TAG_NAME, true)
end

local function setTagEnabled(player, enabled)
	local tag = getNameTag(player)

	if tag and tag:IsA("BillboardGui") then
		tag.Enabled = enabled == true
	end
end

local function shouldIgnoreHit(part, targetPlayer)
	if not part then
		return true
	end

	local localCharacter = localPlayer.Character
	local targetCharacter = targetPlayer.Character

	if localCharacter and part:IsDescendantOf(localCharacter) then
		return true
	end

	if targetCharacter and part:IsDescendantOf(targetCharacter) then
		return true
	end

	if part.Transparency >= 0.65 then
		return true
	end

	if part.CanCollide == false and part.CanQuery == false then
		return true
	end

	return false
end

local function hasLineOfSight(targetPlayer)
	local camera = getCamera()
	local head = getHead(targetPlayer)

	if not camera or not head then
		return false
	end

	local origin = camera.CFrame.Position
	local destination = head.Position + Vector3.new(0, 0.8, 0)
	local direction = destination - origin
	local distance = direction.Magnitude

	local maxDistance = isMobile and MAX_VISIBLE_DISTANCE_MOBILE or MAX_VISIBLE_DISTANCE_DESKTOP

	if distance > maxDistance then
		return false
	end

	if distance <= ALWAYS_SHOW_CLOSE_DISTANCE then
		return true
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local ignoreList = {}

	if localPlayer.Character then
		table.insert(ignoreList, localPlayer.Character)
	end

	if targetPlayer.Character then
		table.insert(ignoreList, targetPlayer.Character)
	end

	params.FilterDescendantsInstances = ignoreList
	params.IgnoreWater = true

	local result = Workspace:Raycast(origin, direction, params)

	if not result then
		return true
	end

	if shouldIgnoreHit(result.Instance, targetPlayer) then
		return true
	end

	return false
end

local function updatePlayer(player)
	local tag = getNameTag(player)

	if not tag then
		return
	end

	if player == localPlayer then
		tag.Enabled = true
		return
	end

	tag.Enabled = hasLineOfSight(player)
end

local function updateTagScale(player, camera)
	local tag = getNameTag(player)
	local container = tag and tag:FindFirstChild("Container")
	local head = getHead(player)

	if not container or not head then
		return
	end

	local scale = container:FindFirstChild(SCALE_NAME)

	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = SCALE_NAME
		scale.Parent = container
	end

	local distance = (camera.CFrame.Position - head.Position).Magnitude
	scale.Scale = math.clamp(SCALE_FULL_SIZE_DISTANCE / math.max(distance, 1), SCALE_MIN, 1)
end

RunService.RenderStepped:Connect(function()
	-- Scale every frame so tags resize smoothly; the line-of-sight raycasts below stay throttled.
	local camera = getCamera()

	if camera then
		for _, player in ipairs(Players:GetPlayers()) do
			updateTagScale(player, camera)
		end
	end

	if os.clock() - lastCheck < CHECK_INTERVAL then
		return
	end

	lastCheck = os.clock()

	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayer(player)
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		updatePlayer(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function()
		task.wait(1)
		updatePlayer(player)
	end)
end

print("[NameTagVisibilityController] Loaded")