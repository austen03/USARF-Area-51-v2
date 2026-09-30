local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local WeaponTestService = {}

local DUMMY_FOLDER_NAME = "USARF_WeaponTestDummies"
local TEMPLATE_PATH = { "Developer", "WeaponTestDummy" }

local RESPAWN_DELAY = 1.25
local SPAWN_DISTANCE = 10
local DEFAULT_HEALTH = 100

local activeDummies = {}

local function getOrCreateWorkspaceFolder()
	local folder = Workspace:FindFirstChild(DUMMY_FOLDER_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = DUMMY_FOLDER_NAME
		folder.Parent = Workspace
	end

	return folder
end

local function getTemplate()
	local current = ServerStorage

	for _, name in ipairs(TEMPLATE_PATH) do
		current = current:FindFirstChild(name)
		if not current then
			return nil
		end
	end

	return current
end

local function getCharacterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getSpawnCFrame(player)
	local root = getCharacterRoot(player)

	if not root then
		return CFrame.new(0, 6, 0)
	end

	local look = root.CFrame.LookVector
	local position = root.Position + (look * SPAWN_DISTANCE)

	return CFrame.lookAt(position, root.Position)
end

local function makeDamageNumber(dummy, damageAmount)
	local head = dummy:FindFirstChild("Head")
	if not head then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamageNumber"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = dummy

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 24
	label.TextColor3 = Color3.fromRGB(255, 80, 80)
	label.TextStrokeTransparency = 0.3
	label.Text = "-" .. tostring(math.floor(damageAmount + 0.5))
	label.Parent = billboard

	task.spawn(function()
		for i = 1, 20 do
			billboard.StudsOffset += Vector3.new(0, 0.035, 0)
			label.TextTransparency = i / 20
			label.TextStrokeTransparency = 0.3 + (i / 20)
			task.wait(0.025)
		end

		if billboard then
			billboard:Destroy()
		end
	end)
end

local function setupDummyHealthDisplay(dummy, humanoid)
	local lastHealth = humanoid.Health

	humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth < lastHealth then
			makeDamageNumber(dummy, lastHealth - newHealth)
		end

		lastHealth = newHealth
	end)
end

function WeaponTestService.Clear(player)
	local userId = player.UserId
	local existing = activeDummies[userId]

	if existing and existing.Parent then
		existing:Destroy()
	end

	activeDummies[userId] = nil
end

function WeaponTestService.Spawn(player)
	local template = getTemplate()

	if not template then
		return false, "Missing ServerStorage > Developer > WeaponTestDummy"
	end

	WeaponTestService.Clear(player)

	local folder = getOrCreateWorkspaceFolder()
	local dummy = template:Clone()

	dummy.Name = "WeaponTestDummy_" .. player.Name
	dummy.Parent = folder

	local humanoid = dummy:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		dummy:Destroy()
		return false, "WeaponTestDummy is missing a Humanoid"
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

	setupDummyHealthDisplay(dummy, humanoid)

	humanoid.Died:Connect(function()
		if activeDummies[player.UserId] ~= dummy then
			return
		end

		task.delay(RESPAWN_DELAY, function()
			if not player.Parent then
				return
			end

			if activeDummies[player.UserId] == dummy then
				WeaponTestService.Spawn(player)
			end
		end)

		Debris:AddItem(dummy, RESPAWN_DELAY)
	end)

	return true, "Weapon test dummy spawned."
end

function WeaponTestService.Start()
	Players.PlayerRemoving:Connect(function(player)
		WeaponTestService.Clear(player)
	end)

	print("[WeaponTestService] Started")
end

return WeaponTestService
