local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Config = require(USARFServer:WaitForChild("Config"):WaitForChild("RibbonRackConfig"))

local RibbonRackService = {}

local started = false

-- Set on the character by UniformService whenever a uniform is applied or cleared.
local UNIFORM_APPLIED_ATTRIBUTE = "USARFUniformApplied"

local playerConnections = {}
local characterConnections = {}
local folderConnections = {}

-- [userId] = { [medalKey] = true }, loaded from the Google Sheet.
local sheetMedals = {}
local sheetFetching = false

local function normalizeName(value)
	return (string.lower(tostring(value)):gsub("[^%w]", ""))
end

-- Normalized Key / DisplayName / Alias -> definition.
local definitionsByName = {}

for _, definition in ipairs(Config.Medals) do
	definitionsByName[normalizeName(definition.Key)] = definition
	definitionsByName[normalizeName(definition.DisplayName)] = definition

	for _, alias in ipairs(definition.Aliases or {}) do
		definitionsByName[normalizeName(alias)] = definition
	end
end

local function resolveMedal(name)
	local definition = definitionsByName[normalizeName(name)]

	if definition and definition.Enabled ~= false then
		return definition
	end

	return nil
end

local function disconnectConnections(connectionList)
	for _, connection in ipairs(connectionList or {}) do
		connection:Disconnect()
	end
end

local function getMedalSignature(owned)
	local keys = {}

	for key in pairs(owned or {}) do
		table.insert(keys, key)
	end

	table.sort(keys)
	return table.concat(keys, ",")
end

--// Ownership sources

-- Accepts an array of names or a { [name] = true } dictionary; returns { [medalKey] = true }.
local function resolveOwnedMedals(raw)
	local owned = {}

	if typeof(raw) ~= "table" then
		return owned
	end

	for key, value in pairs(raw) do
		local name = nil

		if typeof(key) == "number" and typeof(value) == "string" then
			name = value
		elseif typeof(key) == "string" and value ~= false and value ~= nil and value ~= 0 then
			name = key
		end

		local definition = name and resolveMedal(name)
		if definition then
			owned[definition.Key] = true
		end
	end

	return owned
end

local function readAttributeMedals(player)
	local value = player:GetAttribute(Config.Ownership.AttributeName)

	if typeof(value) ~= "string" or value == "" then
		return {}
	end

	local success, decoded = pcall(HttpService.JSONDecode, HttpService, value)
	if success and typeof(decoded) == "table" then
		return resolveOwnedMedals(decoded)
	end

	-- Friendly fallback for a comma-separated list.
	local names = {}
	for token in string.gmatch(value, "[^,]+") do
		table.insert(names, token)
	end

	return resolveOwnedMedals(names)
end

local function readFolderMedals(player)
	local folder = player:FindFirstChild(Config.Ownership.FolderName)
	local names = {}

	if not folder then
		return names
	end

	for _, child in ipairs(folder:GetChildren()) do
		local enabled = true

		if child:IsA("BoolValue") then
			enabled = child.Value
		elseif child:IsA("IntValue") or child:IsA("NumberValue") then
			enabled = child.Value > 0
		elseif child:IsA("StringValue") then
			enabled = child.Value ~= ""
		end

		if enabled then
			table.insert(names, child.Name)
		end
	end

	return resolveOwnedMedals(names)
end

local function mergeInto(target, source)
	for key in pairs(source) do
		target[key] = true
	end
end

--// Google Sheet

local function getRowValue(row, columnNames)
	for rowKey, value in pairs(row) do
		local normalizedRowKey = normalizeName(rowKey)

		for _, columnName in ipairs(columnNames) do
			if normalizedRowKey == normalizeName(columnName) then
				return value
			end
		end
	end

	return nil
end

