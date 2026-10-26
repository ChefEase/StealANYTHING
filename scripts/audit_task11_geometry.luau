-- Read-only snapshot audit recorded before the v3 art pass.
local pack=game.ServerStorage.Assets.Task11MapTemplates
local HS=game:GetService("HttpService")
local function signature(root)
 local rows={}
 for _,d in root:GetDescendants() do
  local visual=false
  local p=d
  while p and p~=root do
   if table.find({"ArchitectureVisuals","InteriorVisuals","BackyardVisuals","SharedWorldVisuals","PerimeterDecor","PerimeterCollision","Task11LiveVisuals","Task11PrototypeSeats"},p.Name) then visual=true break end
   p=p.Parent
  end
  if not visual and d:IsA("BasePart") then
   local values={d:GetFullName():sub(#root:GetFullName()+2),tostring(d.Size),tostring(d.CFrame),tostring(d.CanCollide),tostring(d.CanTouch),tostring(d.CanQuery)}
   local keys={}
   for k in d:GetAttributes() do keys[#keys+1]=k end
   table.sort(keys)
   for _,k in keys do values[#values+1]=k.."="..tostring(d:GetAttribute(k)) end
   rows[#rows+1]=table.concat(values,"|")
  end
 end
 table.sort(rows)
 local s=table.concat(rows,"\n")
 local a,b=1,0
 for i=1,#s do a=(a+string.byte(s,i))%65521; b=(b+a)%65521 end
 return {count=#rows,hash=b*65536+a}
end
return HS:JSONEncode({museum=signature(pack.StarterMuseumTemplate),world=signature(pack.SixPlotWorldTemplate),prototype=signature(workspace.Map)})
