local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TAG = "USARF_EntityProp"
local MAX_DISTANCE = 300

local props = {}

local function heartbeat(t)
	local x = t % 1.6
	return math.exp(-(x / 0.12) ^ 2) + 0.6 * math.exp(-((x - 0.32) / 0.12) ^ 2)
end

local function isNeon(part)
	return part.Material == Enum.Material.Neon
end

local function addPart(entry, part)
	if not part:IsA("BasePart") or entry.byPart[part] then
		return
	end

	local light = part:FindFirstChildWhichIsA("Light")
	local record = {
		part = part,
		rel = entry.model.WorldPivot:ToObjectSpace(part.CFrame),
		size = part.Size,
		color = part.Color,
		transparency = part.Transparency,
		light = light,
		brightness = light and light.Brightness or 0,
		index = #entry.parts + 1,
	}

	entry.byPart[part] = record
	table.insert(entry.parts, record)
end

local function removePart(entry, part)
	local record = entry.byPart[part]

	if not record then
		return
	end

	entry.byPart[part] = nil
	table.remove(entry.parts, table.find(entry.parts, record))
end

local MOTIONS = {}

function MOTIONS.Hover(entry, t, pivot)
	local offset = CFrame.new(0, 0.6 * math.sin(t * 1.2), 0)
		* CFrame.Angles(0.03 * math.sin(t * 0.9), t * 0.35, 0.03 * math.cos(t * 0.9))

	for _, record in ipairs(entry.parts) do
		record.part.CFrame = pivot * offset * record.rel

		if isNeon(record.part) then
			local glow = 0.2 + 0.2 * math.sin(t * 2 + record.index * 0.5)
			record.part.Color = record.color:Lerp(Color3.new(1, 1, 1), glow)
		end
	end
end

function MOTIONS.Core(entry, t, pivot)
	local pulse = 0.5 + 0.5 * math.sin(t * 3)

	for _, record in ipairs(entry.parts) do
		local part = record.part

		if record.light then
			part.Size = record.size * (1 + 0.1 * math.sin(t * 3))
			part.CFrame = pivot * record.rel * CFrame.new(0, 0.15 * math.sin(t * 1.5), 0) * CFrame.Angles(0, t * 0.6, 0)
			record.light.Brightness = record.brightness * (0.75 + 0.35 * pulse)
		elseif isNeon(part) and math.min(record.size.X, record.size.Y, record.size.Z) < 0.3 then
			local flicker = math.clamp(0.5 + math.noise(t * 8, record.index), 0, 1)
			part.Transparency = math.min(record.transparency + 0.5 * flicker * flicker, 0.9)
		end
	end
end

function MOTIONS.Blob(entry, t, pivot)
	local breath = math.sin(t * 1.2)
	local beat = heartbeat(t)

	for _, record in ipairs(entry.parts) do
		local part = record.part

		if part:IsA("MeshPart") then
			local sy = 1 + 0.06 * breath + 0.05 * beat
			local sxz = 1 - 0.03 * breath + 0.03 * beat
			part.Size = record.size * Vector3.new(sxz, sy, sxz)
			part.CFrame = pivot * record.rel * CFrame.new(0, record.size.Y * (sy - 1) / 2, 0)
		elseif isNeon(part) and record.size.Magnitude < 1 then
			part.CFrame = pivot * CFrame.new(0, 0.1 * breath + 0.08 * beat, 0) * record.rel
			part.Transparency = math.clamp(record.transparency + 0.5 * (1 - beat), 0, 0.8)
		end
	end
end

function MOTIONS.Halo(entry, t)
	local motor = entry.halo

	if motor and motor.Parent then
		motor.C0 = entry.haloC0 * CFrame.Angles(0, 0, t * 0.8)
	end
end

local function attach(model)
	if props[model] or not model:IsA("Model") then
		return
	end

	local motion = MOTIONS[model:GetAttribute("PropMotion")]

	if not motion then
		warn(
			"[EntityPropController] "
				.. model.Name
				.. " has unknown PropMotion "
				.. tostring(model:GetAttribute("PropMotion"))
		)
		return
	end

	local entry = {
		model = model,
		motion = motion,
		parts = {},
		byPart = {},
		connections = {},
	}

	if motion == MOTIONS.Halo then
		entry.halo = model:FindFirstChild("HaloSpin", true)
		entry.haloC0 = entry.halo and entry.halo.C0
	else
		for _, descendant in ipairs(model:GetDescendants()) do
			addPart(entry, descendant)
		end

		table.insert(
			entry.connections,
			model.DescendantAdded:Connect(function(descendant)
				addPart(entry, descendant)
			end)
		)

		table.insert(
			entry.connections,
			model.DescendantRemoving:Connect(function(descendant)
				removePart(entry, descendant)
			end)
		)
	end

	props[model] = entry
end

local function detach(model)
	local entry = props[model]

	if not entry then
		return
	end

	props[model] = nil

	for _, connection in ipairs(entry.connections) do
		connection:Disconnect()
	end
end

for _, model in ipairs(CollectionService:GetTagged(TAG)) do
	attach(model)
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(attach)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(detach)

RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	local t = os.clock()

	for model, entry in pairs(props) do
		if model.Parent then
			local pivot = model:GetPivot()

			if not camera or (camera.CFrame.Position - pivot.Position).Magnitude <= MAX_DISTANCE then
				entry.motion(entry, t, pivot)
			end
		end
	end
end)
