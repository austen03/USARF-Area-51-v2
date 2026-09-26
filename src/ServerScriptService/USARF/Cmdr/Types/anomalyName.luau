local Workspace = game:GetService("Workspace")

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

local function isAnomalyModel(model)
	if not model:IsA("Model") then
		return false
	end

	if string.match(model.Name, "^EE%-") then
		return true
	end

	if model:FindFirstChild("SpawnPos", true) then
		return true
	end

	return false
end

local function getAnomalyModels()
	local names = {}
	local seen = {}

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if isAnomalyModel(descendant) and not seen[descendant.Name] then
			seen[descendant.Name] = true
			table.insert(names, descendant.Name)
		end
	end

	table.sort(names)
	return names
end

local function getAnomalyMatches(text)
	text = clean(text)

	local names = getAnomalyModels()
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

local function findAnomaly(text)
	local wanted = lower(text)

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if isAnomalyModel(descendant) and lower(descendant.Name) == wanted then
			return descendant
		end
	end

	return nil
end

return function(registry)
	registry:RegisterType("anomalyName", {
		Transform = function(text)
			return clean(text)
		end,

		Validate = function(text)
			if findAnomaly(text) then
				return true
			end

			return false, "Invalid anomaly name."
		end,

		Autocomplete = function(text)
			return getAnomalyMatches(text)
		end,

		Parse = function(text)
			local model = findAnomaly(text)
			return model and model.Name or clean(text)
		end,
	})
end