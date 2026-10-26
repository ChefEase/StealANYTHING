-- Original modular art for the measured Task 11 starter district.
-- No player state, remotes, running effects, or gameplay sockets are created here.
local D = require(game.ReplicatedStorage.Shared.Task11VisualDefinitions)
local Plots = require(game.ReplicatedStorage.Shared.PlotDefinitions)
local P = D.Palette
local V, CF = Vector3.new, CFrame.new
local Kit = { Version = 9 }
local owner = "Task11VisualKit"

local function group(parent, name, class)
    local g = Instance.new(class or "Folder")
    g.Name = name
    g:SetAttribute("GeneratedBy", owner)
    g:SetAttribute("CosmeticOnly", true)
    if g:IsA("Model") then g.WorldPivot = CF() end
    g.Parent = parent
    return g
end

local function replace(parent, name, class)
    local prior = parent:FindFirstChild(name)
    -- These names belong to the inspected v2 visual builder; functional roots
    -- such as StarterHall, GroundsTier1, Depot and Routes are never replaced.
    if prior then prior:Destroy() end
    return group(parent, name, class)
end

local function part(parent, name, size, cf, color, material)
    local p = Instance.new("Part")
    p.Name, p.Size = name, size
    p.CFrame = typeof(cf) == "Vector3" and CF(cf) or cf
    p.Color, p.Material = color or P.stone, material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p:SetAttribute("Task11Visual", true)
    p.Parent = parent
    return p
end

local function ball(parent, name, size, pos, color)
    local p = part(parent, name, size, pos, color, Enum.Material.SmoothPlastic)
    p.Shape = Enum.PartType.Ball
    return p
end

local function cylinder(parent, name, radius, height, cf, color, material)
    local base = typeof(cf) == "Vector3" and CF(cf) or cf
    local p = part(parent, name, V(height, radius * 2, radius * 2),
        base * CFrame.Angles(0, 0, math.pi / 2), color, material)
    p.Shape = Enum.PartType.Cylinder
    return p
end

local function text(parent, name, value, size, cf, color, face)
    local p = part(parent, name, size, cf, color or P.charcoal, Enum.Material.Metal)
    local gui = Instance.new("SurfaceGui")
    gui.Name, gui.Face = "Lettering", face or Enum.NormalId.Front
    gui.SizingMode, gui.PixelsPerStud = Enum.SurfaceGuiSizingMode.PixelsPerStud, 40
    gui.LightInfluence, gui.AlwaysOnTop, gui.MaxDistance = 0.25, false, 150
    gui.Parent = p
    local label = Instance.new("TextLabel")
    label.Size, label.BackgroundTransparency = UDim2.fromScale(0.94, 0.84), 1
    label.Position = UDim2.fromScale(0.03, 0.08)
    label.Font, label.TextScaled = Enum.Font.GothamMedium, true
    label.Text, label.TextColor3 = value, P.ivory
    label.Parent = gui
    return p
end

local function point(p, brightness, range)
    local light = Instance.new("PointLight")
    light.Name, light.Color = "WarmLight", P.warmLight
    light.Brightness, light.Range, light.Shadows = brightness, range, false
    light.Parent = p
end

local function template(folder, name)
    local assets = game.ReplicatedStorage:FindFirstChild("VisualAssets")
    local collection = assets and assets:FindFirstChild(folder)
    local model = collection and collection:FindFirstChild(name)
    return if model and model:IsA("Model") then model else nil
end

local function colorImported(model, kind)
    for _, mesh in model:GetDescendants() do
        if mesh:IsA("MeshPart") then
            mesh.Anchored = true
            mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = false, false, false
            mesh:SetAttribute("Task11Visual", true)
            if mesh.TextureID == "" and not mesh:FindFirstChildOfClass("SurfaceAppearance") then
                local name = mesh.Name
                if string.find(name, "Gold") or string.find(name, "Bronze")
                    or string.find(name, "Bolt") or string.find(name, "Crest") then
                    mesh.Color, mesh.Material = P.entranceGold, Enum.Material.Metal
                elseif string.find(name, "Teal") or string.find(name, "Gem") then
                    mesh.Color, mesh.Material = P.entranceTeal, Enum.Material.SmoothPlastic
                elseif kind == "Bench" and (string.find(name, "Slat") or string.find(name, "End"))
                    or kind == "Desk" and (string.find(name, "Wood") or name == "DeskBody") then
                    mesh.Color, mesh.Material = P.walnut, Enum.Material.Wood
                elseif string.find(name, "Stone") or string.find(name, "Plinth")
                    or string.find(name, "Cream") or name == "CounterTop" then
                    mesh.Color, mesh.Material = P.ivory, Enum.Material.Limestone
                else
                    mesh.Color, mesh.Material = P.charcoal, Enum.Material.Metal
                end
            end
        end
    end
end

Kit.ApplyImportedPalette = colorImported

local function colorLandscape(model)
    for _, mesh in model:GetDescendants() do
        if mesh:IsA("MeshPart") then
            mesh.Anchored = true
            mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = false, false, false
            mesh.Massless = true
            mesh:SetAttribute("Task11Visual", true)
            if mesh.TextureID == "" and not mesh:FindFirstChildOfClass("SurfaceAppearance")
                and not mesh:FindFirstChildOfClass("Texture")
                and not mesh:FindFirstChildOfClass("Decal") then
                local name = mesh.Name
                if name:find("Gold") or name:find("Berry") or name:find("Bud") then
                    mesh.Color, mesh.Material = Color3.fromRGB(191, 151, 76), Enum.Material.Metal
                elseif name:find("Teal") then
                    mesh.Color, mesh.Material = P.entranceTeal, Enum.Material.SmoothPlastic
                elseif name:find("Plinth") or name:find("Stone") or name:find("Corner_Post")
                    or name:find("Planter_Body") or name:find("InnerLip") then
                    mesh.Color, mesh.Material = P.ivory, Enum.Material.Limestone
                elseif name:find("Soil") then
                    mesh.Color, mesh.Material = P.soil, Enum.Material.Ground
                elseif name:find("Leaf") or name:find("Leaves") or name:find("Shrub") then
                    mesh.Color, mesh.Material = P.hedge, Enum.Material.SmoothPlastic
                    mesh.CastShadow = false
                elseif name:find("Trunk") or name:find("Branch") or name:find("Bark")
                    or name:find("Root") then
                    mesh.Color, mesh.Material = P.walnut, Enum.Material.Wood
                else
                    mesh.Color, mesh.Material = P.stone, Enum.Material.Limestone
                end
            end
        end
    end
end

Kit.ApplyLandscapePalette = colorLandscape

-- Keep the imported model's internal transforms. The target is the existing
-- landscape socket/position at ground height, never a new world-space point.
local function landscapeModel(source, parent, name, target, scale)
    local copy = source:Clone()
    copy.Name = name
    copy:ScaleTo(scale)
    local box, size = copy:GetBoundingBox()
    local pivotToBox = copy:GetPivot():ToObjectSpace(box)
    copy:PivotTo(target * CF(0, size.Y / 2, 0) * pivotToBox:Inverse())
    colorLandscape(copy)
    copy.Parent = parent
    return copy
end

local function colorB6789(model, kind)
    for _, mesh in model:GetDescendants() do
        if mesh:IsA("MeshPart") then
            mesh.Anchored, mesh.Massless = true, true
            mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = false, false, false
            mesh:SetAttribute("Task11Visual", true)
            if mesh.TextureID == "" and not mesh:FindFirstChildOfClass("SurfaceAppearance") then
                local n = mesh.Name:lower()
                if n:find("gold") or n:find("bolt") or n:find("nail")
                    or n:find("rosette") or n:find("border") then
                    mesh.Color, mesh.Material = P.entranceGold, Enum.Material.Metal
                elseif n:find("teal") or n:find("statuslight") then
                    mesh.Color, mesh.Material = P.entranceTeal, Enum.Material.SmoothPlastic
                elseif kind == "Rock" then
                    mesh.Color, mesh.Material = Color3.fromRGB(105, 108, 102), Enum.Material.Slate
                elseif kind == "Pallet" or kind == "Crate" then
                    if n:find("slat") or n:find("stringer") or n:find("panel")
                        or n:find("body") or n:find("rail") then
                        mesh.Color, mesh.Material = P.walnut, Enum.Material.Wood
                    else
                        mesh.Color, mesh.Material = P.charcoal, Enum.Material.Metal
                    end
                elseif n:find("lens") then
                    mesh.Color, mesh.Material = P.warmLight, Enum.Material.Neon
                elseif kind == "Pedestal" and (n:find("slab") or n:find("ledge")) then
                    mesh.Color, mesh.Material = P.ivory, Enum.Material.Limestone
                else
                    mesh.Color, mesh.Material = P.charcoal, Enum.Material.Metal
                end
            end
        end
    end
end

Kit.ApplyB6789Palette = colorB6789

local function batchModel(source, parent, name, groundCf, scale, kind)
    local copy = source:Clone()
    copy.Name = name
    copy:ScaleTo(scale)
    local box, size = copy:GetBoundingBox()
    local pivotToBox = copy:GetPivot():ToObjectSpace(box)
    copy:PivotTo(groundCf * CF(0, size.Y / 2, 0) * pivotToBox:Inverse())
    colorB6789(copy, kind)
    copy.Parent = parent
    return copy
end

