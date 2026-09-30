local ServerScriptService = game:GetService("ServerScriptService")

local Cmdr = require(ServerScriptService:WaitForChild("Cmdr"))

local USARFServer = ServerScriptService:WaitForChild("USARF")
local CmdrFolder = USARFServer:WaitForChild("Cmdr")
local ConfigFolder = USARFServer:WaitForChild("Config")

local CmdrAdminConfig = require(ConfigFolder:WaitForChild("CmdrAdminConfig"))

Cmdr.Registry:RegisterHook("BeforeRun", require(CmdrFolder:WaitForChild("Hooks"):WaitForChild("BeforeRun")))

Cmdr.Registry:RegisterTypesIn(CmdrFolder:WaitForChild("Types"))
Cmdr.Registry:RegisterCommandsIn(CmdrFolder:WaitForChild("Commands"))

local function normalizeCommandName(name)
	return string.lower(tostring(name or ""))
end

local function getDisplayGroup(commandName)
	local commandConfig = CmdrAdminConfig.Commands[normalizeCommandName(commandName)]
		or CmdrAdminConfig.Commands.Default

	if commandConfig and commandConfig.DisplayGroup then
		return commandConfig.DisplayGroup
	end

	if commandConfig and commandConfig.MainServerLevel then
		return CmdrAdminConfig.DisplayGroups[commandConfig.MainServerLevel] or commandConfig.MainServerLevel
	end

	return "Moderator"
end

local function applyCommandGroups()
	local commands = Cmdr.Registry:GetCommands()

	for _, commandObject in ipairs(commands) do
		if type(commandObject) == "table" then
			commandObject.Group = getDisplayGroup(commandObject.Name)
		end
	end
end

applyCommandGroups()

print("[USARF Cmdr] Initialized with USARF-only commands")
