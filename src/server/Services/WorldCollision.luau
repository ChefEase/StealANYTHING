--!strict

-- Imported visual meshes are deliberately non-colliding. Give objects a
-- simple invisible hull so players cannot walk through their solid body.
local WorldCollision = {}

local HULL_MODELS = {
    PremiumBench = true,
    SculptureMesh = true,
    B5RoundPlanter = true,
    ReceptionDeskVisual = true,
    RidgeToeRock = true,
    Rock_Hero = true,
    RockArch = true,
    B6_RockTall = true,
}

local SOLID_PARTS = {
    DepotColumn = true,
    DepotCanopyColumn = true,
    PavilionEntryPost = true,
    CuratorCounter = true,
    Trunk = true,
    LogisticsCrate = true,
    Crate_Body = true,
    Crate1 = true,
    Crate2 = true,
    Gen_Body = true,
    Stone = true,
    RidgeBoulder = true,
    RockArch_Bridge = true,
    RockLeg_Left = true,
    RockLeg_Right = true,
    Rock_Mid_A = true,
    Rock_Mid_B = true,
    Rock_Small_A = true,
    Rock_Small_B = true,
    B6_RockTall_Body = true,
    Pole = true,
    Bollard = true,
    WayfindingPost = true,
    UtilityCabinet = true,
    EstatePier = true,
    FrontEstateWall = true,
    SideEstateWall = true,
    EstateEdge = true,
    Wayfinding = true,
}

local function addHull(model: Model)
    if model:FindFirstChild("CollisionHull") then return end
    local frame, bounds = model:GetBoundingBox()
    if bounds.X < 0.25 or bounds.Z < 0.25 then return end
    local height = math.min(bounds.Y, 6)
    local hull = Instance.new("Part")
    hull.Name = "CollisionHull"
    hull.Size = Vector3.new(bounds.X, height, bounds.Z)
    hull.CFrame = frame * CFrame.new(0, -(bounds.Y - height) / 2, 0)
    hull.Transparency = 1
    hull.Anchored = true
    hull.CanCollide = true
    hull.CanTouch = false
    hull.CanQuery = true
    hull.Parent = model
end

function WorldCollision.Prepare(root: Instance)
    for _, item in root:GetDescendants() do
        if item:IsA("Model") and HULL_MODELS[item.Name] then
            addHull(item)
        elseif item:IsA("BasePart") and (SOLID_PARTS[item.Name]
            or string.match(item.Name, "^DistantTree%d+Trunk$") ~= nil)
            and item.Transparency < 0.75 then
            item.CanCollide = true
        end
    end
end

return table.freeze(WorldCollision)
