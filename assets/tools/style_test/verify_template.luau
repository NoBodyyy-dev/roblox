--!strict
-- Style test: проверка собранных моделей по манифестам (генерируется build_style_test.py, манифесты вшиты).
-- Каждая Model из Workspace.StyleTest сериализуется и десериализуется (как .rbxm), pivot модели — в начало координат,
-- затем сверяются: PrimaryPart, атрибуты, части, мировые позиции attachments и pivot частей, CollisionFidelity,
-- отсутствие скриптов, Anchored, контракт Body (TextureID пустой, цвет белый).

local HttpService = game:GetService("HttpService")
local SS = game:GetService("SerializationService")
local MANIFESTS = HttpService:JSONDecode([==[--@@MANIFESTS@@]==])
local TOL = 0.02

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local out = {}
for _, asset in MANIFESTS do
	local src = workspace.StyleTest:FindFirstChild(asset.asset)
	if not src then
		table.insert(out, asset.asset .. ": нет модели")
		continue
	end
	local c = src:Clone()
	c:PivotTo(CFrame.identity)
	local m = SS:DeserializeInstancesAsync(SS:SerializeInstancesAsync({ c }))[1] :: Model
	c:Destroy()
	local bad = {}
	local mp0 = v3(asset.model_pivot or { 0, 0, 0 })
	if not m.PrimaryPart or m.PrimaryPart.Name ~= asset.primary_part then
		table.insert(bad, "PrimaryPart")
	end
	for k, v in asset.attributes do
		if m:GetAttribute(k) ~= v then
			table.insert(bad, "атрибут " .. k)
		end
	end
	local fid = {}
	for _, p in asset.parts do
		local part = m:FindFirstChild(p.name) :: BasePart?
		if not part then
			table.insert(bad, "нет части " .. p.name)
			continue
		end
		-- pivot модели после PivotTo(identity) в нуле; у PrimaryPart pivot = pivot модели
		local want = p.name == asset.primary_part and Vector3.zero
			or v3(p.center) + (p.pivot_offset and v3(p.pivot_offset) or Vector3.zero) - mp0
		local got = part:GetPivot().Position
		if (got - want).Magnitude > TOL then
			table.insert(bad, string.format("pivot %s %s≠%s", p.name, tostring(got), tostring(want)))
		end
		if part:IsA("MeshPart") then
			fid[part.CollisionFidelity.Name] = (fid[part.CollisionFidelity.Name] or 0) + 1
			if not p.textured and (part.TextureID ~= "" or part.Color ~= Color3.new(1, 1, 1)) then
				table.insert(bad, p.name .. ": TextureID/Color")
			end
		end
	end
	for _, a in asset.attachments do
		local att = m:FindFirstChild(a.name, true) :: Attachment?
		if not att or att.Parent == nil or att.Parent.Name ~= a.parent then
			table.insert(bad, "нет Attachment " .. a.name)
		elseif (att.WorldPosition - (v3(a.position) - mp0)).Magnitude > TOL then
			table.insert(bad, string.format("Attachment %s %s≠%s", a.name, tostring(att.WorldPosition), tostring(v3(a.position) - mp0)))
		end
	end
	local scripts, loose = 0, 0
	for _, d in m:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			scripts += 1
		elseif d:IsA("BasePart") and not d.Anchored then
			loose += 1
		end
	end
	if scripts > 0 then
		table.insert(bad, scripts .. " скриптов")
	end
	if loose > 0 then
		table.insert(bad, loose .. " не Anchored")
	end
	local f = {}
	for k, n in fid do
		table.insert(f, k .. "×" .. n)
	end
	table.insert(out, string.format("%s: %s | CollisionFidelity %s", asset.asset,
		#bad == 0 and "OK" or table.concat(bad, "; "), table.concat(f, ", ")))
	m:Destroy()
end
return table.concat(out, "\n")
