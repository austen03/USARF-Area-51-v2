local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local AmmoCrateService = {}

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local WeaponService = require(Services:WaitForChild("WeaponService"))

local CRATE_FOLDER_PATH = { "Map", "AmmoCrates" }

local PROMPT_NAME = "USARF_AmmoCratePrompt"
local PROMPT_ACTION_TEXT = "Resupply"
local PROMPT_OBJECT_TEXT = "Ammo Crate"
local HOLD_DURATION = 1.5
local MAX_DISTANCE = 10
local COOLDOWN = 2

local playerCooldowns = {}

local function getCrateFolder()
	local current = Workspace

	for _, name in ipairs(CRATE_FOLDER_PATH) do
		current = current:FindFirstChild(name)
		if not current then
			return nil
		end
	end

	return current
end

local function getPromptPart(crate)
	if crate:IsA("BasePart") then
		return crate
	end

	if crate:IsA("Model") then
		if crate.PrimaryPart then
			return crate.PrimaryPart
		end

		return crate:FindFirstChildWhichIsA("BasePart", true)
	end

	return nil
end

local function playCrateSound(promptPart)
	local sound = promptPart:FindFirstChild("ResupplySound")

	if sound and sound:IsA("Sound") then
		sound:Play()
	end
end

local function canUseCrate(player)
	local now = os.clock()
	local lastUse = playerCooldowns[player] or 0

	if now - lastUse < COOLDOWN then
		return false
	end

	playerCooldowns[player] = now
	return true
end

local function createPrompt(crate)
	local promptPart = getPromptPart(crate)
	if not promptPart then
		warn("[AmmoCrateService] Crate has no BasePart:", crate:GetFullName())
		return
	end

	local oldPrompt = promptPart:FindFirstChild(PROMPT_NAME)
	if oldPrompt then
		oldPrompt:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ActionText = PROMPT_ACTION_TEXT
	prompt.ObjectText = PROMPT_OBJECT_TEXT
	prompt.HoldDuration = HOLD_DURATION
	prompt.MaxActivationDistance = MAX_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = promptPart

	prompt.Triggered:Connect(function(player)
		if not canUseCrate(player) then
			return
		end

		local count = WeaponService.RefillAllAmmo(player)
		playCrateSound(promptPart)

		print("[AmmoCrateService] Refilled ammo for", player.Name, "Weapons:", count)
	end)
end

local function setupExistingCrates()
	local folder = getCrateFolder()
	if not folder then
		warn("[AmmoCrateService] Missing Workspace > Map > AmmoCrates")
		return
	end

	for _, crate in ipairs(folder:GetChildren()) do
		createPrompt(crate)
	end

	folder.ChildAdded:Connect(function(crate)
		task.wait(0.1)
		createPrompt(crate)
	end)
end

function AmmoCrateService.Start()
	setupExistingCrates()
	print("[AmmoCrateService] Started")
end

return AmmoCrateService