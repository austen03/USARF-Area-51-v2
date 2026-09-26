local CATEGORY_ORDER = {
	["Facility"] = 1,
	["Nuclear Command"] = 2,
	["Announcements"] = 3,
	["System"] = 4,
	["General"] = 5,
}

local CATEGORY_TITLES = {
	["Facility"] = "FACILITY COMMANDS",
	["Nuclear Command"] = "NUCLEAR COMMAND",
	["Announcements"] = "ANNOUNCEMENTS",
	["System"] = "SYSTEM COMMANDS",
	["General"] = "GENERAL COMMANDS",
}

local function getCategoryOrder(category)
	return CATEGORY_ORDER[category] or 999
end

local function buildCommandHelp(command)
	local lines = {}

	table.insert(lines, string.upper(command.Name))
	table.insert(lines, "")
	table.insert(lines, "Description")
	table.insert(lines, "-----------")
	table.insert(lines, command.Description or "No description.")
	table.insert(lines, "")
	table.insert(lines, "Usage")
	table.insert(lines, "-----")
	table.insert(lines, command.Usage or command.Name)
	table.insert(lines, "")
	table.insert(lines, "Permission")
	table.insert(lines, "----------")

	if command.PermissionLevel then
		table.insert(lines, tostring(command.PermissionLevel))
	elseif command.MinRank then
		table.insert(lines, "Minimum group rank " .. tostring(command.MinRank))
	else
		table.insert(lines, "None")
	end

	if command.Aliases and #command.Aliases > 0 then
		table.insert(lines, "")
		table.insert(lines, "Aliases")
		table.insert(lines, "-------")
		table.insert(lines, table.concat(command.Aliases, ", "))
	end

	if command.Examples and #command.Examples > 0 then
		table.insert(lines, "")
		table.insert(lines, "Examples")
		table.insert(lines, "--------")

		for _, example in ipairs(command.Examples) do
			table.insert(lines, example)
		end
	end

	return table.concat(lines, "\n")
end

local function buildGeneralHelp(context)
	local categories = {}

	for _, command in ipairs(context.Registry.GetAll()) do
		local canRun = context.Registry.CanRun(context.Player, command)

		if canRun then
			local category = command.Category or "General"

			if not categories[category] then
				categories[category] = {}
			end

			table.insert(categories[category], command)
		end
	end

	local categoryNames = {}

	for category in pairs(categories) do
		table.insert(categoryNames, category)
	end

	table.sort(categoryNames, function(a, b)
		local orderA = getCategoryOrder(a)
		local orderB = getCategoryOrder(b)

		if orderA == orderB then
			return a < b
		end

		return orderA < orderB
	end)

	local lines = {}

	table.insert(lines, "FACILITYOS HELP")
	table.insert(lines, "===============")
	table.insert(lines, "")

	for _, category in ipairs(categoryNames) do
		table.sort(categories[category], function(a, b)
			return a.Name < b.Name
		end)

		local title = CATEGORY_TITLES[category] or string.upper(category)

		table.insert(lines, title)
		table.insert(lines, string.rep("-", #title))

		for _, command in ipairs(categories[category]) do
			table.insert(lines, command.Name .. " - " .. tostring(command.Description or "No description."))
		end

		table.insert(lines, "")
	end

	table.insert(lines, "Type help [command] for details.")
	table.insert(lines, "Example: help lockdown")

	return table.concat(lines, "\n")
end

return {
	Name = "help",
	Aliases = { "commands", "cmds", "?" },
	Description = "Displays terminal commands or detailed help for one command.",
	Usage = "help [command]",
	Category = "System",
	MinRank = 3,
	Examples = {
		"help",
		"help lockdown",
		"help nuke",
	},

	Run = function(context, args)
		local requested = args[2]

		if requested then
			local command = context.Registry.Get(requested)

			if not command then
				return {
					Type = "Error",
					Message = "No help page found for command: " .. tostring(requested),
				}
			end

			local canRun = context.Registry.CanRun(context.Player, command)

			if not canRun then
				return {
					Type = "Error",
					Message = "Access denied for help page: " .. tostring(requested),
				}
			end

			return {
				Type = "Info",
				Message = buildCommandHelp(command),
			}
		end

		return {
			Type = "Info",
			Message = buildGeneralHelp(context),
		}
	end,
}