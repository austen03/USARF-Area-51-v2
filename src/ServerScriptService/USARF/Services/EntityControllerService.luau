local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local AnimationClipProvider = game:GetService("AnimationClipProvider")

local EntityControllerService = {}

local TAG = "USARF_Entity"
local THINK_INTERVAL = 0.2
local ARRIVE_DISTANCE = 3
local WAYPOINT_REACHED = 2.5
local PATH_REFRESH_SECONDS = 4
local TELEPORT_THRESHOLD = 25

local DEFAULTS = {
	DetectRange = 60,
	LoseRange = 0,
	AttackRange = 6,
	AttackDamage = 15,
	AttackCooldown = 1.5,
	AttackArc = 0.3,
	WalkSpeed = 12,
	BreachAnimation = "",
	ReturnTimeout = 30,
	Ability = "",
	PullRange = 10,
	PullCooldown = 1.5,
	BlackHoleTemplate = "BlackHole",
	BurnDuration = 30,
	InfectScript = "PlayerInfect",
}

local MARKERS = { "Hit", "Footstep", "Roar", "Burst", "Spores", "Emerged", "Scream", "Alert", "Pull", "Mimic" }

local AntiExploitService = nil
pcall(function()
	local usarf = ServerScriptService:FindFirstChild("USARF")
	local services = usarf and usarf:FindFirstChild("Services")
	local module = services and services:FindFirstChild("AntiExploitService")

	if module then
		AntiExploitService = require(module)
	end
end)

local started = false
local controllers = {}

local function getSetting(model, name)
	local value = model:GetAttribute(name)

	if value == nil then
		return DEFAULTS[name]
	end

	return value
end

local function getLoseRange(model)
	local loseRange = getSetting(model, "LoseRange")

	if loseRange <= 0 then
		return getSetting(model, "DetectRange") + 20
	end

	return loseRange
end

local function giveGrace(player, seconds, reason)
	if not player then
		return
	end

	if AntiExploitService and typeof(AntiExploitService.GiveGrace) == "function" then
		AntiExploitService.GiveGrace(player, seconds, reason)
	else
		player:SetAttribute("USARF_TeleportGraceUntil", os.clock() + seconds)
		player:SetAttribute("USARF_TeleportGraceReason", reason)
	end
end

local function resolveAnimation(model, animation)
	if animation.AnimationId ~= "" then
		return animation
	end

	local saves = model:FindFirstChild("AnimSaves")
	local sequence = saves and saves:FindFirstChild(animation.Name)

	if RunService:IsStudio() and sequence and sequence:IsA("KeyframeSequence") then
		local success, id = pcall(function()
			return AnimationClipProvider:RegisterAnimationClip(sequence)
		end)

		if success then
			local temporary = Instance.new("Animation")
			temporary.Name = animation.Name
			temporary.AnimationId = id
			return temporary
		end
	end

	warn(
		"[EntityControllerService] "
			.. model.Name
			.. " animation '"
			.. animation.Name
			.. "' has no AnimationId. Publish it and paste the id into Animations."
			.. animation.Name
	)

	return nil
end

local function getLivingRoot(player)
	local character = player and player.Parent and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if humanoid and root and humanoid.Health > 0 then
		return root, humanoid
	end

	return nil
end

local function findTarget(root, range, ignores)
	local bestPlayer = nil
	local bestRoot = nil
	local bestDistance = range

	for _, player in ipairs(Players:GetPlayers()) do
		local targetRoot = getLivingRoot(player)

		if targetRoot and not ignores(targetRoot.Parent) then
			local distance = (targetRoot.Position - root.Position).Magnitude

			if distance < bestDistance then
				bestPlayer = player
				bestRoot = targetRoot
				bestDistance = distance
			end
		end
	end

	return bestPlayer, bestRoot, bestDistance
end

local function faceTowards(root, position)
	root.CFrame = CFrame.lookAt(root.Position, Vector3.new(position.X, root.Position.Y, position.Z))
end

local function playOnce(state, trackName)
	local track = state.tracks[trackName]

	if not track then
		return
	end

	track:Play(0.1)
	track.Stopped:Wait()
end

local function stopMoving(state)
	state.humanoid:MoveTo(state.root.Position)
end

local ABILITIES = {}

ABILITIES.BlackHole = {}

