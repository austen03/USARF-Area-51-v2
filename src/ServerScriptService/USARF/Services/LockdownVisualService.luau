local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LockdownVisualService = {}

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")
local Shared = USARF:WaitForChild("Shared")

local LockdownVisualConfig = require(Config:WaitForChild("LockdownVisualConfig"))

local FacilityState = Shared:WaitForChild("FacilityState")
local LockdownLevelValue = FacilityState:WaitForChild("LockdownLevel")

local started = false
local flashingToken = 0

local function isLightPart(part)
	local name = part.Name:lower()

	return name:find("light") or name:find("lamp") or name:find("bulb") or part.Material == Enum.Material.Neon
end

local function getLightsFromModel(model)
	local lights = {}

	if model:IsA("PointLight") or model:IsA("SpotLight") or model:IsA("SurfaceLight") then
		table.insert(lights, model)
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
			table.insert(lights, descendant)
		end
	end

	return lights
end

local function getLightPartsFromModel(model)
	local parts = {}

	if model:IsA("BasePart") and isLightPart(model) then
		table.insert(parts, model)
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and isLightPart(descendant) then
			table.insert(parts, descendant)
		end
	end

	return parts
end

local RANGE_SCALE_ATTRIBUTE = "USARF_RangeScale"
local BRIGHTNESS_SCALE_ATTRIBUTE = "USARF_BrightnessScale"

local function getFixtureScales(model)
	local rangeScale = model:GetAttribute(RANGE_SCALE_ATTRIBUTE)
	local brightnessScale = model:GetAttribute(BRIGHTNESS_SCALE_ATTRIBUTE)
	return (typeof(rangeScale) == "number" and rangeScale) or 1,
		(typeof(brightnessScale) == "number" and brightnessScale) or 1
end

local function applyLightModel(model, color, brightness, range, enabled, partTransparency)
	local rangeScale, brightnessScale = getFixtureScales(model)
	local scaledBrightness = (brightness or 0) * brightnessScale
	local scaledRange = (range or 0) * rangeScale

	for _, part in ipairs(getLightPartsFromModel(model)) do
		part.Material = Enum.Material.Neon
		part.Color = color
		part.Transparency = partTransparency or 0
	end

	for _, light in ipairs(getLightsFromModel(model)) do
		light.Enabled = enabled == true
		light.Color = color
		light.Brightness = scaledBrightness
		light.Range = scaledRange

		if light:IsA("PointLight") then
			light.Shadows = false
		end
	end
end

local function isOwnedByDefconPanel(model)
	if CollectionService:HasTag(model, LockdownVisualConfig.DefconTag) then
		return true
	end

	local ancestor = model.Parent
	while ancestor do
		if CollectionService:HasTag(ancestor, LockdownVisualConfig.DefconTag) then
			return true
		end
		ancestor = ancestor.Parent
	end

	return false
end

local function applyAmbient(levelInfo)
	for _, model in ipairs(CollectionService:GetTagged(LockdownVisualConfig.AmbientLightTag)) do
		if not isOwnedByDefconPanel(model) then
			applyLightModel(model, levelInfo.AmbientColor, levelInfo.AmbientBrightness, levelInfo.AmbientRange, true, 0)
		end
	end
end

local EMERGENCY_IDLE_BRIGHTNESS_DROP = 0.15
local EMERGENCY_IDLE_MIN_BRIGHTNESS = 0.1

local function applyEmergency(levelInfo, enabledOverride)
	local enabled = enabledOverride

	if enabled == nil then
		enabled = levelInfo.EmergencyEnabled == true
	end

	local color, brightness, range, transparency

	if enabled then
		color = levelInfo.EmergencyColor
		brightness = levelInfo.EmergencyBrightness
		range = levelInfo.EmergencyRange
		transparency = 0
	else
		color = levelInfo.AmbientColor
		brightness =
			math.max(EMERGENCY_IDLE_MIN_BRIGHTNESS, (levelInfo.AmbientBrightness or 0) - EMERGENCY_IDLE_BRIGHTNESS_DROP)
		range = levelInfo.AmbientRange
		transparency = 0
	end

	for _, model in ipairs(CollectionService:GetTagged(LockdownVisualConfig.EmergencyLightTag)) do
		if not isOwnedByDefconPanel(model) then
			applyLightModel(model, color, brightness, range, true, transparency)
		end
	end
