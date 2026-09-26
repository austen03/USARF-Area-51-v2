local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function clean(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function lower(value)
	return string.lower(clean(value))
end

local function startsWith(value, query)
	value = lower(value)
	query = lower(query)

	return query == "" or string.sub(value, 1, #query) == query
end

local function contains(value, query)
	value = lower(value)
	query = lower(query)

	return query == "" or string.find(value, query, 1, true) ~= nil
end

local function getSharedToolNamesFolder()
	local USARF = ReplicatedStorage:FindFirstChild("USARF")
	if not USARF then
		return nil
	end

	local Shared = USARF:FindFirstChild("Shared")
	if not Shared then
		return nil
	end

	return Shared:FindFirstChild("CmdrToolNames")
end

local function getToolNames()
	local names = {}
	local seen = {}

	local sharedFolder = getSharedToolNamesFolder()

	if sharedFolder then
		for _, child in ipairs(sharedFolder:GetChildren()) do
			if child:IsA("StringValue") and child.Value ~= "" and not seen[child.Value] then
				seen[child.Value] = true
				table.insert(names, child.Value)
			end
		end
	end

	table.sort(names)
	return names
end

local function getToolMatches(text)
	text = clean(text)

	local names = getToolNames()
	local results = {}
	local used = {}

	for _, name in ipairs(names) do
		if startsWith(name, text) then
			used[name] = true
			table.insert(results, name)
		end
	end

	for _, name in ipairs(names) do
		if not used[name] and contains(name, text) then
			used[name] = true
			table.insert(results, name)
		end
	end

	return results
end

local function findTool(toolName)
	if RunService:IsClient() then
		local wanted = lower(toolName)

		for _, name in ipairs(getToolNames()) do
			if lower(name) == wanted then
				return name
			end
		end

		for _, name in ipairs(getToolNames()) do
			if string.find(lower(name), wanted, 1, true) then
				return name
			end
		end

		return nil
	end

	local toolsFolder = ServerStorage:FindFirstChild("Tools")
	if not toolsFolder then
		return nil
	end

	local wanted = lower(toolName)
	local partialMatch = nil

	for _, descendant in ipairs(toolsFolder:GetDescendants()) do
		if descendant:IsA("Tool") then
			local toolLower = lower(descendant.Name)

			if toolLower == wanted then
				return descendant
			end

			if not partialMatch and string.find(toolLower, wanted, 1, true) then
				partialMatch = descendant
			end
		end
	end

	return partialMatch
end

return function(registry)
	registry:RegisterType("tool", {
		Transform = function(text)
			return clean(text)
		end,

		Validate = function(text)
			if findTool(text) then
				return true
			end

			return false, "Invalid tool."
		end,

		Autocomplete = function(text)
			return getToolMatches(text)
		end,

		Parse = function(text)
			return findTool(text)
		end,
	})
end