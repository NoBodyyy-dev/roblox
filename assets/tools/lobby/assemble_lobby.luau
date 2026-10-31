--!strict
-- Style test: сборка Model по контракту ASSETS_PROMPT §6 из импортированных OBJ.
-- Генерируется build_style_test.py (манифесты вшиты ниже). Запуск: Command Bar или MCP execute_luau в режиме Edit.
--
-- Перед запуском: File → Import 3D — assets/source/style_test/<Asset>.obj (три файла), «Rescale if too large» выключить.
-- Импортированные модели могут лежать где угодно в Workspace: скрипт ищет Model с MeshPart по именам частей.
-- Масштаб и поворот импорта не важны: Size и CFrame частей ставятся из манифеста, разворот 180° по Y распознаётся.
-- Результат: Workspace.StyleTest.<Asset> (готовая Model) — её сохраняют в assets/rbxm/<Category>/<Asset>.rbxm.

local HttpService = game:GetService("HttpService")
local AssetService = game:GetService("AssetService")

local MANIFESTS = HttpService:JSONDecode([==[[{"asset": "Lobby_Hub", "category": "Lobby", "primary_part": "Ground", "coords": "Roblox studs; pivot модели = центр основания (0,0,0); перёд −Z; оси (x,y,z)_blender → (−x,z,y)", "attributes": {"AssetId": "Lobby_Hub", "Category": "Lobby", "Tris": 6159}, "tris_visible": 6159, "parts": [{"name": "Ground", "tris": 243, "size": [106.0068, 1.04, 88.0], "center": [1.0034, -0.48, 0.0], "textured": true}, {"name": "Walls", "tris": 2664, "size": [97.8, 8.9213, 81.8], "center": [-0.0, 4.4606, 0.0], "textured": true}, {"name": "Props", "tris": 1872, "size": [85.5565, 9.0, 62.6215], "center": [1.3242, 4.5, 5.1284], "textured": true}, {"name": "Fire", "tris": 24, "size": [2.0909, 3.6, 2.3124], "center": [0.1354, 2.4, -3.9204], "textured": true}, {"name": "Tower", "tris": 432, "size": [6.9736, 21.5451, 7.0], "center": [-40.0, 10.7631, 32.0], "textured": true}, {"name": "Backdrop", "tris": 924, "size": [158.2507, 55.6325, 109.0], "center": [-0.1253, 27.8163, 21.5], "textured": true}], "model_pivot": [-0.0, 0.0, 0.0], "attachments": [{"name": "Campfire", "parent": "Ground", "position": [-0.0, 1.2, -4.0]}, {"name": "Lookout", "parent": "Ground", "position": [-40.0, 16.2, 32.0]}, {"name": "Spawn_1", "parent": "Ground", "position": [12.0, 0.0, -30.0]}, {"name": "Spawn_2", "parent": "Ground", "position": [4.0, 0.0, -30.0]}, {"name": "Spawn_3", "parent": "Ground", "position": [-4.0, 0.0, -30.0]}, {"name": "Spawn_4", "parent": "Ground", "position": [-12.0, 0.0, -30.0]}, {"name": "DoorSlot_Sea", "parent": "Ground", "position": [30.0, 0.0, 40.0]}, {"name": "DoorSlot_City", "parent": "Ground", "position": [-0.0, 0.0, 40.0]}, {"name": "DoorSlot_Mountains", "parent": "Ground", "position": [-30.0, 0.0, 40.0]}, {"name": "Shop", "parent": "Ground", "position": [-38.0, 0.0, 4.0]}, {"name": "Leaderboard_1", "parent": "Ground", "position": [34.0, 0.0, -32.0]}, {"name": "Leaderboard_2", "parent": "Ground", "position": [20.0, 0.0, -32.0]}, {"name": "Leaderboard_3", "parent": "Ground", "position": [6.0, 0.0, -32.0]}], "colliders": [{"center": [44.0, 4.5, 40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [38.8, 4.5, 40.0], "size": [2.4, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [18.4, 4.5, 40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [11.0, 4.5, 40.0], "size": [6.8, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-11.6, 4.5, 40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-19.0, 4.5, 40.0], "size": [6.8, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-41.6, 4.5, 40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-46.8, 4.5, 40.0], "size": [2.4, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [44.0, 4.5, -40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [36.0, 4.5, -40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [28.0, 4.5, -40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [20.0, 4.5, -40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [12.0, 4.5, -40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [4.0, 4.5, -40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-4.0, 4.5, -40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-12.0, 4.5, -40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-20.0, 4.5, -40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-28.0, 4.5, -40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-36.0, 4.5, -40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-44.0, 4.5, -40.0], "size": [8.0, 9.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-48.0, 4.5, -36.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-48.0, 4.5, -28.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-48.0, 4.5, -20.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-48.0, 4.5, -12.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-48.0, 4.5, -4.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-48.0, 4.5, 4.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-48.0, 4.5, 12.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-48.0, 4.5, 20.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-48.0, 4.5, 28.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-48.0, 4.5, 36.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [48.0, 4.5, -36.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [48.0, 4.5, -28.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [48.0, 4.5, -20.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [48.0, 4.5, -12.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [48.0, 4.5, -4.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [48.0, 4.5, 4.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [48.0, 4.5, 12.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [48.0, 4.5, 20.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [48.0, 4.5, 28.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [48.0, 4.5, 36.0], "size": [1.6, 9.0, 8.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-0.0, 0.6, -4.0], "size": [5.5, 1.2, 5.5], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [36.0, 2.0, 10.0], "size": [6.0, 4.0, 6.0], "rot": [0.17365, 0.0, 0.98481, 0.0, 1.0, 0.0, -0.98481, 0.0, 0.17365]}, {"center": [36.0, 2.0, -6.0], "size": [6.0, 4.0, 6.0], "rot": [-0.17365, 0.0, 0.98481, 0.0, 1.0, 0.0, -0.98481, 0.0, -0.17365]}, {"center": [26.0, 2.0, 24.0], "size": [6.0, 4.0, 6.0], "rot": [0.86603, 0.0, 0.5, 0.0, 1.0, 0.0, -0.5, 0.0, 0.86603]}, {"center": [-30.1622, 1.2, -1.5038], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-28.8325, 1.2, -17.7731], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [27.5259, 1.2, 6.9024], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-33.861, 1.2, -13.0798], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-30.1916, 1.2, 1.8944], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-32.5778, 1.2, 15.0708], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [36.8172, 1.2, 17.1167], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [41.566, 1.2, 1.7001], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [37.3762, 1.2, 17.1282], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [28.8409, 1.2, 10.6654], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [27.4116, 1.2, 24.9214], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-27.8913, 1.2, -25.5819], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [38.6117, 1.2, -22.3031], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [42.9019, 1.2, -13.0663], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-31.9163, 1.2, -20.7057], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-39.1626, 1.2, -20.9775], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [41.7024, 1.2, 31.3723], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-40.6207, 1.2, -18.8199], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [38.6726, 1.2, -8.6689], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-27.9726, 1.2, 2.0952], "size": [3.0, 2.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-24.0, 1.2, 30.0], "size": [3.2, 2.4, 2.2], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-15.0, 0.6, 33.5], "size": [6.0, 1.2, 2.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-40.0, 8.0, 32.0], "size": [5.0, 16.0, 5.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-40.0, 16.2, 32.0], "size": [6.0, 0.4, 6.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-0.0, -0.5, 0.0], "size": [104.0, 1.0, 88.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}], "studio_props": {"Ground": {"CanCollide": false}, "Walls": {"CanCollide": false, "CanTouch": false, "CanQuery": false}, "Props": {"CanCollide": false, "CanTouch": false, "CanQuery": false}, "Fire": {"CanCollide": false, "CanTouch": false, "CanQuery": false, "Material": "Neon"}, "Tower": {"CanCollide": false, "CanTouch": false, "CanQuery": false}, "Backdrop": {"CanCollide": false, "CanTouch": false, "CanQuery": false, "CastShadow": false}}, "uv": {"Ground": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "Walls": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "Props": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "Fire": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "Tower": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "Backdrop": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}}, "palette_image_id": "75482071682779 (T_Palette_Main, группа «Грева нет» 867558223)", "place_at": [0.0, 0.0, 300.0]}, {"asset": "Lobby_Door_Sea", "category": "Lobby", "primary_part": "Frame", "coords": "Roblox studs; pivot модели = центр основания (0,0,0); перёд −Z; оси (x,y,z)_blender → (−x,z,y)", "attributes": {"AssetId": "Lobby_Door_Sea", "Category": "Lobby", "Tris": 640, "Region": "Sea", "OpenByDefault": false}, "tris_visible": 640, "parts": [{"name": "Frame", "tris": 144, "size": [18.3506, 14.9159, 1.95], "center": [-0.0, 7.3421, 0.075], "textured": true, "src": "GateSea__Frame"}, {"name": "Door", "tris": 216, "size": [12.3, 10.0, 0.575], "center": [0.15, 5.3, -0.0375], "textured": true, "pivot_offset": [5.85, 0.0, 0.0375], "src": "GateSea__Door"}, {"name": "Sign", "tris": 124, "size": [7.6, 3.2, 0.5], "center": [-0.0, 15.4, -0.75], "textured": true, "src": "GateSea__Sign"}, {"name": "Lock", "tris": 156, "size": [10.2167, 8.1664, 0.55], "center": [-0.0, 5.3, -0.625], "textured": true, "src": "GateSea__Lock"}], "model_pivot": [-0.0, 0.0, 0.0], "attachments": [{"name": "Entrance", "parent": "Frame", "position": [-0.0, 0.0, -5.0]}], "colliders": [], "studio_props": {"Frame": {"CollisionFidelity": "Box"}, "Door": {"CanCollide": true, "CollisionFidelity": "Box"}, "Sign": {"CanCollide": false, "CanTouch": false, "CanQuery": false}, "Lock": {"CanCollide": false, "CanTouch": false, "CanQuery": false}}, "uv": {"GateSea__Frame": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "GateSea__Door": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "GateSea__Sign": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "GateSea__Lock": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}}, "palette_image_id": "75482071682779 (T_Palette_Main, группа «Грева нет» 867558223)", "place_at": [30.0, 0.0, 340.0]}, {"asset": "Lobby_Door_City", "category": "Lobby", "primary_part": "Frame", "coords": "Roblox studs; pivot модели = центр основания (0,0,0); перёд −Z; оси (x,y,z)_blender → (−x,z,y)", "attributes": {"AssetId": "Lobby_Door_City", "Category": "Lobby", "Tris": 744, "Region": "City", "OpenByDefault": true}, "tris_visible": 744, "parts": [{"name": "Frame", "tris": 144, "size": [18.3506, 14.9159, 1.95], "center": [-0.0, 7.3421, 0.075], "textured": true, "src": "GateCity__Frame"}, {"name": "Door", "tris": 216, "size": [12.3, 10.0, 0.575], "center": [0.15, 5.3, -0.0375], "textured": true, "pivot_offset": [5.85, 0.0, 0.0375], "src": "GateCity__Door"}, {"name": "Sign", "tris": 228, "size": [7.6, 3.2, 0.485], "center": [-0.0, 15.4, -0.7425], "textured": true, "src": "GateCity__Sign"}, {"name": "Lock", "tris": 156, "size": [10.2167, 8.1664, 0.55], "center": [-0.0, 5.3, -0.625], "textured": true, "src": "GateCity__Lock"}], "model_pivot": [-0.0, 0.0, 0.0], "attachments": [{"name": "Entrance", "parent": "Frame", "position": [-0.0, 0.0, -5.0]}], "colliders": [], "studio_props": {"Frame": {"CollisionFidelity": "Box"}, "Door": {"CanCollide": true, "CollisionFidelity": "Box"}, "Sign": {"CanCollide": false, "CanTouch": false, "CanQuery": false}, "Lock": {"CanCollide": false, "CanTouch": false, "CanQuery": false}}, "uv": {"GateCity__Frame": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "GateCity__Door": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "GateCity__Sign": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "GateCity__Lock": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}}, "palette_image_id": "75482071682779 (T_Palette_Main, группа «Грева нет» 867558223)", "place_at": [0.0, 0.0, 340.0]}, {"asset": "Lobby_Door_Mountains", "category": "Lobby", "primary_part": "Frame", "coords": "Roblox studs; pivot модели = центр основания (0,0,0); перёд −Z; оси (x,y,z)_blender → (−x,z,y)", "attributes": {"AssetId": "Lobby_Door_Mountains", "Category": "Lobby", "Tris": 584, "Region": "Mountains", "OpenByDefault": false}, "tris_visible": 584, "parts": [{"name": "Frame", "tris": 144, "size": [18.3506, 14.9159, 1.95], "center": [-0.0, 7.3421, 0.075], "textured": true, "src": "GateMountains__Frame"}, {"name": "Door", "tris": 216, "size": [12.3, 10.0, 0.575], "center": [0.15, 5.3, -0.0375], "textured": true, "pivot_offset": [5.85, 0.0, 0.0375], "src": "GateMountains__Door"}, {"name": "Sign", "tris": 68, "size": [7.6, 3.2, 0.55], "center": [-0.0, 15.4, -0.775], "textured": true, "src": "GateMountains__Sign"}, {"name": "Lock", "tris": 156, "size": [10.2167, 8.1664, 0.55], "center": [-0.0, 5.3, -0.625], "textured": true, "src": "GateMountains__Lock"}], "model_pivot": [-0.0, 0.0, 0.0], "attachments": [{"name": "Entrance", "parent": "Frame", "position": [-0.0, 0.0, -5.0]}], "colliders": [], "studio_props": {"Frame": {"CollisionFidelity": "Box"}, "Door": {"CanCollide": true, "CollisionFidelity": "Box"}, "Sign": {"CanCollide": false, "CanTouch": false, "CanQuery": false}, "Lock": {"CanCollide": false, "CanTouch": false, "CanQuery": false}}, "uv": {"GateMountains__Frame": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "GateMountains__Door": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "GateMountains__Sign": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "GateMountains__Lock": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}}, "palette_image_id": "75482071682779 (T_Palette_Main, группа «Грева нет» 867558223)", "place_at": [-30.0, 0.0, 340.0]}]]==])
local PALETTE_TEXTURE = "rbxassetid://75482071682779" -- T_Palette_Main, группа «Грева нет» (867558223)
local SPACING = 40

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function findImport(asset: any): Model?
	local wanted = {}
	for _, p in asset.parts do
		if p.name ~= "Collider" then
			wanted[p.src or p.name] = true -- src: имя группы в OBJ, если оно не совпадает с именем части
		end
	end
	local best, bestHits = nil, 0
	local done = workspace:FindFirstChild("Lobby")
	for _, m in workspace:GetDescendants() do
		if m:IsA("Model") and not (done and m:IsDescendantOf(done)) then
			local hits = 0
			for _, d in m:GetDescendants() do
				if d:IsA("MeshPart") and wanted[d.Name] then
					hits += 1
				end
			end
			if hits > bestHits then
				best, bestHits = m, hits
			end
		end
	end
	return best
end

local function findPart(m: Instance, name: string): MeshPart?
	for _, d in m:GetDescendants() do
		if d:IsA("MeshPart") and d.Name == name then
			return d
		end
	end
	return nil
end

-- Импорт OBJ в TEST_01 обращал X и Z (поворот 180° по Y). Проверяем по двум самым удалённым частям.
local function detectFlip(asset: any, src: Model): boolean
	local a, b, dmax = nil, nil, 0
	for i, p in asset.parts do
		for j = i + 1, #asset.parts do
			local q = asset.parts[j]
			local d = (v3(p.center) - v3(q.center)) * Vector3.new(1, 0, 1)
			if d.Magnitude > dmax and findPart(src, p.src or p.name) and findPart(src, q.src or q.name) then
				a, b, dmax = p, q, d.Magnitude
			end
		end
	end
	if not a or dmax < 1 then
		return false
	end
	local pa, pb = findPart(src, a.src or a.name) :: MeshPart, findPart(src, b.src or b.name) :: MeshPart
	local imported = (pb.Position - pa.Position) * Vector3.new(1, 0, 1)
	local expected = (v3(b.center) - v3(a.center)) * Vector3.new(1, 0, 1)
	return imported:Dot(expected) < 0
end

local function apply(part: BasePart, props: any)
	for k, v in props do
		if k == "Color" then
			part.Color = Color3.fromRGB(v[1], v[2], v[3])
		elseif k == "Material" then
			part.Material = (Enum.Material :: any)[v]
		elseif k == "CollisionFidelity" then
			continue -- задаётся при создании меша (см. ApplyMesh); у обычного Part свойства нет
		else
			(part :: any)[k] = v
		end
	end
end

local root = workspace:FindFirstChild("Lobby") or Instance.new("Folder")
root.Name = "Lobby"
root.Parent = workspace

local log = {}
for i, asset in MANIFESTS do
	local src = findImport(asset)
	if not src then
		table.insert(log, asset.asset .. ": импорт не найден")
		continue
	end
	local old = root:FindFirstChild(asset.asset)
	if old then
		old:Destroy()
	end
	local flip = detectFlip(asset, src)
	local fix = flip and CFrame.Angles(0, math.pi, 0) or CFrame.identity
	local origin = asset.place_at and CFrame.new(v3(asset.place_at)) or CFrame.new((i - 2) * SPACING, 0, 0)
	local model = Instance.new("Model")
	model.Name = asset.asset
	local defaults = asset.studio_props["*"] or {}
	local made: { [string]: BasePart } = {}
	local scaleNote = {}
	for _, p in asset.parts do
		local part: BasePart
		local srcPart = findPart(src, p.src or p.name)
		if p.name == "Collider" or not srcPart then
			if p.name ~= "Collider" then
				table.insert(log, asset.asset .. ": нет части " .. p.name)
				continue
			end
			local c = Instance.new("Part")
			c.Name = "Collider"
			c.Size = v3(p.size)
			part = c
		else
			local mp = (srcPart :: MeshPart):Clone()
			local want = v3(p.size)
			local ratio = mp.Size.Magnitude / want.Magnitude
			if math.abs(ratio - 1) > 0.02 then
				table.insert(scaleNote, string.format("%s ×%.3f", p.name, ratio))
			end
			-- CollisionFidelity из скрипта присваиванием не меняется (Studio молча оставляет Default):
			-- берём меш через AssetService с нужной fidelity и переносим его в часть через ApplyMesh
			local fidelity = (asset.studio_props[p.name] or {}).CollisionFidelity or defaults.CollisionFidelity or "Box"
			local okMesh, fresh = pcall(function()
				return AssetService:CreateMeshPartAsync(Content.fromUri(mp.MeshId), {
					CollisionFidelity = (Enum.CollisionFidelity :: any)[fidelity],
					RenderFidelity = Enum.RenderFidelity.Automatic,
				})
			end)
			if okMesh and fresh then
				mp:ApplyMesh(fresh)
				fresh:Destroy()
			else
				table.insert(log, asset.asset .. ": CollisionFidelity не задан у " .. p.name .. ": " .. tostring(fresh))
			end
			mp.Size = want
			mp.DoubleSided = false
			mp.TextureID = p.textured and PALETTE_TEXTURE or ""
			mp.Color = Color3.new(1, 1, 1)
			mp.Material = Enum.Material.SmoothPlastic
			for _, d in mp:GetChildren() do
				d:Destroy() -- SurfaceAppearance/скрипты из импорта не нужны
			end
			part = mp
		end
		part.Anchored = true
		part.CFrame = origin * CFrame.new(v3(p.center)) * fix
		-- импортёр ставит PivotOffset в начало координат исходной модели: сбрасываем на центр части
		part.PivotOffset = p.pivot_offset and fix:Inverse() * CFrame.new(v3(p.pivot_offset)) or CFrame.identity
		apply(part, defaults)
		apply(part, asset.studio_props[p.name] or {})
		part.Parent = model
		made[p.name] = part
	end
	for n, c in asset.colliders do
		local r = c.rot
		local cp = Instance.new("Part")
		cp.Name = "Collider_" .. n
		cp.Size = v3(c.size)
		cp.CFrame = origin * CFrame.new(c.center[1], c.center[2], c.center[3], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		cp.Anchored = true
		cp.Transparency = 1
		cp.CanCollide = true
		cp.CanTouch = false
		cp.CanQuery = true
		cp.CastShadow = false
		cp.Parent = model
	end
	for _, a in asset.attachments do
		local parent = made[a.parent]
		if parent then
			local att = Instance.new("Attachment")
			att.Name = a.name
			att.Parent = parent -- сначала родитель: без него WorldCFrame пишется как локальный CFrame
			att.WorldCFrame = origin * CFrame.new(v3(a.position))
		end
	end
	-- при заданном PrimaryPart pivot модели = pivot PrimaryPart: ставим его в точку pivot модели из манифеста
	-- (центр основания; у варианта колеса — ось)
	local primary = made[asset.primary_part]
	local modelPivot = origin * CFrame.new(v3(asset.model_pivot or { 0, 0, 0 }))
	primary.PivotOffset = primary.CFrame:ToObjectSpace(modelPivot)
	model.PrimaryPart = primary
	model.WorldPivot = modelPivot
	for k, v in asset.attributes do
		model:SetAttribute(k, v)
	end
	model.Parent = root
	table.insert(log, string.format("%s: частей %d, коллайдеров %d, attachments %d, Tris %d, разворот импорта %s%s",
		asset.asset, #asset.parts, #asset.colliders, #asset.attachments, asset.attributes.Tris,
		flip and "180°" or "нет", #scaleNote > 0 and (", масштаб импорта исправлен: " .. table.concat(scaleNote, ", ")) or ""))
end
print("StyleTest assemble:\n" .. table.concat(log, "\n"))
return table.concat(log, "\n")
