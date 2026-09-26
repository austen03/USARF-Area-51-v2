local WeaponAttachmentResolver = {}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}

	for key, childValue in pairs(value) do
		copy[key] = deepCopy(childValue)
	end

	return copy
end

local function addNumber(config, key, amount)
	if type(amount) ~= "number" then
		return
	end

	config[key] = (config[key] or 0) + amount
end

local function multiplyNumber(config, key, multiplier)
	if type(multiplier) ~= "number" then
		return
	end

	config[key] = (config[key] or 0) * multiplier
end

local function addNestedNumber(config, sectionName, key, amount)
	if type(amount) ~= "number" then
		return
	end

	config[sectionName] = config[sectionName] or {}
	config[sectionName][key] = (config[sectionName][key] or 0) + amount
end

local function multiplyNestedNumber(config, sectionName, key, multiplier)
	if type(multiplier) ~= "number" then
		return
	end

	config[sectionName] = config[sectionName] or {}
	config[sectionName][key] = (config[sectionName][key] or 0) * multiplier
end

local function applyModifier(config, modifier)
	if type(modifier) ~= "table" then
		return
	end

	if modifier.DamageAdd then
		addNumber(config, "Damage", modifier.DamageAdd)
	end

	if modifier.DamageMultiplier then
		multiplyNumber(config, "Damage", modifier.DamageMultiplier)
	end

	if modifier.RangeAdd then
		addNumber(config, "Range", modifier.RangeAdd)
	end

	if modifier.RangeMultiplier then
		multiplyNumber(config, "Range", modifier.RangeMultiplier)
	end

	if modifier.SpreadAdd then
		addNumber(config, "Spread", modifier.SpreadAdd)
	end

	if modifier.SpreadMultiplier then
		multiplyNumber(config, "Spread", modifier.SpreadMultiplier)
	end

	if modifier.FireRateAdd then
		addNumber(config, "FireRate", modifier.FireRateAdd)
	end

	if modifier.FireRateMultiplier then
		multiplyNumber(config, "FireRate", modifier.FireRateMultiplier)
	end

	if modifier.MagazineSizeAdd then
		addNumber(config, "MagazineSize", modifier.MagazineSizeAdd)
	end

	if modifier.MagazineSizeMultiplier then
		multiplyNumber(config, "MagazineSize", modifier.MagazineSizeMultiplier)
	end

	if modifier.ReserveAmmoAdd then
		addNumber(config, "ReserveAmmo", modifier.ReserveAmmoAdd)
	end

	if modifier.ReserveAmmoMultiplier then
		multiplyNumber(config, "ReserveAmmo", modifier.ReserveAmmoMultiplier)
	end

	if modifier.ReloadTimeAdd then
		addNumber(config, "ReloadTime", modifier.ReloadTimeAdd)
	end

	if modifier.ReloadTimeMultiplier then
		multiplyNumber(config, "ReloadTime", modifier.ReloadTimeMultiplier)
	end

	if modifier.RecoilVerticalMultiplier then
		multiplyNestedNumber(config, "Recoil", "Vertical", modifier.RecoilVerticalMultiplier)
	end

	if modifier.RecoilHorizontalMultiplier then
		multiplyNestedNumber(config, "Recoil", "Horizontal", modifier.RecoilHorizontalMultiplier)
	end

	if modifier.RecoilRecoveryMultiplier then
		multiplyNestedNumber(config, "Recoil", "Recovery", modifier.RecoilRecoveryMultiplier)
	end

	if modifier.ADSFOVAdd then
		addNestedNumber(config, "ADS", "FOV", modifier.ADSFOVAdd)
	end

	if modifier.ADSSpreadMultiplier then
		multiplyNestedNumber(config, "ADS", "SpreadMultiplier", modifier.ADSSpreadMultiplier)
	end

	if modifier.ADSRecoilMultiplier then
		multiplyNestedNumber(config, "ADS", "RecoilMultiplier", modifier.ADSRecoilMultiplier)
	end

	if modifier.SoundOverrides then
		for soundKey, soundName in pairs(modifier.SoundOverrides) do
			config[soundKey] = soundName
		end
	end

	if modifier.Flags then
		config.AttachmentFlags = config.AttachmentFlags or {}

		for flagName, flagValue in pairs(modifier.Flags) do
			config.AttachmentFlags[flagName] = flagValue
		end
	end
end

function WeaponAttachmentResolver.Resolve(baseConfig)
	local resolved = deepCopy(baseConfig or {})

	local equippedAttachments = baseConfig.Attachments or {}
	local definitions = baseConfig.AttachmentDefinitions or {}

	resolved.ActiveAttachments = {}

	for slotName, attachmentName in pairs(equippedAttachments) do
		if attachmentName ~= nil and attachmentName ~= "" then
			local definition = definitions[attachmentName]

			if definition then
				resolved.ActiveAttachments[slotName] = {
					Name = attachmentName,
					DisplayName = definition.DisplayName or attachmentName,
					Slot = slotName,
				}

				applyModifier(resolved, definition.Modifiers)
			end
		end
	end

	resolved.MagazineSize = math.max(1, math.floor(resolved.MagazineSize or 1))
	resolved.ReserveAmmo = math.max(0, math.floor(resolved.ReserveAmmo or 0))
	resolved.FireRate = math.max(1, resolved.FireRate or 600)
	resolved.ReloadTime = math.max(0.1, resolved.ReloadTime or 2)

	return resolved
end

return WeaponAttachmentResolver