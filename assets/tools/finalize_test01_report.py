"""Assemble TEST_01 evidence tables and the reviewed Studio findings."""
import json
from pathlib import Path
from PIL import Image

assets=Path(__file__).resolve().parent.parent
out=assets/'textures/models/_tests'
e=json.loads((out/'rebuild_evidence.json').read_text(encoding='utf-8'))
h=json.loads((out/'H_runtime_evidence.json').read_text(encoding='utf-8'))
info=e['windows_build_info']
files=[]
for p in sorted((assets/'textures/models').glob('*.png')):
    im=Image.open(p);files.append(f'| {p.name} | {im.width}×{im.height}; {p.stat().st_size} B | {im.mode} | OK; пиксели = Linux |')
p=assets/'palette/palette.json';pal=json.loads(p.read_text(encoding='utf-8'))
files.append(f'| palette.json | {p.stat().st_size} B; 232 записи | JSON UTF-8 | OK |')
for name,tri in [('TestPaletteBox',12),('TestUVBleed',6),('TestSkinBox',12)]:
    p=assets/f'source/test/{name}.obj';files.append(f'| {name}.obj | {p.stat().st_size} B; {tri} треугольников | OBJ UTF-8 | OK |')
time_rows=[]
for r in h['records']:
    v=json.loads(next(c['text'] for c in r['state']['content'] if c['type']=='text'))
    time_rows.append(f"| {r['nominalTime']} | {r['hostElapsedSeconds']:.2f} | {v['time']:.2f} | [H_auto_t{r['nominalTime']}.png](H_auto_t{r['nominalTime']}.png) |")
