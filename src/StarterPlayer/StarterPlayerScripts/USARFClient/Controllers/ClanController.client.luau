-- Clans window (opened from the "Clans" top bar icon). All actions go through
-- ClanService on the server, which re-checks every permission.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local ClanConfig = require(USARF:WaitForChild("Config"):WaitForChild("ClanConfig"))
local Remotes = USARF:WaitForChild("Remotes")
local ClanRequest = Remotes:WaitForChild("ClanRequest")
local ClanUpdated = Remotes:WaitForChild("ClanUpdated")

local COLORS = {
	Panel = Color3.fromRGB(16, 16, 20),
	Section = Color3.fromRGB(22, 22, 28),
	Row = Color3.fromRGB(28, 28, 35),
	RowSelected = Color3.fromRGB(40, 48, 42),
	Stroke = Color3.fromRGB(70, 70, 82),
	Text = Color3.fromRGB(235, 235, 240),
	SubText = Color3.fromRGB(150, 150, 160),
	Accent = Color3.fromRGB(70, 170, 95),
	AccentDark = Color3.fromRGB(45, 95, 58),
	Button = Color3.fromRGB(38, 38, 46),
	Danger = Color3.fromRGB(150, 50, 50),
	Gold = Color3.fromRGB(240, 200, 70),
}

local screenGui
local mainFrame
local statusLabel
local tabButtons = {}
local pages = {}
local currentTab = "Browse"
local myClanSubTab = "Members"

local state = nil -- last GetState result
local browseClans = {}
local selectedClanId = nil
local selectedClan = nil
local refreshQueued = false

-- Settings / create form selections (kept across re-renders)
local createForm = { Name = "", Tag = "", Description = "" }
local createLogoId = ClanConfig.Logos[1] and ClanConfig.Logos[1].Id
local createColorId = ClanConfig.LogoColors[1] and ClanConfig.LogoColors[1].Id
local editLogoId, editColorId, editDescription = nil, nil, nil

--// Small UI helpers

local function create(className, properties)
	local instance = Instance.new(className)

	for key, value in pairs(properties or {}) do
		if key ~= "Parent" then
			instance[key] = value
		end
	end

	if properties and properties.Parent then
		instance.Parent = properties.Parent
	end

	return instance
end

local function corner(parent, radius)
	create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

local function stroke(parent, transparency)
	create("UIStroke", { Color = COLORS.Stroke, Transparency = transparency or 0.5, Thickness = 1, Parent = parent })
end

local function label(parent, text, properties)
	local textLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = text,
		TextColor3 = COLORS.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	})

	for key, value in pairs(properties or {}) do
		textLabel[key] = value
	end

	return textLabel
end

local function button(parent, text, properties, onClick)
	local textButton = create("TextButton", {
		BackgroundColor3 = COLORS.Button,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = COLORS.Text,
		TextSize = 12,
		Parent = parent,
	})

	for key, value in pairs(properties or {}) do
		textButton[key] = value
	end

	corner(textButton, 6)

	if onClick then
		textButton.MouseButton1Click:Connect(onClick)
	end

	return textButton
end

local function textBox(parent, placeholder, properties)
	local box = create("TextBox", {
		BackgroundColor3 = COLORS.Row,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
		PlaceholderText = placeholder,
		PlaceholderColor3 = COLORS.SubText,
		Text = "",
		TextColor3 = COLORS.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})

	for key, value in pairs(properties or {}) do
		box[key] = value
	end

	corner(box, 6)
	create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = box })

	return box
end

local function scrollList(parent, properties)
	local scroll = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})

	for key, value in pairs(properties or {}) do
		scroll[key] = value
	end

	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
	create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = scroll })

	return scroll
end

