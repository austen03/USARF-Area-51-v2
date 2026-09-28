local ServerScriptService = game:GetService("ServerScriptService")

local Cmdr = require(ServerScriptService:WaitForChild("Cmdr"))

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")
local Config = USARFServer:WaitForChild("Config")

local CmdrPermissionService = require(
	Services:WaitForChild("CmdrPermissionService")
)

local CmdrAdminConfig = require(
	Config:WaitForChild("CmdrAdminConfig")
)

local GROUP_ORDER = {
	"Training",
	"VPOTUS | POTUS",
	"Moderator",
	"Administrator",
	"Developer",
	"Owner",
}

local GROUP_LOOKUP = {}

for _, groupName in ipairs(GROUP_ORDER) do
	GROUP_LOOKUP[groupName] = true
end

local function clean(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function lower(value)
	return string.lower(clean(value))
end

local function getConfiguredCommand(commandName)
	local commandsConfig = CmdrAdminConfig.Commands or {}
	local normalizedName = lower(commandName)

	for configuredName, commandConfig in pairs(commandsConfig) do
		if lower(configuredName) == normalizedName then
			return commandConfig, configuredName
		end
	end

	return commandsConfig.Default, "Default"
end

local function getDisplayGroup(commandName)
	local commandConfig = getConfiguredCommand(commandName)

	if type(commandConfig) ~= "table" then
		return "Moderator"
	end

	local displayGroup = clean(commandConfig.DisplayGroup)

	if displayGroup == "" then
		displayGroup = "Moderator"
	end

	if not GROUP_LOOKUP[displayGroup] then
		warn(string.format(
			"[HelpServer] Command %q has unknown DisplayGroup %q. Falling back to Moderator.",
			tostring(commandName),
			displayGroup
			))

		return "Moderator"
	end

	return displayGroup
end

local function getPrimaryCommands()
	local commands = {}
	local seen = {}

	for _, commandObject in ipairs(Cmdr.Registry:GetCommands()) do
		local registryName = commandObject.Name
		if type(commandObject) == "table" then
			local primaryName = clean(commandObject.Name or registryName)
			local registryNameText = clean(registryName)

			if primaryName ~= "" then
				local primaryKey = lower(primaryName)
				local registryKey = lower(registryNameText)

				if not seen[primaryKey] and primaryKey == registryKey then
					seen[primaryKey] = true

					table.insert(commands, {
						name = primaryName,

						-- This is Cmdr's internal command group.
						cmdrGroup = clean(commandObject.Group) ~= ""
							and clean(commandObject.Group)
							or "USARF Admin",

						-- This is the category shown by the custom help command.
						displayGroup = getDisplayGroup(primaryName),

						description = clean(commandObject.Description),
						aliases = commandObject.Aliases or {},
						args = commandObject.Args or {},
					})
				end
			end
		end
	end

	table.sort(commands, function(a, b)
		return lower(a.name) < lower(b.name)
	end)

	return commands
end

local function findCommand(commandName)
	local normalizedName = lower(commandName)

	for _, command in ipairs(getPrimaryCommands()) do
		if lower(command.name) == normalizedName then
			return command
		end

		for _, alias in ipairs(command.aliases or {}) do
			if lower(alias) == normalizedName then
				return command
			end
		end
	end

	return nil
end

local function formatCommandDetails(command)
	local lines = {
		"══════════════════════════════════════",
		"USARF Command Help",
		"══════════════════════════════════════",
		"",
		command.name,
		"",
		"Administration Group:",
		command.displayGroup,
		"",
		"Description:",
		command.description ~= ""
			and command.description
			or "No description provided.",
	}

	if command.aliases and #command.aliases > 0 then
		local aliases = {}

		for _, alias in ipairs(command.aliases) do
			table.insert(aliases, tostring(alias))
		end

		table.sort(aliases, function(a, b)
			return lower(a) < lower(b)
		end)

		table.insert(lines, "")
		table.insert(lines, "Aliases:")
		table.insert(lines, table.concat(aliases, ", "))
	end

	if command.args and #command.args > 0 then
		table.insert(lines, "")
		table.insert(lines, "Arguments:")

		for _, arg in ipairs(command.args) do
			-- Dynamic arguments are functions whose shape depends on earlier arguments.
			if type(arg) ~= "table" then
				table.insert(lines, "  ... - depends on the previous arguments")
				continue
			end

			local optional = arg.Optional and "optional" or "required"
			local argType = if type(arg.Type) == "table" then arg.Type.DisplayName else arg.Type

			table.insert(lines, string.format(
				"  %s <%s> - %s (%s)",
				tostring(arg.Name or "Argument"),
				tostring(argType or "any"),
				tostring(arg.Description or "No description."),
				optional
				))
		end
	end

	return table.concat(lines, "\n")
end

return function(context, commandName)
	commandName = clean(commandName)

	if commandName ~= "" then
		local command = findCommand(commandName)

		if not command then
			return "Unknown command: " .. commandName
		end

		return formatCommandDetails(command)
	end

	local grouped = {}

	for _, groupName in ipairs(GROUP_ORDER) do
		grouped[groupName] = {}
	end

	for _, command in ipairs(getPrimaryCommands()) do
		local canRun = CmdrPermissionService.CanRun(
			context.Executor,
			command.name
		)

		if canRun then
			local groupName = command.displayGroup

			if not grouped[groupName] then
				warn(string.format(
					"[HelpServer] Unable to display command %q because group %q is not registered.",
					command.name,
					tostring(groupName)
					))
			else
				table.insert(grouped[groupName], command.name)
			end
		end
	end

	local lines = {
		"══════════════════════════════════════",
		"USARF Administration Terminal",
		"══════════════════════════════════════",
		"",
	}

	for _, groupName in ipairs(GROUP_ORDER) do
		local commands = grouped[groupName] or {}

		table.sort(commands, function(a, b)
			return lower(a) < lower(b)
		end)

		if #commands > 0 then
			table.insert(
				lines,
				string.format("%s (%d)", groupName, #commands)
			)

			table.insert(lines, "")

			for _, command in ipairs(commands) do
				table.insert(lines, "    " .. command)
			end

			table.insert(lines, "")
		end
	end

	table.insert(lines, "Type:")
	table.insert(lines, "")
	table.insert(lines, "help <command>")
	table.insert(lines, "")
	table.insert(lines, "for detailed information.")

	return table.concat(lines, "\n")
end
