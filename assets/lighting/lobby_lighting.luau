--!strict
-- Пресет мрачного освещения лобби (предложение Художника; применяет Разработчик в плейсе Lobby).
-- Сумерки над заброшенным городом: низкое солнце, холодная дымка, приглушённые цвета, тёплый свет костра
-- выделяется на общем фоне. Запуск: Command Bar / MCP execute_luau в Edit. Старые эффекты с теми же именами заменяются.

local Lighting = game:GetService("Lighting")

local props = {
	ClockTime = 18.9,
	GeographicLatitude = 35,
	Brightness = 1.4,
	ExposureCompensation = 0.15,
	Ambient = Color3.fromRGB(60, 62, 72),
	OutdoorAmbient = Color3.fromRGB(108, 110, 124),
	ColorShift_Top = Color3.fromRGB(255, 196, 160),
	ColorShift_Bottom = Color3.fromRGB(40, 44, 60),
	EnvironmentDiffuseScale = 0.35,
	EnvironmentSpecularScale = 0.15,
	GlobalShadows = true,
}
for k, v in props do
	(Lighting :: any)[k] = v
end

local function effect(class: string, name: string, values: { [string]: any })
	local old = Lighting:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local e = Instance.new(class)
	e.Name = name
	for k, v in values do
		(e :: any)[k] = v
	end
	e.Parent = Lighting
end

effect("Atmosphere", "GloomAtmosphere", {
	Density = 0.42,
	Offset = 0.12,
	Color = Color3.fromRGB(150, 146, 142),
	Decay = Color3.fromRGB(92, 82, 76),
	Glare = 0.1,
	Haze = 2.2,
})
effect("ColorCorrectionEffect", "GloomGrade", {
	Saturation = -0.32,
	Contrast = 0.14,
	Brightness = -0.03,
	TintColor = Color3.fromRGB(232, 226, 216),
})
effect("BloomEffect", "GloomBloom", { Intensity = 0.6, Size = 24, Threshold = 1.5 })

return "lobby lighting applied"