local function clearChildren(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end
end

-- A logo image tinted with the clan color, or its initials while the image isn't set yet.
local function logoView(parent, logoId, colorId, size, properties)
	local logo = ClanConfig.GetLogo(logoId)
	local color = ClanConfig.GetColor(colorId)
	local tint = color and color.Color or COLORS.Text
	local holder

	if logo and logo.Image ~= "" and logo.Image ~= "rbxassetid://0" then
		holder = create("ImageLabel", {
			BackgroundTransparency = 1,
			Image = logo.Image,
			ImageColor3 = tint,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(size, size),
			Parent = parent,
		})
	else
		holder = create("TextLabel", {
			BackgroundColor3 = COLORS.Row,
			Font = Enum.Font.GothamBlack,
			Text = logo and string.upper(string.sub(logo.Name, 1, 2)) or "?",
			TextColor3 = tint,
			TextScaled = true,
			Size = UDim2.fromOffset(size, size),
			Parent = parent,
		})
		corner(holder, math.floor(size / 4))
		create("UIPadding", {
			PaddingTop = UDim.new(0.18, 0),
			PaddingBottom = UDim.new(0.18, 0),
			PaddingLeft = UDim.new(0.12, 0),
			PaddingRight = UDim.new(0.12, 0),
			Parent = holder,
		})
	end

	for key, value in pairs(properties or {}) do
		holder[key] = value
	end

	return holder
end

-- Two clicks within 3 seconds to confirm destructive actions.
local function confirmButton(parent, text, confirmText, properties, onConfirm)
	local armedUntil = 0
	local target

	target = button(parent, text, properties, function()
		if os.clock() < armedUntil then
			armedUntil = 0
			target.Text = text
			onConfirm()
			return
		end

		armedUntil = os.clock() + 3
		target.Text = confirmText

		task.delay(3, function()
			if target.Parent and os.clock() >= armedUntil then
				target.Text = text
			end
		end)
	end)

	return target
end

local function timeAgo(timestamp)
	local seconds = math.max(0, os.time() - (tonumber(timestamp) or os.time()))

	if seconds < 60 then
		return "just now"
	elseif seconds < 3600 then
		return `{math.floor(seconds / 60)}m ago`
	elseif seconds < 86400 then
		return `{math.floor(seconds / 3600)}h ago`
	end

	return `{math.floor(seconds / 86400)}d ago`
end

local function setStatus(message, isError)
	if statusLabel then
		statusLabel.Text = message or ""
		statusLabel.TextColor3 = isError and Color3.fromRGB(235, 110, 110) or COLORS.SubText
	end
end

--// Server calls

local function request(action, payload)
	local success, result = pcall(function()
		return ClanRequest:InvokeServer(action, payload)
	end)

	if not success or type(result) ~= "table" then
		return { Success = false, Message = "Couldn't reach the server." }
	end

	return result
end

local renderAll

-- Runs a mutating action, shows its message, and reloads everything.
local function act(action, payload)
	setStatus("Working...")

	local result = request(action, payload)
	setStatus(result.Message, not result.Success)

	if result.NeedsGamepass and ClanConfig.CreateGamepassId ~= 0 then
		MarketplaceService:PromptGamePassPurchase(player, ClanConfig.CreateGamepassId)
	end

	task.spawn(function()
		renderAll(true)
	end)

	return result
end

--// Browse page

local browseList, browseSearch, detailPane

local function renderDetail()
	clearChildren(detailPane)

	if not selectedClan then
		label(detailPane, "Select a clan to see its details.", {
			Size = UDim2.new(1, 0, 0, 20),
			TextColor3 = COLORS.SubText,
		})
		return
	end

	local clan = selectedClan

	local header = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 64), LayoutOrder = 1, Parent = detailPane })
	logoView(header, clan.LogoId, clan.ColorId, 56, { Position = UDim2.fromOffset(0, 4) })
	label(header, clan.Name, { Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(68, 6), Size = UDim2.new(1, -68, 0, 22) })
	label(header, `[{clan.Tag}]  ·  {clan.MemberCount}/{ClanConfig.MaxMembers} members`, {
		TextColor3 = COLORS.SubText,
		Position = UDim2.fromOffset(68, 32),
		Size = UDim2.new(1, -68, 0, 18),
	})

	if clan.Description ~= "" then
		label(detailPane, clan.Description, {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			TextColor3 = COLORS.SubText,
		})
	end

	local inClan = state and state.MyClan ~= nil
	local actionButton

	if inClan and state.MyClan.Id == clan.Id then
		actionButton = button(detailPane, "YOUR CLAN", { AutoButtonColor = false, BackgroundColor3 = COLORS.AccentDark })
	elseif inClan then
		actionButton = button(detailPane, "ALREADY IN A CLAN", { AutoButtonColor = false })
	elseif clan.HasRequested then
		actionButton = button(detailPane, "CANCEL REQUEST", {}, function()
			act("CancelRequest", { ClanId = clan.Id })
		end)
	elseif clan.MemberCount >= ClanConfig.MaxMembers then
		actionButton = button(detailPane, "CLAN IS FULL", { AutoButtonColor = false })
	else
		actionButton = button(detailPane, "REQUEST TO JOIN", { BackgroundColor3 = COLORS.Accent }, function()
			act("RequestJoin", { ClanId = clan.Id })
		end)
	end

	actionButton.Size = UDim2.new(1, 0, 0, 34)
	actionButton.LayoutOrder = 3

	label(detailPane, "MEMBERS", { LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = COLORS.SubText })

	for index, member in ipairs(clan.Members or {}) do
		local row = create("Frame", { BackgroundColor3 = COLORS.Row, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 4 + index, Parent = detailPane })
		corner(row, 6)
		label(row, member.Name, { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.6, -10, 1, 0) })
		label(row, member.Rank, {
			Position = UDim2.new(0.6, 0, 0, 0),
			Size = UDim2.new(0.4, -10, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = member.Rank == "Leader" and COLORS.Gold or COLORS.SubText,
		})
	end
end

local function selectClan(clanId)
	selectedClanId = clanId
	local result = request("GetClan", { ClanId = clanId })

	selectedClan = result.Success and result.Clan or nil

	if not result.Success then
		setStatus(result.Message, true)
	end

	renderDetail()
end

local function renderBrowseList()
	clearChildren(browseList)

	if #browseClans == 0 then
		label(browseList, "No clans found.", { Size = UDim2.new(1, 0, 0, 24), TextColor3 = COLORS.SubText })
		return
	end

	for index, summary in ipairs(browseClans) do
		local selected = summary.Id == selectedClanId
		local row = create("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = selected and COLORS.RowSelected or COLORS.Row,
			BorderSizePixel = 0,
			Text = "",
			Size = UDim2.new(1, 0, 0, 50),
			LayoutOrder = index,
			Parent = browseList,
		})
		corner(row, 8)

		logoView(row, summary.LogoId, summary.ColorId, 38, { Position = UDim2.fromOffset(6, 6) })
		label(row, `[{summary.Tag}] {summary.Name}`, { Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(52, 7), Size = UDim2.new(1, -120, 0, 18) })
		label(row, "Leader: " .. tostring(summary.LeaderName), { TextSize = 11, TextColor3 = COLORS.SubText, Position = UDim2.fromOffset(52, 26), Size = UDim2.new(1, -120, 0, 16) })
		label(row, `{summary.MemberCount}/{ClanConfig.MaxMembers}`, {
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = COLORS.SubText,
			Position = UDim2.new(1, -68, 0, 0),
			Size = UDim2.new(0, 60, 1, 0),
		})

		row.MouseButton1Click:Connect(function()
			selectClan(summary.Id)
			renderBrowseList()
		end)
	end
