--!strict
-- Админ-команды для тестов (AGENT_PROMPT §3 п. 10). Доступ:
--   в Studio — всем;
--   в плейсах окружений из config/admin.environments — рангу группы не ниже admin.minGroupRank;
--   иначе (публичная игра) — никому.
-- Игроку с доступом ставится атрибут IsAdmin; клиент по нему регистрирует команды чата и шлёт текст в AdminCommand.
-- Новая команда — запись в COMMANDS. Команды предметов, сезона, зомби, выживших и сброса прогресса появятся
-- вместе со своими системами.

local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminParse = require(ReplicatedStorage.Shared.rules.AdminParse)
local Config = require(ReplicatedStorage.Shared.Config)
local Place = require(ReplicatedStorage.Shared.Place)
local NetServer = require(script.Parent.Parent.net.NetServer)
local WorldClockService = require(script.Parent.WorldClockService)

type Command = {
	usage: string,
	run: (player: Player, args: { string }) -> string,
}

local AdminService = {}

local COMMANDS: { [string]: Command } = {}

COMMANDS.help = {
	usage = "/help",
	run = function()
		local lines = {}
		for _, c in COMMANDS do
			table.insert(lines, c.usage)
		end
		table.sort(lines)
		return table.concat(lines, "  ")
	end,
}

COMMANDS.time = {
	usage = "/time <0–24>",
	run = function(_player, args)
		local t = AdminParse.number(args[1], 0, 24)
		if t == nil then
			return "нужно число от 0 до 24"
		end
		WorldClockService.set(t)
		return `время {t}`
	end,
}

COMMANDS.tp = {
	usage = "/tp <x> <y> <z> | /tp <игрок>",
	run = function(player, args)
		local character = player.Character
		if character == nil then
			return "нет персонажа"
		end
		local target: Vector3? = nil
		if #args == 3 then
			local limit = 15000 -- игровая зона ±15 000 studs, AGENT_PROMPT §6
			local x = AdminParse.number(args[1], -limit, limit)
			local y = AdminParse.number(args[2], -limit, limit)
			local z = AdminParse.number(args[3], -limit, limit)
			if x and y and z then
				target = Vector3.new(x, y, z)
			end
		elseif #args == 1 then
			local other = Players:FindFirstChild(args[1])
			local root = other and other:IsA("Player") and other.Character and other.Character.PrimaryPart
			if root then
				target = root.Position + Vector3.new(0, 0, 4)
			end
		end
		if target == nil then
			return "использование: " .. COMMANDS.tp.usage
		end
		character:PivotTo(CFrame.new(target))
		return `телепорт в {math.round(target.X)}, {math.round(target.Y)}, {math.round(target.Z)}`
	end,
}

COMMANDS.config = {
	usage = "/config <файл.путь>",
	run = function(_player, args)
		local cur: any = Config
		for part in string.gmatch(args[1] or "", "[^%.]+") do
			if typeof(cur) ~= "table" then
				cur = nil
				break
			end
			cur = cur[part]
		end
		if cur == nil then
			return "нет такого значения"
		end
		return if typeof(cur) == "table" then "таблица" else `{args[1]} = {tostring(cur)}`
	end,
}

local function hasAccess(player: Player): boolean
	if Place.environment == "studio" then
		return true
	end
	if not table.find(Config.admin.environments, Place.environment) then
		return false
	end
	-- Ответ: { IsMember, Roles = { { Name, Rank } } } (документация GroupService)
	local ok, result = pcall(GroupService.GetRolesInGroupAsync, GroupService, player.UserId, Config.places.groupId)
	if not ok or typeof(result) ~= "table" or result.IsMember ~= true then
		return false
	end
	for _, role in result.Roles or {} do
		if typeof(role.Rank) == "number" and role.Rank >= Config.admin.minGroupRank then
			return true
		end
	end
	return false
end

local function onPlayer(player: Player)
	if hasAccess(player) then
		local names = {}
		for name in COMMANDS do
			table.insert(names, name)
		end
		table.sort(names)
		-- Клиент регистрирует по этим именам команды чата
		player:SetAttribute("AdminCommands", table.concat(names, ","))
		player:SetAttribute("IsAdmin", true)
	end
end

function AdminService.Start(_self)
	NetServer.on("AdminCommand", function(player, text: string)
		if player:GetAttribute("IsAdmin") ~= true then
			return
		end
		local name, args = AdminParse.split(text)
		local command = name and COMMANDS[name]
		local reply = if command then command.run(player, args) else "неизвестная команда, /help"
		NetServer.fire("AdminResult", player, reply)
	end)
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
end

return AdminService