local function importedModel(source, parent, name, target, scale, kind, verticalStretch)
    local copy = source:Clone()
    copy.Name = name
    copy:ScaleTo(scale)
    if verticalStretch then
        local pivot = copy:GetPivot()
        for _, mesh in copy:GetDescendants() do
            if mesh:IsA("MeshPart") then
                local localCf = pivot:ToObjectSpace(mesh.CFrame)
                mesh.Size = V(mesh.Size.X, mesh.Size.Y * verticalStretch, mesh.Size.Z)
                mesh.CFrame = pivot * CF(localCf.Position.X,
                    localCf.Position.Y * verticalStretch, localCf.Position.Z) * localCf.Rotation
            end
        end
    end
    local box, size = copy:GetBoundingBox()
    local pivotToBox = copy:GetPivot():ToObjectSpace(box)
    copy:PivotTo(target * CF(0, size.Y / 2, 0) * pivotToBox:Inverse())
    colorImported(copy, kind)
    copy.Parent = parent
    return copy
end

local function bench(parent, name, cf, floorY)
    local g = group(parent, name)
    local source = template("BenchKit", "B2BenchPremium")
    if source then
        local _, size = source:GetBoundingBox()
        local scale = 6 / size.X
        -- The imported seat is unusually low relative to its width. Stretch
        -- vertically so its slats meet the existing invisible sitting frame.
        local slat = assert(source:FindFirstChild("Bench_SeatSlat_3"),
            "B2 bench seat slat missing")
        local seatHeight = source:GetPivot():PointToObjectSpace(slat.Position).Y * scale
        importedModel(source, g, "PremiumBench", cf * CF(0, floorY, 0), scale,
            "Bench", 1.7 / seatHeight)
    else
        for _, z in {-0.55, 0, 0.55} do
            part(g, "SeatSlat", V(6, 0.22, 0.42), cf * CF(0, floorY + 1.7, z), P.walnut, Enum.Material.Wood)
        end
        for _, x in {-2.2, 2.2} do
            part(g, "Frame", V(0.3, 1.6, 1.7), cf * CF(x, floorY + 0.8, 0), P.charcoal, Enum.Material.Metal)
        end
        part(g, "Back", V(6, 0.8, 0.22), cf * CF(0, floorY + 2.6, 0.8), P.walnut, Enum.Material.Wood)
    end
    local seat = Instance.new("Seat")
    seat.Name = "SitOnlySeat"
    seat.Size = V(4.8, 0.18, 1.15)
    seat.CFrame = cf * CF(0, floorY + 2.12, 0)
    seat.Transparency = 1
    seat.Anchored = true
    seat.CanCollide, seat.CanTouch, seat.CanQuery = false, false, false
    seat:SetAttribute("Task11Visual", true)
    seat:SetAttribute("Task11SitOnly", true)
    seat.Parent = g
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "SitPrompt"
    prompt.ActionText, prompt.ObjectText = "Sit", "Bench"
    prompt.MaxActivationDistance, prompt.HoldDuration = 7, 0.15
    prompt.RequiresLineOfSight = false
    prompt.Style = Enum.ProximityPromptStyle.Default
    prompt:SetAttribute("Task11SitPrompt", true)
    prompt.Parent = seat
end

local function pot(parent, name, cf, floorY, scale)
    local g = group(parent, name)
    local source = template("LandscapeKit", "RoundPlanterShrub")
    if source then
        local _, size = source:GetBoundingBox()
        landscapeModel(source, g, "B5RoundPlanter", cf * CF(0, floorY, 0), 2 * scale / size.X)
        return g
    end
    cylinder(g, "Vessel", scale, scale * 1.4, cf * CF(0, floorY + scale * 0.7, 0), P.stone, Enum.Material.Concrete)
    cylinder(g, "Soil", scale * 0.86, 0.06, cf * CF(0, floorY + scale * 1.42, 0), P.soil)
    for i = 1, 3 do
        local a = i * math.pi * 2 / 3
        local leaf = ball(g, "Leaves", V(scale * 0.9, scale * 2.1, scale * 0.9),
            cf * CF(math.cos(a) * scale * 0.4, floorY + scale * 2.15, math.sin(a) * scale * 0.4), P.hedge)
        leaf.CFrame *= CFrame.Angles(0, a, 0.2)
    end
    return g
end

local function tree(parent, name, pos, variant, scale)
    local g = group(parent, name)
    local cf = CF(pos)
    -- Distant perimeter trees remain low-cost silhouettes. Close ornamental
    -- sockets use the two imported variations without filling the whole map
    -- with 37- and 54-mesh copies.
    local distant = name == "RidgeTree" or name == "ShoulderTree"
        or name:find("BackgroundTree", 1, true) == 1
    if not distant then
        local variation = (variant + (name == "RightOrnamental" and 1 or 0)) % 2
        local source = template("LandscapeKit", variation == 0 and "TreeTall" or "TreeRound")
        if source then
            local _, size = source:GetBoundingBox()
            landscapeModel(source, g, "B4OrnamentalTree", cf, 13 * scale / size.Y)
            return g
        end
    end
    cylinder(g, "Trunk", 0.32 * scale, 9 * scale, cf * CF(0, 4.5 * scale, 0), P.walnut, Enum.Material.Wood)
    local colors = {P.hedge, Color3.fromRGB(66, 104, 66), Color3.fromRGB(80, 117, 74)}
    for i = 1, 3 do
        local a = i * 2.1 + variant
        local p = ball(g, "Canopy", V(6.2, variant == 3 and 9 or 5, 5.8) * scale,
            cf * CF(math.cos(a) * 1.7 * scale, (10 + i * 0.7) * scale, math.sin(a) * 1.7 * scale), colors[i])
        p.CastShadow = false
    end
    return g
end

local function sculpture(parent, name, cf, floorY, style)
    local g = group(parent, name)
    part(g, "StoneFoot", V(5, 0.45, 5), cf * CF(0, floorY + 0.225, 0), P.stone, Enum.Material.Limestone)
    local designs = {
        ArrivalSculpture = "B3_SculptureSpiral_RobloxSafe",
        CourtyardArt = "B3SculptureOrbit",
        SideArt = "B3SculptureTotem",
        StillFountain = "B3SculptureOrbit",
        DistrictMonument = "B3SculptureTotem",
    }
    local sourceName = designs[name]
    if not sourceName then
        local total = 0
        for i = 1, #name do total += string.byte(name, i) end
        sourceName = ({"B3SculptureTotem", "B3SculptureOrbit",
            "B3_SculptureSpiral_RobloxSafe"})[total % 3 + 1]
    end
    local source = template("Sculptures", sourceName)
    if source then
        local _, size = source:GetBoundingBox()
        importedModel(source, g, "SculptureMesh", cf * CF(0, floorY + 0.45, 0),
            4.5 / math.max(size.X, size.Z), "Sculpture")
    elseif style == "fountain" then
        cylinder(g, "Basin", 2.1, 0.8, cf * CF(0, floorY + 0.65, 0), P.stone, Enum.Material.Marble)
        cylinder(g, "StillWater", 1.9, 0.06, cf * CF(0, floorY + 1.09, 0), Color3.fromRGB(76, 111, 116))
        cylinder(g, "CentralFinial", 0.4, 2.1, cf * CF(0, floorY + 1.6, 0), P.bronze, Enum.Material.Metal)
    else
        -- Open abstract steel ribbon, never a copy of a collectible.
        for i = 1, 3 do
            part(g, "Ribbon", V(0.35, 4.2, 2.1), cf * CF((i - 2) * 0.8, floorY + 2.6, 0)
                * CFrame.Angles(0, math.rad(30 * i), math.rad((i - 2) * 14)), P.bronze, Enum.Material.Metal)
        end
    end
    return g
end

local function frameArt(parent, name, cf, title, variant)
    local g = group(parent, name)
    part(g, "Frame", V(6.6, 6, 0.18), cf, P.bronze, Enum.Material.Metal)
    part(g, "Canvas", V(6.1, 5.5, 0.06), cf * CF(0, 0, -0.13), P.ivory)
    local colors = {Color3.fromRGB(75, 107, 109), P.walnut, Color3.fromRGB(148, 131, 99)}
    for i = 1, 3 do
        part(g, "AbstractForm", V(1.35, 2.5 + (i % 2), 0.03),
            cf * CF((i - 2) * 1.65, (i % 2) * 0.6 - 0.3, -0.18)
                * CFrame.Angles(0, 0, math.rad(variant * 7 - i * 12)), colors[i])
    end
    text(g, "Caption", title, V(5, 0.65, 0.06), cf * CF(0, -3.7, 0), P.charcoal)
end

local function starter(museum)
    local hall = assert(museum:FindFirstChild("StarterHall"), "StarterHall missing")
    assert(hall.Floor.Size == V(60, 1, 60), "Visual kit requires the audited 60x60 floor")
    assert(museum:GetPivot().Position.Magnitude < 0.001, "Build source visuals at the template origin")
    return hall, hall.Floor.Size.X / 2, museum.GroundsTier1.Lawn.Size.X / 2
end

function Kit.ApplyEntrancePalette(model)
    for _, mesh in model:GetDescendants() do
        if mesh:IsA("MeshPart") and mesh.TextureID == ""
            and mesh:FindFirstChildOfClass("SurfaceAppearance") == nil
            and mesh:FindFirstChildOfClass("Texture") == nil
            and mesh:FindFirstChildOfClass("Decal") == nil then
            local name = mesh.Name
            if string.find(name, "Gold") or string.find(name, "CornerOrn")
                or string.find(name, "CentreTop") then
                mesh.Color, mesh.Material = P.entranceGold, Enum.Material.Metal
            elseif string.find(name, "Teal") then
                mesh.Color, mesh.Material = P.entranceTeal, Enum.Material.SmoothPlastic
            elseif name == "Fascia_Body" or name == "Soffit_Rail"
                or name == "BackingPanel" or name == "OuterBorderFrame" then
                mesh.Color, mesh.Material = P.charcoal, Enum.Material.Metal
            elseif name == "Sconce_BackPlate" then
                mesh.Color, mesh.Material = P.entranceGold, Enum.Material.Metal
            elseif string.find(name, "FluteChan") then
                mesh.Color, mesh.Material = P.stone, Enum.Material.Limestone
            else
                mesh.Color, mesh.Material = P.ivory, Enum.Material.Limestone
            end
        end
    end
