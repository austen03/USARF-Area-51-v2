return {
	Name = "kick",
	Aliases = {},
	Description = "Kick a player with a reason.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Player to kick." },
		{ Type = "string", Name = "Reason", Description = "Kick reason." },
	},
}