-- Returns the new { [userId] = { [medalKey] = true } } map, or nil on failure.
local function fetchSheetMedals()
	local sheetConfig = Config.GoogleSheet

	if not sheetConfig.Enabled or sheetConfig.Url == "" then
		return nil
	end

	local success, body = pcall(HttpService.GetAsync, HttpService, sheetConfig.Url)
	if not success then
		warn("[RibbonRackService] Failed to fetch medal sheet:", body)
		return nil
	end

	local decodeSuccess, rows = pcall(HttpService.JSONDecode, HttpService, body)
	if not decodeSuccess or typeof(rows) ~= "table" then
		warn("[RibbonRackService] Medal sheet did not return valid JSON")
		return nil
	end

	local medalsByUserId = {}
	local unknownNames = {}

	for _, row in ipairs(rows) do
		if typeof(row) == "table" then
			local userId = tonumber(getRowValue(row, sheetConfig.UserIdColumns))
			local medalsText = getRowValue(row, sheetConfig.MedalColumns)

			if userId and medalsText ~= nil then
				local owned = medalsByUserId[userId] or {}
				medalsByUserId[userId] = owned

				for name in string.gmatch(tostring(medalsText), "[^,;\n]+") do
					local trimmed = string.match(name, "^%s*(.-)%s*$")

					if trimmed ~= "" then
						local definition = resolveMedal(trimmed)

						if definition then
							owned[definition.Key] = true
						else
							unknownNames[trimmed] = true
						end
					end
				end
			end
		end
	end

	local unknownList = {}
	for name in pairs(unknownNames) do
		table.insert(unknownList, name)
	end

	if #unknownList > 0 then
		table.sort(unknownList)
		warn("[RibbonRackService] Unknown medal names in sheet: " .. table.concat(unknownList, ", "))
	end

	return medalsByUserId
end

--// Rack building

local function getSortedDefinitions(owned)
	local definitions = {}

	for _, definition in ipairs(Config.Medals) do
		if definition.Enabled ~= false and owned[definition.Key] then
			table.insert(definitions, definition)
		end
	end

	table.sort(definitions, function(a, b)
		if a.Priority == b.Priority then
			return a.Key < b.Key
		end

		return a.Priority < b.Priority
	end)

	return definitions
end

local function findMount(character)
	local customMount = character:FindFirstChild(Config.Mount.AttachmentName, true)

	if customMount then
		if customMount:IsA("Attachment") and customMount.Parent:IsA("BasePart") then
			return customMount.Parent, customMount.WorldCFrame * Config.Mount.AttachmentAdjustment
		elseif customMount:IsA("BasePart") then
			return customMount, customMount.CFrame * Config.Mount.AttachmentAdjustment
		end
	end

	local upperTorso = character:FindFirstChild("UpperTorso")
	if upperTorso and upperTorso:IsA("BasePart") then
		return upperTorso, upperTorso.CFrame * Config.Mount.UpperTorsoOffset
	end

	return nil, nil
end

local function destroyExistingRack(character)
	local existing = character:FindFirstChild(Config.Rack.Name)

	if existing then
		existing:Destroy()
	end
end

local function createRibbonImage(surfaceGui, definition, x, y, width, height, layoutOrder)
	local image = Instance.new("ImageLabel")
	image.Name = definition.Key
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Position = UDim2.fromOffset(x, y)
	image.Size = UDim2.fromOffset(width, height)
	image.Image = "rbxassetid://" .. tostring(definition.ImageId)

	-- Crop away the image's transparent padding and stretch the ribbon to fill its slot,
	-- so neighbouring ribbons touch.
	local rect = definition.ImageRect
	if rect then
		local inset = Config.Rack.CropInsetPixels or 0
		image.ImageRectOffset = Vector2.new(rect[1] + inset, rect[2] + inset)
		image.ImageRectSize = Vector2.new(rect[3] - inset * 2, rect[4] - inset * 2)
		image.ScaleType = Enum.ScaleType.Stretch
	else
		image.ScaleType = Enum.ScaleType.Fit
	end

	image.LayoutOrder = layoutOrder
	image.ZIndex = 2
	image:SetAttribute("DisplayName", definition.DisplayName)
	image:SetAttribute("Priority", definition.Priority)
	image.Parent = surfaceGui

	return image
end

