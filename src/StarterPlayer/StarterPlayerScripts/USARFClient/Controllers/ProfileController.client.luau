local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Gui = PlayerGui:WaitForChild("USARFGui")
local ProfilePanel = Gui:WaitForChild("ProfilePanel")

local AvatarImage = ProfilePanel:WaitForChild("AvatarImage")
local UsernameLabel = ProfilePanel:WaitForChild("UsernameLabel")
local RankLabel = ProfilePanel:WaitForChild("RankLabel")
local TeamLabel = ProfilePanel:WaitForChild("TeamLabel")

local uiScale = ProfilePanel:FindFirstChild("UIScale")
if not uiScale then
	uiScale = Instance.new("UIScale")
	uiScale.Parent = ProfilePanel
end

local TEAM_DISPLAY_NAMES = {
	["137th Military Police Company"] = "137th MP",
	["108th Infantry Regiment"] = "108th Infantry",
	["1st Spec. Ops. A . I . G"] = "1st SPEC OPS",
	["Central Intelligence Agency"] = "CIA",
	["Federal Bureau of Investigation"] = "FBI",
	["Federal Defense Service"] = "FDS",
	["Secret Service"] = "USSS",
	["Research Division"] = "Research",
	["Medical Division"] = "Medical",
	["Engineering & Technical"] = "Engineering",
	["Rules & Regulations"] = "R&R",
	["United States Air Force"] = "USAF",
	["Department of Defense"] = "DoD",
	["Facility Personnel"] = "Facility Personnel",
	["EXTECH"] = "EXTECH",
	["President of the United States"] = "POTUS",
	["Vice President of the United States"] = "VPOTUS",
	["Presidential Cabinet"] = "Cabinet",
	["Federal Administration"] = "Federal Admin",
	["Test Subject"] = "Test Subject",
	["Private Military Company"] = "PMC",
	["Private Military Contractor"] = "PMC",
}

local function applyDesktopLayout()
	uiScale.Scale = 1
	ProfilePanel.AnchorPoint = Vector2.new(0, 1)
	ProfilePanel.Position = UDim2.new(0, 24, 1, -16)
	ProfilePanel.Size = UDim2.new(0, 280, 0, 96)
end

local function getShortTeamName(teamName)
	if teamName == nil or teamName == "" then
		return ""
	end

	return TEAM_DISPLAY_NAMES[teamName] or teamName
end

local function updateVisibility()
	local inMenu = Player:GetAttribute("USARF_InMenu")

	if inMenu == nil then
		inMenu = true
	end

	ProfilePanel.Visible = inMenu == false
end

local function updateAvatar()
	local image = Players:GetUserThumbnailAsync(
		Player.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size150x150
	)

	AvatarImage.Image = image
end

local function updateProfile()
	local teamName = Player:GetAttribute("USARF_TeamName") or ""

	UsernameLabel.Text = Player.Name
	RankLabel.Text = Player:GetAttribute("USARF_RankName") or "Guest"
	TeamLabel.Text = getShortTeamName(teamName)

	updateVisibility()
end

Player:GetAttributeChangedSignal("USARF_TeamName"):Connect(updateProfile)
Player:GetAttributeChangedSignal("USARF_TeamKey"):Connect(updateProfile)
Player:GetAttributeChangedSignal("USARF_RankName"):Connect(updateProfile)
Player:GetAttributeChangedSignal("USARF_InMenu"):Connect(updateVisibility)

applyDesktopLayout()
updateAvatar()
updateProfile()
updateVisibility()

print("USARF ProfileController initialized")
