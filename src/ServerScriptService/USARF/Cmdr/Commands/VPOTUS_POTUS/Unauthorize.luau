return {
	Name = "unauthorize",
	Aliases = { "unauth", "clearauth" },
	Description = "Clears a Test Subject authorization.",
	Group = "VPOTUS_POTUS",
	Args = {
		{
			Type = "player",
			Name = "target",
			Description = "The Test Subject to clear authorization from.",
		},
	},
}
