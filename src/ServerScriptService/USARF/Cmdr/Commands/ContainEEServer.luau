local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityStatusService = nil
pcall(function()
	FacilityStatusService = require(Services:WaitForChild("FacilityStatusService"))
end)

local RadioService = nil
pcall(function()
	RadioService = require(Services:WaitForChild("RadioService"))
end)

local AuditService = nil
pcall(function()
	AuditService = require(Services:WaitForChild("AuditService"))
end)

local originalSpawnCFrames = {}

local function clean(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function lower(value)
	return string.lower(clean(value))
end

local function getModelKey(model)
	return model:GetFullName()
end

local function findMovableEntity(entityName)
	local wanted = lower(entityName)

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") and lower(descendant.Name) == wanted then
			return descendant
		end
	end

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") and lower(descendant.Name) == wanted then
			return descendant
		end
	end

	return nil
end

local function getSpawnPart(entity)
	local spawnPart = entity:FindFirstChild("SpawnPos", true)

	if spawnPart and spawnPart:IsA("BasePart") then
		return spawnPart
	end

	return nil
end

local function cacheOriginalSpawn(entity)
	local spawnPart = getSpawnPart(entity)

	if not spawnPart then
		return nil
	end

	local key = getModelKey(entity)

	if not originalSpawnCFrames[key] then
		originalSpawnCFrames[key] = spawnPart.CFrame
	end

	return originalSpawnCFrames[key]
end

local function cacheAllOriginalSpawns()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") and string.match(descendant.Name, "^EE%-") then
			cacheOriginalSpawn(descendant)
		end
	end
end

local function setContained(entity)
	entity:SetAttribute("USARF_Breached", false)
	entity:SetAttribute("USARF_ContainedAt", os.time())

	local breachedValue = entity:FindFirstChild("Breached", true)
	if breachedValue and breachedValue:IsA("BoolValue") then
		breachedValue.Value = false
	end

	local autoBreach = entity:FindFirstChild("Auto Breach", true)
	if autoBreach and autoBreach:IsA("BoolValue") then
		autoBreach.Value = false
	end
end

cacheAllOriginalSpawns()

return function(context, entityName)
	entityName = clean(entityName)

	if entityName == "" then
		return "Missing entity name."
	end

	local entity = findMovableEntity(entityName)

	if not entity then
		return "Could not find entity: " .. entityName
	end

	local spawnPart = getSpawnPart(entity)

	if not spawnPart then
		return entity.Name .. " has no SpawnPos."
	end

	local originalSpawnCFrame = originalSpawnCFrames[getModelKey(entity)] or spawnPart.CFrame
	originalSpawnCFrames[getModelKey(entity)] = originalSpawnCFrame

	setContained(entity)

	entity:PivotTo(originalSpawnCFrame + Vector3.new(0, 3, 0))

	task.defer(function()
		if spawnPart and spawnPart.Parent then
			spawnPart.CFrame = originalSpawnCFrame
		end
	end)

	local message = entity.Name .. " has been contained."

	if FacilityStatusService and typeof(FacilityStatusService.SetLastEvent) == "function" then
		FacilityStatusService.SetLastEvent("Entity Contained: " .. entity.Name)
	end

	if RadioService and typeof(RadioService.System) == "function" then
		RadioService.System("alerts", "[ENTITY CONTAINED] " .. message)
	end

	if AuditService and typeof(AuditService.Log) == "function" then
		AuditService.Log({
			category = "Facility",
			action = "EntityContained",
			actor = context.Executor,
			message = message,
			severity = "Info",
			metadata = {
				entityName = entity.Name,
				spawnPos = spawnPart:GetFullName(),
			},
		})
	end

	return "Contained " .. entity.Name .. "."
end
