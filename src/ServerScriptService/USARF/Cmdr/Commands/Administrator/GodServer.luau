return function(context, target, enabled)
	if not target or not target.Character then
		return "Target has no character."
	end

	local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return "Target has no humanoid."
	end

	local current = target:GetAttribute("USARF_GodMode") == true
	local newState = enabled

	if newState == nil then
		newState = not current
	end

	target:SetAttribute("USARF_GodMode", newState == true)

	if newState then
		target:SetAttribute("USARF_PreGodMaxHealth", humanoid.MaxHealth)
		target:SetAttribute("USARF_PreGodHealth", humanoid.Health)

		humanoid.MaxHealth = 1000000000
		humanoid.Health = humanoid.MaxHealth

		local forceField = target.Character:FindFirstChild("USARF_GodModeForceField")
		if not forceField then
			forceField = Instance.new("ForceField")
			forceField.Name = "USARF_GodModeForceField"
			forceField.Visible = false
			forceField.Parent = target.Character
		end

		return "God mode enabled for " .. target.Name .. "."
	end

	local forceField = target.Character:FindFirstChild("USARF_GodModeForceField")
	if forceField then
		forceField:Destroy()
	end

	local oldMax = tonumber(target:GetAttribute("USARF_PreGodMaxHealth")) or 100

	humanoid.MaxHealth = oldMax
	humanoid.Health = oldMax

	target:SetAttribute("USARF_PreGodMaxHealth", nil)
	target:SetAttribute("USARF_PreGodHealth", nil)

	return "God mode disabled for " .. target.Name .. "."
end
