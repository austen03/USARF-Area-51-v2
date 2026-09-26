local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local GlassService = {}

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local NotificationService = require(Services:WaitForChild("NotificationService"))

local GLASS_NAMES = {
	TSCZ_Glass = true,
}

local REPAIR_TEAM_NAME = "Engineering & Technical"
local REQUIRED_TOOL_NAME = "Wrench"
local REPAIR_HOLD_DURATION = 3
local REPAIR_DISTANCE = 6

local registeredGlass = {}

local function isGlassRoot(instance)
	if not instance then
		return false
	end

	if instance:GetAttribute("WeaponGlassPenetration") == true then
		return true
	end

	if GLASS_NAMES[instance.Name] then
		return true
	end

	return false
end

local function findGlassRoot(instance)
	local current = instance

	while current and current ~= Workspace do
		if isGlassRoot(current) then
			return current
		end

		current = current.Parent
	end

	return nil
end

local function getWindowPart(glassRoot)
	if glassRoot:IsA("BasePart") then
		return glassRoot
	end

	local window = glassRoot:FindFirstChild("Window", true)
	if window and window:IsA("BasePart") then
		return window
	end

	return glassRoot:FindFirstChildWhichIsA("BasePart", true)
end

local function getGlassParts(glassRoot)
	local parts = {}

	if glassRoot:IsA("BasePart") then
		table.insert(parts, glassRoot)
	end

	for _, descendant in ipairs(glassRoot:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "USARF_GlassRepairPromptPart" then
			table.insert(parts, descendant)
		end
	end

	return parts
end

local function hasWrenchEquipped(player)
	local character = player.Character
	if not character then
		return false
	end

	local tool = character:FindFirstChildOfClass("Tool")
	return tool and tool.Name == REQUIRED_TOOL_NAME
end

local function canRepair(player, data)
	if not data.Broken then
		return false
	end

	if not player.Team or player.Team.Name ~= REPAIR_TEAM_NAME then
		return false
	end

	if not hasWrenchEquipped(player) then
		return false
	end

	return true
end

local function playBreakSound(glassRoot)
	for _, descendant in ipairs(glassRoot:GetDescendants()) do
		if descendant:IsA("Sound") and descendant.Name == "Break" then
			descendant:Play()
			return
		end
	end
end

local function saveOriginalStates(glassRoot)
	local states = {}

	for _, part in ipairs(getGlassParts(glassRoot)) do
		states[part] = {
			Transparency = part.Transparency,
			CanCollide = part.CanCollide,
			CanTouch = part.CanTouch,
			CanQuery = part.CanQuery,
		}
	end

	return states
end

local function setGuiEnabled(glassRoot, enabled)
	for _, descendant in ipairs(glassRoot:GetDescendants()) do
		if descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui") then
			descendant.Enabled = enabled
		end
	end
end

local function setClickDetectors(glassRoot, distance)
	for _, descendant in ipairs(glassRoot:GetDescendants()) do
		if descendant:IsA("ClickDetector") then
			descendant.MaxActivationDistance = distance
		end
	end
end

local function createRepairPrompt(glassRoot, data)
	local windowPart = getWindowPart(glassRoot)
	if not windowPart then
		warn("[GlassService] No window part for", glassRoot:GetFullName())
		return
	end

	local old = glassRoot:FindFirstChild("USARF_GlassRepairPromptPart")
	if old then
		old:Destroy()
	end

	local promptPart = Instance.new("Part")
	promptPart.Name = "USARF_GlassRepairPromptPart"
	promptPart.Anchored = true
	promptPart.CanCollide = false
	promptPart.CanTouch = false
	promptPart.CanQuery = true
	promptPart.Transparency = 1
	promptPart.Size = Vector3.new(4, 4, 4)
	promptPart.CFrame = windowPart.CFrame
	promptPart.Parent = glassRoot

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "USARF_GlassRepairPrompt"
	prompt.ActionText = "Repair"
	prompt.ObjectText = "Broken Glass"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = REPAIR_HOLD_DURATION
	prompt.MaxActivationDistance = REPAIR_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = promptPart

	prompt.Triggered:Connect(function(player)
		GlassService.RepairGlass(glassRoot, player)
	end)

	data.PromptPart = promptPart
	data.Prompt = prompt

	print("[GlassService] Repair prompt ready:", glassRoot:GetFullName())
end

function GlassService.RegisterGlass(glassRoot)
	if registeredGlass[glassRoot] then
		return registeredGlass[glassRoot]
	end

	local data = {
		Root = glassRoot,
		Broken = false,
		OriginalStates = saveOriginalStates(glassRoot),
		Prompt = nil,
		PromptPart = nil,
	}

	registeredGlass[glassRoot] = data

	glassRoot:SetAttribute("USARF_GlassBroken", false)

	createRepairPrompt(glassRoot, data)
	setGuiEnabled(glassRoot, false)
	setClickDetectors(glassRoot, 0)

	return data
end

function GlassService.BreakGlass(glassRoot)
	if not glassRoot then
		return false
	end

	local data = GlassService.RegisterGlass(glassRoot)

	if data.Broken then
		return false
	end

	data.Broken = true
	glassRoot:SetAttribute("USARF_GlassBroken", true)

	for _, part in ipairs(getGlassParts(glassRoot)) do
		part.Transparency = 1
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
	end

	playBreakSound(glassRoot)
	setGuiEnabled(glassRoot, true)
	setClickDetectors(glassRoot, 0)

	if data.PromptPart then
		local windowPart = getWindowPart(glassRoot)
		if windowPart then
			data.PromptPart.CFrame = windowPart.CFrame
		end

		data.PromptPart.CanQuery = true
	end

	if data.Prompt then
		data.Prompt.Enabled = true
	end

	print("[GlassService] Glass broken:", glassRoot:GetFullName())

	return true
end

function GlassService.RepairGlass(glassRoot, player)
	local data = registeredGlass[glassRoot]
	if not data then
		return false
	end

	if not canRepair(player, data) then
		return false
	end

	data.Broken = false
	glassRoot:SetAttribute("USARF_GlassBroken", false)

	for part, state in pairs(data.OriginalStates) do
		if part and part.Parent then
			part.Transparency = state.Transparency
			part.CanCollide = state.CanCollide
			part.CanTouch = state.CanTouch
			part.CanQuery = state.CanQuery
		end
	end

	setGuiEnabled(glassRoot, false)
	setClickDetectors(glassRoot, 0)

	if data.Prompt then
		data.Prompt.Enabled = false
	end

	print("[GlassService] Glass repaired:", glassRoot:GetFullName(), "by", player.Name)
	
	NotificationService.Notify(player, {
		Title = "Glass Repaired",
		Message = "TSCZ Observation Window has been restored.",
		Type = "Success",
		Duration = 3,
		Size = "Small",
		Priority = 2,
	})
	
	return true
end

function GlassService.FindGlassRoot(instance)
	return findGlassRoot(instance)
end

function GlassService.Start()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if isGlassRoot(descendant) then
			GlassService.RegisterGlass(descendant)
		end
	end

	Workspace.DescendantAdded:Connect(function(descendant)
		task.defer(function()
			if descendant and descendant.Parent and isGlassRoot(descendant) then
				GlassService.RegisterGlass(descendant)
			end
		end)
	end)

	print("[GlassService] Started")
end

return GlassService