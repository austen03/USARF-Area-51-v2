local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")
local Config = USARFServer:WaitForChild("Config")

local DetainConfig = require(Config:WaitForChild("DetainConfig"))

local ModerationCaseService = nil
pcall(function()
	ModerationCaseService = require(Services:WaitForChild("ModerationCaseService"))
end)

local DetainService = {}

local started = false

local detainStates = {}
local escortConnections = {}

local function getRemotesRoot()
	local usarf = ReplicatedStorage:FindFirstChild("USARF")
	if usarf then
		local remotes = usarf:FindFirstChild("Remotes")
		if remotes then
			return remotes
		end
	end

	local fallback = ReplicatedStorage:FindFirstChild("USARF_Remotes")
	if not fallback then
		fallback = Instance.new("Folder")
		fallback.Name = "USARF_Remotes"
		fallback.Parent = ReplicatedStorage
	end

	return fallback
end

local function getOrCreate(parent, className, name)
	local object = parent:FindFirstChild(name)

	if not object then
		object = Instance.new(className)
		object.Name = name
		object.Parent = parent
	end

	return object
end

local remotesRoot = getRemotesRoot()
local detainFolder = getOrCreate(remotesRoot, "Folder", "Detain")

local toggleCuffRemote = getOrCreate(detainFolder, "RemoteEvent", "ToggleCuff")
local toggleEscortRemote = getOrCreate(detainFolder, "RemoteEvent", "ToggleEscort")
local removeToolsRemote = getOrCreate(detainFolder, "RemoteEvent", "RemoveAuthorizedTools")
local statusRemote = getOrCreate(detainFolder, "RemoteEvent", "StatusUpdate")
local inspectFunction = getOrCreate(detainFolder, "RemoteFunction", "InspectTarget")

local function getAttributeName(key)
	return DetainConfig.Attributes[key]
end

local function getTeamKey(player)
	if not player then
		return "NoDepartment"
	end

	local teamKey = player:GetAttribute("USARF_TeamKey")
	if teamKey and teamKey ~= "" then
		return teamKey
	end

	local teamName = player:GetAttribute("USARF_TeamName")
	if teamName and teamName ~= "" then
		local map = {
			["Test Subject"] = "TestSubject",
			["PMC"] = "PMC",

			["Facility Personnel"] = "FacilityPersonnel",
			["Engineering & Technical"] = "EngineeringTechnical",
			["Medical Division"] = "MedicalDivision",
			["Research Division"] = "ResearchDivision",
			["Rules & Regulations"] = "RulesRegulations",
			["United States Air Force"] = "UnitedStatesAirForce",
			["Department of Defense"] = "DepartmentOfDefense",

			["108th Infantry Regiment"] = "Infantry108",
			["137th Military Police Company"] = "MP137",
			["1st Spec. Ops. A.I.G"] = "SpecOpsAIG",
			["Secret Service"] = "SecretService",

			["Central Intelligence Agency"] = "CentralIntelligenceAgency",
			["Federal Bureau of Investigation"] = "FederalBureauInvestigation",
			["Federal Defense Service"] = "FederalDefenseService",

			["Federal Administration"] = "FederalAdministration",
			["President of the United States"] = "President",
			["Vice President of the United States"] = "VicePresident",
			["Presidential Cabinet"] = "PresidentialCabinet",
		}

		if map[teamName] then
			return map[teamName]
		end
	end

	if player.Team then
		local map = {
			["Test Subject"] = "TestSubject",
			["PMC"] = "PMC",

			["Facility Personnel"] = "FacilityPersonnel",
			["Engineering & Technical"] = "EngineeringTechnical",
			["Medical Division"] = "MedicalDivision",
			["Research Division"] = "ResearchDivision",
			["Rules & Regulations"] = "RulesRegulations",
			["United States Air Force"] = "UnitedStatesAirForce",
			["Department of Defense"] = "DepartmentOfDefense",

			["108th Infantry Regiment"] = "Infantry108",
			["137th Military Police Company"] = "MP137",
			["1st Spec. Ops. A.I.G"] = "SpecOpsAIG",
			["Secret Service"] = "SecretService",

			["Central Intelligence Agency"] = "CentralIntelligenceAgency",
			["Federal Bureau of Investigation"] = "FederalBureauInvestigation",
			["Federal Defense Service"] = "FederalDefenseService",

			["Federal Administration"] = "FederalAdministration",
			["President of the United States"] = "President",
			["Vice President of the United States"] = "VicePresident",
			["Presidential Cabinet"] = "PresidentialCabinet",
		}

		if map[player.Team.Name] then
			return map[player.Team.Name]
		end
	end

	return "NoDepartment"
