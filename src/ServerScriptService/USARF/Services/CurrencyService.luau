local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CurrencyService = {}

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")
local Remotes = USARF:WaitForChild("Remotes")

local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))

local USARFConfig = nil
pcall(function()
	USARFConfig = require(Config:WaitForChild("USARFConfig"))
end)

local AFKActivityRemote = Remotes:WaitForChild("AFKActivity")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local TransactionLogService = require(Services:WaitForChild("TransactionLogService"))
local NotificationService = require(Services:WaitForChild("NotificationService"))
local GamepassService = require(Services:WaitForChild("GamepassService"))

local dataStore = DataStoreService:GetDataStore("USARF_Currency_v1")

local cache = {}
local saving = {}
local paycheckLoops = {}
local afkLoops = {}
local activityState = {}
local started = false

local DEBUG_PAYCHECKS = false

local function debugPaycheck(...)
	if DEBUG_PAYCHECKS then
		print("[CurrencyService][Paycheck]", ...)
	end
end

local function defaultData()
	return {
		Cash = 0,
		Gold = 0,
		LastUpdated = os.time(),
	}
end

local function sanitize(data)
	if typeof(data) ~= "table" then
		data = defaultData()
	end

	data.Cash = math.max(0, math.floor(tonumber(data.Cash) or 0))
	data.Gold = math.max(0, math.floor(tonumber(data.Gold) or 0))
	data.LastUpdated = tonumber(data.LastUpdated) or os.time()

	return data
end

local function getKey(userId)
	return "Player_" .. tostring(userId)
end

local function formatNumber(value)
	value = tonumber(value) or 0
	return tostring(value):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function validCurrency(currencyType)
	return currencyType == "Cash" or currencyType == "Gold"
end

local function replicate(player)
	local data = cache[player.UserId]

	if not data then
		return
	end

	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("Gold", data.Gold)
end

local function getRootPosition(player)
	local character = player.Character

	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")

	if not root then
		return nil
	end

	return root.Position
end

local function getHumanoid(player)
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function setAFK(player, value)
	if not player or not player.Parent then
		return
	end

	if player:GetAttribute("USARF_AFK") ~= value then
		player:SetAttribute("USARF_AFK", value)
	end
end

local function setSuspiciousIdle(player, value)
	if not player or not player.Parent then
		return
	end

	if player:GetAttribute("USARF_SuspiciousIdle") ~= value then
		player:SetAttribute("USARF_SuspiciousIdle", value)
	end
end

local function getActivityState(player)
	local state = activityState[player.UserId]

	if not state then
		state = {
			LastActive = os.time(),
			LastClientActivity = os.time(),
			LastPosition = getRootPosition(player),
			LastCameraMovedAt = os.time(),
			TinyMoves = {},
			ClientPackets = 0,
		}

		activityState[player.UserId] = state
	end

	return state
end

local function clearOldTinyMoves(state, windowSeconds)
	local now = os.time()
	local kept = {}

	for _, entry in ipairs(state.TinyMoves or {}) do
		if now - entry.When <= windowSeconds then
			table.insert(kept, entry)
		end
	end

	state.TinyMoves = kept
end

local function markActive(player, reason, cameraMoved)
	local state = getActivityState(player)

	state.LastActive = os.time()
	state.LastClientActivity = os.time()
	state.LastActiveReason = reason or "Unknown"

	if cameraMoved == true then
		state.LastCameraMovedAt = os.time()
	end

	setAFK(player, false)
	setSuspiciousIdle(player, false)
end

local function isPaycheckBlocked(player)
	local afkConfig = EconomyConfig.AFK or {}

	if afkConfig.SkipPaycheckInMenu == true and player:GetAttribute("USARF_InMenu") ~= false then
		return true, "No paycheck while in menu"
	end

	if afkConfig.SkipPaycheck == true and player:GetAttribute("USARF_AFK") == true then
		return true, "No paycheck while AFK"
	end

	if afkConfig.SkipPaycheckIfSuspicious == true and player:GetAttribute("USARF_SuspiciousIdle") == true then
		return true, "No paycheck while suspicious idle"
	end

	return false, nil
end

