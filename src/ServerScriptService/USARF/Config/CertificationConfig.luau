-- Certifications (e.g. "Covert") are granted in Discord through the USARF bot.
-- The Google Sheet is only a fallback for when the bot can't be reached.

local CertificationConfig = {}

-- Bot endpoint, relative to DiscordBotBridge's base URL. The user id is appended:
-- GET /certifications/<userId> -> { "certifications": ["Covert", ...] }
CertificationConfig.BotPath = "/certifications/"

-- Apps Script web app serving the "certifications" tab: one row per player with
-- a RobloxUserId column and a Certifications column ("Covert, ...").
CertificationConfig.SheetUrl =
	"https://script.google.com/macros/s/AKfycbxLBXO-xrQSH-lkl_zsyMKtvv2pXHivaXR_ikCHJJhaexuVk1gq0Dljy6OF3lJD2o0u0g/exec?sheet=certifications"

-- How long a player's certifications are trusted before they are fetched again.
CertificationConfig.RefreshSeconds = 60

-- How long the whole fallback sheet is cached.
CertificationConfig.SheetCacheSeconds = 120

return CertificationConfig
