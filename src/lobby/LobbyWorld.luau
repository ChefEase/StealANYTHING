--!strict
-- Small, reusable heist staging room. Build in Studio Edit once so the lobby
-- can be reviewed before publication; Bootstrap also builds it if absent.
local Lighting = game:GetService("Lighting")
local AssetPlacement = require(script.Parent.LobbyAssetPlacement)

local LobbyWorld = {}
local FLOOR = Color3.fromRGB(31, 37, 42)
local WALL = Color3.fromRGB(48, 55, 61)
local STEEL = Color3.fromRGB(79, 94, 101)
local BRASS = Color3.fromRGB(189, 145, 75)
local RED = Color3.fromRGB(227, 64, 62)
local TEAL = Color3.fromRGB(49, 214, 190)

local function part(parent: Instance, name: string, size: Vector3,
    position: Vector3, color: Color3, material: Enum.Material,
    collide: boolean?): Part
    local item = Instance.new("Part")
    item.Name = name
    item.Size = size
    item.Position = position
    item.Anchored = true
    item.CanCollide = collide ~= false
    item.Color = color
    item.Material = material
    item.TopSurface = Enum.SurfaceType.Smooth
    item.BottomSurface = Enum.SurfaceType.Smooth
    item.Parent = parent
    return item
end

local function sign(parent: Instance, name: string, text: string,
    size: Vector3, position: Vector3, color: Color3,
    facing: Enum.NormalId?): Part
    local board = part(parent, name, size, position, Color3.fromRGB(15, 23, 29),
        Enum.Material.Metal)
    local face = Instance.new("SurfaceGui")
    face.Face = facing or Enum.NormalId.Back
    face.PixelsPerStud = 45
    face.LightInfluence = 0
    face.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = face
    return board
end

local function light(parent: Instance, position: Vector3, color: Color3)
    local lamp = part(parent, "AlarmLight", Vector3.new(2.5, 0.4, 1.2),
        position, color, Enum.Material.Neon, false)
    local point = Instance.new("PointLight")
    point.Color = color
    point.Range = 18
    point.Brightness = 1.5
    point.Parent = lamp
end

local function addLoungeSeats(model: Model)
    for index, x in { -29, -23 } do
        local seat = model:FindFirstChild("LoungeSeat" .. index)
        if not seat or not seat:IsA("Seat") then
            seat = Instance.new("Seat")
            seat.Name = "LoungeSeat" .. index
            seat.Parent = model
        end
        seat.Size = Vector3.new(5.3, 0.4, 3.25)
        seat.Position = Vector3.new(x, 2.38, 21.8)
        seat.Anchored = true
        seat.CanCollide = true
        seat.CanTouch = false -- E prompt seats players; walking into the couch does not.
        seat.Transparency = 0
        seat.Color = Color3.fromRGB(80, 105, 104)
        seat.Material = Enum.Material.Fabric
        local attachment = seat:FindFirstChild("SitPromptAttachment")
        if not attachment or not attachment:IsA("Attachment") then
            attachment = Instance.new("Attachment")
            attachment.Name = "SitPromptAttachment"
            attachment.Parent = seat
        end
        attachment.Position = Vector3.new(0, 1.7, -1.2)
        local prompt = seat:FindFirstChildOfClass("ProximityPrompt")
            or attachment:FindFirstChildOfClass("ProximityPrompt")
        if not prompt then prompt = Instance.new("ProximityPrompt") end
        prompt.Name = "SitPrompt"
        prompt.Parent = attachment
        prompt.ActionText = "Sit"
        prompt.ObjectText = "Crew Lounge"
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Style = Enum.ProximityPromptStyle.Default
        local standAttachment = seat:FindFirstChild("StandPromptAttachment")
        if not standAttachment or not standAttachment:IsA("Attachment") then
            standAttachment = Instance.new("Attachment")
            standAttachment.Name = "StandPromptAttachment"
            standAttachment.Parent = seat
        end
        standAttachment.Position = Vector3.new(0, 3.8, 1.2)
        local standPrompt = attachment:FindFirstChild("StandPrompt")
            or standAttachment:FindFirstChild("StandPrompt")
        if not standPrompt or not standPrompt:IsA("ProximityPrompt") then
            standPrompt = Instance.new("ProximityPrompt")
            standPrompt.Name = "StandPrompt"
        end
        standPrompt.Parent = standAttachment
        standPrompt.ActionText = "Stand"
        standPrompt.ObjectText = "Crew Lounge"
        standPrompt.KeyboardKeyCode = Enum.KeyCode.G
        standPrompt.GamepadKeyCode = Enum.KeyCode.ButtonB
        standPrompt.MaxActivationDistance = 10
        standPrompt.RequiresLineOfSight = false
        standPrompt.Style = Enum.ProximityPromptStyle.Default
    end
