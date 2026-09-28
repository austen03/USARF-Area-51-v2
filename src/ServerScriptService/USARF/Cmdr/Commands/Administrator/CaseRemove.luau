return {
	Name = "caseremove",
	Aliases = { "casevoid", "voidcase", "removecase" },
	Description = "Void a moderation case by case ID.",
	Group = "USARF Admin",

	Args = {
		{ Type = "string", Name = "CaseId", Description = "Case ID to void." },
		{ Type = "string", Name = "Reason", Description = "Void reason." },
	},
}
