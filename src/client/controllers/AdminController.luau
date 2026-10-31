--!strict
-- Админ-команды в чате. Сервер ставит игроку с доступом атрибуты IsAdmin и AdminCommands ("help,time,…");
-- контроллер регистрирует локальные TextChatCommand и отправляет текст команды серверу. Право проверяет сервер.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local NetClient = require(script.Parent.Parent.net.NetClient)

local AdminController = {}

local function systemMessage(text: string)
	local channels = TextChatService:FindFirstChild("TextChannels")
	local general = channels and channels:FindFirstChild("RBXGeneral")
	if general and general:IsA("TextChannel") then
		general:DisplaySystemMessage("[admin] " .. text)
	else
		print("[admin] " .. text)
	end
end

local function register(names: string)
	local folder = Instance.new("Folder")
	folder.Name = "AdminCommands"
	for name in string.gmatch(names, "[^,]+") do
		local command = Instance.new("TextChatCommand")
		command.Name = "Admin_" .. name
		command.PrimaryAlias = "/" .. name
		command.Triggered:Connect(function(_source, text)
			NetClient.fire("AdminCommand", text)
		end)
		command.Parent = folder
	end
	folder.Parent = TextChatService
end

function AdminController.Start(_self)
	local player = Players.LocalPlayer
	NetClient.on("AdminResult", systemMessage)
	local function check()
		local names = player:GetAttribute("AdminCommands")
		if player:GetAttribute("IsAdmin") == true and typeof(names) == "string" then
			if TextChatService:FindFirstChild("AdminCommands") == nil then
				register(names)
			end
		end
	end
	player:GetAttributeChangedSignal("IsAdmin"):Connect(check)
	check()
end

return AdminController
