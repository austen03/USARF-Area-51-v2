local Players = game:GetService("Players")

local MedicalStateService = {}

local started = false
local characterConnections = {}
local bleedingTasks = {}

local ATTR_BLEEDING = "USARF_Bleeding"
local ATTR_BLEEDING_SEVERITY = "USARF_BleedingSeverity"
local ATTR_INJURY_TYPE = "USARF_InjuryType"
local ATTR_INJURY = "USARF_Injury"
local ATTR_DEAD = "USARF_Dead"

local LIGHT_DAMAGE_MIN = 15
local MODERATE_DAMAGE_MIN = 35
local SEVERE_DAMAGE_MIN = 60

local BLEED_RULES = {
	Light = {
		Chance = 0.2,
		TickSeconds = 3,
		Damage = 1,
		InjuryType = "Minor Wound",
	},

	Moderate = {
		Chance = 0.5,
		TickSeconds = 2,
		Damage = 2,
		InjuryType = "Open Wound",
	},

	Severe = {
		Chance = 1,
		TickSeconds = 1,
		Damage = 3,
		InjuryType = "Severe Trauma",
	},
}

local BLEED_PRIORITY = {
	None = 0,
	Light = 1,
	Moderate = 2,
	Severe = 3,
}

local function disconnectPlayer(player)
	local connections = characterConnections[player]

	if connections then
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end

	characterConnections[player] = nil
end

local function stopBleedingTask(player)
	bleedingTasks[player] = nil
end

local function setMedicalDefaults(player)
	player:SetAttribute(ATTR_BLEEDING, false)
	player:SetAttribute(ATTR_BLEEDING_SEVERITY, "None")
	player:SetAttribute(ATTR_INJURY_TYPE, "None")
end

local function disableRobloxHealthRegen(character)
	local healthScript = character:FindFirstChild("Health")

	if healthScript and healthScript:IsA("Script") then
		healthScript.Disabled = true
		healthScript:Destroy()
	end
end

local function getSeverityFromDamage(damage)
	if damage >= SEVERE_DAMAGE_MIN then
		return "Severe"
	end

	if damage >= MODERATE_DAMAGE_MIN then
		return "Moderate"
	end

	if damage >= LIGHT_DAMAGE_MIN then
		return "Light"
	end

	return nil
end

local function shouldBleed(severity)
	local rule = BLEED_RULES[severity]

	if not rule then
		return false
	end

	return math.random() <= rule.Chance
end

local function getCurrentSeverity(player)
	return player:GetAttribute(ATTR_BLEEDING_SEVERITY) or "None"
end

local function shouldUpgradeSeverity(currentSeverity, newSeverity)
	return (BLEED_PRIORITY[newSeverity] or 0) > (BLEED_PRIORITY[currentSeverity] or 0)
end

local function updateInjuryLabel(player, humanoid)
	if not humanoid or humanoid.Health <= 0 then
		player:SetAttribute(ATTR_INJURY, "Dead")
		return
	end

	local bleeding = player:GetAttribute(ATTR_BLEEDING) == true
	local severity = getCurrentSeverity(player)
	local percent = humanoid.Health / math.max(humanoid.MaxHealth, 1)

	if bleeding then
		if severity == "Severe" then
			player:SetAttribute(ATTR_INJURY, "Critical")
		else
			player:SetAttribute(ATTR_INJURY, "Injured")
		end

		return
	end

	if percent <= 0.25 then
		player:SetAttribute(ATTR_INJURY, "Critical")
	elseif percent <= 0.5 then
		player:SetAttribute(ATTR_INJURY, "Injured")
	else
		player:SetAttribute(ATTR_INJURY, "Stable")
	end
end

local function beginBleedingLoop(player)
	if bleedingTasks[player] then
		return
	end

	local token = {}
	bleedingTasks[player] = token

	task.spawn(function()
		while bleedingTasks[player] == token do
			local severity = getCurrentSeverity(player)
			local rule = BLEED_RULES[severity]

			if not rule then
				stopBleedingTask(player)
				return
			end

			task.wait(rule.TickSeconds)

			if bleedingTasks[player] ~= token then
				return
			end

			if player.Parent ~= Players then
				stopBleedingTask(player)
				return
			end

			if player:GetAttribute(ATTR_DEAD) == true then
				stopBleedingTask(player)
				return
			end

			if player:GetAttribute(ATTR_BLEEDING) ~= true then
				stopBleedingTask(player)
				return
			end

			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")

			if not humanoid or humanoid.Health <= 0 then
				stopBleedingTask(player)
				return
			end

			humanoid:TakeDamage(rule.Damage)
			updateInjuryLabel(player, humanoid)
		end
	end)
