return {
	Name = "announce",
	Aliases = { "announcement", "broadcast", "shout", "m" },
	Description = "Send an announcement inside the current server.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "announcementScope",
			Name = "Scope",
			Description = "server, moderation, developer, event, team, facility, security",
		},
		{
			Type = "string",
			Name = "Message",
			Description = "The announcement text.",
		},
		{
			Type = "boolean",
			Name = "SystemMask",
			Description = "Show as SYSTEM if allowed.",
			Optional = true,
			Default = false,
		},
		{
			Type = "teamName",
			Name = "Team",
			Description = "Required when scope is team.",
			Optional = true,
		},
		{
			Type = "boolean",
			Name = "SendToAlerts",
			Description = "Also send to radio alerts.",
			Optional = true,
			Default = false,
		},
	},
}
