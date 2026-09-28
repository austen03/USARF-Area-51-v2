return {
	Name = "cases",
	Aliases = { "casehistory" },
	Description = "List recent cases for a player.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Target player." },
		{ Type = "integer", Name = "Page", Description = "Page number.", Optional = true, Default = 1 },
	},
}
