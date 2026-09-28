return {
	Name = "weapontest";
	Aliases = { "wtest" };
	Description = "Spawn or remove a weapon testing dummy.";
	Group = "USARF Admin";

	Args = {
		{
			Type = "string";
			Name = "mode";
			Description = "spawn, clear";
			Optional = true;
			Default = "spawn";
		}
	};
}
