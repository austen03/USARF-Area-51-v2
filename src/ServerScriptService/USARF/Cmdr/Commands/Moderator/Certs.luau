return {
	Name = "certs",
	Aliases = { "certifications" },
	Description = "Shows a player's certifications. Certifications are granted in Discord.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Player to check." },
	},
}
