--!strict
-- Схемы конфигов `src/shared/config/*.json`. Ключ — имя файла без расширения.
-- Описание полей для людей — `docs/config.md`; меняешь схему — обнови и его.

local function num(min: number?, max: number?)
	return { type = "number", min = min, max = max }
end

local function int(min: number?, max: number?)
	return { type = "number", min = min, max = max, integer = true }
end

local function str(enum: { string }?)
	return { type = "string", enum = enum }
end

local function record(fields: { [string]: any }, optional: { [string]: boolean }?)
	return { type = "record", fields = fields, optional = optional }
end

local REGIONS = { "City", "Sea", "Mountains" }
local PLACES = { "Lobby", "City", "Sea", "Mountains" }
local SURFACES = { "Asphalt", "Gravel", "Dirt", "Rubble" }
-- Материалы Roblox, которые встречаются на картах; расширяй по мере надобности
local MATERIALS = {
	"Asphalt",
	"Concrete",
	"Pavement",
	"Pebble",
	"Cobblestone",
	"Slate",
	"Ground",
	"Grass",
	"LeafyGrass",
	"Mud",
	"Sand",
	"Rock",
	"Basalt",
	"Brick",
	"Sandstone",
	"Snow",
	"Ice",
	"WoodPlanks",
	"Wood",
	"Plastic",
	"SmoothPlastic",
	"Metal",
	"CorrodedMetal",
	"DiamondPlate",
}

local placeIds = { type = "map", key = str(PLACES), value = int(0) }

local environment = record({
	universeId = int(0),
	places = placeIds,
})

return {
	places = record({
		groupId = int(1),
		environments = { type = "map", key = str({ "prod", "dev" }), value = environment },
	}),

	admin = record({
		environments = { type = "array", of = str({ "prod", "dev" }) },
		minGroupRank = int(1, 255),
	}),

	regions = record({
		order = { type = "array", of = str(REGIONS), minItems = 1 },
		regions = {
			type = "map",
			key = str(REGIONS),
			value = record({ openByDefault = { type = "boolean" }, requires = str(REGIONS) }, { requires = true }),
		},
	}),

	lobby = record({
		maxPlayers = int(1, 50),
		startCountdownSeconds = num(0, 60),
		inviteTimeoutSeconds = num(5, 300),
		spawnJitterStuds = num(0, 10),
		clockTime = num(0, 24),
	}),

	world = record({
		dayLengthMinutes = num(1, 120),
		startClockTime = num(0, 24),
	}),

	survival = record({
		tickSeconds = num(0.1, 10),
		hunger = record({ max = num(1), perMinute = num(0) }),
		thirst = record({ max = num(1), perMinute = num(0), sunExtraPerMinute = num(0) }),
		warnAtPercent = num(0, 100),
	}),

	vehicles = record({
		vehicles = {
			type = "map",
			key = str(),
			value = record({
				seats = int(4, 12),
				cruiseSpeed = num(1, 300),
				cargoSlots = int(0),
				fuelCapacity = num(1),
				fuelPerMinute = num(0),
				price = int(0),
			}),
		},
	}),

	surfaces = record({
		materials = { type = "map", key = str(MATERIALS), value = str(SURFACES) },
		default = str(SURFACES),
		rubbleTag = str(),
		surfaces = {
			type = "map",
			key = str(SURFACES),
			value = record({ grip = num(0, 2), drag = num(0, 10) }),
		},
		wetGripMultiplier = num(0, 1),
	}),

	weather = record({
		events = {
			type = "map",
			key = str({ "Storm" }),
			value = record({
				chancePerRun = num(0, 1),
				warningSeconds = num(0),
				durationSeconds = num(1),
				visibilityStuds = num(10),
				gripMultiplier = num(0, 1),
				zombieHearingMultiplier = num(0, 2),
				thirstMultiplier = num(0, 2),
			}),
		},
	}),
}
