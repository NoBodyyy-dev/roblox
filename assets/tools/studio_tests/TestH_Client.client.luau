-- TEST_01, тест H, клиент. LocalScript "TestH_Client" в StarterPlayer.StarterPlayerScripts (вставить до Play).
-- 1) Те же шаги, что на сервере, но на TestBox_Client / TestBox_Client_SA (видит ли сам клиент изменение).
--    Идут сами со сдвигом STEP_OFFSET после серверных, если workspace.TestH_Auto = true,
--    или по одному: workspace:SetAttribute("TestH_ClientStep", n).
-- 2) HUD (TextLabel): результаты сервера, что клиент реально видит у серверных кубов (репликация),
--    результаты клиента. Работает и без чтения консоли — снимай screen_capture.
-- 3) Камера фиксируется на четырёх кубах, чтобы скриншоты Play были одинаковыми.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local STEP_DELAY = 8
local STEP_OFFSET = 4 -- клиентский шаг n идёт через 4 с после серверного шага n

local box = workspace:WaitForChild("TestBox_Client")
local boxSA = workspace:WaitForChild("TestBox_Client_SA")
local serverBox = workspace:WaitForChild("TestBox_Server")
local serverBoxSA = workspace:WaitForChild("TestBox_Server_SA")

local function tex(name)
	return workspace:GetAttribute("Tex_" .. name)
end

local clientResults = {}

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
	print(("[TestH][client] %s: %s"):format(step[1], res))
	clientResults[n] = step[1] .. ": " .. res
end

-- HUD
local gui = Instance.new("ScreenGui")
gui.Name = "TestH_HUD"
gui.ResetOnSpawn = false
local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(640, 380)
label.Position = UDim2.fromOffset(10, 10)
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.BackgroundTransparency = 0.25
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.Code
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.TextWrapped = true
label.Parent = gui
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local function read(fn)
	local ok, v = pcall(fn)
	if not ok then
		return "ошибка чтения: " .. tostring(v)
	end
	if typeof(v) == "Color3" then
		return ("%d,%d,%d"):format(math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5))
	end
	return tostring(v)
end

local function saOf(part)
	return part:FindFirstChildOfClass("SurfaceAppearance")
end

local function render()
	local lines = {
		("ТЕСТ H   t=%.0f с   IsServer=%s IsClient=%s"):format(
			workspace.DistributedGameTime, tostring(RunService:IsServer()), tostring(RunService:IsClient())
		),
		"",
		"СЕРВЕР, результат установки:",
	}
	for n = 1, #STEPS do
		local v = workspace:GetAttribute(("TestH_S%d"):format(n))
		table.insert(lines, "  " .. (v or ("%d ещё не выполнен"):format(n)))
	end
	table.insert(lines, "")
	table.insert(lines, "КЛИЕНТ ВИДИТ У СЕРВЕРНЫХ КУБОВ (репликация):")
	table.insert(lines, "  TestBox_Server.TextureID = " .. read(function()
		return serverBox.TextureID
	end))
	table.insert(lines, "  TestBox_Server.Color = " .. read(function()
		return serverBox.Color
	end))
	local sa = saOf(serverBoxSA)
	table.insert(lines, "  TestBox_Server_SA: SA = " .. (sa and sa.Name or "нет"))
	if sa then
		table.insert(lines, "    ColorMap = " .. read(function()
			return sa.ColorMap
		end))
		table.insert(lines, "    Color = " .. read(function()
			return (sa :: any).Color
		end))
	end
	table.insert(lines, "")
	table.insert(lines, "КЛИЕНТ, свои кубы:")
	for n = 1, #STEPS do
		table.insert(lines, "  " .. (clientResults[n] or ("%d ещё не выполнен"):format(n)))
	end
	label.Text = table.concat(lines, "\n")
end

-- Камера на четырёх кубах (вид сверху-спереди: видны грани +Y sand_08 и +Z weapon_steel)
local cam = workspace.CurrentCamera
cam.CameraType = Enum.CameraType.Scriptable
cam.CFrame = CFrame.lookAt(Vector3.new(0, 16, serverBox.Position.Z + 34), Vector3.new(0, 2, serverBox.Position.Z))

workspace:GetAttributeChangedSignal("TestH_ClientStep"):Connect(function()
	run(workspace:GetAttribute("TestH_ClientStep"))
end)

task.spawn(function()
	while true do
		render()
		task.wait(0.5)
	end
end)

if workspace:GetAttribute("TestH_Auto") then
	task.wait(STEP_DELAY + STEP_OFFSET)
	for n = 1, #STEPS do
		run(n)
		task.wait(STEP_DELAY)
	end
end
