--!strict
-- Style test: проверка собранных моделей по манифестам (генерируется build_style_test.py, манифесты вшиты).
-- Каждая Model из Workspace.StyleTest сериализуется и десериализуется (как .rbxm), pivot модели — в начало координат,
-- затем сверяются: PrimaryPart, атрибуты, части, мировые позиции attachments и pivot частей, CollisionFidelity,
-- отсутствие скриптов, Anchored, контракт Body (TextureID пустой, цвет белый).

local HttpService = game:GetService("HttpService")
local SS = game:GetService("SerializationService")
local MANIFESTS = HttpService:JSONDecode([==[[{"asset": "House_Small_01", "category": "Buildings", "primary_part": "Shell", "coords": "Roblox studs; pivot модели = центр основания (0,0,0); перёд −Z; оси (x,y,z)_blender → (−x,z,y)", "attributes": {"AssetId": "House_Small_01", "Category": "Buildings", "Tris": 3177}, "tris_visible": 3177, "parts": [{"name": "Shell", "tris": 3131, "size": [21.3396, 18.2107, 26.5962], "center": [1.0262, 8.9185, -2.0981], "textured": true}, {"name": "Door_1", "tris": 46, "size": [3.9, 7.95, 0.64], "center": [-0.0, 4.6, -9.7], "textured": true, "pivot_offset": [1.95, 0.0, 0.0]}], "model_pivot": [-0.0, 0.0, 0.0], "attachments": [{"name": "Entrance_1", "parent": "Shell", "position": [-0.0, 0.35, -10.9]}, {"name": "Loot_1", "parent": "Shell", "position": [5.5, 0.6, 6.5]}, {"name": "Loot_2", "parent": "Shell", "position": [-5.5, 0.6, -6.5]}, {"name": "Loot_3", "parent": "Shell", "position": [-5.0, 0.6, 7.0]}, {"name": "ZombieSpawn_1", "parent": "Shell", "position": [3.0, 0.6, 4.0]}, {"name": "SurvivorSpawn_1", "parent": "Shell", "position": [-3.0, 0.6, 2.0]}], "colliders": [{"center": [7.25, 5.8, -9.7], "size": [1.5, 10.4, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [5.0, 2.1, -9.7], "size": [3.0, 3.0, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [5.0, 9.3, -9.7], "size": [3.0, 3.4, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [2.75, 5.8, -9.7], "size": [1.5, 10.4, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-0.0, 9.8, -9.7], "size": [4.0, 2.4, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-2.75, 5.8, -9.7], "size": [1.5, 10.4, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-5.0, 2.1, -9.7], "size": [3.0, 3.0, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-5.0, 9.3, -9.7], "size": [3.0, 3.4, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-7.25, 5.8, -9.7], "size": [1.5, 10.4, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [4.75, 5.8, 9.7], "size": [6.5, 10.4, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-0.0, 2.1, 9.7], "size": [3.0, 3.0, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-0.0, 9.3, 9.7], "size": [3.0, 3.4, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-4.75, 5.8, 9.7], "size": [6.5, 10.4, 0.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-7.7, 5.8, -7.95], "size": [0.6, 10.4, 2.9], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-7.7, 2.1, -5.0], "size": [0.6, 3.0, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-7.7, 9.3, -5.0], "size": [0.6, 3.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-7.7, 5.8, -0.25], "size": [0.6, 10.4, 6.5], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-7.7, 2.1, 4.5], "size": [0.6, 3.0, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-7.7, 9.3, 4.5], "size": [0.6, 3.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-7.7, 5.8, 7.7], "size": [0.6, 10.4, 3.4], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [7.7, 5.8, -7.95], "size": [0.6, 10.4, 2.9], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [7.7, 2.1, -5.0], "size": [0.6, 3.0, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [7.7, 9.3, -5.0], "size": [0.6, 3.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [7.7, 5.8, -2.55], "size": [0.6, 10.4, 1.9], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [7.7, 7.7, -0.1], "size": [0.6, 6.6, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [7.7, 5.8, 2.2], "size": [0.6, 10.4, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [7.7, 2.1, 4.5], "size": [0.6, 3.0, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [7.7, 9.3, 4.5], "size": [0.6, 3.4, 3.0], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [7.7, 5.8, 7.7], "size": [0.6, 10.4, 3.4], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-0.0, 0.3, 0.0], "size": [16.6, 0.6, 20.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [1.3, 0.175, -10.9], "size": [2.4, 0.35, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-1.25, 0.175, -10.9], "size": [2.5, 0.35, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}, {"center": [-4.606, 13.3571, -4.0], "size": [10.6132, 0.4, 14.0], "rot": [0.848, -0.53, 0.0, 0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [-1.231, 15.4665, 4.0], "size": [2.6533, 0.4, 2.0], "rot": [0.848, -0.53, 0.0, 0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [-3.481, 14.0602, 4.0], "size": [2.6533, 0.4, 2.0], "rot": [0.848, -0.53, 0.0, 0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [-7.981, 11.2477, 4.0], "size": [2.6533, 0.4, 2.0], "rot": [0.848, -0.53, 0.0, 0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [-4.606, 13.3571, 8.0], "size": [10.6132, 0.4, 6.0], "rot": [0.848, -0.53, 0.0, 0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [4.606, 13.3571, -8.0], "size": [10.6132, 0.4, 6.0], "rot": [0.848, 0.53, 0.0, -0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [7.981, 11.2477, -4.0], "size": [2.6533, 0.4, 2.0], "rot": [0.848, 0.53, 0.0, -0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [1.231, 15.4665, -4.0], "size": [2.6533, 0.4, 2.0], "rot": [0.848, 0.53, 0.0, -0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [7.981, 11.2477, -2.0], "size": [2.6533, 0.4, 2.0], "rot": [0.848, 0.53, 0.0, -0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [1.231, 15.4665, -2.0], "size": [2.6533, 0.4, 2.0], "rot": [0.848, 0.53, 0.0, -0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [7.981, 11.2477, 0.0], "size": [2.6533, 0.4, 2.0], "rot": [0.848, 0.53, 0.0, -0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [5.731, 12.654, 0.0], "size": [2.6533, 0.4, 2.0], "rot": [0.848, 0.53, 0.0, -0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [1.231, 15.4665, 0.0], "size": [2.6533, 0.4, 2.0], "rot": [0.848, 0.53, 0.0, -0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [4.606, 13.3571, 6.0], "size": [10.6132, 0.4, 10.0], "rot": [0.848, 0.53, 0.0, -0.53, 0.848, 0.0, 0.0, 0.0, 1.0]}, {"center": [-4.5, 14.5, 4.0], "size": [1.6, 6.0, 1.6], "rot": [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]}], "studio_props": {"Shell": {"CanCollide": false, "CanTouch": false, "CanQuery": false, "CollisionFidelity": "Box"}, "Door_1": {"CanCollide": true, "CollisionFidelity": "Box"}}, "uv": {"Shell": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "Door_1": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}}, "palette_image_id": "75482071682779 (T_Palette_Main, группа «Грева нет» 867558223)"}, {"asset": "Sedan", "category": "Vehicles", "primary_part": "Body", "coords": "Roblox studs; pivot модели = центр основания (0,0,0); перёд −Z; оси (x,y,z)_blender → (−x,z,y)", "attributes": {"AssetId": "Sedan", "Category": "Vehicles", "Tris": 1600}, "tris_visible": 1600, "parts": [{"name": "Body", "tris": 438, "size": [6.4, 4.67, 15.2], "center": [-0.0, 3.085, 0.0], "textured": false}, {"name": "Glass", "tris": 16, "size": [5.6, 2.2, 6.8], "center": [-0.0, 4.2, 1.0], "textured": true}, {"name": "Trim", "tris": 586, "size": [7.6539, 5.435, 15.8026], "center": [-0.4769, 2.7375, 0.0987], "textured": true}, {"name": "Hood", "tris": 136, "size": [5.4, 0.8174, 4.6], "center": [-0.0, 3.2218, -4.85], "textured": false, "pivot_offset": [-0.0, 0.0336, 2.3]}, {"name": "Trunk", "tris": 96, "size": [5.4, 0.2578, 2.6], "center": [-0.0, 3.1577, 5.95], "textured": false, "pivot_offset": [-0.0, 0.1289, -1.3]}, {"name": "Steering", "tris": 40, "size": [0.9239, 0.7956, 0.7991], "center": [-1.4, 3.3075, -1.3913], "textured": true, "pivot_offset": [-0.0, -0.0075, 0.0413]}, {"name": "Wheel_FL", "tris": 72, "size": [0.92, 2.4, 2.2825], "center": [-2.85, 1.2, -4.7], "textured": true, "pivot_offset": [-0.0, 0.0, 0.0]}, {"name": "Wheel_FR", "tris": 72, "size": [0.92, 2.4, 2.2825], "center": [2.85, 1.2, -4.7], "textured": true, "pivot_offset": [-0.0, 0.0, 0.0]}, {"name": "Wheel_RL", "tris": 72, "size": [0.92, 2.4, 2.2825], "center": [-2.85, 1.2, 4.7], "textured": true, "pivot_offset": [-0.0, 0.0, 0.0]}, {"name": "Wheel_RR", "tris": 72, "size": [0.92, 2.4, 2.2825], "center": [2.85, 1.2, 4.7], "textured": true, "pivot_offset": [-0.0, 0.0, 0.0]}, {"name": "Collider", "tris": 20, "size": [6.4, 4.67, 15.6], "center": [-0.0, 3.085, 0.0], "textured": false}], "model_pivot": [-0.0, 0.0, 0.0], "attachments": [{"name": "Seat_Driver", "parent": "Body", "position": [-1.4, 1.7, -0.4]}, {"name": "Seat_1", "parent": "Body", "position": [1.4, 1.7, -0.4]}, {"name": "Seat_2", "parent": "Body", "position": [-1.6, 1.7, 2.75]}, {"name": "Seat_3", "parent": "Body", "position": [-0.0, 1.7, 2.75]}, {"name": "Seat_4", "parent": "Body", "position": [1.6, 1.7, 2.75]}, {"name": "Engine", "parent": "Body", "position": [-0.0, 2.3, -5.0]}, {"name": "Slot_SparkPlug", "parent": "Body", "position": [-0.5, 2.75, -4.4]}, {"name": "Slot_Battery", "parent": "Body", "position": [-1.7, 2.7, -5.9]}, {"name": "Slot_Radiator", "parent": "Body", "position": [-0.0, 2.4, -6.9]}, {"name": "Slot_Oil", "parent": "Body", "position": [0.7, 2.75, -4.9]}, {"name": "Slot_FuelCap", "parent": "Body", "position": [3.2, 2.75, 5.9]}, {"name": "Cargo", "parent": "Body", "position": [-0.0, 2.6, 6.0]}, {"name": "Headlight_L", "parent": "Body", "position": [-2.05, 2.2, -7.7]}, {"name": "Headlight_R", "parent": "Body", "position": [2.05, 2.2, -7.7]}, {"name": "Exhaust", "parent": "Body", "position": [1.8, 0.9, 8.0]}], "colliders": [], "studio_props": {"Body": {"Color": [255, 255, 255], "Material": "SmoothPlastic", "TextureID": ""}, "Hood": {"Color": [255, 255, 255], "Material": "SmoothPlastic", "TextureID": ""}, "Trunk": {"Color": [255, 255, 255], "Material": "SmoothPlastic", "TextureID": ""}, "Glass": {"Transparency": 0.35, "Material": "SmoothPlastic", "CanCollide": false}, "Trim": {"CanCollide": false}, "Steering": {"CanCollide": false}, "Collider": {"Transparency": 1, "CanCollide": true, "CollisionFidelity": "Hull"}, "*": {"CanCollide": false, "CanTouch": false, "CanQuery": false}}, "uv": {"Body": {"texel_studs_per_uv": 34.079, "px_per_stud_1024": 30.0, "groups": {"-Y": [0.7672, 0.7388, 0.1761, 0.0572], "-Z": [0.0156, 0.0156, 0.4343, 0.1878], "+X": [0.0156, 0.4225, 0.4343, 0.1297], "+Z_deck": [0.4655, 0.0156, 0.4401, 0.1878], "-X": [0.4655, 0.4225, 0.4343, 0.1297], "inner+Y@-6.2": [0.0156, 0.911, 0.1878, 0.0205], "inner+Y@-6.0": [0.0156, 0.869, 0.1878, 0.0264], "inner+Z_deck": [0.3687, 0.219, 0.2758, 0.1702], "-Y@-3.5": [0.0156, 0.8196, 0.1878, 0.0337], "-Y@-3.2": [0.219, 0.911, 0.1878, 0.0205], "+Y@3.2": [0.4225, 0.911, 0.1878, 0.0205], "+Y@3.4": [0.219, 0.869, 0.1878, 0.0264], "inner-Z": [0.0156, 0.219, 0.3374, 0.1878], "inner-Y@5.9": [0.219, 0.8196, 0.1878, 0.0337], "inner-Y@6.2": [0.6259, 0.911, 0.1878, 0.0205], "+Y": [0.5755, 0.7388, 0.1761, 0.0631], "-Y@-0.9": [0.8293, 0.911, 0.1455, 0.0065], "+Y@2.8": [0.0156, 0.9472, 0.1455, 0.0065], "+Z_roof": [0.6601, 0.219, 0.1074, 0.1461], "inner+Y@-1.7": [0.1852, 0.6554, 0.1712, 0.066], "inner-X": [0.0156, 0.5678, 0.2091, 0.0719], "-Y@-2.0": [0.3721, 0.6554, 0.1754, 0.066], "inner-Y@3.1": [0.8237, 0.6554, 0.1534, 0.0651], "+Y@3.9": [0.0156, 0.7388, 0.1753, 0.0651], "inner-Y@0.9": [0.4651, 0.5678, 0.1724, 0.0679], "+Y@1.3": [0.6531, 0.5678, 0.1724, 0.0679], "-Y@-1.4": [0.5631, 0.6554, 0.1754, 0.066], "inner+X": [0.2404, 0.5678, 0.2091, 0.0719], "inner-Y@3.7": [0.2065, 0.7388, 0.1714, 0.0651], "+Y@1.2": [0.0156, 0.6554, 0.1539, 0.0679], "inner+Y@-5.9": [0.4225, 0.8196, 0.1878, 0.0337], "-Y@-3.4": [0.4225, 0.869, 0.1878, 0.0264], "+Y@3.5": [0.6259, 0.8196, 0.1878, 0.0337], "inner-Y@6.0": [0.6259, 0.869, 0.1878, 0.0264], "inner+Y@-1.2": [0.7541, 0.6554, 0.0147, 0.066], "+Y@3.3": [0.3936, 0.7388, 0.1662, 0.0651], "inner+Y@-1.1": [0.7844, 0.6554, 0.0237, 0.066]}}, "Glass": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "Trim": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "Steering": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "Wheel_FL": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "Wheel_FR": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "Wheel_RL": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}, "Wheel_RR": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}}, "palette_image_id": "75482071682779 (T_Palette_Main, группа «Грева нет» 867558223)"}, {"asset": "Rock_Desert_01", "category": "Nature", "primary_part": "Rock", "coords": "Roblox studs; pivot модели = центр основания (0,0,0); перёд −Z; оси (x,y,z)_blender → (−x,z,y)", "attributes": {"AssetId": "Rock_Desert_01", "Category": "Nature", "Tris": 500}, "tris_visible": 500, "parts": [{"name": "Rock", "tris": 500, "size": [15.0527, 5.9047, 12.0397], "center": [-0.1076, 2.9523, 0.6991], "textured": true}], "model_pivot": [-0.0, 0.0, 0.0], "attachments": [], "colliders": [], "studio_props": {"Rock": {"CanCollide": true, "CollisionFidelity": "Hull"}}, "uv": {"Rock": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}}, "palette_image_id": "75482071682779 (T_Palette_Main, группа «Грева нет» 867558223)"}, {"asset": "Sedan_Wheel_Flat", "category": "Vehicles", "primary_part": "Wheel_Flat", "coords": "Roblox studs; pivot модели = центр основания (0,0,0); перёд −Z; оси (x,y,z)_blender → (−x,z,y)", "attributes": {"AssetId": "Sedan_Wheel_Flat", "Category": "Vehicles", "Tris": 72, "Vehicle": "Sedan", "AxleDrop": 0.5}, "tris_visible": 72, "parts": [{"name": "Wheel_Flat", "tris": 72, "size": [1.05, 1.88, 2.2825], "center": [-0.0, 0.96, 0.0], "textured": true, "pivot_offset": [-0.0, -0.26, 0.0]}], "model_pivot": [-0.0, 0.7, 0.0], "attachments": [], "colliders": [], "studio_props": {"*": {"CanCollide": false, "CanTouch": false, "CanQuery": false}}, "uv": {"Wheel_Flat": {"outside_safe_rect": 0, "min_px_to_cell_edge": 12.0}}, "palette_image_id": "75482071682779 (T_Palette_Main, группа «Грева нет» 867558223)"}]]==])
local TOL = 0.02

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local out = {}
for _, asset in MANIFESTS do
	local src = workspace.StyleTest:FindFirstChild(asset.asset)
	if not src then
		table.insert(out, asset.asset .. ": нет модели")
		continue
	end
	local c = src:Clone()
	c:PivotTo(CFrame.identity)
	local m = SS:DeserializeInstancesAsync(SS:SerializeInstancesAsync({ c }))[1] :: Model
	c:Destroy()
	local bad = {}
	local mp0 = v3(asset.model_pivot or { 0, 0, 0 })
	if not m.PrimaryPart or m.PrimaryPart.Name ~= asset.primary_part then
		table.insert(bad, "PrimaryPart")
	end
	for k, v in asset.attributes do
		if m:GetAttribute(k) ~= v then
			table.insert(bad, "атрибут " .. k)
		end
	end
	local fid = {}
	for _, p in asset.parts do
		local part = m:FindFirstChild(p.name) :: BasePart?
		if not part then
			table.insert(bad, "нет части " .. p.name)
			continue
		end
		-- pivot модели после PivotTo(identity) в нуле; у PrimaryPart pivot = pivot модели
		local want = p.name == asset.primary_part and Vector3.zero
			or v3(p.center) + (p.pivot_offset and v3(p.pivot_offset) or Vector3.zero) - mp0
		local got = part:GetPivot().Position
		if (got - want).Magnitude > TOL then
			table.insert(bad, string.format("pivot %s %s≠%s", p.name, tostring(got), tostring(want)))
		end
		if part:IsA("MeshPart") then
			fid[part.CollisionFidelity.Name] = (fid[part.CollisionFidelity.Name] or 0) + 1
			if not p.textured and (part.TextureID ~= "" or part.Color ~= Color3.new(1, 1, 1)) then
				table.insert(bad, p.name .. ": TextureID/Color")
			end
		end
	end
	for _, a in asset.attachments do
		local att = m:FindFirstChild(a.name, true) :: Attachment?
		if not att or att.Parent == nil or att.Parent.Name ~= a.parent then
			table.insert(bad, "нет Attachment " .. a.name)
		elseif (att.WorldPosition - (v3(a.position) - mp0)).Magnitude > TOL then
			table.insert(bad, string.format("Attachment %s %s≠%s", a.name, tostring(att.WorldPosition), tostring(v3(a.position) - mp0)))
		end
	end
	local scripts, loose = 0, 0
	for _, d in m:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			scripts += 1
		elseif d:IsA("BasePart") and not d.Anchored then
			loose += 1
		end
	end
	if scripts > 0 then
		table.insert(bad, scripts .. " скриптов")
	end
	if loose > 0 then
		table.insert(bad, loose .. " не Anchored")
	end
	local f = {}
	for k, n in fid do
		table.insert(f, k .. "×" .. n)
	end
	table.insert(out, string.format("%s: %s | CollisionFidelity %s", asset.asset,
		#bad == 0 and "OK" or table.concat(bad, "; "), table.concat(f, ", ")))
	m:Destroy()
end
return table.concat(out, "\n")
