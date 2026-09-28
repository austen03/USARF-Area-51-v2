return {
	Name = "ban",
	Aliases = { "gameban" },
	Description = "Ban a player for a duration or permanent.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Player to ban." },
		{ Type = "string", Name = "Duration", Description = "30m, 2h, 7d, perm." },
		{ Type = "string", Name = "Reason", Description = "Ban reason." },
	},
}