function ABILITIES.BlackHole.think(state, targetRoot, distance)
	local model = state.model

	if distance <= getSetting(model, "AttackRange") or distance > getSetting(model, "PullRange") then
		return false
	end

	if os.clock() - (state.lastPull or 0) < getSetting(model, "PullCooldown") then
		return false
	end

	state.busy = true
	state.lastPull = os.clock()
	stopMoving(state)
	faceTowards(state.root, targetRoot.Position)

	local track = state.tracks.Pull

	if track then
		track:Play(0.1)
	end

	local character = targetRoot.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local template = Lighting:FindFirstChild(getSetting(model, "BlackHoleTemplate"))
	local hole = nil
	local fade = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

	if template and template:IsA("BasePart") then
		hole = template:Clone()
		hole.Anchored = false
		hole.CanCollide = false
		hole.Massless = true
		hole.CFrame = targetRoot.CFrame
		hole.Parent = character

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hole
		weld.Part1 = targetRoot
		weld.Parent = hole

		TweenService:Create(hole, fade, { Transparency = 0 }):Play()
	end

	task.wait(0.5)

	if targetRoot.Parent and getLivingRoot(player) then
		giveGrace(player, 5, model.Name .. " BlackHole")

		local landing = (state.root.CFrame * CFrame.new(0, 0, -3)).Position
		targetRoot.CFrame = CFrame.lookAt(landing, Vector3.new(state.root.Position.X, landing.Y, state.root.Position.Z))
	end

	if hole then
		TweenService:Create(hole, fade, { Transparency = 1 }):Play()
		task.wait(0.5)
		hole:Destroy()
	end

	if track and track.IsPlaying then
		track.Stopped:Wait()
	end

	state.busy = false
	return true
end

function ABILITIES.BlackHole.onHit(state)
	local sound = state.model:FindFirstChild("Hit", true)

	if sound and sound:IsA("Sound") then
		sound:Play()
	end
end

ABILITIES.Burn = {}

function ABILITIES.Burn.ignores(_state, character)
	return character:FindFirstChild("Burn") ~= nil
end

function ABILITIES.Burn.onHit(state, _player, victimHumanoid)
	local character = victimHumanoid.Parent

	if not character or character:FindFirstChild("Burn") then
		return
	end

	local tag = Instance.new("BoolValue")
	tag.Name = "Burn"
	tag.Parent = character

	local burn = TweenInfo.new(getSetting(state.model, "BurnDuration"), Enum.EasingStyle.Linear)

	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			TweenService:Create(part, burn, { Color = Color3.fromRGB(255, 89, 89) }):Play()
		end
	end

	TweenService:Create(victimHumanoid, burn, { Health = 0 }):Play()

	local infect = state.model:FindFirstChild(getSetting(state.model, "InfectScript"), true)

	if infect and infect:IsA("BaseScript") then
		local copy = infect:Clone()
		copy.Parent = character
		copy.Enabled = true
	end
end

ABILITIES.Mimic = {}

function ABILITIES.Mimic.onHit(state, _player, victimHumanoid, killed)
	if not killed then
		return
	end

	local success, description = pcall(function()
		return victimHumanoid:GetAppliedDescription()
	end)

	if success then
		state.pendingDescription = description
	end
end

function ABILITIES.Mimic.afterAttack(state)
	local description = state.pendingDescription

	if not description then
		return
	end

	state.pendingDescription = nil

	local track = state.tracks.Mimic
	local applied = false

	local function apply()
		if applied then
			return
		end

		applied = true

		local success, result = pcall(function()
			state.humanoid:ApplyDescription(description)
		end)

		if not success then
			warn("[EntityControllerService] " .. state.model.Name .. " failed to mimic: " .. tostring(result))
		end
	end

	if track then
		local connection = track:GetMarkerReachedSignal("Mimic"):Connect(apply)
		playOnce(state, "Mimic")
		connection:Disconnect()
	end

	apply()
end

local function dealDamage(state)
	local model = state.model
	local root = state.root
	local range = getSetting(model, "AttackRange") * 1.25
	local arc = getSetting(model, "AttackArc")
	local damage = getSetting(model, "AttackDamage")
	local look = root.CFrame.LookVector
	local ability = ABILITIES[getSetting(model, "Ability")]

	for _, player in ipairs(Players:GetPlayers()) do
		local targetRoot, humanoid = getLivingRoot(player)

		if targetRoot then
			local offset = targetRoot.Position - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)

			if offset.Magnitude <= range and (flat.Magnitude < 0.01 or look:Dot(flat.Unit) >= arc) then
				giveGrace(player, 3, model.Name .. " Attack")
				humanoid:TakeDamage(damage)

				if ability and ability.onHit then
					ability.onHit(state, player, humanoid, humanoid.Health <= 0)
				end
			end
		end
	end
