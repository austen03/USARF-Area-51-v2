return {
	Name = "logs",
	Aliases = { "adminlogs", "cmdrlogs" },
	Description = "View recent admin/Cmdr command logs.",
	Group = "USARF Admin",

	Args = {
		{ Type = "string", Name = "Query", Description = "Optional username/userId/caseId/command search or count.", Optional = true },
		{ Type = "number", Name = "Count", Description = "Optional amount to show.", Optional = true },
	},
}
