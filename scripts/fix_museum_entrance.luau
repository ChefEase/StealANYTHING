-- Run once in the connected place's Studio Edit command bar if the entrance
-- dressing is restored from an older map backup. Workspace/Map is Studio-owned.
local map = workspace:WaitForChild("Map")
local facade = map.Museum01.MuseumFacadeArt
local exterior = map.ExteriorDressing

local function place(parent: Instance, name: string, position: Vector3, size: Vector3)
    local part = parent:FindFirstChild(name)
    assert(part and part:IsA("BasePart"), "Missing entrance part: " .. name)
    part.Size = size
    part.CFrame = CFrame.new(position)
end

-- Hide the coplanar route slabs beneath one continuous forecourt surface.
place(exterior, "ApproachPlaza", Vector3.new(65, 0.64, 35), Vector3.new(40, 0.08, 20))
exterior.ApproachPlaza.CanCollide = true
exterior.ApproachPlaza.CanQuery = true

-- Adjacent bands meet at their edges; the old parts overlapped in depth.
place(exterior, "EntranceStep-1", Vector3.new(65, 0.73, 41.5), Vector3.new(14, 0.10, 1))
place(exterior, "EntranceStep0", Vector3.new(65, 0.78, 42.5), Vector3.new(14, 0.20, 1))
place(exterior, "EntranceStep1", Vector3.new(65, 0.83, 43.5), Vector3.new(14, 0.30, 1))
place(exterior, "EntranceMat", Vector3.new(65, 0.895, 42.5), Vector3.new(12, 0.025, 0.9))
place(facade, "EntryThreshold", Vector3.new(65, 0.86, 44.5), Vector3.new(12, 0.36, 1))
for _, part in { exterior["EntranceStep-1"], exterior.EntranceStep0,
    exterior.EntranceStep1, facade.EntryThreshold } do
    part.CanCollide = true
    part.CanQuery = true
end

-- Use the solid front wall as the visible upper surface, with no duplicate skin.
for _, name in { "LeftWallPanel", "RightWallPanel",
    "LeftWallPanelFrame", "RightWallPanelFrame" } do
    local part = facade[name]
    part.Transparency = 1
    part.CanCollide = false
    part.CanQuery = false
end
map.Museum01.SouthWallLeft.Material = Enum.Material.Limestone
map.Museum01.SouthWallRight.Material = Enum.Material.Limestone

-- These later decorative columns shared the exact front plane of the core
-- wall. The facade pilasters already provide the visible entrance columns.
for _, name in { "EntranceColumnLeft", "EntranceColumnRight",
    "EntranceColumnLeftBase", "EntranceColumnRightBase",
    "EntranceColumnLeftCap", "EntranceColumnRightCap" } do
    local part = exterior[name]
    part.Transparency = 1
    part.CanCollide = false
    part.CanQuery = false
end

print("Museum entrance dressing repaired")
