return {
	Name = "clanremove",
	Aliases = {},
	Description = "Removes a player from their clan (online or offline). A removed Leader is replaced by the highest-ranked member.",
	Group = "USARF Admin",
	Args = {
		{ Type = "playerId", Name = "Player", Description = "The player to remove (name or user ID)." },
	},
}
