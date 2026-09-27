return {
	Name = "chatlogs",
	Aliases = { "clogs" },
	Description = "View recent normal Roblox chat box logs.",
	Group = "USARF Admin",

	Args = {
		{ Type = "string", Name = "Query", Description = "Optional username/userId/message search or count.", Optional = true },
		{ Type = "number", Name = "Count", Description = "Optional amount to show.", Optional = true },
	},
}
