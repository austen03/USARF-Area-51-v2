local function setCharacterInvisible(character, invisible)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if descendant.Name ~= "HumanoidRootPart" then
				descendant.Transparency = invisible and 1 or 0
			end
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = invisible and 1 or 0
		elseif descendant:IsA("BillboardGui") then
			if descendant.Name == "USARFNameTag" then
				descendant.Enabled = not invisible
			end
		end
	end
end

return function(context, target, invisible)
	if not target or not target.Character then
		return "Target has no character."
	end

	local current = target:GetAttribute("USARF_Invisible") == true
	local newState = invisible

	if newState == nil then
		newState = not current
	end

	target:SetAttribute("USARF_Invisible", newState == true)
	setCharacterInvisible(target.Character, newState == true)

	return target.Name .. " is now " .. (newState and "invisible." or "visible.")
end
