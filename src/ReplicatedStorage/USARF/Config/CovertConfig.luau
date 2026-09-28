-- Covert mode: a certified player plays as a Test Subject while keeping their
-- home team's radio (and, when they choose, its door access).

local CovertConfig = {}

-- Certification a player needs (see CertificationService).
CovertConfig.Certification = "Covert"

-- The team covert players join.
CovertConfig.TeamKey = "TestSubject"

-- Home teams that cannot go covert.
CovertConfig.BlockedHomeTeams = {
	TestSubject = true,
	Loading = true,
	PMC = true,
}

-- Covert players wear the Test Subject team's outfit (UniformConfig.Teams["Test
-- Subject"]). Unlike regular Test Subjects, their avatar accessories are removed
-- so they don't give the player away.
CovertConfig.Outfit = {
	RemoveAvatarAccessories = true,
}

-- Tools given on top of the Test Subject loadout.
CovertConfig.Tools = {
	"Glock 18c",
}

-- Leaderboard icon moderators see on covert players. Upload it white on a
-- transparent background: Color tints the image, and a black image stays black.
-- Size is in pixels, up to 24 (the row is 26 tall).
CovertConfig.ModeratorIcon = {
	Image = "rbxassetid://92453895448695",
	Color = Color3.fromRGB(255, 255, 255),
	Size = 24,
}

CovertConfig.Name = {
	MinLength = 3,
	MaxLength = 20,
}

-- Chat commands. The radio command sends to the radio instead of public chat.
CovertConfig.PanelCommand = "/covert"
CovertConfig.RadioCommand = "/c"

-- Radio channel /c falls back to when the home team has no channel of its own.
CovertConfig.RadioFallbackChannel = "general"

-- Seconds between going covert and going back (and vice versa).
CovertConfig.ToggleCooldownSeconds = 10

return CovertConfig
