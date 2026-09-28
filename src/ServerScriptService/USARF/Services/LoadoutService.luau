local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LoadoutService = {}

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local ConfigFolder = USARF:WaitForChild("Config")

local EconomyConfig = require(ConfigFolder:WaitForChild("EconomyConfig"))
local CovertConfig = require(ConfigFolder:WaitForChild("CovertConfig"))

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local InventoryService = require(Services:WaitForChild("InventoryService"))
local GamepassService = require(Services:WaitForChild("GamepassService"))
local CovertState = require(Services:WaitForChild("CovertState"))

local ToolsFolder = ServerStorage:WaitForChild("Tools")

local started = false

local DEFAULT_WALKSPEED = 16
local SPEED_BOOST_WALKSPEED = 24

local VALID_LOADOUT_SLOTS = {
	Primary = true,
	Secondary = true,
	Equipment = true,
}

local DEFAULT_LOADOUT_CONFIG = {
	Teams = {},
	Gamepasses = {},
}

local LoadoutConfig = DEFAULT_LOADOUT_CONFIG

pcall(function()
	LoadoutConfig = require(ConfigFolder:WaitForChild("LoadoutConfig"))
end)

local function getOrCreateRemoteFunction(name)
	local remote = Remotes:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = Remotes
	end

	return remote
end

local GetBlackMarketInventoryRemote = getOrCreateRemoteFunction("GetBlackMarketInventory")
local EquipLoadoutItemRemote = getOrCreateRemoteFunction("EquipLoadoutItem")
local UnequipLoadoutItemRemote = getOrCreateRemoteFunction("UnequipLoadoutItem")
local ClearServerLifeLoadoutRemote = getOrCreateRemoteFunction("ClearServerLifeLoadout")
local ApplyLoadoutNowRemote = getOrCreateRemoteFunction("ApplyLoadoutNow")

local function getItem(itemId)
	for _, item in ipairs(EconomyConfig.ShopItems or {}) do
		if item.Id == itemId then
			return item
		end
	end

	return nil
end

local function normalizeSlot(slot)
	slot = tostring(slot or "")

	if slot == "PrimaryWeapon" then
		return "Primary"
	end

	if slot == "SecondaryWeapon" then
		return "Secondary"
	end

	return slot
end

local function isPermanentItem(item)
	return item and (item.ItemType == "Permanent" or item.ItemType == "Unlock")
end

local function isLifeItem(item)
	return item and item.ItemType == "LifeItem"
end

local function isValidLoadoutItem(item)
	if typeof(item) ~= "table" then
		return false
	end

	local slot = normalizeSlot(item.LoadoutSlot)

	if not VALID_LOADOUT_SLOTS[slot] then
		return false
	end

	if not item.ToolName or item.ToolName == "" then
		return false
	end

	return true
end

local function getTool(toolName)
	if not toolName or toolName == "" then
		return nil
	end

	local direct = ToolsFolder:FindFirstChild(toolName)

	if direct and direct:IsA("Tool") then
		return direct
	end

	local deep = ToolsFolder:FindFirstChild(toolName, true)

	if deep and deep:IsA("Tool") then
		return deep
	end

	return nil
end

local function getBackpack(player)
	if not player then
		return nil
	end

	return player:FindFirstChildOfClass("Backpack") or player:FindFirstChild("Backpack")
end

local function hasTool(player, toolName)
	if not player or not toolName then
		return false
	end

	local backpack = getBackpack(player)

	if backpack and backpack:FindFirstChild(toolName) then
		return true
	end

	local character = player.Character

	if character and character:FindFirstChild(toolName) then
		return true
	end

	return false
end

local function giveTool(player, toolName)
	if not player then
		return false
	end

	local template = getTool(toolName)

	if not template then
		warn("[LoadoutService] Missing tool:", tostring(toolName))
		return false
	end

	if hasTool(player, template.Name) then
		return true
	end

	local backpack = getBackpack(player)

	if not backpack then
		warn("[LoadoutService] Missing Backpack for:", player.Name)
		return false
	end

	local clone = template:Clone()
	clone.Parent = backpack

	return true
end

local function removeBlackMarketTools(player)
	if not player then
		return
	end

	local shopToolNames = {}

	for _, item in ipairs(EconomyConfig.ShopItems or {}) do
		if item.ToolName and item.ToolName ~= "" then
			shopToolNames[item.ToolName] = true
		end
	end

	for _, container in ipairs({
		getBackpack(player),
		player.Character,
		}) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and shopToolNames[child.Name] then
					child:Destroy()
				end
			end
		end
	end
