--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local AdminParse = require(ReplicatedStorage.Shared.rules.AdminParse)

local describe, it, expect = JestGlobals.describe, JestGlobals.it, JestGlobals.expect

describe("AdminParse", function()
	it("разбирает команду и аргументы", function()
		local name, args = AdminParse.split("/TP  1 2.5   -3")
		expect(name).toBe("tp")
		expect(args).toEqual({ "1", "2.5", "-3" })
	end)

	it("пустой текст и одиночный слэш — не команда", function()
		expect((AdminParse.split("   "))).toBeNil()
		expect((AdminParse.split("/"))).toBeNil()
	end)

	it("number проверяет диапазон и мусор", function()
		expect(AdminParse.number("12", 0, 24)).toBe(12)
		expect(AdminParse.number("25", 0, 24)).toBeNil()
		expect(AdminParse.number("abc", 0, 24)).toBeNil()
		expect(AdminParse.number("nan", 0, 24)).toBeNil()
		expect(AdminParse.number(nil, 0, 24)).toBeNil()
	end)
end)