end

local function loadBrowse()
	local result = request("ListClans", { Search = browseSearch and browseSearch.Text or "" })
	browseClans = result.Success and result.Clans or {}
	renderBrowseList()

	if selectedClanId then
		selectClan(selectedClanId)
	else
		renderDetail()
	end
end

local function buildBrowsePage(page)
	local left = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.5, -6, 1, 0), Parent = page })
	browseSearch = textBox(left, "Search clans by name or tag", { Size = UDim2.new(1, 0, 0, 32) })
	browseList = scrollList(left, { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40) })

	local right = create("Frame", {
		BackgroundColor3 = COLORS.Section,
		Position = UDim2.new(0.5, 6, 0, 0),
		Size = UDim2.new(0.5, -6, 1, 0),
		Parent = page,
	})
	corner(right, 10)
	detailPane = scrollList(right, { Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -18, 1, -24) })

	local searchDebounce = 0
	browseSearch:GetPropertyChangedSignal("Text"):Connect(function()
		searchDebounce += 1
		local mine = searchDebounce

		task.delay(0.4, function()
			if mine == searchDebounce then
				loadBrowse()
			end
		end)
	end)
end

--// My Clan page

local myClanHeader, myClanTabs, myClanBody

local function myRankIndex()
	return state and state.MyClan and ClanConfig.GetRankIndex(state.MyClan.MyRank) or 0
end

local function canDo(permission)
	return state and state.MyClan and ClanConfig.HasPermission(state.MyClan.MyRank, permission)
end