end

local function isTestSubject(player)
	return getTeamKey(player) == "TestSubject"
end

local function getCharacter(player)
	return player and player.Character
end

local function getHumanoid(player)
	local character = getCharacter(player)
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(player)
	local character = getCharacter(player)
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getDistance(actor, target)
	local actorRoot = getRoot(actor)
	local targetRoot = getRoot(target)

	if not actorRoot or not targetRoot then
		return math.huge
	end

	return (actorRoot.Position - targetRoot.Position).Magnitude
end

local function isWithinCuffDistance(actor, target)
	return getDistance(actor, target) <= DetainConfig.MaxCuffDistance
end

local function isBlocked(targetTeamKey, blockedTargets)
	return blockedTargets and blockedTargets[targetTeamKey] == true
end

local function isLeadershipOverride(player)
	if not player then
		return false
	end

	for groupId, minimumRank in pairs(DetainConfig.LeadershipRanks) do
		local rank = 0

		pcall(function()
			rank = player:GetRankInGroup(groupId)
		end)

		if rank >= minimumRank then
			return true
		end
	end

	return false
end

local function sendNotice(player, title, message)
	if not player then
		return
	end

	statusRemote:FireClient(player, "Notice", {
		title = tostring(title or "Detain"),
		message = tostring(message or ""),
	})
end

local function setAttribute(player, key, value)
	local attributeName = getAttributeName(key)
	if attributeName then
		player:SetAttribute(attributeName, value)
	end
end

local function getAttribute(player, key)
	local attributeName = getAttributeName(key)
	if attributeName then
		return player:GetAttribute(attributeName)
	end

	return nil
end

local function ensureState(player)
	local state = detainStates[player.UserId]

	if not state then
		state = {
			IsCuffed = false,
			IsEscorted = false,
			EscortOfficer = nil,
			CuffedBy = nil,
			CuffedAt = nil,
			Reason = nil,
		}

		detainStates[player.UserId] = state
	end

	return state
end

local function applyStateAttributes(player)
	local state = ensureState(player)

	setAttribute(player, "IsCuffed", state.IsCuffed == true)
	setAttribute(player, "IsEscorted", state.IsEscorted == true)
	setAttribute(player, "EscortOfficer", state.EscortOfficer)
	setAttribute(player, "CuffedBy", state.CuffedBy)
	setAttribute(player, "CuffedAt", state.CuffedAt)
	setAttribute(player, "DetainReason", state.Reason)
end

local function clearEscortObjects(target)
	local character = getCharacter(target)
	if not character then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant.Name == "USARF_EscortTargetAttachment" then
			descendant:Destroy()
		end
	end
end

local function clearOfficerEscortObjects(officer)
	local character = getCharacter(officer)
	if not character then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant.Name == "USARF_EscortOfficerAttachment" then
			descendant:Destroy()
		end
	end
end

local function stopEscortConnection(target)
	local connection = escortConnections[target.UserId]

	if connection then
		connection:Disconnect()
		escortConnections[target.UserId] = nil
	end
end

