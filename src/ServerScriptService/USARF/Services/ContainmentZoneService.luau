local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ContainmentZoneService = {}

local SCAN_INTERVAL = 0.08
local DEBUG = true

local TERMINATION_BLOCK_PATH = {
	"Map",
	"TerminationBlocks",
	"TerminateBlock",
}

local CROSS_AXIS = "X"

local DANGER_SIDE = 1

local HEIGHT_PADDING = 2
local LENGTH_PADDING = 12

local SPAWN_GRACE_SECONDS = 3

local CROSS_EPSILON = 0.08

local SAFE_TEST_SUBJECT_TOOLS = {
	["Medkit"] = true,
	["Building Tools"] = true,
	["F3X"] = true,
}

local started = false
local playerStates = {}

local configuredBlock = nil

local function debugPrint(...)
	if DEBUG then
		print("[ContainmentZoneService]", ...)
	end
end

local function getTerminationBlock()
	local current = Workspace

	for _, name in ipairs(TERMINATION_BLOCK_PATH) do
		current = current:FindFirstChild(name)

		if not current then
			return nil
		end
	end

	if current:IsA("BasePart") then
		return current
	end

	return nil
end

local function configureTerminationBlock(block)
	if not block or not block:IsA("BasePart") then
		return
	end

	block.Anchored = true
	block.CanCollide = false
	block.CanTouch = false
	block.CanQuery = false
	block.CastShadow = false
	block.Transparency = 1

	configuredBlock = block
end

local function getRoot(player)
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function isTestSubject(player)
	if not player then
		return false
	end

	if player:GetAttribute("USARF_TeamKey") == "TestSubject" then
		return true
	end

	if player.Team and player.Team.Name == "Test Subject" then
		return true
	end

	return false
end

local function isRestrictedTool(tool)
	if not tool or not tool:IsA("Tool") then
		return false
	end

	if SAFE_TEST_SUBJECT_TOOLS[tool.Name] == true then
		return false
	end

	return true
end

local function getEquippedRestrictedTool(player)
	local character = player.Character

	if not character then
		return nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if isRestrictedTool(child) then
			return child
		end
	end

	return nil
end

local function getCrossValue(localPosition)
	if CROSS_AXIS == "X" then
		return localPosition.X
	elseif CROSS_AXIS == "Y" then
		return localPosition.Y
	elseif CROSS_AXIS == "Z" then
		return localPosition.Z
	end

	return localPosition.X
end

local function getSideFromLocalPosition(localPosition)
	local crossValue = getCrossValue(localPosition)
	local signedValue = crossValue * DANGER_SIDE

	if signedValue > CROSS_EPSILON then
		return "Danger"
	elseif signedValue < -CROSS_EPSILON then
		return "Safe"
	end

	return "Boundary"
end

local function isInsideBoundaryCoverage(block, localPosition)
	local halfX = block.Size.X / 2
	local halfY = block.Size.Y / 2
	local halfZ = block.Size.Z / 2

	if CROSS_AXIS == "X" then
		return math.abs(localPosition.Y) <= halfY + HEIGHT_PADDING
			and math.abs(localPosition.Z) <= halfZ + LENGTH_PADDING
	end

	if CROSS_AXIS == "Z" then
		return math.abs(localPosition.Y) <= halfY + HEIGHT_PADDING
			and math.abs(localPosition.X) <= halfX + LENGTH_PADDING
	end

	if CROSS_AXIS == "Y" then
		return math.abs(localPosition.X) <= halfX + LENGTH_PADDING
			and math.abs(localPosition.Z) <= halfZ + LENGTH_PADDING
	end

	return false
end

local function crossedSafeToDanger(previousLocalPosition, currentLocalPosition)
	if not previousLocalPosition or not currentLocalPosition then
		return false
	end

	local previousValue = getCrossValue(previousLocalPosition) * DANGER_SIDE

	local currentValue = getCrossValue(currentLocalPosition) * DANGER_SIDE

	return previousValue < -CROSS_EPSILON and currentValue > CROSS_EPSILON
end

local function crossingWasInsideCoverage(block, previousLocalPosition, currentLocalPosition)
	return isInsideBoundaryCoverage(block, previousLocalPosition)
		or isInsideBoundaryCoverage(block, currentLocalPosition)
end

local function setTerminate(player, reason, force)
	if player:GetAttribute("USARF_ContainmentStatus") == "AUTHORIZED" and force ~= true then
		return
	end

	if player:GetAttribute("USARF_ContainmentStatus") ~= "TERMINATE" then
		player:SetAttribute("USARF_ContainmentStatus", "TERMINATE")

		debugPrint(player.Name, "marked TERMINATE", reason or "")
	end
end

