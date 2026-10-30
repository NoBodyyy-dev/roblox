-- TEST_01: камера на заданной дальности, почти перпендикулярно грани. Используется в A–G.
-- Запуск: execute_luau в режиме редактирования; меняй параметры и запускай снова перед каждым screen_capture.

local TARGETS = { "TestPaletteBox" } -- имена в Workspace (ищутся рекурсивно), рамка — по всем сразу
local FACE = Vector3.new(1, 0, 0) -- нормаль грани в мире: +X (1,0,0), -X, +Y, -Y, +Z (0,0,1), -Z
local DIST = 50 -- от центра объекта, studs: 50 / 200 / 500 / 1000
local TILT = 0.03 -- лёгкий сдвиг «почти перпендикулярно» (доля DIST)
local FOV = 70

local lo, hi
for _, name in TARGETS do
	local inst = workspace:FindFirstChild(name, true)
	assert(inst, name .. " не найден в Workspace")
	local cf, size
	if inst:IsA("BasePart") then
		cf, size = inst.CFrame, inst.Size
	else
		cf, size = inst:GetBoundingBox()
	end
	local a, b = cf.Position - size / 2, cf.Position + size / 2
	lo = lo and lo:Min(a) or a
	hi = hi and hi:Max(b) or b
end
local center = (lo + hi) / 2

local n = FACE.Unit
local side = math.abs(n.Y) > 0.9 and Vector3.new(1, 0, 0) or Vector3.new(0, 1, 0)
local eye = center + n * DIST + side * DIST * TILT
local up = math.abs(n.Y) > 0.9 and Vector3.new(0, 0, -1) or Vector3.new(0, 1, 0)

-- снизу (-Y) камера оказалась бы под полом: временно прячем пол
local ground = workspace:FindFirstChild("TestStand_Ground")
if ground then
	ground.Transparency = n.Y < -0.5 and 1 or 0
end

local cam = workspace.CurrentCamera
cam.FieldOfView = FOV
cam.CFrame = CFrame.lookAt(eye, center, up)
cam.Focus = CFrame.new(center)

local px = workspace.CurrentCamera.ViewportSize
print(("[camera] %s, грань %s, дальность %d, объект %.1f×%.1f×%.1f, окно %dx%d"):format(
	table.concat(TARGETS, "+"), tostring(FACE), DIST, hi.X - lo.X, hi.Y - lo.Y, hi.Z - lo.Z, px.X, px.Y
))
