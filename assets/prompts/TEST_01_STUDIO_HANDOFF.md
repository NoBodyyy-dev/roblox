# TEST_01 — передача: тесты в Studio (§8) и отчёт (§9)

Ты — агент Художника на Windows-ПК с Roblox Studio и Studio MCP. Основное задание — `assets/prompts/TEST_01_MODEL_TEXTURES.md` (дальше «промпт»). **Прочитай его целиком.** §1–§7 (генерация и самопроверка) уже сделаны на другой машине (Linux, без Studio). Твоя часть — §0.3–§0.4, §8 и §9. Этот файл говорит, что уже готово, что подготовлено для тестов и в каком порядке работать. Если он расходится с промптом, приоритет у промпта, а расхождение запиши в отчёт.

Правила промпта действуют: работаешь только в `assets/`, только в **тестовом** плейсе, заданные hex не трогаешь, основной плейс не трогаешь.

---

## 1. Что уже сделано

- Генераторы переписаны с JS на Python: `assets/tools/gen_palette.py` (палитра, варианты, образцы, превью, `palette.json`, самопроверка, `_build_info.json`; в конце вызывает меши) и `assets/tools/gen_test_mesh.py` (меши §6).
- Сделано два прогона. Все файлы побайтово одинаковы, включая `_build_info.json`.
- Сравнение с прежней JS-сборкой (`assets/tools/legacy_js/_build_info_js.json`):
  - побайтово совпали 6 палитр, `T_Sticker_Flames_01`, `T_Plate_01`, `T_Glass_Cracked_01`, `palette.json`, `TestPaletteBox.obj`, `TestUVBleed.obj`;
  - у `T_VehicleSkin_Test.png` пиксели идентичны, отличается только zlib-сжатие: на Linux стоял zlib-ng, а JS сжимал zlib-ом браузера;
  - `_preview.png` отличается намеренно: подписи нарисованы собственным блочным шрифтом (системные шрифты запрещены по §5).
- Самопроверка §7: **0 FAIL**, один ожидаемый WARN.
  - `T_Palette_Armor_State3`: `armor_paper_aged/armor_tape` 0.0160, `armor_paper_aged/armor_twine` 0.0123, `armor_news_dark/armor_tape_dark` 0.0187.
  - Worn проходит впритык: строки 1 и 3 — min ΔE 0.0210 и 0.0206 при пороге 0.02.
  - Полный вывод — `assets/textures/models/_selfcheck_palette.txt`.
- **Отклонение от §6 (добавлено):** `assets/source/test/TestSkinBox.obj` — куб 4×4×4 с полной UV 0..1 на каждой грани. Он нужен для E и F: у `TestPaletteBox` грани сжаты в точку или в маленький остров, и скин 1024² на нём показал бы по одному текселю на грань. Промпт допускает «любой MeshPart с UV».
- **Отклонение от §8 H (уточнено):** на сервере и на клиенте не по одному кубу, а по два. `TestBox_Server` (без SurfaceAppearance) — для шагов 1–2, `TestBox_Server_SA` (с SA) — для шагов 3–4; на клиенте так же. Причина: пока у MeshPart есть SurfaceAppearance, его `TextureID` не отображается, и шаг 1 на одном кубе ничего бы не показал.

## 2. Карта файлов

```
assets/
  palette/palette.json                 232 записи, UV в соглашении OBJ (V снизу)
  textures/models/
    T_Palette_Main.png                 + Worn, WeaponSkin_Gold, WeaponSkin_Arctic, Armor_State2, Armor_State3
    T_VehicleSkin_Test.png  T_Sticker_Flames_01.png  T_Plate_01.png  T_Glass_Cracked_01.png
    _preview.png                       контактный лист — открой и держи рядом при сравнении
    _build_info.json                   версии + SEED + SHA-256
    _selfcheck_palette.txt             вывод самопроверки
    _tests/                            сюда скриншоты и REPORT.md (пока пусто)
  source/test/
    TestPaletteBox.obj/.mtl            куб §6 (грани: +Y sand_08, −Y asphalt_04, +X signal_orange_base,
                                       −X grad_sand_terracotta, +Z weapon_steel, −Z ПЛОХАЯ skin_6 у края)
    TestUVBleed.obj/.mtl               три плитки §6
    TestSkinBox.obj/.mtl               куб с полной UV (E, F)
  tools/
    gen_palette.py  gen_test_mesh.py   генераторы (Python 3 + Pillow + numpy)
    crop_zoom.py                       вырезать область скриншота и увеличить ×8 nearest (тест B)
    studio_test_stand.luau             стенд §8 (свет, эффекты, серый пол, меши белые SmoothPlastic)
    studio_tests/
      00_set_texture_ids.luau          ID текстур -> атрибуты Workspace Tex_<имя>; остальные скрипты читают их отсюда
      B_camera.luau                    камера: объект, грань, дальность (для A–G)
      EF_setup.luau                    модели TestE (E1/E2/E3) и TestF (наклейка на светлой и тёмной подложке)
      H_prepare.luau                   4 куба для H + SurfaceAppearance-копия в ReplicatedStorage
      TestH_Server.server.luau         Script для ServerScriptService
      TestH_Client.client.luau         LocalScript для StarterPlayerScripts (шаги клиента + HUD + камера)
      cleanup.luau                     удалить из плейса всё, что создали E, F, H
    legacy_js/                         старые JS-генераторы и их _build_info/_preview — только для справки
```