local function setMovementRestricted(player, restricted)
	local humanoid = getHumanoid(player)
	if not humanoid then
		return
	end

	if restricted then
		if player:GetAttribute("USARF_PreDetainWalkSpeed") == nil then
			player:SetAttribute("USARF_PreDetainWalkSpeed", humanoid.WalkSpeed)
		end

		if player:GetAttribute("USARF_PreDetainJumpPower") == nil then
			player:SetAttribute("USARF_PreDetainJumpPower", humanoid.JumpPower)
		end

		if player:GetAttribute("USARF_PreDetainJumpHeight") == nil then
			player:SetAttribute("USARF_PreDetainJumpHeight", humanoid.JumpHeight)
		end

		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	else
		local walkSpeed = tonumber(player:GetAttribute("USARF_PreDetainWalkSpeed")) or 16
		local jumpPower = tonumber(player:GetAttribute("USARF_PreDetainJumpPower")) or 50
		local jumpHeight = tonumber(player:GetAttribute("USARF_PreDetainJumpHeight")) or 7.2

		humanoid.WalkSpeed = walkSpeed
		humanoid.JumpPower = jumpPower
		humanoid.JumpHeight = jumpHeight
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

		player:SetAttribute("USARF_PreDetainWalkSpeed", nil)
		player:SetAttribute("USARF_PreDetainJumpPower", nil)
		player:SetAttribute("USARF_PreDetainJumpHeight", nil)
	end
end

local function unequipTools(player)
	local humanoid = getHumanoid(player)
	if humanoid then
		humanoid:UnequipTools()
	end

	local character = getCharacter(player)
	local backpack = player:FindFirstChildOfClass("Backpack")

	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				child.Parent = backpack or player
			end
		end
	end
end

local function blockTools(player)
	unequipTools(player)

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end

	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Enabled = false
		end
	end
end

