--!strict
-- Token bucket на ключ (обычно игрок). Чистая логика: время передаётся снаружи.
-- `perSecond` — скорость пополнения, `burst` — сколько запросов подряд можно сделать с полного бака.

export type RateLimiter = {
	perSecond: number,
	burst: number,
	buckets: { [any]: { tokens: number, at: number } },
	allow: (self: RateLimiter, key: any, now: number) -> boolean,
	forget: (self: RateLimiter, key: any) -> (),
}

local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(perSecond: number, burst: number): RateLimiter
	assert(perSecond > 0 and burst >= 1, "RateLimiter: perSecond > 0 и burst >= 1")
	return (setmetatable({ perSecond = perSecond, burst = burst, buckets = {} }, RateLimiter) :: any) :: RateLimiter
end

function RateLimiter.allow(self: RateLimiter, key: any, now: number): boolean
	local b = self.buckets[key]
	if b == nil then
		b = { tokens = self.burst, at = now }
		self.buckets[key] = b
	else
		b.tokens = math.min(self.burst, b.tokens + math.max(0, now - b.at) * self.perSecond)
		b.at = now
	end
	if b.tokens >= 1 then
		b.tokens -= 1
		return true
	end
	return false
end

function RateLimiter.forget(self: RateLimiter, key: any)
	self.buckets[key] = nil
end

return RateLimiter