end

local DEFCON_LAMP_BRIGHTNESS = 0.6
local DEFCON_LAMP_RANGE = 6

local DEFCON_LAMP_COLORS = {
	[5] = Color3.fromRGB(33, 84, 185),
	[4] = Color3.fromRGB(39, 70, 45),
	[3] = Color3.fromRGB(193, 190, 66),
	[2] = Color3.fromRGB(196, 40, 28),
	[1] = Color3.fromRGB(242, 243, 243),
}

local function setDefconPanel(defconNumber)
	for _, panel in ipairs(CollectionService:GetTagged(LockdownVisualConfig.DefconTag)) do
		for _, descendant in ipairs(panel:GetDescendants()) do
			if descendant:IsA("BasePart") then
				local number = tonumber(descendant.Name)

				if number then
					local lampColor = DEFCON_LAMP_COLORS[number]
					if lampColor then
						descendant.Color = lampColor
					end

					if number == defconNumber then
						descendant.Material = Enum.Material.Neon
						descendant.Transparency = 0
					else
						descendant.Material = Enum.Material.SmoothPlastic
						descendant.Transparency = 0.25
					end
				end
			elseif descendant:IsA("TextLabel") then
				local number = tonumber(descendant.Name) or tonumber(descendant.Text)

				if number then
					descendant.TextTransparency = number == defconNumber and 0 or 0.45
				end
			elseif descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
				local parent = descendant.Parent
				local number = parent and tonumber(parent.Name)

				if number then
					local isActive = number == defconNumber
					local lampColor = DEFCON_LAMP_COLORS[number]

					descendant.Enabled = isActive
					if lampColor then
						descendant.Color = lampColor
					end
					descendant.Brightness = isActive and DEFCON_LAMP_BRIGHTNESS or 0
					descendant.Range = isActive and DEFCON_LAMP_RANGE or 0

					if descendant:IsA("PointLight") then
						descendant.Shadows = false
					end
				end
			end
		end
	end
end

local function startEmergencyFlashing(levelInfo)
	flashingToken += 1
	local token = flashingToken

	task.spawn(function()
		local on = true
		local speed = levelInfo.FlashSpeed or 0.5
		local offTransparency = levelInfo.EmergencyOffTransparency or 0.65

		while token == flashingToken and levelInfo.Flashing do
			for _, model in ipairs(CollectionService:GetTagged(LockdownVisualConfig.EmergencyLightTag)) do
				local rangeScale, brightnessScale = getFixtureScales(model)

				for _, part in ipairs(getLightPartsFromModel(model)) do
					part.Material = Enum.Material.Neon
					part.Color = levelInfo.EmergencyColor
					part.Transparency = on and 0 or offTransparency
				end

				for _, light in ipairs(getLightsFromModel(model)) do
					light.Enabled = on
					light.Color = levelInfo.EmergencyColor
					light.Brightness = (levelInfo.EmergencyBrightness or 2) * brightnessScale
					light.Range = (levelInfo.EmergencyRange or 20) * rangeScale
				end
			end

			on = not on
			task.wait(speed)
		end
	end)
end

function LockdownVisualService.ApplyLevel(level)
	level = tonumber(level) or 0

	local levelInfo = LockdownVisualConfig.Levels[level] or LockdownVisualConfig.Levels[0]

	flashingToken += 1

	applyAmbient(levelInfo)
	applyEmergency(levelInfo)

	setDefconPanel(levelInfo.Defcon or 5)

	if levelInfo.Flashing and levelInfo.EmergencyEnabled then
		startEmergencyFlashing(levelInfo)
	end

	print("[LockdownVisualService] Applied lockdown visuals level", level)
end

function LockdownVisualService.Start()
	if started then
		return
	end

	started = true

	LockdownLevelValue.Changed:Connect(function()
		LockdownVisualService.ApplyLevel(LockdownLevelValue.Value)
	end)

	LockdownVisualService.ApplyLevel(LockdownLevelValue.Value)

	print("[LockdownVisualService] Started")
end

return LockdownVisualService