local function unblockTools(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				tool.Enabled = true
			end
		end
	end
end

function DetainService.GetState(player)
	if not player then
		return nil
	end

	local state = ensureState(player)

	return {
		IsCuffed = state.IsCuffed == true,
		IsEscorted = state.IsEscorted == true,
		EscortOfficer = state.EscortOfficer,
		CuffedBy = state.CuffedBy,
		CuffedAt = state.CuffedAt,
		Reason = state.Reason,
	}
end

function DetainService.IsCuffed(player)
	if not player then
		return false
	end

	local state = ensureState(player)
	return state.IsCuffed == true
end

function DetainService.IsEscorted(player)
	if not player then
		return false
	end

	local state = ensureState(player)
	return state.IsEscorted == true
end

function DetainService.GetEscortOfficer(player)
	if not player then
		return nil
	end

	local state = ensureState(player)
	if not state.EscortOfficer then
		return nil
	end

	return Players:GetPlayerByUserId(state.EscortOfficer)
end

function DetainService.CanDetain(actor, target)
	if not actor or not target then
		return false, "Missing actor or target."
	end

	if actor == target then
		return false, "You cannot detain yourself."
	end

	if not isWithinCuffDistance(actor, target) then
		return false, "Target is too far away."
	end

	local actorTeamKey = getTeamKey(actor)
	local targetTeamKey = getTeamKey(target)

	if DetainConfig.FullAccessTeamKeys[actorTeamKey] then
		return true, "Full access."
	end

	if isLeadershipOverride(actor) then
		if isBlocked(targetTeamKey, DetainConfig.LeadershipBlockedTargets) then
			return false, "Leadership may not detain POTUS, VPOTUS, or Federal Administration."
		end

		return true, "Leadership access."
	end

	if isTestSubject(target) then
		return true, "Test Subject target."
	end

	if DetainConfig.IntelligenceTeamKeys[actorTeamKey] then
		if isBlocked(targetTeamKey, DetainConfig.IntelligenceBlockedTargets) then
			return false, "You may not detain this target."
		end

		return true, "Intelligence access."
	end

	if DetainConfig.SecretServiceTeamKeys[actorTeamKey] then
		if isBlocked(targetTeamKey, DetainConfig.SecretServiceBlockedTargets) then
			return false, "You may not detain this target."
		end

		return true, "Secret Service access."
	end

	if DetainConfig.RulesRegulationsTeamKeys[actorTeamKey] then
		if isBlocked(targetTeamKey, DetainConfig.RulesRegulationsBlockedTargets) then
			return false, "You may not detain this target."
		end

		return true, "Rules & Regulations access."
	end

	return false, "You may only detain Test Subjects."
end

function DetainService.Cuff(actor, target, reason)
	local allowed, message = DetainService.CanDetain(actor, target)

	if not allowed then
		return false, message
	end

	local state = ensureState(target)

	if state.IsCuffed then
		return false, "Target is already cuffed."
	end

	state.IsCuffed = true
	state.CuffedBy = actor.UserId
	state.CuffedAt = os.time()
	state.Reason = reason

	applyStateAttributes(target)
	blockTools(target)
	setMovementRestricted(target, true)

	statusRemote:FireClient(target, "Cuffed", {
		by = actor.Name,
	})

	sendNotice(actor, "Detain", target.Name .. " has been cuffed.")

	return true, "Cuffed."
end

function DetainService.Uncuff(actor, target)
	if not target then
		return false, "Missing target."
	end

	local state = ensureState(target)

	if not state.IsCuffed then
		return false, "Target is not cuffed."
	end

	DetainService.StopEscort(actor, target)

	state.IsCuffed = false
	state.CuffedBy = nil
	state.CuffedAt = nil
	state.Reason = nil

	applyStateAttributes(target)
	unblockTools(target)
	setMovementRestricted(target, false)

	statusRemote:FireClient(target, "Uncuffed", {
		by = actor and actor.Name or "System",
	})

	if actor then
		sendNotice(actor, "Detain", target.Name .. " has been uncuffed.")
	end

	return true, "Uncuffed."
end

function DetainService.ToggleCuff(actor, target, reason)
	if DetainService.IsCuffed(target) then
		return DetainService.Uncuff(actor, target)
	end

	return DetainService.Cuff(actor, target, reason)
end

function DetainService.StartEscort(actor, target)
	if not actor or not target then
		return false, "Missing actor or target."
	end

	if not DetainService.IsCuffed(target) then
		return false, "Target must be cuffed first."
	end

	local allowed, message = DetainService.CanDetain(actor, target)
	if not allowed then
		return false, message
	end

	local officerRoot = getRoot(actor)
	local targetRoot = getRoot(target)

	if not officerRoot or not targetRoot then
		return false, "Missing character root."
	end

	local state = ensureState(target)

	if state.IsEscorted and state.EscortOfficer == actor.UserId then
		return false, "Target is already being escorted by you."
	end

	if state.IsEscorted then
		DetainService.StopEscort(nil, target)
	end

	clearEscortObjects(target)
	clearOfficerEscortObjects(actor)
	stopEscortConnection(target)

	actor:SetAttribute("USARF_DetainEscortActive", true)
	actor:SetAttribute("USARF_AntiExploitBypass", true)

	target:SetAttribute("USARF_DetainEscortActive", true)
	target:SetAttribute("USARF_AntiExploitBypass", true)
	target:SetAttribute("USARF_DetainTeleportBypass", true)

	local escortFolder = workspace:FindFirstChild("USARF_EscortConstraints")

	if not escortFolder then
		escortFolder = Instance.new("Folder")
		escortFolder.Name = "USARF_EscortConstraints"
		escortFolder.Parent = workspace
	end

	local officerAttachment = Instance.new("Attachment")
	officerAttachment.Name = "USARF_EscortOfficerAttachment"
	officerAttachment.Position = Vector3.new(0, 0, 3)
	officerAttachment.Parent = officerRoot

	local targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = "USARF_EscortTargetAttachment"
	targetAttachment.Parent = targetRoot

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Name = "USARF_EscortAlignPosition_" .. tostring(target.UserId)
	alignPosition.Attachment0 = targetAttachment
	alignPosition.Attachment1 = officerAttachment
	alignPosition.MaxForce = 45000
	alignPosition.Responsiveness = 35
	alignPosition.RigidityEnabled = false
	alignPosition.ApplyAtCenterOfMass = true
	alignPosition.Parent = escortFolder

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "USARF_EscortAlignOrientation_" .. tostring(target.UserId)
	alignOrientation.Attachment0 = targetAttachment
	alignOrientation.Attachment1 = officerAttachment
	alignOrientation.MaxTorque = 25000
	alignOrientation.Responsiveness = 20
	alignOrientation.RigidityEnabled = false
	alignOrientation.Parent = escortFolder

	state.IsEscorted = true
	state.EscortOfficer = actor.UserId
	applyStateAttributes(target)

	setMovementRestricted(target, true)

	statusRemote:FireClient(target, "Escorted", {
		by = actor.Name,
	})

	sendNotice(actor, "Escort", "You are now escorting " .. target.Name .. ".")

	local actorHumanoid = getHumanoid(actor)

	if actorHumanoid then
		local deathConnection
		deathConnection = actorHumanoid.Died:Connect(function()
			if deathConnection then
				deathConnection:Disconnect()
			end

			DetainService.StopEscort(nil, target)
		end)
	end

	escortConnections[target.UserId] = RunService.Heartbeat:Connect(function()
		if not target.Parent or not actor.Parent then
			DetainService.StopEscort(nil, target)
			return
		end

		if not DetainService.IsCuffed(target) then
			DetainService.StopEscort(nil, target)
			return
		end

		local currentOfficerRoot = getRoot(actor)
		local currentTargetRoot = getRoot(target)

		if not currentOfficerRoot or not currentTargetRoot then
			DetainService.StopEscort(nil, target)
			return
		end

		local distance = (currentOfficerRoot.Position - currentTargetRoot.Position).Magnitude

		if distance >= DetainConfig.EscortTeleportDistance then
			target:SetAttribute(DetainConfig.Attributes.AntiExploitBypass, true)
			target:SetAttribute(DetainConfig.Attributes.DetainTeleportBypass, true)
			target:SetAttribute("USARF_DetainEscortActive", true)

			currentTargetRoot.CFrame = currentOfficerRoot.CFrame * CFrame.new(0, 0, 3)
		end
	end)

	return true, "Escort started."
end

function DetainService.StopEscort(actor, target)
	if not target then
		return false, "Missing target."
	end

	local state = ensureState(target)

	if not state.IsEscorted then
		return false, "Target is not being escorted."
	end

	local officer = Players:GetPlayerByUserId(state.EscortOfficer or 0)

	stopEscortConnection(target)
	clearEscortObjects(target)
	
	if officer then
		officer:SetAttribute("USARF_DetainEscortActive", false)
		officer:SetAttribute("USARF_AntiExploitBypass", false)
	end

	local escortFolder = workspace:FindFirstChild("USARF_EscortConstraints")

	if escortFolder then
		for _, object in ipairs(escortFolder:GetChildren()) do
			if string.find(object.Name, tostring(target.UserId)) then
				object:Destroy()
			end
		end
	end

	if officer then
		clearOfficerEscortObjects(officer)
	end

	state.IsEscorted = false
	state.EscortOfficer = nil
	applyStateAttributes(target)

	target:SetAttribute("USARF_DetainEscortActive", false)

	task.delay(1.5, function()
		if target and target.Parent and not DetainService.IsEscorted(target) then
			target:SetAttribute(DetainConfig.Attributes.AntiExploitBypass, false)
			target:SetAttribute(DetainConfig.Attributes.DetainTeleportBypass, false)
		end
	end)

	statusRemote:FireClient(target, "EscortStopped", {
		by = actor and actor.Name or "System",
	})

	if actor then
		sendNotice(actor, "Escort", "Stopped escorting " .. target.Name .. ".")
	end

	return true, "Escort stopped."
end

function DetainService.ToggleEscort(actor, target)
	if not target then
		return false, "Missing target."
	end

	if DetainService.IsEscorted(target) then
		local officer = DetainService.GetEscortOfficer(target)

		if officer and officer ~= actor then
			return false, "Target is being escorted by another officer."
		end

		if DetainService.IsEscorted(target) then
			DetainService.StopEscort(actor, target)
		end
	end

	return DetainService.StartEscort(actor, target)
end

function DetainService.RemoveAuthorizedTools(actor, target)
	if not actor or not target then
		return false, "Missing actor or target."
	end

	if not isTestSubject(target) then
		return false, "Target must be a Test Subject."
	end

	if target:GetAttribute("USARF_ContainmentStatus") ~= "AUTHORIZED" then
		return false, "Target must be authorized before tools can be removed."
	end

	local allowed, message = DetainService.CanDetain(actor, target)
	if not allowed then
		return false, message
	end

	local removed = 0

	local humanoid = getHumanoid(target)
	if humanoid then
		humanoid:UnequipTools()
	end

	local backpack = target:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				item:Destroy()
				removed += 1
			end
		end
	end

	local character = getCharacter(target)
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				item:Destroy()
				removed += 1
			end
		end
	end

	sendNotice(actor, "Tools Removed", "Removed " .. tostring(removed) .. " tool(s) from " .. target.Name .. ".")

	return true, removed
end

local function issueLeaveWarning(player)
	if not ModerationCaseService then
		return
	end

	if typeof(ModerationCaseService.CreateSystemWarning) == "function" then
		pcall(function()
			ModerationCaseService.CreateSystemWarning(
				player.UserId,
				player.Name,
				DetainConfig.LeaveWhileCuffedWarningReason,
				"DetainService"
			)
		end)
	end
end

local function setupPlayer(player)
	ensureState(player)
	applyStateAttributes(player)

	player.CharacterAdded:Connect(function()
		task.wait(0.75)

		if DetainService.IsCuffed(player) then
			blockTools(player)
			setMovementRestricted(player, true)
		end
	end)

	player.Backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and DetainService.IsCuffed(player) then
			task.defer(function()
				blockTools(player)
			end)
		end
	end)