local function renderMembers()
	local clan = state.MyClan
	local actorIndex = myRankIndex()

	for index, member in ipairs(clan.Members) do
		local targetIndex = ClanConfig.GetRankIndex(member.Rank)
		local isSelf = member.UserId == state.UserId
		local row = create("Frame", { BackgroundColor3 = COLORS.Row, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = index, Parent = myClanBody })
		corner(row, 6)

		label(row, member.Name .. (isSelf and "  (you)" or ""), { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.34, -10, 1, 0) })
		label(row, member.Rank, {
			Position = UDim2.new(0.34, 0, 0, 0),
			Size = UDim2.new(0.18, 0, 1, 0),
			TextColor3 = member.Rank == "Leader" and COLORS.Gold or COLORS.SubText,
		})

		local actions = create("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.52, 0, 0, 5), Size = UDim2.new(0.48, -6, 1, -10), Parent = row })
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = actions,
		})

		local below = not isSelf and targetIndex < actorIndex

		if below and canDo("RankMembers") then
			if targetIndex + 1 < actorIndex and ClanConfig.Ranks[targetIndex + 1] ~= "Leader" then
				button(actions, "▲", { Size = UDim2.fromOffset(28, 26), LayoutOrder = 1 }, function()
					act("SetRank", { UserId = member.UserId, Rank = ClanConfig.Ranks[targetIndex + 1] })
				end)
			end

			if targetIndex > 1 then
				button(actions, "▼", { Size = UDim2.fromOffset(28, 26), LayoutOrder = 2 }, function()
					act("SetRank", { UserId = member.UserId, Rank = ClanConfig.Ranks[targetIndex - 1] })
				end)
			end
		end

		if below and canDo("KickMembers") then
			confirmButton(actions, "Kick", "Sure?", { Size = UDim2.fromOffset(48, 26), LayoutOrder = 3, BackgroundColor3 = COLORS.Danger }, function()
				act("Kick", { UserId = member.UserId })
			end)
		end

		if not isSelf and canDo("TransferLeadership") then
			confirmButton(actions, "Make Leader", "Confirm?", { Size = UDim2.fromOffset(84, 26), LayoutOrder = 4 }, function()
				act("TransferLeadership", { UserId = member.UserId })
			end)
		end
	end
end

local function renderRequests()
	local requests = state.MyClan.Requests or {}

	if not canDo("ManageRequests") then
		label(myClanBody, `Officers and above manage join requests.`, { Size = UDim2.new(1, 0, 0, 24), TextColor3 = COLORS.SubText })
		return
	end

	if #requests == 0 then
		label(myClanBody, "No pending join requests.", { Size = UDim2.new(1, 0, 0, 24), TextColor3 = COLORS.SubText })
		return
	end

	for index, pending in ipairs(requests) do
		local row = create("Frame", { BackgroundColor3 = COLORS.Row, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = index, Parent = myClanBody })
		corner(row, 6)
		label(row, pending.Name, { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.5, -10, 1, 0) })
		label(row, timeAgo(pending.RequestedAt), { TextColor3 = COLORS.SubText, Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.2, 0, 1, 0) })
		button(row, "Accept", { BackgroundColor3 = COLORS.Accent, Position = UDim2.new(1, -140, 0, 5), Size = UDim2.fromOffset(64, 26) }, function()
			act("AcceptRequest", { UserId = pending.UserId })
		end)
		button(row, "Deny", { BackgroundColor3 = COLORS.Danger, Position = UDim2.new(1, -70, 0, 5), Size = UDim2.fromOffset(64, 26) }, function()
			act("DenyRequest", { UserId = pending.UserId })
		end)
	end
end

local function renderLog()
	local entries = state.MyClan.Log or {}

	if #entries == 0 then
		label(myClanBody, "No activity yet.", { Size = UDim2.new(1, 0, 0, 24), TextColor3 = COLORS.SubText })
		return
	end

	for index, entry in ipairs(entries) do
		local row = create("Frame", { BackgroundColor3 = COLORS.Row, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = index, Parent = myClanBody })
		corner(row, 6)
		label(row, entry.Text, { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -90, 1, 0) })
		label(row, timeAgo(entry.Time), {
			TextColor3 = COLORS.SubText,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(1, -86, 0, 0),
			Size = UDim2.new(0, 78, 1, 0),
		})
	end
end

