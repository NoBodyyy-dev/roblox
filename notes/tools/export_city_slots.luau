-- Выгрузка мест построек с карты города в CSV. Только читает, ничего не меняет.
-- Как запустить:
--   1. Открыть в Studio places/AbandonedCity-v0.1.0.rbxl (или свежую версию карты).
--   2. View → Output и View → Command Bar.
--   3. Вставить весь этот файл в Command Bar, нажать Enter.
--   4. Скопировать строки между «CSV START» и «CSV END» из Output в файл city_slots.csv.
-- Колонки:
--   kind      enterable (доступная постройка, UsefulBuildings) / sealed (закрытый дом, SealedBuildings)
--   x, y, z   центр основания (земля), studs
--   yaw       поворот вокруг Y, градусы (вход смотрит в −Z модели, как в контракте ASSETS_PROMPT.md §5)
--   width     размер по X модели, depth — по Z, height — высота
--   floors    этажей (только enterable; высота этажа на карте 16 studs)
--   near      true — у главной улицы
--   axisDist  расстояние по X от оси главной улицы (со знаком)

local city = workspace:FindFirstChild("AbandonedCity")
assert(city, "Нет workspace.AbandonedCity — откройте плейс с картой города")

local function ax(z: number): number
	return 260 * math.sin(z / 1600) + 100 * math.sin(z / 650)
end

local function f1(n: number): string
	return string.format("%.1f", n)
end

local rows = { "kind,name,x,y,z,yaw,width,depth,height,floors,near,axisDist" }

local function add(kind: string, m: Instance)
	if not m:IsA("Model") or not m.PrimaryPart then
		return
	end
	local p = m.PrimaryPart
	local _, yaw, _ = p.CFrame:ToOrientation()
	local w, d, h, baseY
	local floors = m:GetAttribute("Floors") or 0
	if kind == "enterable" then
		-- PrimaryPart = Foundation (на 2 studs шире здания), этаж 16 studs
		w, d, h, baseY = p.Size.X - 2, p.Size.Z - 2, floors * 16, p.Position.Y
	else
		-- PrimaryPart = сплошной блок, центр на половине высоты
		w, d, h, baseY = p.Size.X, p.Size.Z, p.Size.Y, p.Position.Y - p.Size.Y / 2
	end
	local pos = p.Position
	table.insert(rows, table.concat({
		kind,
		m.Name,
		f1(pos.X),
		f1(baseY),
		f1(pos.Z),
		f1(math.deg(yaw)),
		f1(w),
		f1(d),
		f1(h),
		tostring(floors),
		tostring(m:GetAttribute("NearMainRoad") == true),
		f1(pos.X - ax(pos.Z)),
	}, ","))
end

for _, folderName in { "UsefulBuildings", "SealedBuildings" } do
	local folder = city:FindFirstChild(folderName)
	if folder then
		local kind = if folderName == "UsefulBuildings" then "enterable" else "sealed"
		for _, m in folder:GetChildren() do
			add(kind, m)
		end
	else
		warn("Нет папки " .. folderName)
	end
end

print("CSV START")
for _, line in rows do
	print(line)
end
print("CSV END")
print(`Строк: {#rows - 1}`)