local function createRack(character, definitions)
	local rackConfig = Config.Rack
	local total = #definitions
	local columns = math.min(rackConfig.MaxColumns, total)
	local rows = math.ceil(total / rackConfig.MaxColumns)

	local rackWidth = columns * rackConfig.RibbonWidth
		+ math.max(0, columns - 1) * rackConfig.HorizontalGap
	local rackHeight = rows * rackConfig.RibbonHeight
		+ math.max(0, rows - 1) * rackConfig.VerticalGap

	local anchorPart, mountCFrame = findMount(character)
	if not anchorPart or not mountCFrame then
		warn("[RibbonRackService] No UpperTorso or custom medal mount for " .. character:GetFullName())
		return nil
	end

	local rack = Instance.new("Part")
	rack.Name = rackConfig.Name
	rack.Size = Vector3.new(rackWidth, rackHeight, rackConfig.Depth)
	-- Bottom-anchored racks grow upward from the mount point; top-anchored racks grow downward.
	local growDirection = Config.Mount.AnchorEdge == "Bottom" and 1 or -1
	rack.CFrame = mountCFrame * CFrame.new(0, growDirection * rackHeight / 2, 0)
	rack.Transparency = 1
	rack.CastShadow = false
	rack.Anchored = false
	rack.Massless = true
	rack.CanCollide = false
	rack.CanTouch = false
	rack.CanQuery = false
	rack:SetAttribute("MedalCount", total)
	rack:SetAttribute("HighestPriorityMedal", definitions[1].Key)
	rack.Parent = character

	local canvasWidth = columns * rackConfig.PixelWidth
		+ math.max(0, columns - 1) * rackConfig.PixelGap
	local canvasHeight = rows * rackConfig.PixelHeight
		+ math.max(0, rows - 1) * rackConfig.PixelGap

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "Ribbons"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	surfaceGui.CanvasSize = Vector2.new(canvasWidth, canvasHeight)
	surfaceGui.AlwaysOnTop = Config.Rendering.AlwaysOnTop
	surfaceGui.LightInfluence = Config.Rendering.LightInfluence
	surfaceGui.ZOffset = Config.Rendering.ZOffset
	surfaceGui.Parent = rack

	-- The top row holds the remainder and is centered; lower rows are full.
	local remainder = total % rackConfig.MaxColumns
	local firstRowCount = remainder == 0 and rackConfig.MaxColumns or remainder
	local definitionIndex = 1

	for row = 1, rows do
		local rowCount = row == 1 and firstRowCount or rackConfig.MaxColumns
		local rowPixelWidth = rowCount * rackConfig.PixelWidth
			+ math.max(0, rowCount - 1) * rackConfig.PixelGap
		local startX = math.floor((canvasWidth - rowPixelWidth) / 2)
		local y = (row - 1) * (rackConfig.PixelHeight + rackConfig.PixelGap)

		for column = 1, rowCount do
			local definition = definitions[definitionIndex]
			local x = startX + (column - 1) * (rackConfig.PixelWidth + rackConfig.PixelGap)

			createRibbonImage(
				surfaceGui,
				definition,
				x,
				y,
				rackConfig.PixelWidth,
				rackConfig.PixelHeight,
				definitionIndex
			)

			definitionIndex += 1
		end
	end

	local weld = Instance.new("WeldConstraint")
	weld.Name = "MedalRackWeld"
	weld.Part0 = anchorPart
	weld.Part1 = rack
	weld.Parent = rack

	return rack
end

--// Public API

-- All medals the player currently wears: sheet + temporary (attribute / Medals folder).
function RibbonRackService.GetOwnedMedals(player)
	local owned = {}

	mergeInto(owned, sheetMedals[player.UserId] or {})
	mergeInto(owned, readAttributeMedals(player))
	mergeInto(owned, readFolderMedals(player))

	if Config.Testing.GrantAllInStudio and RunService:IsStudio() then
		for _, definition in ipairs(Config.Medals) do
			if definition.Enabled ~= false then
				owned[definition.Key] = true
			end
		end
	end

	return owned
end

function RibbonRackService.BuildForCharacter(player, character)
	destroyExistingRack(character)

	local definitions = getSortedDefinitions(RibbonRackService.GetOwnedMedals(player))
	if #definitions == 0 then
		return nil
	end

	return createRack(character, definitions)
end

function RibbonRackService.RefreshPlayer(player)
	local character = player.Character

	if not character or not character.Parent then
		return nil
	end

	return RibbonRackService.BuildForCharacter(player, character)
end

-- Re-reads the Google Sheet now and rebuilds racks for players whose medals changed.
function RibbonRackService.RefreshSheet()
	if sheetFetching then
		return false
	end

	sheetFetching = true
	local newSheetMedals = fetchSheetMedals()
	sheetFetching = false

	if not newSheetMedals then
		return false
	end

	local oldSheetMedals = sheetMedals
	sheetMedals = newSheetMedals

	for _, player in ipairs(Players:GetPlayers()) do
		local oldSignature = getMedalSignature(oldSheetMedals[player.UserId])
		local newSignature = getMedalSignature(newSheetMedals[player.UserId])

		if oldSignature ~= newSignature then
			RibbonRackService.RefreshPlayer(player)
		end
	end

	return true
end