end

local function startBleeding(player, humanoid, severity)
	if not severity then
		return
	end

	local rule = BLEED_RULES[severity]

	if not rule then
		return
	end

	local currentSeverity = getCurrentSeverity(player)

	if player:GetAttribute(ATTR_BLEEDING) == true and not shouldUpgradeSeverity(currentSeverity, severity) then
		return
	end

	if player:GetAttribute(ATTR_BLEEDING) ~= true and not shouldBleed(severity) then
		return
	end

	player:SetAttribute(ATTR_BLEEDING, true)
	player:SetAttribute(ATTR_BLEEDING_SEVERITY, severity)
	player:SetAttribute(ATTR_INJURY_TYPE, rule.InjuryType)

	updateInjuryLabel(player, humanoid)

	stopBleedingTask(player)
	beginBleedingLoop(player)

	if _G.USARFNotifyPlayer then
		_G.USARFNotifyPlayer(player, "Medical", "You are bleeding. Use a bandage before healing.", 5)
	end
end

function MedicalStateService.StopBleeding(player)
	if not player then
		return false, "Missing player"
	end

	local wasBleeding = player:GetAttribute(ATTR_BLEEDING) == true

	player:SetAttribute(ATTR_BLEEDING, false)
	player:SetAttribute(ATTR_BLEEDING_SEVERITY, "None")
	player:SetAttribute(ATTR_INJURY_TYPE, "None")

	stopBleedingTask(player)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid and humanoid.Health > 0 then
		updateInjuryLabel(player, humanoid)
	end

	return wasBleeding
end

function MedicalStateService.HealPlayer(player, amount)
	if not player then
		return false, "Missing player"
	end

	if player:GetAttribute(ATTR_BLEEDING) == true then
		return false, "Player must be bandaged before healing"
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return false, "Player is not alive"
	end

	local oldHealth = humanoid.Health

	amount = tonumber(amount) or 25
	humanoid.Health = math.clamp(humanoid.Health + amount, 0, humanoid.MaxHealth)

	updateInjuryLabel(player, humanoid)

	return humanoid.Health > oldHealth
end

local function setupCharacter(player, character)
	disconnectPlayer(player)
	stopBleedingTask(player)
	setMedicalDefaults(player)
	disableRobloxHealthRegen(character)

	local connections = {}
	characterConnections[player] = connections

	local humanoid = character:WaitForChild("Humanoid", 10)

	if not humanoid then
		return
	end

	local lastHealth = humanoid.Health

	table.insert(connections, humanoid.HealthChanged:Connect(function(newHealth)
		if player:GetAttribute(ATTR_DEAD) == true then
			lastHealth = newHealth
			return
		end

		if newHealth <= 0 then
			stopBleedingTask(player)
			player:SetAttribute(ATTR_BLEEDING, false)
			player:SetAttribute(ATTR_BLEEDING_SEVERITY, "None")
			player:SetAttribute(ATTR_INJURY_TYPE, "None")
			lastHealth = newHealth
			return
		end

		local damageTaken = lastHealth - newHealth

		if damageTaken > 0 then
			local severity = getSeverityFromDamage(damageTaken)

			if severity then
				startBleeding(player, humanoid, severity)
			end
		end

		updateInjuryLabel(player, humanoid)
		lastHealth = newHealth
	end))

	table.insert(connections, humanoid.Died:Connect(function()
		stopBleedingTask(player)
		player:SetAttribute(ATTR_BLEEDING, false)
		player:SetAttribute(ATTR_BLEEDING_SEVERITY, "None")
		player:SetAttribute(ATTR_INJURY_TYPE, "None")
	end))
end

local function setupPlayer(player)
	setMedicalDefaults(player)

	if player.Character then
		setupCharacter(player, player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
end

function MedicalStateService.Start()
	if started then
		return
	end

	started = true
	math.randomseed(os.clock() * 100000)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		disconnectPlayer(player)
		stopBleedingTask(player)
	end)

	print("[MedicalStateService] Started")
end

return MedicalStateService