return {
	Name = "teamkill",
	Aliases = { "friendlyfire", "ff" },
	Description = "Set or inspect the current server combat restrictions.",
	Group = "USARF Admin",
	Args = {
		{ Type = "teamKillMode", Name = "Mode", Description = "default, unrestricted, or status.", Optional = true, Default = "status" },
	},
}
