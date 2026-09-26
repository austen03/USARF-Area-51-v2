local TweenService = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")

local DoorAccessService = {}

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local AccessService = require(Services:WaitForChild("AccessService"))
local NotificationService = require(Services:WaitForChild("NotificationService"))
local FacilityLockdownService = require(Services:WaitForChild("FacilityLockdownService"))

local doors = {}

local AUTO_CLOSE_DEFAULT = 4

local function safePlay(sound)
	if sound and sound:IsA("Sound") then
		sound:Play()
	end
end

local function findSound(model, soundName)
	local found = model:FindFirstChild(soundName, true)

	if found and found:IsA("Sound") then
		return found
	end

	return nil
end

local function playDoorSound(door, soundName)
	safePlay(findSound(door, soundName))
end

local function tween(instance, info, goal)
	local t = TweenService:Create(instance, info, goal)
	t:Play()
	return t
end

local function getBasePartCFrameMap(model)
	local map = {}

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			map[descendant] = descendant.CFrame
		end
	end

	return map
end

local function requireSettings(door)
	local settingsModule = door:FindFirstChild("DoorSettings")

	if not settingsModule or not settingsModule:IsA("ModuleScript") then
		return nil
	end

	local success, settings = pcall(require, settingsModule)

	if not success or typeof(settings) ~= "table" then
		warn("[DoorAccessService] Invalid DoorSettings:", door:GetFullName())
		return nil
	end

	return settings
end

local function getPlayerTeamName(player)
	if not player or not player.Team then
		return nil
	end

	return player.Team.Name
end

local function setClientState(player, state)
	DoorAccessService.SendClientState(player, state)
end

function DoorAccessService.SendClientState(player, state)
	if DoorAccessService.RemoteEvent then
		DoorAccessService.RemoteEvent:FireClient(player, state)
	end
end

function DoorAccessService.RegisterDoor(door)
	if doors[door] then
		return true
	end

	local settings = requireSettings(door)

	if not settings then
		return false
	end

	local data = {
		Model = door,
		Settings = settings,
		Open = settings.open == true or settings.Open == true,
		Locked = settings.locked == true or settings.Locked == true,
		Busy = false,
		ClosedCFrames = getBasePartCFrameMap(door),
	}

	doors[door] = data

	door:SetAttribute("Open", data.Open)
	door:SetAttribute("Locked", data.Locked)
	door:SetAttribute("DoorType", settings.doorType or settings.DoorType or 0)

	return true
end

function DoorAccessService.GetDoorData(door)
	if not doors[door] then
		DoorAccessService.RegisterDoor(door)
	end

	return doors[door]
end

function DoorAccessService.SetLocked(door, locked)
	local data = DoorAccessService.GetDoorData(door)

	if not data then
		return false
	end

	data.Locked = locked == true

	data.Settings.locked = data.Locked
	data.Settings.Locked = data.Locked

	door:SetAttribute("Locked", data.Locked)

	if data.Locked then
		playDoorSound(door, "Lock")
	else
		playDoorSound(door, "Grant")
	end

	return true
end

local function canBypassLockdown(player)
	local teamName = getPlayerTeamName(player)

	if FacilityLockdownService.IsTeamLockdownBypass(teamName) then
		return true
	end

	return false
end

local function checkLockdown(player, door, data)
	local behavior = FacilityLockdownService.GetDoorBehavior(data.Settings)

	if behavior == "Normal" then
		return true, "Normal"
	end

	if behavior == "Ignore" then
		return true, "Ignored"
	end

	if behavior == "Unlocked" or behavior == "Open" then
		return true, "Unlocked by lockdown"
	end

	if behavior == "Locked" then
		if canBypassLockdown(player) then
			return true, "Lockdown bypass"
		end

		return false, "Facility lockdown active."
	end

	return true, "Unknown lockdown behavior"
end

function DoorAccessService.ToggleLock(player, door)
	local data = DoorAccessService.GetDoorData(door)

	if not data then
		return false
	end

	local allowed, reason = AccessService.CanLockDoor(player, data.Settings)

	if not allowed then
		playDoorSound(door, "Lock")

		NotificationService.Notify(player, {
			Title = "Lock Denied",
			Message = reason,
			Type = "Error",
			Duration = 3,
		})

		setClientState(player, "denied")

		task.delay(1, function()
			setClientState(player, "idle")
		end)

		return false
	end

	DoorAccessService.SetLocked(door, not data.Locked)

	NotificationService.Notify(player, {
		Title = data.Locked and "Door Locked" or "Door Unlocked",
		Message = data.Locked and "Door has been locked." or "Door has been unlocked.",
		Type = "Info",
		Duration = 3,
	})

	setClientState(player, "granted")

	task.delay(1, function()
		setClientState(player, "idle")
	end)

	return true
