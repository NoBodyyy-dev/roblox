-- TEST_01: ID загруженных текстур -> атрибуты Workspace "Tex_<имя>" = "rbxassetid://<id>".
-- Остальные скрипты читают ID только отсюда. Атрибуты сохраняются в плейсе и видны в Play (сервер и клиент).
-- Запуск: execute_luau в режиме редактирования. Впиши числа (ID изображения/Decal -> Image ID, не Decal ID).

local IDS = {
	-- обязательные для тестов A–H
	T_Palette_Main = 0,
	T_Palette_Worn = 0,
	T_Palette_WeaponSkin_Gold = 0,
	T_Palette_WeaponSkin_Arctic = 0,
	T_VehicleSkin_Test = 0,
	T_Sticker_Flames_01 = 0,
	-- не участвуют в тестах, грузить по желанию
	T_Palette_Armor_State2 = 0,
	T_Palette_Armor_State3 = 0,
	T_Plate_01 = 0,
	T_Glass_Cracked_01 = 0,
}
local REQUIRED = {
	"T_Palette_Main",
	"T_Palette_Worn",
	"T_Palette_WeaponSkin_Gold",
	"T_Palette_WeaponSkin_Arctic",
	"T_VehicleSkin_Test",
	"T_Sticker_Flames_01",
}

for _, name in REQUIRED do
	assert(IDS[name] ~= 0, name .. ": впиши ID")
end
local set = {}
for name, id in IDS do
	if id ~= 0 then
		workspace:SetAttribute("Tex_" .. name, "rbxassetid://" .. id)
		table.insert(set, name .. "=" .. id)
	end
end
table.sort(set)
print("[ids] " .. table.concat(set, " "))
