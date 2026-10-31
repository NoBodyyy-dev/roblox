--!strict
-- Все remote игры в одном месте (AGENT_PROMPT §4: «каждый remote: схема t, … rate limit»).
--   kind     — "Event" | "Unreliable" (UnreliableRemoteEvent для частых некритичных данных)
--   toServer — проверка аргументов от клиента (схема t). Нет поля — клиенту слать нельзя, сервер отбросит.
--   rate     — лимит запросов от одного игрока: { perSecond, burst }. Обязателен вместе с toServer.
-- Сервер создаёт инстансы при загрузке NetServer; клиент находит их по имени.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t) :: any

export type Definition = {
	kind: "Event" | "Unreliable",
	toServer: ((...any) -> (boolean, string?))?,
	rate: { perSecond: number, burst: number }?,
}

local MAX_ADMIN_TEXT = 200

local Remotes: { [string]: Definition } = {
	-- Клиент → сервер: текст админ-команды из чата ("/time 18")
	AdminCommand = {
		kind = "Event",
		toServer = t.tuple(function(text: any)
			if typeof(text) == "string" and #text <= MAX_ADMIN_TEXT then
				return true
			end
			return false, `строка до {MAX_ADMIN_TEXT} символов`
		end),
		rate = { perSecond = 1, burst = 5 },
	},
	-- Сервер → клиент: ответ на админ-команду
	AdminResult = { kind = "Event" },
}

return Remotes
