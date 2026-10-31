--!strict
-- Офлайн-проверка конфигов: `lune run validate-config`. Та же схема и валидатор, что и на сервере при старте.
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")

local ConfigSchema = require("../src/shared/rules/ConfigSchema")
local ConfigValidator = require("../src/shared/rules/ConfigValidator")

local DIR = "src/shared/config"

local configs = {}
for _, file in fs.readDir(DIR) do
	local name = string.match(file, "^(.+)%.json$")
	if name then
		local ok, data = pcall(serde.decode, "json" :: any, fs.readFile(`{DIR}/{file}`))
		if not ok then
			print(`ОШИБКА {file}: невалидный JSON: {data}`)
			process.exit(1)
		end
		configs[name] = data
	end
end

local result = ConfigValidator.validateAll(ConfigSchema, configs)
for _, e in result.errors do
	print("ОШИБКА " .. e)
end
print(
	`Конфигов: {#fs.readDir(DIR)}, ошибок: {#result.errors}, временных значений TODO_DESIGN: {#result.todo}`
)
process.exit(#result.errors == 0 and 0 or 1)
