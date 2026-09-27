return {
	Name = "breachee",
	Aliases = { "ee", "breachanomaly", "breachentity" },
	Description = "Breach an EE/anomaly by model name.",
	Group = "USARF Admin",

	Args = {
		{ Type = "string", Name = "EntityName", Description = "Example: EE-04A, EE-01, EE-05." },
	},
}
