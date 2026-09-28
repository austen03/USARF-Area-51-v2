return function(context, target, power, radius)
	if not target or not target.Character then
		return "Target has no character."
	end

	local character = target.Character
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not root then
		return "Target has no HumanoidRootPart."
	end

	power = tonumber(power) or 100
	radius = tonumber(radius) or 8

	local godField = character:FindFirstChild("USARF_GodModeForceField")
	if godField then
		godField:Destroy()
	end

	target:SetAttribute("USARF_GodMode", false)

	local explosion = Instance.new("Explosion")
	explosion.Position = root.Position
	explosion.BlastPressure = math.clamp(power * 5000, 0, 500000)
	explosion.BlastRadius = math.clamp(radius, 1, 40)
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace

	if humanoid then
		humanoid.MaxHealth = math.min(humanoid.MaxHealth, 100)
		humanoid.Health = 0
	end

	return "Exploded " .. target.Name .. "."
end