Luau-скрипты написаны без доступа к Studio, их синтаксис нигде не проверялся. Если что-то падает, исправь в файле, а не только в плейсе, и упомяни исправление в отчёте.

## 3. Порядок работы

### Шаг 0. Окружение и пересборка

```powershell
cd <репозиторий>
python -m venv assets\tools\.venv
assets\tools\.venv\Scripts\pip install pillow numpy
assets\tools\.venv\Scripts\python assets\tools\gen_palette.py
assets\tools\.venv\Scripts\python assets\tools\gen_palette.py
```

- Оба прогона должны дать 0 FAIL и одинаковый `_build_info.json`: сравни SHA-256 после первого и второго прогона.
- SHA-256 PNG могут отличаться от записанных на Linux (другая сборка zlib) — это нормально, только проверь, что пиксели те же: `Image.open(...)` → `numpy.array_equal`. Различие пикселей — уже ошибка, остановись и запиши в отчёт.
- `_build_info.json` перезапишется версиями этой машины — так и надо.
- Открой `_preview.png` и посмотри его.

### Шаг 1. MCP-инструменты (§1)

Получи список реально доступных инструментов Studio MCP. Запиши в отчёт таблицу «ожидаемый → фактический» для: загрузки изображения (`upload_image` или аналог), `insert_asset`, `execute_luau`, `start_stop_play`, `inspect_instance`, `screen_capture`, чтения консоли. Чего нет — так и пиши «нет», ничего не изобретай.

### Шаг 2. Тестовый плейс и загрузка (§0.3–§0.4) — с участием человека

1. Спроси, какой плейс тестовый. **Не основной.** Сохрани его версию (File → Save / Publish) до первого `execute_luau`.
2. Выясни, кому принадлежит тестовый плейс: личному аккаунту или группе.
3. Загрузка текстур:
   - если у MCP есть загрузка и она умеет того же владельца, что у плейса, — загружай сам;
   - иначе попроси человека загрузить через Creator Hub (Creations → Development Items → Images, от владельца плейса) эти файлы: `T_Palette_Main`, `T_Palette_Worn`, `T_Palette_WeaponSkin_Gold`, `T_Palette_WeaponSkin_Arctic`, `T_VehicleSkin_Test`, `T_Sticker_Flames_01`; по желанию и остальные 4. Попроси прислать **Image ID**, не Decal ID.
   
   Выбранный вариант запиши в отчёт.
4. Попроси человека импортировать через *File → Import 3D* три меша: `TestPaletteBox.obj`, `TestUVBleed.obj`, `TestSkinBox.obj`. Затем проверь через `inspect_instance`:
   - в Workspace есть `TestPaletteBox`, `TestUVBleed`, `TestSkinBox`;
   - у `TestPaletteBox` и `TestSkinBox` ровно по одному MeshPart (если импорт разбил куб по группам, попроси переимпортировать одним мешем);
   - размер куба ≈ 4×4×4 studs;
   - как легли оси: какая грань куба смотрит в мировые +X/+Y/+Z. Если импорт повернул оси, запиши фактическое соответствие граней в отчёт и используй его в `FACE` камеры.
5. Впиши ID в `studio_tests/00_set_texture_ids.luau` (в файле, чтобы остались в репозитории) и выполни его.
6. Выполни `tools/studio_test_stand.luau`. Он заодно ставит `TextureID = T_Palette_Main` на `TestPaletteBox` и `TestUVBleed`. Перед каждой серией скриншотов выполняй стенд заново. Для C и D ставь в нём `SET_MAIN_TEXTURE = false`, иначе он вернёт Main.

### Шаг 3. Тесты A–H

