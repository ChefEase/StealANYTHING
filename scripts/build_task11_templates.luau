-- Run in the connected place's Studio Edit command context after Rojo sync.
-- Creates source assets only. Task 12 activates them and assigns plots.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Plots = require(ReplicatedStorage.Shared.PlotDefinitions)
local assets = assert(ServerStorage:FindFirstChild("Assets"), "Missing ServerStorage/Assets")
local sourceMap = assert(workspace:FindFirstChild("Map"), "Missing playable prototype Map")
local sourceMuseum = assert(sourceMap:FindFirstChild("Museum01"), "Missing Museum01")

local pack = Instance.new("Folder")
pack.Name = "Task11MapTemplates"
pack:SetAttribute("GeneratedBy", "scripts/build_task11_templates.luau")
pack:SetAttribute("TemplateVersion", 1)

local archive = sourceMuseum:Clone()
archive.Name = "PrototypeMuseumSource"
archive:SetAttribute("SourceFootprint", "36x30")
archive.Parent = pack

local function part(parent, name, size, cf, color, material, collide, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.Material = material or Enum.Material.SmoothPlastic
    p.Color = color or Color3.fromRGB(209, 204, 190)
    p.Transparency = transparency or 0
    p.CanCollide = collide == true
    p.CanTouch = false
    p.CanQuery = collide == true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function socket(parent, name, cf, size, anchorId, kind)
    local p = part(parent, name, size, cf, Color3.new(1, 1, 1),
        Enum.Material.SmoothPlastic, false, 1)
    p.CanQuery = true
    p.CanTouch = true
    p:SetAttribute("AnchorId", anchorId)
    p:SetAttribute("SocketId", "template." .. anchorId)
    p:SetAttribute("SocketKind", kind)
    CollectionService:AddTag(p, "MapSocket")
    return p
end

local stone = Color3.fromRGB(220, 215, 198)
local darkStone = Color3.fromRGB(89, 103, 98)
local trim = Color3.fromRGB(172, 131, 66)
local grass = Color3.fromRGB(94, 135, 102)
local pathColor = Color3.fromRGB(185, 179, 166)

local museum = Instance.new("Model")
museum.Name = "StarterMuseumTemplate"
museum:SetAttribute("TemplateVersion", 1)
museum:SetAttribute("Tier", 1)
museum:SetAttribute("BuildingStuds", 60)
museum:SetAttribute("GroundsStuds", 120)
museum:SetAttribute("StandCount", 3)
museum.WorldPivot = CFrame.new(0, 0, 0)
museum.Parent = pack

local grounds = Instance.new("Model")
grounds.Name = "GroundsTier1"
grounds.Parent = museum
part(grounds, "Lawn", Vector3.new(120, 0.3, 120), CFrame.new(0, 0.15, 0),
    grass, Enum.Material.Grass, true)
part(grounds, "FrontWalk", Vector3.new(16, 0.08, 30),
    CFrame.new(0, 0.37, -45), pathColor, Enum.Material.Pavement, false)
local fenceHeight = 12
local fenceY = 6.3
local fenceColor = Color3.fromRGB(108, 116, 105)
for _, spec in {
    { "BackFence", Vector3.new(120, fenceHeight, 1), CFrame.new(0, fenceY, 59.5) },
    { "LeftFence", Vector3.new(1, fenceHeight, 120), CFrame.new(-59.5, fenceY, 0) },
    { "RightFence", Vector3.new(1, fenceHeight, 120), CFrame.new(59.5, fenceY, 0) },
    { "FrontFenceLeft", Vector3.new(52, fenceHeight, 1), CFrame.new(-34, fenceY, -59.5) },
    { "FrontFenceRight", Vector3.new(52, fenceHeight, 1), CFrame.new(34, fenceY, -59.5) },
} do
    part(grounds, spec[1], spec[2], spec[3], fenceColor, Enum.Material.Limestone, true)
end
socket(grounds, "PlotGate", CFrame.new(0, 3, -60), Vector3.new(16, 6, 2),
    "plot_gate", "PlotGate")

local hall = Instance.new("Model")
hall.Name = "StarterHall"
hall.Parent = museum
part(hall, "Floor", Vector3.new(60, 1, 60), CFrame.new(0, 0.8, 0),
    Color3.fromRGB(214, 207, 189), Enum.Material.Limestone, true)
part(hall, "NorthWall", Vector3.new(60, 17, 1), CFrame.new(0, 9.8, 29.5),
    stone, Enum.Material.Limestone, true)
part(hall, "WestWall", Vector3.new(1, 17, 60), CFrame.new(-29.5, 9.8, 0),
    stone, Enum.Material.Limestone, true)
part(hall, "EastWall", Vector3.new(1, 17, 60), CFrame.new(29.5, 9.8, 0),
    stone, Enum.Material.Limestone, true)
part(hall, "SouthWallLeft", Vector3.new(23, 17, 1), CFrame.new(-18.5, 9.8, -29.5),
    stone, Enum.Material.Limestone, true)
part(hall, "SouthWallRight", Vector3.new(23, 17, 1), CFrame.new(18.5, 9.8, -29.5),
    stone, Enum.Material.Limestone, true)
part(hall, "DoorLintel", Vector3.new(14, 3, 1), CFrame.new(0, 16.8, -29.5),
    darkStone, Enum.Material.Limestone, true)
part(hall, "Roof", Vector3.new(60, 1, 60), CFrame.new(0, 18.8, 0),
    darkStone, Enum.Material.Limestone, true)
part(hall, "LeftDoorTrim", Vector3.new(0.6, 14, 0.5), CFrame.new(-7.3, 8.3, -29.75),
    trim, Enum.Material.Metal, false)
part(hall, "RightDoorTrim", Vector3.new(0.6, 14, 0.5), CFrame.new(7.3, 8.3, -29.75),
    trim, Enum.Material.Metal, false)
part(hall, "ReceivingPad", Vector3.new(10, 0.08, 10), CFrame.new(0, 1.35, -20),
    Color3.fromRGB(66, 173, 155), Enum.Material.SmoothPlastic, false)
part(hall, "ProtectedStand", Vector3.new(7, 2, 7), CFrame.new(0, 2.3, 17),
    Color3.fromRGB(133, 94, 48), Enum.Material.Wood, true)
part(hall, "ProtectedStandTop", Vector3.new(8, 0.2, 8), CFrame.new(0, 3.4, 17),
    trim, Enum.Material.Metal, true)
for _, stand in { { "Exposed01", -18 }, { "Exposed02", 18 } } do
    part(hall, stand[1] .. "Stand", Vector3.new(5, 2, 5), CFrame.new(stand[2], 2.3, 8),
        Color3.fromRGB(125, 109, 88), Enum.Material.Wood, true)
    part(hall, stand[1] .. "StandTop", Vector3.new(6, 0.2, 6),
        CFrame.new(stand[2], 3.4, 8), stone, Enum.Material.Limestone, true)
end
part(hall, "RecoveryConsole", Vector3.new(3, 4, 2), CFrame.new(-23, 3.3, -10),
    Color3.fromRGB(210, 137, 64), Enum.Material.Metal, true)

socket(museum, "PlayerSpawn", CFrame.new(0, 3, 25), Vector3.new(6, 3, 6),
    "spawn", "PlayerSpawn")
socket(museum, "ReceivingZone", CFrame.new(0, 3, -20), Vector3.new(10, 4, 10),
    "receiving", "ReceivingZone")
socket(museum, "ProtectedDisplaySocket", CFrame.new(0, 4.5, 17),
    Vector3.new(8, 3, 8), "protected", "ProtectedDisplay")
socket(museum, "Exposed01Socket", CFrame.new(-18, 4.5, 8),
    Vector3.new(6, 3, 6), "exposed_01", "ExposedDisplay")
socket(museum, "Exposed02Socket", CFrame.new(18, 4.5, 8),
    Vector3.new(6, 3, 6), "exposed_02", "ExposedDisplay")
socket(museum, "RecoveryConsoleSocket", CFrame.new(-23, 3.3, -10),
    Vector3.new(4, 5, 3), "recovery_console", "RecoveryConsole")
socket(museum, "RaidEntrance", CFrame.new(0, 7.5, -29.5),
    Vector3.new(14, 13, 2), "raid_entrance", "RaidEntrance")
socket(museum, "Approach", CFrame.new(0, 3, -35),
    Vector3.new(8, 4, 8), "approach", "Approach")

local seams = Instance.new("Folder")
seams.Name = "ExpansionAnchors"
seams.Parent = museum
for tierIndex = 2, #Plots.Tiers do
    local tier = Plots.Tiers[tierIndex]
    for _, edge in {
        { "North", Vector3.new(0, 2, tier.buildingStuds / 2) },
        { "East", Vector3.new(tier.buildingStuds / 2, 2, 0) },
        { "South", Vector3.new(0, 2, -tier.buildingStuds / 2) },
        { "West", Vector3.new(-tier.buildingStuds / 2, 2, 0) },
    } do
        local anchor = socket(seams, "Tier" .. tierIndex .. edge[1],
            CFrame.new(edge[2]), Vector3.new(1, 1, 1),
            "tier_" .. tierIndex .. "_" .. string.lower(edge[1]), "ExpansionAnchor")
        anchor:SetAttribute("BuildingStuds", tier.buildingStuds)
        anchor:SetAttribute("GroundsStuds", tier.groundsStuds)
    end
end

local world = Instance.new("Model")
world.Name = "SixPlotWorldTemplate"
world:SetAttribute("TemplateVersion", 1)
world:SetAttribute("MaximumEnvelopeStuds", Plots.MaximumEnvelopeStuds)
world.WorldPivot = CFrame.new(0, 0, 0)
world.Parent = pack
part(world, "Ground", Vector3.new(Plots.WorldGroundStuds.X, 1, Plots.WorldGroundStuds.Y),
    CFrame.new(0, -0.5, 0), grass, Enum.Material.Grass, true)
part(world, "DepotPlaza", Vector3.new(84, 0.18, 84), CFrame.new(0, 0.09, 0),
    pathColor, Enum.Material.Pavement, true)

local depot = Instance.new("Model")
depot.Name = "Depot"
depot.Parent = world
part(depot, "Platform", Vector3.new(70, 0.6, 70), CFrame.new(0, 0.39, 0),
    darkStone, Enum.Material.Limestone, true)
for _, entry in {
    { name = "Tutorial", x = 0, z = -18, id = "depot.tutorial_pedestal" },
    { name = "Public01", x = -20, z = 12, id = "depot.public_01" },
    { name = "Public02", x = 0, z = 12, id = "depot.public_02" },
    { name = "Public03", x = 20, z = 12, id = "depot.public_03" },
} do
    part(depot, entry.name .. "Pedestal", Vector3.new(8, 2, 8),
        CFrame.new(entry.x, 1.7, entry.z),
        entry.name == "Tutorial" and trim or stone, Enum.Material.Limestone, true)
    local anchor = socket(depot, entry.name .. "PedestalSocket",
        CFrame.new(entry.x, 3, entry.z), Vector3.new(8, 3, 8),
        entry.id, "DepotPedestal")
    anchor:SetAttribute("SocketId", entry.id)
end

local layout = Instance.new("Folder")
layout.Name = "PlotSlots"
layout.Parent = world
local routes = Instance.new("Folder")
routes.Name = "Routes"
routes.Parent = world

local function strip(parent, name, a, b, width, height, color)
    local a3 = Vector3.new(a.X, height, a.Z)
    local b3 = Vector3.new(b.X, height, b.Z)
    local mid = (a3 + b3) * 0.5
    local p = part(parent, name, Vector3.new(width, 0.1, (b3 - a3).Magnitude),
        CFrame.lookAt(mid, b3), color, Enum.Material.Pavement, false)
    return p
end

for index, definition in Plots.Slots do
    local plot = Instance.new("Model")
    plot.Name = definition.id
    plot:SetAttribute("PlotId", definition.id)
    plot:SetAttribute("YawDegrees", definition.yawDegrees)
    plot.Parent = layout
    local cf = CFrame.new(definition.center) * CFrame.Angles(0,
        math.rad(definition.yawDegrees), 0)
    local front = cf:VectorToWorldSpace(Vector3.new(0, 0, -1))
    local side = cf:VectorToWorldSpace(Vector3.new(
        ({ -1, 1, -1, -1, 1, -1 })[index], 0, 0))
    local gate1 = definition.center + front * 60
    local gate5 = definition.center + front * 140
    local coveredMid = gate1 + front * 85 + side * 95
    local coveredNear = gate1 + front * 30 + side * 95

    socket(plot, "Origin", cf, Vector3.new(2, 2, 2),
        definition.id .. ".origin", "PlotOrigin")
    socket(plot, "GateTier1", CFrame.new(gate1), Vector3.new(16, 6, 2),
        definition.id .. ".gate_tier_1", "PlotGate")
    socket(plot, "GateTier5", CFrame.new(gate5), Vector3.new(16, 6, 2),
        definition.id .. ".gate_tier_5", "PlotGate")
    local envelope = part(plot, "MaximumEnvelope", Vector3.new(280, 0.1, 280),
        CFrame.new(definition.center.X, -0.2, definition.center.Z),
        Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, false, 1)
    envelope:SetAttribute("PlotId", definition.id)
    envelope:SetAttribute("ReservedStuds", 280)
    local tier5 = part(plot, "Tier5BuildingOutline", Vector3.new(170, 0.1, 170),
        CFrame.new(definition.center.X, -0.1, definition.center.Z)
            * CFrame.Angles(0, math.rad(definition.yawDegrees), 0),
        Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, false, 1)
    tier5:SetAttribute("BuildingStuds", 170)

    strip(routes, "Open" .. index, Vector3.zero, gate1, 18, 0.14, pathColor)
    for waypointIndex, point in { coveredMid, coveredNear } do
        socket(routes, "Covered" .. index .. "Waypoint" .. waypointIndex,
            CFrame.new(point), Vector3.new(2, 2, 2),
            definition.id .. ".covered_" .. waypointIndex, "RouteWaypoint")
    end
    for tierIndex = 2, #Plots.Tiers do
        local tierGate = definition.center + front * (Plots.Tiers[tierIndex].groundsStuds / 2)
        local tierMid = tierGate + front * 70 + side * 75
        local tierNear = tierGate + front * 15 + side * 75
        for waypointIndex, point in { tierMid, tierNear } do
            local anchor = socket(routes,
                "CoveredTier" .. tierIndex .. "Plot" .. index .. "Waypoint" .. waypointIndex,
                CFrame.new(point), Vector3.new(2, 2, 2),
                definition.id .. ".tier_" .. tierIndex .. "_covered_" .. waypointIndex,
                "RouteWaypoint")
            anchor:SetAttribute("Tier", tierIndex)
        end
    end
    -- A wall divides the direct approach from the covered offset; leave the
    -- 14-stud covered lane on the outer side of the wall.
    local coverCenter = gate1 + front * 55 + side * 48
    local wallCf = CFrame.lookAt(Vector3.new(coverCenter.X, 6, coverCenter.Z),
        Vector3.new(coverCenter.X, 6, coverCenter.Z) + front)
    part(routes, "CoverWall" .. index, Vector3.new(48, 12, 2), wallCf,
        darkStone, Enum.Material.Limestone, true)
end

local prior = assets:FindFirstChild(pack.Name)
if prior ~= nil then
    assert(prior:GetAttribute("GeneratedBy") == "scripts/build_task11_templates.luau",
        "Refusing to replace an unrelated MapTemplates asset")
    prior:Destroy()
end
pack.Parent = assets
print("Task 11 templates built: six plot slots, one 60x60 starter museum,"
    .. " three stands, four depot pedestals, and archived prototype")
