--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local Config = require(ReplicatedStorage.Shared.Config)
local ConfigSchema = require(ReplicatedStorage.Shared.rules.ConfigSchema)
local ConfigValidator = require(ReplicatedStorage.Shared.rules.ConfigValidator)

local describe, it, expect = JestGlobals.describe, JestGlobals.it, JestGlobals.expect

local schema = {
	type = "record",
	fields = {
		count = { type = "number", min = 1, max = 10, integer = true },
		mode = { type = "string", enum = { "A", "B" } },
		list = { type = "array", of = { type = "boolean" }, minItems = 1 },
	},
	optional = { list = true },
}

describe("ConfigValidator", function()
	it("принимает верные данные и пропускает ключи с _", function()
		local r = ConfigValidator.validate("x", schema, { count = 3, mode = "A", _comment = "что угодно" })
		expect(r.errors).toEqual({})
	end)

	it("ловит тип, диапазон, целое, enum, опечатку и пропуск поля", function()
		local r = ConfigValidator.validate("x", schema, { count = 2.5, mode = "C", cuont = 1, list = { 1 } })
		expect(#r.errors).toBe(4)
		local r2 = ConfigValidator.validate("x", schema, { mode = "A" })
		expect(r2.errors).toEqual({ "x.count: поле отсутствует" })
		local r3 = ConfigValidator.validate("x", schema, { count = 11, mode = "A" })
		expect(r3.errors).toEqual({ "x.count: 11 больше максимума 10" })
	end)

	it(
		"_TODO_DESIGN: существующие пути — предупреждения, несуществующие — ошибки",
		function()
			local r =
				ConfigValidator.validate("x", schema, { count = 1, mode = "A", _TODO_DESIGN = { "count", "nope" } })
			expect(r.todo).toEqual({ "x.count" })
			expect(r.errors).toEqual({ 'x._TODO_DESIGN: путь "nope" не найден' })
		end
	)

	it("конфиги репозитория проходят свои схемы", function()
		local r = ConfigValidator.validateAll(ConfigSchema, Config)
		expect(r.errors).toEqual({})
	end)
end)