end

local function addEntranceModule(kit, parent, sourceName, width, height, center, yaw)
    local source = kit:FindFirstChild(sourceName)
    if source == nil or not source:IsA("Model") then
        warn("[Task11] Missing A2 entrance module: " .. sourceName)
        return
    end
    local sourceBox, sourceSize = source:GetBoundingBox()
    local scale = if width then width / sourceSize.X else height / sourceSize.Y
    local centerFromPivot = source:GetPivot():ToObjectSpace(sourceBox).Position
    local copy = source:Clone()
    copy:ScaleTo(scale)
    copy:PivotTo(CF(center) * CFrame.Angles(0, yaw or 0, 0)
        * CF(-centerFromPivot * scale))
    for _, mesh in copy:GetDescendants() do
        if mesh:IsA("MeshPart") then
            mesh.Anchored = true
            mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = false, false, false
            mesh:SetAttribute("Task11Visual", true)
        end
    end
    Kit.ApplyEntrancePalette(copy)
    copy.Parent = parent
end

local function addEntranceKit(entrance)
    local visualAssets = game.ReplicatedStorage:FindFirstChild("VisualAssets")
    local kit = visualAssets and visualAssets:FindFirstChild("EntranceKit")
    if kit == nil then return end
    local imported = group(entrance, "A2EntranceKit")
    -- The existing functional sign stays in front of the canopy trim.
    addEntranceModule(kit, imported, "CanopyTrim", 18, nil, V(0, 17.15, -34.3), math.pi)
    -- Each pilaster is a separate module, scaled to the 14-stud doorway height.
    addEntranceModule(kit, imported, "DoorPilasterLeft", nil, 14.7, V(-7.5, 8.65, -30.2), 0)
    addEntranceModule(kit, imported, "DoorPilasterRight", nil, 14.7, V(7.5, 8.65, -30.2), 0)
    -- Small framed plaques flank the existing central sign above the windows.
    addEntranceModule(kit, imported, "SignFrame", 5.5, nil, V(-16.5, 16.65, -30.25), 0)
    addEntranceModule(kit, imported, "SignFrame", 5.5, nil, V(16.5, 16.65, -30.25), 0)
    -- The imported backplate frames the existing lit fixture on each side.
    addEntranceModule(kit, imported, "WallSconceBackPlate", nil, 3.2, V(-10, 10, -30.1), 0)
    addEntranceModule(kit, imported, "WallSconceBackPlate", nil, 3.2, V(10, 10, -30.1), 0)
end

function Kit.BuildExterior(museum)
    local hall, h = starter(museum)
    local root = replace(museum, "ArchitectureVisuals")
    local facade, entrance = group(root, "Facade"), group(root, "EntranceDecor")
    local roof, fixtures = group(root, "RoofDetails"), group(root, "ExteriorFixtures")
    local boundary = group(root, "GroundsFinish")
    part(boundary, "TrimmedLawn", V(119.8, 0.02, 119.8), V(0, 0.315, 0), P.lawn, Enum.Material.Grass)
    for _, side in {-1, 1} do
        part(boundary, "SideEstateWall", V(0.03, 11.6, 117), V(side * 58.97, 6.3, 0), P.stone, Enum.Material.Concrete)
        part(boundary, "SideEstateCoping", V(0.5, 0.14, 117), V(side * 59.15, 12.15, 0), P.charcoal, Enum.Material.Metal)
        for _, z in {-40, -20, 0, 20, 40} do
            part(boundary, "EstatePier", V(0.12, 11.6, 0.4), V(side * 58.86, 6.3, z), P.ivory, Enum.Material.Concrete)
        end
        part(boundary, "FrontEstateWall", V(51.8, 11.6, 0.03), V(side * 34, 6.3, -60.025), P.stone, Enum.Material.Concrete)
    end
    part(boundary, "RearEstateWall", V(117, 11.6, 0.03), V(0, 6.3, 58.97), P.stone, Enum.Material.Concrete)
    -- Surface treatments are visual-only; the structural parts are untouched.
    for _, x in {-18.5, 18.5} do
        part(facade, "FrontStonePanel", V(22.8, 16.8, 0.035), V(x, 9.8, -h - 0.025), P.ivory, Enum.Material.Concrete)
        part(facade, "FrontBase", V(22.8, 0.8, 0.14), V(x, 1.75, -h - 0.1), P.stone, Enum.Material.Limestone)
        part(facade, "FrontCornice", V(22.8, 0.35, 0.2), V(x, 14.5, -h - 0.12), P.stone, Enum.Material.Limestone)
    end
    for _, side in {-1, 1} do
        part(facade, "SideStonePanel", V(0.035, 16.8, 59.8), V(side * (h + 0.025), 9.8, 0), P.ivory, Enum.Material.Concrete)
        part(facade, "SideBase", V(0.14, 0.8, 59.8), V(side * (h + 0.1), 1.75, 0), P.stone, Enum.Material.Limestone)
        for _, z in {-19, 0, 19} do
            local cf = CF(side * (h + 0.04), 10.5, z) * CFrame.Angles(0, -side * math.pi / 2, 0)
            part(facade, "GlazedFrame", V(7, 6.5, 0.18), cf, P.charcoal, Enum.Material.Metal)
            part(facade, "FrostedPanel", V(6.5, 6, 0.06), cf * CF(0, 0, -0.15), Color3.fromRGB(92, 124, 128), Enum.Material.Glass)
            part(facade, "Mullion", V(0.15, 6, 0.1), cf * CF(0, 0, -0.23), P.bronze, Enum.Material.Metal)
            part(facade, "WindowSill", V(7.4, 0.25, 0.55), cf * CF(0, -3.3, -0.15), P.stone, Enum.Material.Limestone)
        end
        for _, x in {11, 27} do
            part(facade, "FrontPilaster", V(0.35, 15.8, 0.2), V(side * x, 9.8, -h - 0.16), P.stone, Enum.Material.Limestone)
        end
        local cf = CF(side * 20, 9.5, -h - 0.08)
        part(facade, "EntranceWindowFrame", V(4.5, 8.8, 0.16), cf, P.charcoal, Enum.Material.Metal)
        part(facade, "EntranceGlazing", V(4.05, 8.3, 0.06), cf * CF(0, 0, -0.15), Color3.fromRGB(92, 124, 128), Enum.Material.Glass)
        part(facade, "EntranceMullion", V(0.12, 8.3, 0.1), cf * CF(0, 0, -0.21), P.bronze, Enum.Material.Metal)
    end
    for _, side in {-1, 1} do
        part(roof, "FasciaLong", V(60, 0.65, 0.18), V(0, 18.65, side * 30.1), P.charcoal, Enum.Material.Metal)
        part(roof, "CopingLong", V(60, 0.12, 0.45), V(0, 19.35, side * 29.7), P.bronze, Enum.Material.Metal)
        part(roof, "FasciaSide", V(0.18, 0.65, 59.8), V(side * 30.1, 18.65, 0), P.charcoal, Enum.Material.Metal)
        part(roof, "CopingSide", V(0.45, 0.12, 59.4), V(side * 29.7, 19.35, 0), P.bronze, Enum.Material.Metal)
    end
    part(roof, "UtilityHousing", V(7, 1.5, 5), V(17, 20.05, 19), P.charcoal, Enum.Material.Metal)
    for i = 1, 4 do part(roof, "VentLouver", V(5.8, 0.08, 0.2), V(17, 19.6 + i * 0.25, 16.45), P.stone, Enum.Material.Metal) end
    part(roof, "SkylightFrame", V(13, 0.25, 7), V(-7, 19.55, 4), P.charcoal, Enum.Material.Metal)
    part(roof, "SkylightGlazing", V(12.4, 0.1, 6.4), V(-7, 19.75, 4), Color3.fromRGB(102, 126, 128), Enum.Material.Glass)
    for _, x in {-10, -4} do part(roof, "SkylightBar", V(0.12, 0.08, 6.4), V(x, 19.85, 4), P.bronze, Enum.Material.Metal) end
    cylinder(roof, "ExtractVent", 0.8, 1.6, V(-22, 20.1, 22), P.charcoal, Enum.Material.Metal)
    part(entrance, "Canopy", V(18, 0.38, 5), V(0, 15.7, -32.5), P.charcoal, Enum.Material.Metal)
    part(entrance, "CanopyLip", V(18, 0.14, 0.18), V(0, 15.46, -35), P.bronze, Enum.Material.Metal)
    for _, x in {-7.5, 7.5} do
        part(entrance, "DoorJamb", V(0.4, 13.7, 0.4), V(x, 8.35, -30.25), P.bronze, Enum.Material.Metal)
        part(entrance, "CanopyBracket", V(0.18, 2.6, 0.18), CF(x, 16.2, -32) * CFrame.Angles(-0.65, 0, 0), P.bronze, Enum.Material.Metal)
    end
    for _, side in {-1, 1} do
        for i = 1, 4 do
            part(entrance, "WalnutFlute", V(0.15, 13.4, 0.12), V(side * (8.1 + i * 0.24), 8.3, -30.16), P.walnut, Enum.Material.Wood)
        end
    end
    text(entrance, "MuseumSign", "THE COLLECTOR'S MUSEUM", V(23, 1.7, 0.2), V(0, 16.8, -35.18))
    text(entrance, "InformationBoard", "COLLECTIONS\nGALLERY  /  CURATOR\nVISITOR INFORMATION", V(5.2, 3.7, 0.16), V(-13, 5.4, -30.22))
    for _, x in {-10, 10} do
        part(fixtures, "LanternBack", V(0.8, 3, 0.35), V(x, 10, -30.3), P.charcoal, Enum.Material.Metal)
        local p = part(fixtures, "LanternDiffuser", V(0.48, 2.3, 0.15), V(x, 10, -30.55), P.warmLight, Enum.Material.Neon)
        point(p, 0.45, 14)
        pot(entrance, "EntryPlanter", CF(x * 1.2, 0, -35.5), 0.3, 1.15)
    end
    part(entrance, "ThresholdLine", V(13.5, 0.025, 0.25), V(0, 1.325, -29), P.bronze, Enum.Material.Metal)
    sculpture(entrance, "ArrivalSculpture", CF(20, 0, -37), 0.3, "ribbon")
    addEntranceKit(entrance)
    local rear = group(root, "ServiceFacade")
    local back = CF(18, 6.5, 30.15) * CFrame.Angles(0, math.pi, 0)
    part(rear, "ServiceDoor", V(6, 10, 0.12), back, P.charcoal, Enum.Material.Metal)
    part(rear, "DoorRecess", V(5.2, 8.5, 0.08), back * CF(0, 0, -0.1), Color3.fromRGB(72, 78, 78), Enum.Material.Metal)
    part(rear, "Handle", V(0.15, 1.1, 0.2), back * CF(2, 0, -0.2), P.bronze, Enum.Material.Metal)
    text(rear, "ServicePlaque", "STAFF / MAINTENANCE", V(6, 0.8, 0.1), back * CF(0, 4, -0.2))
    part(rear, "DrainPipe", V(0.3, 16.5, 0.3), V(27, 9, 30.3), P.charcoal, Enum.Material.Metal)
    part(rear, "ServiceLuminaire", V(2.4, 0.3, 0.4), V(18, 12.4, 30.4), P.warmLight, Enum.Material.Neon)
    museum:SetAttribute("VisualKitVersion", Kit.Version)
