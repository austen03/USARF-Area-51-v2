local ClassifiedUtilityConfig = {}

ClassifiedUtilityConfig.MainGroupId = 6033326
ClassifiedUtilityConfig.MainGroupMinimumRank = 18

ClassifiedUtilityConfig.AllowedTeams = {
	["Central Intelligence Agency"] = {
		GroupId = 6033914,
		MinimumRank = 1,
	},

	["Federal Bureau of Investigation"] = {
		GroupId = 6033902,
		MinimumRank = 1,
	},

	["Federal Defense Service"] = {
		GroupId = 35312413,
		MinimumRank = 1,
	},
}

-- These teams can use the panel, but cannot be selected as targets.
ClassifiedUtilityConfig.ProtectedTargetTeams = {
	["Central Intelligence Agency"] = true,
	["Federal Bureau of Investigation"] = true,
	["Federal Defense Service"] = true,
}

ClassifiedUtilityConfig.Keybinds = {
	ToggleUtility = Enum.KeyCode.LeftBracket,
	Spectate = Enum.KeyCode.V,
	StopSpectate = Enum.KeyCode.X,
	Blackbag = Enum.KeyCode.B,
	Mark = Enum.KeyCode.T,
	Inspect = Enum.KeyCode.P,
}

ClassifiedUtilityConfig.BlackbagRemoteName = "ClassifiedUtilityRemote"

ClassifiedUtilityConfig.GroupLabels = {
	{ GroupId = 6033326, Label = "USARF" },
	{ GroupId = 8068762, Label = "137th MP" },
	{ GroupId = 6075911, Label = "1st Spec Ops" },
	{ GroupId = 6033914, Label = "CIA" },
	{ GroupId = 6773532, Label = "DoD" },
	{ GroupId = 6075931, Label = "E&T" },
	{ GroupId = 6773540, Label = "EXTECH" },
	{ GroupId = 6033902, Label = "FBI" },
	{ GroupId = 6075925, Label = "Medical" },
	{ GroupId = 6034021, Label = "Research" },
	{ GroupId = 6075941, Label = "R&R" },
	{ GroupId = 6033945, Label = "Secret Service" },
	{ GroupId = 6773526, Label = "USAF" },
	{ GroupId = 6075919, Label = "108th" },
	{ GroupId = 35312413, Label = "FDS" },
}

return ClassifiedUtilityConfig