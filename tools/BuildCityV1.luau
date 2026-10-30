-- Reproduce the approved v0.1.0 map in a NEW place. Run in Studio Edit Command Bar.
assert(not workspace:FindFirstChild("AbandonedCity"), "Use a new place to avoid overwriting the map")
local sources=Instance.new("Folder");sources.Name="CityV1Sources";sources.Parent=game.ServerStorage
do local m=Instance.new("ModuleScript");m.Name="BaseCity";m.Source=[====[
-- AbandonedCityBuilder ModuleScript. Execute Build stages in Edit mode.
local B={}
local R=Random.new(30102027)
local Y=120
local C={ground=Color3.fromRGB(105,105,94),road=Color3.fromRGB(48,51,51),rock=Color3.fromRGB(79,82,77),rust=Color3.fromRGB(109,66,49),glass=Color3.fromRGB(35,45,44),trim=Color3.fromRGB(151,147,131),green=Color3.fromRGB(60,75,53)}
local colors={Color3.fromRGB(139,137,120),Color3.fromRGB(120,130,125),Color3.fromRGB(153,135,113),Color3.fromRGB(130,116,108),Color3.fromRGB(114,121,126),Color3.fromRGB(161,151,125)}
local function root() return workspace:FindFirstChild("AbandonedCity") end
local function model(n,p) local m=Instance.new("Model");m.Name=n;m.Parent=p;return m end
local function part(m,n,size,cf,c,mat)
 local p=Instance.new("Part");p.Name=n;p.Size=size;p.CFrame=cf;p.Color=c or C.ground;p.Material=mat or Enum.Material.Concrete;p.Anchored=true;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m;return p
end
local function box(m,n,x,y,z,w,h,d,c,mat) return part(m,n,Vector3.new(w,h,d),CFrame.new(x,y,z),c,mat) end
local function ax(z) return 260*math.sin(z/1600)+100*math.sin(z/650) end
local function att(p,n,v) local a=Instance.new("Attachment");a.Name=n;a.Position=v or Vector3.zero;a.Parent=p;return a end
local function strip(m,n,a,b,w,c) return part(m,n,Vector3.new(w,0.5,(b-a).Magnitude+0.5),CFrame.lookAt((a+b)/2,b),c,Enum.Material.Asphalt) end
function B.Foundation()
 assert(not root(),"City already exists; refusing overwrite")
 pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("Before abandoned city") end)
 local old=workspace:FindFirstChild("DesertMap");if old then old.Parent=game.ServerStorage;old.Name="DesertMap_Backup" end
 local r=model("AbandonedCity",workspace);r:SetAttribute("Version","0.2");r:SetAttribute("Seed",30102027);r:SetAttribute("Width",6400)
 for z=-800,13200,400 do
  if z<6800 or z>=7200 then
   local m=model("DistrictGround_"..z,nil)
   for x=-3200,2800,400 do box(m,"Ground",x+200,Y-40,z+200,400,80,400,C.ground,Enum.Material.Ground) end
   m.Parent=r;task.wait()
  end
 end
 local l=game.Lighting;l.ClockTime=15;l.Brightness=1.8;l.Ambient=Color3.fromRGB(107,114,112);l.OutdoorAmbient=Color3.fromRGB(125,133,129)
 for _,a in l:GetChildren() do if a:IsA("Atmosphere") then a:Destroy() end end
 local a=Instance.new("Atmosphere");a.Name="CityHaze";a.Density=0.23;a.Offset=0.05;a.Color=Color3.fromRGB(188,199,190);a.Decay=Color3.fromRGB(115,128,122);a.Haze=1.8;a.Parent=l
 local s=Instance.new("SpawnLocation");s.Name="CitySpawn";s.Size=Vector3.new(8,1,8);s.Position=Vector3.new(90,Y+1,80);s.Anchored=true;s.Transparency=1;s.CanCollide=false;s.Neutral=true;s.Duration=0;s.Parent=r
 pcall(function() workspace.StreamingEnabled=true end)
 return "City foundation: 6400 studs wide, ground elevation 120, ravine and cliff reserved. Desert preserved."
end
function B.Streets()
 local roads=model("Streets",root())
 for zone=0,13 do
  local m=model("Route_"..zone,nil)
  for z=zone*1000,math.min(zone*1000+900,13300),100 do
   if z<6800 or z>=7200 then
    local a=Vector3.new(ax(z),Y+0.5,z);local b=Vector3.new(ax(z+100),Y+0.5,z+100)
    strip(m,"MainRoad",a,b,54,C.road)
    local mid=(a+b)/2;strip(m,"WornDash",mid-Vector3.new(0,-0.3,8),mid+Vector3.new(0,0.3,8),0.6,C.trim)
   end
  end
  if zone~=6 then
   local z=zone*1000+R:NextInteger(200,700)
   strip(m,"CrossStreet",Vector3.new(-2850,Y+0.3,z),Vector3.new(2850,Y+0.3,z+R:NextInteger(-150,150)),27,C.road)
  end
  m.Parent=roads;task.wait()
 end
 return "Irregular main route and side streets created"
end
local function building(parent,id,x,z,floors,near)
 local m=model(id,nil);local w=R:NextInteger(40,66);local d=R:NextInteger(44,60);local col=colors[R:NextInteger(1,#colors)]
 local yaw=math.rad(R:NextInteger(-1,1)*90+R:NextInteger(-9,9));local origin=CFrame.new(x,Y,z)*CFrame.Angles(0,yaw,0)
 local function p(n,px,py,pz,sw,sh,sd,c,mat)
  return part(m,n,Vector3.new(sw,sh,sd),origin*CFrame.new(px,py,pz),c or col,mat)
 end
 m:SetAttribute("Enterable",true);m:SetAttribute("LootEligible",true);m:SetAttribute("Floors",floors);m:SetAttribute("NearMainRoad",near)
 local foundation=p("Foundation",0,0,0,w+2,1,d+2,C.rock);m.PrimaryPart=foundation
 att(foundation,"Entrance_1",Vector3.new(5,2,-d/2-5));att(foundation,"SurvivorSpawn_1",Vector3.new(5,3,8))
 for f=0,floors-1 do
  local base=f*16
  -- Continuous stairwell on left; floor plates leave the entire stair bay open.
  p("Floor_"..(f+1),6,base+0.5,0,w-12,1,d,C.trim)
  p("StairLanding_"..(f+1),-w/2+6,base+0.5,(f%2==0 and -1 or 1)*(d/2-4),12,1,8,C.trim)
  for _,side in {-1,1} do
   p("WallSill",side*w/2,base+2,0,1,3,d)
   p("WallHeader",side*w/2,base+14,0,1,4,d)
   for zz=-d/2+4,d/2,10 do p("WindowPier",side*w/2,base+8,zz,1,10,2) end
  end
  for _,front in {-1,1} do
   if f==0 and front==-1 then
    p("EntranceLeft",-w/4-2,base+8,front*d/2,w/2-4,15,1)
    p("EntranceRight",w/4+6,base+8,front*d/2,w/2-12,15,1)
    p("EntranceLintel",4,base+14,front*d/2,12,4,1)
   else
    p("FacadeSill",0,base+2,front*d/2,w,3,1)
    p("FacadeHeader",0,base+14,front*d/2,w,4,1)
    for xx=-w/2+1,w/2,10 do p("FacadePier",xx,base+8,front*d/2,2,10,1) end
   end
  end
  -- Switchback flights, with 24 short steps and unobstructed head clearance.
  if f<floors-1 then
   local run=d-16;local dir=f%2==0 and 1 or -1
   for step=1,24 do
    local zz=dir*(-run/2+(step-0.5)*run/24)
    p("Stair_"..f.."_"..step,-w/2+6,base+step*16/24-0.35,zz,10,0.7,run/24+0.1,C.trim)
   end
   p("StairGuard", -w/2+12,base+9,0,0.5,2,run,C.rust,Enum.Material.Metal)
  end
  local tablePart=p("LootShelf_"..(f+1),w/2-6,base+2,8,6,4,4,C.rust)
  att(tablePart,"LootPoint",Vector3.new(0,3,0));att(foundation,"FloorAccess_"..(f+1),Vector3.new(4,base+3,0))
  if f%2==0 then
   p("InteriorPartition",w/4,base+5,0,w/2-4,9,0.5,C.trim)
   p("Balcony",w/4,base+0.8,-d/2-3,w/2,0.6,6,C.rock)
   p("BalconyRail",w/4,base+3,-d/2-6,w/2,0.5,0.5,C.rust)
  end
 end
 -- Incomplete roof and exposed beams distinguish silhouettes.
 p("BrokenRoof",w/4,floors*16,0,w/2,1,d,C.rock)
 for i=1,4 do p("ExposedRebar",-w/2+R:NextNumber(3,w/2),floors*16+2,R:NextNumber(-d/2,d/2),0.3,R:NextNumber(3,8),0.3,C.rust,Enum.Material.Metal) end
 if near then p("ShopAwning",3,11,-d/2-4,w-6,0.7,9,Color3.fromRGB(75,101,94),Enum.Material.Metal) end
 m.Parent=parent;return m
end
function B.Buildings()
 local folder=model("UsefulBuildings",root());local used={}
 for i=1,25 do
  local near=i<=5;local x,z
  for attempt=1,200 do
   z=R:NextInteger(300,13150)
   x=near and ax(z)+(i%2==0 and -1 or 1)*R:NextInteger(180,320) or R:NextInteger(-2750,2750)
   local ok=not(z>6500 and z<7450) and (near or math.abs(x-ax(z))>550)
   for _,v in used do if (Vector2.new(x,z)-v).Magnitude<270 then ok=false end end
   if ok then break end
  end
  table.insert(used,Vector2.new(x,z));building(folder,"Explore_"..string.format("%02d",i),x,z,R:NextInteger(2,5),near);task.wait()
 end
 return "25 enterable buildings: 5 near route, 20 distributed; 2-5 floors with switchback stairs."
end
function B.Decor()
 local folder=model("SealedBuildings",root());local useful=root().UsefulBuildings:GetChildren()
 for i=1,95 do
  local x,z;local ok=false
  for attempt=1,100 do
   x=R:NextInteger(-2950,2950);z=R:NextInteger(-300,13150)
   ok=math.abs(x-ax(z))>100 and not(z>6650 and z<7350)
   for _,b in useful do local pos=b.PrimaryPart.Position;if (Vector2.new(x,z)-Vector2.new(pos.X,pos.Z)).Magnitude<150 then ok=false end end
   if ok then break end
  end
  if ok then
   local m=model("SealedBlock_"..i,nil);m:SetAttribute("Enterable",false);m:SetAttribute("LootEligible",false)
   local h=R:NextInteger(20,85);local w=R:NextInteger(25,65);local d=R:NextInteger(26,65);local col=colors[R:NextInteger(1,#colors)]
   local body=box(m,"SolidSealedBuilding",x,Y+h/2,z,w,h,d,col);m.PrimaryPart=body
   for yy=8,h-2,14 do
    for xx=-w/2+5,w/2-3,10 do
     box(m,"DarkWindow",x+xx,Y+yy,z-d/2-0.15,4,6,0.2,C.glass)
    end
   end
   box(m,"BlockedEntrance",x,Y+4,z-d/2-0.4,7,8,0.6,C.rust,Enum.Material.CorrodedMetal)
   box(m,"RoofRemnant",x-w/4,Y+h+2,z,w/2,4,d,C.rock)
   m.Parent=folder
  end
  if i%8==0 then task.wait() end
 end
 local skyline=model("RuinedSkyline",root());pcall(function() skyline.ModelStreamingMode=Enum.ModelStreamingMode.Persistent end)
 for i=1,85 do
  local side=i%2==0 and -1 or 1;local x=side*R:NextInteger(3050,3500);local z=R:NextInteger(-600,13200)
  if i>70 then x=R:NextInteger(-3200,3200);z=-650 end
  local m=model("TowerRuin_"..i,nil);local h=R:NextInteger(120,340);local w=R:NextInteger(60,115);local d=R:NextInteger(60,110)
  local col=Color3.fromRGB(R:NextInteger(78,110),R:NextInteger(82,112),R:NextInteger(80,107))
  box(m,"TowerCore",x,Y+h/2,z,w,h,d,col)
  for yy=18,h,20 do
   box(m,"FloorBand",x,Y+yy,z,w+3,1.3,d+3,C.rock)
   for xx=-w/2+8,w/2-4,16 do box(m,"DeadWindow",x+xx,Y+yy-7,z-d/2-0.2,8,9,0.4,C.glass) end
  end
  for j=1,3 do
   box(m,"BrokenCrown",x-w/2+j*w/4,Y+h+R:NextNumber(8,22),z,w/5,R:NextNumber(15,50),d*(j%2==0 and 0.4 or 0.7),col)
  end
  m.Parent=skyline;if i%5==0 then task.wait() end
 end
 local debris=model("StreetDebris",root())
 for k=0,13 do
  local m=model("Debris_"..k,nil)
  for i=1,30 do
   local z=R:NextNumber(k*1000,k*1000+800);local x=ax(z)+R:NextNumber(-85,85)
   if z<6700 or z>7300 then
    local p=box(m,"Rubble",x,Y+0.8,z,R:NextNumber(1,5),R:NextNumber(0.5,2),R:NextNumber(1,5),C.rock);p.Orientation=Vector3.new(0,R:NextNumber(0,360),0)
   end
  end
  for j=1,5 do
   local z=k*1000+j*150;local x=ax(z)+40
   if z<6700 or z>7300 then
    box(m,"StreetLightPole",x,Y+12,z,0.7,24,0.7,C.rock,Enum.Material.Metal)
    box(m,"LampHead",x-3,Y+24,z,7,0.6,1.5,C.trim)
   end
  end
  m.Parent=debris;task.wait()
 end
 return "Sealed houses, ruined skyline, rubble and dead street lights built."
end
function B.BridgeCoast()
 local r=root();local bridge=model("DestroyedBridge",r)
 local x=ax(7000)
 for _,range in {{6800,6960},{7040,7200}} do
  box(bridge,"BrokenDeck",x,Y, (range[1]+range[2])/2,58,5,range[2]-range[1],C.rock)
  for _,side in {-1,1} do box(bridge,"Guardrail",x+side*28,Y+3,(range[1]+range[2])/2,1,3,range[2]-range[1],C.rust) end
  box(bridge,"Pier",x,Y-43,(range[1]+range[2])/2,20,80,20,C.rock)
 end
 for i=1,8 do local p=box(bridge,"FallenSlab",x+R:NextNumber(-35,35),65+R:NextNumber(-10,10),R:NextNumber(6970,7040),20,4,20,C.rock);p.Orientation=Vector3.new(R:NextNumber(-30,30),R:NextNumber(0,180),R:NextNumber(-30,30)) end
 -- A narrow maintenance footbridge provides a traversable bypass.
 box(bridge,"Footbridge",x+140,Y,7000,12,2,440,C.rust,Enum.Material.Metal)
 for _,z in {6760,7240} do strip(bridge,"FootbridgeAccess",Vector3.new(ax(z),Y+0.5,z),Vector3.new(x+140,Y+0.5,z),14,C.road) end
 local coast=model("CliffAndSea",r)
 for xx=-3200,2800,400 do
  box(coast,"CliffFace",xx+200,58,13590,400,120,20,C.rock,Enum.Material.Rock)
  box(coast,"Beach",xx+200,0,14000,400,8,800,Color3.fromRGB(133,127,109),Enum.Material.Sand)
  box(coast,"SeaSurface",xx+200,-5,15300,400,8,1800,Color3.fromRGB(47,92,103),Enum.Material.Glass)
 end
 -- Seven switchback stair flights descend from city elevation 120 to beach elevation 8.
 local startX=ax(13400);local z=13620
 strip(coast,"CliffApproach",Vector3.new(ax(13400),Y+0.6,13400),Vector3.new(startX,Y+0.6,13620),20,C.road)
 for flight=0,6 do
  local dir=flight%2==0 and 1 or -1;local sx=startX+(flight%2==0 and 0 or 100);local yy=Y-flight*16
  for step=1,24 do
   box(coast,"DescentStep",sx+dir*(step-0.5)*100/24,yy-step*16/24-0.5,z+flight*18,100/24+0.2,1,14,C.trim)
  end
  box(coast,"SwitchbackLanding",sx+dir*100,yy-16-0.5,z+flight*18+9,16,1,32,C.rock)
 end
 box(coast,"Pier",startX+100,7,14400,20,2,260,C.rust,Enum.Material.WoodPlanks)
 box(coast,"BeachWalk",startX+100,6,14100,18,2,400,C.trim)
 local marker=box(coast,"BoatDeparture",startX+100,8,14510,14,1,14,C.rock);att(marker,"BoatSpawn",Vector3.new(0,-10,24))
 workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(-310,235,-180),Vector3.new(120,140,650))
 pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("Abandoned city") end)
 return "Destroyed bridge with bypass and coastal cliff switchback descent built."
end
function B.Finish()
do
local r=workspace.AbandonedCity
local bg=Instance.new("Model");bg.Name="CityPanorama";bg.Parent=r
pcall(function() bg.ModelStreamingMode=Enum.ModelStreamingMode.Persistent end)
local function panel(cf)
 local p=Instance.new("Part");p.Name="PanoramaPanel";p.Size=Vector3.new(1800,600,1);p.CFrame=cf;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Transparency=1;p.Parent=bg
 for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
  local g=Instance.new("SurfaceGui");g.Face=face;g.CanvasSize=Vector2.new(2048,683);g.LightInfluence=0;g.Parent=p
  local im=Instance.new("ImageLabel");im.Size=UDim2.fromScale(1,1);im.BackgroundTransparency=1;im.Image="rbxassetid://83137947733144";im.Parent=g
 end
end
for z=0,12600,1800 do
 panel(CFrame.new(-3650,420,z)*CFrame.Angles(0,math.pi/2,0))
 panel(CFrame.new(3650,420,z)*CFrame.Angles(0,-math.pi/2,0))
end
for x=-2700,2700,1800 do panel(CFrame.new(x,420,-1100)) end
local clouds=Instance.new("Clouds");clouds.Name="Overcast";clouds.Cover=0.93;clouds.Density=0.7;clouds.Color=Color3.fromRGB(177,185,180);clouds.Parent=workspace.Terrain
game.Lighting.ClockTime=12;game.Lighting.ExposureCompensation=0.3
game.Lighting.CityHaze.Density=0.17;game.Lighting.CityHaze.Haze=0.7
local walk=r.CliffAndSea.BeachWalk;walk.Position=Vector3.new(walk.Position.X,6,13920);walk.Size=Vector3.new(18,2,800)
end
do
local r=workspace.AbandonedCity;local rng=Random.new(8432)
for _,m in r.UsefulBuildings:GetChildren() do
 local f=m.PrimaryPart;local w=f.Size.X-2;local d=f.Size.Z-2;local cf=f.CFrame
 local decor=Instance.new("Model");decor.Name="DamageAndSurroundings";decor.Parent=m
 local function p(n,pos,size,c,mat)
  local a=Instance.new("Part");a.Name=n;a.Size=size;a.CFrame=cf*CFrame.new(pos);a.Color=c;a.Material=mat or Enum.Material.Concrete;a.Anchored=true;a.CanTouch=false;a.Parent=decor;return a
 end
 p("Pavement",Vector3.new(0,0.05,-d/2-10),Vector3.new(w+18,0.2,18),Color3.fromRGB(122,124,114))
 for i=1,12 do
  local a=p("FacadeDebris",Vector3.new(rng:NextNumber(-w/2-10,w/2+10),0.7,-d/2-rng:NextNumber(4,20)),Vector3.new(rng:NextNumber(1,4),rng:NextNumber(0.5,1.7),rng:NextNumber(1,4)),Color3.fromRGB(103,106,98));a.CFrame*=CFrame.Angles(0,rng:NextNumber(0,6.28),0)
 end
 local floors=m:GetAttribute("Floors")
 for level=0,floors-1 do
  if rng:NextNumber()<0.65 then
   local a=p("BoardedWindow",Vector3.new(-w/2+7,level*16+8,-d/2-0.8),Vector3.new(9,1.3,0.3),Color3.fromRGB(89,78,64),Enum.Material.Wood);a.CFrame*=CFrame.Angles(0,0,0.25)
  end
  if rng:NextNumber()<0.55 then
   p("BrickInfill",Vector3.new(w/2-6,level*16+8,d/2),Vector3.new(8,9,0.8),Color3.fromRGB(112,87,71),Enum.Material.Brick)
  end
 end
end
for _,v in r.CityPanorama:GetDescendants() do
 if v:IsA("ImageLabel") then local g=Instance.new("UIGradient");g.Rotation=90;g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0.2),NumberSequenceKeypoint.new(0.4,0),NumberSequenceKeypoint.new(1,0)});g.Parent=v end
