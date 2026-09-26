local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")

local USARFConfig = require(Config:WaitForChild("USARFConfig"))

return {
	Categories = USARFConfig.Categories,
	Teams = USARFConfig.Teams,
}