-- Grid of selectable logo or color swatches.
-- tintColorId previews the logo choices in the currently picked color.
local function pickerGrid(parent, layoutOrder, items, selectedId, onPick, isColor, tintColorId)
	local grid = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = layoutOrder,
		Parent = parent,
	})
	create("UIGridLayout", {
		CellSize = isColor and UDim2.fromOffset(28, 28) or UDim2.fromOffset(46, 46),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	-- Room for the selection ring, which is drawn outside the cell and would otherwise be
	-- clipped against the scrolling list's edge.
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		Parent = grid,
	})

	for index, item in ipairs(items) do
		local isSelected = item.Id == selectedId
		local cell = create("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = isColor and item.Color or (isSelected and COLORS.RowSelected or COLORS.Row),
			BorderSizePixel = 0,
			Text = "",
			LayoutOrder = index,
			Parent = grid,
		})
		corner(cell, isColor and 14 or 8)

		if isSelected then
			-- Border mode: on a TextButton a UIStroke otherwise outlines the (empty) text only.
			create("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.fromRGB(255, 255, 255),
				Thickness = isColor and 3 or 2,
				Parent = cell,
			})

			if isColor then
				local r, g, b = item.Color.R, item.Color.G, item.Color.B
				local isLight = (0.299 * r + 0.587 * g + 0.114 * b) > 0.6

				cell.Text = "✓"
				cell.Font = Enum.Font.GothamBlack
				cell.TextSize = 16
				cell.TextColor3 = isLight and Color3.fromRGB(20, 20, 24) or Color3.fromRGB(255, 255, 255)
			end
		end

		if not isColor then
			logoView(cell, item.Id, tintColorId, 36, { Position = UDim2.fromOffset(5, 5) })
		end

		cell.MouseButton1Click:Connect(function()
			onPick(item.Id)
		end)
	end

	return grid
end

local renderMyClan

local function renderSettings()
	local clan = state.MyClan
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	if canDo("EditAppearance") then
		editLogoId = editLogoId or clan.LogoId
		editColorId = editColorId or clan.ColorId

		label(myClanBody, "LOGO", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = COLORS.SubText })
		pickerGrid(myClanBody, nextOrder(), ClanConfig.Logos, editLogoId, function(id)
			editLogoId = id
			renderMyClan()
		end, false, editColorId)

		label(myClanBody, "LOGO COLOR", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = COLORS.SubText })
		pickerGrid(myClanBody, nextOrder(), ClanConfig.LogoColors, editColorId, function(id)
			editColorId = id
			renderMyClan()
		end, true)

		label(myClanBody, "DESCRIPTION", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = COLORS.SubText })
		local description = textBox(myClanBody, `Up to {ClanConfig.Description.MaxLength} characters`, {
			LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 56),
			MultiLine = true,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = editDescription or clan.Description or "",
		})
		-- Keep an unsaved description when picking a logo/color re-renders the tab.
		description:GetPropertyChangedSignal("Text"):Connect(function()
			editDescription = description.Text
		end)

		button(myClanBody, "SAVE CHANGES", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = COLORS.Accent }, function()
			act("EditAppearance", { LogoId = editLogoId, ColorId = editColorId, Description = description.Text })
		end)
	else
		label(myClanBody, "Only the Leader can change the clan's logo, color and description.", {
			LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 24),
			TextColor3 = COLORS.SubText,
		})
	end

	if canDo("Disband") then
		label(myClanBody, "To leave, transfer leadership to another member first (Members tab → Make Leader).", {
			LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 24),
			TextColor3 = COLORS.SubText,
		})
		confirmButton(myClanBody, "DISBAND CLAN", "CLICK AGAIN TO DISBAND FOREVER", {
			LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = COLORS.Danger,
		}, function()
			act("Disband")
		end)
	else
		confirmButton(myClanBody, "LEAVE CLAN", "CLICK AGAIN TO LEAVE", {
			LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = COLORS.Danger,
		}, function()
			act("Leave")
		end)
	end
end