Скриншоты клади в `assets/textures/models/_tests/`, имя начинается с буквы теста: `A_posX.png`, `B_box_posX_200.png`, `B_bleed_500_zoom.png`, `E1_red.png`, `H_auto_t20.png` и т.п. Перед каждым `screen_capture` выставляй камеру через `B_camera.luau`: правишь `TARGETS`, `FACE`, `DIST` вверху и выполняешь. Скриншоты сравнивай на глаз рядом с `_preview.png`: точного совпадения hex не жди (§8).

| # | Что сделать | Что записать |
|---|---|---|
| A | `TestPaletteBox` с Main. Камера на 6 граней (`DIST` 15), 6 скриншотов. | Узнаётся ли каждая грань как своя ячейка. −Z вблизи ровная. |
| B | `TestPaletteBox` (грани +X, −X, +Z, −Z, +Y, −Y) и `TestUVBleed` (`FACE` +Z — проверь по факту импорта), `DIST` = 50 / 200 / 500 / 1000. Объект мелкий — `crop_zoom.py <скрин> x y w h <out> --scale 8`. | Таблица: грань/плитка × дальность → чисто / подмес. **Дальность начала подмеса** для каждой. Плитка 3 двухцветная уже на 50? Подмешивает ли плитка 1 на 500 (если да — правило «сжимать в точку»). |
| C | `TestPaletteBox.TextureID` → Worn, те же ракурсы, что в A. | Выгоревшая, но узнаваемая; +X (сигнальная) не изменилась. |
| D | TextureID → Gold, потом Arctic, грань +Z крупно + общий вид. Потом верни Main. | Меняется только +Z. |
| E | `EF_setup.luau` трижды: `COLOR` красный, синий, белый. Камера `TARGETS = {"TestE"}`, `FACE` (0.6, 0.5, 1) (видно две грани), `DIST` 25. | Таблица E1/E2/E3 × цвет: виден ли цвет в прозрачных местах / красится ли маска. Плюс вывод `[EF]` (ошибки установки свойств). |
| F | Модель `TestF` создаётся тем же `EF_setup.luau`. Камера `TARGETS = {"TestF"}`, `FACE` (0, 1, 0.3), `DIST` 15, плюс крупно край ×8. | Есть ли белая/чёрная кайма на светлой и тёмной подложке. |
| G | Device Emulator (Test → Device → телефон среднего класса): повтори скриншоты A (+X, −X), B (`TestPaletteBox` на 200) и E. В Studio: Settings → Rendering → Quality Level 1 и 10, те же кадры. | Banding на градиенте −X, сдвиг цвета, мыло; выделяются ли сигнальные на песке. |
| H | См. ниже. | Таблица шагов × сторона + контекст `execute_luau`. |

### Тест H — подробно

1. В режиме редактирования выполни `H_prepare.luau`.
2. Вставь скрипты через `execute_luau`, подставив содержимое файлов (содержимое файлов не меняй):
   ```lua
   local s = Instance.new("Script"); s.Name = "TestH_Server"
   s.Source = [==[ <содержимое TestH_Server.server.luau> ]==]
   s.Parent = game:GetService("ServerScriptService")
   local c = Instance.new("LocalScript"); c.Name = "TestH_Client"
   c.Source = [==[ <содержимое TestH_Client.client.luau> ]==]
   c.Parent = game:GetService("StarterPlayer").StarterPlayerScripts
   ```
   Если `Source` не ставится (нет прав), попроси человека вставить их вручную.
3. `start_stop_play` (Play). Сразу выполни `execute_luau`:
   ```lua
   local RS = game:GetService("RunService"); return tostring(RS:IsServer()) .. " " .. tostring(RS:IsClient())
   ```
   Запиши результат: **в каком контексте выполняется `execute_luau` во время Play**. Если результат не возвращается и консоль не читается, его видно в HUD (первая строка — контекст самого LocalScript, не `execute_luau`; тогда выведи результат в `TextLabel` сам, как требует §1).
4. Дальше всё идёт само (`TestH_Auto`): серверный шаг n — на ~8·n с, клиентский — на 4 с позже. Шаги: 1 TextureID → Worn, 2 Color → красный, 3a SA.ColorMap → Worn, 3b SA.Color → синий, 4 удалить SA + вставить копию (ColorMap = Worn). Делай `screen_capture` примерно на 6, 14, 22, 30, 38, 46 с и в конце (HUD + кубы в кадре, камеру ставит LocalScript). Порядок кубов слева направо: Server, Server_SA, Client, Client_SA.
5. Для каждого шага и стороны определи:
   - **работает** — ошибки нет и изменение видно на скриншоте;
   - **ошибка** — текст из HUD или консоли;
   - **работает, но не реплицируется** (только сервер) — на сервере OK, а HUD в блоке «клиент видит у серверных кубов» показывает старое значение или на кубе ничего не поменялось.
   
   «OK» в HUD значит только «установилось без ошибки» — верь скриншоту.
