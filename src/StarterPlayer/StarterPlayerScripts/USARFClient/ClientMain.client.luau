local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local GetMenuPayload = Remotes:WaitForChild("GetMenuPayload")
local SelectTeam = Remotes:WaitForChild("SelectTeam")
local ReturnToMenu = Remotes:WaitForChild("ReturnToMenu")

local ClientMain = {}

function ClientMain.LoadMenuData()
	local success, result = pcall(function()
		return GetMenuPayload:InvokeServer()
	end)

	if not success then
		warn("[ClientMain] Failed to get menu payload:", result)
		return nil
	end

	return result
end

function ClientMain.SelectTeam(teamKey)
	local success, result = pcall(function()
		return SelectTeam:InvokeServer(teamKey)
	end)

	if not success then
		warn("[ClientMain] Failed selecting team:", result)

		return {
			success = false,
			message = "Failed to communicate with server",
		}
	end

	return result
end

function ClientMain.ReturnToMenu()
	local success, result = pcall(function()
		return ReturnToMenu:InvokeServer()
	end)

	if not success then
		warn("[ClientMain] Failed returning to menu:", result)

		return {
			success = false,
			message = "Failed to communicate with server",
		}
	end

	return result
end

function ClientMain.Start()
	print("[USARF] Client loaded.")

	local payload = ClientMain.LoadMenuData()

	if payload then
		print("[USARF] Categories:", #payload.categories)
	end
end

ClientMain.Start()

return ClientMain