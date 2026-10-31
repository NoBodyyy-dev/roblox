# Конфиги игры

Все числа игры — в `src/shared/config/*.json`. **Значения** меняет Геймдизайнер, **структуру** (какие поля есть) — Разработчик (`TEAM.md` §3). Rojo превращает каждый JSON в ModuleScript `ReplicatedStorage.Shared.config.<имя>`, код читает их через `Shared.Config` (только чтение).

## Как поменять число и увидеть эффект

1. Поменяй значение в JSON.
2. Проверь: `lune run validate-config` (или `lune run check` — все проверки разом). Ошибка покажет файл, поле и что не так.
3. В Studio (Rojo подключён, см. `docs/dev.md`) нажми Play. Сервер при старте ещё раз проверяет все конфиги: если что-то не так, в Output будет «Конфиги не прошли проверку» со списком, и игра не запустится.

Пример, который виден сразу: `lobby.json` → `clockTime` (время суток в лобби). Поставь `12` — в лобби будет полдень.

## Правила

- Ключи, начинающиеся с `_`, — комментарии, код их не читает (`_comment`).
- `_TODO_DESIGN` — список полей с временными значениями (пути через точку). Валидатор проверяет, что такие поля есть, и считает их. Заменил число на настоящее — убери путь из списка.
- Лишнее поле — ошибка («неизвестное поле (опечатка?)»): так ловятся опечатки в именах.
- Новое поле или новый файл — сначала запрос Разработчику (Issue, `TEAM.md` §5): он добавит поле в схему `src/shared/rules/ConfigSchema.luau` и сюда.

## Файлы

### `places.json` — Разработчик
| Поле | Что |
|---|---|
| `groupId` | ID группы Roblox «Грева нет» (867558223) |
| `environments.prod` / `.dev` | `universeId` и `places.Lobby/City/Sea/Mountains` — ID после публикации от группы (Issue #8). 0 — ещё не опубликовано |

### `admin.json` — Разработчик
| Поле | Что |
|---|---|
| `environments` | В каких окружениях (`prod`, `dev`) работают админ-команды. В Studio работают всегда |
| `minGroupRank` | Минимальный ранг в группе для админ-команд (Художник — 140, Issue #8) |

### `regions.json`
| Поле | Что |
|---|---|
| `order` | Порядок регионов и ворот лобби: `City`, `Sea`, `Mountains` |
| `regions.<Регион>.openByDefault` | Открыт ли регион новому игроку |
| `regions.<Регион>.requires` | Какой регион нужно пройти, чтобы открылся этот |

### `lobby.json` (`design/specs/lobby.md`)
| Поле | Единицы | Что |
|---|---|---|
| `maxPlayers` | игроки | Максимум на сервере лобби (в настройках игры ставится то же число) |
| `startCountdownSeconds` | с | Отсчёт перед телепортом группы |
| `inviteTimeoutSeconds` | с | Сколько живёт приглашение в группу |
| `spawnJitterStuds` | studs | Случайный сдвиг от точки `Spawn_N`, чтобы игроки не появлялись друг в друге |
| `clockTime` | ч, 0–24 | Время суток в лобби |

### `world.json`
| Поле | Единицы | Что |
|---|---|---|
| `dayLengthMinutes` | мин | Полный цикл день-ночь (с фазы 8) |
| `startClockTime` | ч, 0–24 | Время суток на старте локации |

### `survival.json` — заглушка до фазы 5
`tickSeconds` (тик сервера), `hunger.max` / `hunger.perMinute`, `thirst.max` / `thirst.perMinute` / `thirst.sunExtraPerMinute` (на солнце сверх обычного), `warnAtPercent` — с какого остатка предупреждать.

### `vehicles.json` — заглушка до фазы 3
`vehicles.<Машина>`: `seats` (не меньше 4, AGENT_PROMPT §7a), `cruiseSpeed` (studs/s; седан 35–40, `city.md` §2), `cargoSlots`, `fuelCapacity`, `fuelPerMinute`, `price` (Жетоны; стартовая — 0).

### `surfaces.json` (`design/specs/city.md` §10)
| Поле | Кто | Что |
|---|---|---|
| `materials` | Разработчик | Material Roblox → покрытие (`Asphalt`, `Gravel`, `Dirt`, `Rubble`) |
| `default` | Разработчик | Покрытие для материалов не из списка |
| `rubbleTag` | Разработчик | Тег CollectionService частей завалов → покрытие `Rubble` |
| `surfaces.<Покрытие>.grip` / `.drag` | Геймдизайнер | Множители сцепления и сопротивления (1 — норма) |
| `wetGripMultiplier` | Геймдизайнер | Множитель сцепления в ливень |

### `weather.json` — заглушка до фазы 8 (`city.md` §11)
`events.Storm`: `chancePerRun`, `warningSeconds`, `durationSeconds`, `visibilityStuds`, `gripMultiplier`, `zombieHearingMultiplier`, `thirstMultiplier`.
