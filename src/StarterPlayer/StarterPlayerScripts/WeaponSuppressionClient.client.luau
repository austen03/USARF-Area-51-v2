local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local Shared = USARF:WaitForChild("Shared")
local WeaponFramework = Shared:WaitForChild("WeaponFramework")

local WeaponSuppression = Remotes:WaitForChild("WeaponSuppression")
local WeaponSuppressionController = require(WeaponFramework:WaitForChild("WeaponSuppressionController"))

print("[WeaponSuppressionClient] Loaded")

WeaponSuppression.OnClientEvent:Connect(function(position, intensity)
	print("[WeaponSuppressionClient] Received suppression", intensity)
	WeaponSuppressionController.Play(position, intensity)
end)