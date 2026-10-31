--!strict
-- Все проверки перед PR (AGENT_PROMPT §3 п. 4): `lune run check`.
-- stylua --check, selene, luau-lsp analyze (типы Roblox скачиваются в .luau-lsp/ при первом запуске), конфиги.
-- Юнит-тесты Jest идут в Studio: см. docs/dev.md.
local fs = require("@lune/fs")
local process = require("@lune/process")

local TYPES = ".luau-lsp/globalTypes.d.luau"
local TYPES_URL = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau"

local failed = {}

local function run(label: string, program: string, args: { string })
	print(`\n== {label}`)
	local result = process.exec(program, args, { stdio = "forward" })
	if not result.ok then
		table.insert(failed, label)
	end
end

if not fs.isFile(TYPES) then
	local net = require("@lune/net")
	if not fs.isDir(".luau-lsp") then
		fs.writeDir(".luau-lsp")
	end
	local response = net.request(TYPES_URL)
	assert(response.ok, `не скачались типы Roblox: {response.statusCode}`)
	fs.writeFile(TYPES, response.body)
end

run("stylua", "stylua", { "--check", "src", "tests", ".lune" })
run("selene", "selene", { "src", "tests", ".lune" })
run("sourcemap", "rojo", { "sourcemap", "default.project.json", "-o", "sourcemap.json", "--include-non-scripts" })
run("luau-lsp", "luau-lsp", {
	"analyze",
	`--defs={TYPES}`,
	"--sourcemap=sourcemap.json",
	"--ignore=Packages/**",
	"--ignore=ServerPackages/**",
	"--ignore=DevPackages/**",
	"src",
	"tests",
})
run("конфиги", "lune", { "run", "validate-config" })

print(if #failed == 0 then "\nВсё чисто." else `\nНе прошло: {table.concat(failed, ", ")}`)
process.exit(#failed == 0 and 0 or 1)