end

local function finishWardrobeDisplay(lobby: Model, display: Model)
    local mannequin = display:FindFirstChild("StarterOutfitMannequin")
    if mannequin and mannequin:IsA("Model") then
        for _, visual in mannequin:GetDescendants() do
            if visual:IsA("BasePart") then visual.CanCollide = true end
        end
        local hull = display:FindFirstChild("MannequinCollision")
        if not hull or not hull:IsA("BasePart") then
            hull = part(display, "MannequinCollision", Vector3.new(3.25, 5.8, 1.6),
                Vector3.new(24, 3.7, 17.5), STEEL, Enum.Material.SmoothPlastic)
        end
        hull.CanCollide = true
        hull.CanQuery = false
        hull.Transparency = 1
    end
    local plinth = display:FindFirstChild("MannequinPlinth")
    if plinth and plinth:IsA("BasePart") then plinth.CanCollide = true end
    for _, name in { "MirrorFrame", "Mirror" } do
        local surface = display:FindFirstChild(name)
        if surface and surface:IsA("BasePart") then surface.CanCollide = true end
    end
    if not display:FindFirstChild("MirrorTitle") then
        sign(display, "MirrorTitle", "FITTING MIRROR",
            Vector3.new(4, 0.45, 0.12), Vector3.new(35.5, 9.2, 23.65),
            Color3.fromRGB(232, 237, 235), Enum.NormalId.Front)
    end
    local oldSign = lobby:FindFirstChild("LockerSign")
    local label = oldSign and oldSign:FindFirstChildOfClass("SurfaceGui")
    local text = label and label:FindFirstChildOfClass("TextLabel")
    if text then text.Text = "ROBBER WARDROBE\nTRY ON + EQUIP" end
end

local function addDeploymentPrompt(lobby: Model)
    local anchor = lobby:FindFirstChild("DeploymentPromptAnchor")
    if not anchor or not anchor:IsA("BasePart") then
        anchor = part(lobby, "DeploymentPromptAnchor", Vector3.new(1, 1, 1),
            Vector3.new(0, 4, -31.5), STEEL, Enum.Material.SmoothPlastic, false)
    end
    anchor.Transparency = 1
    anchor.CanCollide = false
    anchor.CanQuery = false
    local prompt = anchor:FindFirstChild("PlayHeistPrompt")
    if not prompt or not prompt:IsA("ProximityPrompt") then
        prompt = Instance.new("ProximityPrompt")
        prompt.Name = "PlayHeistPrompt"
        prompt.Parent = anchor
    end
    prompt.ActionText = "Play / Join Heist"
    prompt.ObjectText = "Deployment Vault"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
end

