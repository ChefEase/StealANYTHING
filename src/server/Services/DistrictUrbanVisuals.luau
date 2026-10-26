--!strict

-- Runtime-only visual layer for the six-plot district. Every building in this
-- file sits outside the reserved 280 x 280 museum envelopes. Visible art and
-- simple collision hulls are separate so Blender meshes can replace the art.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Plots = require(ReplicatedStorage.Shared.PlotDefinitions)

local Urban = {}
local BRICK = Color3.fromRGB(99, 72, 69)
local BLUE_STONE = Color3.fromRGB(67, 79, 88)
local WARM_STONE = Color3.fromRGB(113, 99, 79)
local DARK_METAL = Color3.fromRGB(39, 49, 55)
local WARM_LIGHT = Color3.fromRGB(238, 178, 105)
local TEAL_LIGHT = Color3.fromRGB(91, 194, 178)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame,
    color: Color3, material: Enum.Material, collision: boolean): Part
    local item = Instance.new("Part")
    item.Name = name
    item.Size = size
    item.CFrame = cf
    item.Color = color
    item.Material = material
    item.Anchored = true
    item.CanCollide = collision
    item.CanQuery = collision
    item.CanTouch = false
    item.CastShadow = collision or (size.Y > 3 and material ~= Enum.Material.Neon)
    item.Parent = parent
    return item
end

local function localGround(ground: BasePart, x: number, z: number): Vector3
    return ground.CFrame:PointToWorldSpace(Vector3.new(x, ground.Size.Y / 2, z))
end

local function module(parent: Instance, name: string, cf: CFrame,
    width: number, depth: number, height: number, color: Color3,
    accent: Color3, signText: string?): Model
    local model = Instance.new("Model")
    model.Name = name
    model.WorldPivot = cf
    model:SetAttribute("UrbanModule", true)
    model:SetAttribute("VisualSwapSlot", name)
    model:SetAttribute("VisualBounds", Vector3.new(width, height, depth))
    model.Parent = parent

    local visual = Instance.new("Model")
    visual.Name = "Visual"
    visual.WorldPivot = cf
    visual.Parent = model
    part(visual, "Masonry", Vector3.new(width, height, depth),
        cf * CFrame.new(0, height / 2, 0), color, Enum.Material.Brick, false)
    part(visual, "RoofCap", Vector3.new(width + 1, 1.2, depth + 1),
        cf * CFrame.new(0, height + 0.6, 0), DARK_METAL, Enum.Material.Metal, false)
    part(visual, "Storefront", Vector3.new(width - 3, 4.5, 0.3),
        cf * CFrame.new(0, 4.2, -depth / 2 - 0.16),
        Color3.fromRGB(36, 53, 59), Enum.Material.Glass, false)
    part(visual, "Cornice", Vector3.new(width, 0.65, 0.8),
        cf * CFrame.new(0, height * 0.72, -depth / 2 - 0.3),
        accent, Enum.Material.Metal, false)
    part(visual, "Entrance", Vector3.new(5, 6.5, 0.4),
        cf * CFrame.new(0, 3.25, -depth / 2 - 0.42),
        DARK_METAL, Enum.Material.Metal, false)
    for _, side in {-1, 1} do
        part(visual, "Pier", Vector3.new(1, height - 2, 0.7),
            cf * CFrame.new(side * (width / 2 - 1.5), (height - 2) / 2, -depth / 2 - 0.4),
            accent, Enum.Material.Concrete, false)
    end
    for row = 1, 2 do
        for column = -1, 1 do
            local glass = part(visual, "UpperWindow", Vector3.new(math.min(7, width / 6), 4.5, 0.25),
                cf * CFrame.new(column * width * 0.26, height * (if row == 1 then 0.43 else 0.65),
                    -depth / 2 - 0.2),
                if (column + row) % 3 == 0 then WARM_LIGHT else TEAL_LIGHT,
                Enum.Material.Neon, false)
            glass.Transparency = 0.55
        end
    end
    if signText then
        local panel = part(visual, "DistrictSign", Vector3.new(math.min(width - 3, 28), 3, 0.4),
            cf * CFrame.new(0, 8, -depth / 2 - 0.38), DARK_METAL, Enum.Material.Metal, false)
        local gui = Instance.new("SurfaceGui")
        gui.Name = "SignFace"
        gui.Face = Enum.NormalId.Front
        gui.PixelsPerStud = 24
        gui.LightInfluence = 0
        gui.Parent = panel
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = signText
        label.TextColor3 = WARM_LIGHT
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.Parent = gui
    end
    -- Collision remains stable when the visible model is swapped for a mesh.
    local hull = part(model, "CollisionProxy", Vector3.new(width, height, depth),
        cf * CFrame.new(0, height / 2, 0), DARK_METAL,
        Enum.Material.SmoothPlastic, true)
    hull.Transparency = 1
    return model
