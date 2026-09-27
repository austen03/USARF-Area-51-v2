return {
	Name = "doublepaycheck",
	Aliases = { "2xpaycheck", "bonuspaycheck" },
	Description = "Toggles or sets the server's 2x paycheck multiplier.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "boolean",
			Name = "Value",
			Description = "Leave blank to toggle; true/false to set.",
			Optional = true,
		},
	},
}
