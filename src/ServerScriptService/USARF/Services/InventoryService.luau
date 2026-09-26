local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local InventoryService = {}

local DATASTORE_NAME = "USARF_Inventory_v2"
local dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

local cache = {}
local saving = {}

local function getKey(userId)
	return "Player_" .. tostring(userId)
end

local function defaultInventory()
	return {
		OwnedItems = {},
		Consumables = {},
		Boosts = {},
		Loadout = {
			Primary = nil,
			Secondary = nil,
			Equipment = {},
		},
		ServerLifeLoadout = {
			Primary = nil,
			Secondary = nil,
			Equipment = {},
		},
		Metadata = {
			CreatedAt = os.time(),
			UpdatedAt = os.time(),
		},
	}
end

local function sanitizeInventory(inventory)
	if typeof(inventory) ~= "table" then
		inventory = defaultInventory()
	end

	inventory.OwnedItems = inventory.OwnedItems or {}
	inventory.Consumables = inventory.Consumables or {}
	inventory.Boosts = inventory.Boosts or {}

	inventory.Loadout = inventory.Loadout or {}
	inventory.Loadout.Primary = inventory.Loadout.Primary
	inventory.Loadout.Secondary = inventory.Loadout.Secondary
	inventory.Loadout.Equipment = inventory.Loadout.Equipment or {}

	inventory.ServerLifeLoadout = inventory.ServerLifeLoadout or {}
	inventory.ServerLifeLoadout.Primary = inventory.ServerLifeLoadout.Primary
	inventory.ServerLifeLoadout.Secondary = inventory.ServerLifeLoadout.Secondary
	inventory.ServerLifeLoadout.Equipment = inventory.ServerLifeLoadout.Equipment or {}

	inventory.Metadata = inventory.Metadata or {}
	inventory.Metadata.CreatedAt = inventory.Metadata.CreatedAt or os.time()
	inventory.Metadata.UpdatedAt = inventory.Metadata.UpdatedAt or os.time()

	return inventory
end

local function touch(inventory)
	inventory.Metadata = inventory.Metadata or {}
	inventory.Metadata.UpdatedAt = os.time()
end

function InventoryService.Load(player)
	local key = getKey(player.UserId)

	local success, result = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if not success then
		warn("[InventoryService] Failed loading inventory for " .. player.Name .. ": " .. tostring(result))
		cache[player.UserId] = defaultInventory()
		return false
	end

	cache[player.UserId] = sanitizeInventory(result)
	return true
end

function InventoryService.Save(player)
	local inventory = cache[player.UserId]

	if not inventory then
		return false
	end

	if saving[player.UserId] then
		return false
	end

	saving[player.UserId] = true
	touch(inventory)

	local success, result = pcall(function()
		dataStore:SetAsync(getKey(player.UserId), inventory)
	end)

	saving[player.UserId] = nil

	if not success then
		warn("[InventoryService] Failed saving inventory for " .. player.Name .. ": " .. tostring(result))
		return false
	end

	return true
end

function InventoryService.GetInventory(player)
	local inventory = cache[player.UserId]

	if not inventory then
		inventory = defaultInventory()
		cache[player.UserId] = inventory
	end

	return sanitizeInventory(inventory)
end

function InventoryService.HasItem(player, itemId)
	local inventory = InventoryService.GetInventory(player)
	return inventory.OwnedItems[itemId] == true
end

function InventoryService.GrantItem(player, itemId)
	local inventory = InventoryService.GetInventory(player)

	inventory.OwnedItems[itemId] = true
	touch(inventory)

	return true
end

function InventoryService.RevokeItem(player, itemId)
	local inventory = InventoryService.GetInventory(player)

	inventory.OwnedItems[itemId] = nil
	touch(inventory)

	return true
end

function InventoryService.GetConsumableCount(player, itemId)
	local inventory = InventoryService.GetInventory(player)
	return math.max(0, tonumber(inventory.Consumables[itemId]) or 0)
end

function InventoryService.AddConsumable(player, itemId, amount)
	local inventory = InventoryService.GetInventory(player)

	amount = math.max(1, math.floor(tonumber(amount) or 1))
	inventory.Consumables[itemId] = InventoryService.GetConsumableCount(player, itemId) + amount
	touch(inventory)

	return true, inventory.Consumables[itemId]
end

function InventoryService.UseConsumable(player, itemId, amount)
	local inventory = InventoryService.GetInventory(player)

	amount = math.max(1, math.floor(tonumber(amount) or 1))

	local current = InventoryService.GetConsumableCount(player, itemId)
	if current < amount then
		return false, "Not enough consumables"
	end

	inventory.Consumables[itemId] = current - amount

	if inventory.Consumables[itemId] <= 0 then
		inventory.Consumables[itemId] = nil
	end

	touch(inventory)

	return true, inventory.Consumables[itemId] or 0
end

function InventoryService.GetBoostEndsAt(player, boostKey)
	local inventory = InventoryService.GetInventory(player)
	return tonumber(inventory.Boosts[boostKey]) or 0
end

function InventoryService.IsBoostActive(player, boostKey)
	return InventoryService.GetBoostEndsAt(player, boostKey) > os.time()
end

function InventoryService.AddBoost(player, boostKey, durationSeconds, stackable)
	local inventory = InventoryService.GetInventory(player)

	durationSeconds = math.max(1, math.floor(tonumber(durationSeconds) or 1))

	local now = os.time()
	local currentEndsAt = tonumber(inventory.Boosts[boostKey]) or 0

	if stackable == true and currentEndsAt > now then
		inventory.Boosts[boostKey] = currentEndsAt + durationSeconds
	else
		inventory.Boosts[boostKey] = now + durationSeconds
	end

	touch(inventory)

	return true, inventory.Boosts[boostKey]
end

function InventoryService.SetLoadoutItem(player, slot, itemId, serverLifeOnly)
	local inventory = InventoryService.GetInventory(player)
	local target = serverLifeOnly == true and inventory.ServerLifeLoadout or inventory.Loadout

	slot = tostring(slot or "")

	if slot == "Primary" or slot == "Secondary" then
		target[slot] = itemId
	elseif slot == "Equipment" then
		target.Equipment = target.Equipment or {}

		if itemId then
			target.Equipment[itemId] = true
		end
	else
		return false, "Invalid loadout slot"
	end

	touch(inventory)

	return true
end

function InventoryService.RemoveLoadoutItem(player, slot, itemId, serverLifeOnly)
	local inventory = InventoryService.GetInventory(player)
	local target = serverLifeOnly == true and inventory.ServerLifeLoadout or inventory.Loadout

	slot = tostring(slot or "")

	if slot == "Primary" or slot == "Secondary" then
		if target[slot] == itemId or itemId == nil then
			target[slot] = nil
		end
	elseif slot == "Equipment" then
		target.Equipment = target.Equipment or {}
		target.Equipment[itemId] = nil
	else
		return false, "Invalid loadout slot"
	end

	touch(inventory)

	return true
end

function InventoryService.ClearServerLifeLoadout(player)
	local inventory = InventoryService.GetInventory(player)

	inventory.ServerLifeLoadout = {
		Primary = nil,
		Secondary = nil,
		Equipment = {},
	}

	touch(inventory)

	return true
end

function InventoryService.Start()
	Players.PlayerAdded:Connect(function(player)
		InventoryService.Load(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		InventoryService.Save(player)
		cache[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			InventoryService.Load(player)
		end)
	end

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			InventoryService.Save(player)
		end
	end)

	print("[InventoryService] Started")
end

return InventoryService