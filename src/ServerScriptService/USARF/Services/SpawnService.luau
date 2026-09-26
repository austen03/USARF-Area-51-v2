local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local TeamAccessService = require(Services.TeamAccessService)

local SpawnService = {}

local DEFAULT_SPAWN_KEY = "TestSubject"

local function getSpawnFolder()
	local usarfFolder = Workspace:FindFirstChild("USARF")
	if not usarfFolder then
		warn("[SpawnService] Missing Workspace.USARF folder")
		return nil
	end

	local spawnsFolder = usarfFolder:FindFirstChild("Spawns")
	if not spawnsFolder then
		warn("[SpawnService] Missing Workspace.USARF.Spawns folder")
		return nil
	end

	return spawnsFolder
end

local function getSpawnByKey(spawnKey)
	local spawnsFolder = getSpawnFolder()
	if not spawnsFolder then
		return nil
	end

	local spawnObject = spawnsFolder:FindFirstChild(spawnKey)

	if not spawnObject then
		warn("[SpawnService] Missing spawn:", spawnKey)
		return nil
	end

	return spawnObject
end

local function getSpawnCFrame(spawnObject)
	if spawnObject:IsA("BasePart") then
		return spawnObject.CFrame
	end

	if spawnObject:IsA("Model") then
		if spawnObject.PrimaryPart then
			return spawnObject.PrimaryPart.CFrame
		end

		local part = spawnObject:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part.CFrame
		end
	end

	if spawnObject:IsA("Folder") then
		local part = spawnObject:FindFirstChildWhichIsA("BasePart", true)
		if part then
			return part.CFrame
		end
	end

	return nil
end

local function getCharacterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function moveCharacterToSpawn(player, spawnObject)
	local root = getCharacterRoot(player)

	if not root then
		return false, "Character is not ready"
	end

	local spawnCFrame = getSpawnCFrame(spawnObject)

	if not spawnCFrame then
		return false, "Spawn has no valid BasePart"
	end

	local offset = CFrame.new(0, 4, 0)
	root.CFrame = spawnCFrame * offset

	return true
end

local function assignRobloxTeam(player, teamName)
	local robloxTeam = Teams:FindFirstChild(teamName)

	if not robloxTeam then
		warn("[SpawnService] Missing Roblox team:", teamName)
		return false
	end

	player.Team = robloxTeam
	player.TeamColor = robloxTeam.TeamColor

	return true
end

function SpawnService.GetDefaultSpawn()
	return getSpawnByKey(DEFAULT_SPAWN_KEY)
end

function SpawnService.GetSpawnForTeam(teamKey)
	local teamData = TeamAccessService.GetTeam(teamKey)

	if not teamData then
		return nil, "Invalid team"
	end

	local spawnKey = teamData.spawnKey or DEFAULT_SPAWN_KEY
	local spawnObject = getSpawnByKey(spawnKey)

	if not spawnObject then
		return nil, "Missing spawn for " .. tostring(spawnKey)
	end

	return spawnObject, nil
end

function SpawnService.SendPlayerToDefaultSpawn(player)
	local spawnObject = SpawnService.GetDefaultSpawn()

	if not spawnObject then
		return false, "Default spawn missing"
	end

	local moved, moveError = moveCharacterToSpawn(player, spawnObject)

	if not moved then
		return false, moveError
	end

	return true
end

function SpawnService.SendPlayerToTeamSpawn(player, teamKey)
	local access = TeamAccessService.CanPlayerUseTeam(player, teamKey)
	
	
	
	if not access.canAccess then
		return false, access.reason or "Access denied", access
	end

	local teamData = access.teamData

	if not teamData then
		return false, "Missing team data", access
	end

	local spawnObject, spawnError = SpawnService.GetSpawnForTeam(teamKey)

	if not spawnObject then
		return false, spawnError, access
	end

	local assignedTeam = assignRobloxTeam(player, teamData.teamName)

	if not assignedTeam then
		return false, "Roblox team does not exist: " .. tostring(teamData.teamName), access
	end

	local moved, moveError = moveCharacterToSpawn(player, spawnObject)

	if not moved then
		return false, moveError, access
	end

	player:SetAttribute("USARF_TeamKey", teamKey)
	player:SetAttribute("USARF_TeamName", teamData.teamName)
	player:SetAttribute("USARF_SpawnKey", teamData.spawnKey)
	
	local rankName = player:GetAttribute("USARF_RankName")

	local timeout = tick() + 5

	while not rankName and tick() < timeout do
		task.wait(0.1)
		rankName = player:GetAttribute("USARF_RankName")
	end

	rankName = rankName or "Guest"

	return true, "Spawned successfully", access
end

function SpawnService.RespawnPlayerAtCurrentTeam(player)
	local teamKey = player:GetAttribute("USARF_TeamKey")

	if not teamKey then
		return SpawnService.SendPlayerToDefaultSpawn(player)
	end

	return SpawnService.SendPlayerToTeamSpawn(player, teamKey)
end

return SpawnService