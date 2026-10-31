
-- ---------------------------------------------------------------- живой костёр (дописывается в assemble_lobby.luau)
-- Частицы и свет на Attachment Campfire хаба. Текстуры встроенные (rbxasset://), загрузка не нужна.
-- Скриптов нет: мерцание света (Brightness/Range по шуму) — код Разработчика, если нужно.
do
	local hub = workspace.Lobby:FindFirstChild("Lobby_Hub")
	local att = hub and hub:FindFirstChild("Campfire", true)
	if att then
		for _, d in att:GetChildren() do
			d:Destroy()
		end
		local function emitter(name: string, props: { [string]: any })
			local e = Instance.new("ParticleEmitter")
			e.Name = name
			for k, v in props do
				(e :: any)[k] = v
			end
			e.Parent = att
		end
		emitter("Flames", {
			Texture = "rbxasset://textures/particles/fire_main.dds",
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 214, 120)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 40)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 40, 20)),
			}),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.2), NumberSequenceKeypoint.new(1, 0.4) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(0.5, 0.9),
			Rate = 30,
			Speed = NumberRange.new(3, 5),
			SpreadAngle = Vector2.new(12, 12),
			RotSpeed = NumberRange.new(-60, 60),
			Rotation = NumberRange.new(0, 360),
			LightEmission = 0.9,
			ZOffset = 0.5,
		})
		emitter("Embers", {
			Texture = "rbxasset://textures/particles/sparkles_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(255, 160, 60)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0.05) }),
			Lifetime = NumberRange.new(1.2, 2.2),
			Rate = 8,
			Speed = NumberRange.new(4, 8),
			SpreadAngle = Vector2.new(25, 25),
			Acceleration = Vector3.new(0.6, -1, 0.3),
			LightEmission = 1,
		})
		emitter("Smoke", {
			Texture = "rbxasset://textures/particles/smoke_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(70, 66, 62)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 7) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(4, 6),
			Rate = 4,
			Speed = NumberRange.new(3, 5),
			SpreadAngle = Vector2.new(10, 10),
			Acceleration = Vector3.new(0.8, 0.4, 0.3), -- ветер сносит дым
			RotSpeed = NumberRange.new(-20, 20),
			Rotation = NumberRange.new(0, 360),
		})
		local light = Instance.new("PointLight")
		light.Name = "FireLight"
		light.Color = Color3.fromRGB(255, 150, 70)
		light.Brightness = 2.5
		light.Range = 26
		light.Shadows = true
		light.Parent = att
	end
end
