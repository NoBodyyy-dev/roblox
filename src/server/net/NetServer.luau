--!strict
-- Серверная сторона net-слоя. Создаёт все remote из `Shared.net.Remotes` в ReplicatedStorage.Remotes.
-- Каждое сообщение от клиента проходит rate limit и схему t до обработчика; нарушения логируются и отбрасываются.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.net.Remotes)
local RateLimiter = require(ReplicatedStorage.Shared.rules.RateLimiter)

local NetServer = {}

local folder = Instance.new("Folder")
folder.Name = "Remotes"

local instances: { [string]: Instance } = {}
local limiters: { [string]: RateLimiter.RateLimiter } = {}

for name, def in Remotes do
	local remote: Instance = if def.kind == "Unreliable"
		then Instance.new("UnreliableRemoteEvent")
		else Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	instances[name] = remote
	if def.toServer then
		assert(def.rate, `Remotes.{name}: у remote с toServer обязателен rate`)
		limiters[name] = RateLimiter.new(def.rate.perSecond, def.rate.burst)
	end
end
folder.Parent = ReplicatedStorage

Players.PlayerRemoving:Connect(function(player)
	for _, limiter in limiters do
		limiter:forget(player)
	end
end)

local function get(name: string): Instance
	local remote = instances[name]
	if not remote then
		error(`NetServer: нет remote {name} в Shared.net.Remotes`, 3)
	end
	return remote
end

-- Обработчик сообщений клиента. Аргументы уже проверены схемой `toServer`.
function NetServer.on(name: string, handler: (player: Player, ...any) -> ())
	local def = Remotes[name]
	local check = def and def.toServer
	if not check then
		error(`NetServer.on: у {name} нет toServer — клиенту слать нельзя`, 2)
	end
	local limiter = limiters[name]
	local remote = get(name) :: any
	remote.OnServerEvent:Connect(function(player: Player, ...)
		if not limiter:allow(player, os.clock()) then
			return
		end
		local ok, why = check(...)
		if not ok then
			warn(`NetServer: {player.Name} → {name}: неверные аргументы ({why})`)
			return
		end
		handler(player, ...)
	end)
end

function NetServer.fire(name: string, player: Player, ...: any)
	(get(name) :: any):FireClient(player, ...)
end

function NetServer.fireAll(name: string, ...: any)
	(get(name) :: any):FireAllClients(...)
end

return NetServer