function renderMyClan()
	clearChildren(myClanHeader)
	clearChildren(myClanBody)

	local clan = state and state.MyClan

	myClanTabs.Visible = clan ~= nil

	if not clan then
		label(myClanHeader, "You're not in a clan. Find one in Browse and request to join.", {
			Size = UDim2.new(1, 0, 1, 0),
			TextColor3 = COLORS.SubText,
			TextWrapped = true,
		})
		return
	end

	logoView(myClanHeader, clan.LogoId, clan.ColorId, 48, { Position = UDim2.fromOffset(0, 2) })
	label(myClanHeader, `[{clan.Tag}] {clan.Name}`, { Font = Enum.Font.GothamBold, TextSize = 17, Position = UDim2.fromOffset(60, 4), Size = UDim2.new(1, -60, 0, 22) })
	label(myClanHeader, `Your rank: {clan.MyRank}  ·  {#clan.Members}/{ClanConfig.MaxMembers} members`, {
		TextColor3 = COLORS.SubText,
		Position = UDim2.fromOffset(60, 28),
		Size = UDim2.new(1, -60, 0, 18),
	})

	for name, tab in pairs(myClanTabs:GetChildren()) do
		if tab:IsA("TextButton") then
			local isCurrent = tab.Name == myClanSubTab
			tab.BackgroundColor3 = isCurrent and COLORS.AccentDark or COLORS.Button

			if tab.Name == "Requests" then
				local count = #(clan.Requests or {})
				tab.Text = count > 0 and `Requests ({count})` or "Requests"
			end
		end
	end

	if myClanSubTab == "Members" then
		renderMembers()
	elseif myClanSubTab == "Requests" then
		renderRequests()
	elseif myClanSubTab == "Log" then
		renderLog()
	else
		renderSettings()
	end
end

local function buildMyClanPage(page)
	myClanHeader = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52), Parent = page })

	myClanTabs = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 0, 28), Parent = page })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = myClanTabs })

	for index, name in ipairs({ "Members", "Requests", "Log", "Settings" }) do
		local tab = button(myClanTabs, name, { Name = name, Size = UDim2.fromOffset(100, 28), LayoutOrder = index }, function()
			myClanSubTab = name
			renderMyClan()
		end)
		tab.Name = name
	end

	myClanBody = scrollList(page, { Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 1, -96) })
end

--// Create page

local createBody

local function renderCreate()
	clearChildren(createBody)

	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	if state and state.MyClan then
		label(createBody, "You're already in a clan. Leave it before creating your own.", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 24), TextColor3 = COLORS.SubText })
		return
	end

	if not (state and state.CreateAvailable) then
		label(createBody, "Clan creation isn't available yet. You can still join a clan from Browse.", {
			LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 24),
			TextColor3 = COLORS.SubText,
		})
		return
	end

	if not state.CanCreate then
		label(createBody, "Creating a clan needs the Clan Creator gamepass. Anyone can join a clan for free.", {
			LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 24),
			TextColor3 = COLORS.SubText,
			TextWrapped = true,
		})
		button(createBody, "GET CLAN CREATOR", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = COLORS.Gold, TextColor3 = Color3.fromRGB(30, 25, 10) }, function()
			MarketplaceService:PromptGamePassPurchase(player, ClanConfig.CreateGamepassId)
		end)
		return
	end

	label(createBody, "NAME", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = COLORS.SubText })
	local nameBox = textBox(createBody, `{ClanConfig.Name.MinLength}-{ClanConfig.Name.MaxLength} letters, numbers or spaces`, {
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 32),
		Text = createForm.Name,
	})
	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		createForm.Name = nameBox.Text
	end)

	label(createBody, "TAG", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = COLORS.SubText })
	local tagBox = textBox(createBody, `{ClanConfig.Tag.MinLength}-{ClanConfig.Tag.MaxLength} letters or numbers`, {
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 32),
		Text = createForm.Tag,
	})
	tagBox:GetPropertyChangedSignal("Text"):Connect(function()
		local cleaned = string.upper(string.sub((tagBox.Text:gsub("[^%w]", "")), 1, ClanConfig.Tag.MaxLength))

		if cleaned ~= tagBox.Text then
			tagBox.Text = cleaned
		end

		createForm.Tag = cleaned
	end)

	label(createBody, "LOGO", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = COLORS.SubText })
	pickerGrid(createBody, nextOrder(), ClanConfig.Logos, createLogoId, function(id)
		createLogoId = id
		renderCreate()
	end, false, createColorId)

	label(createBody, "LOGO COLOR", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = COLORS.SubText })
	pickerGrid(createBody, nextOrder(), ClanConfig.LogoColors, createColorId, function(id)
		createColorId = id
		renderCreate()
	end, true)

	label(createBody, "DESCRIPTION (OPTIONAL)", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = COLORS.SubText })
	local descriptionBox = textBox(createBody, `Up to {ClanConfig.Description.MaxLength} characters`, {
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 56),
		MultiLine = true,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = createForm.Description,
	})
	descriptionBox:GetPropertyChangedSignal("Text"):Connect(function()
		createForm.Description = descriptionBox.Text
	end)

	button(createBody, "CREATE CLAN", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = COLORS.Accent }, function()
		local result = act("Create", {
			Name = createForm.Name,
			Tag = createForm.Tag,
			LogoId = createLogoId,
			ColorId = createColorId,
			Description = createForm.Description,
		})

		if result.Success then
			createForm = { Name = "", Tag = "", Description = "" }
			currentTab = "MyClan"
		end
	end)