handoff=(assets/'prompts/TEST_01_STUDIO_HANDOFF.md').read_text(encoding='utf-8')
linux=handoff.split('## 1. Что уже сделано',1)[1].split('## 2. Карта файлов',1)[0].strip()
report='''# TEST_01 — отчёт

Статус: тестовый прогон A–H выполнен, результаты переданы на review. Это не утверждение палитры для массового производства. B на 1000 studs имеет ограничения разрешения; см. таблицу. Основной игровой плейс не изменялся.

## 1. Загрузка и инструменты

- Рабочая ветка `art/test-01`, документы команды получены через stash → pull --rebase → stash pop до `074b37c`, без конфликтов. Прочитаны оба TEST_01 целиком, TEAM.md, PROJECT.md, ASSETS_PROMPT.md §2, §4, §5–6 и assets/TEXTURES.md §0–1. README карты не использовался как обзор проекта.
- Плейс: новый личный тестовый Place1, Studio ID `7c514097-b736-4a78-b1cc-78392aae303e`, PlaceId 0. Владелец подтверждён пользователем: личный аккаунт **sssskorrrr**, StudioService:GetUserId() = **10655828368**. CreatorId 0 у локального плейса сам по себе не подтверждает владельца.
- Перед первым execute_luau найдена сохранённая копия `C:\\Users\\ssskorrr\\Desktop\\TEST_01_Textures.rbxl`, 88 523 байта, пользователь подтвердил сохранение. Закрытую основную карту не открывали.
- Изображения загружены **MCP upload_image** с локального HTTP-сервера. У каждого ID через MarketplaceService:GetProductInfo проверены AssetTypeId **1 (Image)**, CreatorType **User**, CreatorTargetId **10655828368**. Применён личный тестовый вариант §0.4: владелец загрузок совпадает с подтверждённым владельцем плейса. Перед производством ассеты нужно загрузить от группы проекта.

| Изображение | Image ID |
|---|---|
| T_Palette_Main | 108152632748455 |
| T_Palette_Worn | 84625703848594 |
| T_Palette_WeaponSkin_Gold | 80943362922688 |
| T_Palette_WeaponSkin_Arctic | 118374044746602 |
| T_VehicleSkin_Test | 79832822427286 |
| T_Sticker_Flames_01 | 139530244188451 |

ID сохранены в `assets/tools/studio_tests/00_set_texture_ids.luau`. Остальные четыре текстуры проверены локально, не загружались. ContentProvider:PreloadAsync для шести Image ID вернул Success. Первые запросы до готовности asset representation выдавали временные предупреждения; финальные серии сняты после успешной предзагрузки.

| Ожидаемый | Фактический | Проверено |
|---|---|---|
| upload_image | mcp__Roblox_Studio__upload_image | Загрузка шести Image; параметра группы нет |
| insert_asset | mcp__Roblox_Studio__insert_asset | Доступен; OBJ импортировал пользователь |
| execute_luau | mcp__Roblox_Studio__execute_luau | Edit, Server и Client использованы |
| start_stop_play | mcp__Roblox_Studio__start_stop_play | Play и Stop |
| inspect_instance | mcp__Roblox_Studio__inspect_instance | Меши и удаление H-скриптов |
| screen_capture | mcp__Roblox_Studio__screen_capture | Снимки A–H |
| Чтение консоли | mcp__Roblox_Studio__get_console_output | Сообщения EF/H, ошибки прав |

**Импорт OBJ.** После переимпорта TestPaletteBox — один MeshPart 4×4×4, MeshId 88233994589322; TestSkinBox — один MeshPart 4×4×4, MeshId 133209494154604; TestUVBleed — один MeshPart 28×8×0.001 с тремя раздельными геометрическими плитками, MeshId 74861836929955. Старый куб из шести граней и дубликат убраны в ServerStorage.Test01_ImportBackup. Совмещение плиток в одном MeshPart не меняет их UV и не мешает B.

Поворот CFrame в Studio единичный, но импортированные координаты X и Z относительно OBJ обращены:

| Грань исходного OBJ | Нормаль в мире Studio | Содержимое |
|---|---|---|
| +X | −X | signal_orange_base |
| −X | +X | grad_sand_terracotta |
| +Y | +Y | sand_08 |
| −Y | −Y | asphalt_04 |
| +Z | −Z | weapon_steel |
| −Z | +Z | BAD skin_6 у края |

Суффиксы `world_*` в снимках — **мировые** направления, а не исходные обозначения OBJ. Камера TestUVBleed направлялась с −Z, видны все три плитки.

## 2. Файлы и самопроверка

| Файл | Размер | Режим | OK |
|---|---|---|---|
'''+ '\n'.join(files)+f'''

Windows: Python **{info['python']}**, Pillow **{info['pillow']}**, numpy **{info['numpy']}**, SEED **{info['SEED']}**. Виртуальная среда assets/tools/.venv использует уже установленные пакеты; генераторы работали без сети.

**Два успешных прогона: SHA-256 всех выходных файлов, включая _build_info.json и самопроверку, совпали.** Пиксели всех 10 PNG и превью совпали с файлами из git HEAD Linux-сборки через numpy.array_equal. Байты PNG могут отличаться из-за zlib. Подробные хеши и версии: [rebuild_evidence.json](rebuild_evidence.json); выводы [прогон 1](rebuild_run_1.txt), [прогон 2](rebuild_run_2.txt).

**FAIL: 0 в обоих успешных прогонах.** WARN только ожидаемый Armor_State3: armor_paper_aged/armor_tape **0.0160**, armor_paper_aged/armor_twine **0.0123**, armor_news_dark/armor_tape_dark **0.0187**. Worn строки 1 и 3: **0.0210**, **0.0206** при пороге 0.02. Заданные hex и коэффициенты не изменялись. Превью открыто и просмотрено: все образцы присутствуют, подписи читаются.

Один незавершённый запуск был остановлен перед git stash/pull. Следующий завершил запись файлов, но печать Δ в cp1251 вызвала UnicodeEncodeError. Проверяющий скрипт исправлен на запуск дочернего Python с `-X utf8`; затем выполнены два полных успешных прогона. Это изменение запуска, не алгоритма или цветов.

### Исходные факты HANDOFF (Linux; сохранены без переоценки)

'''+linux+'''

### Отклонения и исправления на Windows

- TestSkinBox и четыре отдельные копии в H использованы по HANDOFF.
- Добавлен `capture_isolation.luau`: перед снимком оставляет только целевую тестовую геометрию. Иначе TestSkinBox на X=40 перекрывает куб с дальнего +X, а TestUVBleed или E — с направлений Z. Ранние перекрытые кадры заменены, в отчёте используются финальные изолированные серии.
- B_camera применялся перед каждым снимком с параметрами из screenshot_manifest.json. Для C/D стенд запускался с SET_MAIN_TEXTURE=false. Оригинальные H-скрипты вставлены без изменения Source; в финальной записи камера сдвинута отдельной runtime-командой, чтобы кубы не перекрывались HUD. Первые попытки H заменены финальной записью.
- Большие JPEG-блоки сохранялись порциями после выявления ограничения размера одной команды записи. Итоговые записи проверены, PNG декодируются Pillow. PNG — **копии кадров из JPEG MCP**, а не исходные lossless-снимки: JPEG может добавлять ореол/размытие. Это ограничивает вывод о тонком подмесе и компрессии Roblox.
- F выполнен предоставленным EF_setup: Decal на двух тонких Part. Это проверяет указанный стенд HANDOFF, но не доказывает такое же поведение на изогнутом кузове/меш-наклейке.

## 3. Тесты A–H

Нейтральный стенд: GlobalShadows=false, ClockTime=12, Brightness=2, Ambient/OutdoorAmbient=(128,128,128), EnvironmentDiffuseScale/EnvironmentSpecularScale=0, ExposureCompensation=0. Sky/Atmosphere/постэффекты перемещены в TestStand_Stash; фон штатного неба может оставаться видимым без экземпляра Sky. Тестовые меши — белый SmoothPlastic. Сравнение визуальное с _preview.png, без требования совпадения hex экрана.

PC: Average Laptop, viewport 1366×768. G: Samsung Galaxy A16 (780×360, ResolutionScale=3), landscape, фактический viewport 686×339. StarterGui.ScreenOrientation=Sensor; UI игры не тестировался. Все финальные кадры сохранены как PNG плюс исходные JPEG.

| # | Результат | Скриншоты |
|---|---|---|
| A | 6 граней узнаются; BAD-грань вблизи ровная. Направления — по таблице выше | [A_contact](A_world_contact.png), A_world_*.png |
| B | 28 ракурсов; видимый контроль и ограничения дальности — ниже | [B_contact](B_contact.png), B_*_zoom.png (×8 nearest) |
| C | Выгоревшая, узнаваемая палитра; сигнальная мировая −X визуально не изменилась | [C_contact](C_world_contact.png), C_world_*.png |
| D | Стальная исходная +Z (мировая −Z) стала золотой / холодной серо-голубой; видимые сигнальная и песочная грани сохранились. Локальная проверка подтверждает неизменность прочих строк | [D_contact](D_contact.png) |
| E | Overlay даёт краску в прозрачной зоне; TextureID её не даёт; TintMask красит иную область | [E_contact](E_contact.png), E_red/blue/white.png |
| F | На светлой и тёмной подложках нет устойчивого чёрного/белого контура по всему силуэту; фильтрация смягчает края, JPEG мешает оценке тонкой каймы | [F](F_light_dark.png), [светлый край ×8](F_light_edge_zoom.png), [тёмный край ×8](F_dark_edge_zoom.png) |
| G | На A16 качество 1 и 10: сигнальная читается на песке, градиент узнаётся, E2/E3 сохраняют различие. На 200 куб очень мал; тонкий подмес неразличим. Явного сильного banding не видно; мелкие полосы нельзя отделить от JPEG | [G_contact](G_contact.png), G_A16_Q1_*.png, G_A16_Q10_*.png |
| H | TextureID/Color и SA.Color доступны; ColorMap запрещён обычным скриптам; копия готового SA работает. Репликация и ограничения — ниже | H_auto_t0/6/14/22/30/38/46/50.png, [консоль](H_console.txt), [данные](H_runtime_evidence.json) |

### B — грань/плитка × дальность

«Чисто» означает отсутствие **видимого** цвета соседней ячейки; не означает доказанное отсутствие подмеса на уровне субпикселей. Н/О — недостаточно пикселей, нельзя надёжно отличить мип-смешение атласа от края силуэта/фона/JPEG. На 500 куб ~4–5 пикселей, на 1000 ~2; плитки крупнее. Начало подмеса не следует выдумывать из ожидаемого результата.

| Исходная грань / плитка (мир) | 50 | 200 | 500 | 1000 | Начало видимого подмеса |
|---|---|---|---|---|---|
| +Y sand_08 (+Y), UV в точку | Чисто | Чисто | Чужой цвет не виден, мало пикселей | Н/О | Не установлено |
| −Y asphalt_04 (−Y), UV в точку | Чисто | Чисто | Чужой цвет не виден, мало пикселей | Н/О | Не установлено |
| +X signal (−X), safe rect | Чисто | Чисто | Чужой цвет не виден, мало пикселей | Н/О | Не установлено |
| −X градиент (+X) | Градиент чистый | Градиент читается | Только несколько тонов, Н/О для края | Н/О | Не установлено |
| +Z steel (−Z), UV в точку | Чисто | Чисто | Чужой цвет не виден, мало пикселей | Н/О | Не установлено |
| −Z BAD skin_6 (+Z), 1 px от края | Чисто | Явной тёмной полосы нет | Н/О для слабого подмеса | Н/О | Ожидаемое раннее потемнение не подтверждено |
| Плитка 1: skin_6, safe rect | Чисто | Чисто | Явной тёмной полосы нет | Н/О для слабого подмеса | Не установлено; до 500 явно не замечен |
| Плитка 2: skin_6, 1 px | Чисто | Явной тёмной полосы нет | Н/О для слабого подмеса | Н/О | Раньше плитки 1 не доказано |
| Плитка 3: через skin_6/denim_1 | Два цвета | Два цвета | Два цвета | Разделение ещё видно | Уже 50; намеренная ошибка UV, не мипы |

### E — три цвета, три способа

| Вариант | Красный | Синий | Белый | Вывод |
|---|---|---|---|---|
| E1 MeshPart.TextureID + MeshPart.Color | Прозрачные области серые | Те же серые | Те же серые | Как «краска + скин» не работает: цвет не проявляется |
| E2 SA Overlay + MeshPart.Color | Красная подложка | Синяя подложка | Белая подложка | Работает; непрозрачные полосы/звезда сохраняются |
| E3 SA TintMask + SA.Color | Меняется область маски | Синие области маски | Белая область маски | Свойства существуют и видны, но это иной эффект; не замена E2 |

Все сообщения [EF] для TextureID, Overlay, TintMask, SurfaceAppearance.Color и двух Decal: OK. Успешная установка E1 сама по себе не означает требуемого визуального эффекта.

### H — контекст, репликация и реальное время

execute_luau **выбирает** datamodel_type: Server вернул IsServer=true/IsClient=false; Client — false/true. Поэтому здесь проверены оба контекста, а не один предполагаемый. HUD также false/true, потому что его пишет LocalScript. Данные серверных кубов читаются отдельно на клиенте в JSON.

| Шаг | Сервер | Клиент |
|---|---|---|
| 1 TextureID → Worn | Работает, Worn виден и ID дошёл до клиента | Работает локально, Worn виден |
| 2 MeshPart.Color → красный | Свойство меняется и реплицируется; на непрозрачной TextureID-палитре красная краска визуально скрыта | Свойство меняется локально; на непрозрачной палитре визуально скрыто. Визуальная краска доказана E2, не этим кубом |
| 3a существующий SA.ColorMap → Worn | Ошибка: The current thread cannot write 'ColorMap' (lacking capability Plugin) | Та же ошибка |
| 3b существующий SA.Color → синий | Работает и реплицируется: синий серверный SA-куб на H_auto_t30, клиент читает 0,0,1 | Работает локально: синий клиентский SA-куб до подмены |
| 4 удалить SA + клон Alt из ReplicatedStorage | Работает, Worn виден на клиенте; клиентский JSON ColorMap = Worn | Работает локально; к финалу обе SA-копии Worn |

Обычный LocalScript также не может **читать** SA.ColorMap: HUD показывает lacking capability Plugin. Это ограничение чтения, не доказательство отсутствия репликации; ColorMap проверен MCP-клиентским контекстом и изображением. При клонировании SA цвет возвращается к цвету подготовленной копии (в тесте белый).

| Номинальное имя t | Реальные секунды от начала записи | DistributedGameTime | Снимок |
|---|---|---|---|
'''+ '\n'.join(time_rows)+'''

После H: Stop, cleanup.luau; inspect_instance подтвердил отсутствие ServerScriptService.TestH_Server и StarterPlayer.StarterPlayerScripts.TestH_Client. E/F, четыре H-куба, Alt и TestH_* атрибуты удалены. Эмулятор остановлен, viewport возвращён к обычному, QualityLevel и EditQualityLevel — Automatic. Импортированные меши, нейтральный стенд и Tex_* оставлены для повторения.

## 4. Вывод по E и H

Рекомендуемый проверенный путь «краска + скин» — **E2: белая подготовленная SurfaceAppearance в AlphaMode.Overlay, прозрачные участки ColorMap + MeshPart.Color**. E1 не проявляет краску. E3 TintMask работает для окраски маски, но меняет другую область рисунка и требует отдельного авторинга текстуры. Не смешивать эти два эффекта.

В игре TextureID палитр можно менять скриптом. Для нового ColorMap подготовить SA заранее в Studio и менять экземпляр из набора в ReplicatedStorage: runtime-запись ColorMap запрещена и серверу, и клиенту. SA.Color менять можно; серверное изменение реплицируется. Подмена SA сбрасывает его цвет к сохранённому значению копии — цвет нужно применять заново, если он должен сохраняться.

ASSETS_PROMPT.md §2/§6 требуют Body «без текстуры», assets/TEXTURES.md §1 предполагает прозрачный скин поверх краски. Результат E2 уточняет технический смысл, но **контракт не изменялся**. Для продакшена сначала согласовать контракт и загрузить ассеты от группы.

### Текст Issue для Разработчика (не создан)

**Заголовок:** [запрос][разработка] Уточнить Body и runtime-смену скина по TEST_01

Что нужно: согласовать контракт Body как отдельного белого MeshPart с цветом краски через MeshPart.Color и опциональной заранее подготовленной SA Overlay со скином.

Зачем: E1 TextureID не показывает краску в прозрачных местах; E2 Overlay показывает. В H runtime-запись SA.ColorMap запрещена обычным Script/LocalScript, зато клоны готовых SA и изменение SA.Color работают, включая серверную репликацию.

Срок: до производства скинов и интеграции магазина.

Детали: сохранить UV Body; палитры статичных моделей и смена TextureID оружия остаются отдельным путём. Подготовить каталог SA по разрешённым skin ID в ReplicatedStorage, менять экземпляр и повторно применять нужный цвет. Согласовать, должен ли цвет жить в MeshPart.Color (Overlay) или SA.Color (TintMask); это разные эффекты. Решение отразить в assets/TEXTURES.md §1 и ASSETS_PROMPT.md §6 совместно с Художником. Тестовые личные Image ID не считать готовыми групповыми ассетами. Доказательства: E_contact.png, H_runtime_evidence.json, H_console.txt и H_auto_*.png в папке этого отчёта.

## 5. Правило UV для ASSETS_PROMPT.md §5 (предложение)

Острова ровного цвета сжимать в центр ячейки; если нужен остров площадью, оставлять минимум 6 px в uv_safe_rect. Градиент — вертикально внутри безопасной области. Контроль с 6 px не показал явной тёмной полосы на 50/200/500 studs; **чистоту на любых дальностях не обещать**. На 1000 куб слишком мал для надёжной оценки. Плитка через границу двухцветна уже на 50. Ранний подмес при 1 px этим прогоном не доказан — не ужесточать цифру на основании ожидания. Для крупных производственных мешей повторить B на их фактических размерах и целевом разрешении.

## 6. Вопросы к команде

- Художнику, Геймдизайнеру и Разработчику утвердить [превью](../_preview.png), особенно выгоревшие оттенки. Пока статус review, массовое производство не начато.
- FAIL на заданных hex нет. Решить, устраивают ли намеренно близкие пары Armor_State3 и небольшой запас Worn (0.0210/0.0206). Цвета не исправлялись автоматически.
- По A/C/G обязательных цветовых правок не предлагаю: сигнальная узнаётся, Worn отличается. Световой сдвиг экрана не основание менять hex.
- Для окончательного вывода о сжатии Roblox и тонких ореолах нужен lossless-захват или реальное устройство: текущий MCP возвращает JPEG. Эмулятор формы экрана не является измерением производительности телефона.
- Утвердить предложение Issue по Body. Ни Issue, ни PR без запроса не создавались; main не менялся.
- Общие документы группы не отменили сделанное: все изменения только assets/. Исключение для личного тестового владельца взято из TEST_01 §0.4; для игры группы всё переоформить на группу.

## 7. Строки для assets/ASSETS.md (status review)

Добавлены шесть палитр, четыре образца и три меша: 13 строк, status review, источник «своё (скрипт)». Кубы 12 треугольников, UVBleed 6; текстуры без треугольников. Четыре опциональных изображения не загружались; review не означает production-ready.
'''
(out/'REPORT.md').write_text(report,encoding='utf-8')
tracker=assets/'ASSETS.md';text=tracker.read_text(encoding='utf-8')
ids={'T_Palette_Main':108152632748455,'T_Palette_Worn':84625703848594,'T_Palette_WeaponSkin_Gold':80943362922688,'T_Palette_WeaponSkin_Arctic':118374044746602,'T_VehicleSkin_Test':79832822427286,'T_Sticker_Flames_01':139530244188451}
for p in sorted((assets/'textures/models').glob('T_*.png')):
    if f'| {p.stem} |' not in text:
        note=f'TEST_01; Image ID {ids[p.stem]}, личный тестовый аккаунт' if p.stem in ids else 'TEST_01; локальная проверка, не загружено'
        text+=f'| {p.stem} | Textures/Models | TEST_01 | review | — | своё (скрипт) | {note}; отчёт textures/models/_tests/REPORT.md |\n'
for name,tri in [('TestPaletteBox',12),('TestUVBleed',6),('TestSkinBox',12)]:
    if f'| {name} |' not in text:text+=f'| {name} | Tests | TEST_01 | review | {tri} | своё (скрипт) | OBJ; тестовый импорт; textures/models/_tests/REPORT.md |\n'
tracker.write_text(text,encoding='utf-8')
print('REPORT.md and 13 review tracker rows written')
