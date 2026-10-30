local r=workspace.AbandonedCity
local bak=Instance.new("Folder");bak.Name="BeforeTerrainRavine";bak.Parent=game.ServerStorage
r.CollapsedCityRavine.Parent=bak
if r:FindFirstChild("RepairedCoastRoads") then r.RepairedCoastRoads.Parent=bak end
-- Remove old terrain slabs at the end; the earlier city remains untouched.
for _,m in r:GetChildren() do local z=tonumber(m.Name:match("^DistrictGround_(%d+)$"));if z and z>=12000 then m.Parent=bak end end
for _,p in r.Streets:GetDescendants() do if p:IsA("BasePart") and p.Position.Z>=12000 then p.Parent=bak end end
local f=Instance.new("Model");f.Name="NaturalCityRavine";f.Parent=r
return "All overlapping ravine plates, patch roads and end-ground slabs removed from active map."
