-- Studio Edit: correct the playable prototype's hill and bench surroundings.
-- The prototype map is a Studio-managed asset, so keep these edits repeatable.
local map = assert(workspace:FindFirstChild("Map"), "Playable Map missing")

local function moveFrom(part, original, target, previous)
    assert(part and part:IsA("BasePart"), "Expected prototype part missing")
    if (part.Position - target).Magnitude < 0.02 then return end
    assert((part.Position - original).Magnitude < 0.02
        or (previous ~= nil and (part.Position - previous).Magnitude < 0.02),
        "Prototype part moved unexpectedly: " .. part:GetFullName())
    part.CFrame += target - part.Position
end

-- These two southeast ellipsoids crossed the east wall of Museum01.
moveFrom(map.HillTerrain.HillSEMain,
    Vector3.new(95, 6, 78), Vector3.new(112, 6, 78), Vector3.new(105, 6, 78))
moveFrom(map.HillTerrain.HillSEBump2,
    Vector3.new(87, 3.5, 70.5), Vector3.new(105, 3.5, 70.5),
    Vector3.new(99, 3.5, 70.5))

-- Move the two entrance trees onto the adjacent grass, clear of all four benches.
for _, spec in {
    {prefix = "ExtTreeB4", originalX = 50, targetX = 38},
    {prefix = "ExtTreeB5", originalX = 80, targetX = 92},
} do
    local trunk = assert(map.LandscapeArt:FindFirstChild(spec.prefix .. "Trunk"),
        "Prototype tree trunk missing: " .. spec.prefix)
    if math.abs(trunk.Position.X - spec.targetX) >= 0.02 then
        assert(math.abs(trunk.Position.X - spec.originalX) < 0.02,
            "Prototype tree moved unexpectedly: " .. spec.prefix)
        local moved = 0
        for _, part in map.LandscapeArt:GetDescendants() do
            if part:IsA("BasePart") and part.Name:sub(1, #spec.prefix) == spec.prefix then
                part.CFrame += Vector3.new(spec.targetX - spec.originalX, 0, 0)
                moved += 1
            end
        end
        assert(moved >= 6, "Tree parts missing: " .. spec.prefix)
    end
end

-- The depot's upper shelf was directly through the seated avatar's torso.
moveFrom(map.Depot.DepotArt.StockDisplayShelf,
    Vector3.new(-105, 3.2, -73), Vector3.new(-105, 3.2, -65))

print("Task 11 prototype hills, bench trees, and depot shelf cleared")
