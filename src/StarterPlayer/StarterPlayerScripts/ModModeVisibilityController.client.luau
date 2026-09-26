local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local MOD_CLOAK_TRANSPARENCY = 0.55
local MOD_OUTLINE_COLOR = Color3.fromRGB(155, 95, 255)

local tracked = {}

local function isModMode()
	return LocalPlayer:GetAttribute("USARF_ModMode") == true
		or LocalPlayer:GetAttribute("USARF_RadioModMode") == true
end

local function isCloaked(player)
	if player:GetAttribute("USARF_Cloaked") == true then
		return true
	end

	local character = player.Character
	return character and character:GetAttribute("USARF_Cloaked") == true
end

local function isScrambled(player)
	if player:GetAttribute("USARF_Scrambled") == true then
		return true
	end

	local character = player.Character
	return character and character:GetAttribute("USARF_Scrambled") == true
end

local function getOrCreateHighlight(character)
	local highlight = character:FindFirstChild("USARF_ModModeCloakHighlight")

	if highlight then
		return highlight
	end

	highlight = Instance.new("Highlight")
	highlight.Name = "USARF_ModModeCloakHighlight"
	highlight.FillTransparency = 0.82
	highlight.OutlineTransparency = 0.15
	highlight.FillColor = MOD_OUTLINE_COLOR
	highlight.OutlineColor = MOD_OUTLINE_COLOR
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	return highlight
end

local function removeHighlight(character)
	local highlight = character and character:FindFirstChild("USARF_ModModeCloakHighlight")
	if highlight then
		highlight:Destroy()
	end
end

local function findScramblerBillboard(character)
	if not character then
		return nil
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BillboardGui") and string.find(string.lower(descendant.Name), "scrambler", 1, true) then
			return descendant
		end
	end

	return nil
end

local function setScramblerBillboardText(player, reveal)
	local character = player.Character
	if not character then
		return
	end

	local billboard = findScramblerBillboard(character)
	if not billboard then
		return
	end

	local container = billboard:FindFirstChild("Container")
	if not container then
		return
	end

	local top = container:FindFirstChild("Top")
	local main = container:FindFirstChild("Main")
	local bottom = container:FindFirstChild("Bottom")

	if reveal then
		if top then
			top.Text = "MODMODE REVEAL"
			top.TextColor3 = Color3.fromRGB(155, 95, 255)
		end

		if main then
			main.Text = player.Name
			main.TextColor3 = Color3.fromRGB(255, 255, 255)
		end

		if bottom then
			bottom.Text = "SCRAMBLED PERSONNEL"
			bottom.TextColor3 = Color3.fromRGB(190, 160, 255)
		end
	else
		if top then
			top.Text = "████████"
			top.TextColor3 = Color3.fromRGB(155, 155, 155)
		end

		if main then
			main.Text = "REDACTED"
			main.TextColor3 = Color3.fromRGB(245, 245, 245)
		end

		if bottom then
			bottom.Text = "CLASSIFIED PERSONNEL"
			bottom.TextColor3 = Color3.fromRGB(185, 185, 185)
		end
	end
end

local function applyLocalVisibility(player)
	if player == LocalPlayer then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local modMode = isModMode()
	local cloaked = isCloaked(player)
	local scrambled = isScrambled(player)

	if not tracked[player] then
		tracked[player] = {}
	end

	if modMode and cloaked then
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
				if tracked[player][descendant] == nil then
					tracked[player][descendant] = descendant.LocalTransparencyModifier
				end

				descendant.LocalTransparencyModifier = MOD_CLOAK_TRANSPARENCY
			elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
				if tracked[player][descendant] == nil then
					tracked[player][descendant] = descendant.Transparency
				end

				descendant.Transparency = MOD_CLOAK_TRANSPARENCY
			elseif descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
				if descendant.Name == "USARFNameTag" or string.find(string.lower(descendant.Name), "nametag", 1, true) then
					descendant.Enabled = true
				end
			end
		end

		getOrCreateHighlight(character)
	else
		if tracked[player] then
			for instance, originalValue in pairs(tracked[player]) do
				if instance and instance.Parent then
					if instance:IsA("BasePart") then
						instance.LocalTransparencyModifier = originalValue
					elseif instance:IsA("Decal") or instance:IsA("Texture") then
						instance.Transparency = originalValue
					end
				end
			end
		end

		tracked[player] = {}
		removeHighlight(character)
	end

	setScramblerBillboardText(player, modMode and scrambled)
end

local function refreshAll()
	for _, player in ipairs(Players:GetPlayers()) do
		applyLocalVisibility(player)
	end
end

local function setupPlayer(player)
	player:GetAttributeChangedSignal("USARF_Cloaked"):Connect(refreshAll)
	player:GetAttributeChangedSignal("USARF_Scrambled"):Connect(refreshAll)

	player.CharacterAdded:Connect(function(character)
		character:GetAttributeChangedSignal("USARF_Cloaked"):Connect(refreshAll)
		character:GetAttributeChangedSignal("USARF_Scrambled"):Connect(refreshAll)

		character.DescendantAdded:Connect(function()
			task.wait(0.05)
			applyLocalVisibility(player)
		end)

		task.wait(0.5)
		applyLocalVisibility(player)
	end)

	if player.Character then
		player.Character:GetAttributeChangedSignal("USARF_Cloaked"):Connect(refreshAll)
		player.Character:GetAttributeChangedSignal("USARF_Scrambled"):Connect(refreshAll)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
	tracked[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

LocalPlayer:GetAttributeChangedSignal("USARF_ModMode"):Connect(refreshAll)
LocalPlayer:GetAttributeChangedSignal("USARF_RadioModMode"):Connect(refreshAll)

RunService.Heartbeat:Connect(function()
	if isModMode() then
		refreshAll()
	end
end)

refreshAll()

print("[ModModeVisibilityController] initialized")