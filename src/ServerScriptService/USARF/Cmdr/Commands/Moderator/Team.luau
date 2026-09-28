return {
	Name = "team";
	Aliases = { "setteam" };
	Description = "Moves player(s) to a selected team.";
	Group = "USARF Admin";

	Args = {
		{
			Type = "players";
			Name = "players";
			Description = "Player(s) to move.";
		},
		{
			Type = "teamName";
			Name = "team";
			Description = "Team to assign.";
		},
	};
}
