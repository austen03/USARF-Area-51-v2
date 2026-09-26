local WeaponEffectsController = {}

local Debris = game:GetService("Debris")

local context = nil

local MATERIAL_SOUND_NAMES = {
	Metal = "ImpactMetal",
	CorrodedMetal = "ImpactMetal",
	DiamondPlate = "ImpactMetal",

	Concrete = "ImpactConcrete",
	Slate = "ImpactConcrete",
	Brick = "ImpactConcrete",

	Wood = "ImpactWood",
	WoodPlanks = "ImpactWood",

	Glass = "ImpactGlass",

	Flesh = "ImpactFlesh",
	Default = "ImpactDefault",
}

local function getBulletPointFromTool(targetTool)
	targetTool = targetTool or (context and context.Tool)
	if not targetTool then
		return nil
	end

	local bulletPoint = targetTool:FindFirstChild("BulletPoint", true)
	if bulletPoint and bulletPoint:IsA("BasePart") then
		return bulletPoint
	end

	local handle = targetTool:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		return handle
	end

	return nil
end

local function getEjectionPointFromTool(targetTool)
	targetTool = targetTool or (context and context.Tool)
	if not targetTool then
		return nil
	end

	local shellConfig = context and context.Config and context.Config.ShellEjection or {}
	local partName = shellConfig.PartName or "BulletEjection"

	local point = targetTool:FindFirstChild(partName, true)
	if point and point:IsA("BasePart") then
		return point
	end

	return nil
end

local function randomRange(amount)
	return (math.random() * 2 - 1) * (amount or 0)
end

local function randomVector(rangeVector)
	rangeVector = rangeVector or Vector3.new(0, 0, 0)

	return Vector3.new(
		randomRange(rangeVector.X),
		randomRange(rangeVector.Y),
		randomRange(rangeVector.Z)
	)
end

local function createTracer(origin, endPosition)
	if not origin or not endPosition then
		return
	end

	local distance = (endPosition - origin).Magnitude
	if distance <= 0 then
		return
	end

	local tracer = Instance.new("Part")
	tracer.Name = "USARF_Tracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanTouch = false
	tracer.CanQuery = false
	tracer.Material = Enum.Material.Neon
	tracer.Transparency = 0.2
	tracer.Size = Vector3.new(0.045, 0.045, distance)
	tracer.CFrame = CFrame.lookAt(origin, endPosition) * CFrame.new(0, 0, -distance / 2)
	tracer.Parent = workspace

	Debris:AddItem(tracer, 0.045)
end

local function createImpactBurst(position, normal, amount, color, material, size, speed, lifetime)
	normal = normal or Vector3.new(0, 1, 0)

	for _ = 1, amount do
		local shard = Instance.new("Part")
		shard.Name = "USARF_ImpactShard"
		shard.Anchored = false
		shard.CanCollide = false
		shard.CanTouch = false
		shard.CanQuery = false
		shard.Material = material or Enum.Material.SmoothPlastic
		shard.Color = color or Color3.fromRGB(180, 180, 180)
		shard.Size = size or Vector3.new(0.06, 0.06, 0.06)
		shard.CFrame = CFrame.new(position + normal * 0.08)
		shard.Parent = workspace

		local side = Vector3.new(
			randomRange(1),
			randomRange(1),
			randomRange(1)
		)

		local direction = (normal + side * 0.75).Unit
		shard.AssemblyLinearVelocity = direction * math.random(speed.Min, speed.Max)
		shard.AssemblyAngularVelocity = Vector3.new(
			randomRange(20),
			randomRange(20),
			randomRange(20)
		)

		Debris:AddItem(shard, lifetime or 0.35)
	end
end

local function createDustPuff(position, normal, color)
	for _ = 1, 6 do
		local puff = Instance.new("Part")
		puff.Name = "USARF_DustPuff"
		puff.Anchored = true
		puff.CanCollide = false
		puff.CanTouch = false
		puff.CanQuery = false
		puff.Material = Enum.Material.SmoothPlastic
		puff.Color = color or Color3.fromRGB(160, 155, 140)
		puff.Transparency = 0.25
		puff.Shape = Enum.PartType.Ball
		puff.Size = Vector3.new(0.12, 0.12, 0.12)
		puff.CFrame = CFrame.new(position + normal * 0.06 + randomVector(Vector3.new(0.12, 0.12, 0.12)))
		puff.Parent = workspace

		task.spawn(function()
			for i = 1, 10 do
				if not puff.Parent then
					return
				end

				local scale = 1 + i * 0.12
				puff.Size = Vector3.new(0.12, 0.12, 0.12) * scale
				puff.Transparency = 0.25 + i * 0.075
				task.wait(0.02)
			end

			if puff then
				puff:Destroy()
			end
		end)
	end
end

local function playImpactSound(position, soundName)
	if not context or not context.Tool then
		return
	end

	local soundsFolder = context.Tool:FindFirstChild("Sounds")
	if not soundsFolder then
		return
	end

	local sourceSound = soundsFolder:FindFirstChild(soundName)
	if not sourceSound or not sourceSound:IsA("Sound") then
		sourceSound = soundsFolder:FindFirstChild("ImpactDefault")
	end

	if not sourceSound or not sourceSound:IsA("Sound") then
		return
	end

	local soundPart = Instance.new("Part")
	soundPart.Name = "USARF_ImpactSound"
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.CanTouch = false
	soundPart.CanQuery = false
	soundPart.Transparency = 1
	soundPart.Size = Vector3.new(0.2, 0.2, 0.2)
	soundPart.Position = position
	soundPart.Parent = workspace

	local sound = sourceSound:Clone()
	sound.Parent = soundPart
	sound:Play()

	Debris:AddItem(soundPart, math.max(sound.TimeLength, 1))
