-- Studio Edit: verify art cannot change gameplay geometry or own live sockets.
local pack = game.ServerStorage.Assets.Task11MapTemplates
local CS = game:GetService("CollectionService")
local HS = game:GetService("HttpService")
local D = require(game.ReplicatedStorage.Shared.Task11VisualDefinitions)
local P = require(game.ReplicatedStorage.Shared.PlotDefinitions)
local museum = pack.StarterMuseumTemplate
local errors, checked, lightCount = {}, 0, 0
local function check(ok, message) if not ok then table.insert(errors, message) end end
local function art(root)
    for _, d in root:GetDescendants() do
        if d:IsA("BasePart") then
            checked += 1
            check(d.Anchored and not d.CanCollide and not d.CanTouch and not d.CanQuery, d:GetFullName() .. " physics flags")
            check(not CS:HasTag(d, "MapSocket") and d:GetAttribute("SocketId") == nil, d:GetFullName() .. " gameplay socket in art")
        elseif d:IsA("BaseScript") then
            check(false, d:GetFullName() .. " active decorative script")
        elseif d:IsA("Light") then
            lightCount += 1
            check(not d.Shadows, d:GetFullName() .. " dynamic shadow light")
        end
    end
end
local function corners(p, pivot)
    local result = {}
    for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
        table.insert(result, pivot:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size * Vector3.new(x,y,z) / 2)))
    end end end
    return result
end
check(museum.StarterHall.Floor.Size == Vector3.new(60,1,60), "hall footprint changed")
check(museum:GetPivot().Position.Magnitude < 0.001, "source pivot changed")
local ids, sockets, stands = {}, 0, 0
for _, d in museum:GetDescendants() do
    local id = d:GetAttribute("SocketId")
    if id then
        check(not ids[id], "duplicate socket " .. id)
        ids[id], sockets = true, sockets + 1
        if d:GetAttribute("SocketKind") == "ProtectedDisplay" or d:GetAttribute("SocketKind") == "ExposedDisplay" then stands += 1 end
    end
end
check(sockets == 25 and stands == 3, "socket/stand counts changed")
art(museum.ArchitectureVisuals)
art(museum.InteriorVisuals)
check(#pack.LandscapePresets:GetChildren() == 6, "preset count")
for _, preset in D.Presets do
    local model = pack.LandscapePresets:FindFirstChild(preset.id)
    check(model ~= nil, "missing preset " .. preset.id)
    if model then
        art(model)
        check(model:GetAttribute("ClearOnExpansion") == true, "preset must clear with its tier")
        for _, p in model:GetDescendants() do
            if p:IsA("BasePart") then
                local lo, hi = Vector3.new(math.huge,math.huge,math.huge), Vector3.new(-math.huge,-math.huge,-math.huge)
                for _, c in corners(p, model:GetPivot()) do lo=lo:Min(c); hi=hi:Max(c) end
                check(lo.X >= -59 and hi.X <= 59 and lo.Z >= -59 and hi.Z <= 59, p:GetFullName() .. " outside grounds")
                check(hi.X <= -30 or lo.X >= 30 or hi.Z <= -30 or lo.Z >= 30, p:GetFullName() .. " overlaps building")
                check(hi.X <= -9 or lo.X >= 9 or hi.Z <= -60 or lo.Z >= -30, p:GetFullName() .. " overlaps entrance lane")
            end
        end
    end
end
art(pack.SixPlotWorldTemplate.SharedWorldVisuals)
art(pack.SixPlotWorldTemplate.PerimeterDecor)
local boundary = pack.SixPlotWorldTemplate:FindFirstChild("PerimeterCollision")
check(boundary ~= nil, "missing outer collision boundary")
if boundary then
    check(#boundary:GetChildren() == 5, "outer boundary must have five segments and a west connector gap")
    for _, wall in boundary:GetChildren() do
        check(wall:IsA("BasePart") and wall.Anchored and wall.CanCollide and wall.CanQuery
            and not wall.CanTouch and wall.Transparency == 1
            and wall:GetAttribute("Task11Boundary") == true,
            wall:GetFullName() .. " boundary flags")
        if wall:IsA("BasePart") then
            local x, z = math.abs(wall.Position.X), math.abs(wall.Position.Z)
            check((wall.Position.X == 500 and z == 0 and wall.Size == Vector3.new(4,80,1084))
                or (wall.Position.X == -500 and z == 301 and wall.Size == Vector3.new(4,80,482))
                or (z == 540 and x == 0 and wall.Size == Vector3.new(1004,80,4)),
                wall:GetFullName() .. " boundary position or size")
        end
    end
end
for i, a in P.Slots do
    for j = i+1, #P.Slots do
        local b=P.Slots[j]
        check(math.abs(a.center.X-b.center.X) >= 280 or math.abs(a.center.Z-b.center.Z) >= 280, "plot envelopes overlap")
    end
end
local preview=workspace:FindFirstChild("Task11InspectionPreview")
local clones=0
if preview then
    check(not preview.Archivable, "inspection preview would be saved/published")
    for i=1,6 do
        local m=preview.Museums:FindFirstChild(string.format("Museum%02d",i))
        check(m~=nil, "missing preview museum")
        if m then
            clones+=1
            for _, name in {"ArchitectureVisuals","InteriorVisuals","BackyardVisuals"} do
                local count=0
                for _,child in m:GetChildren() do if child.Name==name then count+=1 end end
                check(count==1,m.Name.." duplicate/missing "..name)
            end
            check(m:FindFirstChild("Task11LiveVisuals")==nil,m.Name.." legacy visual duplicate")
            check(m.BackyardVisuals:GetAttribute("PresetId")==D.Presets[i].id,m.Name.." wrong preset")
            local expected=CFrame.new(Vector3.new(2000,0,0)+P.Slots[i].center)*CFrame.Angles(0,math.rad(P.Slots[i].yawDegrees),0)
            check((m:GetPivot().Position-expected.Position).Magnitude<0.01,m.Name.." position changed")
            check((m:GetPivot().LookVector-expected.LookVector).Magnitude<0.001,m.Name.." orientation changed")
        end
    end
end
if #errors>0 then error(HS:JSONEncode(errors)) end
return HS:JSONEncode({passed=true,artParts=checked,sourceLights=lightCount,previewMuseums=clones,sockets=sockets,stands=stands})