6. Стоп Play. Выполни `cleanup.luau`. Убедись через `inspect_instance`, что `TestH_Server` / `TestH_Client` из плейса удалены (§8). Файлы в `assets/tools/studio_tests/` остаются.

## 4. Отчёт — `assets/textures/models/_tests/REPORT.md`

Структура обязательна (§9). Факты из раздела 1 этого файла перенеси как есть.

```markdown
# TEST_01 — отчёт

## 1. Загрузка и инструменты
- Тестовый плейс: <название / ID>, владелец: <личный аккаунт | группа>. Текстуры загружены: <MCP | вручную через Creator Hub>, владелец: <...>. Вариант §0.4: <...>.
- MCP: | ожидаемый | фактический | — upload_image, insert_asset, execute_luau, start_stop_play, inspect_instance, screen_capture, чтение консоли.
- Импорт OBJ: размер куба, оси (какая грань куба смотрит в мировые +X/+Y/+Z), сколько MeshPart.

## 2. Файлы и самопроверка
| Файл | Размер | Режим | OK |   (все 10 PNG + _preview, palette.json, 3 OBJ)
- Python / Pillow / numpy / SEED — из _build_info.json этой машины. Два прогона: SHA совпали? Пиксели совпали с Linux-сборкой?
- FAIL: нет. WARN: Armor_State3 — 3 пары (числа). Worn строки 1, 3 впритык (0.0210, 0.0206).
- Отклонения от промпта: TestSkinBox (E, F), раздельные кубы с SA в H, исправления Luau-скриптов (если были).

## 3. Тесты A–H
| # | Результат | Скриншоты |
- B: таблица «грань/плитка × 50/200/500/1000 → чисто/подмес», дальность начала подмеса по каждой.
- H: контекст execute_luau во время Play; таблица «шаг × сервер/клиент → работает / ошибка (текст) / не реплицируется».

## 4. Вывод по E и H
- Какой способ «краска + скин» работает (E1 / E2 / E3) и с какими оговорками.
- Как менять скины во время игры: сервер / клиент; что работает — свойства или только подмена экземпляров.
- Что из этого следует для assets/TEXTURES.md §1 и контракта Body (ASSETS_PROMPT.md §6). Контракт НЕ правим — текст Issue для Разработчика ниже (заголовок + тело).

## 5. Правило UV для ASSETS_PROMPT.md §5 (предложение)
Текст правила, подтверждённый B (с дальностями). Если 6 px не хватило — уточнённое правило.

## 6. Вопросы к команде
- Утверждение палитры: показать _preview.png Художнику, Геймдизайнеру, Разработчику.
- FAIL на заданных hex: нет (или список).
- Что поправить в цветах (по A, C, G).
- Артефакты сжатия из G.

## 7. Строки для assets/ASSETS.md (status review)
```

После отчёта:
- Добавь в `assets/ASSETS.md` строки со статусом `review`: палитра и 5 вариантов, 4 образца, 3 тестовых меша. Формат таблицы — как в файле. Треугольники: `TestPaletteBox` 12, `TestUVBleed` 6, `TestSkinBox` 12. Источник — «своё (скрипт)».
- Текст Issue положи в отчёт. Создавать Issue в GitHub — только если человек попросит.
- Git: ветка `art/test-01`, коммит только файлов из `assets/`. Pull Request — по просьбе человека.

## 5. Итоговое сообщение человеку (в чат)

Коротко, по-русски, в таком порядке:
1. Одна строка — готово / не готово и почему.
2. Где грузились текстуры и чей плейс.
3. Главное по E и H: какой способ краски и скина работает, что можно менять в игре на сервере и на клиенте.
4. Правило UV по итогам B, одной фразой с дальностями.
5. Что нужно от людей: утвердить палитру по `_preview.png`, ответить на вопросы из §6 отчёта, решить по Issue про контракт `Body`.
6. Путь к `REPORT.md` и папке скриншотов.

Без пересказа всего отчёта.

## Чего не делать

- Не начинать массовое производство текстур: оно идёт только после утверждения палитры и выводов E/H.
- Не менять заданные hex и коэффициенты, даже если в Studio что-то выглядит не так — это в вопросы.
- Не трогать основной плейс и файлы вне `assets/`. Не править `ASSETS_PROMPT.md` и контракт — только предложения в отчёте.
- Не оставлять тестовые скрипты в плейсе после H.