end

local function parcelPaving(parent: Instance, ground: BasePart)
    local parcels = Instance.new("Folder")
    parcels.Name = "PlotParcels"
    parcels.Parent = parent
    for _, slot in Plots.Slots do
        local parcel = Instance.new("Folder")
        parcel.Name = slot.id
        parcel:SetAttribute("PlotId", slot.id)
        parcel:SetAttribute("ClearOnGroundsUpgrade", true)
        parcel.Parent = parcels
        local cf = CFrame.new(localGround(ground, slot.center.X, slot.center.Z))
        local paving = Color3.fromRGB(89, 94, 92)
        for _, x in {-100, 100} do
            part(parcel, "ExpansionPaving", Vector3.new(80, 0.06, 280),
                cf * CFrame.new(x, 0.045, 0), paving, Enum.Material.Concrete, false)
        end
        for _, z in {-100, 100} do
            part(parcel, "ExpansionPaving", Vector3.new(120, 0.06, 80),
                cf * CFrame.new(0, 0.045, z), paving, Enum.Material.Concrete, false)
        end
    end
end

local function boundary(parent: Instance, ground: BasePart)
    local edge = Instance.new("Folder")
    edge.Name = "CityBoundary"
    edge.Parent = parent
    local colors = { BRICK, BLUE_STONE, WARM_STONE }
    for _, sign in {-1, 1} do
        for index, x in {-420, -300, -180, -60, 60, 180, 300, 420} do
            local pos = localGround(ground, x, sign * 525)
            module(edge, "BoundaryBlock", CFrame.new(pos) * CFrame.Angles(0,
                if sign > 0 then 0 else math.pi, 0),
                102, 18, 48 + (index % 3) * 9, colors[(index % 3) + 1],
                if index % 2 == 0 then WARM_STONE else DARK_METAL, nil)
        end
        for index, z in {-440, -320, -200, -80, 80, 200, 320, 440} do
            local pos = localGround(ground, sign * 485, z)
            module(edge, "BoundaryBlock", CFrame.new(pos) * CFrame.Angles(0,
                if sign > 0 then math.pi / 2 else -math.pi / 2, 0),
                102, 18, 50 + (index % 3) * 8, colors[((index + 1) % 3) + 1],
                if index % 2 == 0 then DARK_METAL else WARM_STONE, nil)
        end
    end
end

local function innerBlocks(parent: Instance, ground: BasePart)
    local blocks = Instance.new("Folder")
    blocks.Name = "InnerBlocks"
    blocks.Parent = parent
    for _, spec in {
        {x = 80, z = 150, width = 68, depth = 56, height = 56,
            text = "SECURITY  /  NORTH", color = BRICK},
        {x = -135, z = 165, width = 44, depth = 34, height = 43,
            text = "ARCHIVE  /  NORTH", color = BLUE_STONE},
        {x = 135, z = -165, width = 44, depth = 34, height = 43,
            text = "RESTORATION", color = WARM_STONE},
        {x = -80, z = -150, width = 68, depth = 56, height = 56,
            text = "DISTRICT OFFICE", color = BRICK},
    } do
        local pos = localGround(ground, spec.x, spec.z)
        part(blocks, "CourtyardPaving", Vector3.new(spec.width + 28, 0.05, spec.depth + 28),
            CFrame.new(pos + Vector3.new(0, 0.03, 0)),
            Color3.fromRGB(96, 99, 94), Enum.Material.Concrete, false)
        module(blocks, "CivicBlock", CFrame.new(pos) * CFrame.Angles(0,
            if spec.z > 0 then math.pi else 0, 0),
            spec.width, spec.depth, spec.height, spec.color, DARK_METAL, spec.text)
    end
end

