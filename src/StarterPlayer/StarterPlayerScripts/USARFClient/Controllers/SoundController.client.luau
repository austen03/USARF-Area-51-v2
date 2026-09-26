local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local SoundsFolder = USARF:WaitForChild("Assets"):WaitForChild("Sounds")

local SoundController = {}

local function getSound(soundName)
	local sound = SoundsFolder:FindFirstChild(soundName)

	if not sound or not sound:IsA("Sound") then
		return nil
	end

	return sound
end

function SoundController.Play(soundName, settingKey)
	local settings = _G.USARFSettings

	if settingKey and settings and settings[settingKey] == false then
		return
	end

	local sound = getSound(soundName)
	if not sound then
		return
	end

	local clone = sound:Clone()
	clone.Parent = SoundService
	clone:Play()

	clone.Ended:Connect(function()
		clone:Destroy()
	end)
end

_G.USARFPlaySound = SoundController.Play

print("USARF SoundController initialized")

return SoundController