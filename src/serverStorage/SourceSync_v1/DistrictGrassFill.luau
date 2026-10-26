--!strict

-- Sparse, solid scenery for the open grass in the six-museum district.
-- Generated before the district enters Workspace to avoid a replication spike.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Plots = require(ReplicatedStorage.Shared.PlotDefinitions)

local DistrictGrassFill = {}
local STEP = 88
local SEED = 20261015

local function piece(parent: Instance, className: string, name: string,
    size: Vector3, cf: CFrame, color: Color3, material: Enum.Material,
    solid: boolean, shape: Enum.PartType?): BasePart
    local p = Instance.new(className) :: BasePart
    if shape and p:IsA("Part") then p.Shape = shape end
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material
    p.Anchored = true
    p.CanCollide = solid
    p.CanTouch = false
    p.CanQuery = solid
    p.CastShadow = solid and material ~= Enum.Material.Grass
    p.Parent = parent
    return p
end

local function nearRoute(routes: Instance?, point: Vector3): boolean
    if routes == nil then return false end
    for _, route in routes:GetChildren() do
        if route:IsA("BasePart") then
            local localPoint = route.CFrame:PointToObjectSpace(point)
            local margin = if route.Name:match("^Open") then 40 else 34
            if math.abs(localPoint.X) < route.Size.X / 2 + margin
                and math.abs(localPoint.Z) < route.Size.Z / 2 + margin then
                return true
            end
        end
    end
    return false
end

local function plotAt(x: number, z: number): (string?, boolean)
    for _, slot in Plots.Slots do
        local dx = math.abs(x - slot.center.X)
        local dz = math.abs(z - slot.center.Z)
        if dx < 160 and dz < 160 then
            -- Leave the current museum grounds and entrance approach open.
            return slot.id, dx < 95 and dz < 95
        end
    end
    return nil, false
end

local function meadow(parent: Instance, base: Vector3, rng: Random, index: number)
    local angle = rng:NextNumber(-0.6, 0.6)
    local cf = CFrame.new(base) * CFrame.Angles(0, angle, 0)
    local color = if index % 2 == 0
        then Color3.fromRGB(72, 106, 71) else Color3.fromRGB(96, 123, 78)
    -- Two very shallow overlapping grass shapes color a broad area with
    -- an uneven edge. They sit on the ground and remain walkable.
    piece(parent, "Part", "Meadow", Vector3.new(80, 0.09, 57),
        cf * CFrame.new(-8, 0.055, 0), color, Enum.Material.Grass,
        false, Enum.PartType.Ball)
    piece(parent, "Part", "Meadow", Vector3.new(66, 0.09, 67),
        cf * CFrame.new(15, 0.058, 7) * CFrame.Angles(0, 0.38, 0),
        color, Enum.Material.Grass, false, Enum.PartType.Ball)
end

local function shrub(parent: Instance, base: Vector3, rng: Random, index: number)
    local offset = Vector3.new(rng:NextNumber(-11, 11), 0, rng:NextNumber(-9, 9))
    local cf = CFrame.new(base + offset) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
    -- Different sizes and overlapping offsets avoid a single spherical bush.
    piece(parent, "Part", "ShrubLeaves", Vector3.new(10, 4.5, 6),
        cf * CFrame.new(-2.2, 2.1, 0) * CFrame.Angles(0, 0, -0.13),
        Color3.fromRGB(49, 87, 59), Enum.Material.Grass, true, Enum.PartType.Ball)
    piece(parent, "Part", "ShrubLeaves", Vector3.new(6, 6.2, 9),
        cf * CFrame.new(2.7, 3.0, 1.3) * CFrame.Angles(0.18, 0.7, 0),
        Color3.fromRGB(85, 122, 69), Enum.Material.Grass, true, Enum.PartType.Ball)
    piece(parent, "Part", "ShrubLeaves", Vector3.new(5.5, 3.4, 7),
        cf * CFrame.new(0, 1.8, -3.5),
        Color3.fromRGB(67, 106, 65), Enum.Material.Grass, true, Enum.PartType.Ball)
    if index % 3 == 0 then
        piece(parent, "Part", "FlowerCluster", Vector3.new(3.5, 0.8, 2.5),
            cf * CFrame.new(1, 5.3, -1),
            if index % 2 == 0 then Color3.fromRGB(222, 176, 111)
                else Color3.fromRGB(193, 139, 162),
            Enum.Material.SmoothPlastic, true, Enum.PartType.Ball)
    end
