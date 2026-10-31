--!strict
-- Точка входа сервера: единственный Script. Сервисы — ModuleScript в services/, порядок ниже.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Loader)

Loader.run(script.services, {
	"ConfigService", -- первым: остальные читают уже проверенные конфиги
	"WorldClockService",
	"AdminService",
})
