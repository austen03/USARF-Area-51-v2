local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatRulesService = {}

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")
local USARFConfig = require(Config:WaitForChild("USARFConfig"))

local VALID_MODES = { default = true, unrestricted = true }
local currentMode = "default"

local function normalize(value)
	return string.lower(tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function resolveTeamKey(player)
	if not player then return nil end
	local key = player:GetAttribute("USARF_TeamKey")
	if key and USARFConfig.Teams[key] then return key end
	if player.Team then return USARFConfig.GetTeamKeyFromName(player.Team.Name) end
	local name = player:GetAttribute("USARF_TeamName")
	if name and name ~= "" then return USARFConfig.GetTeamKeyFromName(name) end
	return nil
end

local function classify(player)
	local teamKey = resolveTeamKey(player)
	if teamKey == "TestSubject" then return "testsubject" end
	if teamKey == "PMC" then return "pmc" end

	local teamData = teamKey and USARFConfig.Teams[teamKey]
	local category = teamData and normalize(teamData.category) or ""
	if category == "civil" or category == "combative" or category == "intelligence" or category == "government" or category == "leadership" then
		return "facility"
	end
	return "other"
end

function CombatRulesService.GetMode()
	return currentMode
end

function CombatRulesService.SetMode(mode)
	mode = normalize(mode)
	if not VALID_MODES[mode] then
		return false, "Mode must be default or unrestricted."
	end
	currentMode = mode
	workspace:SetAttribute("USARF_CombatRulesMode", currentMode)
	return true, currentMode
end

function CombatRulesService.CanDamage(attacker, target)
	if not attacker or not target then return true, "non_player_target" end
	if attacker == target then return false, "self_damage_blocked" end
	if currentMode == "unrestricted" then return true, "unrestricted" end

	local attackerClass = classify(attacker)
	local targetClass = classify(target)

	if attackerClass == "testsubject" then
		return targetClass ~= "pmc", targetClass == "pmc" and "test_subject_cannot_damage_pmc" or "default_allowed"
	elseif attackerClass == "pmc" then
		return targetClass ~= "pmc", targetClass == "pmc" and "pmc_friendly_fire_blocked" or "default_allowed"
	elseif attackerClass == "facility" then
		return targetClass ~= "facility", targetClass == "facility" and "facility_friendly_fire_blocked" or "default_allowed"
	end

	if attacker.Team and target.Team and attacker.Team == target.Team then
		return false, "same_team_blocked"
	end
	return true, "fallback_allowed"
end

function CombatRulesService.GetStatusText()
	if currentMode == "unrestricted" then
		return "Current Combat Rules\n\nMode: UNRESTRICTED\n\nAll players may damage all other players.\nSelf-damage remains blocked."
	end
	return table.concat({
		"Current Combat Rules", "", "Mode: DEFAULT", "",
		"Test Subject", "  Test Subject: ALLOWED", "  PMC: BLOCKED", "  Facility: ALLOWED", "",
		"PMC", "  Test Subject: ALLOWED", "  PMC: BLOCKED", "  Facility: ALLOWED", "",
		"Facility / Security", "  Test Subject: ALLOWED", "  PMC: ALLOWED", "  Facility / Security: BLOCKED",
	}, "\n")
end

CombatRulesService.SetMode("default")
return CombatRulesService