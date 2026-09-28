local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityAnnouncementService = nil
pcall(function()
	FacilityAnnouncementService = require(Services:WaitForChild("FacilityAnnouncementService"))
end)

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

local function clean(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function lower(value)
	return string.lower(clean(value))
end

local function findEntity(entityName)
	local wanted = lower(entityName)

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") and lower(descendant.Name) == wanted then
			return descendant
		end
	end

	return nil
end

local function getBreachNodes()
	local map = Workspace:FindFirstChild("Map")
	local breachNodesFolder = map and map:FindFirstChild("BreachNodes")

	if not breachNodesFolder then
		return {}
	end

	local nodes = {}

	for _, child in ipairs(breachNodesFolder:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(nodes, child)
		end
	end

	return nodes
end

local function getRandomBreachNode()
	local nodes = getBreachNodes()

	if #nodes <= 0 then
		return nil
	end

	return nodes[math.random(1, #nodes)]
end

local function setEntityBreached(entity)
	entity:SetAttribute("USARF_Breached", true)
	entity:SetAttribute("USARF_BreachedAt", os.time())

	local breachedValue = entity:FindFirstChild("Breached", true)
	if breachedValue and breachedValue:IsA("BoolValue") then
		breachedValue.Value = true
	end

	local autoBreach = entity:FindFirstChild("Auto Breach", true)
	if autoBreach then
		if autoBreach:IsA("BoolValue") then
			autoBreach.Value = true
		elseif autoBreach:IsA("Script") or autoBreach:IsA("LocalScript") then
			autoBreach.Disabled = false
		end
	end
end

local function moveEntityToRandomBreachNode(entity)
	local node = getRandomBreachNode()

	if not node then
		return false, nil
	end

	entity:PivotTo(node.CFrame + Vector3.new(0, 3, 0))
	return true, node
end

return function(context, entityName)
	entityName = clean(entityName)

	if entityName == "" then
		return "Missing entity name."
	end

	local entity = findEntity(entityName)

	if not entity then
		return "Could not find entity: " .. entityName
	end

	setEntityBreached(entity)

	local moved, node = moveEntityToRandomBreachNode(entity)
	local message = entity.Name .. " containment breach initiated."

	if FacilityAnnouncementService and typeof(FacilityAnnouncementService.PlayEvent) == "function" then
		FacilityAnnouncementService.PlayEvent("Breach")
	end

	if FacilityStatusService and typeof(FacilityStatusService.SetLastEvent) == "function" then
		FacilityStatusService.SetLastEvent("Entity Breach: " .. entity.Name)
	end

	if RadioService and typeof(RadioService.System) == "function" then
		RadioService.System("alerts", "[ENTITY BREACH] " .. message)
	end

	if AuditService and typeof(AuditService.Log) == "function" then
		AuditService.Log({
			category = "Facility",
			action = "EntityBreach",
			actor = context.Executor,
			message = message,
			severity = "Emergency",
			metadata = {
				entityName = entity.Name,
				movedToBreachNode = moved,
				breachNode = node and node:GetFullName() or nil,
			},
		})
	end

	if moved then
		return "Breach initiated for " .. entity.Name .. " at " .. node.Name .. "."
	end

	return "Breach initiated for " .. entity.Name .. ". No breach nodes found."
end