end

function Kit.BuildInterior(museum)
    local hall, h = starter(museum)
    local root = replace(museum, "InteriorVisuals")
    local lobby = group(root, "LobbyDecor")
    local walls, ceiling = group(root, "WallDetails"), group(root, "CeilingDetails")
    local gallery, furniture = group(root, "GalleryLighting"), group(root, "DecorativeFurniture")
    part(root, "GalleryStoneFinish", V(57.8, 0.018, 57.8), V(0, 1.312, 0), Color3.fromRGB(177, 167, 152), Enum.Material.SmoothPlastic)
    for _, n in {-21, -14, -7, 0, 7, 14, 21} do
        -- Visible separation and a wider joint avoid subpixel shimmer on phones.
        part(root, "StoneJoint", V(0.10, 0.02, 57.8), V(n, 1.345, 0), P.stone)
        part(root, "StoneJoint", V(57.8, 0.02, 0.10), V(0, 1.345, n), P.stone)
    end
    for _, side in {-1, 1} do
        part(walls, "WallLining", V(0.04, 16.8, 57.8), V(side * 28.97, 9.8, 0), P.ivory, Enum.Material.Concrete)
        part(walls, "DadoRail", V(0.15, 0.2, 57.8), V(side * 28.85, 4.1, 0), P.bronze, Enum.Material.Metal)
        part(walls, "Skirting", V(0.16, 0.6, 57.8), V(side * 28.84, 1.62, 0), P.stone, Enum.Material.Limestone)
        for _, z in {-8, 15} do
            part(walls, "PanelSeam", V(0.08, 12.8, 0.12), V(side * 28.87, 10.65, z), P.stone)
        end
        for i, z in {2, 20} do
            frameArt(walls, "GalleryArtwork", CF(side * 28.72, 10, z) * CFrame.Angles(0, side * math.pi / 2, 0),
                i == 1 and "FORM / STUDY 01" or "LAND / STUDY 02", i)
        end
    end
    part(walls, "FeatureWall", V(20, 14.5, 0.12), V(0, 10.2, 28.88), P.charcoal, Enum.Material.Concrete)
    for _, x in {-10.2, 10.2} do
        part(walls, "FeatureBorder", V(0.12, 14.5, 0.18), V(x, 10.2, 28.76), P.bronze, Enum.Material.Metal)
    end
    text(walls, "FeaturedTitle", "THE COLLECTION", V(14, 1.5, 0.12), V(0, 13.6, 28.72))
    text(walls, "FeaturedSubtitle", "A GALLERY OF EXTRAORDINARY FINDS", V(13, 0.65, 0.08), V(0, 11.8, 28.65))
    for _, x in {-26.8, 26.8} do
        part(root, "FloorBorder", V(0.16, 0.02, 55), V(x, 1.36, 0), P.bronze, Enum.Material.Metal)
    end
    for _, z in {-27, 27} do part(root, "FloorBorder", V(53.6, 0.02, 0.16), V(0, 1.36, z), P.bronze, Enum.Material.Metal) end
    part(root, "GalleryFloorInlay", V(45, 0.018, 0.3), V(0, 1.375, -7), P.stone, Enum.Material.Marble)
    -- Lobby stays to the right of the receiving zone and opposite recovery.
    local deskSource = template("ReceptionDesk", "B1ReceptionDesk")
    if deskSource then
        local _, deskSize = deskSource:GetBoundingBox()
        importedModel(deskSource, lobby, "ReceptionDeskVisual", CF(20, 1.3, -19),
            9.3 / deskSize.X, "Desk")
        text(lobby, "CuratorLabel", "CURATOR", V(4, 0.7, 0.06), V(20, 3.25, -21.05))
    else
        part(lobby, "Counter", V(9, 2.8, 2.8), V(20, 2.7, -19), P.walnut, Enum.Material.Wood)
        part(lobby, "CounterTop", V(9.4, 0.22, 3.1), V(20, 4.2, -19), P.stone, Enum.Material.Marble)
        part(lobby, "CounterAccent", V(8.8, 0.1, 0.08), V(20, 2.2, -20.45), P.bronze, Enum.Material.Metal)
        text(lobby, "CuratorLabel", "CURATOR", V(4, 0.7, 0.06), V(20, 3.25, -20.5))
    end
    text(lobby, "Welcome", "WELCOME TO YOUR MUSEUM", V(12, 1.2, 0.12), CF(18, 10, -28.88) * CFrame.Angles(0, math.pi, 0))
    local map = text(lobby, "WallMap", "MUSEUM DISTRICT\n\n01   02   03\n     DEPOT\n04   05   06", V(7, 5, 0.16),
        CF(28.75, 9, -18) * CFrame.Angles(0, math.pi / 2, 0))
    part(lobby, "BrochureStand", V(1.4, 3, 0.8), V(13.6, 2.8, -20), P.charcoal, Enum.Material.Metal)
    part(lobby, "Brochures", V(1.2, 0.08, 1), CF(13.6, 4.35, -20) * CFrame.Angles(0.3, 0, 0), P.ivory)
    pot(lobby, "LobbyPlant", CF(26, 0, -25), 1.3, 0.9)
    bench(furniture, "VisitorBench", CF(24.5, 0, -3) * CFrame.Angles(0, math.pi / 2, 0), 1.3)
    pot(furniture, "RearPlant", CF(-25.6, 0, 25.5), 1.3, 0.9)
    part(furniture, "UtilityCabinet", V(3.6, 4.8, 0.7), V(-25, 3.75, 28.55), P.stone, Enum.Material.Metal)
    part(furniture, "CabinetHandle", V(0.1, 0.7, 0.1), V(-24, 3.8, 28.12), P.charcoal, Enum.Material.Metal)
    text(furniture, "SafetyPlaque", "GALLERY SERVICES", V(3.8, 0.6, 0.1), V(-25, 6.55, 28.12))
    part(furniture, "ExtinguisherCase", V(1.2, 2.2, 0.4), V(9, 3, -28.7), Color3.fromRGB(132, 67, 58), Enum.Material.Metal)
    part(furniture, "RecoveryFinish", V(3.05, 4.05, 0.035), V(-23, 3.3, -11.03), P.charcoal, Enum.Material.Metal)
    for _, side in {-1, 1} do
        part(furniture, "RecoverySideFinish", V(0.035, 4.05, 2), V(-23 + side * 1.525, 3.3, -10), P.charcoal, Enum.Material.Metal)
    end
    text(furniture, "RecoveryLabel", "RECOVERY", V(2.6, 0.5, 0.04), V(-23, 4.5, -11.08))
    text(lobby, "ExitSign", "EXIT", V(3, 0.8, 0.12), CF(0, 14, -28.82) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(50, 88, 72))
    part(furniture, "CameraMount", V(0.2, 0.3, 0.6), V(27, 16, -26.7), P.charcoal, Enum.Material.Metal)
    part(furniture, "VisualCamera", V(0.8, 0.55, 1.2), CF(27, 15.7, -26.2) * CFrame.Angles(-0.2, -0.6, 0), P.stone, Enum.Material.Metal)
    -- Ceiling lining stays immediately below the existing 18.3-stud underside.
    part(ceiling, "CeilingLining", V(57.8, 0.04, 57.8), V(0, 18.26, 0), P.ivory)
    for _, x in {-20, 0, 20} do part(ceiling, "CeilingJoint", V(0.14, 0.02, 56), V(x, 18.23, 0), P.stone) end
    for _, z in {-20, 0, 20} do part(ceiling, "CeilingJoint", V(56, 0.02, 0.14), V(0, 18.23, z), P.stone) end
    for _, x in {-26, 26} do part(ceiling, "PerimeterLightStrip", V(0.18, 0.08, 51), V(x, 18.08, 0), P.warmLight, Enum.Material.Neon) end
    for _, z in {-26, 26} do part(ceiling, "PerimeterLightStrip", V(51, 0.08, 0.18), V(0, 18.08, z), P.warmLight, Enum.Material.Neon) end
    for _, x in {-18, 18} do
        part(ceiling, "TrackRail", V(0.2, 0.22, 38), V(x, 17.95, 0), P.charcoal, Enum.Material.Metal)
        for _, z in {-15, 0, 15} do
            part(ceiling, "TrackHousing", V(0.8, 0.65, 1), V(x, 17.55, z), P.charcoal, Enum.Material.Metal)
            part(ceiling, "TrackLens", V(0.6, 0.06, 0.7), V(x, 17.18, z), P.warmLight, Enum.Material.Neon)
        end
    end
    local ambient = part(ceiling, "LobbyLightBox", V(12, 0.1, 5), V(0, 18.12, -16), P.warmLight, Enum.Material.Neon)
    local light = Instance.new("SurfaceLight")
    light.Face, light.Angle, light.Range, light.Brightness = Enum.NormalId.Bottom, 160, 38, 0.55
    light.Color, light.Shadows, light.Parent = P.warmLight, false, ambient
    for _, entry in {{"ProtectedDisplaySocket", "PROTECTED COLLECTION"}, {"Exposed01Socket", "GALLERY / 01"}, {"Exposed02Socket", "GALLERY / 02"}} do
        local socket = museum[entry[1]]
        local x, z, half = socket.Position.X, socket.Position.Z, socket.Size.X / 2
        text(root, entry[1] .. "Label", entry[2], V(half * 1.7, 0.5, 0.08), V(x, 2.5, z - half - 0.08))
        local ring = template("DisplayKit", "B8PedestalDetailedRing")
        if ring then
            local _, bounds = ring:GetBoundingBox()
            local topName = (entry[1]:gsub("Display", ""):gsub("Socket", "StandTop"))
            local top = assert(hall:FindFirstChild(topName))
            local scale = socket.Size.X / bounds.X
            local topY = top.Position.Y + top.Size.Y / 2 - 0.01
            batchModel(ring, root, entry[1] .. "Detail",
                CF(x, topY - bounds.Y * scale, z), scale, "Pedestal")
        else
            for _, side in {-1, 1} do
                part(root, "StandEdge", V(0.08, 0.08, half * 2), V(x + side * (half - 0.04), 3.47, z), P.bronze, Enum.Material.Metal)
            end
        end
        local lamp = part(gallery, entry[1] .. "Spot", V(0.85, 0.55, 0.85), V(x, 17.4, z), P.charcoal, Enum.Material.Metal)
        local spot = Instance.new("SpotLight")
        spot.Face, spot.Color, spot.Angle = Enum.NormalId.Bottom, P.warmLight, 65
        spot.Range, spot.Brightness, spot.Shadows, spot.Parent = 24, 1.4, false, lamp
        local housing = template("LightingKit", "B7SpotlightHousing")
        if housing then
            local _, bounds = housing:GetBoundingBox()
            batchModel(housing, gallery, entry[1] .. "Housing", CF(x, 17.1, z),
                0.85 / math.max(bounds.X, bounds.Z), "Light")
            lamp.Transparency = 1
        end
    end
