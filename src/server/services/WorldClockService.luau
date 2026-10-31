--!strict
-- Время суток. Фаза 0: ставит стартовое время из конфига (лобби — lobby.clockTime, регион — world.startClockTime).
-- Цикл дня и ночи и сохранение времени в экспедицию — фаза 8.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Place = require(ReplicatedStorage.Shared.Place)

local WorldClockService = {}

function WorldClockService.Start(_self)
	Lighting.ClockTime = if Place.role == "Lobby" then Config.lobby.clockTime else Config.world.startClockTime
end

-- Для админ-команды /time
function WorldClockService.set(clockTime: number)
	Lighting.ClockTime = clockTime
end

return WorldClockService
