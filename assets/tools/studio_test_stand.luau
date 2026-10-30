-- TEST_01 §8: нейтральный стенд для всех скриншотов.
-- Запуск: execute_luau в режиме редактирования (до Play). Повторный запуск безопасен.
-- Только для ТЕСТОВОГО плейса: свойства Lighting не восстанавливаются, эффекты уезжают в ServerStorage.TestStand_Stash.

local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

-- true: TestPaletteBox и TestUVBleed получают TextureID = T_Palette_Main (из атрибута Tex_T_Palette_Main).
-- Для тестов C и D ставь false, иначе стенд вернёт Main поверх Worn/Gold/Arctic.
local SET_MAIN_TEXTURE = true

local GRAY = Color3.fromRGB(128, 128, 128)

Lighting.GlobalShadows = false
Lighting.ClockTime = 12
Lighting.Brightness = 2
Lighting.Ambient = GRAY
Lighting.OutdoorAmbient = GRAY
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.ExposureCompensation = 0

-- Atmosphere, Sky и пост-эффекты (Bloom, ColorCorrection, SunRays, DepthOfField, Blur — все PostEffect)
local stash = ServerStorage:FindFirstChild("TestStand_Stash")
if not stash then
	stash = Instance.new("Folder")
	stash.Name = "TestStand_Stash"
	stash.Parent = ServerStorage
end
local parked = {}
local function park(container)
	for _, inst in container:GetChildren() do
		if inst:IsA("Atmosphere") or inst:IsA("Sky") or inst:IsA("PostEffect") then
			inst.Parent = stash
			table.insert(parked, inst.ClassName)
		end
	end
end
park(Lighting)
park(workspace.CurrentCamera)

local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
if clouds then
	clouds.Enabled = false
end

-- Серая опорная плоскость (2048 — максимум размера Part; хватает для камеры на 1000 studs)
local ground = workspace:FindFirstChild("TestStand_Ground")
if not ground then
	ground = Instance.new("Part")
	ground.Name = "TestStand_Ground"
	ground.Parent = workspace
end
ground.Anchored = true
ground.Size = Vector3.new(2048, 1, 2048)
ground.CFrame = CFrame.new(0, -0.5, 0)
ground.Material = Enum.Material.SmoothPlastic
ground.Color = GRAY
ground.Transparency = 0

-- Тестовые меши: SmoothPlastic, белый. Папку/модель теста E (TestE) не трогаем — там цвет задаётся тестом.
local touched = {}
local mainTex = workspace:GetAttribute("Tex_T_Palette_Main")
local function prep(inst, texture)
	for _, d in { inst, unpack(inst:GetDescendants()) } do
		if d:IsA("MeshPart") then
			d.Material = Enum.Material.SmoothPlastic
			d.Color = Color3.new(1, 1, 1)
			d.Anchored = true
			if texture then
				d.TextureID = texture
			end
			table.insert(touched, d:GetFullName())
		end
	end
end
for _, name in { "TestPaletteBox", "TestUVBleed", "TestSkinBox" } do
	local inst = workspace:FindFirstChild(name)
	if inst then
		prep(inst, SET_MAIN_TEXTURE and name ~= "TestSkinBox" and mainTex or nil)
	end
end
if SET_MAIN_TEXTURE and not mainTex then
	warn("[stand] нет атрибута Tex_T_Palette_Main — сначала studio_tests/00_set_texture_ids.luau")
end

print(("[stand] OK. Убрано: %s. Clouds: %s. Меши: %s"):format(
	#parked > 0 and table.concat(parked, ", ") or "ничего",
	clouds and "выключены" or "нет",
	#touched > 0 and table.concat(touched, ", ") or "НЕ НАЙДЕНЫ (импортируй OBJ)"
))
