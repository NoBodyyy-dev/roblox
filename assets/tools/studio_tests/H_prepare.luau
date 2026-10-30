-- TEST_01, тест H: подготовка до Play (execute_luau в режиме редактирования).
-- Создаёт 4 куба из TestPaletteBox и запасной SurfaceAppearance в ReplicatedStorage.
--   TestBox_Server / TestBox_Client       — без SurfaceAppearance: шаги 1–2 (TextureID, Color).
--   TestBox_Server_SA / TestBox_Client_SA — с SurfaceAppearance: шаги 3–4.
-- Кубы раздельные, потому что при SurfaceAppearance MeshPart.TextureID не отображается,
-- и шаг 1 на одном кубе с SA ничего бы не показал.
-- Скрипты TestH_Server / TestH_Client вставляет отдельно агент (см. TEST_01_STUDIO_HANDOFF.md, шаг H).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Z = 60

local function tex(name)
	local v = workspace:GetAttribute("Tex_" .. name)
	assert(v, "нет Tex_" .. name .. ": сначала 00_set_texture_ids.luau")
	return v
end

local function sourcePart()
	local src = workspace:FindFirstChild("TestPaletteBox", true)
	assert(src, "TestPaletteBox не найден: импортируй assets/source/test/TestPaletteBox.obj")
	if src:IsA("MeshPart") then
		return src
	end
	local parts = {}
	for _, d in src:GetDescendants() do
		if d:IsA("MeshPart") then
			table.insert(parts, d)
		end
	end
	assert(#parts == 1, ("в TestPaletteBox %d MeshPart, нужен ровно 1"):format(#parts))
	return parts[1]
end

local base = sourcePart()

local function make(name, x, withSA)
	local old = workspace:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local p = base:Clone()
	p:ClearAllChildren()
	p.Name = name
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.Color = Color3.new(1, 1, 1)
	p.TextureID = tex("T_Palette_Main")
	p.CFrame = CFrame.new(x, p.Size.Y / 2, Z)
	if withSA then
		local sa = Instance.new("SurfaceAppearance")
		sa.AlphaMode = Enum.AlphaMode.Overlay
		sa.ColorMap = tex("T_Palette_Main")
		sa.Parent = p
	end
	p.Parent = workspace
end

make("TestBox_Server", -15, false)
make("TestBox_Server_SA", -7, true)
make("TestBox_Client", 7, false)
make("TestBox_Client_SA", 15, true)

local alt = ReplicatedStorage:FindFirstChild("TestH_SA_Alt")
if alt then
	alt:Destroy()
end
alt = Instance.new("SurfaceAppearance")
alt.Name = "TestH_SA_Alt"
alt.AlphaMode = Enum.AlphaMode.Overlay
alt.ColorMap = tex("T_Palette_Worn")
alt.Parent = ReplicatedStorage

for name in workspace:GetAttributes() do
	if name:sub(1, 6) == "TestH_" then
		workspace:SetAttribute(name, nil)
	end
end
workspace:SetAttribute("TestH_Auto", true)

print("[H] готово: 4 куба на Z=" .. Z .. ", ReplicatedStorage.TestH_SA_Alt (ColorMap = Worn), TestH_Auto = true")
