return {
	Name = "suspend",
	Aliases = { "suspension" },
	Description = "Suspend a player from facility, area, current team, or selected team.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Target player." },
		{ Type = "string", Name = "Scope", Description = "facility, civil, combative, intelligence, protection, team, or current." },
		{ Type = "string", Name = "Duration", Description = "30m, 2h, 7d, perm." },
		{ Type = "string", Name = "Reason", Description = "Suspension reason." },
		{ Type = "string", Name = "Team", Description = "Team name/key when scope is team.", Optional = true },
	},
}
