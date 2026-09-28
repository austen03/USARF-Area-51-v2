local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UniformLoadoutIndex = require(
	ReplicatedStorage:WaitForChild("USARF"):WaitForChild("Shared"):WaitForChild("UniformLoadoutIndex")
)

local ACTIONS = {
	"setDivision",
	"setClass",
	"setSubClass",
	"clear",
	"clearClass",
	"clearSubClass",
	"default",
	"apply",
}

local function clean(value)
	return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function findOption(options, text)
	local query = string.lower(clean(text))

	for _, option in ipairs(options) do
		if string.lower(option) == query then
			return option
		end
	end

	return nil
end

local function getMatches(options, text)
	local query = string.lower(clean(text))
	local results = {}

	for _, option in ipairs(options) do
		if query == "" or string.sub(string.lower(option), 1, #query) == query then
			table.insert(results, option)
		end
	end

	for _, option in ipairs(options) do
		if not table.find(results, option) and string.find(string.lower(option), query, 1, true) then
			table.insert(results, option)
		end
	end

	return results
end

-- Inline Cmdr type over a list of names; getOptions is re-read on every keystroke
-- so the dropdown always reflects the published morph index.
local function makeChoiceType(displayName, getOptions, invalidMessage)
	return {
		DisplayName = displayName,

		Transform = function(text)
			return clean(text)
		end,

		Validate = function(text)
			if findOption(getOptions(), text) then
				return true
			end

			return false, invalidMessage
		end,

		Autocomplete = function(text)
			return getMatches(getOptions(), text)
		end,

		Parse = function(text)
			return findOption(getOptions(), text)
		end,
	}
end

local actionType = makeChoiceType("LoadoutAction", function()
	return ACTIONS
end, "Unknown loadout action.")

local divisionType = makeChoiceType("LoadoutDivision", UniformLoadoutIndex.GetDivisions, "Unknown division.")

local function getAction(context)
	local argument = context:GetArgument(2)
	return if argument then findOption(ACTIONS, argument.RawValue) else nil
end

-- The division the first target player is wearing (set by UniformService), which
-- is where setClass and setSubClass look for their morphs.
local function getTargetDivision(context)
	local argument = context:GetArgument(1)

	if not argument then
		return nil
	end

	local success, players = pcall(function()
		return argument:GetValue()
	end)

	local target = if success and typeof(players) == "table" then players[1] else nil
	return if typeof(target) == "Instance" then target:GetAttribute("USARF_UniformDivision") else nil
end

local function makeClassType(displayName, division, getNames)
	return makeChoiceType(displayName, function()
		return getNames(division)
	end, if division then `Not found in {division}.` else "That player has no division; use setDivision first.")
end

return {
	Name = "loadout",
	Aliases = {},
	Description = "Sets a player's division, class uniform and sub class morphs.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "players",
			Name = "players",
			Description = "Player(s) to change.",
		},
		{
			Type = actionType,
			Name = "action",
			Description = "The action to perform.",
		},

		-- The remaining arguments depend on the chosen action.
		function(context)
			local action = getAction(context)

			if action == "setDivision" then
				return { Type = divisionType, Name = "division", Description = "The division to wear." }
			elseif action == "setClass" then
				local division = getTargetDivision(context)

				return {
					Type = makeClassType("LoadoutClass", division, UniformLoadoutIndex.GetClasses),
					Name = "class",
					Description = if division then `The {division} class to wear.` else "The class to wear.",
				}
			elseif action == "setSubClass" then
				local division = getTargetDivision(context)

				return {
					Type = makeClassType("LoadoutSubClass", division, UniformLoadoutIndex.GetSubClasses),
					Name = "subClass",
					Description = if division then `The {division} sub class to wear.` else "The sub class to wear.",
				}
			end

			return nil
		end,

		-- setDivision can also pick the class; left out, the wearer's rank decides it.
		function(context)
			if getAction(context) ~= "setDivision" then
				return nil
			end

			local divisionArgument = context:GetArgument(3)
			local division = if divisionArgument
				then findOption(UniformLoadoutIndex.GetDivisions(), divisionArgument.RawValue)
				else nil

			return {
				Type = makeClassType("LoadoutClass", division, UniformLoadoutIndex.GetClasses),
				Name = "class",
				Description = if division
					then `The {division} class to wear (default: by rank).`
					else "The class to wear (default: by rank).",
				Optional = true,
			}
		end,
	},
}