end

local function giveDefaultTeamTools(player)
	if not player or not player.Team then
		return
	end

	local teamConfig = LoadoutConfig.Teams and LoadoutConfig.Teams[player.Team.Name]

	if teamConfig then
		for _, toolName in ipairs(teamConfig.Default or {}) do
			giveTool(player, toolName)
		end
	end

	if CovertState.IsCovert(player) then
		for _, toolName in ipairs(CovertConfig.Tools or {}) do
			giveTool(player, toolName)
		end
	end

	for gamepassName, toolName in pairs(LoadoutConfig.Gamepasses or {}) do
		if GamepassService.Has(player, gamepassName) then
			giveTool(player, toolName)
		end
	end
end

local function normalizeEquipment(equipment)
	local result = {}

	if typeof(equipment) ~= "table" then
		return result
	end

	for key, value in pairs(equipment) do
		if typeof(key) == "number" and typeof(value) == "string" then
			result[value] = true
		elseif typeof(key) == "string" and value == true then
			result[key] = true
		end
	end

	return result
end

local function normalizeLoadout(loadout)
	loadout = typeof(loadout) == "table" and loadout or {}

	return {
		Primary = loadout.Primary,
		Secondary = loadout.Secondary,
		Equipment = normalizeEquipment(loadout.Equipment),
	}
end

local function getLoadoutForPlayer(player)
	local inventory = InventoryService.GetInventory(player)

	inventory.OwnedItems = inventory.OwnedItems or {}
	inventory.Consumables = inventory.Consumables or {}
	inventory.Loadout = normalizeLoadout(inventory.Loadout)
	inventory.ServerLifeLoadout = normalizeLoadout(inventory.ServerLifeLoadout)

	return inventory
end

local function clearLifeEffects(player)
	player:SetAttribute("USARF_TemporaryRadioAccess", false)
	player:SetAttribute("USARF_TemporaryClearance", nil)
end

local function applySpeedBoost(player)
	local character = player.Character

	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	if InventoryService.IsBoostActive(player, "SpeedBoost") then
		humanoid.WalkSpeed = SPEED_BOOST_WALKSPEED
	else
		humanoid.WalkSpeed = DEFAULT_WALKSPEED
	end
end

local function consumeServerLifeItem(player, itemId)
	if InventoryService.HasItem(player, itemId) then
		return true
	end

	local count = InventoryService.GetConsumableCount(player, itemId)

	if count <= 0 then
		return false
	end

	return InventoryService.UseConsumable(player, itemId, 1) == true
end

local function applyLoadoutTable(player, loadout, consumeConsumables)
	loadout = normalizeLoadout(loadout)

	local applied = {}
	local failed = {}
	local inventory = getLoadoutForPlayer(player)

	local function applyItem(itemId)
		if not itemId then
			return
		end

		local item = getItem(itemId)

		if not item or not isValidLoadoutItem(item) then
			table.insert(failed, tostring(itemId))
			return
		end

		if consumeConsumables == true then
			if not consumeServerLifeItem(player, itemId) then
				table.insert(failed, tostring(itemId))
				return
			end
		elseif inventory.OwnedItems[itemId] ~= true then
			table.insert(failed, tostring(itemId))
			return
		end

		if giveTool(player, item.ToolName) then
			table.insert(applied, tostring(itemId))
		else
			table.insert(failed, tostring(itemId))
		end
	end

	applyItem(loadout.Primary)
	applyItem(loadout.Secondary)

	for itemId, enabled in pairs(loadout.Equipment) do
		if enabled == true then
			applyItem(itemId)
		end
	end

	return applied, failed
end

local function applyBaseLoadout(player)
	clearLifeEffects(player)
	removeBlackMarketTools(player)
	giveDefaultTeamTools(player)
end

local function equipLifeItemNow(player, item)
	if not item or not isLifeItem(item) or not isValidLoadoutItem(item) then
		return false, "This item cannot be equipped now."
	end

	if hasTool(player, item.ToolName) then
		return false, item.Name .. " is already equipped."
	end

	local count = InventoryService.GetConsumableCount(player, item.Id)

	if count <= 0 then
		return false, "You do not have any uses left."
	end

	local template = getTool(item.ToolName)

	if not template then
		return false, "The tool for this item is unavailable."
	end

	if not InventoryService.UseConsumable(player, item.Id, 1) then
		return false, "Could not consume this item."
	end

	if not giveTool(player, item.ToolName) then
		InventoryService.AddConsumable(player, item.Id, 1)
		return false, "Could not equip the tool. Your use was returned."
	end

	InventoryService.Save(player)

	return true, item.Name .. " equipped for your current life."