end

--// Window

local function updateTabs()
	for name, tabButton in pairs(tabButtons) do
		tabButton.BackgroundColor3 = name == currentTab and COLORS.AccentDark or COLORS.Button
	end

	for name, page in pairs(pages) do
		page.Visible = name == currentTab
	end

	-- Creating only makes sense while you're not in a clan.
	tabButtons.Create.Visible = not (state and state.MyClan)

	if currentTab == "Create" and state and state.MyClan then
		currentTab = "MyClan"
		updateTabs()
	end
end

function renderAll(reloadState)
	if reloadState or not state then
		local result = request("GetState")

		if result.Success then
			state = result
		end
	end

	editLogoId, editColorId, editDescription = nil, nil, nil
	updateTabs()

	if currentTab == "Browse" then
		loadBrowse()
	elseif currentTab == "MyClan" then
		renderMyClan()
	else
		renderCreate()
	end
end

local function applyScale()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local scale = math.clamp(math.min(viewport.X / 1100, viewport.Y / 680), 0.65, 1)
	mainFrame:FindFirstChildOfClass("UIScale").Scale = scale
end

local function buildWindow()
	screenGui = create("ScreenGui", {
		Name = "USARF_Clans",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 60,
		Enabled = false,
		Parent = playerGui,
	})

	mainFrame = create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(760, 500),
		BackgroundColor3 = COLORS.Panel,
		BorderSizePixel = 0,
		Parent = screenGui,
	})
	corner(mainFrame, 14)
	stroke(mainFrame, 0.4)
	create("UIScale", { Parent = mainFrame })

	label(mainFrame, "CLANS", { Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(18, 12), Size = UDim2.new(1, -80, 0, 22) })
	label(mainFrame, `Anyone can join a clan · up to {ClanConfig.MaxMembers} members`, {
		TextSize = 11,
		TextColor3 = COLORS.SubText,
		Position = UDim2.fromOffset(18, 34),
		Size = UDim2.new(1, -80, 0, 16),
	})

	button(mainFrame, "X", { Position = UDim2.new(1, -46, 0, 12), Size = UDim2.fromOffset(32, 32) }, function()
		screenGui.Enabled = false
	end)

	local tabRow = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 60), Size = UDim2.new(1, -36, 0, 30), Parent = mainFrame })
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabRow })

	for index, tab in ipairs({ { "Browse", "Browse" }, { "MyClan", "My Clan" }, { "Create", "Create" } }) do
		tabButtons[tab[1]] = button(tabRow, tab[2], { Size = UDim2.fromOffset(130, 30), LayoutOrder = index }, function()
			currentTab = tab[1]
			renderAll(false)
		end)
	end

	local content = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 100), Size = UDim2.new(1, -36, 1, -136), Parent = mainFrame })

	for _, name in ipairs({ "Browse", "MyClan", "Create" }) do
		pages[name] = create("Frame", { Name = name, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = content })
	end

	buildBrowsePage(pages.Browse)
	buildMyClanPage(pages.MyClan)
	createBody = scrollList(pages.Create, { Size = UDim2.fromScale(1, 1) })

	statusLabel = label(mainFrame, "", { TextSize = 12, TextColor3 = COLORS.SubText, Position = UDim2.new(0, 18, 1, -30), Size = UDim2.new(1, -36, 0, 20) })

	applyScale()

	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)
	end
end

local function toggle()
	if not screenGui then
		buildWindow()
	end

	screenGui.Enabled = not screenGui.Enabled

	if screenGui.Enabled then
		setStatus("")
		renderAll(true)
	end
end

_G.USARFToggleClans = toggle

-- Something changed in some clan (here or in another server): refresh if the window is open.
ClanUpdated.OnClientEvent:Connect(function()
	if not screenGui or not screenGui.Enabled or refreshQueued then
		return
	end

	refreshQueued = true

	task.delay(0.5, function()
		refreshQueued = false

		if screenGui.Enabled then
			renderAll(true)
		end
	end)
end)

print("[ClanController] Loaded")
