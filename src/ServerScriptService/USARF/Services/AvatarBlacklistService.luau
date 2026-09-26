local AvatarEditorService = game:GetService("AvatarEditorService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local AvatarBlacklistService = {}

local DATASTORE_NAME = "USARF_AvatarBlacklist_v2"
local DATASTORE_KEY = "global"

local MORPH_ITEM_ATTRIBUTE = "USARFMorphItem"
local FILTER_DELAY = 0.35

local BODY_ASSET_PROPERTIES = {
	"Head",
	"Face",
	"Torso",
	"LeftArm",
	"RightArm",
	"LeftLeg",
	"RightLeg",
	"Shirt",
	"Pants",
	"GraphicTShirt",
}

local blacklist = {}
local blockedAssetIds = {}
local characterConnections = {}
local appearanceConnections = {}
local applyingCharacters = {}
local started = false
local loaded = false

local store = DataStoreService:GetDataStore(DATASTORE_NAME)

local function normalizeId(value)
	local numeric = tonumber(value)

	if not numeric or numeric <= 0 or numeric % 1 ~= 0 then
		return nil
	end

	return math.floor(numeric)
end

local function normalizeType(value)
	value = string.lower(
		tostring(value or "auto")
			:gsub("^%s+", "")
			:gsub("%s+$", "")
	)

	if value == "" then
		value = "auto"
	end

	if value ~= "auto"
		and value ~= "asset"
		and value ~= "bundle"
	then
		return nil
	end

	return value
end

local function cloneArray(values)
	local result = {}

	for _, value in ipairs(values or {}) do
		table.insert(result, value)
	end

	return result
end

local function rebuildBlockedAssetIds()
	table.clear(blockedAssetIds)

	for _, entry in pairs(blacklist) do
		for _, assetId in ipairs(entry.assetIds or {}) do
			assetId = normalizeId(assetId)

			if assetId then
				blockedAssetIds[assetId] = true
			end
		end
	end
end

local function collectBundleAssetIds(details)
	local collected = {}
	local seen = {}

	local function addId(value)
		local assetId = normalizeId(value)

		if assetId and not seen[assetId] then
			seen[assetId] = true
			table.insert(collected, assetId)
		end
	end

	local function scanItems(items)
		if type(items) ~= "table" then
			return
		end

		for _, item in pairs(items) do
			if type(item) == "table" then
				local itemType = string.lower(
					tostring(
						item.ItemType
							or item.Type
							or item.itemType
							or item.type
							or ""
					)
				)

				local candidateId =
					item.Id
					or item.ID
					or item.AssetId
					or item.assetId
					or item.id

				if itemType == ""
					or string.find(itemType, "asset", 1, true)
				then
					addId(candidateId)
				end
			end
		end
	end

	scanItems(details and details.Items)
	scanItems(details and details.BundledItems)
	scanItems(details and details.items)
	scanItems(details and details.bundledItems)

	return collected
end

local function getItemDetails(itemId, itemType)
	local enumType = itemType == "bundle"
		and Enum.AvatarItemType.Bundle
		or Enum.AvatarItemType.Asset

	local success, result = pcall(function()
		return AvatarEditorService:GetItemDetailsAsync(
			itemId,
			enumType
		)
	end)

	if not success or type(result) ~= "table" then
		return nil
	end

	return result
end

local function resolveEntry(itemId, requestedType)
	itemId = normalizeId(itemId)
	requestedType = normalizeType(requestedType)

	if not itemId then
		return nil, "Item ID must be a positive integer."
	end

	if not requestedType then
		return nil, "Item type must be auto, asset, or bundle."
	end

	local detectedType = requestedType
	local details = nil

	if requestedType == "auto" then
		details = getItemDetails(itemId, "asset")

		if details then
			detectedType = "asset"
		else
			details = getItemDetails(itemId, "bundle")

			if details then
				detectedType = "bundle"
			else
				-- Catalog lookups can occasionally fail temporarily. Treat an
				-- unresolved ID as an asset so moderation is never blocked.
				detectedType = "asset"
			end
		end
	else
		details = getItemDetails(itemId, requestedType)
	end

	local assetIds = {}

	if detectedType == "bundle" then
		assetIds = collectBundleAssetIds(details)

		if #assetIds == 0 then
			return nil,	"Bundle could not be expanded. Try again later or blacklist its individual asset IDs."
		end
	else
		table.insert(assetIds, itemId)
	end

	local name = details
		and (
			details.Name
			or details.name
			or details.ItemName
		)
		or nil

	return {
		id = itemId,
		itemType = detectedType,
		name = tostring(name or ""),
		assetIds = assetIds,
		addedAt = os.time(),
	}
end

local function serialize()
	local entries = {}

	for _, entry in pairs(blacklist) do
		table.insert(entries, {
			id = entry.id,
			itemType = entry.itemType,
			name = entry.name,
			assetIds = cloneArray(entry.assetIds),
			addedAt = entry.addedAt,
		})
	end

	table.sort(entries, function(a, b)
		return tonumber(a.id) < tonumber(b.id)
	end)

	return entries
end

local function save()
	local payload = serialize()

	local success, result = pcall(function()
		store:SetAsync(DATASTORE_KEY, payload)
	end)

	if not success then
		warn("[AvatarBlacklistService] Save failed:", result)
	end

	return success, result
end

local function load()
	local success, result = pcall(function()
		return store:GetAsync(DATASTORE_KEY)
	end)

	if not success then
		warn("[AvatarBlacklistService] Load failed:", result)
		loaded = true
		return
	end

	table.clear(blacklist)

	if type(result) == "table" then
		for _, entry in pairs(result) do
			if type(entry) == "table" then
				local id = normalizeId(entry.id)

				if id then
					local cleanAssets = {}

					for _, assetId in ipairs(entry.assetIds or {}) do
						assetId = normalizeId(assetId)

						if assetId then
							table.insert(cleanAssets, assetId)
						end
					end

					if #cleanAssets == 0
						and entry.itemType ~= "bundle"
					then
						table.insert(cleanAssets, id)
					end

					blacklist[id] = {
						id = id,
						itemType = entry.itemType == "bundle"
							and "bundle"
							or "asset",
						name = tostring(entry.name or ""),
						assetIds = cleanAssets,
						addedAt = tonumber(entry.addedAt) or 0,
					}
				end
			end
		end
	end

	rebuildBlockedAssetIds()
	loaded = true
end

local function getAccessorySourceAssetId(accessory)
	local success, value = pcall(function()
		return accessory.SourceAssetId
	end)

	if success then
		local assetId = normalizeId(value)

		if assetId then
			return assetId
		end
	end

	for _, attributeName in ipairs({
		"AssetId",
		"AccessoryAssetId",
		"SourceAssetId",
		}) do
		local assetId = normalizeId(
			accessory:GetAttribute(attributeName)
		)

		if assetId then
			return assetId
		end
	end

	return nil
end

local function removeInstancedBlockedAccessories(character)
	local removed = 0

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Accessory")
			and descendant:GetAttribute(MORPH_ITEM_ATTRIBUTE) ~= true
		then
			local sourceAssetId =
				getAccessorySourceAssetId(descendant)

			if sourceAssetId
				and blockedAssetIds[sourceAssetId] == true
			then
				descendant:Destroy()
				removed += 1
			end
		end
	end

	return removed
end

local function cleanDescription(description)
	local changed = false
	local removedIds = {}

	local accessories = description:GetAccessories(true)
	local keptAccessories = {}

	for _, accessoryInfo in ipairs(accessories) do
		local assetId = normalizeId(accessoryInfo.AssetId)

		if assetId and blockedAssetIds[assetId] == true then
			changed = true
			table.insert(removedIds, assetId)
		else
			table.insert(keptAccessories, accessoryInfo)
		end
	end

	if changed then
		description:SetAccessories(keptAccessories, true)
	end

	for _, propertyName in ipairs(BODY_ASSET_PROPERTIES) do
		local success, value = pcall(function()
			return description[propertyName]
		end)

		local assetId = success and normalizeId(value) or nil

		if assetId and blockedAssetIds[assetId] == true then
			pcall(function()
				description[propertyName] = 0
			end)

			changed = true
			table.insert(removedIds, assetId)
		end
	end

	return changed, removedIds
end

function AvatarBlacklistService.IsAssetBlocked(assetId)
	assetId = normalizeId(assetId)

	return assetId ~= nil
		and blockedAssetIds[assetId] == true
end

function AvatarBlacklistService.IsListed(itemId)
	itemId = normalizeId(itemId)

	return itemId ~= nil
		and blacklist[itemId] ~= nil
end

function AvatarBlacklistService.GetEntry(itemId)
	itemId = normalizeId(itemId)

	local entry = itemId and blacklist[itemId]

	if not entry then
		return nil
	end

	return {
		id = entry.id,
		itemType = entry.itemType,
		name = entry.name,
		assetIds = cloneArray(entry.assetIds),
		addedAt = entry.addedAt,
	}
end

function AvatarBlacklistService.List()
	return serialize()
end

function AvatarBlacklistService.Add(itemId, requestedType)
	local entry, resolveError =
		resolveEntry(itemId, requestedType)

	if not entry then
		return false, resolveError
	end

	if blacklist[entry.id] then
		return false, "That avatar item is already blacklisted."
	end

	blacklist[entry.id] = entry
	rebuildBlockedAssetIds()

	local success, result = save()

	if not success then
		blacklist[entry.id] = nil
		rebuildBlockedAssetIds()
		return false, tostring(result)
	end

	local removed = AvatarBlacklistService.FilterAllPlayers()

	return true, {
		entry = AvatarBlacklistService.GetEntry(entry.id),
		removed = removed,
	}
end

function AvatarBlacklistService.Remove(itemId)
	itemId = normalizeId(itemId)

	if not itemId then
		return false, "Item ID must be a positive integer."
	end

	local previous = blacklist[itemId]

	if not previous then
		return false, "That avatar item is not blacklisted."
	end

	blacklist[itemId] = nil
	rebuildBlockedAssetIds()

	local success, result = save()

	if not success then
		blacklist[itemId] = previous
		rebuildBlockedAssetIds()
		return false, tostring(result)
	end

	return true, itemId
end

function AvatarBlacklistService.Clear()
	local previous = table.clone(blacklist)

	table.clear(blacklist)
	rebuildBlockedAssetIds()

	local success, result = save()

	if not success then
		blacklist = previous
		rebuildBlockedAssetIds()
		return false, tostring(result)
	end

	return true
end

function AvatarBlacklistService.FilterCharacter(character)
	if not character or applyingCharacters[character] then
		return 0
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return removeInstancedBlockedAccessories(character)
	end

	applyingCharacters[character] = true

	local removedCount =
		removeInstancedBlockedAccessories(character)

	local description = nil
	local gotDescription = pcall(function()
		description = humanoid:GetAppliedDescription()
	end)

	if gotDescription
		and description
		and description:IsA("HumanoidDescription")
	then
		local changed, removedIds =
			cleanDescription(description)

		if changed then
			local applied, applyError = pcall(function()
				humanoid:ApplyDescriptionResetAsync(description)
			end)

			if not applied then
				warn(
					"[AvatarBlacklistService] Failed to apply cleaned avatar:",
					applyError
				)
			else
				removedCount += #removedIds
			end
		end

		description:Destroy()
	end

	-- ApplyDescription may reconstruct accessories. Run a final instance scan.
	removedCount +=
		removeInstancedBlockedAccessories(character)

	applyingCharacters[character] = nil

	return removedCount
end

function AvatarBlacklistService.FilterPlayer(player)
	if not player then
		return 0
	end

	return AvatarBlacklistService.FilterCharacter(
		player.Character
	)
end

function AvatarBlacklistService.FilterAllPlayers()
	local removed = 0

	for _, player in ipairs(Players:GetPlayers()) do
		removed += AvatarBlacklistService.FilterPlayer(player)
	end

	return removed
end

local function scheduleFilter(character)
	task.delay(FILTER_DELAY, function()
		if character and character.Parent then
			AvatarBlacklistService.FilterCharacter(character)
		end
	end)
end

local function watchCharacter(character)
	if not character then
		return
	end

	scheduleFilter(character)

	character.DescendantAdded:Connect(function(descendant)
		if not descendant:IsA("Accessory") then
			return
		end

		task.defer(function()
			if not descendant.Parent
				or descendant:GetAttribute(MORPH_ITEM_ATTRIBUTE) == true
			then
				return
			end

			local assetId =
				getAccessorySourceAssetId(descendant)

			if assetId
				and blockedAssetIds[assetId] == true
			then
				descendant:Destroy()
			else
				-- Some UGC accessories do not expose SourceAssetId. Recheck
				-- the full applied HumanoidDescription instead.
				scheduleFilter(character)
			end
		end)
	end)
end

local function watchPlayer(player)
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
	end

	if appearanceConnections[player] then
		appearanceConnections[player]:Disconnect()
	end

	characterConnections[player] =
		player.CharacterAdded:Connect(watchCharacter)

	appearanceConnections[player] =
		player.CharacterAppearanceLoaded:Connect(function(character)
			scheduleFilter(character)
		end)

	if player.Character then
		watchCharacter(player.Character)
	end
end

function AvatarBlacklistService.Start()
	if started then
		return
	end

	started = true
	load()

	Players.PlayerAdded:Connect(watchPlayer)

	Players.PlayerRemoving:Connect(function(player)
		if characterConnections[player] then
			characterConnections[player]:Disconnect()
			characterConnections[player] = nil
		end

		if appearanceConnections[player] then
			appearanceConnections[player]:Disconnect()
			appearanceConnections[player] = nil
		end
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end

	AvatarBlacklistService.FilterAllPlayers()

	print(
		"[AvatarBlacklistService] Started with",
		#AvatarBlacklistService.List(),
		"blocked avatar item(s)"
	)
end

function AvatarBlacklistService.IsLoaded()
	return loaded
end

return AvatarBlacklistService