local function analyzeSuspiciousIdle(player, state, movedDistance)
	local afkConfig = EconomyConfig.AFK or {}

	if afkConfig.SuspiciousMacroDetection ~= true then
		return
	end

	local windowSeconds = tonumber(afkConfig.RepeatedTinyMoveWindow) or 90
	local tinyMin = tonumber(afkConfig.TinyMoveMin) or 0.05
	local tinyMax = tonumber(afkConfig.TinyMoveMax) or 0.65
	local threshold = tonumber(afkConfig.TinyMoveCountThreshold) or 45
	local cameraStillRequired = afkConfig.CameraStillRequired == true

	clearOldTinyMoves(state, windowSeconds)

	if movedDistance and movedDistance >= tinyMin and movedDistance <= tinyMax then
		table.insert(state.TinyMoves, {
			When = os.time(),
			Distance = movedDistance,
		})
	end

	local cameraStill = true

	if cameraStillRequired then
		local lastCameraMovedAt = state.LastCameraMovedAt or 0
		cameraStill = os.time() - lastCameraMovedAt >= windowSeconds
	end

	local suspicious = #state.TinyMoves >= threshold and cameraStill

	if suspicious then
		setSuspiciousIdle(player, true)

		if afkConfig.MarkSuspiciousAsAFK == true then
			setAFK(player, true)
		end
	else
		setSuspiciousIdle(player, false)
	end
end

local function startAFKMonitor(player)
	if afkLoops[player.UserId] then
		return
	end

	afkLoops[player.UserId] = true

	local afkConfig = EconomyConfig.AFK or {}
	local enabled = afkConfig.Enabled ~= false
	local idleSeconds = tonumber(afkConfig.IdleSeconds) or 180
	local checkInterval = tonumber(afkConfig.CheckInterval) or 1
	local moveThreshold = tonumber(afkConfig.MoveThreshold) or 0.75

	local state = getActivityState(player)
	state.LastActive = os.time()
	state.LastClientActivity = os.time()
	state.LastPosition = getRootPosition(player)
	state.LastCameraMovedAt = os.time()
	state.TinyMoves = {}
	state.ClientPackets = 0

	player:SetAttribute("USARF_AFK", false)
	player:SetAttribute("USARF_SuspiciousIdle", false)

	task.spawn(function()
		while player.Parent and afkLoops[player.UserId] do
			if enabled then
				local currentState = getActivityState(player)
				local currentPosition = getRootPosition(player)
				local movedDistance = nil

				if currentPosition and currentState.LastPosition then
					movedDistance = (currentPosition - currentState.LastPosition).Magnitude

					if movedDistance >= moveThreshold then
						currentState.LastActive = os.time()
						currentState.LastActiveReason = "ServerMovement"
						setAFK(player, false)
						setSuspiciousIdle(player, false)
					end
				end

				if currentPosition then
					currentState.LastPosition = currentPosition
				end

				local humanoid = getHumanoid(player)
				if humanoid and humanoid.MoveDirection.Magnitude > 0.05 then
					currentState.LastActive = os.time()
					currentState.LastActiveReason = "HumanoidMoveDirection"
					setAFK(player, false)
				end

				analyzeSuspiciousIdle(player, currentState, movedDistance)

				if os.time() - (currentState.LastActive or os.time()) >= idleSeconds then
					setAFK(player, true)
				end
			end

			task.wait(checkInterval)
		end
	end)
end

