local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")

local USARFConfig = require(Config:WaitForChild("USARFConfig"))

local RadioConfig = USARFConfig.Radio

RadioConfig.MainGroupId = USARFConfig.Groups.Main
RadioConfig.ModGroupId = USARFConfig.Groups.Moderation

return RadioConfig