end

local function bed(parent, name, x, z, width, depth, style)
    local g = group(parent, name)
    local planter = template("LandscapeKit", "RectPlanterShrub")
    if planter and (name == "ArrivalLeft" or name == "ArrivalRight") then
        local _, size = planter:GetBoundingBox()
        -- Two compact modules fit entirely inside each existing 13 x 5 bed.
        for _, side in {-1, 1} do
            landscapeModel(planter, g, "B5ArrivalPlanter",
                CF(x + side * 3, 0.4, z), 4 / size.X)
        end
        return
    end
    local base = part(g, "Soil", V(width, 0.08, depth), V(x, 0.4, z), P.soil, Enum.Material.Ground)
    if style == "natural" then base.Shape = Enum.PartType.Cylinder; base.Size = V(0.08, width, depth); base.CFrame *= CFrame.Angles(0, 0, math.pi / 2) end
    for _, side in {-1, 1} do
        part(g, "Edging", V(width, 0.18, 0.18), V(x, 0.48, z + side * depth / 2), P.stone, Enum.Material.Limestone)
    end
    local shrubSource = template("LandscapeKit", "ShrubOnly")
    local shrubSize = if shrubSource then select(2, shrubSource:GetBoundingBox()) else nil
    for i = 1, 3 do
        local shrubX = x + (i - 2) * width / 3.3
        if shrubSource and shrubSize then
            local turn = depth > width
            local sourceWidth = if turn then shrubSize.Z else shrubSize.X
            local sourceDepth = if turn then shrubSize.X else shrubSize.Z
            local fit = math.min(width / 3.4 / sourceWidth,
                math.min(depth - 0.3, 2.4) / sourceDepth)
            local cf = CF(shrubX, 0.44, z)
                * CFrame.Angles(0, if turn then math.pi / 2 else 0, 0)
            landscapeModel(shrubSource, g, "B5Shrub", cf, fit)
        else
            local shrub = ball(g, "Shrub", V(width / 3.4, 1.25, math.min(depth - 0.3, 2.4)),
                V(shrubX, 1.05, z), i == 2 and P.lawn or P.hedge)
            shrub.CastShadow = false
            ball(g, "Flower", V(0.55, 0.2, 0.55), V(shrubX, 1.72, z - 0.3),
                style == "classical" and Color3.fromRGB(193, 169, 156) or Color3.fromRGB(192, 188, 143))
        end
    end
end

