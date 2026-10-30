-- TEST_01: убрать из тестового плейса всё, что создали тесты E, F, H (§8: «после теста удали их из плейса»).
-- Стенд, импортированные меши и атрибуты Tex_* остаются — они нужны для повторных тестов.
-- Запуск: execute_luau в режиме редактирования (после остановки Play).

local removed = {}
local function kill(inst)
	if inst then
		table.insert(removed, inst:GetFullName())
		inst:Destroy()
	end
end

for _, name in { "TestE", "TestF", "TestBox_Server", "TestBox_Server_SA", "TestBox_Client", "TestBox_Client_SA" } do
	kill(workspace:FindFirstChild(name))
end
kill(game:GetService("ReplicatedStorage"):FindFirstChild("TestH_SA_Alt"))
kill(game:GetService("ServerScriptService"):FindFirstChild("TestH_Server"))
kill(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("TestH_Client"))
for name in workspace:GetAttributes() do
	if name:sub(1, 6) == "TestH_" then
		workspace:SetAttribute(name, nil)
		table.insert(removed, "attr " .. name)
	end
end

print("[cleanup] " .. (#removed > 0 and table.concat(removed, ", ") or "нечего удалять"))