local function resetPlayerState(player)
	playerStates[player] = {
		spawnedAt = os.clock(),
		armed = false,
		lastLocalPosition = nil,
		lastSide = nil,
	}
end

local function clearIfNotTestSubject(player)
	if not isTestSubject(player) then
		player:SetAttribute("USARF_ContainmentStatus", nil)
	end
end

local function scanPlayer(player, block)
	if not player.Parent then
		playerStates[player] = nil
		return
	end

	if not isTestSubject(player) then
		clearIfNotTestSubject(player)
		resetPlayerState(player)
		return
	end

	local restrictedTool = getEquippedRestrictedTool(player)

	if restrictedTool then
		setTerminate(player, "Restricted tool equipped: " .. restrictedTool.Name, true)

		return
	end

	local root = getRoot(player)

	if not root then
		return
	end

	local state = playerStates[player]

	if not state then
		resetPlayerState(player)
		state = playerStates[player]
	end

	local currentLocalPosition = block.CFrame:PointToObjectSpace(root.Position)

	local currentSide = getSideFromLocalPosition(currentLocalPosition)

	if os.clock() - state.spawnedAt < SPAWN_GRACE_SECONDS then
		state.lastLocalPosition = currentLocalPosition

		state.lastSide = currentSide
		return
	end

	if not state.armed then
		state.armed = true
		state.lastLocalPosition = currentLocalPosition

		state.lastSide = currentSide

		debugPrint(player.Name, "armed on side:", currentSide)

		return
	end

	if
		state.lastLocalPosition
		and crossedSafeToDanger(state.lastLocalPosition, currentLocalPosition)
		and crossingWasInsideCoverage(block, state.lastLocalPosition, currentLocalPosition)
	then
		setTerminate(player, "Crossed termination boundary", false)
	end

	state.lastLocalPosition = currentLocalPosition

	state.lastSide = currentSide
end

local function setupCharacter(player, character)
	task.wait(0.5)

	resetPlayerState(player)

	if isTestSubject(player) then
		if player:GetAttribute("USARF_ContainmentStatus") == "TERMINATE" then
			player:SetAttribute("USARF_ContainmentStatus", nil)
		end
	else
		clearIfNotTestSubject(player)
	end

	character.ChildAdded:Connect(function(child)
		if isTestSubject(player) and isRestrictedTool(child) then
			setTerminate(player, "Restricted tool equipped: " .. child.Name, true)
		end
	end)
end

local function handleTeamStateChanged(player)
	task.wait(0.15)

	resetPlayerState(player)

	if not isTestSubject(player) then
		player:SetAttribute("USARF_ContainmentStatus", nil)

		return
	end

	if player:GetAttribute("USARF_ContainmentStatus") == "TERMINATE" then
		player:SetAttribute("USARF_ContainmentStatus", nil)
	end
end

local function setupPlayer(player)
	resetPlayerState(player)

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		handleTeamStateChanged(player)
	end)

	player:GetAttributeChangedSignal("USARF_TeamKey"):Connect(function()
		handleTeamStateChanged(player)
	end)

	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end
end

function ContainmentZoneService.Authorize(player)
	if not player or not isTestSubject(player) then
		return false
	end

	player:SetAttribute("USARF_ContainmentStatus", "AUTHORIZED")

	return true
end

function ContainmentZoneService.ClearStatus(player)
	if not player then
		return false
	end

	player:SetAttribute("USARF_ContainmentStatus", nil)

	resetPlayerState(player)

	return true
end

function ContainmentZoneService.MarkTerminate(player)
	if not player or not isTestSubject(player) then
		return false
	end

	player:SetAttribute("USARF_ContainmentStatus", "TERMINATE")

	return true
end

function ContainmentZoneService.Start()
	if started then
		return
	end

	started = true

	local initialBlock = getTerminationBlock()

	if initialBlock then
		configureTerminationBlock(initialBlock)
	else
		warn("[ContainmentZoneService] Missing termination block.")
	end

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		playerStates[player] = nil
	end)

	task.spawn(function()
		local warnedMissing = false

		while started do
			local block = getTerminationBlock()

			if block then
				warnedMissing = false

				if configuredBlock ~= block or block.CanQuery or block.CanCollide or block.CanTouch then
					configureTerminationBlock(block)
				end

				for _, player in ipairs(Players:GetPlayers()) do
					scanPlayer(player, block)
				end
			elseif not warnedMissing then
				warnedMissing = true

				warn("[ContainmentZoneService] Missing termination block.")
			end

			task.wait(SCAN_INTERVAL)
		end
	end)

	print("[ContainmentZoneService] Started")
end

task.defer(function()
	ContainmentZoneService.Start()
end)

return ContainmentZoneService
