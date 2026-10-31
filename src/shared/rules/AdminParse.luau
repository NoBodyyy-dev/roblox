--!strict
-- Разбор текста админ-команды: "/time 18.5" → "time", { "18.5" }. Чистая логика.

local AdminParse = {}

function AdminParse.split(text: string): (string?, { string })
	local words = {}
	for w in string.gmatch(text, "%S+") do
		table.insert(words, w)
	end
	local head = table.remove(words, 1)
	if head == nil then
		return nil, words
	end
	head = string.lower((string.gsub(head, "^/", "")))
	return if head == "" then nil else head, words
end

-- Число из аргумента в пределах [min, max]; nil, если не число или вне пределов
function AdminParse.number(arg: string?, min: number, max: number): number?
	local n = if arg then tonumber(arg) else nil
	if n == nil or n ~= n or n < min or n > max then
		return nil
	end
	return n
end

return AdminParse
