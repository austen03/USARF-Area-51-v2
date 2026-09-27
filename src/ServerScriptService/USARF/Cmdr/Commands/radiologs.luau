return {
	Name = "radiologs",
	Aliases = { "rlogs" },
	Description = "View recent radio message logs.",
	Group = "USARF Admin",

	Args = {
		{ Type = "string", Name = "Query", Description = "Optional username/userId/channel/message search or count.", Optional = true },
		{ Type = "number", Name = "Count", Description = "Optional amount to show.", Optional = true },
	},
}
