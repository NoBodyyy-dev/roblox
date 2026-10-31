--!strict
-- Проверка конфигов по схеме. Чистая логика без Roblox API: работает и на сервере, и в Lune (`lune run validate-config`).
--
-- Узлы схемы:
--   { type = "number", min = 0, max = 10, integer = true }
--   { type = "string", enum = { "A", "B" } }
--   { type = "boolean" }
--   { type = "array", of = <узел>, minItems = 1 }
--   { type = "record", fields = { name = <узел> }, optional = { name = true } }
--   { type = "map", key = <узел string>, value = <узел> }
-- Ключи, начинающиеся с "_", в данных пропускаются (комментарии). `_TODO_DESIGN` — список путей с временными
-- значениями: каждый путь должен существовать, сами пути возвращаются как предупреждения.

export type Schema = { [string]: any }
export type Result = {
	errors: { string },
	todo: { string },
}

local ConfigValidator = {}

local function describe(value: any): string
	local t = typeof(value)
	if t == "string" then
		return string.format("%q", value)
	end
	return t == "table" and "table" or tostring(value)
end

local function isArray(value: { [any]: any }): boolean
	local n = 0
	for k in value do
		if typeof(k) ~= "number" then
			return false
		end
		n += 1
	end
	return n == #value
end

local function check(node: Schema, value: any, path: string, errors: { string })
	local kind = node.type
	if kind == "number" then
		if typeof(value) ~= "number" or value ~= value then
			table.insert(errors, `{path}: ожидалось число, получено {describe(value)}`)
			return
		end
		if node.integer and value % 1 ~= 0 then
			table.insert(errors, `{path}: ожидалось целое число, получено {value}`)
		end
		if node.min ~= nil and value < node.min then
			table.insert(errors, `{path}: {value} меньше минимума {node.min}`)
		end
		if node.max ~= nil and value > node.max then
			table.insert(errors, `{path}: {value} больше максимума {node.max}`)
		end
	elseif kind == "string" then
		if typeof(value) ~= "string" then
			table.insert(errors, `{path}: ожидалась строка, получено {describe(value)}`)
			return
		end
		if node.enum and not table.find(node.enum, value) then
			table.insert(errors, `{path}: {describe(value)} не из списка {table.concat(node.enum, ", ")}`)
		end
	elseif kind == "boolean" then
		if typeof(value) ~= "boolean" then
			table.insert(errors, `{path}: ожидалось true/false, получено {describe(value)}`)
		end
	elseif kind == "array" then
		if typeof(value) ~= "table" or not isArray(value) then
			table.insert(errors, `{path}: ожидался список`)
			return
		end
		if node.minItems and #value < node.minItems then
			table.insert(errors, `{path}: элементов {#value}, нужно не меньше {node.minItems}`)
		end
		for i, item in value do
			check(node.of, item, `{path}[{i}]`, errors)
		end
	elseif kind == "record" then
		if typeof(value) ~= "table" then
			table.insert(errors, `{path}: ожидался объект`)
			return
		end
		local optional = node.optional or {}
		for name, child in node.fields do
			local v = value[name]
			if v == nil then
				if not optional[name] then
					table.insert(errors, `{path}.{name}: поле отсутствует`)
				end
			else
				check(child, v, `{path}.{name}`, errors)
			end
		end
		for name in value do
			if typeof(name) ~= "string" then
				table.insert(errors, `{path}: ключ {describe(name)} не строка`)
			elseif string.sub(name, 1, 1) ~= "_" and node.fields[name] == nil then
				table.insert(errors, `{path}.{name}: неизвестное поле (опечатка?)`)
			end
		end
	elseif kind == "map" then
		if typeof(value) ~= "table" then
			table.insert(errors, `{path}: ожидался объект`)
			return
		end
		for k, v in value do
			if typeof(k) == "string" and string.sub(k, 1, 1) == "_" then
				continue
			end
			check(node.key, k, `{path} (ключ)`, errors)
			check(node.value, v, `{path}.{tostring(k)}`, errors)
		end
	else
		table.insert(errors, `{path}: в схеме неизвестный тип {describe(kind)}`)
	end
end

local function resolve(root: any, dotted: string): boolean
	local cur = root
	for part in string.gmatch(dotted, "[^%.]+") do
		if typeof(cur) ~= "table" then
			return false
		end
		cur = cur[part]
		if cur == nil then
			return false
		end
	end
	return true
end

-- Проверяет один конфиг. `name` — имя файла без .json, для сообщений.
function ConfigValidator.validate(name: string, schema: Schema, data: any): Result
	local errors = {}
	local todo = {}
	check(schema, data, name, errors)
	if typeof(data) == "table" then
		local marks = data._TODO_DESIGN
		if marks ~= nil then
			if typeof(marks) ~= "table" or not isArray(marks) then
				table.insert(errors, `{name}._TODO_DESIGN: ожидался список путей`)
			else
				for _, p in marks do
					if typeof(p) ~= "string" or not resolve(data, p) then
						table.insert(errors, `{name}._TODO_DESIGN: путь {describe(p)} не найден`)
					else
						table.insert(todo, `{name}.{p}`)
					end
				end
			end
		end
	end
	return { errors = errors, todo = todo }
end

-- Проверяет все конфиги: и лишние файлы без схемы, и схемы без файла.
function ConfigValidator.validateAll(schemas: { [string]: Schema }, configs: { [string]: any }): Result
	local errors = {}
	local todo = {}
	for name, schema in schemas do
		if configs[name] == nil then
			table.insert(errors, `{name}: нет файла config/{name}.json`)
		else
			local r = ConfigValidator.validate(name, schema, configs[name])
			table.move(r.errors, 1, #r.errors, #errors + 1, errors)
			table.move(r.todo, 1, #r.todo, #todo + 1, todo)
		end
	end
	for name in configs do
		if schemas[name] == nil then
			table.insert(errors, `{name}: нет схемы в rules/ConfigSchema`)
		end
	end
	table.sort(errors)
	table.sort(todo)
	return { errors = errors, todo = todo }
end

return ConfigValidator