end

function DetainService.Start()
	if started then
		return
	end

	started = true

	Players.PlayerAdded:Connect(setupPlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		if DetainService.IsCuffed(player) then
			issueLeaveWarning(player)
		end

		stopEscortConnection(player)
		detainStates[player.UserId] = nil
	end)

	inspectFunction.OnServerInvoke = function(actor, target)
		if typeof(target) ~= "Instance" or not target:IsA("Player") then
			return {
				success = false,
				canDetain = false,
				message = "Invalid target.",
			}
		end

		local canDetain, reason = DetainService.CanDetain(actor, target)
		local state = DetainService.GetState(target)

		return {
			success = true,
			canDetain = canDetain,
			message = reason,
			targetUserId = target.UserId,
			targetName = target.Name,
			teamKey = getTeamKey(target),
			isTestSubject = isTestSubject(target),
			isAuthorized = target:GetAttribute("USARF_ContainmentStatus") == "AUTHORIZED",
			state = state,
		}
	end

	toggleCuffRemote.OnServerEvent:Connect(function(actor, target)
		if typeof(target) ~= "Instance" or not target:IsA("Player") then
			return
		end

		local ok, message = DetainService.ToggleCuff(actor, target)

		if not ok then
			sendNotice(actor, "Detain Failed", tostring(message))
		end
	end)

	toggleEscortRemote.OnServerEvent:Connect(function(actor, target)
		if typeof(target) ~= "Instance" or not target:IsA("Player") then
			return
		end

		local ok, message = DetainService.ToggleEscort(actor, target)

		if not ok then
			sendNotice(actor, "Escort Failed", tostring(message))
		end
	end)

	removeToolsRemote.OnServerEvent:Connect(function(actor, target)
		if typeof(target) ~= "Instance" or not target:IsA("Player") then
			return
		end

		local ok, result = DetainService.RemoveAuthorizedTools(actor, target)

		if not ok then
			sendNotice(actor, "Remove Tools Failed", tostring(result))
		end
	end)

	print("[DetainService] Started")
end

task.defer(function()
	DetainService.Start()
end)

return DetainService