--!strict
-- Проверяет все конфиги по схеме при старте сервера. Ошибка в конфиге останавливает загрузку сервисов:
-- лучше упасть сразу в Studio, чем играть с неверным числом.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ConfigSchema = require(ReplicatedStorage.Shared.rules.ConfigSchema)
local ConfigValidator = require(ReplicatedStorage.Shared.rules.ConfigValidator)

local ConfigService = {}

function ConfigService.Init(_self)
	local result = ConfigValidator.validateAll(ConfigSchema, Config)
	if #result.errors > 0 then
		error("Конфиги не прошли проверку:\n  " .. table.concat(result.errors, "\n  "), 0)
	end
	if #result.todo > 0 then
		print(`Config: OK, временных значений TODO_DESIGN: {#result.todo}`)
	end
end

return ConfigService
