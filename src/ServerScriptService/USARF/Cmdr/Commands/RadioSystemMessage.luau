return {
	Name = "radiosystemmessage",
	Aliases = { "radio", "rsm" },
	Description = "Send a SYSTEM radio line to one channel or all.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Text",
			Description = "Message to transmit.",
		},
		{
			Type = "radioChannel",
			Name = "Channel",
			Description = "Default: all channels.",
			Optional = true,
			Default = "all",
		},
	},
}
