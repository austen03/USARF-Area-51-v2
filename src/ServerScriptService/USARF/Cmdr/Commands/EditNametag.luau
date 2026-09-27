return {
	Name = "editnametag",
	Aliases = { "nametagedit" },
	Description = "Edit a player's nametag name, rank, and color.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Player to edit." },
		
		{ Type = "string", Name = "DisplayedName", Description = "Name, . to skip, or clear.", Optional = true, Default = "." },
		
		{ Type = "string", Name = "DisplayedRank", Description = "Rank or . to skip.", Optional = true, Default = "." },
		
		{ Type = "color3", Name = "Color", Description = "Optional nametag color.", Optional = true },
	},
}