end
game.Selection:Set({})
end
do
for _,b in workspace.AbandonedCity.UsefulBuildings:GetChildren() do
 local f=b.PrimaryPart;local w=f.Size.X-2;local d=f.Size.Z-2;local run=d-16
 for level=0,b:GetAttribute("Floors")-2 do
  local dir=level%2==0 and 1 or -1
  local a=Vector3.new(-w/2+6,level*16+0.65,-dir*run/2)
  local z=Vector3.new(-w/2+6,level*16+16.65,dir*run/2)
  local p=Instance.new("Part");p.Name="StairWalkSurface";p.Size=Vector3.new(10,0.5,(z-a).Magnitude+1);p.CFrame=f.CFrame*CFrame.lookAt((a+z)/2,z);p.Anchored=true;p.Transparency=1;p.CanTouch=false;p.Parent=b
 end
end
end
do
for _,b in workspace.AbandonedCity.UsefulBuildings:GetChildren() do
 local f=b.PrimaryPart;local w=f.Size.X-2;local d=f.Size.Z-2;local ramps={}
 for _,p in b:GetChildren() do
  if p:IsA("BasePart") then
   local level=string.match(p.Name,"^Stair_(%d+)_")
   if level then
    local cf=f.CFrame:ToObjectSpace(p.CFrame);local v=cf.Position;local xx=-w/2+(tonumber(level)%2==0 and 5 or 14)
    p.CFrame=f.CFrame*CFrame.new(xx,v.Y,v.Z);p.Size=Vector3.new(7,p.Size.Y,p.Size.Z)
   elseif p.Name=="StairGuard" then p:Destroy()
   elseif p.Name=="StairWalkSurface" then table.insert(ramps,p)
   elseif string.match(p.Name,"^Floor_%d") then local v=f.CFrame:PointToObjectSpace(p.Position);p.Size=Vector3.new(w-20,1,d);p.CFrame=f.CFrame*CFrame.new(10,v.Y,0)
   elseif string.match(p.Name,"^StairLanding_") then local v=f.CFrame:PointToObjectSpace(p.Position);p.Size=Vector3.new(20,1,8);p.CFrame=f.CFrame*CFrame.new(-w/2+10,v.Y,v.Z) end
  end
 end
 for _,p in ramps do
  local cf=f.CFrame:ToObjectSpace(p.CFrame);local v=cf.Position;local level=math.floor(v.Y/16)
  local rot=cf-cf.Position;p.CFrame=f.CFrame*CFrame.new(-w/2+(level%2==0 and 5 or 14),v.Y,v.Z)*rot;p.Size=Vector3.new(7,p.Size.Y,p.Size.Z)
 end
