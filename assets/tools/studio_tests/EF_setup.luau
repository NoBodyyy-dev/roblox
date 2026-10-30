-- TEST_01, тесты E (краска + скин) и F (наклейка). Строит модели TestE и TestF из TestSkinBox (полная UV на гранях).
-- Запуск: execute_luau в режиме редактирования. Для E запускай трижды: COLOR = красный, синий, белый.
-- Ошибки установки свойств ловятся и печатаются: это тоже результат теста.

local COLOR = Color3.fromRGB(255, 0, 0) -- красный; синий (0, 0, 255); белый (255, 255, 255)
local Z = 30 -- E и F стоят в ряд на этой линии, подальше от остальных тестов

local function tex(name)
	local v = workspace:GetAttribute("Tex_" .. name)
	assert(v, "нет Tex_" .. name .. ": сначала 00_set_texture_ids.luau")
	return v
end

local function sourcePart()
	local src = workspace:FindFirstChild("TestSkinBox", true)
	assert(src, "TestSkinBox не найден: импортируй assets/source/test/TestSkinBox.obj")
	if src:IsA("MeshPart") then
		return src
	end
	local parts = {}
	for _, d in src:GetDescendants() do
		if d:IsA("MeshPart") then
			table.insert(parts, d)
		end
	end
	assert(#parts == 1, ("в TestSkinBox %d MeshPart, нужен ровно 1"):format(#parts))
	return parts[1]
end

local base = sourcePart()
local results = {}
local function try(label, fn)
	local ok, err = pcall(fn)
	local line = label .. ": " .. (ok and "OK" or ("ОШИБКА " .. tostring(err)))
	table.insert(results, line)
end

local function freshModel(name)
	local old = workspace:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = workspace
	return m
end

local function clonePart(parent, name, pos, size)
	local p = base:Clone()
	p:ClearAllChildren()
	p.Name = name
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TextureID = ""
	p.Color = Color3.new(1, 1, 1)
	if size then
		p.Size = size
	end
	p.CFrame = CFrame.new(pos + Vector3.new(0, p.Size.Y / 2, 0))
	p.Parent = parent
	return p
end

-- E1: TextureID = скин, меняем MeshPart.Color
local e = freshModel("TestE")
local e1 = clonePart(e, "E1_TextureID", Vector3.new(-8, 0, Z))
try("E1 TextureID", function()
	e1.TextureID = tex("T_VehicleSkin_Test")
end)
e1.Color = COLOR

-- E2: SurfaceAppearance Overlay, меняем MeshPart.Color
local e2 = clonePart(e, "E2_SA_Overlay", Vector3.new(0, 0, Z))
e2.Color = COLOR
try("E2 SurfaceAppearance Overlay", function()
	local sa = Instance.new("SurfaceAppearance")
	sa.AlphaMode = Enum.AlphaMode.Overlay
	sa.ColorMap = tex("T_VehicleSkin_Test")
	sa.Parent = e2
end)

-- E3: SurfaceAppearance TintMask, меняем SurfaceAppearance.Color (если свойство есть)
local e3 = clonePart(e, "E3_SA_TintMask", Vector3.new(8, 0, Z))
try("E3 SurfaceAppearance TintMask", function()
	local sa = Instance.new("SurfaceAppearance")
	sa.AlphaMode = Enum.AlphaMode.TintMask
	sa.ColorMap = tex("T_VehicleSkin_Test")
	sa.Parent = e3
end)
try("E3 SurfaceAppearance.Color", function()
	(e3:FindFirstChildOfClass("SurfaceAppearance") :: any).Color = COLOR
end)

-- F: наклейка на тонкой плоскости, над светлой и над тёмной подложкой (кайма видна на контрасте)
local f = freshModel("TestF")
for i, under in { Color3.fromRGB(240, 240, 240), Color3.fromRGB(25, 25, 25) } do
	local x = 20 + (i - 1) * 10
	local plate = Instance.new("Part")
	plate.Name = "F_Plate" .. i
	plate.Anchored = true
	plate.Material = Enum.Material.SmoothPlastic
	plate.Color = under
	plate.Size = Vector3.new(8, 0.2, 8)
	plate.CFrame = CFrame.new(x, 0.1, Z)
	plate.Parent = f
	try("F" .. i .. " Decal", function()
		local d = Instance.new("Decal")
		d.Face = Enum.NormalId.Top
		d.Texture = tex("T_Sticker_Flames_01")
		d.Parent = plate
	end)
end

print(("[EF] цвет %s\n  %s"):format(tostring(COLOR), table.concat(results, "\n  ")))
