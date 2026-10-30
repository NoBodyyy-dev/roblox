local sources=script.Parent
local r=workspace.AbandonedCity;local f=r.NaturalCityRavine;local B=require(sources.Terrain);local rng=Random.new(8822)
local function ax(z) return 260*math.sin(z/1600)+100*math.sin(z/650) end
local function p(n,size,cf,c,mat)
 local a=Instance.new("Part");a.Name=n;a.Size=size;a.CFrame=cf;a.Color=c or Color3.fromRGB(116,113,101);a.Material=mat or Enum.Material.Concrete;a.Anchored=true;a.CanTouch=false;a.Parent=f;return a
end
for z=12000,12480,20 do
 local a=Vector3.new(ax(z),B.Height(ax(z),z)+0.7,z);local b=Vector3.new(ax(z+20),B.Height(ax(z+20),z+20)+0.7,z+20)
 p("ContinuousApproach",Vector3.new(54,0.6,(b-a).Magnitude+0.3),CFrame.lookAt((a+b)/2,b),Color3.fromRGB(48,51,51),Enum.Material.Asphalt)
end
local bx=ax(12500);local by=B.Height(bx,12500)+0.7
p("BrokenBridgeDeck",Vector3.new(56,4,340),CFrame.new(bx,by-1.7,12670))
for _,z in {12550,12770} do
 local foot=B.Height(bx,z);local h=by-foot
 p("BridgePier",Vector3.new(15,h,20),CFrame.new(bx,foot+h/2,z),Color3.fromRGB(83,82,75))
end
for _,side in {-1,1} do p("BridgeRail",Vector3.new(0.8,2,280),CFrame.new(bx+side*27,by+1.5,12640),Color3.fromRGB(103,70,50),Enum.Material.CorrodedMetal) end
for i=1,7 do p("ExposedRebar",Vector3.new(0.4,0.4,28),CFrame.new(bx-24+i*6,by-1,12849),Color3.fromRGB(103,70,50),Enum.Material.CorrodedMetal) end
p("FallenBridgeSpan",Vector3.new(50,4,100),CFrame.new(bx+25,B.Height(bx+25,13050)+9,13050)*CFrame.Angles(-0.16,0.12,0.08))
-- Reuse sunken ruins only, with foundations now placed on the true terrain surface.
local old=game.ServerStorage.BeforeTerrainRavine.CollapsedCityRavine
for _,m in old:GetChildren() do
 if m.Name:match("^SunkenCityBlock") and #m:GetChildren()>0 then
  local clone=m:Clone();local cf,size=clone:GetBoundingBox();local h=B.Height(cf.X,cf.Z);clone:PivotTo(clone:GetPivot()+Vector3.new(0,h-(cf.Y-size.Y/2)-2,0));clone.Parent=f
 end
end
for _,folder in {r.UsefulBuildings,r.SealedBuildings} do
 for _,m in folder:GetChildren() do local q=m.PrimaryPart;if q and q.Position.Z>=12000 then local delta=B.Height(q.Position.X,q.Position.Z)-120;m:PivotTo(m:GetPivot()+Vector3.new(0,delta,0)) end end
end
for _,m in r.StreetDebris:GetChildren() do for _,q in m:GetChildren() do if q:IsA("BasePart") and q.Position.Z>=12000 then q.Position+=Vector3.new(0,B.Height(q.Position.X,q.Position.Z)-120,0) end end end
-- Small debris rests on the ground instead of large tilted plates.
for i=1,120 do
 local x=rng:NextNumber(-1250,1250);local z=rng:NextNumber(12500,14300);local h=B.Height(x,z)
 p("SmallConcreteDebris",Vector3.new(rng:NextNumber(1.5,5),rng:NextNumber(0.8,2.5),rng:NextNumber(2,6)),CFrame.new(x,h+0.8,z)*CFrame.Angles(0,rng:NextNumber(0,6.28),0),Color3.fromRGB(126,122,108))
end
local pier=p("ShoreJetty",Vector3.new(16,1.2,100),CFrame.new(230,3,14430),Color3.fromRGB(94,77,57),Enum.Material.WoodPlanks)
local marker=p("BoatDeparture",Vector3.new(12,0.5,12),CFrame.new(230,3.8,14460))
local at=Instance.new("Attachment");at.Name="BoatSpawn";at.Position=Vector3.new(0,-3,25);at.Parent=marker
game.Selection:Set({})
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(-1300,650,12300),Vector3.new(0,30,13500))
game.ChangeHistoryService:SetWaypoint("Natural terrain ravine rebuilt")
return "Natural terrain coast rebuilt, road fitted, ruins grounded. No radial slabs or descent road strips."

