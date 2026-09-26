local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local REMOTE_NAME = "AnnouncementBannerRemote"

local remote = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME):WaitForChild(REMOTE_NAME)

local gui = Instance.new("ScreenGui")
gui.Name = "USARFAnnouncementBannerGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 950
gui.Parent = PlayerGui

local queue = {}
local showing = false

local function tableToColor3(tbl)
	if type(tbl) ~= "table" then
		return Color3.fromRGB(56, 132, 255)
	end

	return Color3.new(tbl[1] or 0.22, tbl[2] or 0.52, tbl[3] or 1)
end

local function createBanner(payload)
	local frame = Instance.new("Frame")
	frame.Name = "AnnouncementBanner"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, -120)
	frame.Size = UDim2.new(0, 620, 0, 78)
	frame.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
	frame.BackgroundTransparency = 0.04
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = tableToColor3(payload.color)
	stroke.Transparency = 0.45
	stroke.Thickness = 1
	stroke.Parent = frame

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.new(0, 18, 0, 0)
	icon.Size = UDim2.new(0, 40, 1, 0)
	icon.Font = Enum.Font.GothamBold
	icon.Text = tostring(payload.icon or "📢")
	icon.TextColor3 = Color3.fromRGB(255, 255, 255)
	icon.TextSize = 25
	icon.TextXAlignment = Enum.TextXAlignment.Center
	icon.TextYAlignment = Enum.TextYAlignment.Center
	icon.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 72, 0, 13)
	title.Size = UDim2.new(1, -92, 0, 27)
	title.Font = Enum.Font.GothamBold
	title.Text = tostring(payload.title or "Announcement")
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 17
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = frame

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.new(0, 72, 0, 43)
	body.Size = UDim2.new(1, -92, 0, 22)
	body.Font = Enum.Font.Gotham
	body.Text = tostring(payload.body or "")
	body.TextColor3 = Color3.fromRGB(205, 205, 215)
	body.TextSize = 14
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextTruncate = Enum.TextTruncate.AtEnd
	body.Parent = frame

	return frame
end

local function showPayload(payload)
	showing = true

	local frame = createBanner(payload)

	local showTween = TweenService:Create(
		frame,
		TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{
			Position = UDim2.new(0.5, 0, 0, 112),
		}
	)

	showTween:Play()
	showTween.Completed:Wait()

	task.wait(6)

	local hideTween = TweenService:Create(
		frame,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Position = UDim2.new(0.5, 0, 0, -120),
			BackgroundTransparency = 1,
		}
	)

	hideTween:Play()
	hideTween.Completed:Wait()

	frame:Destroy()
	showing = false

	if #queue > 0 then
		local nextPayload = table.remove(queue, 1)
		showPayload(nextPayload)
	end
end

remote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end

	if showing then
		table.insert(queue, payload)
	else
		task.spawn(showPayload, payload)
	end
end)

print("[AnnouncementBannerController] Loaded")