end

local function getImpactSoundName(payload)
	if payload.IsHumanoid then
		return MATERIAL_SOUND_NAMES.Flesh
	end

	local material = tostring(payload.Material or "Default"):gsub("Enum.Material.", "")
	return MATERIAL_SOUND_NAMES[material] or MATERIAL_SOUND_NAMES.Default
end

function WeaponEffectsController.PlayImpact(payload)
	if not payload or typeof(payload.Position) ~= "Vector3" then
		return
	end

	local position = payload.Position
	local normal = payload.Normal

	if typeof(normal) ~= "Vector3" then
		normal = Vector3.new(0, 1, 0)
	end

	local material = tostring(payload.Material or "Default"):gsub("Enum.Material.", "")

	if payload.IsHumanoid then
		createImpactBurst(
			position,
			normal,
			8,
			Color3.fromRGB(145, 25, 25),
			Enum.Material.SmoothPlastic,
			Vector3.new(0.055, 0.055, 0.055),
			NumberRange.new(3, 7),
			0.35
		)
	elseif material == "Metal" or material == "CorrodedMetal" or material == "DiamondPlate" then
		createImpactBurst(
			position,
			normal,
			14,
			Color3.fromRGB(255, 195, 75),
			Enum.Material.Neon,
			Vector3.new(0.035, 0.035, 0.11),
			NumberRange.new(10, 22),
			0.22
		)
	elseif material == "Wood" or material == "WoodPlanks" then
		createImpactBurst(
			position,
			normal,
			10,
			Color3.fromRGB(120, 78, 42),
			Enum.Material.Wood,
			Vector3.new(0.045, 0.045, 0.12),
			NumberRange.new(5, 12),
			0.45
		)
	elseif material == "Glass" then
		createImpactBurst(
			position,
			normal,
			16,
			Color3.fromRGB(210, 240, 255),
			Enum.Material.Glass,
			Vector3.new(0.04, 0.04, 0.04),
			NumberRange.new(6, 14),
			0.5
		)
	else
		createDustPuff(position, normal, Color3.fromRGB(160, 155, 140))
	end

	playImpactSound(position, getImpactSoundName(payload))
end

function WeaponEffectsController.EjectShell(targetTool)
	if not context or not context.Config then
		return
	end

	local shellConfig = context.Config.ShellEjection or {}
	if shellConfig.Enabled == false then
		return
	end

	local ejectionPoint = getEjectionPointFromTool(targetTool)
	if not ejectionPoint then
		return
	end

	local casing = Instance.new("Part")
	casing.Name = "USARF_ShellCasing"
	casing.Anchored = false
	casing.CanCollide = true
	casing.CanTouch = false
	casing.CanQuery = false
	casing.Massless = false
	casing.Size = shellConfig.Size or Vector3.new(0.12, 0.12, 0.32)
	casing.Color = shellConfig.Color or Color3.fromRGB(214, 170, 70)
	casing.Material = shellConfig.Material or Enum.Material.Metal
	casing.CFrame = ejectionPoint.CFrame
	casing.Parent = workspace

	local mesh = Instance.new("CylinderMesh")
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = casing

	local baseVelocity = shellConfig.Velocity or Vector3.new(8, 5, 2)
	local randomVelocity = shellConfig.RandomVelocity or Vector3.new(3, 2, 3)

	local localVelocity = baseVelocity + randomVector(randomVelocity)
	local worldVelocity =
		(ejectionPoint.CFrame.RightVector * localVelocity.X)
		+ (ejectionPoint.CFrame.UpVector * localVelocity.Y)
		+ (ejectionPoint.CFrame.LookVector * localVelocity.Z)

	casing.AssemblyLinearVelocity = worldVelocity

	local baseSpin = shellConfig.Spin or Vector3.new(18, 35, 12)
	local randomSpin = shellConfig.RandomSpin or Vector3.new(8, 10, 8)

	casing.AssemblyAngularVelocity = baseSpin + randomVector(randomSpin)

	Debris:AddItem(casing, shellConfig.LifeTime or 4)
end

function WeaponEffectsController.PlayMuzzleFX(targetTool, origin, endPosition)
	local bulletPoint = getBulletPointFromTool(targetTool)

	if bulletPoint then
		for _, descendant in ipairs(bulletPoint:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				descendant:Emit(descendant:GetAttribute("EmitCount") or 8)
			elseif descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
				descendant.Enabled = true

				task.delay(0.045, function()
					if descendant then
						descendant.Enabled = false
					end
				end)
			end
		end
	end

	if origin and endPosition then
		createTracer(origin, endPosition)
	end
end

function WeaponEffectsController.PlaySound(soundName)
	if not context or not context.Tool or not soundName then
		return
	end

	local soundsFolder = context.Tool:FindFirstChild("Sounds")
	if not soundsFolder then
		return
	end

	local sound = soundsFolder:FindFirstChild(soundName)

	if sound and sound:IsA("Sound") then
		sound:Play()
	end
end

function WeaponEffectsController.Start(newContext)
	context = newContext
end

function WeaponEffectsController.Stop()
	context = nil
end

return WeaponEffectsController