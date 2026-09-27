return {
	Name = "mutevoice",
	Aliases = { "vcmute", "voiceban" },
	Description = "Mute or unmute a player's in-experience Roblox voice input.",
	Group = "USARF Admin",
	Args = {
		{ Type = "player", Name = "Player", Description = "Player whose voice input will be changed." },
		{ Type = "string", Name = "Mode", Description = "on, off, toggle, or status.", Optional = true, Default = "toggle" },
	},
}