function Kit.BuildLandscape(index, museum)
    local _, _, half = starter(museum)
    local preset = assert(D.Presets[index], "Unknown landscape preset")
    local model = group(nil, preset.id, "Model")
    model:SetAttribute("PresetId", preset.id)
    model:SetAttribute("PresetIndex", index)
    model:SetAttribute("Tier", 1)
    model:SetAttribute("ClearOnExpansion", true)
    -- Normalized to the measured used grounds. All objects are removable with
    -- this tier. The unused reservation outside +/-60 stays free of scenery.
    local garden, service = group(model, "Garden"), group(model, "ServiceArea")
    local x, front, back = half * 0.73, -half * 0.75, half * 0.73
    local style = index == 2 and "natural" or index == 4 and "classical" or "formal"
    bed(garden, "ArrivalLeft", -24, front, index == 5 and 5 or 13, 5, style)
    bed(garden, "ArrivalRight", 24, front, index == 5 and 5 or 13, 5, style)
    bed(garden, "SideLeft", -x, -7, 5, 13, style)
    bed(garden, "SideRight", x, -7, 5, 13, style)
    -- Small side-garden details stay inside the 120-stud used grounds.
    for _, side in {-1, 1} do
        part(garden, "SideGardenGravel", V(6, 0.045, 11), V(side * 43, 0.35, 29),
            P.stone, Enum.Material.Pebble)
        for _, z in {25, 31} do
            ball(garden, "SideGrass", V(2.4, 1.1, 2.2), V(side * 43, 0.95, z), P.hedge)
        end
        part(garden, "ArrivalStoneBand", V(7.5, 0.045, 8), V(side * 21, 0.35, -36),
            P.paving, Enum.Material.Pavement)
        part(garden, "GardenMarker", V(0.65, 2.6, 0.65), V(side * 35, 1.6, 42),
            P.bronze, Enum.Material.Metal)
        part(garden, "GardenMarkerLens", V(0.8, 0.12, 0.8), V(side * 35, 2.95, 42),
            P.warmLight, Enum.Material.Neon)
    end
    -- Comparable sightlines: low planting and two trees with high canopies at
    -- the same side-edge positions for every preset.
    tree(garden, "LeftOrnamental", V(-half * 0.86, 0.3, 18), index == 4 and 3 or index % 3, 0.9)
    tree(garden, "RightOrnamental", V(half * 0.86, 0.3, 18), index == 6 and 3 or index % 3, 0.9)
    local patioWidth = index == 3 and 29 or 23
    part(garden, "PrivatePatio", V(patioWidth, 0.06, 14), V(-12, 0.36, back), P.paving, Enum.Material.Pavement)
    for _, z in {back - 5, back, back + 5} do part(garden, "PatioJoint", V(patioWidth, 0.02, 0.14), V(-12, 0.43, z), P.stone) end
    bench(garden, "GardenBench", CF(-18, 0, back + 4), 0.4)
    bed(garden, "RearPlanting", -12, half * 0.92, 24, 3, style)
    if index == 1 then
        bed(garden, "FormalRearBorder", -28, back, 3, 12, style)
        pot(garden, "FormalUrn", CF(-2, 0, back), 0.4, 1)
    elseif index == 2 then
        for i = 1, 4 do
            part(garden, "GardenSteppingStone", V(2.5, 0.07, 2.5), CF(-28 + i * 3, 0.42, 35 + math.sin(i) * 2) * CFrame.Angles(0, i * 0.12, 0), P.stone, Enum.Material.Slate)
            ball(garden, "Rock", V(1.8, 0.9, 1.3), V(44 + i * 1.5, 0.7, -28 + i), P.stone)
        end
    elseif index == 3 then
        sculpture(garden, "CourtyardArt", CF(-7, 0, back), 0.4, "ribbon")
        sculpture(garden, "SideArt", CF(-x, 0, -30), 0.3, "ribbon")
        bench(garden, "SecondGardenBench", CF(-26, 0, back) * CFrame.Angles(0, -math.pi / 2, 0), 0.4)
    elseif index == 4 then
        sculpture(garden, "StillFountain", CF(-7, 0, back), 0.4, "fountain")
        pot(garden, "ClassicalUrnLeft", CF(-28, 0, front + 8), 0.3, 1)
        pot(garden, "ClassicalUrnRight", CF(28, 0, front + 8), 0.3, 1)
    elseif index == 5 then
        part(garden, "GravelGarden", V(9, 0.05, 13), V(45, 0.35, -30), P.stone, Enum.Material.Pebble)
        for _, x2 in {-10, 10} do part(garden, "LinearPathLight", V(0.12, 0.04, 18), V(x2, 0.36, -45), P.warmLight, Enum.Material.Neon) end
        pot(garden, "SculpturalPlanter", CF(-4, 0, back), 0.4, 1.25)
    elseif index == 6 then
        for _, x2 in {-30, 30} do
            part(garden, "BannerPole", V(0.16, 9, 0.16), V(x2, 4.8, -51), P.charcoal, Enum.Material.Metal)
            text(garden, "ExhibitionBanner", "COLLECT\nCURATE", V(2.5, 5, 0.08), V(x2 + 1.3, 6.3, -51), P.charcoal)
        end
        part(garden, "GardenLowWall", V(12, 1.2, 0.5), V(-44, 0.9, -30), P.stone, Enum.Material.Concrete)
    end
    -- Identical service envelope keeps the private garden and routes open.
    part(service, "ServicePaving", V(18, 0.06, 16), V(22, 0.36, 43), P.stone, Enum.Material.Concrete)
    local generator = template("ServiceKit", "B9Generator")
    if generator then
        local _, bounds = generator:GetBoundingBox()
        batchModel(generator, service, "B9Generator", CF(26, 0.35, 47),
            math.min(4 / bounds.X, 2.8 / bounds.Y, 3 / bounds.Z), "Generator")
    else
        part(service, "Generator", V(4, 2.8, 3), V(26, 1.75, 47), P.charcoal, Enum.Material.Metal)
        for i = 1, 4 do part(service, "GeneratorLouver", V(3.4, 0.12, 0.08), V(26, 0.8 + i * 0.5, 45.45), P.stone, Enum.Material.Metal) end
    end
    for i = 1, 5 do part(service, "UtilityScreenSlat", V(9, 0.22, 0.25), V(25, 0.45 + i * 0.65, 50.4), P.walnut, Enum.Material.Wood) end
    local pallet = template("ServiceKit", "B9Pallet")
    if pallet then
        local _, bounds = pallet:GetBoundingBox()
        batchModel(pallet, service, "B9Pallet", CF(16, 0.37, 47),
            math.min(4 / bounds.X, 3 / bounds.Z), "Pallet")
    else
        part(service, "Pallet", V(4, 0.35, 3), V(16, 0.55, 47), P.walnut, Enum.Material.WoodPlanks)
    end
    local crate = template("ServiceKit", "B9ServiceCrate")
    if crate then
        local _, bounds = crate:GetBoundingBox()
        batchModel(crate, service, "B9ServiceCrate", CF(16, 0.79, 47),
            math.min(2.7 / bounds.X, 2.5 / bounds.Z, 2.6 / bounds.Y), "Crate")
    else
        part(service, "ServiceCrate", V(2.7, 1.8, 2.5), V(16, 1.62, 47), P.stone, Enum.Material.WoodPlanks)
        for _, x2 in {15, 17} do part(service, "CrateStrap", V(0.15, 1.86, 2.56), V(x2, 1.62, 47), P.charcoal, Enum.Material.Metal) end
    end
    part(service, "Drain", V(3, 0.03, 0.55), V(18, 0.41, 33), P.charcoal, Enum.Material.Metal)
    text(service, "ServiceNotice", "MAINTENANCE\nKEEP CLEAR", V(3.5, 1.4, 0.1), V(26, 3.8, 45.35))
    for _, pos in {V(-25, 1.2, 39), V(-1, 1.2, 49)} do
        part(garden, "Bollard", V(0.4, 1.8, 0.4), pos, P.charcoal, Enum.Material.Metal)
        part(garden, "BollardLens", V(0.44, 0.18, 0.44), pos + V(0, 0.65, 0), P.warmLight, Enum.Material.Neon)
    end
    return model
end

local function pathStrip(parent, name, a, b, width, y, color)
    local av, bv = V(a.X, y, a.Z), V(b.X, y, b.Z)
    return part(parent, name, V(width, 0.04, (bv - av).Magnitude), CFrame.lookAt((av + bv) / 2, bv), color, Enum.Material.Pavement)
end

local function streetLamp(parent, name, pos, actual)
    local g = group(parent, name)
    part(g, "Foot", V(1.5, 0.3, 1.5), pos + V(0, 0.15, 0), P.stone, Enum.Material.Concrete)
    part(g, "Pole", V(0.22, 10, 0.22), pos + V(0, 5.2, 0), P.charcoal, Enum.Material.Metal)
    part(g, "Head", V(2.1, 0.3, 1.1), pos + V(0, 10.3, 0), P.charcoal, Enum.Material.Metal)
    local lens = part(g, "Lens", V(1.7, 0.08, 0.8), pos + V(0, 10.1, 0), P.warmLight, Enum.Material.Neon)
    if actual then point(lens, 0.6, 26) end
end

local function edgeFog(parent, name, pos)
    local anchor = part(parent, name, V(65, 5, 24), pos, P.stone)
    anchor.Transparency = 1
    local fog = Instance.new("ParticleEmitter")
    fog.Name = "LocalizedEdgeMist"
    fog.Texture = "rbxasset://textures/particles/smoke_main.dds"
    fog.Color = ColorSequence.new(Color3.fromRGB(172, 184, 190))
    fog.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0.77),
        NumberSequenceKeypoint.new(0.7, 0.79),
        NumberSequenceKeypoint.new(1, 1),
    })
    fog.Size = NumberSequence.new(37)
    fog.Rate = 1.1
    fog.Lifetime = NumberRange.new(9, 12)
    fog.Speed = NumberRange.new(0.6, 1.2)
    fog.SpreadAngle = Vector2.new(12, 12)
    fog.LightInfluence = 0.8
    fog.Parent = anchor
end

local function buildEdgeLandforms(per)
    local land = group(per, "SculptedRidges")
    local grass = Color3.fromRGB(77, 103, 78)
    local darkGrass = Color3.fromRGB(62, 87, 70)
    -- Join the original ground at its exact outer edge so no ridge can appear
    -- suspended over empty space. The crossing strips do not enter the map.
    for _, sign in {-1, 1} do
        part(land, "NorthSouthGroundExtension", V(1000, 1, 220),
            V(0, -0.5, sign * 650), grass, Enum.Material.Grass)
        part(land, "EastWestGroundExtension", V(220, 1, 1080),
            V(sign * 610, -0.5, 0), grass, Enum.Material.Grass)
    end
    local function hill(name, pos, size, buried, color)
        -- The lower half lives below the grass apron. This produces a rounded
        -- crest and tapered sides without a floating triangle or flat roof.
        local mound = part(land, name, size,
            pos - V(0, buried, 0), color, Enum.Material.Grass)
        mound.Shape = Enum.PartType.Ball
        mound.CastShadow = false
        mound:SetAttribute("EdgeLandform", true)
    end
    -- Broad overlapping mounds follow the original outer edge. The north,
    -- south, east, and west approach gaps stay open for future connections.
    for _, sign in {-1, 1} do
        for i, x in {-405, -290, -175, 175, 290, 405} do
            local height = ({163, 181, 173, 177, 187, 167})[i]
            local size = V(180, height, 250)
            local buried = height / 2 - (42 + i % 3 * 5)
            hill("RoundedOuterHill", V(x, 0, sign * 610), size, buried,
                if i % 2 == 0 then grass else darkGrass)
            for _, dx in {-27, 28} do
                local names = {"B6RockLow", "B6RockTall", "B6RockArch"}
                local rock = dx < 0 and template("RockKit", names[(i + (sign + 1) / 2) % 3 + 1])
                if rock then
                    local _, bounds = rock:GetBoundingBox()
                    local yaw = math.rad((i * 37 + sign * 19) % 150 - 75)
                    -- The old 551-stud toe sits behind the 80-stud boundary.
                    -- The hill's inner toe at 610 - 107 is visible and still
                    -- outside every plot reservation and traveled route.
                    batchModel(rock, land, "RidgeToeRock", CF(x + dx, 0.06, sign * (610 - 107))
                        * CFrame.Angles(0, yaw, 0),
                        math.min(7.5 / bounds.X, 5.5 / bounds.Y, 6.5 / bounds.Z), "Rock")
                else
                    ball(land, "RidgeToeRock", V(7.5, 3.8, 6),
                        V(x + dx, 1.1, sign * 551), Color3.fromRGB(82, 90, 86))
                end
            end
            for j, dx in {-43, -14, 16, 42} do
                local distance = 546 + (i % 3) * 4
                tree(land, "RidgeTree", V(x + dx, 0, sign * distance),
                    (i + j) % 3, 1.15 + ((i + j) % 3) * 0.15)
            end
            for j, dx in {-17, 16} do
                ball(land, "RidgeBoulder", V(5 + (i % 2), 2.4, 3.8),
                    V(x + dx, 0.9, sign * (541 + j * 0.14)), Color3.fromRGB(82, 90, 86))
            end
        end
        for i, z in {-390, -300, 300, 390} do
            local size = V(230, 134 + (i % 3) * 9, 150)
            local buried = size.Y / 2 - 38
            hill("RoundedSideHill", V(sign * 585, 0, z), size, buried, grass)
            tree(land, "ShoulderTree", V(sign * 513, 0, z + 14), i % 3, 1.25)
        end
    end
    for _, x in {-345, 345} do
        for _, z in {-556, 556} do edgeFog(land, "EdgeMist", V(x, 7, z)) end
    end
    for _, x in {-531, 531} do
        for _, z in {-340, 340} do edgeFog(land, "EdgeMist", V(x, 7, z)) end
    end
