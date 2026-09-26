local ServerScriptService = game:GetService("ServerScriptService")

local Cmdr = require(ServerScriptService:WaitForChild("Cmdr"))

local USARFServer = ServerScriptService:WaitForChild("USARF")
local CmdrFolder = USARFServer:WaitForChild("Cmdr")
local ConfigFolder = USARFServer:WaitForChild("Config")

local CmdrAdminConfig = require(ConfigFolder:WaitForChild("CmdrAdminConfig"))

-- Default Cmdr commands disabled.
-- Cmdr:RegisterDefaultCommands()

Cmdr:RegisterTypesIn(CmdrFolder:WaitForChild("Types"))
Cmdr:RegisterCommandsIn(CmdrFolder:WaitForChild("Commands"))

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
		return CmdrAdminConfig.DisplayGroups[commandConfig.MainServerLevel]
			or commandConfig.MainServerLevel
	end

	return "Moderator"
end

local function applyCommandGroups()
	local registry = Cmdr.Registry

	if not registry or type(registry.Commands) ~= "table" then
		warn("[USARF Cmdr] Could not apply command groups. Registry.Commands missing.")
		return
	end

	for commandName, commandObject in pairs(registry.Commands) do
		if type(commandObject) == "table" then
			commandObject.Group = getDisplayGroup(commandName)
		end
	end
end

applyCommandGroups()

Cmdr.Registry:RegisterHook(
	"BeforeRun",
	require(CmdrFolder:WaitForChild("Hooks"):WaitForChild("BeforeRun"))
)

print("[USARF Cmdr] Initialized with USARF-only commands")