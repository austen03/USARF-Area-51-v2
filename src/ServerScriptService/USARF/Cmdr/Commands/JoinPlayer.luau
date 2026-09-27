return {
	Name = "joinplayer",
	Aliases = { "followplayer", "joinuser" },
	Description = "Join a player's public server in this experience.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Username",
			Description = "Roblox username to join.",
		},
	},
}