end

local function attack(state, targetRoot)
	local model = state.model
	local humanoid = state.humanoid

	state.busy = true
	state.lastAttack = os.clock()

	stopMoving(state)
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false
	faceTowards(state.root, targetRoot.Position)

	if state.tracks.Attack then
		playOnce(state, "Attack")
	else
		task.wait(0.5)
		dealDamage(state)
	end

	humanoid.AutoRotate = true
	humanoid.WalkSpeed = getSetting(model, "WalkSpeed")

	local ability = ABILITIES[getSetting(model, "Ability")]

	if ability and ability.afterAttack then
		ability.afterAttack(state)
	end

	state.busy = false
end

local function settle(state)
	state.target = nil
	state.mode = "Idle"
	state.path = nil
	state.home = state.root.CFrame
	state.lastPosition = state.root.Position
	stopMoving(state)
end

local function walkTowards(state, goal)
	local root = state.root

	if state.path == nil or os.clock() - state.pathComputedAt > PATH_REFRESH_SECONDS then
		local path = PathfindingService:CreatePath(state.agentParams)
		local success = pcall(function()
			path:ComputeAsync(root.Position, goal)
		end)

		state.pathComputedAt = os.clock()

		if success and path.Status == Enum.PathStatus.Success then
			state.path = path:GetWaypoints()
			state.waypointIndex = 2
		else
			state.path = false
		end
	end

	if state.path then
		local waypoint = state.path[state.waypointIndex]

		while waypoint do
			local offset = waypoint.Position - root.Position

			if Vector3.new(offset.X, 0, offset.Z).Magnitude > WAYPOINT_REACHED then
				break
			end

			state.waypointIndex += 1
			waypoint = state.path[state.waypointIndex]
		end

		if waypoint then
			state.humanoid:MoveTo(waypoint.Position)
			return
		end
	end

	state.humanoid:MoveTo(goal)
end

local function returnHome(state)
	local home = state.home
	local root = state.root

	if not home then
		settle(state)
		return
	end

	local offset = home.Position - root.Position

	if Vector3.new(offset.X, 0, offset.Z).Magnitude <= ARRIVE_DISTANCE then
		state.mode = "Idle"
		state.path = nil
		stopMoving(state)
		root.CFrame = CFrame.new(root.Position) * home.Rotation
		return
	end

	if state.mode ~= "Return" then
		state.mode = "Return"
		state.returnStartedAt = os.clock()
		state.path = nil
	end

	if os.clock() - state.returnStartedAt > getSetting(state.model, "ReturnTimeout") then
		root.CFrame = home
		state.lastPosition = home.Position
		state.mode = "Idle"
		state.path = nil
		stopMoving(state)
		return
	end

	walkTowards(state, home.Position)
end

local function think(state)
	if state.busy or state.humanoid.Health <= 0 then
		return
	end

	local model = state.model
	local root = state.root

	if state.lastPosition and (root.Position - state.lastPosition).Magnitude > TELEPORT_THRESHOLD then
		settle(state)
	end

	state.lastPosition = root.Position

	local ability = ABILITIES[getSetting(model, "Ability")]

	local function ignores(character)
		return ability ~= nil and ability.ignores ~= nil and ability.ignores(state, character)
	end

	local targetRoot = getLivingRoot(state.target)
	local distance = targetRoot and (targetRoot.Position - root.Position).Magnitude

	if targetRoot and (distance > getLoseRange(model) or ignores(targetRoot.Parent)) then
		targetRoot = nil
	end

	if not targetRoot then
		state.target = nil

		local player, newRoot, newDistance = findTarget(root, getSetting(model, "DetectRange"), ignores)

		if player then
			if state.mode == "Idle" then
				state.home = root.CFrame
			end

			state.target = player
			state.mode = "Chase"
			targetRoot = newRoot
			distance = newDistance
		end
	end

	if targetRoot then
		if ability and ability.think and ability.think(state, targetRoot, distance) then
			return
		end

		local ready = os.clock() - state.lastAttack >= getSetting(model, "AttackCooldown")

		if distance <= getSetting(model, "AttackRange") and ready then
			attack(state, targetRoot)
		else
			state.humanoid:MoveTo(targetRoot.Position)
		end

		return
	end

	if state.mode ~= "Idle" then
		returnHome(state)
	end
