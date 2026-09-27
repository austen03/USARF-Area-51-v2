local ServerStorage = game:GetService("ServerStorage")

local CANDIDATE_NAMES = {
	["f3x"] = true,
	["building tools"] = true,
	["buildingtools"] = true,
	["building tool"] = true,
}

local function lower(value)
	return string.lower(tostring(value or ""))
end

local function alreadyHasTool(player, toolName)
	local backpack = player:FindFirstChildOfClass("Backpack")
		or player:FindFirstChild("Backpack")
	local character = player.Character

	return (backpack and backpack:FindFirstChild(toolName) ~= nil)
		or (character and character:FindFirstChild(toolName) ~= nil)
end

local function collectToolsFrom(instance)
	local tools = {}

	if instance:IsA("Tool") then
		table.insert(tools, instance)
		return tools
	end

	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("Tool") then
			table.insert(tools, descendant)
		end
	end

	return tools
end

local function findApprovedSource(developerFolder)
	for _, descendant in ipairs(developerFolder:GetDescendants()) do
		if CANDIDATE_NAMES[lower(descendant.Name)] then
			return descendant
		end
	end

	if CANDIDATE_NAMES[lower(developerFolder.Name)] then
		return developerFolder
	end

	local allTools = collectToolsFrom(developerFolder)

	if #allTools == 1 then
		return allTools[1]
	end

	return nil
end

return function(context)
	local executor = context.Executor

	if not executor or not executor.Parent then
		return "Unable to locate the command executor."
	end

	local developerFolder = ServerStorage:FindFirstChild("Developer")

	if not developerFolder then
		return "ServerStorage.Developer was not found."
	end

	local source = findApprovedSource(developerFolder)

	if not source then
		return "Could not find F3X or Building Tools inside ServerStorage.Developer."
	end

	local tools = collectToolsFrom(source)

	if #tools == 0 then
		return "The approved F3X source contains no Tool instances."
	end

	local backpack = executor:FindFirstChildOfClass("Backpack")
		or executor:FindFirstChild("Backpack")

	if not backpack then
		return "Your Backpack is not ready."
	end

	local given = 0
	local skipped = 0

	for _, tool in ipairs(tools) do
		if alreadyHasTool(executor, tool.Name) then
			skipped += 1
		else
			local clone = tool:Clone()
			clone.Parent = backpack
			given += 1
		end
	end

	if given == 0 then
		return "You already have the approved F3X building tools."
	end

	if skipped > 0 then
		return string.format(
			"Given %d F3X tool(s). Skipped %d duplicate tool(s).",
			given,
			skipped
		)
	end

	return string.format("Given %d F3X building tool(s).", given)
end