end
end
for _,v in workspace.AbandonedCity:GetDescendants() do if v.Name=="InteriorPartition" then v:Destroy() elseif v.Name=="FacadeDebris" then v.CanCollide=false end end
end
function B.Build()
B.Foundation();B.Streets();B.Buildings();B.Decor();B.BridgeCoast();B.Finish()
end
return B


]====];m.Parent=sources end
do local m=Instance.new("ModuleScript");m.Name="CollapsedCoast";m.Source=[====[
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


]====];m.Parent=sources end
do local m=Instance.new("ModuleScript");m.Name="TerrainPrepare";m.Source=[====[
local r=workspace.AbandonedCity
local bak=Instance.new("Folder");bak.Name="BeforeTerrainRavine";bak.Parent=game.ServerStorage
r.CollapsedCityRavine.Parent=bak
if r:FindFirstChild("RepairedCoastRoads") then r.RepairedCoastRoads.Parent=bak end
-- Remove old terrain slabs at the end; the earlier city remains untouched.
for _,m in r:GetChildren() do local z=tonumber(m.Name:match("^DistrictGround_(%d+)$"));if z and z>=12000 then m.Parent=bak end end
for _,p in r.Streets:GetDescendants() do if p:IsA("BasePart") and p.Position.Z>=12000 then p.Parent=bak end end
local f=Instance.new("Model");f.Name="NaturalCityRavine";f.Parent=r
return "All overlapping ravine plates, patch roads and end-ground slabs removed from active map."

]====];m.Parent=sources end
do local m=Instance.new("ModuleScript");m.Name="Terrain";m.Source=[====[
local B={}
function B.Height(x,z)
 local function s(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
 local radius=math.sqrt(((x-100)/1450)^2+((z-13600)/1350)^2)
 local h=6+114*s((radius-0.20)/0.80)
 local channel=6+114*s((math.abs(x-230)-180)/1000)
 if z>13500 then h=math.min(h,120+(channel-120)*s((z-13500)/450)) end
 h=math.min(h,120-134*s((z-13900)/750))
 local rough=math.sin(x/75+z/130)*math.cos(z/83)*2*(1-s((radius-0.7)/0.3))
 return h+rough
end
function B.Chunk(x0,x1)
 local terrain=workspace.Terrain
 for z0=12000,14800,200 do
  local region=Region3.new(Vector3.new(x0,-40,z0),Vector3.new(x1,144,z0+200)):ExpandToGrid(4)
  local n=(region.Size/4);local origin=region.CFrame.Position-region.Size/2
  local mats,occs={},{}
  for ix=1,n.X do
   mats[ix]={};occs[ix]={}
   local x=origin.X+(ix-0.5)*4
   for iy=1,n.Y do mats[ix][iy]={};occs[ix][iy]={} end
   for iz=1,n.Z do
    local z=origin.Z+(iz-0.5)*4;local h=B.Height(x,z)
    for iy=1,n.Y do
     local bottom=origin.Y+(iy-1)*4
     local solid=math.clamp((h-bottom)/4,0,1)
     local mat=Enum.Material.Air;local occ=solid
     if solid>0 then
      if bottom>h-8 then
       local grad=math.abs(B.Height(x+8,z)-B.Height(x-8,z))+math.abs(B.Height(x,z+8)-B.Height(x,z-8))
       mat=grad>5 and Enum.Material.Rock or Enum.Material.Ground
      else mat=Enum.Material.Slate end
     elseif bottom<0 and z>13900 then mat=Enum.Material.Water;occ=math.clamp(-bottom/4,0,1) end
     mats[ix][iy][iz]=mat;occs[ix][iy][iz]=occ
    end
   end
  end
  terrain:WriteVoxels(region,4,mats,occs);task.wait()
 end
 return "Terrain strip "..x0.." to "..x1.." complete"
end
return B

]====];m.Parent=sources end
do local m=Instance.new("ModuleScript");m.Name="CoastDetail";m.Source=[====[
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


]====];m.Parent=sources end
require(sources.BaseCity).Build()
require(sources.CollapsedCoast)
require(sources.TerrainPrepare)
local terrain=require(sources.Terrain)
for x=-3200,2400,800 do terrain.Chunk(x,x+800);task.wait() end
require(sources.CoastDetail)
print("Abandoned City v0.1.0 built. Save the place to a file.")
