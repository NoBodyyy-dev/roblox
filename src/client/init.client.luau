--!strict
-- Точка входа клиента: единственный LocalScript. Контроллеры — ModuleScript в controllers/, порядок ниже.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Loader)

Loader.run(script.controllers, {
	"AdminController",
})