end

local function onBreachedChanged(state)
	local breachAnimation = getSetting(state.model, "BreachAnimation")

	if state.model:GetAttribute("USARF_Breached") == true and state.tracks[breachAnimation] then
		state.busy = true
		stopMoving(state)
		state.humanoid.WalkSpeed = 0
		playOnce(state, breachAnimation)
		state.humanoid.WalkSpeed = getSetting(state.model, "WalkSpeed")
		state.busy = false
	end

	settle(state)
end

local function detach(model)
	local state = controllers[model]

	if not state then
		return
	end

	controllers[model] = nil
	state.alive = false

	for _, connection in ipairs(state.connections) do
		connection:Disconnect()
	end

	for _, track in pairs(state.tracks) do
		track:Stop(0)
	end
end

local function attach(model)
	if controllers[model] or not model:IsA("Model") then
		return
	end

	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	local rig = humanoid and humanoid.Parent
	local root = rig and rig:FindFirstChild("HumanoidRootPart")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	local folder = model:FindFirstChild("Animations")

	if not (humanoid and root and animator and folder) then
		warn(
			"[EntityControllerService] "
				.. model.Name
				.. " needs a Humanoid, Animator, HumanoidRootPart and Animations folder"
		)
		return
	end

	local markerEvent = model:FindFirstChild("AnimationMarker")

	if not markerEvent then
		markerEvent = Instance.new("BindableEvent")
		markerEvent.Name = "AnimationMarker"
		markerEvent.Parent = model
	end

	local extents = rig:GetExtentsSize()

	local state = {
		model = model,
		humanoid = humanoid,
		root = root,
		tracks = {},
		connections = {},
		alive = true,
		busy = false,
		lastAttack = 0,
		mode = "Idle",
		target = nil,
		home = nil,
		lastPosition = nil,
		path = nil,
		pathComputedAt = 0,
		agentParams = {
			AgentRadius = math.clamp(math.max(extents.X, extents.Z) / 2, 1, 10),
			AgentHeight = math.clamp(extents.Y, 2, 30),
			AgentCanJump = false,
		},
	}

	controllers[model] = state

	for _, animation in ipairs(folder:GetChildren()) do
		if animation:IsA("Animation") then
			local resolved = resolveAnimation(model, animation)

			if resolved then
				local track = animator:LoadAnimation(resolved)
				state.tracks[animation.Name] = track

				for _, markerName in ipairs(MARKERS) do
					table.insert(
						state.connections,
						track:GetMarkerReachedSignal(markerName):Connect(function(value)
							markerEvent:Fire(animation.Name, markerName, value)
						end)
					)
				end
			end
		end
	end

	if state.tracks.Attack then
		table.insert(
			state.connections,
			state.tracks.Attack:GetMarkerReachedSignal("Hit"):Connect(function()
				dealDamage(state)
			end)
		)
	end

	if state.tracks.Idle then
		state.tracks.Idle:Play()
	end

	table.insert(
		state.connections,
		humanoid.Running:Connect(function(speed)
			local walk = state.tracks.Walk

			if not walk then
				return
			end

			if speed > 0.5 then
				if not walk.IsPlaying then
					walk:Play(0.25)
				end

				walk:AdjustSpeed(math.clamp(speed / math.max(getSetting(model, "WalkSpeed"), 1), 0.5, 2))
			elseif walk.IsPlaying then
				walk:Stop(0.3)
			end
		end)
	)

	table.insert(
		state.connections,
		model:GetAttributeChangedSignal("USARF_Breached"):Connect(function()
			task.defer(onBreachedChanged, state)
		end)
	)

	root.Anchored = false
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	humanoid.WalkSpeed = getSetting(model, "WalkSpeed")
	settle(state)

	task.spawn(function()
		while state.alive and model.Parent do
			task.wait(THINK_INTERVAL)

			local success, result = pcall(think, state)

			if not success then
				warn("[EntityControllerService] " .. model.Name .. ": " .. tostring(result))
				state.busy = false
			end
		end
	end)
end

function EntityControllerService.Start()
	if started then
		return
	end

	started = true

	for _, model in ipairs(CollectionService:GetTagged(TAG)) do
		task.spawn(attach, model)
	end

	CollectionService:GetInstanceAddedSignal(TAG):Connect(attach)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(detach)

	print("[EntityControllerService] Started")
end

return EntityControllerService
