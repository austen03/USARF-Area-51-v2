return {
	Name = "case",
	Aliases = { "viewcase" },
	Description = "View a moderation case by case ID.",
	Group = "USARF Admin",

	Args = {
		{ Type = "string", Name = "CaseId", Description = "Case ID." },
	},
}
