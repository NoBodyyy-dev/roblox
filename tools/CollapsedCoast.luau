-- Replaces the stair coast and middle bridge with a collapsed city ravine at the boat.
local r=workspace.AbandonedCity
assert(r,"AbandonedCity missing")
assert(not r:FindFirstChild("CollapsedCityRavine"),"Ravine already installed")
game.ChangeHistoryService:SetWaypoint("Before collapsed city ravine")
local backup=Instance.new("Folder");backup.Name="BeforeRavineCoast";backup.Parent=game.ServerStorage
r.DestroyedBridge.Parent=backup;r.CliffAndSea.Parent=backup
local function box(m,n,pos,size,color,cf)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.CanTouch=false;p.Size=size;p.CFrame=cf or CFrame.new(pos);p.Color=color or Color3.fromRGB(88,89,81);p.Material=Enum.Material.Concrete;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m;return p
end
local function model(n,p) local m=Instance.new("Model");m.Name=n;m.Parent=p;return m end
local function ax(z) return 260*math.sin(z/1600)+100*math.sin(z/650) end
local function ramp(m,n,a,b,width,color,thick)
 return box(m,n,Vector3.zero,Vector3.new(width,thick or 3,(b-a).Magnitude+5),color,CFrame.lookAt((a+b)/2,b))
end
-- Restore uninterrupted city ground where the former bridge stood.
local repair=model("RestoredMiddleDistrict",r)
for x=-3200,2800,400 do box(repair,"RestoredGround",Vector3.new(x+200,80,7000),Vector3.new(400,80,400),Color3.fromRGB(105,105,94)) end
for z=6800,7100,100 do ramp(repair,"RestoredAsphalt",Vector3.new(ax(z),120.5,z),Vector3.new(ax(z+100),120.5,z+100),54,Color3.fromRGB(48,51,51),0.5) end
-- Reserve a wide area at the end for the city subsidence bowl.
for _,m in r:GetChildren() do
 local z=tonumber(string.match(m.Name,"^DistrictGround_(%d+)$"))
 if z and z>=12400 then m.Parent=backup end
end
for _,p in r.Streets:GetDescendants() do if p:IsA("BasePart") and p.Position.Z>=12500 then p.Parent=backup end end
local ravine=model("CollapsedCityRavine",r)
local rng=Random.new(43878)
local rock=Color3.fromRGB(83,82,72);local concrete=Color3.fromRGB(120,118,105)
local center=Vector3.new(0,0,13700)
-- Outer plateau tiles follow an irregular elliptical collapse edge.
for z=12400,14800,200 do
 local chunk=model("OuterRim_"..z,nil)
 for x=-3200,3000,200 do
  local xx=x+100;local zz=z+100
  local radius=math.sqrt((xx/1450)^2+((zz-13700)/1250)^2)
  if radius>1.04 and zz<14400 then box(chunk,"RemainingCityGround",Vector3.new(xx,80,zz),Vector3.new(200,80,200),Color3.fromRGB(105,105,94)) end
 end
 chunk.Parent=ravine;task.wait()
end
-- Rock basin, then overlapping radial slopes: rough continuous ground, no steps.
for x=-1600,1200,400 do box(ravine,"BasinFloor",Vector3.new(x+200,-19,13750),Vector3.new(400,20,1900),rock) end
for sector=0,31 do
 local m=model("CollapsedSlope_"..sector,nil)
 local a=sector*math.pi*2/32;local ca,sa=math.cos(a),math.sin(a)
 local outer=Vector3.new(ca*1480,118,13700+sa*1280)
 local inner=Vector3.new(ca*500,5,13700+sa*420)
 local mid=(outer+inner)/2
 ramp(m,"RoughSlope",inner,outer,330,rock,18)
 for j=1,7 do
  local t=rng:NextNumber(0.15,0.95);local pos=inner:Lerp(outer,t)+Vector3.new(rng:NextNumber(-70,70),8,rng:NextNumber(-60,60))
  local p=box(m,"CollapsedConcrete",pos,Vector3.new(rng:NextNumber(8,32),rng:NextNumber(4,11),rng:NextNumber(10,40)),concrete)
  p.CFrame*=CFrame.Angles(rng:NextNumber(-0.3,0.3),rng:NextNumber(0,6.28),rng:NextNumber(-0.25,0.25))
 end
 m.Parent=ravine;task.wait()
