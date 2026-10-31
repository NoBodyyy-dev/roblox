--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local RateLimiter = require(ReplicatedStorage.Shared.rules.RateLimiter)

local describe, it, expect = JestGlobals.describe, JestGlobals.it, JestGlobals.expect

describe("RateLimiter", function()
	it("пускает burst запросов подряд, потом отказывает", function()
		local r = RateLimiter.new(1, 3)
		expect(r:allow("p", 0)).toBe(true)
		expect(r:allow("p", 0)).toBe(true)
		expect(r:allow("p", 0)).toBe(true)
		expect(r:allow("p", 0)).toBe(false)
	end)

	it("пополняет бак со скоростью perSecond, не выше burst", function()
		local r = RateLimiter.new(2, 2)
		r:allow("p", 0)
		r:allow("p", 0)
		expect(r:allow("p", 0.4)).toBe(false)
		expect(r:allow("p", 0.6)).toBe(true)
		expect(r:allow("p", 100)).toBe(true)
		expect(r:allow("p", 100)).toBe(true)
		expect(r:allow("p", 100)).toBe(false)
	end)

	it("ключи независимы, forget сбрасывает бак", function()
		local r = RateLimiter.new(1, 1)
		expect(r:allow("a", 0)).toBe(true)
		expect(r:allow("b", 0)).toBe(true)
		expect(r:allow("a", 0)).toBe(false)
		r:forget("a")
		expect(r:allow("a", 0)).toBe(true)
	end)
end)