end

local function animateSwingDoor(data, open)
	local door = data.Model
	local doorRotation = door:FindFirstChild("DoorRotation")

	if not doorRotation or not doorRotation:IsA("NumberValue") then
		return
	end

	local openValue = data.Settings.openValue or data.Settings.OpenValue or -2
	local closedValue = data.Settings.closedValue or data.Settings.ClosedValue or 0

	if open then
		playDoorSound(door, "Grant")
		playDoorSound(door, "Open")
	else
		playDoorSound(door, "Close")
	end

	tween(
		doorRotation,
		TweenInfo.new(
			data.Settings.openTime or data.Settings.OpenTime or 1,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.InOut
		),
		{
			Value = open and openValue or closedValue,
		}
	)
end

local function animateRegularExtra(data, open)
	local door = data.Model
	local moving = door:FindFirstChild("Moving")

	if not moving then
		return
	end

	local bar = moving:FindFirstChild("Bar")
	local bolts = moving:FindFirstChild("Bolts")

	if bar and bar:IsA("BasePart") then
		local closed = data.ClosedCFrames[bar] or bar.CFrame

		tween(
			bar,
			TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
			{
				CFrame = open and closed * CFrame.new(0, 0, -0.1) or closed,
			}
		)
	end

	if bolts and bolts:IsA("BasePart") then
		local closed = data.ClosedCFrames[bolts] or bolts.CFrame

		tween(
			bolts,
			TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
			{
				CFrame = open and closed * CFrame.new(0, 0, 0.4) or closed,
			}
		)
	end
end

local function animateSlideDoor(data, open)
	local door = data.Model
	local part = door:FindFirstChild("Door")

	if not part or not part:IsA("BasePart") then
		warn("[DoorAccessService] Slide door missing BasePart Door:", door:GetFullName())
		return
	end

	local closed = data.ClosedCFrames[part] or part.CFrame
	local offset = data.Settings.slideOffset or data.Settings.SlideOffset or Vector3.new(0, 6.25, 0)

	if typeof(offset) ~= "Vector3" then
		offset = Vector3.new(0, 6.25, 0)
	end

	if open then
		playDoorSound(door, "Grant")
		playDoorSound(door, "Move")
		playDoorSound(door, "Open")
	else
		playDoorSound(door, "Move")
		playDoorSound(door, "Close")
	end

	tween(
		part,
		TweenInfo.new(
			data.Settings.openTime or data.Settings.OpenTime or 2,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.InOut
		),
		{
			CFrame = open and closed * CFrame.new(offset) or closed,
		}
	)
end

local function animateGateSlide(data, open)
	local door = data.Model
	local part = door:FindFirstChild("Door1")

	if not part or not part:IsA("BasePart") then
		warn("[DoorAccessService] GateSlide missing BasePart Door1:", door:GetFullName())
		return
	end

	local closed = data.ClosedCFrames[part] or part.CFrame
	local offset = data.Settings.slideOffset or data.Settings.SlideOffset or Vector3.new(0, 10.5, 0)

	if typeof(offset) ~= "Vector3" then
		offset = Vector3.new(0, 10.5, 0)
	end

	if open then
		playDoorSound(door, "Grant")
		playDoorSound(door, "Open")
	else
		playDoorSound(door, "Close")
	end

	tween(
		part,
		TweenInfo.new(
			data.Settings.openTime or data.Settings.OpenTime or 4.3,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.InOut
		),
		{
			CFrame = open and closed * CFrame.new(offset) or closed,
		}
	)
end

local function animateDoor(data, open)
	local doorType = data.Settings.doorType or data.Settings.DoorType

	if doorType == 1 or doorType == 2 or doorType == "Swing" or doorType == "HeavySwing" then
		animateRegularExtra(data, open)

		task.delay(0.1, function()
			animateSwingDoor(data, open)
		end)

		return
	end

	if doorType == 3 or doorType == "Slide" then
		animateSlideDoor(data, open)
		return
	end

	if doorType == 4 or doorType == "GateSlide" then
		animateGateSlide(data, open)
		return
	end

	warn("[DoorAccessService] Unsupported doorType:", tostring(doorType), data.Model:GetFullName())
