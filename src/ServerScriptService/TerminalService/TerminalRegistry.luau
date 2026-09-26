local Permissions = require(script.Parent:WaitForChild("TerminalPermissions"))

local TerminalRegistry = {}

local commands = {}
local commandList = {}

local function register(command)
	if type(command) ~= "table" then
		return
	end

	if not command.Name then
		warn("[TerminalRegistry] Command missing Name")
		return
	end

	command.Name = string.lower(command.Name)
	command.Aliases = command.Aliases or {}
	command.Category = command.Category or "General"
	command.Description = command.Description or "No description."
	command.Usage = command.Usage or command.Name
	command.MinRank = command.MinRank or 0
	command.PermissionLevel = command.PermissionLevel or nil
	command.Examples = command.Examples or {}

	commands[command.Name] = command
	table.insert(commandList, command)

	for _, alias in ipairs(command.Aliases) do
		commands[string.lower(alias)] = command
	end
end

function TerminalRegistry.Load(commandsFolder)
	table.clear(commands)
	table.clear(commandList)

	for _, child in ipairs(commandsFolder:GetChildren()) do
		if child:IsA("ModuleScript") then
			local success, command = pcall(require, child)

			if success then
				register(command)
			else
				warn("[TerminalRegistry] Failed to load", child.Name, command)
			end
		end
	end

	table.sort(commandList, function(a, b)
		if a.Category == b.Category then
			return a.Name < b.Name
		end

		return a.Category < b.Category
	end)

	print("[TerminalRegistry] Loaded", #commandList, "commands")
end

function TerminalRegistry.Get(name)
	return commands[string.lower(tostring(name or ""))]
end

function TerminalRegistry.GetAll()
	local output = {}

	for index, command in ipairs(commandList) do
		output[index] = command
	end

	return output
end

function TerminalRegistry.CanAccessTerminal(player)
	return Permissions.CanAccessTerminal(player)
end

function TerminalRegistry.CanRun(player, command)
	return Permissions.CanRun(player, command)
end

function TerminalRegistry.GetClientList(player)
	local accessAllowed = TerminalRegistry.CanAccessTerminal(player)

	if not accessAllowed then
		return {}
	end

	local output = {}

	for _, command in ipairs(commandList) do
		local canRun = TerminalRegistry.CanRun(player, command)

		if canRun then
			table.insert(output, {
				Name = command.Name,
				Aliases = command.Aliases or {},
				Category = command.Category,
				Description = command.Description,
				Usage = command.Usage,
				PermissionLevel = command.PermissionLevel,
				MinRank = command.MinRank,
				Examples = command.Examples or {},
			})
		end
	end

	return output
end

return TerminalRegistry