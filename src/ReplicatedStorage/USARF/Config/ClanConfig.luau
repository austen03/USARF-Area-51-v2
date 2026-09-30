local ClanConfig = {}

ClanConfig.CreateGamepassId = 1999749146

ClanConfig.MaxMembers = 25

ClanConfig.MaxPendingRequests = 25

ClanConfig.MaxLogEntries = 50

ClanConfig.Name = {
	MinLength = 3,
	MaxLength = 20,
}

ClanConfig.Tag = {
	MinLength = 3,
	MaxLength = 4,
}

ClanConfig.Description = {
	MaxLength = 120,
}

ClanConfig.BlacklistedTags = { "USARF", "USA", "MOD", "ADMIN", "STAFF", "RBLX", "RBX", "ROBLOX" }

ClanConfig.BlacklistedNames = { "USARF", "USA", "MOD", "ADMIN", "STAFF", "RBLX", "RBX", "ROBLOX" }

ClanConfig.Ranks = { "Member", "Veteran", "Specialist", "Officer", "Co-Leader", "Leader" }

ClanConfig.Permissions = {
	ManageRequests = "Officer",
	RankMembers = "Officer",
	KickMembers = "Co-Leader",
	EditAppearance = "Leader",
	TransferLeadership = "Leader",
	Disband = "Leader",
}

ClanConfig.Logos = {
	{ Id = "Skull", Name = "Skull", Image = "rbxassetid://81619610446507" },
	{ Id = "Warning", Name = "Warning", Image = "rbxassetid://120772833059655" },
	{ Id = "Radiation", Name = "Radiation", Image = "rbxassetid://94594911587456" },
	{ Id = "Gas Mask", Name = "Gas Mask", Image = "rbxassetid://95012490738164" },
	{ Id = "Flask", Name = "Flask", Image = "rbxassetid://89745401015778" },
	{ Id = "Syringe", Name = "Syringe", Image = "rbxassetid://107064479577467" },
	{ Id = "Crosshair", Name = "Crosshair", Image = "rbxassetid://116480001406592" },
	{ Id = "Watchful Eye", Name = "Watchful Eye", Image = "rbxassetid://138562409695570" },
	{ Id = "Cell Bars", Name = "Cell Bars", Image = "rbxassetid://118876623089477" },
	{ Id = "Crown", Name = "Crown", Image = "rbxassetid://111537920420363" },
	{ Id = "Failed Test", Name = "Failed Test", Image = "rbxassetid://90144724893194" },
	{ Id = "Lightning", Name = "Lightning", Image = "rbxassetid://87664634084286" },
	{ Id = "Tally Marks", Name = "Tally Marks", Image = "rbxassetid://133960714876708" },
	{ Id = "Crossed Knives", Name = "Crossed Knives", Image = "rbxassetid://83161396526682" },
	{ Id = "Claw Marks", Name = "Claw Marks", Image = "rbxassetid://129504150948232" },
	{ Id = "Crowbar", Name = "Crowbar", Image = "rbxassetid://82870956657911" },
	{ Id = "Handprint", Name = "Handprint", Image = "rbxassetid://91336733287924" },
	{ Id = "Raised Fist", Name = "Raised Fist", Image = "rbxassetid://78985279345339" },
	{ Id = "Scarred Eye", Name = "Scarred Eye", Image = "rbxassetid://84682138029345" },
}

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

function ClanConfig.HasPermission(rankName: string?, permission: string): boolean
	local required = ClanConfig.Permissions[permission]

	if not required then
		return false
	end

	return ClanConfig.GetRankIndex(rankName) >= ClanConfig.GetRankIndex(required)
end

return ClanConfig
