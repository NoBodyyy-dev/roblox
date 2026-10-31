# Установка рабочего места (Windows) для нового участника

Для человека, который управляет агентом и сам не программирует. Делать по порядку. Где написано «команда», открыть
**PowerShell** (Пуск → набрать «PowerShell» → Enter), вставить строку, нажать Enter.

## 1. Что нужно каждому

| # | Что | Как | Проверка |
|---|---|---|---|
| 1 | **Git** | команда `winget install --id Git.Git -e` | закрыть и открыть PowerShell, `git --version` |
| 2 | **GitHub CLI** | команда `winget install --id GitHub.cli -e` | `gh --version` |
| 3 | Вход в GitHub | команда `gh auth login` → GitHub.com → HTTPS → Login with a web browser | `gh auth status` |
| 4 | **Claude Code** | приложение Claude для компьютера (claude.ai/download), раздел Code | агент отвечает в нужной папке |
| 5 | Копия проекта | команда `gh repo clone NoBodyyy-dev/roblox "$HOME\Documents\roblox"` | в `Документы\roblox` есть `TEAM.md` |
| 6 | **Roblox Studio** | create.roblox.com → Start Creating → установить, войти **своим** аккаунтом | Studio открывается |
| 7 | Роль в группе «Грева нет» | прислать владельцу ник Roblox, он выдаёт роль (Issue #8) | на roblox.com в группе видна ваша роль |

Доступ к репозиторию: либо вход в общий аккаунт `lfg-cdg`, либо ваш аккаунт GitHub, добавленный в репозиторий. Решает владелец.

## 2. Studio MCP (агент управляет Studio)

1. Открыть Roblox Studio и любой плейс (например, пустой Baseplate).
2. Вкладка **Assistant** → кнопка **⋯** → включить **«Enable Studio as MCP server»**.
3. Сказать агенту: «Подключи Roblox Studio MCP к Claude Code в этой папке и проверь, что видишь Studio».
   У Художника-1 рабочая настройка лежит в `C:\Users\m1sha\Documents\roblox\.mcp.json` (в git её нет) — можно попросить копию.
4. Studio должна быть **открыта** всё время, пока агент работает с ней.

## 3. Только для Художника

| # | Что | Как |
|---|---|---|
| 1 | **Blender** (любая 4.x или 5.x LTS) | команда `winget install --id BlenderFoundation.Blender -e` или через Steam |
| 2 | **Python 3** | python.org → Downloads → установщик, отметить **«Add python.exe to PATH»** |
| 3 | Проверка | сказать агенту: «Найди Blender и запусти его из скрипта в фоне» |

Blender MCP не нужен: агент управляет Blender скриптами.

## 4. Только для Разработчика

После слияния PR #12 всё описано в `docs/dev.md`. Коротко:
1. Установить **Rokit** (github.com/rojo-rbx/rokit → Releases → установщик для Windows).
2. В папке проекта: `rokit install`, затем `wally install`.
3. Плагин Rojo в Studio: `rojo plugin install`, перезапустить Studio.
4. Проверка: `lune run check` → «Всё чисто».

## 5. Первое сообщение агенту

> Прочитай TEAM.md и свой промпт (<ваш промпт>.md), следуй им. Работай в этой папке. Сделай git pull в main и новую ветку <роль>/<задача>.

Готовые стартовые промпты для Художника-2 и Разработчика владелец получил в чате.

## 6. Частые проблемы

| Проблема | Что делать |
|---|---|
| `winget` не найден | Microsoft Store → обновить «App Installer» |
| Команда не найдена сразу после установки | закрыть и снова открыть PowerShell |
| Агент не видит Studio | Studio открыта? Включён «Enable Studio as MCP server»? Перезапустить Claude Code |
| Импорт в Studio не от группы | при File → Import 3D в колонке **Creator** выбрать «Грева нет» |
| PowerShell пишет числа с запятой (4,6) | агент должен писать числа в JSON с точкой — напомнить ему |
| Нет связи с GitHub | проверить VPN, повторить через минуту |
