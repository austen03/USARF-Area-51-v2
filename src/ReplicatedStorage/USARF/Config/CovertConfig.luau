local CovertConfig = {}

CovertConfig.Certification = "Covert"

CovertConfig.TeamKey = "TestSubject"

CovertConfig.AllowedHomeTeams = {
	CentralIntelligenceAgency = true,
	FederalDefenseService = true,
	FederalAdministration = true,
}

CovertConfig.Outfit = {
	RemoveAvatarAccessories = false,
}

CovertConfig.Tools = {
	"Glock 18c",
}

CovertConfig.ModeratorIcon = {
	Image = "rbxassetid://139048928484649",
	Color = Color3.fromRGB(255, 255, 255),
	Size = 24,
}

CovertConfig.Name = {
	MinLength = 3,
	MaxLength = 20,
}

CovertConfig.PanelCommand = "/covert"

CovertConfig.ToggleCooldownSeconds = 10

return CovertConfig
