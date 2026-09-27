return {
	Name = "globalannounce",
	Aliases = { "gannounce", "globalannouncement" },
	Description = "Send an announcement to every active USARF server.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "globalAnnouncementScope",
			Name = "Scope",
			Description = "Global.",
		},
		{
			Type = "string",
			Name = "Message",
			Description = "The global announcement text.",
		},
		{
			Type = "boolean",
			Name = "SystemMask",
			Description = "Show as SYSTEM if allowed.",
			Optional = true,
			Default = false,
		},
		{
			Type = "boolean",
			Name = "SendToAlerts",
			Description = "Also send to radio alerts in every server.",
			Optional = true,
			Default = false,
		},
	},
}
