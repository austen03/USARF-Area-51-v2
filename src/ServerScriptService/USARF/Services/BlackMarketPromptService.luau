local Workspace = game:GetService("Workspace")

local BlackMarketPromptService = {}

local NPC_NAME = "Blackmarket"
local PROMPT_NAME = "USARF_BlackMarketPrompt"

local started = false

local function findBlackMarketNpc()
	local direct = Workspace:FindFirstChild(NPC_NAME)

	if direct then
		return direct
	end

	return Workspace:FindFirstChild(NPC_NAME, true)
end

local function getPromptPart(npc)
	if not npc then
		return nil
	end

	return npc:FindFirstChild("HumanoidRootPart")
		or npc:FindFirstChild("Head")
		or npc:FindFirstChild("UpperTorso")
		or npc:FindFirstChildWhichIsA("BasePart", true)
end

local function setupPrompt()
	local npc = findBlackMarketNpc()

	if not npc then
		warn("[BlackMarketPromptService] Missing NPC named:", NPC_NAME)
		return
	end

	local part = getPromptPart(npc)

	if not part then
		warn("[BlackMarketPromptService] No prompt part found for:", npc:GetFullName())
		return
	end

	local oldClickDetector = npc:FindFirstChildOfClass("ClickDetector")
	if oldClickDetector then
		oldClickDetector.MaxActivationDistance = 0
	end

	local prompt = part:FindFirstChild(PROMPT_NAME)

	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = PROMPT_NAME
		prompt.Parent = part
	end

	prompt.ActionText = "Open Black Market"
	prompt.ObjectText = "Black Market Dealer"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true

	print("[BlackMarketPromptService] Prompt ready at", part:GetFullName())
end

function BlackMarketPromptService.Start()
	if started then
		return
	end

	started = true

	task.defer(function()
		task.wait(1)
		setupPrompt()
	end)

	print("[BlackMarketPromptService] Started")
end

return BlackMarketPromptService