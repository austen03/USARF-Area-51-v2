return {
	Name = "unsuspend",
	Aliases = { "unsuspension", "revsuspension", "revokesuspension" },
	Description = "Remove an active suspension by case ID.",
	Group = "USARF Admin",

	Args = {
		{ Type = "string", Name = "CaseId", Description = "Suspension case ID. Example: USARF-S-A1B2C3D4" },
	},
}
