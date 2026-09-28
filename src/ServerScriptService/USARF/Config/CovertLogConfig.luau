-- Where covert names are recorded whenever a player goes covert or renames.
-- Each entry goes to the Discord bot (posted in the covert name logs channel)
-- and, as a backup, to the Google Sheet.

local CovertLogConfig = {}

-- Bot event (DiscordBotBridge.SendEvent) the bot posts to the covert name logs channel.
CovertLogConfig.BotEventType = "covert.name"

-- Apps Script web app that appends each entry as a row on the "covertnames" tab (doPost).
CovertLogConfig.SheetUrl =
	"https://script.google.com/macros/s/AKfycbxLBXO-xrQSH-lkl_zsyMKtvv2pXHivaXR_ikCHJJhaexuVk1gq0Dljy6OF3lJD2o0u0g/exec?sheet=covertnames"

-- Roblox Secrets Store secret sent as &token= so only the game can write rows.
-- Optional: without it, rows are sent with no token.
CovertLogConfig.SheetTokenSecretName = "USARFSheetWriteToken"

CovertLogConfig.SheetMaxAttempts = 3

return CovertLogConfig
