local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local DUMMY_FOLDER_NAME = "USARF_WeaponTestDummies"
local RESPAWN_DELAY = 1.25
local SPAWN_DISTANCE = 10
local DEFAULT_HEALTH = 100

local activeDummies = {}

local function getTemplate()
	local developerFolder = ServerStorage:FindFirstChild("Developer")
	if not developerFolder then
		return nil
	end

	return developerFolder:FindFirstChild("WeaponTestDummy")
end

local function getOrCreateDummyFolder()
	local folder = Workspace:FindFirstChild(DUMMY_FOLDER_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = DUMMY_FOLDER_NAME
		folder.Parent = Workspace
	end

	return folder
end

local function getRoot(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getSpawnCFrame(player)
	local root = getRoot(player)

	if not root then
		return CFrame.new(0, 6, 0)
	end

	local position = root.Position + root.CFrame.LookVector * SPAWN_DISTANCE
	return CFrame.lookAt(position, root.Position)
end

local function createDamageNumber(dummy, amount)
	local head = dummy:FindFirstChild("Head")
	if not head then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamageNumber"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 120, 0, 42)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = dummy

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 24
	label.TextColor3 = Color3.fromRGB(255, 80, 80)
	label.TextStrokeTransparency = 0.25
	label.Text = "-" .. tostring(math.floor(amount + 0.5))
	label.Parent = billboard

	task.spawn(function()
		for i = 1, 20 do
			if not billboard.Parent then
				return
			end

			billboard.StudsOffset += Vector3.new(0, 0.035, 0)
			label.TextTransparency = i / 20
			label.TextStrokeTransparency = 0.25 + (i / 20)
			task.wait(0.025)
		end

		if billboard then
			billboard:Destroy()
		end
	end)
end

local function watchDamage(dummy, humanoid)
	local lastHealth = humanoid.Health

	humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth then
			createDamageNumber(dummy, lastHealth - newHealth)
		end

		lastHealth = newHealth
	end)
end

local function clearDummy(player)
	local existing = activeDummies[player.UserId]

	if existing and existing.Parent then
		existing:Destroy()
	end

	activeDummies[player.UserId] = nil
end

local function spawnDummy(player)
	local template = getTemplate()

	if not template then
		return "Failed: Missing ServerStorage > Developer > WeaponTestDummy"
	end

	clearDummy(player)

	local folder = getOrCreateDummyFolder()
	local dummy = template:Clone()
	dummy.Name = "WeaponTestDummy_" .. player.Name
	dummy.Parent = folder

	local humanoid = dummy:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		dummy:Destroy()
		return "Failed: WeaponTestDummy is missing a Humanoid"
	end

	humanoid.MaxHealth = DEFAULT_HEALTH
	humanoid.Health = DEFAULT_HEALTH
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer

	for _, descendant in ipairs(dummy:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = true
			descendant.CanTouch = true
			descendant.CanQuery = true
		end
	end

	dummy:PivotTo(getSpawnCFrame(player))
	activeDummies[player.UserId] = dummy

	watchDamage(dummy, humanoid)

	humanoid.Died:Connect(function()
		if activeDummies[player.UserId] ~= dummy then
			return
		end

		task.delay(RESPAWN_DELAY, function()
			if player and player.Parent and activeDummies[player.UserId] == dummy then
				spawnDummy(player)
			end
		end)

		Debris:AddItem(dummy, RESPAWN_DELAY)
	end)

	return "Weapon test dummy spawned."
end

return function(context, mode)
	local player = context.Executor

	mode = string.lower(tostring(mode or "spawn"))

	if mode == "clear" or mode == "remove" or mode == "delete" then
		clearDummy(player)
		return "Weapon test dummy cleared."
	end

	return spawnDummy(player)
end
