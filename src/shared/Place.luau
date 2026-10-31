--!strict
-- Какой это плейс и в каком окружении он запущен.
--   role        — "Lobby" | "City" | "Sea" | "Mountains": атрибут Workspace.PlaceRole из places/<Role>.project.json
--   environment — "prod" | "dev" по PlaceId из config/places.json; "studio" в Studio; "unknown" — плейс не из списка

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

export type Role = "Lobby" | "City" | "Sea" | "Mountains"
export type Environment = "prod" | "dev" | "studio" | "unknown"

local ROLES = { "Lobby", "City", "Sea", "Mountains" }

local role = workspace:GetAttribute("PlaceRole")
if not table.find(ROLES, role) then
	local got = tostring(role)
	error(
		`Place: у Workspace нет атрибута PlaceRole из {table.concat(ROLES, "/")} (получено {got})`
	)
end

local environment: Environment = "unknown"
if RunService:IsStudio() then
	environment = "studio"
else
	for env, data in Config.places.environments do
		for _, id in data.places do
			if id ~= 0 and id == game.PlaceId then
				environment = env
			end
		end
	end
end

return {
	role = role :: Role,
	environment = environment,
}
