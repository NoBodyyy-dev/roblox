# Лобби P0 — отчёт

Статус: **review.** Собрано в Blender и в Studio (2026-10-31), проверено по манифестам, `.rbxm` в `assets/rbxm/Lobby/`. Все 18 мешей и палитра принадлежат группе «Грева нет» (867558223), MeshId — `studio/mesh_ids.json`.

## Что это

Безопасный хаб по `ASSETS_PROMPT.md` §7 P0 и GDD §3 в виде **перевалочного пункта выживших посреди заброшенного города** (выбор владельца): двор 96×80 studs за сборной оградой (бетонные блоки, профлист, мешки с песком, доски), в центре костёр с лавками и гирляндой, палатки, навес с припасами, ящики, бочки, генератор, доска объявлений, сторожевая вышка-ориентир, за оградой — силуэты разрушенных домов. На северной стене трое ворот: **Море** (слева, x = +30 Roblox), **Город** (центр), **Горы** (справа). Таблички — пиктограммы без текста (дома, волны с парусом, вершины со снегом).

Магазин и стенды лидербордов — **только размеченные места** (жёлтые рамки на земле); сами модели — P5.

| Ассет | `.rbxm` | Части | Треугольники |
|---|---|---|---|
| Lobby_Hub | `rbxm/Lobby/Lobby_Hub.rbxm` | `Ground` 243, `Walls` 2 664, `Props` 1 872, `Fire` 24, `Tower` 432, `Backdrop` 924 + 69 невидимых `Collider_N` | 6 159 |
| Lobby_Door_City | `rbxm/Lobby/Lobby_Door_City.rbxm` | `Frame` 144, `Door` 216, `Sign` 228, `Lock` 156 | 744 |
| Lobby_Door_Sea | `rbxm/Lobby/Lobby_Door_Sea.rbxm` | `Frame`, `Door`, `Sign` 124, `Lock` | 640 |
| Lobby_Door_Mountains | `rbxm/Lobby/Lobby_Door_Mountains.rbxm` | `Frame`, `Door`, `Sign` 68, `Lock` | 584 |

## Контракт

**Ворота** (§6 «Дверь лобби»): `Door` — створка 12×10, `PivotOffset` на петле (левая стойка, вид со двора), открывается поворотом вокруг Y; `Sign` — табличка с пиктограммой; `Lock` — доски крест-накрест, цепь и замок, код скрывает при открытии; `Frame` — стойки, балка, башмаки (`PrimaryPart`, pivot — центр проёма на земле). Attachment `Entrance` — 5 studs перед воротами во дворе. Атрибуты: `AssetId`, `Category = Lobby`, `Tris`, `Region` (`City` / `Sea` / `Mountains`), `OpenByDefault` (true только у `City`). В `.rbxm` все ворота закрыты.

**Хаб:** `PrimaryPart = Ground`, pivot — центр двора на земле. Attachments на `Ground`: `Spawn_1..4` (у южной стены), `DoorSlot_City` / `DoorSlot_Sea` / `DoorSlot_Mountains` (сюда ставится pivot ворот), `Shop`, `Leaderboard_1..3` (Спасатель, Скорость, Общий — порядок слева направо со стороны спавна), `Campfire` (огонь, дым, свет — код), `Lookout` (площадка вышки). Визуальные части без коллизии, ходят по невидимым боксам `Collider_N` (пол, ограда, вышка, палатки, ящики). `Fire` — материал `Neon`.

У `Ground` `CollisionFidelity` остался Default: `AssetService:CreateMeshPartAsync` возвращает «Failed to load mesh asset» для этого меша. У `Ground` выключены `CanCollide`/`CanTouch`/`CanQuery`, пол — коллайдер-бокс, поэтому на игру это не влияет. Остальные части — Box.

## Проверка

`assets/tools/lobby/verify_lobby.luau` (тот же шаблон, что у style test): сериализация/десериализация как `.rbxm`, pivot в начало, сверка с манифестами мировых позиций attachments и pivot частей (0,02 stud), PrimaryPart, атрибуты, скрипты, Anchored. **OK для всех четырёх моделей.** Скриншоты `studio/*.png` рядом с R15: `overview`, `spawn_1p`, `spawn_3p`, `gates` (ворота Города открыты только для снимка), `campfire`, `tower`. Превью Blender — `preview/*.png`.

## Пайплайн

`blender --background --factory-startup --python assets/tools/lobby/build_lobby.py` → `assets/source/lobby/Lobby_All.obj` → Studio File → Import 3D, Creator = «Грева нет» → `assemble_lobby.luau` → `verify_lobby.luau`. Геометрия, UV, экспорт, сборка и проверка — общие с style test (`assets/tools/style_test/`). В шаблон сборки добавлены `place_at` (где собрать модель) и `src` (имя группы в OBJ, если оно не совпадает с контрактным именем части).

## Вопросы Разработчику

- Хватит ли 4 точек `Spawn_N`, или нужен `SpawnLocation` — сделаю частью модели.
- Ворота открываются внутрь двора на 100°. Если удобнее раздвижные или наружу — скажи.
- Телепорт: `Entrance` стоит перед воротами; триггер-зону (`Zone`, невидимая, `CanCollide = false`) могу добавить в модель ворот.
