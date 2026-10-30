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
