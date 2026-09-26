local DetainConfig = {}

DetainConfig.MaxCuffDistance = 10
DetainConfig.MaxEscortDistance = 14
DetainConfig.EscortTeleportDistance = 35

DetainConfig.CuffProgressSeconds = 0.65

DetainConfig.LeaveWhileCuffedWarningReason = "Leaving the game while cuffed."

DetainConfig.CuffedAnimationId = "77273751404198"
DetainConfig.CuffedAnimationPriority = Enum.AnimationPriority.Action

DetainConfig.Attributes = {
	IsCuffed = "USARF_Cuffed",
	IsEscorted = "USARF_Escorted",
	EscortOfficer = "USARF_EscortOfficer",
	CuffedBy = "USARF_CuffedBy",
	CuffedAt = "USARF_CuffedAt",
	DetainReason = "USARF_DetainReason",
	AntiExploitBypass = "USARF_AntiExploitBypass",
	DetainTeleportBypass = "USARF_DetainTeleportBypass",
}

DetainConfig.FullAccessTeamKeys = {
	President = true,
	VicePresident = true,
	FederalAdministration = true,
}

DetainConfig.LeadershipBlockedTargets = {
	President = true,
	VicePresident = true,
	FederalAdministration = true,
}

DetainConfig.IntelligenceTeamKeys = {
	CentralIntelligenceAgency = true,
	FederalBureauInvestigation = true,
	FederalDefenseService = true,
}

DetainConfig.IntelligenceBlockedTargets = {
	President = true,
	VicePresident = true,
	FederalAdministration = true,
}

DetainConfig.SecretServiceTeamKeys = {
	SecretService = true,
}

DetainConfig.SecretServiceBlockedTargets = {
	CentralIntelligenceAgency = true,
	FederalBureauInvestigation = true,
	FederalDefenseService = true,
	President = true,
	VicePresident = true,
	FederalAdministration = true,
}

DetainConfig.RulesRegulationsTeamKeys = {
	RulesRegulations = true,
}

DetainConfig.RulesRegulationsBlockedTargets = {
	SecretService = true,
	CentralIntelligenceAgency = true,
	FederalBureauInvestigation = true,
	FederalDefenseService = true,
	President = true,
	VicePresident = true,
	FederalAdministration = true,
}

DetainConfig.LeadershipRanks = {
	[6034021] = 5,
	[6075931] = 5,
	[6075925] = 5,
	[6075941] = 6,

	[6075919] = 6,
	[8068762] = 5,
	[6075911] = 5,
	[6033945] = 5,

	[6033914] = 5,
	[6033902] = 5,
	[35312413] = 5,

	[6773526] = 5,
	[6773532] = 5,
}

return DetainConfig