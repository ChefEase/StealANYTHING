--!strict

-- Small outdoor staging areas make unclaimed plots readable in low-population
-- servers. They are temporary: the server removes one before its museum spawns.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Plots = require(ReplicatedStorage.Shared.PlotDefinitions)

local Detail = {}
local cache: {[string]: Model} = {}

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame,
    color: Color3, material: Enum.Material, collides: boolean): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material
    p.Anchored = true
    p.CanCollide = collides
    p.CanTouch = false
    p.CanQuery = collides
    p.CastShadow = collides
    p.Parent = parent
    return p
end

local function makeLot(slot: any, ground: BasePart): Model
    local lot = Instance.new("Model")
    lot.Name = "Vacant_" .. slot.id
    lot:SetAttribute("PlotId", slot.id)
    local center = ground.CFrame:PointToWorldSpace(Vector3.new(
        slot.center.X, ground.Size.Y / 2, slot.center.Z))
    local base = CFrame.new(center) * CFrame.Angles(0, math.rad(slot.yawDegrees), 0)

    -- The shallow color field is walkable and does not change the plot terrain.
    part(lot, "StoneYard", Vector3.new(142, 0.08, 138),
        base * CFrame.new(0, 0.045, 0), Color3.fromRGB(55, 70, 69),
        Enum.Material.Slate, false)
    part(lot, "InnerYard", Vector3.new(112, 0.09, 108),
        base * CFrame.new(0, 0.095, 0), Color3.fromRGB(86, 91, 82),
        Enum.Material.Concrete, false)

    -- A closed restoration annex gives an unclaimed lot an urban silhouette.
    -- The entire model disappears before the server spawns an owned museum.
    local annex = Instance.new("Model")
    annex.Name = "UnclaimedAnnex"
    annex.WorldPivot = base
    annex:SetAttribute("VisualSwapSlot", "UnclaimedAnnex")
    annex:SetAttribute("VisualBounds", Vector3.new(58, 17, 48))
    annex.Parent = lot
    local visual = Instance.new("Model")
    visual.Name = "Visual"
    visual.WorldPivot = base
    visual.Parent = annex
    local body = part(visual, "AnnexVisual", Vector3.new(58, 17, 48),
        base * CFrame.new(0, 8.5, 0), Color3.fromRGB(79, 75, 73),
        Enum.Material.Brick, false)
    body.CastShadow = true
    local roof = part(visual, "RoofVisual", Vector3.new(62, 1, 52),
        base * CFrame.new(0, 17.5, 0), Color3.fromRGB(42, 52, 57),
        Enum.Material.Metal, false)
    roof.CastShadow = true
    part(visual, "FrontBand", Vector3.new(54, 1, 0.4),
        base * CFrame.new(0, 13, -24.25), Color3.fromRGB(176, 135, 91),
        Enum.Material.Metal, false)
    local sign = part(visual, "MuseumSiteSign", Vector3.new(26, 3.5, 0.35),
        base * CFrame.new(0, 9.5, -24.3), Color3.fromRGB(38, 50, 54),
        Enum.Material.Metal, false)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.PixelsPerStud = 20
    gui.LightInfluence = 0
    gui.Parent = sign
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "MUSEUM SITE " .. string.sub(slot.id, -2)
    label.TextColor3 = Color3.fromRGB(237, 191, 121)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = gui
    local hull = part(annex, "CollisionProxy", Vector3.new(58, 17, 48),
        base * CFrame.new(0, 8.5, 0), Color3.new(0, 0, 0),
        Enum.Material.SmoothPlastic, true)
    hull.Transparency = 1

    -- Low, solid planters occupy corners, leaving a broad center aisle.
    for _, side in {-1, 1} do
        for _, endSign in {-1, 1} do
            local x = side * 43
            local z = endSign * 41
            part(lot, "BrickPlanter", Vector3.new(17, 2.2, 12),
                base * CFrame.new(x, 1.1, z), Color3.fromRGB(124, 83, 67),
                Enum.Material.Brick, true)
            part(lot, "PlanterLeaves", Vector3.new(13, 2.1, 8),
                base * CFrame.new(x, 3.2, z), Color3.fromRGB(60, 106, 79),
                Enum.Material.Grass, true)
        end
    end

    for _, side in {-1, 1} do
        local x = side * 37
        local post = part(lot, "SignalPost", Vector3.new(2, 9, 2),
            base * CFrame.new(x, 4.5, 0), Color3.fromRGB(47, 51, 57),
            Enum.Material.Metal, true)
        local lamp = part(lot, "SignalLamp", Vector3.new(3.4, 1.3, 3.4),
            base * CFrame.new(x, 9.5, 0),
            if side < 0 then Color3.fromRGB(74, 188, 170) else Color3.fromRGB(225, 160, 96),
            Enum.Material.Neon, false)
        local light = Instance.new("PointLight")
        light.Color = lamp.Color
        light.Brightness = 0.6
        light.Range = 20
        light.Parent = lamp
        post:SetAttribute("VacantPlotSignal", true)
    end
    return lot
end

function Detail.Build(world: Model)
    local old = world:FindFirstChild("VacantPlotScenery")
    if old then old:Destroy() end
    table.clear(cache)
    local ground = world:FindFirstChild("Ground")
    if ground == nil or not ground:IsA("BasePart") then return end
    local folder = Instance.new("Folder")
    folder.Name = "VacantPlotScenery"
    folder.Parent = world
    for _, slot in Plots.Slots do
        local lot = makeLot(slot, ground)
        lot.Parent = folder
        cache[slot.id] = lot
    end
end

function Detail.Hide(plotId: string)
    local lot = cache[plotId]
    if lot then lot.Parent = nil end
end

function Detail.Show(world: Model, plotId: string)
    local folder = world:FindFirstChild("VacantPlotScenery")
    local lot = cache[plotId]
    if folder and lot then lot.Parent = folder end
end

return table.freeze(Detail)
