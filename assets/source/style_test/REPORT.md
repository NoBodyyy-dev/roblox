# Style test — отчёт

Статус: **часть Blender готова, проверка в Studio не сделана** (Studio MCP не подключён к сессии агента, см. «Что осталось»). Утверждения стиля пока нет.

## Что сделано

Три ассета по `ASSETS_PROMPT.md` §2, все строятся одним скриптом `assets/tools/style_test/build_style_test.py` (Blender 5.2.3 LTS, `blender --background --factory-startup --python ...`). Исходник `StyleTest.blend` сохраняется тем же скриптом.

| Ассет | Категория | Части | Треугольники | Бюджет §4 |
|---|---|---|---|---|
| House_Small_01 | Buildings | `Shell` 1 084, `Door_1` 36 + 32 невидимых `Collider_N` | 1 120 | ≤ 8 000 здание |
| Sedan | Vehicles | `Body` 438, `Trim` 406, `Wheel_FL/FR/RL/RR` по 72, `Steering` 40, `Hood` 12, `Trunk` 12, `Glass` 10, `Collider` | 1 206 | ≤ 8 000 машина |
| Rock_Desert_01 | Nature | `Rock` 240 | 240 | 500–3 000: ниже нижней границы; для low-poly скалы крупные грани читаются лучше |

**Масштаб (§5):** 1 юнит Blender = 1 stud. Дом 16×20, стены 11 (этаж 10–12), дверь 4×8, крыльцо. Седан 15,6 в длину (с бамперами), крыша 5,4, колёса R 1,2. Рядом стоит R15-болванка 5,2 studs (только на превью).

**Оси и pivot:** перёд смотрит в −Z Roblox, низ на Y = 0, pivot модели — центр основания. Колёса: pivot в центре оси (центр bbox). `Door_1`, `Hood`, `Trunk`: `PivotOffset` на петле (в манифесте `pivot_offset`).

**UV на палитру:** каждый треугольник — остров 8 px в центре своей ячейки `T_Palette_Main`. Самопроверка скрипта: 0 вершин вне `uv_safe_rect`, минимум **12 px** до края ячейки (норма ≥ 6) во всех палитровых частях.

**Контракт Body (решение в #2, PR #3):** `Body`, `Hood`, `Trunk` — белые MeshPart, `TextureID` пустой, `SmoothPlastic`; краску задаёт сервер через `Color`. UV `Body` — развёртка 0..1 по видам (два борта, верх палубы, крыша, перёд, зад, низ, внутренние грани отдельно), без зеркал и наложений. Это фиксированная UV для будущих скинов `SurfaceAppearance`: схема `Sedan_Body_UV.png`, плотность около 30 px/stud на 1024². Скины не делались.

**Attachments седана:** `Seat_Driver`, `Seat_1`…`Seat_4` (5 мест по AGENT_PROMPT §7a), `Engine`, `Slot_SparkPlug`, `Slot_Battery`, `Slot_Radiator`, `Slot_Oil`, `Slot_FuelCap`, `Cargo`, `Headlight_L/R`, `Exhaust`. **Дом:** `Entrance_1`, `Loot_1..3`, `ZombieSpawn_1`, `SurvivorSpawn_1`.

**Файлы** (`assets/source/style_test/`): `<Asset>.obj/.mtl` — основной формат импорта: в TEST_01 OBJ лёг 1:1 по размеру с известным разворотом осей. `<Asset>.fbx` — по §5, масштаб 0.01 (как у Roblox-плагина для Blender), в Studio не проверен. `<Asset>.manifest.json` — части, размеры, центры, pivot, attachments, коллайдеры, свойства для Studio. `preview/*.png` — рендеры Blender (Workbench) для раннего взгляда, **не замена скриншотам Studio**.

**Сборка в Studio:** `assets/tools/style_test/assemble_style_test.luau` (генерируется из `assemble_template.luau`, манифесты вшиты). После импорта трёх OBJ скрипт собирает `Workspace.StyleTest.<Asset>`: Size и CFrame частей из манифеста, автоматически распознаёт разворот импорта на 180° и чужой масштаб, ставит палитру `rbxassetid://108152632748455` на палитровые части, пустой TextureID на Body/Hood/Trunk, attachments, атрибуты `AssetId`, `Category`, `Tris`, `PrimaryPart`. Скриптов внутри моделей нет.

## Что осталось (нужен Studio)

1. Подключить Studio MCP к сессии агента: Studio запущен, `%LOCALAPPDATA%\Roblox\mcp.bat` есть, но в конфиге Claude Code сервера нет.
2. Импорт трёх OBJ (File → Import 3D) в тестовый плейс — делает художник или агент через MCP.
3. Запуск `assemble_style_test.luau`, проверка `inspect_instance`, скриншоты рядом с R15 с 1-го и 3-го лица в одном формате.
4. Экспорт `.rbxm` в `assets/rbxm/Buildings|Vehicles|Nature/`, статус в `ASSETS.md` → `review`, PR в `main`.

## Вопросы Разработчику

- `Hood` и `Trunk` сделаны как `Body`: белые, без текстуры. Краску коду надо ставить на все три части, а скин SurfaceAppearance — только на `Body`. Подходит, или капот и багажник тоже должны нести скин?
- Пассажирские места названы `Seat_1`…`Seat_4`. Если коду удобнее нумерация с 2 — переименую.
- `Collider` седана — один невидимый Part-бокс по габариту кузова. Если нужен Hull по форме, сделаю отдельным мешем.
- Модели собраны с `Anchored = true` (для тестового плейса). У транспорта по §6 решает код.

**Владение:** группы проекта нет. Палитра в сборке — Image ID с личного тестового аккаунта (TEST_01); до продакшена перезалить от группы.
