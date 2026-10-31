--!strict
-- Все конфиги из `config/*.json` (Rojo превращает JSON в ModuleScript), только для чтения: Config.lobby.maxPlayers.
-- Проверяет их по схеме сервер при старте (ConfigService); офлайн — `lune run validate-config`.

local function deepFreeze<T>(t: T): T
	if typeof(t) == "table" and not table.isfrozen(t :: any) then
		for _, v in t :: any do
			deepFreeze(v)
		end
		table.freeze(t :: any)
	end
	return t
end

local raw: { [string]: any } = {}
for _, m in script.Parent.config:GetChildren() do
	if m:IsA("ModuleScript") then
		-- JSON-модули Rojo возвращают новую таблицу, копировать не нужно
		raw[m.Name] = require(m) :: any
	end
end

return deepFreeze(raw)