end

local function rock(parent: Instance, base: Vector3, rng: Random)
    local cf = CFrame.new(base + Vector3.new(rng:NextNumber(-8, 8), 0,
        rng:NextNumber(-7, 7))) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
    piece(parent, "Part", "SlateOutcrop", Vector3.new(10, 4.2, 7),
        cf * CFrame.new(-1.6, 2.1, 0) * CFrame.Angles(0, 0, 0.13),
        Color3.fromRGB(109, 112, 103), Enum.Material.Slate, true, Enum.PartType.Ball)
    piece(parent, "Part", "SlateFragment", Vector3.new(6, 3.1, 5),
        cf * CFrame.new(3, 1.55, 1) * CFrame.Angles(0, 0.8, -0.12),
        Color3.fromRGB(135, 133, 117), Enum.Material.Slate, true, Enum.PartType.Ball)
end

local function tree(parent: Instance, base: Vector3, rng: Random)
    local cf = CFrame.new(base) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
    local height = rng:NextNumber(11, 16)
    piece(parent, "Part", "TreeTrunk", Vector3.new(2.4, height, 2.1),
        cf * CFrame.new(0, height / 2, 0),
        Color3.fromRGB(102, 78, 56), Enum.Material.Wood, true)
    piece(parent, "Part", "TreeCanopy", Vector3.new(13, 8, 11),
        cf * CFrame.new(-2.5, height + 3.3, 0),
        Color3.fromRGB(48, 86, 56), Enum.Material.Grass, true, Enum.PartType.Ball)
    piece(parent, "Part", "TreeCanopy", Vector3.new(10, 7, 10),
        cf * CFrame.new(3.8, height + 4.5, 2.1) * CFrame.Angles(0, 1.3, 0),
        Color3.fromRGB(75, 107, 62), Enum.Material.Grass, true, Enum.PartType.Ball)
end

function DistrictGrassFill.Build(world: Model)
    local old = world:FindFirstChild("GrassFill")
    if old then old:Destroy() end
    local ground = world:FindFirstChild("Ground")
    if ground == nil or not ground:IsA("BasePart") then return end

    local root = Instance.new("Folder")
    root.Name = "GrassFill"
    root:SetAttribute("GeneratedBy", "DistrictGrassFill")
    root.Parent = world
    local public = Instance.new("Folder")
    public.Name = "PublicMeadows"
    public.Parent = root
    local plotFolders: {[string]: Folder} = {}
    for _, slot in Plots.Slots do
        local folder = Instance.new("Folder")
        folder.Name = slot.id
        folder:SetAttribute("PlotId", slot.id)
        folder:SetAttribute("ClearOnGroundsUpgrade", true)
        folder.Parent = root
        plotFolders[slot.id] = folder
    end

    local rng = Random.new(SEED)
    local routes = world:FindFirstChild("Routes")
    local count = 0
    local xLimit = math.floor((ground.Size.X / 2 - 35) / STEP)
    local zLimit = math.floor((ground.Size.Z / 2 - 35) / STEP)
    for ix = -xLimit, xLimit do
        for iz = -zLimit, zLimit do
            local x = ix * STEP + rng:NextNumber(-5, 5)
            local z = iz * STEP + rng:NextNumber(-5, 5)
            local point = ground.CFrame:PointToWorldSpace(Vector3.new(x, ground.Size.Y / 2, z))
            local plotId, inStarter = plotAt(x, z)
            if not inStarter and math.max(math.abs(x), math.abs(z)) > 75
                and not nearRoute(routes, point)
                and not (math.abs(z) < 43 and
                    (math.abs(math.abs(x) - 95) < 43 or math.abs(math.abs(x) - 230) < 43))
                and rng:NextNumber() < 0.88 then
                local parent = if plotId then plotFolders[plotId] else public
                count += 1
                meadow(parent, point, rng, count)
                if count % 11 == 0 then
                    tree(parent, point, rng)
                elseif count % 4 == 0 then
                    rock(parent, point, rng)
                else
                    shrub(parent, point, rng, count)
                end
            end
        end
        -- Building off-world in slices keeps Studio's main thread responsive.
        if ix % 3 == 0 then task.wait() end
    end
    root:SetAttribute("MeadowCount", count)
end

return table.freeze(DistrictGrassFill)