local function addWardrobeDisplay(lobby: Model)
    local existing = lobby:FindFirstChild("RobberWardrobeDisplay")
    if existing and existing:IsA("Model") then
        finishWardrobeDisplay(lobby, existing)
        return
    end
    local display = Instance.new("Model")
    display.Name = "RobberWardrobeDisplay"
    display.Parent = lobby
    part(display, "MirrorFrame", Vector3.new(4.8, 8, 0.25),
        Vector3.new(35.5, 5, 24), BRASS, Enum.Material.Metal)
    local mirror = part(display, "Mirror", Vector3.new(4.3, 7.5, 0.1),
        Vector3.new(35.5, 5, 23.82), Color3.fromRGB(125, 163, 171),
        Enum.Material.Glass)
    mirror.Reflectance = 0.35
    part(display, "MannequinPlinth", Vector3.new(3.8, 0.6, 3.8),
        Vector3.new(24, 0.3, 17.5), STEEL, Enum.Material.Metal, false)
    local mannequin = Instance.new("Model")
    mannequin.Name = "StarterOutfitMannequin"
    mannequin.Parent = display
    local body = Color3.fromRGB(29, 47, 50)
    local trousers = Color3.fromRGB(27, 31, 37)
    part(mannequin, "Torso", Vector3.new(1.7, 2.1, 0.8),
        Vector3.new(24, 4.3, 17.5), body, Enum.Material.Fabric, false)
    part(mannequin, "Head", Vector3.new(1.25, 1.25, 1.2),
        Vector3.new(24, 6.05, 17.5), Color3.fromRGB(62, 73, 72),
        Enum.Material.SmoothPlastic, false)
    for _, side in { -1, 1 } do
        part(mannequin, "Sleeve", Vector3.new(0.55, 1.9, 0.7),
            Vector3.new(24 + side * 1.18, 4.25, 17.5), body, Enum.Material.Fabric, false)
        part(mannequin, "Trouser", Vector3.new(0.7, 1.9, 0.75),
            Vector3.new(24 + side * 0.47, 2.35, 17.5), trousers, Enum.Material.Fabric, false)
    end
    part(mannequin, "Mask", Vector3.new(0.95, 0.38, 0.12),
        Vector3.new(24, 5.83, 16.84), Color3.fromRGB(33, 67, 69),
        Enum.Material.Fabric, false)
    local anchor = part(display, "WardrobePromptAnchor", Vector3.new(1, 1, 1),
        Vector3.new(24, 4, 20), STEEL, Enum.Material.SmoothPlastic, false)
    anchor.Transparency = 1
    anchor.CanQuery = false
    finishWardrobeDisplay(lobby, display)
end

local function configureLighting(model: Model)
    Lighting.ClockTime = 23
    Lighting.Brightness = 1.2
    Lighting.ExposureCompensation = -0.2
    Lighting.Ambient = Color3.fromRGB(58, 66, 75)
    Lighting.OutdoorAmbient = Color3.fromRGB(38, 47, 56)
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("PointLight") then
            if descendant.Parent.Name == "WarehouseLight" then
                descendant.Brightness = 1.25
                descendant.Range = 30
            elseif descendant.Parent.Name == "AlarmLight" then
                descendant.Brightness = 0.8
                descendant.Range = 12
            elseif descendant.Parent.Name == "DeploymentLight" then
                descendant.Brightness = 1.1
                descendant.Range = 14
            end
        end
    end
end

