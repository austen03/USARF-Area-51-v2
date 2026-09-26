local Teams = game:GetService("Teams")

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

local function getTeamNames()
	local names = {}

	for _, team in ipairs(Teams:GetTeams()) do
		table.insert(names, team.Name)
	end

	table.sort(names)
	return names
end

local function findTeamName(text)
	local query = lower(text)

	for _, team in ipairs(Teams:GetTeams()) do
		if lower(team.Name) == query then
			return team.Name
		end
	end

	return nil
end

local function getTeamMatches(text)
	text = clean(text)

	local names = getTeamNames()
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

return function(registry)
	registry:RegisterType("teamName", {
		Transform = function(text)
			return clean(text)
		end,

		Validate = function(text)
			text = clean(text)

			if text == "" then
				return true
			end

			if findTeamName(text) then
				return true
			end

			return false, "Invalid team name."
		end,

		Autocomplete = function(text)
			return getTeamMatches(text)
		end,

		Parse = function(text)
			text = clean(text)

			if text == "" then
				return nil
			end

			return findTeamName(text)
		end,
	})
end