end

local function buildBoundary(world)
    local existing = world:FindFirstChild("PerimeterCollision")
    if existing then
        assert(existing:GetAttribute("GeneratedBy") == owner,
            "Refusing to replace unrelated world boundary")
        existing:Destroy()
    end
    local root = Instance.new("Folder")
    root.Name = "PerimeterCollision"
    root:SetAttribute("GeneratedBy", owner)
    root.Parent = world
    -- The west center gap faces the original museum from the staged district.
    -- Keep the rest of the edge closed until the connecting path is built.
    for _, spec in {
        {"EastWall", V(4, 80, 1084), V(500, 40, 0)},
        {"WestWallNorth", V(4, 80, 482), V(-500, 40, -301)},
        {"WestWallSouth", V(4, 80, 482), V(-500, 40, 301)},
        {"NorthWall", V(1004, 80, 4), V(0, 40, -540)},
        {"SouthWall", V(1004, 80, 4), V(0, 40, 540)},
    } do
        local wall = Instance.new("Part")
        wall.Name, wall.Size, wall.CFrame = spec[1], spec[2], CF(spec[3])
        wall.Transparency = 1
        wall.Anchored = true
        wall.CanCollide, wall.CanQuery, wall.CanTouch = true, true, false
        wall:SetAttribute("Task11Boundary", true)
        wall.Parent = root
    end
end

function Kit.ApplyPavilionPalette(container)
    for _, mesh in container:GetDescendants() do
        if mesh:IsA("MeshPart") and mesh.TextureID == "" and not mesh:FindFirstChildOfClass("SurfaceAppearance") then
            local name = mesh.Name
            if name == "PavRoof_EaveSlab" or name == "Beam_Body"
                or name == "Sign_OverheadBeam" or name == "Beam_Bracket_Left"
                or name == "Beam_Bracket_Right" then
                mesh.Color, mesh.Material = P.charcoal, Enum.Material.Metal
            elseif string.find(name, "Teal") or string.find(name, "Enamel")
                or string.find(name, "Panel_") or name == "Sign_BeamFaceStrip" then
                mesh.Color, mesh.Material = P.entranceTeal, Enum.Material.SmoothPlastic
            elseif string.find(name, "Corbel_L") or string.find(name, "Corbel_R") then
                mesh.Color, mesh.Material = P.ivory, Enum.Material.Limestone
            else
                mesh.Color, mesh.Material = P.entranceGold, Enum.Material.Metal
            end
        end
    end
end

local function addPavilionModule(kit, parent, sourceName, name, scale, target)
    local source = kit:FindFirstChild(sourceName)
    if not source or not source:IsA("Model") then
        warn("[Task11] Missing A3 pavilion module: " .. sourceName)
        return
    end
    local copy = source:Clone()
    copy.Name = name
    copy:ScaleTo(scale)
    local box = copy:GetBoundingBox()
    local pivotToBox = copy:GetPivot():ToObjectSpace(box)
    copy:PivotTo(target * pivotToBox:Inverse())
    for _, mesh in copy:GetDescendants() do
        if mesh:IsA("MeshPart") then
            mesh.Anchored = true
            mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = false, false, false
            mesh:SetAttribute("Task11Visual", true)
        end
    end
    Kit.ApplyPavilionPalette(copy)
    copy.Parent = parent
end

local function addPavilionKit(depot)
    local visualAssets = game.ReplicatedStorage:FindFirstChild("VisualAssets")
    local kit = visualAssets and visualAssets:FindFirstChild("PavilionKit")
    if not kit then return end
    local imported = replace(depot, "A3PavilionKit")
    local roofSource = kit:FindFirstChild("A3PavilionRoofModule")
    local beamSource = kit:FindFirstChild("A3_PavilionBeam")
    local signSource = kit:FindFirstChild("A3_PavilionSignage")
    if roofSource and roofSource:IsA("Model") then
        local _, roofSize = roofSource:GetBoundingBox()
        for _, wing in depot:GetChildren() do
            if wing.Name == "PavilionRoofWing" and wing:IsA("BasePart") then
                local scale = (wing.Size.X - 0.3) / roofSize.X
                local height = roofSize.Y * scale
                local target = wing.CFrame * CF(0, wing.Size.Y / 2 + height / 2 + 0.01, -1.4)
                addPavilionModule(kit, imported, roofSource.Name,
                    if wing.Position.X < 0 then "WestRoofDetail" else "EastRoofDetail", scale, target)
            end
        end
    end
    local entryBeam = depot:FindFirstChild("PavilionEntryBeam")
    if beamSource and beamSource:IsA("Model") and entryBeam then
        local _, beamSize = beamSource:GetBoundingBox()
        local scale = 1.8
        local drop = -entryBeam.Size.Y / 2 - beamSize.Y * scale / 2 + 0.12
        for _, side in {-1, 1} do
            addPavilionModule(kit, imported, beamSource.Name,
                if side < 0 then "WestEntryBeamDetail" else "EastEntryBeamDetail", scale,
                entryBeam.CFrame * CF(side * 23, drop, 0) * CFrame.Angles(0, math.pi / 2, 0))
        end
    end
    local deskSign = depot:FindFirstChild("CuratorDeskSign")
    if signSource and signSource:IsA("Model") and deskSign then
        -- Frame the existing lettering without replacing its SurfaceGui.
        addPavilionModule(kit, imported, signSource.Name, "CuratorSignFrame", 2.05,
            deskSign.CFrame * CF(0, 0, 0.95))
    end
end

function Kit.RefreshPavilion(world)
    local visuals = world:FindFirstChild("SharedWorldVisuals")
    local depot = visuals and visuals:FindFirstChild("DepotVisuals")
    if depot then addPavilionKit(depot) end
end

