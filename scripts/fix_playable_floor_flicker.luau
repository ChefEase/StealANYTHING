-- Run in Studio Edit with Workspace.Map loaded. Workspace.Map is Studio-managed.
-- Removes overlapping coplanar visual floor surfaces without changing hitboxes.
local map = assert(workspace:FindFirstChild("Map"), "Playable Map missing")
local covered = assert(map:FindFirstChild("CoveredRoute"))
local open = assert(map:FindFirstChild("OpenRoute"))
local art = assert(map:FindFirstChild("RouteArt"))
local exterior = assert(map:FindFirstChild("ExteriorDressing"))

local function setTop(part, top)
    assert(part and part:IsA("BasePart"), "Floor visual missing")
    assert(part.Anchored and not part.CanCollide, "Expected static noncolliding floor visual: " .. part.Name)
    part.CFrame += Vector3.new(0, top - (part.Position.Y + part.Size.Y / 2), 0)
end

for i = 1, 4 do
    setTop(covered:FindFirstChild(string.format("Covered%02dPath", i)), 0.58 + (i - 1) * 0.02)
end
for i = 1, 3 do
    setTop(covered:FindFirstChild(string.format("WideCorner%02d", i)), 0.66 + (i - 1) * 0.02)
end
for i = 1, 2 do
    setTop(open:FindFirstChild(string.format("Open%02dPath", i)), if i == 1 then 0.72 else 0.66)
end

local plaza = assert(exterior:FindFirstChild("ApproachPlaza"))
assert(plaza:IsA("BasePart") and plaza.CanCollide, "Authoritative museum approach changed")
-- Leave the already corrected collidable plaza intact.

local start = Vector2.new(-92, -72)
local finish = Vector2.new(65, 43)
local direction = (finish - start).Unit
local trim = 34
for _, side in {-1, 1} do
    local edge = assert(art:FindFirstChild("OpenEdge1" .. side))
    assert(edge:IsA("BasePart") and not edge.CanCollide and edge.Size.Z > trim + 10)
    -- Preserve each strip's rotation, side offset, material and width.
    -- Set from its original long length or leave the already trimmed length.
    local targetLength = (finish - start).Magnitude - 2 - trim
    if math.abs(edge.Size.Z - targetLength) > 0.02 then
        local previousTrim = (finish - start).Magnitude - 2 - edge.Size.Z
        local additionalTrim = trim - previousTrim
        edge.Size = Vector3.new(edge.Size.X, edge.Size.Y, targetLength)
        edge.CFrame += Vector3.new(-direction.X * additionalTrim / 2,
            0, -direction.Y * additionalTrim / 2)
    end
    setTop(edge, 0.815)
end
for _, edgeName in {"OpenEdge2-1", "OpenEdge21"} do
    local edge = art:FindFirstChild(edgeName)
    if edge then edge:Destroy() end -- edge ran through the museum approach
end
for i = 1, 10 do
    local joint = art:FindFirstChild(string.format("PavingJoint%02d", i))
    if joint then
        if joint.Position.X >= 45 then joint:Destroy() else setTop(joint, 0.759) end
    end
end
for _, item in art:GetChildren() do
    if item:IsA("BasePart") then
        if item.Name:match("^OpenArrow") then setTop(item, 0.7725)
        elseif item.Name:match("^ServiceFloorJoint") then setTop(item, 0.795) end
    end
end

-- Perimeter grass strips had four identical coplanar corner overlaps.
for _, name in {"LawnEdgeN", "LawnEdgeS"} do
    local strip = assert(exterior:FindFirstChild(name))
    assert(strip:IsA("BasePart"))
    strip.Size = Vector3.new(206, strip.Size.Y, strip.Size.Z)
end
for _, name in {"DirtPatch1", "DirtPatch2", "GravelPatch1"} do
    local patch = assert(exterior:FindFirstChild(name))
    assert(patch:IsA("BasePart") and not patch.CanCollide)
    setTop(patch, 0.57)
end

print("Playable floor visual seams corrected; gameplay hitboxes unchanged")
