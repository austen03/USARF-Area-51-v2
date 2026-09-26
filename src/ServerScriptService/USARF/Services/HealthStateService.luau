local Players = game:GetService("Players")

local HealthStateService = {}

local started = false
local characterConnections = {}

local ATTR_HEALTH = "USARF_Health"
local ATTR_MAX_HEALTH = "USARF_MaxHealth"
local ATTR_HEALTH_PERCENT = "USARF_HealthPercent"
local ATTR_BLEEDING = "USARF_Bleeding"
local ATTR_INJURY = "USARF_Injury"
local ATTR_DOWNED = "USARF_Downed"
local ATTR_REVIVABLE = "USARF_Revivable"

local INJURY_HEALTH_PERCENT = 0.5
local CRITICAL_HEALTH_PERCENT = 0.25

local function disconnectPlayer(player)
	local connections = characterConnections[player]

	if connections then
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end

	characterConnections[player] = nil
end

local function setDefaultAttributes(player)
	player:SetAttribute(ATTR_HEALTH, 100)
	player:SetAttribute(ATTR_MAX_HEALTH, 100)
	player:SetAttribute(ATTR_HEALTH_PERCENT, 1)
	player:SetAttribute(ATTR_BLEEDING, false)
	player:SetAttribute(ATTR_INJURY, "Stable")
	player:SetAttribute(ATTR_DOWNED, false)
	player:SetAttribute(ATTR_REVIVABLE, false)
end

local function updateHealthAttributes(player, humanoid)
	local maxHealth = humanoid.MaxHealth
	local health = math.max(0, humanoid.Health)
	local percent = 0

	if maxHealth > 0 then
		percent = math.clamp(health / maxHealth, 0, 1)
	end

	local injury = "Stable"

	if health <= 0 then
		injury = "Dead"
	elseif percent <= CRITICAL_HEALTH_PERCENT then
		injury = "Critical"
	elseif percent <= INJURY_HEALTH_PERCENT then
		injury = "Injured"
	end

	player:SetAttribute(ATTR_HEALTH, math.floor(health + 0.5))
	player:SetAttribute(ATTR_MAX_HEALTH, math.floor(maxHealth + 0.5))
	player:SetAttribute(ATTR_HEALTH_PERCENT, percent)
	player:SetAttribute(ATTR_INJURY, injury)

	if health <= 0 then
		player:SetAttribute(ATTR_BLEEDING, false)
		player:SetAttribute(ATTR_DOWNED, false)
		player:SetAttribute(ATTR_REVIVABLE, false)
	end
end

local function setupCharacter(player, character)
	disconnectPlayer(player)
	setDefaultAttributes(player)

	local connections = {}
	characterConnections[player] = connections

	local humanoid = character:WaitForChild("Humanoid", 10)

	if not humanoid then
		return
	end

	updateHealthAttributes(player, humanoid)

	table.insert(connections, humanoid.HealthChanged:Connect(function()
		updateHealthAttributes(player, humanoid)
	end))

	table.insert(connections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		updateHealthAttributes(player, humanoid)
	end))

	table.insert(connections, humanoid.Died:Connect(function()
		updateHealthAttributes(player, humanoid)
	end))
end

local function setupPlayer(player)
	setDefaultAttributes(player)

	if player.Character then
		setupCharacter(player, player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
end

function HealthStateService.Start()
	if started then
		return
	end

	started = true

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		disconnectPlayer(player)
	end)

	print("[HealthStateService] Started")
end

return HealthStateService