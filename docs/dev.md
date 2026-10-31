# Разработка: как всё запустить

## Инструменты (один раз)

1. Установи [Rokit](https://github.com/rojo-rbx/rokit) и в корне репозитория выполни `rokit install`: поставятся Rojo, Wally, Selene, StyLua, luau-lsp и Lune ровно тех версий, что в `rokit.toml`.
2. `wally install` — пакеты из `wally.toml` в `Packages/`, `ServerPackages/`, `DevPackages/` (в git не хранятся).
3. Плагин Rojo в Studio: `rojo plugin install`, потом перезапусти Studio.

## Плейсы

Один `src/` на все плейсы, у каждого свой проект Rojo:

| Проект | Плейс | Что в нём |
|---|---|---|
| `places/Lobby.project.json` | Lobby | Код, пакеты, `ServerStorage.Assets.Lobby`, освещение лобби (пресет Художника `assets/lighting/lobby_lighting.luau`) |
| `places/City.project.json` | City | Код, `ServerStorage.Assets.Buildings/Nature`, `ReplicatedStorage.Assets.Vehicles` |
| `places/Sea.project.json`, `places/Mountains.project.json` | Sea, Mountains | Код, `ReplicatedStorage.Assets.Vehicles` |
| `default.project.json` | Dev | Как Lobby + тесты, `DevPackages` и временный пол `DevBaseplate` (лобби ставит код с фазы 1): для тестов, плейтеста кода, sourcemap и luau-lsp |

Роль плейса задаёт атрибут `Workspace.PlaceRole` в проекте, код читает его через `Shared.Place`. Окружение (`prod` / `dev` / `studio`) определяется по PlaceId из `config/places.json`.

Синхронизация с открытым плейсом: `rojo serve places/Lobby.project.json` → в Studio плагин Rojo → Connect.
Собрать файл: `rojo build places/Lobby.project.json -o build/Lobby.rbxl` (папка `build/` в git не хранится).

Карта города пока живёт в `places/AbandonedCity-v0.1.0.rbxl` (прототип). Генератор `tools/city/` и запекание — фаза 2.

## Структура кода

```
src/shared/      ReplicatedStorage.Shared
  config/*.json  числа игры (docs/config.md)
  rules/         чистая логика без Roblox API: ConfigSchema, ConfigValidator, RateLimiter, AdminParse
  net/Remotes    все remote: тип, схема t, rate limit
  Config, Place, Loader
  localization/  CSV → LocalizationTable (Геймдизайнер)
src/server/      ServerScriptService.Server: init.server (загрузчик), services/, net/NetServer
src/client/      StarterPlayerScripts.Client: init.client (загрузчик), controllers/, net/NetClient
tests/           Jest, *.spec.luau
```

- **Загрузчик** (`Shared.Loader`): сервисы и контроллеры запускаются в порядке из `init.server.luau` / `init.client.luau`: у всех `Init`, затем `Start`. Модуль в `services/` без строки в списке — ошибка при запуске.
- **Remote** — только через `NetServer` / `NetClient`. Новый remote — запись в `src/shared/net/Remotes.luau`. Если клиент шлёт серверу, обязательны `toServer` (схема `t`) и `rate`.
- **Админ-команды** (`AdminService`): в Studio работают у всех, в Dev-игре — у ранга группы ≥ `admin.minGroupRank`, в основной — ни у кого. В чате: `/help`, `/time 12`, `/tp 0 10 0`, `/tp <игрок>`, `/config lobby.clockTime`.

## Проверки

- `lune run check` — StyLua, Selene, luau-lsp, конфиги. Должно быть «Всё чисто».
- Тесты Jest идут внутри Roblox. Собери `rojo build default.project.json -o build/Dev.rbxl`, открой в Studio и выполни в Command Bar:

```lua
local RS = game:GetService("ReplicatedStorage")
local Jest = require(RS.DevPackages.Jest)
local result = Jest.runCLI(RS.Tests, { verbose = true, ci = true }, { RS.Tests }):awaitStatus()
```

- В Studio: Play → в Output нет ошибок и предупреждений.
