-- Studio Edit: repeatable Task 11b fix for the playable main museum prototype.
-- Workspace.Map is Studio-managed; this script records the exact intended edits.
local map = assert(workspace:FindFirstChild("Map"), "Playable Map missing")
local exterior = assert(map:FindFirstChild("ExteriorDressing"))
local front = assert(map:FindFirstChild("FrontDecor"))

local plaza = assert(exterior:FindFirstChild("ApproachPlaza"))
assert(plaza:IsA("BasePart") and plaza.Size == Vector3.new(40, 0.08, 20),
    "Main museum approach floor changed unexpectedly")
local original = Vector3.new(65, 0.64, 35)
local target = Vector3.new(65, 0.71, 35)
assert((plaza.Position - original).Magnitude < 0.02
    or (plaza.Position - target).Magnitude < 0.02,
    "Main museum approach floor moved unexpectedly")
if (plaza.Position - target).Magnitude >= 0.02 then
    plaza.CFrame += target - plaza.Position
end
assert(plaza.CanCollide, "Main museum approach floor must stay collidable")

-- The four foliage pieces belong to the two entrance courtyard shrubs.
-- Their planter bases also block movement so an avatar cannot enter below
-- the foliage. All positions and visual geometry remain unchanged.
for _, name in {"CourtyardPlanter3", "CourtyardPlanter4",
    "CourtyardPlant3", "CourtyardPlant4",
    "CourtyardPlantTop3", "CourtyardPlantTop4"} do
    local p = assert(exterior:FindFirstChild(name), "Missing courtyard part: " .. name)
    assert(p:IsA("BasePart") and p.Anchored, "Courtyard part changed: " .. name)
    p.CanCollide = true
end

-- The near freestanding podium was decorative-only; the podium beside the
-- entrance already had a solid base but its sign board could be walked through.
for _, spec in {
    {exterior, "CourtyardCenterBase"},
    {exterior, "CourtyardCenterPillar"},
    {front, "PodiumBoard"},
} do
    local p = assert(spec[1]:FindFirstChild(spec[2]), "Missing podium part: " .. spec[2])
    assert(p:IsA("BasePart") and p.Anchored, "Podium part changed: " .. spec[2])
    p.CanCollide = true
end

print("Task 11b: main museum plaza, courtyard shrubs, and podium collisions corrected")
