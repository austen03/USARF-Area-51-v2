local ScramblerConfig = {}

ScramblerConfig.MainGroupId = 6033326
ScramblerConfig.MainGroupMinimumRank = 18

ScramblerConfig.AllowedTeams = {
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

ScramblerConfig.RemoteName = "ScramblerRemote"

ScramblerConfig.ToggleKey = Enum.KeyCode.R
ScramblerConfig.CooldownSeconds = 1.5

ScramblerConfig.BillboardName = "USARF_ScramblerBillboard"
ScramblerConfig.CharacterTag = "USARF_Scrambled"

ScramblerConfig.HideNameTags = true

ScramblerConfig.BillboardTextTop = "████████"
ScramblerConfig.BillboardTextMain = "REDACTED"
ScramblerConfig.BillboardTextBottom = "CLASSIFIED PERSONNEL"

return ScramblerConfig