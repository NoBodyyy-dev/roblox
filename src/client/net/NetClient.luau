--!strict
-- Клиентская сторона net-слоя. Remote ищутся по имени в ReplicatedStorage.Remotes с таймаутом (AGENT_PROMPT §6:
-- никаких бесконечных WaitForChild).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.net.Remotes)

local TIMEOUT = 15

local NetClient = {}

local folder: Instance? = nil

local function get(name: string): any
	if Remotes[name] == nil then
		error(`NetClient: нет remote {name} в Shared.net.Remotes`, 3)
	end
	if folder == nil then
		folder = ReplicatedStorage:WaitForChild("Remotes", TIMEOUT)
		if folder == nil then
			error("NetClient: сервер не создал ReplicatedStorage.Remotes", 3)
		end
	end
	local remote = (folder :: Instance):WaitForChild(name, TIMEOUT)
	if remote == nil then
		error(`NetClient: remote {name} не найден`, 3)
	end
	return remote
end

function NetClient.fire(name: string, ...: any)
	if Remotes[name].toServer == nil then
		error(`NetClient.fire: {name} только для сервера → клиента`, 2)
	end
	get(name):FireServer(...)
end

function NetClient.on(name: string, handler: (...any) -> ()): RBXScriptConnection
	return get(name).OnClientEvent:Connect(handler)
end

return NetClient
