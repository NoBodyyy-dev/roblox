--!strict
-- Единый загрузчик сервисов (сервер) и контроллеров (клиент), AGENT_PROMPT §4.
-- Порядок фиксирован списком `order`: сначала у всех вызывается Init (по порядку, без ожиданий),
-- затем Start (каждый в своём потоке). Модуль в папке, которого нет в списке, — ошибка: так ничего не забудется.

export type Module = {
	Init: ((self: any) -> any)?,
	Start: ((self: any) -> any)?,
}

local Loader = {}

function Loader.run(folder: Instance, order: { string }): { [string]: Module }
	local listed = {}
	for _, name in order do
		listed[name] = true
	end
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") and not listed[child.Name] then
			error(`Loader: {child:GetFullName()} не указан в порядке загрузки`)
		end
	end

	local modules: { [string]: Module } = {}
	for _, name in order do
		local m = folder:FindFirstChild(name)
		if not m or not m:IsA("ModuleScript") then
			error(`Loader: нет модуля {name} в {folder:GetFullName()}`)
		end
		modules[name] = require(m) :: any
	end

	for _, name in order do
		local m = modules[name]
		if m.Init then
			local ok, err = pcall(m.Init, m)
			if not ok then
				error(`Loader: {name}.Init: {err}`)
			end
		end
	end

	for _, name in order do
		local m = modules[name]
		if m.Start then
			task.spawn(function()
				local ok, err = xpcall(m.Start, debug.traceback, m)
				if not ok then
					warn(`Loader: {name}.Start: {err}`)
				end
			end)
		end
	end

	return modules
end

return Loader
