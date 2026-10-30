-- TEST_01, тест H, сервер. Script "TestH_Server" в ServerScriptService (вставить до Play).
-- Шаги идут сами каждые STEP_DELAY секунд, если workspace.TestH_Auto = true (ставит H_prepare.luau),
-- или по одному: workspace:SetAttribute("TestH_ServerStep", n) из серверного контекста.
-- Результат шага: print + атрибут workspace.TestH_S<n> (реплицируется, его показывает HUD клиента).
-- «OK» = свойство установилось без ошибки. Виден ли результат клиенту — по HUD и screen_capture.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STEP_DELAY = 8

local box = workspace:WaitForChild("TestBox_Server")
local boxSA = workspace:WaitForChild("TestBox_Server_SA")

local function tex(name)
	return workspace:GetAttribute("Tex_" .. name)
end

local STEPS = {
	{ "1 TextureID -> Worn", function()
		box.TextureID = tex("T_Palette_Worn")
	end },
	{ "2 Color -> красный", function()
		box.Color = Color3.fromRGB(255, 0, 0)
	end },
	{ "3a SA.ColorMap -> Worn", function()
		boxSA:FindFirstChildOfClass("SurfaceAppearance").ColorMap = tex("T_Palette_Worn")
	end },
	{ "3b SA.Color -> синий", function()
		(boxSA:FindFirstChildOfClass("SurfaceAppearance") :: any).Color = Color3.fromRGB(0, 0, 255)
	end },
	{ "4 SA удалить + копия из ReplicatedStorage", function()
		boxSA:FindFirstChildOfClass("SurfaceAppearance"):Destroy()
		local copy = ReplicatedStorage:WaitForChild("TestH_SA_Alt"):Clone()
		copy.Name = "SurfaceAppearance"
		copy.Parent = boxSA
	end },
}

local function run(n)
	local step = STEPS[n]
	if not step then
		return
	end
	local ok, err = pcall(step[2])
	local res = ok and "OK" or ("ОШИБКА: " .. tostring(err))
	print(("[TestH][server] %s: %s"):format(step[1], res))
	workspace:SetAttribute(("TestH_S%d"):format(n), step[1] .. ": " .. res)
end

workspace:GetAttributeChangedSignal("TestH_ServerStep"):Connect(function()
	run(workspace:GetAttribute("TestH_ServerStep"))
end)

if workspace:GetAttribute("TestH_Auto") then
	task.wait(STEP_DELAY)
	for n = 1, #STEPS do
		run(n)
		task.wait(STEP_DELAY)
	end
	workspace:SetAttribute("TestH_ServerDone", true)
end