local function handleClientActivity(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	local afkConfig = EconomyConfig.AFK or {}
	local state = getActivityState(player)

	state.ClientPackets = (state.ClientPackets or 0) + 1
	state.LastClientActivity = os.time()
	state.LastClientType = tostring(payload.Type or "Unknown")

	local cameraMoved = payload.CameraMoved == true

	if cameraMoved then
		state.LastCameraMovedAt = os.time()
	end

	local shouldClearAFK = false

	if afkConfig.ClientInputClearsAFK == true then
		local activityType = tostring(payload.Type or "")

		if activityType == "InputBegan"
			or activityType == "InputChanged"
			or activityType == "MoveDirection"
			or activityType == "CameraMoved"
		then
			shouldClearAFK = true
		end
	end

	if afkConfig.CameraMovementClearsAFK == true and cameraMoved then
		shouldClearAFK = true
	end

	if shouldClearAFK then
		markActive(player, payload.Type or "ClientActivity", cameraMoved)
	end
end

local function getTeamKey(player)
	if not player or not player.Team then
		return nil
	end

	if USARFConfig and typeof(USARFConfig.GetTeamKeyFromName) == "function" then
		return USARFConfig.GetTeamKeyFromName(player.Team.Name)
	end

	return nil
end

local function getTeamPaycheck(teamName, teamKey)
	if USARFConfig and USARFConfig.Economy and USARFConfig.Economy.TeamPaychecks then
		if teamKey and USARFConfig.Economy.TeamPaychecks[teamKey] then
			return USARFConfig.Economy.TeamPaychecks[teamKey]
		end
	end

	if EconomyConfig.TeamPaychecks then
		if teamName and EconomyConfig.TeamPaychecks[teamName] then
			return EconomyConfig.TeamPaychecks[teamName]
		end

		if teamKey and EconomyConfig.TeamPaychecks[teamKey] then
			return EconomyConfig.TeamPaychecks[teamKey]
		end
	end

	return 0
end

function CurrencyService.GetData(player)
	return player and cache[player.UserId] or nil
end

function CurrencyService.GetBalance(player)
	local data = CurrencyService.GetData(player)

	return {
		Cash = data and data.Cash or 0,
		Gold = data and data.Gold or 0,
	}
end

function CurrencyService.Load(player)
	if not player then
		return false, "Missing player"
	end

	local success, result = pcall(function()
		return dataStore:GetAsync(getKey(player.UserId))
	end)

	if not success then
		warn("[CurrencyService] Failed to load " .. player.Name .. ": " .. tostring(result))
		cache[player.UserId] = defaultData()
		replicate(player)
		return false, result
	end

	cache[player.UserId] = sanitize(result)
	replicate(player)

	print("[CurrencyService] Loaded", player.Name, "Cash:", cache[player.UserId].Cash, "Gold:", cache[player.UserId].Gold)

	return true, cache[player.UserId]
end

function CurrencyService.Save(player)
	if not player then
		return false, "Missing player"
	end

	local userId = player.UserId
	local data = cache[userId]

	if not data or saving[userId] then
		return false
	end

	saving[userId] = true
	data.LastUpdated = os.time()

	local success, result = pcall(function()
		dataStore:SetAsync(getKey(userId), data)
	end)

	saving[userId] = nil

	if not success then
		warn("[CurrencyService] Failed to save " .. player.Name .. ": " .. tostring(result))
		return false, result
	end

	return true
end

function CurrencyService.Add(player, currencyType, amount, action, metadata)
	if not player then
		return false, "Missing player"
	end

	currencyType = tostring(currencyType or "")
	amount = math.floor(tonumber(amount) or 0)

	if not validCurrency(currencyType) then
		return false, "Currency must be Cash or Gold"
	end

	if amount <= 0 then
		return false, "Amount must be greater than 0"
	end

	local data = cache[player.UserId]

	if not data then
		CurrencyService.Load(player)
		data = cache[player.UserId]
	end

	if not data then
		return false, "Currency data failed to load"
	end

	local before = data[currencyType]
	data[currencyType] += amount
	data.LastUpdated = os.time()

	replicate(player)

	TransactionLogService.Log(player, action or EconomyConfig.TransactionActions.System, currencyType, amount, before, data[currencyType], metadata)

	return true, data[currencyType]
end

function CurrencyService.Remove(player, currencyType, amount, action, metadata)
	if not player then
		return false, "Missing player"
	end

	currencyType = tostring(currencyType or "")
	amount = math.floor(tonumber(amount) or 0)

	if not validCurrency(currencyType) then
		return false, "Currency must be Cash or Gold"
	end

	if amount <= 0 then
		return false, "Amount must be greater than 0"
	end

	local data = cache[player.UserId]

	if not data then
		CurrencyService.Load(player)
		data = cache[player.UserId]
	end

	if not data then
		return false, "Currency data failed to load"
	end

	local before = data[currencyType]
	data[currencyType] = math.max(0, data[currencyType] - amount)
	data.LastUpdated = os.time()

	replicate(player)

	TransactionLogService.Log(player, action or EconomyConfig.TransactionActions.System, currencyType, -amount, before, data[currencyType], metadata)

	return true, data[currencyType]
end

function CurrencyService.Set(player, currencyType, amount, action, metadata)
	if not player then
		return false, "Missing player"
	end

	currencyType = tostring(currencyType or "")
	amount = math.floor(tonumber(amount) or 0)

	if not validCurrency(currencyType) then
		return false, "Currency must be Cash or Gold"
	end

	if amount < 0 then
		return false, "Amount must be 0 or greater"
	end

	local data = cache[player.UserId]

	if not data then
		CurrencyService.Load(player)
		data = cache[player.UserId]
	end

	if not data then
		return false, "Currency data failed to load"
	end

	local before = data[currencyType]
	data[currencyType] = amount
	data.LastUpdated = os.time()

	replicate(player)

	TransactionLogService.Log(player, action or EconomyConfig.TransactionActions.System, currencyType, amount - before, before, data[currencyType], metadata)

	return true, data[currencyType]
end

function CurrencyService.CanAfford(player, currencyType, amount)
	local data = cache[player.UserId]

	if not data then
		return false
	end

	return validCurrency(currencyType) and data[currencyType] >= (tonumber(amount) or 0)
end

function CurrencyService.GetBasePaycheckAmount(player)
	if not player or not player.Team then
		return 0
	end

	local teamName = player.Team.Name
	local teamKey = getTeamKey(player)

	return getTeamPaycheck(teamName, teamKey)
end

function CurrencyService.GetPaycheckAmount(player)
	local baseAmount = CurrencyService.GetBasePaycheckAmount(player)

	if baseAmount <= 0 then
		return 0
	end

	local amount = baseAmount

	if GamepassService.Has(player, "DoublePaycheck") then
		amount *= 2
	end

	if ReplicatedStorage:GetAttribute("USARF_DoublePaycheck") == true then
		amount *= 2
	end

	return amount
end

function CurrencyService.GivePaycheck(player)
	if not player or not player.Parent then
		return false, "Missing player"
	end

	local teamName = player.Team and player.Team.Name or "Unknown"
	local teamKey = getTeamKey(player)

	debugPaycheck(
		player.Name,
		"Team:",
		teamName,
		"TeamKey:",
		tostring(teamKey),
		"InMenu:",
		tostring(player:GetAttribute("USARF_InMenu")),
		"AFK:",
		tostring(player:GetAttribute("USARF_AFK")),
		"Suspicious:",
		tostring(player:GetAttribute("USARF_SuspiciousIdle"))
	)

	local blocked, reason = isPaycheckBlocked(player)

	if blocked then
		debugPaycheck(player.Name, "blocked:", reason)
		return false, reason
	end

	local baseAmount = CurrencyService.GetBasePaycheckAmount(player)
	local amount = CurrencyService.GetPaycheckAmount(player)

	if amount <= 0 then
		debugPaycheck(player.Name, "blocked: no paycheck amount for", teamName, "teamKey:", tostring(teamKey))
		return false, "No paycheck for current team"
	end

	local hasDouble = amount > baseAmount

	local success, result = CurrencyService.Add(player, "Cash", amount, EconomyConfig.TransactionActions.Paycheck, {
		Team = teamName,
		TeamKey = teamKey,
		BaseAmount = baseAmount,
		DoublePaycheck = hasDouble,
		AFK = player:GetAttribute("USARF_AFK") == true,
		SuspiciousIdle = player:GetAttribute("USARF_SuspiciousIdle") == true,
	})

	if success then
		debugPaycheck(player.Name, "awarded:", amount)

		local message = "+$" .. formatNumber(amount) .. " Cash (" .. teamName .. ")"

		if hasDouble then
			message ..= " | 2x Paycheck"
		end

		local notifySuccess, notifyReason = NotificationService.Notify(player, {
			Title = "Paycheck Received",
			Message = message,
			Type = "Currency",
			Duration = 4,
			Priority = 1,
			Dedupe = false,
		})

		if notifySuccess == false then
			warn("[CurrencyService] Paycheck notification failed:", player.Name, tostring(notifyReason))
		end
	else
		debugPaycheck(player.Name, "award failed:", tostring(result))
	end

	return success, result
end

local function startPlayer(player)
	player:SetAttribute("Cash", nil)
	player:SetAttribute("Gold", nil)
	player:SetAttribute("USARF_AFK", false)
	player:SetAttribute("USARF_SuspiciousIdle", false)

	task.spawn(function()
		GamepassService.GetAll(player)
	end)

	CurrencyService.Load(player)
	startAFKMonitor(player)

	player.CharacterAdded:Connect(function()
		task.wait(1)
		markActive(player, "CharacterAdded", true)
	end)

	if paycheckLoops[player.UserId] then
		return
	end

	paycheckLoops[player.UserId] = true

	task.spawn(function()
		while player.Parent and paycheckLoops[player.UserId] do
			
			local paycheckInterval = EconomyConfig.PaycheckInterval

			if USARFConfig and USARFConfig.Economy and USARFConfig.Economy.PaycheckInterval then
				paycheckInterval = USARFConfig.Economy.PaycheckInterval
			end

			task.wait(paycheckInterval)

			if player.Parent then
				CurrencyService.GivePaycheck(player)
			end
		end
	end)
end

local function stopPlayer(player)
	paycheckLoops[player.UserId] = nil
	afkLoops[player.UserId] = nil
	activityState[player.UserId] = nil

	CurrencyService.Save(player)
	TransactionLogService.ClearSessionLogs(player.UserId)
	cache[player.UserId] = nil
end

function CurrencyService.Start()
	if started then
		return
	end

	started = true

	AFKActivityRemote.OnServerEvent:Connect(handleClientActivity)

	Players.PlayerAdded:Connect(startPlayer)
	Players.PlayerRemoving:Connect(stopPlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(startPlayer, player)
	end

	task.spawn(function()
		while started do
			task.wait(EconomyConfig.AutoSaveInterval)

			for _, player in ipairs(Players:GetPlayers()) do
				CurrencyService.Save(player)
			end
		end
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			CurrencyService.Save(player)
		end
	end)

	print("[CurrencyService] Started")
end

return CurrencyService