-- Temporary medals only (stored in the player attribute for this server).
-- Sheet medals are not affected; edit the sheet to change those permanently.
function RibbonRackService.SetPlayerMedals(player, medalKeys)
	local owned = resolveOwnedMedals(medalKeys)
	local orderedKeys = {}

	for _, definition in ipairs(Config.Medals) do
		if owned[definition.Key] then
			table.insert(orderedKeys, definition.Key)
		end
	end

	player:SetAttribute(Config.Ownership.AttributeName, HttpService:JSONEncode(orderedKeys))
	return RibbonRackService.RefreshPlayer(player)
end

function RibbonRackService.GrantMedal(player, medalName)
	local owned = readAttributeMedals(player)
	local definition = resolveMedal(medalName)

	if definition then
		owned[definition.Key] = true
	end

	return RibbonRackService.SetPlayerMedals(player, owned)
end

function RibbonRackService.RevokeMedal(player, medalName)
	local owned = readAttributeMedals(player)
	local definition = resolveMedal(medalName)

	if definition then
		owned[definition.Key] = nil
	end

	return RibbonRackService.SetPlayerMedals(player, owned)
end

function RibbonRackService.GetAllMedalKeys()
	local keys = {}

	for _, definition in ipairs(Config.Medals) do
		if definition.Enabled ~= false then
			table.insert(keys, definition.Key)
		end
	end

	return keys
end

function RibbonRackService.GetMedalDefinitions()
	return Config.Medals
end

--// Player lifecycle

local function refreshLater(player, delaySeconds)
	task.delay(delaySeconds or 0, function()
		if player.Parent == Players then
			RibbonRackService.RefreshPlayer(player)
		end
	end)
end

local function watchMedalFolder(player)
	disconnectConnections(folderConnections[player])
	folderConnections[player] = {}

	local folder = player:FindFirstChild(Config.Ownership.FolderName)
	if not folder then
		return
	end

	local connections = folderConnections[player]

	local function watchValue(instance)
		if instance:IsA("ValueBase") then
			table.insert(connections, instance.Changed:Connect(function()
				refreshLater(player)
			end))
		end
	end

	for _, descendant in ipairs(folder:GetDescendants()) do
		watchValue(descendant)
	end

	table.insert(connections, folder.DescendantAdded:Connect(function(descendant)
		watchValue(descendant)
		refreshLater(player)
	end))

	table.insert(connections, folder.DescendantRemoving:Connect(function()
		refreshLater(player)
	end))
end

local function onCharacterAdded(player, character)
	disconnectConnections(characterConnections[player])
	characterConnections[player] = {}

	-- First pass handles normal character spawning.
	refreshLater(player, 0.25)

	-- Second pass allows morph/vest systems time to insert a custom mount.
	refreshLater(player, 1.5)

	table.insert(characterConnections[player], character.DescendantAdded:Connect(function(descendant)
		if descendant.Name == Config.Mount.AttachmentName then
			refreshLater(player)
		end
	end))

	-- Applying or clearing a uniform can reset the avatar and replace the UpperTorso
	-- the rack is welded to, so rebuild afterwards.
	table.insert(characterConnections[player], character:GetAttributeChangedSignal(UNIFORM_APPLIED_ATTRIBUTE):Connect(function()
		refreshLater(player, 0.1)
	end))
end

local function onPlayerAdded(player)
	playerConnections[player] = {}

	table.insert(playerConnections[player], player:GetAttributeChangedSignal(Config.Ownership.AttributeName):Connect(function()
		refreshLater(player)
	end))

	table.insert(playerConnections[player], player.ChildAdded:Connect(function(child)
		if child.Name == Config.Ownership.FolderName then
			watchMedalFolder(player)
			refreshLater(player)
		end
	end))

	table.insert(playerConnections[player], player.ChildRemoved:Connect(function(child)
		if child.Name == Config.Ownership.FolderName then
			watchMedalFolder(player)
			refreshLater(player)
		end
	end))

	table.insert(playerConnections[player], player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end))

	watchMedalFolder(player)

	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player)
	disconnectConnections(playerConnections[player])
	disconnectConnections(characterConnections[player])
	disconnectConnections(folderConnections[player])

	playerConnections[player] = nil
	characterConnections[player] = nil
	folderConnections[player] = nil
end

function RibbonRackService.Start()
	if started then
		return
	end

	started = true

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	if Config.GoogleSheet.Enabled then
		task.spawn(function()
			while true do
				RibbonRackService.RefreshSheet()
				task.wait(Config.GoogleSheet.CacheSeconds or 300)
			end
		end)
	end

	print("[RibbonRackService] Started")
end

return RibbonRackService