end

function LoadoutService.ApplySavedLoadout(player)
	if not player then
		return false, "Missing player."
	end

	applyBaseLoadout(player)

	local inventory = getLoadoutForPlayer(player)
	local applied, failed = applyLoadoutTable(player, inventory.Loadout, false)

	applySpeedBoost(player)

	print(
		"[LoadoutService] Applied saved loadout for",
		player.Name,
		"Applied:",
		#applied,
		"Failed:",
		#failed
	)

	if #failed > 0 then
		local message = "Saved loadout applied, but some tools were unavailable: " .. table.concat(failed, ", ")
		return false, message
	end

	if #applied == 0 then
		return true, "Saved loadout applied. No permanent Black Market tools were equipped."
	end

	local message = "Saved loadout applied. Equipped " .. tostring(#applied) .. " item(s)."
	return true, message
end

function LoadoutService.ApplySpawnLoadout(player)
	if not player then
		return false, "Missing player."
	end

	applyBaseLoadout(player)

	local inventory = getLoadoutForPlayer(player)
	local savedApplied, savedFailed = applyLoadoutTable(player, inventory.Loadout, false)
	local lifeApplied, lifeFailed = applyLoadoutTable(player, inventory.ServerLifeLoadout, true)

	InventoryService.ClearServerLifeLoadout(player)
	InventoryService.Save(player)

	applySpeedBoost(player)

	print(
		"[LoadoutService] Applied spawn loadout for",
		player.Name,
		"Saved:",
		#savedApplied,
		"Next life:",
		#lifeApplied,
		"Failed:",
		#savedFailed + #lifeFailed
	)

	return true, "Spawn loadout applied."
end

function LoadoutService.Apply(player)
	return LoadoutService.ApplySpawnLoadout(player)
end

function LoadoutService.GetBlackMarketPayload(player)
	local inventory = getLoadoutForPlayer(player)

	local ownedItems = {}
	local consumables = {}

	for _, item in ipairs(EconomyConfig.ShopItems or {}) do
		if isValidLoadoutItem(item) then
			local owned = inventory.OwnedItems[item.Id] == true
			local count = InventoryService.GetConsumableCount(player, item.Id)

			if owned or count > 0 then
				local entry = {
					Id = item.Id,
					Name = item.Name,
					Description = item.Description,
					ItemType = item.ItemType,
					ToolName = item.ToolName,
					LoadoutSlot = normalizeSlot(item.LoadoutSlot),
					Owned = owned,
					Count = count,
					IsLifeItem = isLifeItem(item),
					CanEquipNow = owned or count > 0,
				}

				if owned then
					table.insert(ownedItems, entry)
				else
					table.insert(consumables, entry)
				end
			end
		end
	end

	return {
		Success = true,
		Inventory = inventory,
		OwnedItems = ownedItems,
		Consumables = consumables,
		Loadout = inventory.Loadout,
		ServerLifeLoadout = inventory.ServerLifeLoadout,
	}
end

function LoadoutService.EquipItem(player, itemId, slot, serverLifeOnly)
	local item = getItem(itemId)

	if not item or not isValidLoadoutItem(item) then
		return {
			Success = false,
			Message = "This item is not a valid Black Market loadout item.",
		}
	end

	local configuredSlot = normalizeSlot(item.LoadoutSlot)
	slot = VALID_LOADOUT_SLOTS[configuredSlot] and configuredSlot or normalizeSlot(slot)

	if not VALID_LOADOUT_SLOTS[slot] then
		return {
			Success = false,
			Message = "This item has an invalid loadout slot.",
		}
	end

	local inventory = getLoadoutForPlayer(player)
	local owned = inventory.OwnedItems[itemId] == true
	local count = InventoryService.GetConsumableCount(player, itemId)

	if serverLifeOnly == true then
		if not owned and count <= 0 then
			return {
				Success = false,
				Message = "You do not have any uses left.",
			}
		end

		local success, reason = InventoryService.SetLoadoutItem(player, slot, itemId, true)

		if not success then
			return {
				Success = false,
				Message = reason or "Could not equip item for next life.",
			}
		end

		InventoryService.Save(player)

		return {
			Success = true,
			Message = item.Name .. " equipped for your next life.",
			Payload = LoadoutService.GetBlackMarketPayload(player),
		}
	end

	if isLifeItem(item) and not owned then
		local success, message = equipLifeItemNow(player, item)

		return {
			Success = success,
			Message = message,
			Payload = LoadoutService.GetBlackMarketPayload(player),
		}
	end

	if not owned or not isPermanentItem(item) then
		return {
			Success = false,
			Message = "You do not permanently own this item.",
		}
	end

	local success, reason = InventoryService.SetLoadoutItem(player, slot, itemId, false)

	if not success then
		return {
			Success = false,
			Message = reason or "Could not add item to saved loadout.",
		}
	end

	InventoryService.Save(player)

	return {
		Success = true,
		Message = item.Name .. " added to your permanent saved loadout.",
		Payload = LoadoutService.GetBlackMarketPayload(player),
	}
end

function LoadoutService.UnequipItem(player, itemId, slot, serverLifeOnly)
	local item = getItem(itemId)

	if not item or not isValidLoadoutItem(item) then
		return {
			Success = false,
			Message = "This item is not a valid loadout item.",
		}
	end

	local configuredSlot = normalizeSlot(item.LoadoutSlot)
	slot = VALID_LOADOUT_SLOTS[configuredSlot] and configuredSlot or normalizeSlot(slot)

	if not VALID_LOADOUT_SLOTS[slot] then
		return {
			Success = false,
			Message = "This item has an invalid loadout slot.",
		}
	end

	if serverLifeOnly ~= true and not isPermanentItem(item) then
		return {
			Success = false,
			Message = "One-life items are consumed when equipped and cannot be unequipped back into inventory.",
		}
	end

	local success, reason = InventoryService.RemoveLoadoutItem(
		player,
		slot,
		itemId,
		serverLifeOnly == true
	)

	if not success then
		return {
			Success = false,
			Message = reason or "Could not unequip item.",
		}
	end

	InventoryService.Save(player)

	return {
		Success = true,
		Message = serverLifeOnly and "Removed from your next-life loadout." or "Removed from your permanent saved loadout.",
		Payload = LoadoutService.GetBlackMarketPayload(player),
	}
end

GetBlackMarketInventoryRemote.OnServerInvoke = function(player)
	return LoadoutService.GetBlackMarketPayload(player)
end

EquipLoadoutItemRemote.OnServerInvoke = function(player, itemId, slot, serverLifeOnly)
	return LoadoutService.EquipItem(player, itemId, slot, serverLifeOnly == true)
end

UnequipLoadoutItemRemote.OnServerInvoke = function(player, itemId, slot, serverLifeOnly)
	return LoadoutService.UnequipItem(player, itemId, slot, serverLifeOnly == true)
end

ClearServerLifeLoadoutRemote.OnServerInvoke = function(player)
	InventoryService.ClearServerLifeLoadout(player)
	InventoryService.Save(player)

	return {
		Success = true,
		Message = "Next-life loadout cleared.",
		Payload = LoadoutService.GetBlackMarketPayload(player),
	}
end

ApplyLoadoutNowRemote.OnServerInvoke = function(player)
	local success, message = LoadoutService.ApplySavedLoadout(player)

	return {
		Success = success,
		Message = message,
		Payload = LoadoutService.GetBlackMarketPayload(player),
	}
end

local function setupPlayer(player)
	player:SetAttribute("USARF_TemporaryRadioAccess", false)
	player:SetAttribute("USARF_TemporaryClearance", nil)

	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		task.wait(1)

		if player.Parent and player.Character == character then
			LoadoutService.ApplySpawnLoadout(player)
		end
	end)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		task.wait(0.75)

		if player.Parent and player.Character then
			LoadoutService.ApplySavedLoadout(player)
		end
	end)

	task.spawn(function()
		while player.Parent do
			task.wait(5)
			applySpeedBoost(player)
		end
	end)

	if player.Character then
		local character = player.Character

		task.defer(function()
			character:WaitForChild("Humanoid", 10)
			task.wait(1)

			if player.Parent and player.Character == character then
				LoadoutService.ApplySpawnLoadout(player)
			end
		end)
	end
end

function LoadoutService.Start()
	if started then
		return
	end

	started = true

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	print("[LoadoutService] Started")
end

return LoadoutService