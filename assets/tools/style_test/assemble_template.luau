--!strict
-- Style test: сборка Model по контракту ASSETS_PROMPT §6 из импортированных OBJ.
-- Генерируется build_style_test.py (манифесты вшиты ниже). Запуск: Command Bar или MCP execute_luau в режиме Edit.
--
-- Перед запуском: File → Import 3D — assets/source/style_test/<Asset>.obj (три файла), «Rescale if too large» выключить.
-- Импортированные модели могут лежать где угодно в Workspace: скрипт ищет Model с MeshPart по именам частей.
-- Масштаб и поворот импорта не важны: Size и CFrame частей ставятся из манифеста, разворот 180° по Y распознаётся.
-- Результат: Workspace.StyleTest.<Asset> (готовая Model) — её сохраняют в assets/rbxm/<Category>/<Asset>.rbxm.

local HttpService = game:GetService("HttpService")

local MANIFESTS = HttpService:JSONDecode([==[--@@MANIFESTS@@]==])
local PALETTE_TEXTURE = "rbxassetid://108152632748455" -- T_Palette_Main, личный тестовый аккаунт (TEST_01)
local SPACING = 40

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function findImport(asset: any): Model?
	local wanted = {}
	for _, p in asset.parts do
		if p.name ~= "Collider" then
			wanted[p.name] = true
		end
	end
	local best, bestHits = nil, 0
	local done = workspace:FindFirstChild("StyleTest")
	for _, m in workspace:GetDescendants() do
		if m:IsA("Model") and not (done and m:IsDescendantOf(done)) then
			local hits = 0
			for _, d in m:GetDescendants() do
				if d:IsA("MeshPart") and wanted[d.Name] then
					hits += 1
				end
			end
			if hits > bestHits then
				best, bestHits = m, hits
			end
		end
	end
	return best
end

local function findPart(m: Instance, name: string): MeshPart?
	for _, d in m:GetDescendants() do
		if d:IsA("MeshPart") and d.Name == name then
			return d
		end
	end
	return nil
end

-- Импорт OBJ в TEST_01 обращал X и Z (поворот 180° по Y). Проверяем по двум самым удалённым частям.
local function detectFlip(asset: any, src: Model): boolean
	local a, b, dmax = nil, nil, 0
	for i, p in asset.parts do
		for j = i + 1, #asset.parts do
			local q = asset.parts[j]
			local d = (v3(p.center) - v3(q.center)) * Vector3.new(1, 0, 1)
			if d.Magnitude > dmax and findPart(src, p.name) and findPart(src, q.name) then
				a, b, dmax = p, q, d.Magnitude
			end
		end
	end
	if not a or dmax < 1 then
		return false
	end
	local pa, pb = findPart(src, a.name) :: MeshPart, findPart(src, b.name) :: MeshPart
	local imported = (pb.Position - pa.Position) * Vector3.new(1, 0, 1)
	local expected = (v3(b.center) - v3(a.center)) * Vector3.new(1, 0, 1)
	return imported:Dot(expected) < 0
end

local function apply(part: BasePart, props: any)
	for k, v in props do
		if k == "Color" then
			part.Color = Color3.fromRGB(v[1], v[2], v[3])
		elseif k == "Material" then
			part.Material = (Enum.Material :: any)[v]
		elseif k == "CollisionFidelity" then
			(part :: any).CollisionFidelity = (Enum.CollisionFidelity :: any)[v]
		else
			(part :: any)[k] = v
		end
	end
end

local root = workspace:FindFirstChild("StyleTest") or Instance.new("Folder")
root.Name = "StyleTest"
root.Parent = workspace

local log = {}
for i, asset in MANIFESTS do
	local src = findImport(asset)
	if not src then
		table.insert(log, asset.asset .. ": импорт не найден")
		continue
	end
	local old = root:FindFirstChild(asset.asset)
	if old then
		old:Destroy()
	end
	local flip = detectFlip(asset, src)
	local fix = flip and CFrame.Angles(0, math.pi, 0) or CFrame.identity
	local origin = CFrame.new((i - 2) * SPACING, 0, 0)
	local model = Instance.new("Model")
	model.Name = asset.asset
	local defaults = asset.studio_props["*"] or {}
	local made: { [string]: BasePart } = {}
	local scaleNote = {}
	for _, p in asset.parts do
		local part: BasePart
		local srcPart = findPart(src, p.name)
		if p.name == "Collider" or not srcPart then
			if p.name ~= "Collider" then
				table.insert(log, asset.asset .. ": нет части " .. p.name)
				continue
			end
			local c = Instance.new("Part")
			c.Name = "Collider"
			c.Size = v3(p.size)
			part = c
		else
			local mp = (srcPart :: MeshPart):Clone()
			local want = v3(p.size)
			local ratio = mp.Size.Magnitude / want.Magnitude
			if math.abs(ratio - 1) > 0.02 then
				table.insert(scaleNote, string.format("%s ×%.3f", p.name, ratio))
			end
			mp.Size = want
			mp.RenderFidelity = Enum.RenderFidelity.Automatic
			mp.DoubleSided = false
			mp.TextureID = p.textured and PALETTE_TEXTURE or ""
			mp.Color = Color3.new(1, 1, 1)
			mp.Material = Enum.Material.SmoothPlastic
			mp.CollisionFidelity = Enum.CollisionFidelity.Box
			for _, d in mp:GetChildren() do
				d:Destroy() -- SurfaceAppearance/скрипты из импорта не нужны
			end
			part = mp
		end
		part.Anchored = true
		part.CFrame = origin * CFrame.new(v3(p.center)) * fix
		if p.pivot_offset then
			part.PivotOffset = fix:Inverse() * CFrame.new(v3(p.pivot_offset))
		end
		apply(part, defaults)
		apply(part, asset.studio_props[p.name] or {})
		part.Parent = model
		made[p.name] = part
	end
	for n, c in asset.colliders do
		local r = c.rot
		local cp = Instance.new("Part")
		cp.Name = "Collider_" .. n
		cp.Size = v3(c.size)
		cp.CFrame = origin * CFrame.new(c.center[1], c.center[2], c.center[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		cp.Anchored = true
		cp.Transparency = 1
		cp.CanCollide = true
		cp.CanTouch = false
		cp.CanQuery = true
		cp.CastShadow = false
		cp.Parent = model
	end
	for _, a in asset.attachments do
		local parent = made[a.parent]
		if parent then
			local att = Instance.new("Attachment")
			att.Name = a.name
			att.WorldCFrame = origin * CFrame.new(v3(a.position))
			att.Parent = parent
		end
	end
	model.PrimaryPart = made[asset.primary_part]
	model.WorldPivot = origin
	for k, v in asset.attributes do
		model:SetAttribute(k, v)
	end
	model.Parent = root
	table.insert(log, string.format("%s: частей %d, коллайдеров %d, attachments %d, Tris %d, разворот импорта %s%s",
		asset.asset, #asset.parts, #asset.colliders, #asset.attachments, asset.attributes.Tris,
		flip and "180°" or "нет", #scaleNote > 0 and (", масштаб импорта исправлен: " .. table.concat(scaleNote, ", ")) or ""))
end
print("StyleTest assemble:\n" .. table.concat(log, "\n"))
return table.concat(log, "\n")
