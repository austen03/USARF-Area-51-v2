local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local Services = ServerScriptService
	:WaitForChild("USARF")
	:WaitForChild("Services")

local CmdrPermissionService = require(
	Services:WaitForChild("CmdrPermissionService")
)

local function getOrCreate(parent, className, name)
	local existing = parent:FindFirstChild(name)

	if existing then
		return existing
	end

	local object = Instance.new(className)
	object.Name = name
	object.Parent = parent

	return object
end

getOrCreate(Remotes, "RemoteFunction", "DeveloperCommandBridge")

local FreecamStateRemote = getOrCreate(
	Remotes,
	"RemoteEvent",
	"DeveloperFreecamState"
)

local frozenStates = {}

local function getCharacterState(player)
	local character = player.Character
	local humanoid = character
		and character:FindFirstChildOfClass("Humanoid")
	local root = character
		and character:FindFirstChild("HumanoidRootPart")

	return character, humanoid, root
end

local function freezeCharacter(player)
	local _, humanoid, root = getCharacterState(player)

	if not humanoid or not root then
		return false
	end

	if not frozenStates[player] then
		frozenStates[player] = {
			rootAnchored = root.Anchored,
			walkSpeed = humanoid.WalkSpeed,
			jumpPower = humanoid.JumpPower,
			jumpHeight = humanoid.JumpHeight,
			autoRotate = humanoid.AutoRotate,
		}
	end

	root.Anchored = true
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false

	player:SetAttribute("USARF_FreecamActive", true)

	return true
end

local function unfreezeCharacter(player)
	local _, humanoid, root = getCharacterState(player)
	local state = frozenStates[player]

	if root then
		root.Anchored = state and state.rootAnchored == true or false
	end

	if humanoid then
		humanoid.WalkSpeed = state and state.walkSpeed or 16
		humanoid.JumpPower = state and state.jumpPower or 50
		humanoid.JumpHeight = state and state.jumpHeight or 7.2
		humanoid.AutoRotate = state == nil or state.autoRotate ~= false
	end

	frozenStates[player] = nil
	player:SetAttribute("USARF_FreecamActive", false)
end

FreecamStateRemote.OnServerEvent:Connect(function(player, active)
	-- Anyone allowed to run freecam (Developers, and QA testers in QA games).
	if not CmdrPermissionService.CanRun(player, "freecam") then
		unfreezeCharacter(player)
		return
	end

	if active == true then
		freezeCharacter(player)
	else
		unfreezeCharacter(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	frozenStates[player] = nil
end)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("USARF_FreecamActive", false)

	player.CharacterAdded:Connect(function()
		frozenStates[player] = nil
		player:SetAttribute("USARF_FreecamActive", false)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player:GetAttribute("USARF_FreecamActive") == nil then
		player:SetAttribute("USARF_FreecamActive", false)
	end

	player.CharacterAdded:Connect(function()
		frozenStates[player] = nil
		player:SetAttribute("USARF_FreecamActive", false)
	end)
end

print("[DeveloperCommandController] Started")