function LobbyWorld.Build(): Model
    local existing = workspace:FindFirstChild("HeistLobby")
    if existing and existing:IsA("Model") then
        addLoungeSeats(existing)
        AssetPlacement.Apply(existing)
        addWardrobeDisplay(existing)
        addDeploymentPrompt(existing)
        configureLighting(existing)
        return existing
    end
    for _, name in { "Baseplate", "SpawnLocation", "LobbyFloor", "LobbySpawn" } do
        local old = workspace:FindFirstChild(name)
        if old then old:Destroy() end
    end
    local model = Instance.new("Model")
    model.Name = "HeistLobby"
    model.Parent = workspace

    part(model, "ConcreteFloor", Vector3.new(92, 2, 76), Vector3.new(0, -1, 0),
        FLOOR, Enum.Material.Concrete)
    for x = -40, 40, 10 do
        part(model, "FloorSeam", Vector3.new(0.12, 0.03, 76),
            Vector3.new(x, 0.02, 0), WALL, Enum.Material.Metal, false)
    end
    for z = -30, 30, 10 do
        part(model, "FloorSeam", Vector3.new(92, 0.03, 0.12),
            Vector3.new(0, 0.02, z), WALL, Enum.Material.Metal, false)
    end
    part(model, "BackWall", Vector3.new(92, 19, 2), Vector3.new(0, 9.5, -37),
        WALL, Enum.Material.Brick)
    part(model, "LeftWall", Vector3.new(2, 19, 76), Vector3.new(-46, 9.5, 0),
        WALL, Enum.Material.Brick)
    part(model, "RightWall", Vector3.new(2, 19, 76), Vector3.new(46, 9.5, 0),
        WALL, Enum.Material.Brick)
    part(model, "FrontWall", Vector3.new(92, 19, 2), Vector3.new(0, 9.5, 37),
        WALL, Enum.Material.Brick)
    for _, x in { -42, -21, 0, 21, 42 } do
        part(model, "WallPillar", Vector3.new(2, 19, 2.5),
            Vector3.new(x, 9.5, -35.7), STEEL, Enum.Material.Metal)
    end
    for _, z in { -27, -9, 9, 27 } do
        for _, x in { -43, 43 } do
            part(model, "WallPillar", Vector3.new(2.5, 19, 2),
                Vector3.new(x, 9.5, z), STEEL, Enum.Material.Metal)
        end
    end
    for _, x in { -30, 0, 30 } do
        part(model, "CeilingBeam", Vector3.new(2, 1, 76),
            Vector3.new(x, 18.5, 0), STEEL, Enum.Material.Metal)
    end
    for _, z in { -20, 20 } do
        part(model, "CeilingBeam", Vector3.new(92, 1, 2),
            Vector3.new(0, 18.5, z), STEEL, Enum.Material.Metal)
    end
    part(model, "WarehouseRoof", Vector3.new(92, 2, 76),
        Vector3.new(0, 20, 0), FLOOR, Enum.Material.Metal)
    for _, x in { -25, 0, 25 } do
        for _, z in { -18, 14 } do
            local fixture = part(model, "WarehouseLight", Vector3.new(12, 0.35, 1.6),
                Vector3.new(x, 17.6, z), Color3.fromRGB(255, 228, 174),
                Enum.Material.Neon, false)
            local glow = Instance.new("PointLight")
            glow.Color = Color3.fromRGB(255, 225, 177)
            glow.Range = 42
            glow.Brightness = 3
            glow.Shadows = false
            glow.Parent = fixture
        end
    end

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "HeistSpawn"
    spawn.Size = Vector3.new(12, 0.5, 9)
    spawn.Position = Vector3.new(0, 0.25, 26)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Material = Enum.Material.Metal
    spawn.Color = STEEL
    spawn.Parent = model
    for _, x in { -5.5, 5.5 } do
        part(model, "SpawnTrim", Vector3.new(0.35, 0.07, 9),
            Vector3.new(x, 0.54, 26), TEAL, Enum.Material.Neon, false)
    end

    -- Central planning table and wall map establish the robbery theme.
    for _, x in { -6.5, 6.5 } do
        for _, z in { -1, 7 } do
            part(model, "PlanTableLeg", Vector3.new(0.8, 3, 0.8),
                Vector3.new(x, 1.5, z), STEEL, Enum.Material.Metal)
        end
    end
    part(model, "PlanningTable", Vector3.new(16, 0.6, 11),
        Vector3.new(0, 3.2, 3), Color3.fromRGB(70, 55, 43), Enum.Material.WoodPlanks)
    part(model, "Blueprint", Vector3.new(12, 0.05, 7),
        Vector3.new(0, 3.54, 3), Color3.fromRGB(23, 79, 91), Enum.Material.SmoothPlastic, false)
    for _, x in { -4, 0, 4 } do
        part(model, "BlueprintRoute", Vector3.new(0.12, 0.06, 5),
            Vector3.new(x, 3.59, 3), TEAL, Enum.Material.Neon, false)
    end
    for _, z in { 1, 5 } do
        part(model, "BlueprintRoute", Vector3.new(10, 0.06, 0.12),
            Vector3.new(0, 3.59, z), TEAL, Enum.Material.Neon, false)
    end
    sign(model, "MissionBoard", "STEAL ANYTHING!\nMUSEUM DISTRICT",
        Vector3.new(30, 5, 0.5), Vector3.new(0, 14, -33.9), TEAL)
    for _, x in { -39, 39 } do light(model, Vector3.new(x, 15, -35.8), RED) end

    -- The back-wall vault is a decorative deployment gate. The solid wall
    -- remains behind it so there is no route out of the waiting place.
    part(model, "VaultFrame", Vector3.new(18, 12, 1),
        Vector3.new(0, 6, -34.2), STEEL, Enum.Material.Metal)
    part(model, "VaultDoor", Vector3.new(14, 10, 1.2),
        Vector3.new(0, 6, -33.4), Color3.fromRGB(39, 49, 56), Enum.Material.Metal)
    for _, y in { 3.2, 6, 8.8 } do
        part(model, "VaultLockBar", Vector3.new(11.5, 0.45, 0.3),
            Vector3.new(0, y, -32.65), BRASS, Enum.Material.Metal)
    end
    for _, x in { -5.8, 5.8 } do
        part(model, "VaultHinge", Vector3.new(0.7, 7, 0.5),
            Vector3.new(x, 6, -32.6), STEEL, Enum.Material.Metal)
    end
    local gateLamp = part(model, "DeploymentLight", Vector3.new(3, 0.55, 0.6),
        Vector3.new(0, 12.5, -32.8), TEAL, Enum.Material.Neon, false)
    local gateGlow = Instance.new("PointLight")
    gateGlow.Color = TEAL
    gateGlow.Brightness = 1.5
    gateGlow.Range = 20
    gateGlow.Parent = gateLamp
    sign(model, "VaultLabel", "DEPLOY TO HEIST",
        Vector3.new(12, 1.5, 0.3), Vector3.new(0, 6, -32.3), TEAL)

    -- The armory and collection archive are visible previews. No purchase,
    -- equip, collectible grant, or inventory state is attached to them.
    for _, x in { -29, 29 } do
        part(model, "DisplayPlinth", Vector3.new(12, 3, 11),
            Vector3.new(x, 1.5, -15), STEEL, Enum.Material.Metal)
        part(model, "CaseGlassFront", Vector3.new(12, 5, 1),
            Vector3.new(x, 5, -9.5), Color3.fromRGB(124, 195, 190),
            Enum.Material.Glass).Transparency = 0.55
        part(model, "CaseGlassBack", Vector3.new(12, 5, 1),
            Vector3.new(x, 5, -20.5), Color3.fromRGB(124, 195, 190),
            Enum.Material.Glass).Transparency = 0.55
        for _, side in { -5.5, 5.5 } do
            part(model, "CaseGlassSide", Vector3.new(1, 5, 12),
                Vector3.new(x + side, 5, -15), Color3.fromRGB(124, 195, 190),
                Enum.Material.Glass).Transparency = 0.55
        end
        part(model, "CaseTop", Vector3.new(12, 0.5, 11),
            Vector3.new(x, 7.75, -15), BRASS, Enum.Material.Metal)
        if x < 0 then
            part(model, "ToolStand", Vector3.new(7, 0.35, 4),
                Vector3.new(x, 3.2, -15), Color3.fromRGB(22, 32, 38), Enum.Material.Metal)
            part(model, "ScannerBody", Vector3.new(3.4, 1, 2),
                Vector3.new(x, 4, -15), STEEL, Enum.Material.Metal)
            part(model, "ScannerScreen", Vector3.new(2.6, 0.1, 1.4),
                Vector3.new(x, 4.56, -15), TEAL, Enum.Material.Neon, false)
            for _, offset in { -2.5, 2.5 } do
                part(model, "ToolGrip", Vector3.new(0.6, 2, 0.6),
                    Vector3.new(x + offset, 4.2, -15), BRASS, Enum.Material.Metal)
            end
        else
            part(model, "ArtifactBase", Vector3.new(6, 0.55, 4),
                Vector3.new(x, 3.3, -15), BRASS, Enum.Material.Metal)
            part(model, "OriginalArtwork", Vector3.new(4.3, 3.2, 0.3),
                Vector3.new(x, 5.1, -15), Color3.fromRGB(21, 61, 73), Enum.Material.SmoothPlastic)
            for _, offset in { -1.2, 0, 1.2 } do
                part(model, "ArtworkMotif", Vector3.new(0.5, 1.3 + math.abs(offset), 0.08),
                    Vector3.new(x + offset, 5.1, -14.8), BRASS, Enum.Material.Metal, false)
            end
        end
    end
    sign(model, "ArmorySign", "BLACK MARKET\nCOMING LATER",
        Vector3.new(17, 3.7, 0.4), Vector3.new(-29, 11, -23), BRASS)
    sign(model, "VaultSign", "COLLECTOR VAULT\nCOMING LATER",
        Vector3.new(17, 3.7, 0.4), Vector3.new(29, 11, -23), BRASS)

    -- A small crew lounge and equipment locker make the room read as a lived-in
    -- hideout. They remain clear of the center route from spawn to planning.
    part(model, "LoungeRug", Vector3.new(19, 0.05, 12),
        Vector3.new(-26, 0.06, 18), Color3.fromRGB(39, 71, 74),
        Enum.Material.Fabric, false)
    part(model, "CouchSeat", Vector3.new(13, 1.5, 4),
        Vector3.new(-26, 1.4, 22), Color3.fromRGB(72, 91, 92), Enum.Material.Fabric)
    addLoungeSeats(model)
    part(model, "CouchBack", Vector3.new(13, 3, 1.2),
        Vector3.new(-26, 2.3, 24.4), Color3.fromRGB(54, 74, 75), Enum.Material.Fabric)
    for _, x in { -33, -19 } do
        part(model, "CouchArm", Vector3.new(1.1, 2.2, 5),
            Vector3.new(x, 1.8, 22), Color3.fromRGB(54, 74, 75), Enum.Material.Fabric)
    end
    part(model, "LoungeTable", Vector3.new(8, 0.6, 3.5),
        Vector3.new(-26, 1.6, 14), Color3.fromRGB(73, 57, 42), Enum.Material.WoodPlanks)
    for _, x in { -29, -23 } do
        part(model, "LoungeTableLeg", Vector3.new(0.7, 1.3, 0.7),
            Vector3.new(x, 0.7, 14), STEEL, Enum.Material.Metal)
    end
    sign(model, "LoungeNotice", "CREW LOUNGE\nPLAN • INVITE • DEPLOY",
        Vector3.new(16, 3.5, 0.4), Vector3.new(-26, 10, 34.8), TEAL,
        Enum.NormalId.Front)
    for _, x in { 18, 24, 30 } do
        part(model, "Locker", Vector3.new(5, 9, 3),
            Vector3.new(x, 4.5, 25), Color3.fromRGB(52, 66, 72), Enum.Material.Metal)
        part(model, "LockerDoor", Vector3.new(4.4, 7.5, 0.15),
            Vector3.new(x, 4.6, 23.4), STEEL, Enum.Material.Metal)
        part(model, "LockerHandle", Vector3.new(0.3, 1.4, 0.3),
            Vector3.new(x + 1.5, 4.5, 23.2), BRASS, Enum.Material.Metal)
    end
    sign(model, "LockerSign", "ROBBER WARDROBE\nTRY ON + EQUIP",
        Vector3.new(16, 3.5, 0.4), Vector3.new(24, 10, 34.8), TEAL,
        Enum.NormalId.Front)
    for _, x in { -39, 39 } do
        for _, z in { -1, 10 } do
            part(model, "SupplyCrate", Vector3.new(4, 3, 4),
                Vector3.new(x, 1.5, z), Color3.fromRGB(81, 62, 45), Enum.Material.WoodPlanks)
            part(model, "CrateBand", Vector3.new(4.1, 0.3, 4.1),
                Vector3.new(x, 2.5, z), STEEL, Enum.Material.Metal)
        end
    end

    AssetPlacement.Apply(model)
    addWardrobeDisplay(model)
    addDeploymentPrompt(model)
    configureLighting(model)
    return model
end

return table.freeze(LobbyWorld)
