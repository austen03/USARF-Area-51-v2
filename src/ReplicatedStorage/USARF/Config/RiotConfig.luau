local RiotConfig = {}

RiotConfig.Enabled = true

RiotConfig.ProductId = 1029674008

RiotConfig.PurchaseDurationSeconds = 10 * 60
RiotConfig.PurchaseCooldownSeconds = 15 * 60
RiotConfig.AllowStacking = false

RiotConfig.AllowGoldPurchase = true
RiotConfig.GoldCost = 2500
RiotConfig.GoldPurchaseMessage = "You purchased a 10 minute riot for %s Gold."
RiotConfig.NotEnoughGoldMessage = "You need %s Gold to start a riot."

RiotConfig.MinimumStageForWeapons = 3
RiotConfig.MinimumStageForClearance = 3

RiotConfig.RiotClearanceLevel = 4

-- Door tag set to true on the Test Subject team(s) while a riot is active, and false when it ends.
-- Add it to a DoorSettings AllowedList to let rioters through, or to a DeniedList to keep them out.
RiotConfig.RiotDoorTag = "doorRiot"

RiotConfig.TestSubjectTeams = {
	["Test Subject"] = true,
}

RiotConfig.RiotWeapons = {
	"AK-47",
	"Glock 17",
}

RiotConfig.ToolsFolderName = "Tools"

RiotConfig.Stages = {
	[0] = {
		Name = "Stable",
		ShortName = "Stable",
		NotificationType = "Success",
	},

	[1] = {
		Name = "Unrest",
		ShortName = "Unrest",
		NotificationType = "Warning",
	},

	[2] = {
		Name = "Riot Warning",
		ShortName = "Riot Warning",
		NotificationType = "Warning",
	},

	[3] = {
		Name = "Active Riot",
		ShortName = "Riot",
		NotificationType = "Error",
	},

	[4] = {
		Name = "Major Riot",
		ShortName = "Major Riot",
		NotificationType = "Error",
	},
}

RiotConfig.DefaultManualDurationSeconds = 10 * 60
RiotConfig.DefaultAutomatedDurationSeconds = 10 * 60

RiotConfig.NotifyPlayers = true
RiotConfig.SendDepartmentAlerts = true
RiotConfig.PlayAnnouncement = true
RiotConfig.SetFacilityStatus = true

RiotConfig.StartMessage = "A Test Subject riot has begun. Security personnel respond immediately."
RiotConfig.EndMessage = "The Test Subject riot has ended. Remaining armed rioters will be disarmed after death."

RiotConfig.ActivePurchaseMessage = "A riot is already active."
RiotConfig.CooldownMessage = "Riot is on cooldown until %s."

return RiotConfig