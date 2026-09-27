return {
	Name = "unban",
	Aliases = { "liftban" },
	Description = "Lift a ban by userId.",
	Group = "USARF Admin",

	Args = {
		{ Type = "integer", Name = "UserId", Description = "Roblox userId to unban." },
		{ Type = "string", Name = "Reason", Description = "Unban reason."},
	},
}
