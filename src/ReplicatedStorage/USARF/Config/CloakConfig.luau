local CloakConfig = {}

CloakConfig.MainGroupId = 6033326
CloakConfig.MainGroupMinimumRank = 18

CloakConfig.AllowedTeams = {
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

CloakConfig.RemoteName = "CloakRemote"

CloakConfig.ToggleKey = Enum.KeyCode.Q
CloakConfig.CooldownSeconds = 2

CloakConfig.CloakedWalkSpeed = 20
CloakConfig.DefaultWalkSpeed = 16

CloakConfig.VisibleToAuthorizedTransparency = 0.78
CloakConfig.FullyInvisibleTransparency = 1

CloakConfig.HideNameTags = true
CloakConfig.AddInvisibleForceField = true

return CloakConfig