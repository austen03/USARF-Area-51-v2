return {
	Name = "rank",
	Aliases = { "overriderank" },
	Description = "Set or clear a team-specific nametag rank override.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "Player whose nametag rank should be overridden.",
		},
		{
			Type = "string",
			Name = "Team",
			Description = "Team name, TeamConfig key, or current.",
		},
		{
			Type = "string",
			Name = "Action",
			Description = "set or clear.",
		},
		{
			Type = "string",
			Name = "RankText",
			Description = "Displayed rank text when using set.",
			Optional = true,
		},
	},
}
