local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARFServer = ServerScriptService:WaitForChild("USARF")

local Controllers = USARFServer:WaitForChild("Controllers")
local Services = USARFServer:WaitForChild("Services")

local function ensureRemoteFolder()
	local folder = ReplicatedStorage:FindFirstChild("USARF_Remotes")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "USARF_Remotes"
		folder.Parent = ReplicatedStorage
	end

	return folder
end

local function ensureRemoteEvent(remoteName)
	local folder = ensureRemoteFolder()
	local remote = folder:FindFirstChild(remoteName)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = folder
	end

	return remote
end

ensureRemoteEvent("CmdrClearOutput")

local function requireOnly(serviceName)
	local success, result = pcall(function()
		return require(Services:WaitForChild(serviceName))
	end)

	if success then
		print("[ServerMain] Loaded " .. serviceName)
		return result
	end

	warn("[ServerMain] Failed to load " .. serviceName .. ": " .. tostring(result))
	return nil
end

local function startService(serviceName)
	local service = requireOnly(serviceName)

	if service and typeof(service.Start) == "function" then
		local success, result = pcall(function()
			service.Start()
		end)

		if success then
			print("[ServerMain] Started " .. serviceName)
		else
			warn("[ServerMain] Failed to start " .. serviceName .. ": " .. tostring(result))
		end
	else
		warn("[ServerMain] " .. serviceName .. " has no Start() function")
	end

	return service
end

--// Core services that only need requiring
requireOnly("DiscordBotBridge")
requireOnly("PermissionService")
requireOnly("SuspensionService")
requireOnly("RankService")
requireOnly("TeamAccessService")
requireOnly("SpawnService")
requireOnly("FacilityAlertService")
requireOnly("RadioService")
requireOnly("CaseIdService")
requireOnly("AuditService")
requireOnly("WebhookService")
requireOnly("ActivityService")
requireOnly("ActivityExportService")
requireOnly("StaffAlertService")
requireOnly("UserAlertHistoryService")
requireOnly("UserAlertService")
requireOnly("BanService")
requireOnly("TeleportProtectionService")
requireOnly("AntiExploitService")
requireOnly("NameTagService")
requireOnly("AnnouncementService")
requireOnly("DepartmentAlertService")
requireOnly("ContainmentZoneService")
requireOnly("LeaderboardService")

--// Start early services
startService("LoadingService")
startService("InventoryService")
startService("LoadoutService")
startService("BlackMarketPromptService")
startService("DeathStateService")

--// Started services
startService("DetainService")
startService("CmdrPermissionService")
startService("ChatLogService")
startService("AdminLogService")
startService("RadioLogService")
startService("InitService")
startService("CmdrAuditService")
startService("ModerationUtilityService")
startService("ModerationCaseService")
startService("UniformService")
startService("RibbonRackService")
startService("ClanService")
startService("CertificationService")
startService("CovertService")
startService("FacilityStatusService")
startService("LockdownVisualService")
startService("FacilityAnnouncementService")
startService("RiotService")
startService("ServerTeleportService")
startService("ToolListService")
startService("HealthStateService")
startService("MedicalStateService")
startService("MedicalTreatmentService")
startService("WeaponService")
startService("WeaponTestService")
startService("GlassService")

--// Controllers
require(Controllers:WaitForChild("TeamController"))

local serverTransferController = Controllers:FindFirstChild("ServerTransferController")
if serverTransferController then
	require(serverTransferController)
end

print("[USARF] Server systems loaded.")