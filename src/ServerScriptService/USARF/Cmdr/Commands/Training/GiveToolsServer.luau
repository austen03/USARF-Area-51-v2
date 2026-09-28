local function removeExisting(container, toolName)
	if not container then
		return
	end

	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") and child.Name == toolName then
			child:Destroy()
		end
	end
end

return function(context, target, tool)
	if not target then
		return "Missing target."
	end

	if not tool or not tool:IsA("Tool") then
		return "Invalid tool."
	end

	local backpack = target:FindFirstChild("Backpack")
	if not backpack then
		return "Target has no Backpack."
	end

	removeExisting(backpack, tool.Name)

	if target.Character then
		removeExisting(target.Character, tool.Name)
	end

	local clone = tool:Clone()
	clone.Parent = backpack

	return "Gave " .. tool.Name .. " to " .. target.Name .. "."
end