local function serviceYards(parent: Instance, ground: BasePart)
    local yards = Instance.new("Folder")
    yards.Name = "ServiceYards"
    yards.Parent = parent
    for _, xSign in {-1, 1} do
        for _, zSign in {-1, 1} do
            local pos = localGround(ground, xSign * 300, zSign * 29)
            part(yards, "ServicePaving", Vector3.new(90, 0.05, 20),
                CFrame.new(pos + Vector3.new(0, 0.03, 0)),
                Color3.fromRGB(75, 78, 76), Enum.Material.Concrete, false)
            module(yards, "ServiceBay", CFrame.new(pos) * CFrame.Angles(0,
                if zSign > 0 then math.pi else 0, 0),
                80, 18, 24, if xSign > 0 then BLUE_STONE else BRICK,
                WARM_STONE, nil)
        end
    end
end

local function checkpoint(parent: Instance, ground: BasePart, slot: any, index: number)
    local yaw = math.rad(slot.yawDegrees)
    local front = CFrame.Angles(0, yaw, 0):VectorToWorldSpace(Vector3.new(0, 0, -1))
    local gate = slot.center + front * 60
    local direction = Vector3.new(gate.X, 0, gate.Z).Unit
    local side = Vector3.new(-direction.Z, 0, direction.X)
    local coveredSide = CFrame.Angles(0, yaw, 0):VectorToWorldSpace(
        Vector3.new(({ -1, 1, -1, -1, 1, -1 })[index], 0, 0))
    local coveredPoint = gate + front * 85 + coveredSide * 95
    local towardsCovered = if side:Dot(coveredPoint) >= 0 then 1 else -1
    local center = direction * 125 - side * towardsCovered * 28
    local pos = localGround(ground, center.X, center.Z)
    local kiosk = module(parent, "Checkpoint_" .. index,
        CFrame.lookAt(pos, pos - direction), 12, 10, 18,
        if index % 2 == 0 then BLUE_STONE else BRICK,
        WARM_STONE, string.format("MUSEUM %02d", index))
    kiosk:SetAttribute("PlotId", slot.id)
    local routePos = localGround(ground, direction.X * 125, direction.Z * 125)
    local armCenter = (routePos + pos) / 2 + Vector3.new(0, 21, 0)
    part(kiosk.Visual, "WayfindingArm", Vector3.new(0.8, 0.8, 28),
        CFrame.lookAt(armCenter, routePos + Vector3.new(0, 21, 0)),
        DARK_METAL, Enum.Material.Metal, false)
    local banner = part(kiosk.Visual, "RouteBanner", Vector3.new(12, 3, 0.5),
        CFrame.lookAt(routePos + Vector3.new(0, 19, 0),
            routePos + Vector3.new(0, 19, 0) - direction),
        if index % 2 == 0 then TEAL_LIGHT else WARM_LIGHT,
        Enum.Material.Metal, false)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.PixelsPerStud = 20
    gui.LightInfluence = 0
    gui.Parent = banner
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = string.format("%02d  MUSEUM", index)
    label.TextColor3 = DARK_METAL
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = gui
end

function Urban.Build(world: Model)
    local existing = world:FindFirstChild("UrbanDistrict")
    if existing then existing:Destroy() end
    local ground = world:FindFirstChild("Ground")
    if ground == nil or not ground:IsA("BasePart") then return end

    -- The distant hills and scattered tree line are cosmetic. Keep the
    -- authored ground, plot markers, routes, depot, and perimeter collision.
    local perimeter = world:FindFirstChild("PerimeterDecor")
    if perimeter then
        local ridges = perimeter:FindFirstChild("SculptedRidges")
        if ridges then ridges:Destroy() end
        for _, child in perimeter:GetChildren() do
            if child.Name:match("^BackgroundTree%d+$") then child:Destroy() end
        end
    end
    ground.Color = Color3.fromRGB(64, 72, 76)
    ground.Material = Enum.Material.Concrete

    local root = Instance.new("Folder")
    root.Name = "UrbanDistrict"
    root:SetAttribute("GeneratedBy", "DistrictUrbanVisuals")
    root.Parent = world
    parcelPaving(root, ground)
    boundary(root, ground)
    innerBlocks(root, ground)
    serviceYards(root, ground)
    local checkpoints = Instance.new("Folder")
    checkpoints.Name = "Checkpoints"
    checkpoints.Parent = root
    for index, slot in Plots.Slots do
        checkpoint(checkpoints, ground, slot, index)
    end
end

return table.freeze(Urban)
