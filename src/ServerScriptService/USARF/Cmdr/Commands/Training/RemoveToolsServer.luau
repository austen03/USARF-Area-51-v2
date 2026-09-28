local function removeTool(container, toolName)
	if not container then
		return false
	end

	local removed = false

	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") and child.Name == toolName then
			child:Destroy()
			removed = true
		end
	end

	return removed
end

return function(context, target, tool)
	if not target then
		return "Missing target."
	end

	if not tool or not tool:IsA("Tool") then
		return "Invalid tool."
	end

	local removed = false

	removed = removeTool(target:FindFirstChild("Backpack"), tool.Name) or removed

	if target.Character then
		removed = removeTool(target.Character, tool.Name) or removed
	end

	if removed then
		return "Removed " .. tool.Name .. " from " .. target.Name .. "."
	end

	return target.Name .. " does not currently have " .. tool.Name .. "."
end