end
-- A broad eroded route follows the western slope down to the boat.
local path={Vector3.new(ax(12500),121,12500),Vector3.new(-680,116,12620),Vector3.new(-1080,87,13060),Vector3.new(-820,51,13580),Vector3.new(-430,24,13960),Vector3.new(40,8,14220),Vector3.new(350,7,14320)}
for i=1,#path-1 do ramp(ravine,"RubbleDescent",path[i],path[i+1],65,Color3.fromRGB(110,105,90),8) end
-- Final road terminates on the ruined bridge above the collapse.
local bx=ax(12800)
ramp(ravine,"FinalRoad",Vector3.new(ax(12500),121,12500),Vector3.new(bx,121,12800),54,Color3.fromRGB(48,51,51),1)
local bridge=model("DestroyedBridgeAtBoat",ravine)
box(bridge,"RemainingBridgeDeck",Vector3.new(bx,119,12935),Vector3.new(60,5,270),concrete)
for _,side in {-1,1} do
 box(bridge,"BrokenGuardrail",Vector3.new(bx+side*29,123,12900),Vector3.new(1,3,180),Color3.fromRGB(95,67,51))
end
for _,z in {12820,13000} do box(bridge,"ExposedBridgePier",Vector3.new(bx,58,z),Vector3.new(20,120,24),rock) end
for j=1,8 do box(bridge,"ExposedRebar",Vector3.new(bx-25+j*6,119,13090),Vector3.new(0.5,0.5,rng:NextNumber(26,48)),Color3.fromRGB(102,65,46)) end
local slab=box(bridge,"FallenBridgeSpan",Vector3.new(bx+80,37,13400),Vector3.new(58,6,230),concrete)
slab.CFrame*=CFrame.Angles(math.rad(19),math.rad(-12),math.rad(8))
for j=1,5 do
 local p=box(bridge,"BrokenDeckSlab",Vector3.new(bx+rng:NextNumber(-100,120),rng:NextNumber(4,20),rng:NextNumber(13200,13600)),Vector3.new(32,6,55),concrete)
 p.CFrame*=CFrame.Angles(rng:NextNumber(-0.4,0.4),rng:NextNumber(0,6),rng:NextNumber(-0.2,0.2))
end
-- Sunken building shells, visibly tilted into the bowl.
for i=1,11 do
 local m=model("SunkenCityBlock_"..i,nil)
 local angle=rng:NextNumber(0,math.pi*2);local radius=rng:NextNumber(400,950)
 local x=math.cos(angle)*radius;local z=13700+math.sin(angle)*radius*0.72
 local base=Vector3.new(x,8+(radius-400)*0.08,z)
 if x>-350 or z<13100 then
  local cf=CFrame.new(base)*CFrame.Angles(rng:NextNumber(-0.22,0.22),rng:NextNumber(0,6.28),rng:NextNumber(-0.26,0.26))
  local h=rng:NextInteger(2,5)*14
  for y=0,h,14 do
   box(m,"CollapsedFloor",Vector3.zero,Vector3.new(45,1.5,42),concrete,cf*CFrame.new(0,y,0))
  end
  for _,dx in {-21,21} do for _,dz in {-19,19} do box(m,"ExposedColumn",Vector3.zero,Vector3.new(3,h+5,3),rock,cf*CFrame.new(dx,h/2,dz)) end end
  box(m,"BrokenWall",Vector3.zero,Vector3.new(45,h,1),Color3.fromRGB(126,121,106),cf*CFrame.new(0,h/2,20))
 end
 m.Parent=ravine;task.wait()
end
-- Lower shoreline and the existing boat marker.
for x=-3200,2800,400 do
 box(ravine,"SeaSurface",Vector3.new(x+200,-5,15500),Vector3.new(400,8,2300),Color3.fromRGB(47,92,103)).Material=Enum.Material.Glass
end
ramp(ravine,"ShoreJetty",Vector3.new(350,6,14320),Vector3.new(350,6,14530),20,Color3.fromRGB(98,77,57),2)
local marker=box(ravine,"BoatDeparture",Vector3.new(350,8,14510),Vector3.new(14,1,14),rock)
local a=Instance.new("Attachment");a.Name="BoatSpawn";a.Position=Vector3.new(0,-10,24);a.Parent=marker
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(-900,500,12500),Vector3.new(0,45,13600))
game.Selection:Set({})
game.ChangeHistoryService:SetWaypoint("Collapsed city ravine and final bridge")
for i=4,12 do
 local m=ravine:FindFirstChild("CollapsedSlope_"..i)
 if m then m.Parent=backup end
end
return "Middle bridge removed; city ravine and broken final bridge installed. All descent stairs removed."

