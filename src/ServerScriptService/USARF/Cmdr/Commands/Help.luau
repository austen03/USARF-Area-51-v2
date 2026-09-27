return {
	Name = "help",
	Aliases = { "commands", "cmds" },
	Description = "Shows the USARF administration terminal command list.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Command",
			Description = "Optional command name for detailed help.",
			Optional = true,
		},
	},
}
