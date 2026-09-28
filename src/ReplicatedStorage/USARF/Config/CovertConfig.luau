-- Covert mode: a certified player plays as a Test Subject while keeping their
-- home team's radio (and, when they choose, its door access).

local CovertConfig = {}

-- Certification a player needs (see CertificationService).
CovertConfig.Certification = "Covert"

-- The team covert players join.
CovertConfig.TeamKey = "TestSubject"

-- The only teams covert can be used from (USARFConfig.Teams keys). Players on
-- other teams don't see the Covert button; the certification is still required.
CovertConfig.AllowedHomeTeams = {
	CentralIntelligenceAgency = true,
	FederalDefenseService = true,
	FederalAdministration = true,
}

-- Covert players wear the Test Subject team's outfit (UniformConfig.Teams["Test
-- Subject"]). Unlike regular Test Subjects, their avatar accessories are removed
-- so they don't give the player away.
CovertConfig.Outfit = {
	RemoveAvatarAccessories = false,
}

-- Tools given on top of the Test Subject loadout.
CovertConfig.Tools = {
	"Glock 18c",
}

-- Leaderboard icon moderators see on covert players. Upload it white on a
-- transparent background: Color tints the image, and a black image stays black.
-- Size is in pixels, up to 24 (the row is 26 tall).
CovertConfig.ModeratorIcon = {
	Image = "rbxassetid://139048928484649",
	Color = Color3.fromRGB(255, 255, 255),
	Size = 24,
}

CovertConfig.Name = {
	MinLength = 3,
	MaxLength = 20,
}

-- Chat command that opens the covert panel.
CovertConfig.PanelCommand = "/covert"

-- Seconds between going covert and going back (and vice versa).
CovertConfig.ToggleCooldownSeconds = 10

return CovertConfig
