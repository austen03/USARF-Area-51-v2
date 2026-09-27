-- USARF Clans configuration (shared by the server ClanService and the client ClanController).

local ClanConfig = {}

-- Creating a clan requires this gamepass. Any player can join a clan.
-- 0 = not set up yet: creating is disabled until you put the real gamepass ID here.
ClanConfig.CreateGamepassId = 1999749146

ClanConfig.MaxMembers = 25

-- Pending join requests a clan can hold at once.
ClanConfig.MaxPendingRequests = 25

-- Clan-visible audit log entries kept per clan.
ClanConfig.MaxLogEntries = 50

ClanConfig.Name = {
	MinLength = 3,
	MaxLength = 20,
}

-- Tags are 3-4 characters, letters and numbers only, stored in UPPERCASE.
ClanConfig.Tag = {
	MinLength = 3,
	MaxLength = 4,
}

ClanConfig.Description = {
	MaxLength = 120,
}

-- Exact tags that can't be used.
ClanConfig.BlacklistedTags = { "USARF", "USA", "MOD", "ADMIN", "STAFF", "RBLX", "RBX", "ROBLOX" }

-- Names and tags can't start with or contain any of these (case-insensitive).
ClanConfig.BlacklistedNames = { "USARF", "USA", "MOD", "ADMIN", "STAFF", "RBLX", "RBX", "ROBLOX" }

-- Lowest to highest. Leader is only gained through Create or Transfer Leadership.
ClanConfig.Ranks = { "Member", "Veteran", "Specialist", "Officer", "Co-Leader", "Leader" }

-- Minimum rank for each action. Ranking and kicking only apply to members ranked
-- below you, and you can only promote someone to a rank below your own.
ClanConfig.Permissions = {
	ManageRequests = "Officer",
	RankMembers = "Officer",
	KickMembers = "Co-Leader",
	EditAppearance = "Leader", -- description, logo, logo color
	TransferLeadership = "Leader",
	Disband = "Leader",
}

-- Logo choices. Put your image asset IDs in Image; a logo with rbxassetid://0 shows its
-- name as a placeholder in the menu and no icon on name tags.
ClanConfig.Logos = {
	{ Id = "Skull", Name = "Skull", Image = "rbxassetid://80216527090034" },
	{ Id = "Warning", Name = "Warning", Image = "rbxassetid://102136528195329" },
	{ Id = "Radiation", Name = "Radiation", Image = "rbxassetid://115183350472165" },
	{ Id = "Gas Mask", Name = "Gas Mask", Image = "rbxassetid://111798211260520" },
	{ Id = "Flask", Name = "Flask", Image = "rbxassetid://80753298032468" },
	{ Id = "Syringe", Name = "Syringe", Image = "rbxassetid://113001959986943" },
	{ Id = "Crosshair", Name = "Crosshair", Image = "rbxassetid://139636929038054" },
	{ Id = "Watchful Eye", Name = "Watchful Eye", Image = "rbxassetid://128312739582487" },
	{ Id = "Cell Bars", Name = "Cell Bars", Image = "rbxassetid://100798766022243" },
	{ Id = "Crown", Name = "Crown", Image = "rbxassetid://93151175489933" },
	{ Id = "Failed Test", Name = "Failed Test", Image = "rbxassetid://99792597791812" },
	{ Id = "Lightning", Name = "Lightning", Image = "rbxassetid://78663557506757" },
	{ Id = "Tally Marks", Name = "Tally Marks", Image = "rbxassetid://130976151585201" },
	{ Id = "Crossed Knives", Name = "Crossed Knives", Image = "rbxassetid://82222168657003" },
	{ Id = "Claw Marks", Name = "Claw Marks", Image = "rbxassetid://92495244669216" },
	{ Id = "Crowbar", Name = "Crowbar", Image = "rbxassetid://76376055534695" },
	{ Id = "Handprint", Name = "Handprint", Image = "rbxassetid://111789201294421" },
	{ Id = "Raised Fist", Name = "Raised Fist", Image = "rbxassetid://136770904384479" },
	{ Id = "Scarred Eye", Name = "Scarred Eye", Image = "rbxassetid://74181839237293" },
}

-- Logo colors players can pick from.
ClanConfig.LogoColors = {
	{ Id = "White", Color = Color3.fromRGB(235, 235, 235) },
	{ Id = "Red", Color = Color3.fromRGB(225, 60, 60) },
	{ Id = "Orange", Color = Color3.fromRGB(240, 140, 50) },
	{ Id = "Gold", Color = Color3.fromRGB(240, 200, 70) },
	{ Id = "Green", Color = Color3.fromRGB(80, 200, 100) },
	{ Id = "Teal", Color = Color3.fromRGB(60, 190, 180) },
	{ Id = "Blue", Color = Color3.fromRGB(70, 140, 235) },
	{ Id = "Navy", Color = Color3.fromRGB(50, 80, 160) },
	{ Id = "Purple", Color = Color3.fromRGB(150, 90, 220) },
	{ Id = "Pink", Color = Color3.fromRGB(235, 110, 180) },
	{ Id = "Grey", Color = Color3.fromRGB(130, 130, 140) },
	{ Id = "Black", Color = Color3.fromRGB(30, 30, 34) },
}

-- Name tags show the clan logo and [TAG] only while the player is on this team.
ClanConfig.NameTagTeamKey = "TestSubject"

function ClanConfig.GetRankIndex(rankName: string?): number
	for index, name in ipairs(ClanConfig.Ranks) do
		if name == rankName then
			return index
		end
	end

	return 0
end

function ClanConfig.GetLogo(logoId: string?)
	for _, logo in ipairs(ClanConfig.Logos) do
		if logo.Id == logoId then
			return logo
		end
	end

	return nil
end

function ClanConfig.GetColor(colorId: string?)
	for _, entry in ipairs(ClanConfig.LogoColors) do
		if entry.Id == colorId then
			return entry
		end
	end

	return nil
end

-- True if rankName meets the minimum rank for a ClanConfig.Permissions entry.
function ClanConfig.HasPermission(rankName: string?, permission: string): boolean
	local required = ClanConfig.Permissions[permission]

	if not required then
		return false
	end

	return ClanConfig.GetRankIndex(rankName) >= ClanConfig.GetRankIndex(required)
end

return ClanConfig
