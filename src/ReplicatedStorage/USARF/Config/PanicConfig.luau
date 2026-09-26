local PanicConfig = {}

PanicConfig.RemoteName = "PanicRemote"
PanicConfig.ToggleKey = Enum.KeyCode.P

PanicConfig.MainGroupId = 6033326
PanicConfig.SecretServiceGroupId = 6033945

PanicConfig.CooldownSeconds = 45
PanicConfig.LocationFolderName = "ProtectionLocations"
PanicConfig.UnknownLocationName = "Unknown Location"

PanicConfig.BlockedTeamNames = {
	["Test Subject"] = true,
	["Private Military Company"] = true,
	["PMC"] = true,
}

PanicConfig.ReceiverRules = {
	SecretServiceTeamNames = {
		["Secret Service"] = true,
	},

	SecretServiceMinimumRank = 1,
	LeadershipMainMinimumRank = 18,
}

PanicConfig.VIPRules = {
	{
		Label = "President",
		TeamNames = {
			["President of the United States"] = true,
			["President"] = true,
		},
		Priority = 100,
	},

	{
		Label = "Vice President",
		TeamNames = {
			["Vice President of the United States"] = true,
			["Vice President"] = true,
		},
		Priority = 90,
	},
}

return PanicConfig