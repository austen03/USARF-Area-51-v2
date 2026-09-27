return {
	Name = "lockteam",
	Aliases = { "eventlockteam" },
	Description = "Lock or unlock a team during an active event server.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Team",
			Description = "Team name/key, list, or clear.",
		},
		{
			Type = "string",
			Name = "Action",
			Description = "lock or unlock.",
			Optional = true,
		},
	},
}