function Kit.BuildWorld(world)
    assert(world.Ground.Size == V(1000, 1, 1080), "World geometry differs from audit")
    buildBoundary(world)
    local root = replace(world, "SharedWorldVisuals")
    local plaza, depot = group(root, "CentralPlaza"), group(root, "DepotVisuals")
    local paths = group(root, "Paths")
    local terrain = group(root, "TerrainDecor")
    local per = replace(world, "PerimeterDecor")
    buildEdgeLandforms(per)
    part(plaza, "PlatformFinish", V(69.8, 0.025, 69.8), V(0, 0.71, 0), P.paving, Enum.Material.Pavement)
    for _, x in {-28, -14, 0, 14, 28} do
        part(plaza, "PavingJoint", V(0.16, 0.02, 69.8), V(x, 0.76, 0), P.stone)
        part(plaza, "PavingJoint", V(69.8, 0.02, 0.16), V(0, 0.76, x), P.stone)
    end
    for _, side in {-1, 1} do
        part(plaza, "PlatformInlay", V(68, 0.02, 0.25), V(0, 0.80, side * 34), P.bronze, Enum.Material.Metal)
        part(plaza, "PlatformInlay", V(0.25, 0.02, 68), V(side * 34, 0.80, 0), P.bronze, Enum.Material.Metal)
    end
    -- The landmark occupies the quiet east margin; all six radial crossings stay open.
    sculpture(plaza, "DistrictMonument", CF(39, 0, 0), 0.2, "ribbon")
    text(plaza, "DistrictIdentity", "THE COLLECTOR'S DISTRICT", V(23, 2.2, 0.2), V(0, 14, 28))
    for _, x in {-30, 30} do
        bench(plaza, "PlazaBench", CF(x, 0, -29), 0.7)
        pot(plaza, "PlazaPlanter", CF(x, 0, 29), 0.7, 1.2)
    end
    for i, pos in {V(-39, 0.2, -39), V(39, 0.2, -39), V(-39, 0.2, 39), V(39, 0.2, 39)} do streetLamp(plaza, "PlazaLamp" .. i, pos, true) end
    for i, x in {-39, 39} do
        part(plaza, "WayfindingPost", V(0.18, 5.5, 0.18), V(x, 2.95, -20), P.charcoal, Enum.Material.Metal)
        text(plaza, "Wayfinding", i == 1 and "04 / 05 / 06\nMUSEUM GARDENS" or "01 / 02 / 03\nMUSEUM GARDENS", V(7, 1.8, 0.12), V(x, 5.2, -20))
    end
    -- High, visually open depot framing surrounds the existing four pedestals.
    for _, x in {-30, 30} do
        part(depot, "DepotColumn", V(0.6, 15, 0.6), V(x, 8.2, 27), P.charcoal, Enum.Material.Metal)
        part(depot, "DepotCanopyColumn", V(0.5, 12.6, 0.5), V(x, 7.05, 5), P.charcoal, Enum.Material.Metal)
        part(depot, "DepotSideBeam", V(0.45, 0.6, 23), V(x, 13.65, 16), P.bronze, Enum.Material.Metal)
    end
    for _, z in {5, 12, 19, 26} do
        part(depot, "OpenCanopyBeam", V(60, 0.5, 0.4), V(0, 13.6, z), P.charcoal, Enum.Material.Metal)
    end
    -- Two roof wings frame the existing public pedestals. The center stays
    -- open to the sky and every authoritative pickup position stays visible.
    for _, x in {-18.5, 18.5} do
        part(depot, "PavilionRoofWing", V(23, 0.35, 26), V(x, 16.1, 15),
            P.charcoal, Enum.Material.Metal)
        part(depot, "PavilionRoofSoffit", V(21, 0.08, 24), V(x, 15.85, 15),
            P.stone, Enum.Material.SmoothPlastic)
        part(depot, "PavilionBronzeEdge", V(23, 0.15, 0.3), V(x, 16.32, 1.9),
            P.bronze, Enum.Material.Metal)
        local lens = part(depot, "PavilionLightRibbon", V(17, 0.09, 0.28), V(x, 15.77, 4),
            P.warmLight, Enum.Material.Neon)
        point(lens, 0.5, 27)
    end
    part(depot, "PavilionEntryBeam", V(60, 1, 0.8), V(0, 15.7, -29),
        P.charcoal, Enum.Material.Metal)
    for _, x in {-29, 29} do
        part(depot, "PavilionEntryPost", V(0.65, 15, 0.65), V(x, 8, -29),
            P.charcoal, Enum.Material.Metal)
    end
    text(depot, "PavilionTitle", "PUBLIC ACQUISITION PAVILION", V(33, 1.9, 0.18),
        V(0, 16.1, -29.55))
    text(depot, "PavilionSubtitle", "DISTRICT DEPOT  /  CURATOR HUB", V(25, 0.9, 0.14),
        V(0, 14.8, -29.55))
    part(depot, "CuratorCounter", V(8, 2.6, 2.2), V(-25, 2.0, -4),
        P.walnut, Enum.Material.Wood)
    part(depot, "CuratorCounterTop", V(8.5, 0.2, 2.5), V(-25, 3.4, -4),
        P.stone, Enum.Material.Marble)
    text(depot, "CuratorDeskSign", "CURATOR  /  INFORMATION", V(8, 0.8, 0.12),
        V(-25, 4.4, -5.2))
    addPavilionKit(depot)
    for _, x in {-31, 31} do
        part(depot, "EntryBannerPole", V(0.15, 10, 0.15), V(x, 6.3, -30),
            P.charcoal, Enum.Material.Metal)
        text(depot, "EntryBanner", "FIND  /  RETURN", V(2.4, 5.4, 0.1),
            V(x + (if x < 0 then 1.3 else -1.3), 9.1, -30))
    end
    part(depot, "DepotHeader", V(61, 1, 1), V(0, 15.8, 27), P.charcoal, Enum.Material.Metal)
    part(depot, "DepotHeaderLine", V(58, 0.12, 0.18), V(0, 15.14, 26.4), P.warmLight, Enum.Material.Neon)
    text(depot, "DepotSign", "PUBLIC COLLECTION DEPOT", V(28, 1.6, 0.18), V(0, 12, 27))
    for i, data in {{"Tutorial", 0, -18}, {"Public01", -20, 12}, {"Public02", 0, 12}, {"Public03", 20, 12}} do
        local x, z = data[2], data[3]
        for _, side in {-1, 1} do part(depot, "PedestalEdge", V(0.1, 0.1, 8), V(x + side * 3.9, 2.72, z), P.bronze, Enum.Material.Metal) end
        text(depot, data[1] .. "Caption", i == 1 and "YOUR FIRST FIND" or "PUBLIC STOCK / " .. (i - 1), V(7, 0.65, 0.1), V(x, 1.8, z - 4.1))
    end
    for _, x in {-26, 26} do
        part(depot, "LogisticsCrate", V(3.5, 2, 3), V(x, 1.7, 23), P.walnut, Enum.Material.WoodPlanks)
        part(depot, "CrateBand", V(0.2, 2.1, 3.1), V(x, 1.7, 23), P.charcoal, Enum.Material.Metal)
    end
    for index, slot in Plots.Slots do
        local reserve = part(terrain, "ReservedLawn" .. index, V(279.8, 0.02, 279.8),
            slot.center + V(0, 0.025, 0), Color3.fromRGB(94, 129, 84), Enum.Material.Grass)
        reserve:SetAttribute("ClearOnExpansion", true)
        local open = world.Routes["Open" .. index]
        local lane = group(paths, "Route" .. index)
        part(lane, "PublicPaving", V(17.9, 0.025, open.Size.Z), open.CFrame + V(0, 0.065, 0), P.paving, Enum.Material.Pavement)
        for _, side in {-1, 1} do
            part(lane, "PathEdge", V(0.3, 0.18, open.Size.Z), open.CFrame * CF(side * 9.3, 0.07, 0), P.stone, Enum.Material.Limestone)
        end
        local count = math.floor(open.Size.Z / 30)
        for i = 2, count - 1 do
            local distance = -open.Size.Z / 2 + i * open.Size.Z / count
            part(lane, "PaverJoint", V(17.9, 0.02, 0.16), open.CFrame * CF(0, 0.12, distance), P.stone)
        end
        for i = 1, 3 do
            local pos = (open.CFrame * CF(i % 2 == 0 and 12.5 or -12.5, 0, open.Size.Z * (i / 4 - 0.5))).Position
            streetLamp(lane, "PathLamp", V(pos.X, 0, pos.Z), i == 2)
        end
        local a, b = world.Routes["Covered" .. index .. "Waypoint1"].Position, world.Routes["Covered" .. index .. "Waypoint2"].Position
        local gate = world.PlotSlots[slot.id].GateTier1.Position
        local service = group(lane, "CoveredTreatment")
        service:SetAttribute("ClearOnExpansion", true)
        pathStrip(service, "ServicePaving", V(0, 0, 0), a, 13.9, 0.09, Color3.fromRGB(155, 153, 141))
        pathStrip(service, "ServicePaving", a, b, 13.9, 0.09, Color3.fromRGB(155, 153, 141))
        pathStrip(service, "ServicePaving", b, gate, 13.9, 0.09, Color3.fromRGB(155, 153, 141))
        local wall = world.Routes["CoverWall" .. index]
        -- Relief sits against existing cover; no new eye-level occlusion panels.
        part(service, "CoverCoping", V(wall.Size.X, 0.3, 2.1), wall.CFrame * CF(0, 6.1, 0), P.charcoal, Enum.Material.Metal)
        for _, x in {-21, -7, 7, 21} do
            part(service, "CoverPilaster", V(0.25, 11.7, 0.15), wall.CFrame * CF(x, 0, -1.1), P.bronze, Enum.Material.Metal)
        end
        text(service, "ServiceWayfinding", "COVERED WALK / " .. string.format("%02d", index), V(12, 1, 0.08), wall.CFrame * CF(0, 2, -1.15))
        local gateCf = CF(slot.center) * CFrame.Angles(0, math.rad(slot.yawDegrees), 0)
        text(lane, "MuseumNumber", "MUSEUM " .. string.format("%02d", index), V(7, 1.4, 0.15), gateCf * CF(16, 6, -60.6))
        task.wait()
    end
    local function outsidePlots(x, z)
        for _, slot in Plots.Slots do
            if math.abs(x - slot.center.X) < 154 and math.abs(z - slot.center.Z) < 154 then return false end
        end
        return true
    end
    local serial = 0
    for _, z in {-519, 519} do
        for x = -440, 440, 80 do
            if outsidePlots(x, z) then
                serial += 1
                tree(per, "BackgroundTree" .. serial, V(x, 0, z + ((serial % 3) - 1) * 3), serial % 3, 1.25 + (serial % 2) * 0.2)
            end
        end
    end
    for _, x in {-482, 482} do
        for z = -420, 420, 84 do
            if outsidePlots(x, z) then serial += 1; tree(per, "BackgroundTree" .. serial, V(x, 0, z), serial % 3, 1.25) end
        end
    end
    for _, x in {-497, 497} do part(per, "EstateEdge", V(1, 3, 1078), V(x, 1.5, 0), P.stone, Enum.Material.Concrete) end
    for _, z in {-537, 537} do part(per, "EstateEdge", V(994, 3, 1), V(0, 1.5, z), P.stone, Enum.Material.Concrete) end
    -- Composed landscape pockets occupy common space outside every reservation.
    for i, pos in {V(-95, 0, 0), V(95, 0, 0), V(-230, 0, 0), V(230, 0, 0)} do
        local island = group(terrain, "CommonGarden" .. i)
        part(island, "GravelBed", V(24, 0.07, 14), pos + V(0, 0.05, 0), P.soil, Enum.Material.Ground)
        tree(island, "Broadleaf", pos + V(-6, 0, 0), i % 3, 1.1)
        for j = 1, 3 do ball(island, "Shrub", V(4, 1.4, 3), pos + V(3 + j * 2, 0.8, j - 2), P.hedge) end
        ball(island, "Stone", V(3, 1.2, 2.2), pos + V(5, 0.65, 4), P.stone)
    end
    world:SetAttribute("VisualKitVersion", Kit.Version)
end

function Kit.ApplyLandscape(museum, presetTemplate)
    local prior = museum:FindFirstChild("BackyardVisuals")
    if prior then prior:Destroy() end
    local copy = presetTemplate:Clone()
    copy.Name = "BackyardVisuals"
    copy:PivotTo(museum:GetPivot())
    copy.Parent = museum
    return copy
end

return Kit