end

function DoorAccessService.SetOpen(door, open)
	local data = DoorAccessService.GetDoorData(door)

	if not data or data.Busy then
		return false
	end

	data.Busy = true
	data.Open = open == true

	data.Settings.open = data.Open
	data.Settings.Open = data.Open

	door:SetAttribute("Open", data.Open)

	animateDoor(data, data.Open)

	task.delay(data.Settings.openTime or data.Settings.OpenTime or 1.5, function()
		if doors[door] then
			doors[door].Busy = false
		end
	end)

	return true
end

function DoorAccessService.ToggleOpen(player, door)
	local data = DoorAccessService.GetDoorData(door)

	if not data then
		setClientState(player, "denied")
		return false
	end

	if data.Busy then
		return false
	end

	local lockdownAllowed, lockdownReason = checkLockdown(player, door, data)

	if not lockdownAllowed then
		playDoorSound(door, "Lock")

		NotificationService.Notify(player, {
			Title = "Door Locked",
			Message = lockdownReason,
			Type = "Error",
			Duration = 3,
		})

		setClientState(player, "denied")

		task.delay(1, function()
			setClientState(player, "idle")
		end)

		return false
	end

	if data.Locked then
		playDoorSound(door, "Lock")

		NotificationService.Notify(player, {
			Title = "Door Locked",
			Message = "This door is locked.",
			Type = "Error",
			Duration = 3,
		})

		setClientState(player, "denied")

		task.delay(1, function()
			setClientState(player, "idle")
		end)

		return false
	end

	local allowed, reason = AccessService.CanOpenDoor(player, data.Settings)

	if not allowed then
		playDoorSound(door, "Lock")

		NotificationService.Notify(player, {
			Title = "Access Denied",
			Message = reason,
			Type = "Error",
			Duration = 3,
		})

		setClientState(player, "denied")

		task.delay(1, function()
			setClientState(player, "idle")
		end)

		return false
	end

	setClientState(player, "granted")

	DoorAccessService.SetOpen(door, not data.Open)

	task.delay(1, function()
		setClientState(player, "idle")
	end)

	local autoClose =
		data.Settings.autoClose
		or data.Settings.AutoClose

	if autoClose ~= false then
		task.delay(data.Settings.autoCloseTime or data.Settings.AutoCloseTime or AUTO_CLOSE_DEFAULT, function()
			local latest = doors[door]

			if latest and latest.Open and not latest.Busy then
				DoorAccessService.SetOpen(door, false)
			elseif latest and latest.Open then
				task.delay(1.5, function()
					local again = doors[door]

					if again and again.Open then
						DoorAccessService.SetOpen(door, false)
					end
				end)
			end
		end)
	end

	return true
end

function DoorAccessService.ApplyLockdownToDoor(door)
	local data = DoorAccessService.GetDoorData(door)

	if not data then
		return
	end

	local behavior = FacilityLockdownService.GetDoorBehavior(data.Settings)

	if behavior == "Open" or behavior == "Unlocked" then
		if data.Locked then
			DoorAccessService.SetLocked(door, false)
		end

		if not data.Open then
			DoorAccessService.SetOpen(door, true)
		end
	elseif behavior == "Locked" then
		if data.Open then
			DoorAccessService.SetOpen(door, false)
		end
	end
end

function DoorAccessService.ApplyLockdownToAllDoors()
	for door in pairs(doors) do
		DoorAccessService.ApplyLockdownToDoor(door)
	end
end

function DoorAccessService.Scan(container)
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("ModuleScript") and descendant.Name == "DoorSettings" then
			DoorAccessService.RegisterDoor(descendant.Parent)
		end
	end
end

function DoorAccessService.Start(remoteEvent)
	DoorAccessService.RemoteEvent = remoteEvent

	DoorAccessService.Scan(workspace)

	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ModuleScript") and descendant.Name == "DoorSettings" then
			task.wait()
			DoorAccessService.RegisterDoor(descendant.Parent)
		end
	end)

	FacilityLockdownService.OnChanged(function()
		DoorAccessService.ApplyLockdownToAllDoors()
	end)

	print("[DoorAccessService] Started")
end

return DoorAccessService