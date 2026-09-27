return {
	Name = "code1",
	Aliases = { "codeone" },
	Description = "Trigger Code 1 announcement.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Message",
			Description = "Code 1 message.",
			Optional = true,
			Default = "Code 1 has been declared.",
		},
	},
}
