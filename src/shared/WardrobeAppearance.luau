--!strict

local TweenService = game:GetService("TweenService")

local WardrobeAppearance = {}
local FOLDER_NAME = "RobberWardrobeVisuals"

local OUTFITS = {
    starter_outfit = { jacket = Color3.fromRGB(30, 55, 51), trim = Color3.fromRGB(70, 190, 158), trousers = Color3.fromRGB(25, 30, 31) },
    classic_outfit = { jacket = Color3.fromRGB(28, 29, 32), trim = Color3.fromRGB(213, 210, 192), trousers = Color3.fromRGB(23, 25, 28) },
    street_outfit = { jacket = Color3.fromRGB(39, 53, 92), trim = Color3.fromRGB(245, 152, 68), trousers = Color3.fromRGB(23, 30, 52) },
    tactical_outfit = { jacket = Color3.fromRGB(33, 40, 39), trim = Color3.fromRGB(177, 149, 83), trousers = Color3.fromRGB(22, 29, 29) },
    neon_phantom_outfit = { jacket = Color3.fromRGB(12, 26, 32), trim = Color3.fromRGB(27, 238, 223), trousers = Color3.fromRGB(10, 20, 27) },
    shadow_king_outfit = { jacket = Color3.fromRGB(24, 19, 35), trim = Color3.fromRGB(165, 83, 224), trousers = Color3.fromRGB(15, 13, 24) },
    legendary_animated_outfit = { jacket = Color3.fromRGB(174, 126, 43), trim = Color3.fromRGB(255, 219, 104), trousers = Color3.fromRGB(25, 27, 38) },
}

local function fitted(character: Model, folder: Folder, bodyName: string, name: string,
    relative: CFrame, size: Vector3, color: Color3, material: Enum.Material)
    local body = character:FindFirstChild(bodyName)
    if body == nil or not body:IsA("BasePart") then return end
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.CastShadow = false
    part.CFrame = body.CFrame * relative
    part.Parent = folder
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = body
    weld.Part1 = part
    weld.Parent = part
    return part
end

local function garment(character: Model, folder: Folder, bodyName: string, name: string,
    color: Color3, extra: Vector3, rounded: boolean?)
    local body = character:FindFirstChild(bodyName)
    if body == nil or not body:IsA("BasePart") then return end
    if bodyName:find("Arm") or bodyName:find("Leg") then
        local diameter = math.max(body.Size.X + extra.X, body.Size.Z + extra.Z) * 1.3
        local roundSleeve = rounded and bodyName:find("Arm") ~= nil
        local sleeve = fitted(character, folder, bodyName, name,
            if roundSleeve then CFrame.identity else CFrame.Angles(0, 0, math.pi / 2),
            if roundSleeve then Vector3.new(diameter, body.Size.Y + extra.Y + 0.2, diameter)
            else Vector3.new(body.Size.Y + extra.Y, diameter, diameter), color, Enum.Material.Fabric)
        if sleeve then sleeve.Shape = if roundSleeve then Enum.PartType.Ball else Enum.PartType.Cylinder end
    else
        local jacket = fitted(character, folder, bodyName, name, CFrame.identity,
            body.Size + extra, color, Enum.Material.Fabric)
        if jacket and rounded then jacket.Shape = Enum.PartType.Ball end
    end
end

local function torsoPart(character: Model): BasePart?
    local part = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    return if part and part:IsA("BasePart") then part else nil
end

local function piece(character: Model, folder: Folder, body: BasePart, name: string,
    position: Vector3, size: Vector3, color: Color3, material: Enum.Material,
    rotation: CFrame?)
    return fitted(character, folder, body.Name, name,
        CFrame.new(position) * (rotation or CFrame.identity), size, color, material)
end

local function angular(character: Model, folder: Folder, body: BasePart, name: string,
    position: Vector3, size: Vector3, color: Color3, material: Enum.Material, rotation: CFrame?)
    local part = Instance.new("WedgePart")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.CastShadow = false
    part.CFrame = body.CFrame * CFrame.new(position) * (rotation or CFrame.identity)
    part.Parent = folder
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = body
    weld.Part1 = part
    weld.Parent = part
    return part
end

local function importedPart(folder: Folder, body: BasePart, assetName: string, name: string,
    relative: CFrame): BasePart?
    local assets = script.Parent:FindFirstChild("WardrobeAssets")
    local template = assets and assets:FindFirstChild(assetName)
    if not template or not template:IsA("BasePart") then return nil end
    local part = template:Clone()
    part.Name = name
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.Anchored = false
    part.CFrame = body.CFrame * relative
    part.Parent = folder
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = body
    weld.Part1 = part
    weld.Parent = part
    return part
end

local function hood(character: Model, folder: Folder, color: Color3, masked: boolean)
    if masked then return end
    local head = character:FindFirstChild("Head")
    if head == nil or not head:IsA("BasePart") then return end
    local cloth = importedPart(folder, head, "Hood", "Hood", CFrame.identity)
    if cloth and cloth:IsA("MeshPart") then
        cloth.Size = Vector3.new(1.43778 * head.Size.X / 1.159,
            1.51384 * head.Size.Y / 1.182, 1.5599 * head.Size.Z / 1.161)
        cloth.Color = color
        cloth.Material = Enum.Material.Fabric
        cloth.TextureID = ""
    end
end

local function gloves(character: Model, folder: Folder, color: Color3)
    local seam = Color3.fromRGB(69, 72, 72)
    for _, name in { "LeftHand", "RightHand", "Left Arm", "Right Arm" } do
        local hand = character:FindFirstChild(name)
        if hand and hand:IsA("BasePart") then
            local r6 = name:find(" Arm") ~= nil
            local y = if r6 then -hand.Size.Y * 0.43 else 0
            local glove = piece(character, folder, hand, "LeatherGlove", Vector3.new(0, y, 0),
                if r6 then Vector3.new(hand.Size.X * 1.04, hand.Size.Y * 0.28, hand.Size.Z * 1.06)
                else hand.Size + Vector3.new(0.07, 0.05, 0.07), color, Enum.Material.Fabric)
            if glove then glove.Shape = Enum.PartType.Ball end
            local knuckle = piece(character, folder, hand, "GloveKnucklePanel",
                Vector3.new(0, y + (if r6 then 0 else hand.Size.Y * 0.1), -hand.Size.Z * 0.49),
                Vector3.new(hand.Size.X * 0.74, if r6 then 0.12 else hand.Size.Y * 0.3, 0.055),
                Color3.fromRGB(32, 35, 37), Enum.Material.Fabric)
            if knuckle then knuckle.Shape = Enum.PartType.Ball end
            for _, x in { -0.24, 0.24 } do
                piece(character, folder, hand, "GloveStitch", Vector3.new(x * hand.Size.X, y,
                    -hand.Size.Z * 0.53), Vector3.new(0.025, 0.13, 0.026), seam, Enum.Material.Fabric)
            end
        end
    end
    for _, name in { "LeftLowerArm", "RightLowerArm" } do
        local arm = character:FindFirstChild(name)
        if arm and arm:IsA("BasePart") then
            local cuff = piece(character, folder, arm, "GloveCuff",
                Vector3.new(0, -arm.Size.Y * 0.43, 0),
                Vector3.new(arm.Size.X * 1.1, 0.15, arm.Size.Z * 1.1), color, Enum.Material.Fabric)
            if cuff then cuff.Shape = Enum.PartType.Cylinder end
        end
    end
end

local function shoulder(character: Model, folder: Folder, color: Color3,
    material: Enum.Material, size: Vector3)
    for _, name in { "LeftUpperArm", "RightUpperArm", "Left Arm", "Right Arm" } do
        local arm = character:FindFirstChild(name)
        if arm and arm:IsA("BasePart") then
            piece(character, folder, arm, "ShoulderLayer", Vector3.new(0, arm.Size.Y * 0.35, 0),
                size, color, material)
        end
    end
end

local function outfit(character: Model, folder: Folder, id: string, masked: boolean)
    local colors = OUTFITS[id]
    if colors == nil then return end
    local bulky = id == "street_outfit" or id == "tactical_outfit" or id == "shadow_king_outfit"
    for _, name in { "UpperTorso", "LowerTorso", "Torso" } do
        garment(character, folder, name, "Jacket_" .. name, colors.jacket,
            if bulky then Vector3.new(0.3, 0.17, 0.31) else Vector3.new(0.16, 0.12, 0.18),
            id == "starter_outfit" or id == "classic_outfit" or id == "street_outfit"
                or id == "neon_phantom_outfit")
    end
    for _, name in { "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
        "Left Arm", "Right Arm" } do
        garment(character, folder, name, "Sleeve_" .. name, colors.jacket,
            if bulky then Vector3.new(0.26, 0.07, 0.26) else Vector3.new(0.11, 0.03, 0.11),
            id == "street_outfit")
    end
    for _, name in { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
        "Left Leg", "Right Leg" } do
        garment(character, folder, name, "Trouser_" .. name, colors.trousers,
            Vector3.new(0.09, 0.02, 0.09))
    end
    local torso = torsoPart(character)
    if torso == nil then return end
    local front = -torso.Size.Z / 2 - (if bulky then 0.18 else 0.11)
    local back = torso.Size.Z / 2 + (if bulky then 0.18 else 0.11)

    if id == "starter_outfit" then
        hood(character, folder, colors.jacket, masked)
        piece(character, folder, torso, "HoodiePocket", Vector3.new(0, -torso.Size.Y * 0.24, front - 0.04),
            Vector3.new(torso.Size.X * 0.65, torso.Size.Y * 0.31, 0.08), colors.trousers, Enum.Material.Fabric)
        for _, x in { -0.16, 0.16 } do
            piece(character, folder, torso, "HoodCord", Vector3.new(x, torso.Size.Y * 0.19, front - 0.09),
                Vector3.new(0.045, torso.Size.Y * 0.4, 0.04), colors.trim, Enum.Material.Fabric)
        end
    elseif id == "classic_outfit" then
        gloves(character, folder, Color3.fromRGB(19, 21, 23))
        for _, y in { -0.29, 0.01, 0.31 } do
            piece(character, folder, torso, "PulloverStripe", Vector3.new(0, y, front - 0.03),
                Vector3.new(torso.Size.X * 0.91, 0.105, 0.05), colors.trim, Enum.Material.Fabric)
            piece(character, folder, torso, "BackStripe", Vector3.new(0, y, back + 0.03),
                Vector3.new(torso.Size.X * 0.91, 0.105, 0.05), colors.trim, Enum.Material.Fabric)
        end
        local head = character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            local cap = piece(character, folder, head, "KnitCap", Vector3.new(0, head.Size.Y * 0.45, 0),
                Vector3.new(head.Size.X * 1.08, head.Size.Y * 0.48, head.Size.Z * 1.08), colors.jacket, Enum.Material.Fabric)
            if cap then cap.Shape = Enum.PartType.Ball end
            piece(character, folder, head, "CapRib", Vector3.new(0, head.Size.Y * 0.36, -head.Size.Z * 0.48),
                Vector3.new(head.Size.X * 1.07, 0.11, 0.08), colors.trim, Enum.Material.Fabric)
        end
        piece(character, folder, torso, "CanvasBelt", Vector3.new(0, -torso.Size.Y * 0.5, 0),
            Vector3.new(torso.Size.X * 1.06, 0.14, torso.Size.Z * 1.08), colors.trim, Enum.Material.Fabric)
    elseif id == "street_outfit" then
        for _, name in { "LeftUpperArm", "RightUpperArm", "Left Arm", "Right Arm" } do
            local arm = character:FindFirstChild(name)
            if arm and arm:IsA("BasePart") then
                local pad = piece(character, folder, arm, "BomberShoulder",
                    Vector3.new(0, arm.Size.Y * 0.35, 0),
                    Vector3.new(arm.Size.X * 1.1, arm.Size.Y * 0.42, arm.Size.Z * 1.12),
                    colors.jacket, Enum.Material.Fabric)
                if pad then pad.Shape = Enum.PartType.Ball end
            end
        end
        for _, x in { -1, 1 } do
            local collar = piece(character, folder, torso, "BomberCollar",
                Vector3.new(x * torso.Size.X * 0.31, torso.Size.Y * 0.43, front - 0.02),
                Vector3.new(torso.Size.X * 0.4, 0.28, 0.24), colors.trim, Enum.Material.Fabric)
            if collar then collar.Shape = Enum.PartType.Ball end
        end
        for _, x in { -0.37, 0.37 } do
            local panel = piece(character, folder, torso, "OpenJacketFront", Vector3.new(x, 0, front - 0.07),
                Vector3.new(torso.Size.X * 0.34, torso.Size.Y * 0.82, 0.16), colors.jacket, Enum.Material.Fabric)
            if panel then panel.Shape = Enum.PartType.Ball end
            piece(character, folder, torso, "JacketEdge", Vector3.new(x * 0.46, 0, front - 0.17),
                Vector3.new(0.07, torso.Size.Y * 0.76, 0.06), colors.trim, Enum.Material.Fabric)
        end
        piece(character, folder, torso, "CrossbodyStrap", Vector3.new(0, 0.02, front - 0.22),
            Vector3.new(0.12, torso.Size.Y * 1.18, 0.045), Color3.fromRGB(31, 35, 45), Enum.Material.Fabric,
            CFrame.Angles(0, 0, -0.55))
        local pouch = piece(character, folder, torso, "CrossbodyPouch",
            Vector3.new(-torso.Size.X * 0.3, -torso.Size.Y * 0.32, front - 0.31),
            Vector3.new(torso.Size.X * 0.52, torso.Size.Y * 0.38, 0.35),
            Color3.fromRGB(50, 57, 69), Enum.Material.Fabric)
        if pouch then pouch.Shape = Enum.PartType.Ball end
        local flap = piece(character, folder, torso, "PouchFlap",
            Vector3.new(-torso.Size.X * 0.3, -torso.Size.Y * 0.2, front - 0.49),
            Vector3.new(torso.Size.X * 0.4, 0.13, 0.07), colors.trim, Enum.Material.Fabric)
        if flap then flap.Shape = Enum.PartType.Ball end
    elseif id == "tactical_outfit" then
        local armor = Color3.fromRGB(48, 58, 57)
        local armorEdge = Color3.fromRGB(117, 127, 109)
        piece(character, folder, torso, "ArmoredVest", Vector3.new(0, 0.02, front - 0.13),
            Vector3.new(torso.Size.X * 0.94, torso.Size.Y * 0.83, 0.24), armor, Enum.Material.Metal)
        for _, x in { -1, 1 } do
            angular(character, folder, torso, "VestChestPlate",
                Vector3.new(x * torso.Size.X * 0.22, torso.Size.Y * 0.18, front - 0.3),
                Vector3.new(torso.Size.X * 0.39, torso.Size.Y * 0.31, 0.11), armorEdge,
                Enum.Material.Metal, CFrame.Angles(0, x * 0.12, 0))
            piece(character, folder, torso, "VestHarness",
                Vector3.new(x * torso.Size.X * 0.34, torso.Size.Y * 0.16, front - 0.36),
                Vector3.new(0.11, torso.Size.Y * 0.62, 0.07), colors.trousers, Enum.Material.Fabric)
            piece(character, folder, torso, "BeltPouch",
                Vector3.new(x * torso.Size.X * 0.37, -torso.Size.Y * 0.48, front - 0.2),
                Vector3.new(torso.Size.X * 0.23, 0.28, 0.28), armor, Enum.Material.Fabric)
        end
        piece(character, folder, torso, "VestCenterPlate", Vector3.new(0, -torso.Size.Y * 0.15, front - 0.3),
            Vector3.new(torso.Size.X * 0.55, torso.Size.Y * 0.26, 0.12), armorEdge, Enum.Material.Metal)
        for _, name in { "LeftUpperArm", "RightUpperArm", "Left Arm", "Right Arm" } do
            local arm = character:FindFirstChild(name)
            if arm and arm:IsA("BasePart") then
                angular(character, folder, arm, "TacticalShoulderPlate",
                    Vector3.new(0, arm.Size.Y * 0.36, -arm.Size.Z * 0.1),
                    Vector3.new(arm.Size.X * 1.32, 0.25, arm.Size.Z * 1.28), armorEdge, Enum.Material.Metal)
            end
        end
        piece(character, folder, torso, "UtilityBelt", Vector3.new(0, -torso.Size.Y * 0.49, 0),
            Vector3.new(torso.Size.X * 1.12, 0.19, torso.Size.Z * 1.19), colors.trousers, Enum.Material.Fabric)
        piece(character, folder, torso, "BeltBuckle", Vector3.new(0, -torso.Size.Y * 0.49, front - 0.22),
            Vector3.new(0.28, 0.18, 0.09), colors.trim, Enum.Material.Metal)
        for _, name in { "LeftLowerLeg", "RightLowerLeg", "Left Leg", "Right Leg" } do
            local leg = character:FindFirstChild(name)
            if leg and leg:IsA("BasePart") then
                angular(character, folder, leg, "KneeGuard", Vector3.new(0, leg.Size.Y * 0.28, -leg.Size.Z * 0.62),
                    Vector3.new(leg.Size.X * 0.86, 0.38, 0.19), armorEdge, Enum.Material.Metal)
            end
        end
    elseif id == "neon_phantom_outfit" then
        hood(character, folder, colors.jacket, masked)
        for _, x in { -1, 1 } do
            piece(character, folder, torso, "CoatTail", Vector3.new(x * torso.Size.X * 0.28, -torso.Size.Y * 0.92, back + 0.07),
                Vector3.new(torso.Size.X * 0.43, torso.Size.Y * 0.94, 0.14), colors.jacket, Enum.Material.Fabric)
            piece(character, folder, torso, "NeonFrontSeam",
                Vector3.new(x * torso.Size.X * 0.25, torso.Size.Y * 0.08, front - 0.06),
                Vector3.new(0.055, torso.Size.Y * 0.64, 0.05), colors.trim, Enum.Material.Neon,
                CFrame.Angles(0, 0, x * 0.24))
        end
        for _, name in { "LeftUpperArm", "RightUpperArm", "Left Arm", "Right Arm" } do
            local arm = character:FindFirstChild(name)
            if arm and arm:IsA("BasePart") then
                local seam = piece(character, folder, arm, "NeonSleeveSeam",
                    Vector3.new(0, 0, -arm.Size.Z * 0.58),
                    Vector3.new(0.045, arm.Size.Y * 0.68, 0.04), colors.trim, Enum.Material.Neon)
                if seam then seam.Transparency = 0.18 end
            end
        end
        local emblem = piece(character, folder, torso, "PhantomEmblem", Vector3.new(0, 0.17, front - 0.09),
            Vector3.new(0.18, 0.25, 0.06), colors.trim, Enum.Material.Neon)
        if emblem then emblem.Shape = Enum.PartType.Ball end
    elseif id == "shadow_king_outfit" then
        local royalIron = Color3.fromRGB(35, 39, 48)
        local royalEdge = Color3.fromRGB(74, 83, 98)
        local cape = importedPart(folder, torso, "Cape", "RoyalCape",
            CFrame.new(0, -torso.Size.Y * 0.5 - 0.2, torso.Size.Z * 0.5))
        if cape then
            cape.Color = Color3.fromRGB(65, 36, 92)
            cape.Material = Enum.Material.Fabric
            cape.Size = Vector3.new(torso.Size.X * 2.1, torso.Size.Y * 2.4, torso.Size.Z * 3)
        end
        for _, x in { -1, 1 } do
            angular(character, folder, torso, "RoyalShoulderArmor",
                Vector3.new(x * torso.Size.X * 0.46, torso.Size.Y * 0.4, front * 0.2),
                Vector3.new(torso.Size.X * 0.42, 0.31, torso.Size.Z * 1.12), royalEdge,
                Enum.Material.Metal, CFrame.Angles(0, 0, x * 0.12))
            piece(character, folder, torso, "RoyalClasp", Vector3.new(x * torso.Size.X * 0.31,
                torso.Size.Y * 0.36, front - 0.3), Vector3.new(0.18, 0.18, 0.09),
                colors.trim, Enum.Material.Metal)
        end
        piece(character, folder, torso, "RoyalBreastplate", Vector3.new(0, 0.07, front - 0.22),
            Vector3.new(torso.Size.X * 0.82, torso.Size.Y * 0.72, 0.22), royalIron, Enum.Material.Metal)
        for _, x in { -1, 1 } do
            angular(character, folder, torso, "RoyalBreastplateFacet",
                Vector3.new(x * torso.Size.X * 0.2, 0.09, front - 0.35),
                Vector3.new(torso.Size.X * 0.37, torso.Size.Y * 0.53, 0.09), royalEdge,
                Enum.Material.Metal, CFrame.Angles(0, x * 0.1, 0))
        end
        piece(character, folder, torso, "RoyalCrest", Vector3.new(0, 0.18, front - 0.47),
            Vector3.new(0.18, 0.3, 0.06), colors.trim, Enum.Material.Neon)
        local head = character:FindFirstChild("Head")
        if head and head:IsA("BasePart") and not masked then
            local crown = importedPart(folder, head, "Crown", "RoyalCrown",
                CFrame.new(0, head.Size.Y * 0.52, 0))
            if crown and crown:IsA("MeshPart") then
                crown.Size = Vector3.new(1.30842 * head.Size.X / 1.159,
                    0.67318 * head.Size.Y / 1.182, 1.30842 * head.Size.Z / 1.161)
                crown.TextureID = ""
                crown.Color = Color3.fromRGB(140, 77, 194)
                crown.Material = Enum.Material.Metal
            end
        end
    elseif id == "legendary_animated_outfit" then
        local midnight = Color3.fromRGB(24, 28, 43)
        local deepGold = Color3.fromRGB(104, 69, 23)
        for _, x in { -1, 1 } do
            angular(character, folder, torso, "LongGoldCoatTail",
                Vector3.new(x * torso.Size.X * 0.3, -torso.Size.Y * 1.05, back + 0.14),
                Vector3.new(torso.Size.X * 0.54, torso.Size.Y * 1.2, 0.18), colors.jacket,
                Enum.Material.Fabric, CFrame.Angles(0, 0, -x * 0.07))
            angular(character, folder, torso, "GoldFrontCoatTail",
                Vector3.new(x * torso.Size.X * 0.36, -torso.Size.Y * 0.85, front - 0.03),
                Vector3.new(0.13, torso.Size.Y * 0.92, torso.Size.X * 0.38),
                colors.jacket, Enum.Material.Fabric, CFrame.Angles(0, x * math.pi / 2, 0))
            angular(character, folder, torso, "GoldLapel",
                Vector3.new(x * torso.Size.X * 0.21, torso.Size.Y * 0.17, front - 0.19),
                Vector3.new(torso.Size.X * 0.31, torso.Size.Y * 0.66, 0.12), colors.trim,
                Enum.Material.Metal, CFrame.Angles(0, 0, x * 0.28))
            piece(character, folder, torso, "GoldEpaulet",
                Vector3.new(x * torso.Size.X * 0.45, torso.Size.Y * 0.44, 0),
                Vector3.new(torso.Size.X * 0.43, 0.17, torso.Size.Z * 0.9),
                deepGold, Enum.Material.Metal)
            piece(character, folder, torso, "CoatChain",
                Vector3.new(x * torso.Size.X * 0.22, -torso.Size.Y * 0.08, front - 0.29),
                Vector3.new(0.035, torso.Size.Y * 0.35, 0.035), colors.trim,
                Enum.Material.Metal, CFrame.Angles(0, 0, x * 0.43))
        end
        piece(character, folder, torso, "MidnightWaistcoat", Vector3.new(0, 0, front - 0.13),
            Vector3.new(torso.Size.X * 0.59, torso.Size.Y * 0.73, 0.12), midnight, Enum.Material.Fabric)
        local crest = piece(character, folder, torso, "LegendaryCrest",
            Vector3.new(0, torso.Size.Y * 0.21, front - 0.29),
            Vector3.new(0.3, 0.36, 0.1), colors.trim, Enum.Material.Neon)
        if crest then crest.Shape = Enum.PartType.Ball end
        piece(character, folder, torso, "GoldBelt", Vector3.new(0, -torso.Size.Y * 0.48, 0),
            Vector3.new(torso.Size.X * 1.04, 0.13, torso.Size.Z * 1.08), deepGold, Enum.Material.Metal)
        for _, name in { "LeftLowerArm", "RightLowerArm", "Left Arm", "Right Arm" } do
            local arm = character:FindFirstChild(name)
            if arm and arm:IsA("BasePart") then
                local cuff = piece(character, folder, arm, "GoldCuff",
                    Vector3.new(0, -arm.Size.Y * 0.38, 0),
                    Vector3.new(arm.Size.X * 1.15, 0.13, arm.Size.Z * 1.15),
                    colors.trim, Enum.Material.Metal)
                if cuff then cuff.Shape = Enum.PartType.Cylinder end
            end
        end
        local head = character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            local brim = piece(character, folder, head, "LegendaryBrim",
                Vector3.new(0, head.Size.Y * 0.53, 0),
                Vector3.new(0.13, head.Size.X * 1.53, head.Size.Z * 1.53),
                midnight, Enum.Material.Fabric, CFrame.Angles(0, 0, math.pi / 2))
            if brim then brim.Shape = Enum.PartType.Cylinder end
            local crown = piece(character, folder, head, "LegendaryHatCrown",
                Vector3.new(0, head.Size.Y * 0.76, head.Size.Z * 0.05),
                Vector3.new(head.Size.X * 0.85, head.Size.Y * 0.5, head.Size.Z * 0.83),
                midnight, Enum.Material.Fabric)
            if crown then crown.Shape = Enum.PartType.Ball end
            piece(character, folder, head, "LegendaryHatBand",
                Vector3.new(0, head.Size.Y * 0.65, -head.Size.Z * 0.42),
                Vector3.new(head.Size.X * 0.78, 0.08, 0.06), colors.trim, Enum.Material.Metal)
        end
        local attachment = Instance.new("Attachment")
        attachment.Name = "LegendarySparkAttachment"
        attachment.Parent = torso
        attachment.Position = Vector3.new(0, torso.Size.Y * 0.2, front - 0.4)
        local light = Instance.new("PointLight")
        light.Name = "LegendaryWarmGlow"
        light.Color = colors.trim
        light.Brightness = 1.5
        light.Range = 9
        light.Parent = attachment
        local particles = Instance.new("ParticleEmitter")
        particles.Name = "LegendarySparks"
        particles.Rate = 13
        particles.Lifetime = NumberRange.new(0.5, 1.1)
        particles.Speed = NumberRange.new(0.3, 0.8)
        particles.LightEmission = 1
        particles.Color = ColorSequence.new(colors.trim)
        particles.Size = NumberSequence.new(0.12)
        particles.Parent = attachment
        local marker = Instance.new("ObjectValue")
        marker.Name = "LegendarySparkAttachment"
        marker.Value = attachment
        marker.Parent = folder
    end
end

local function coverHair(character: Model, folder: Folder, coverHead: boolean)
    local hidden = Instance.new("Folder")
    hidden.Name = "HiddenHair"
    hidden.Parent = folder
    local function hide(target: Instance)
        local visual = target :: any
        local record = Instance.new("ObjectValue")
        record.Name = "CoveredAvatarPart"
        record.Value = target
        record:SetAttribute("OriginalTransparency", visual.Transparency)
        record.Parent = hidden
        visual.Transparency = 1
    end
    local head = character:FindFirstChild("Head")
    if coverHead and head and head:IsA("BasePart") then
        hide(head)
        for _, child in head:GetChildren() do
            if child:IsA("Decal") then hide(child) end
        end
    end
    -- With the ski mask on, the balaclava is the only thing worn on the head.
    local headTypes = {
        [Enum.AccessoryType.Hat] = true, [Enum.AccessoryType.Face] = true,
        [Enum.AccessoryType.Neck] = true, [Enum.AccessoryType.Eyebrow] = true,
        [Enum.AccessoryType.Eyelash] = true,
    }
    local function onHead(accessory: Accessory): boolean
        if headTypes[accessory.AccessoryType] then return true end
        local handle = accessory:FindFirstChild("Handle")
        local weld = handle and handle:FindFirstChildWhichIsA("Weld")
        return weld ~= nil and (weld.Part0 == head or weld.Part1 == head)
    end
    for _, accessory in character:GetChildren() do
        if accessory:IsA("Accessory") and (accessory.AccessoryType == Enum.AccessoryType.Hair
            or (coverHead and onHead(accessory))) then
            for _, part in accessory:GetDescendants() do
                if part:IsA("BasePart") then hide(part) end
            end
        end
    end
end

local function mask(character: Model, folder: Folder, id: string)
    local head = character:FindFirstChild("Head")
    if head == nil or not head:IsA("BasePart") then return end
    local black = Color3.fromRGB(20, 24, 27)
    local cloth = if id == "starter_mask" then Color3.fromRGB(33, 67, 69) else black
    if id == "starter_mask" then
        local frontZ = -head.Size.Z * 0.56
        for _, x in { -1, 1 } do
            angular(character, folder, head, "BandanaTriangle",
                Vector3.new(x * head.Size.X * 0.23, -head.Size.Y * 0.27, frontZ),
                Vector3.new(0.11, head.Size.Y * 0.47, head.Size.X * 0.48),
                cloth, Enum.Material.Fabric, CFrame.Angles(0, x * math.pi / 2, 0))
            piece(character, folder, head, "BandanaTie",
                Vector3.new(x * head.Size.X * 0.51, -head.Size.Y * 0.15, head.Size.Z * 0.08),
                Vector3.new(0.09, head.Size.Y * 0.22, head.Size.Z * 0.3),
                cloth, Enum.Material.Fabric, CFrame.Angles(0, 0, x * 0.28))
        end
        piece(character, folder, head, "BandanaTopFold",
            Vector3.new(0, -head.Size.Y * 0.08, frontZ - 0.04),
            Vector3.new(head.Size.X * 0.96, 0.07, 0.07), Color3.fromRGB(81, 146, 135),
            Enum.Material.Fabric)
    elseif id == "ski_mask" then
        -- Full balaclava silhouette. The two eye openings make it distinct from the free bandana.
        local shell = fitted(character, folder, "Head", "BalaclavaShell", CFrame.identity,
            head.Size + Vector3.new(0.16, 0.19, 0.16), black, Enum.Material.Fabric)
        if shell then
            local headMesh = Instance.new("SpecialMesh")
            headMesh.MeshType = Enum.MeshType.Head
            headMesh.Scale = Vector3.new(1.12, 1.14, 1.13)
            headMesh.Parent = shell
        end
        local gaiter = fitted(character, folder, "Head", "BalaclavaNeck",
            CFrame.new(0, -head.Size.Y * 0.42, 0),
            Vector3.new(head.Size.X * 0.7, 0.28, head.Size.Z * 0.96), black, Enum.Material.Fabric)
        if gaiter then gaiter.Shape = Enum.PartType.Cylinder end
        local faceZ = -head.Size.Z / 2 - 0.17
        for _, x in { -0.24, 0.24 } do
            local opening = fitted(character, folder, "Head", "EyeOpening",
                CFrame.new(x, head.Size.Y * 0.1, faceZ),
                Vector3.new(head.Size.X * 0.22, head.Size.Y * 0.17, 0.07),
                Color3.fromRGB(5, 7, 8), Enum.Material.SmoothPlastic)
            if opening then opening.Shape = Enum.PartType.Ball end
            local visibleSkin = fitted(character, folder, "Head", "SkinAtEye",
                CFrame.new(x, head.Size.Y * 0.085, faceZ - 0.055),
                Vector3.new(head.Size.X * 0.12, head.Size.Y * 0.065, 0.035),
                head.Color, Enum.Material.SmoothPlastic)
            if visibleSkin then visibleSkin.Shape = Enum.PartType.Ball end
            local pupil = fitted(character, folder, "Head", "Eye",
                CFrame.new(x, head.Size.Y * 0.09, faceZ - 0.08),
                Vector3.new(head.Size.X * 0.035, head.Size.Y * 0.055, 0.025),
                Color3.fromRGB(10, 13, 14), Enum.Material.SmoothPlastic)
            if pupil then pupil.Shape = Enum.PartType.Ball end
        end
        fitted(character, folder, "Head", "MouthSeam", CFrame.new(0, -head.Size.Y * 0.27, faceZ - 0.01),
            Vector3.new(head.Size.X * 0.23, 0.025, 0.035), Color3.fromRGB(75, 82, 84), Enum.Material.Fabric)
        for _, x in { -1, 1 } do
            fitted(character, folder, "Head", "KnitSideSeam",
                CFrame.new(x * head.Size.X * 0.43, -0.04, -head.Size.Z * 0.41),
                Vector3.new(0.045, head.Size.Y * 0.63, 0.045), Color3.fromRGB(53, 59, 60), Enum.Material.Fabric)
        end
    end
end

local function bag(character: Model, folder: Folder)
    local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if hand == nil or not hand:IsA("BasePart") then return end
    local drop = if hand.Name == "RightHand" then 0.76 else hand.Size.Y * 0.75
    local leather = Color3.fromRGB(81, 50, 30)
    local webbing = Color3.fromRGB(158, 109, 61)
    local duffel = piece(character, folder, hand, "CarriedDuffel", Vector3.new(0, -drop, 0),
        Vector3.new(1.4, 0.73, 0.76), leather, Enum.Material.Fabric)
    if duffel then duffel.Shape = Enum.PartType.Cylinder end
    piece(character, folder, hand, "DuffelTop", Vector3.new(0, -drop + 0.38, 0),
        Vector3.new(1.31, 0.12, 0.72), webbing, Enum.Material.Fabric)
    for _, x in { -0.39, 0.39 } do
        piece(character, folder, hand, "HandleSide", Vector3.new(x, -drop * 0.48, 0),
            Vector3.new(0.11, drop * 0.88, 0.11), webbing, Enum.Material.Fabric)
        piece(character, folder, hand, "DuffelEndCap", Vector3.new(x * 1.7, -drop, 0),
            Vector3.new(0.1, 0.62, 0.69), Color3.fromRGB(56, 37, 25), Enum.Material.Fabric)
    end
    piece(character, folder, hand, "HandGrip", Vector3.new(0, -0.02, 0),
        Vector3.new(0.9, 0.12, 0.14), Color3.fromRGB(45, 31, 24), Enum.Material.Fabric)
    piece(character, folder, hand, "DuffelZip", Vector3.new(0, -drop + 0.46, -0.02),
        Vector3.new(1.08, 0.035, 0.07), Color3.fromRGB(215, 181, 100), Enum.Material.Metal)
end

-- Looping breathe tween; cancelled when the wardrobe folder is cleared.
local function pulse(folder: Folder, target: Instance, seconds: number, goal: {[string]: any})
    local tween = TweenService:Create(target, TweenInfo.new(seconds, Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut, -1, true), goal)
    tween:Play()
    folder.Destroying:Connect(function() tween:Cancel() end)
end

-- Invisible hub welded to the root that keeps turning; children weld to the hub.
local function spinner(folder: Folder, root: BasePart, name: string, offset: CFrame,
    size: Vector3, period: number, direction: number): BasePart
    local hub = Instance.new("Part")
    hub.Name = name
    hub.Size = size
    hub.Transparency = 1
    hub.CanCollide = false
    hub.CanTouch = false
    hub.CanQuery = false
    hub.Massless = true
    hub.CastShadow = false
    hub.CFrame = root.CFrame * offset
    hub.Parent = folder
    local joint = Instance.new("Weld")
    joint.Part0 = root
    joint.Part1 = hub
    joint.C0 = offset
    joint.Parent = hub
    task.spawn(function()
        local angle = 0
        while hub.Parent and folder.Parent do
            -- Steps under 180 degrees so each tween turns the intended way.
            angle += direction * math.pi * 2 / 3
            TweenService:Create(joint, TweenInfo.new(period / 3, Enum.EasingStyle.Linear),
                { C0 = offset * CFrame.Angles(0, angle, 0) }):Play()
            task.wait(period / 3)
        end
    end)
    return hub
end

local function hubPiece(folder: Folder, hub: BasePart, name: string, relative: CFrame,
    size: Vector3, color: Color3, transparency: number, shape: Enum.PartType?): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = Enum.Material.Neon
    part.Transparency = transparency
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.CastShadow = false
    if shape then part.Shape = shape end
    part.CFrame = hub.CFrame * relative
    part.Parent = folder
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hub
    weld.Part1 = part
    weld.Parent = part
    return part
end

local function glow(character: Model, folder: Folder, masked: boolean)
    local root = character:FindFirstChild("HumanoidRootPart")
    if root == nil or not root:IsA("BasePart") then return end
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") and not masked then
        local halo = importedPart(folder, head, "BlueHalo", "PhantomBlueHalo",
            CFrame.new(0, head.Size.Y * 1.05, 0))
        if halo then
            halo.Color = Color3.fromRGB(33, 163, 255)
            halo.Material = Enum.Material.Neon
            pulse(folder, halo, 1.1, { Color = Color3.fromRGB(150, 236, 255), Transparency = 0.15 })
        end
    end
    local attachment = Instance.new("Attachment")
    attachment.Name = "PhantomGlowAttachment"
    attachment.Parent = root
    attachment:SetAttribute("WardrobeVisual", true)
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(33, 163, 255)
    light.Brightness = 2
    light.Range = 10
    light.Parent = attachment
    pulse(folder, light, 1.1, { Brightness = 4.5, Range = 14 })
    local outline = Instance.new("Highlight")
    outline.Name = "PhantomOutline"
    outline.Adornee = character
    outline.DepthMode = Enum.HighlightDepthMode.Occluded
    outline.FillColor = Color3.fromRGB(18, 86, 82)
    outline.FillTransparency = 1
    outline.OutlineColor = Color3.fromRGB(43, 185, 255)
    outline.OutlineTransparency = 0.08
    outline.Parent = folder
    outline.FillColor = Color3.fromRGB(33, 120, 255)
    pulse(folder, outline, 1.1, { OutlineTransparency = 0.55, FillTransparency = 0.82 })
    local teal = Color3.fromRGB(44, 176, 255)
    local torso = torsoPart(character)
    if torso then
        local glowFront = -torso.Size.Z * 0.5 - 0.38
        for _, x in { -1, 1 } do
            local trace = piece(character, folder, torso, "PhantomShoulderTrace",
                Vector3.new(x * torso.Size.X * 0.43, torso.Size.Y * 0.41, glowFront + 0.03),
                Vector3.new(torso.Size.X * 0.17, 0.045, 0.05), teal, Enum.Material.Neon)
            if trace then pulse(folder, trace, 1.1, { Transparency = 0.45 }) end
        end
        local core = piece(character, folder, torso, "PhantomEnergyCore",
            Vector3.new(0, torso.Size.Y * 0.11, glowFront - 0.06),
            Vector3.new(0.18, 0.24, 0.1), Color3.fromRGB(95, 239, 245), Enum.Material.Neon)
        if core then
            core.Shape = Enum.PartType.Ball
            pulse(folder, core, 0.55, { Size = core.Size * 1.45, Color = Color3.fromRGB(210, 252, 255) })
            local coreLight = Instance.new("PointLight")
            coreLight.Name = "PhantomCoreLight"
            coreLight.Color = teal
            coreLight.Brightness = 1.1
            coreLight.Range = 7
            coreLight.Parent = core
            local wisps = Instance.new("ParticleEmitter")
            wisps.Name = "PhantomEnergyWisps"
            wisps.Rate = 8
            wisps.Lifetime = NumberRange.new(0.35, 0.75)
            wisps.Speed = NumberRange.new(0.2, 0.7)
            wisps.Acceleration = Vector3.new(0, 0.8, 0)
            wisps.SpreadAngle = Vector2.new(18, 18)
            wisps.LightEmission = 1
            wisps.Color = ColorSequence.new(teal, Color3.fromRGB(92, 139, 255))
            wisps.Size = NumberSequence.new(0.1)
            wisps.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.25, 0.1),
                NumberSequenceKeypoint.new(1, 1),
            })
            wisps.Parent = core
        end
    end
    for _, name in { "LeftUpperArm", "RightUpperArm", "Left Arm", "Right Arm" } do
        local arm = character:FindFirstChild(name)
        if arm and arm:IsA("BasePart") then
            local trace = piece(character, folder, arm, "GlowSleeveTrace",
                Vector3.new(0, 0, -arm.Size.Z * 0.5 - 0.25),
                Vector3.new(0.055, arm.Size.Y * 0.55, 0.05), teal, Enum.Material.Neon)
            if trace then pulse(folder, trace, 1.1, { Transparency = 0.45 }) end
        end
    end
    for _, name in { "LeftLowerLeg", "RightLowerLeg", "Left Leg", "Right Leg" } do
        local leg = character:FindFirstChild(name)
        if leg and leg:IsA("BasePart") then
            local trace = piece(character, folder, leg, "GlowShinTrace",
                Vector3.new(0, 0, -leg.Size.Z * 0.5 - 0.16),
                Vector3.new(0.065, leg.Size.Y * 0.54, 0.05), teal, Enum.Material.Neon)
            if trace then pulse(folder, trace, 1.1, { Transparency = 0.45 }) end
        end
    end
    local ice = Color3.fromRGB(170, 240, 255)
    local deep = Color3.fromRGB(60, 90, 255)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local floor = if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15
        then humanoid.HipHeight + root.Size.Y * 0.5 else 3
    -- Rune circle on the ground, slowly turning, with sparks rising out of it.
    local rune = spinner(folder, root, "PhantomRuneCircle", CFrame.new(0, -floor + 0.06, 0),
        Vector3.new(4, 0.1, 4), 7, 1)
    local disk = hubPiece(folder, rune, "PhantomRuneFloor", CFrame.Angles(0, 0, math.pi / 2),
        Vector3.new(0.02, 4.7, 4.7), teal, 0.86, Enum.PartType.Cylinder)
    pulse(folder, disk, 1.1, { Transparency = 0.95 })
    local segments = 20
    for i = 0, segments - 1 do
        local a = i / segments * math.pi * 2
        local bright = i % 2 == 0
        local segment = hubPiece(folder, rune, "PhantomRuneSegment",
            CFrame.new(math.cos(a) * 2.3, 0, math.sin(a) * 2.3) * CFrame.Angles(0, -a, 0),
            Vector3.new(0.09, 0.05, if bright then 0.6 else 0.3),
            if bright then teal else deep, if bright then 0.05 else 0.35)
        if bright then pulse(folder, segment, 1.1, { Transparency = 0.5 }) end
    end
    for i = 0, 5 do
        local a = i / 6 * math.pi * 2
        hubPiece(folder, rune, "PhantomRuneGem",
            CFrame.new(math.cos(a) * 1.55, 0.02, math.sin(a) * 1.55) * CFrame.Angles(0, -a + math.pi / 4, 0),
            Vector3.new(0.2, 0.05, 0.2), ice, 0.1)
    end
    local sparks = Instance.new("ParticleEmitter")
    sparks.Name = "PhantomRisingSparks"
    sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparks.EmissionDirection = Enum.NormalId.Top
    sparks.Rate = 28
    sparks.Lifetime = NumberRange.new(0.9, 1.6)
    sparks.Speed = NumberRange.new(1.8, 3.6)
    sparks.Drag = 1.2
    sparks.SpreadAngle = Vector2.new(8, 8)
    sparks.Rotation = NumberRange.new(0, 360)
    sparks.RotSpeed = NumberRange.new(-120, 120)
    sparks.LightEmission = 1
    sparks.Color = ColorSequence.new(ice, teal)
    sparks.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.32),
        NumberSequenceKeypoint.new(1, 0),
    })
    sparks.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.15, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    sparks.Parent = rune
    -- Three spirit wisps orbiting the body, each dragging a light trail.
    local orbit = spinner(folder, root, "PhantomWispOrbit", CFrame.new(0, 0.2, 0),
        Vector3.new(0.2, 0.2, 0.2), 2.6, -1)
    for i = 0, 2 do
        local a = i / 3 * math.pi * 2
        local wisp = hubPiece(folder, orbit, "PhantomWisp",
            CFrame.new(math.cos(a) * 1.9, (i - 1) * 0.55, math.sin(a) * 1.9),
            Vector3.new(0.26, 0.26, 0.26), ice, 0, Enum.PartType.Ball)
        pulse(folder, wisp, 0.7, { Size = Vector3.new(0.4, 0.4, 0.4) })
        local top = Instance.new("Attachment")
        top.Position = Vector3.new(0, 0.12, 0)
        top.Parent = wisp
        local bottom = Instance.new("Attachment")
        bottom.Position = Vector3.new(0, -0.12, 0)
        bottom.Parent = wisp
        local trail = Instance.new("Trail")
        trail.Attachment0 = top
        trail.Attachment1 = bottom
        trail.Lifetime = 0.5
        trail.LightEmission = 1
        trail.FaceCamera = true
        trail.Color = ColorSequence.new(teal, deep)
        trail.Transparency = NumberSequence.new(0.1, 1)
        trail.WidthScale = NumberSequence.new(1, 0)
        trail.Parent = wisp
    end
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "PhantomMotes"
    emitter.Rate = 13
    emitter.Lifetime = NumberRange.new(0.5, 1)
    emitter.Speed = NumberRange.new(0.2, 0.6)
    emitter.LightEmission = 1
    emitter.Color = ColorSequence.new(teal)
    emitter.Size = NumberSequence.new(0.12)
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.35, 0.16),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment
    local marker = Instance.new("ObjectValue")
    marker.Name = "GlowAttachment"
    marker.Value = attachment
    marker.Parent = folder
end

function WardrobeAppearance.Clear(character: Model)
    local old = character:FindFirstChild(FOLDER_NAME)
    if old then
        local hidden = old:FindFirstChild("HiddenHair")
        if hidden then
            for _, record in hidden:GetChildren() do
                if record:IsA("ObjectValue") and record.Value
                    and (record.Value:IsA("BasePart") or record.Value:IsA("Decal")) then
                    local visual = record.Value :: any
                    visual.Transparency = record:GetAttribute("OriginalTransparency") or 0
                end
            end
        end
        local marker = old:FindFirstChild("GlowAttachment")
        if marker and marker:IsA("ObjectValue") and marker.Value then marker.Value:Destroy() end
        local legendaryMarker = old:FindFirstChild("LegendarySparkAttachment")
        if legendaryMarker and legendaryMarker:IsA("ObjectValue") and legendaryMarker.Value then
            legendaryMarker.Value:Destroy()
        end
        old:Destroy()
    end
end

function WardrobeAppearance.Apply(character: Model, loadout: {[string]: string})
    WardrobeAppearance.Clear(character)
    if next(loadout) == nil then return end
    local folder = Instance.new("Folder")
    folder.Name = FOLDER_NAME
    folder.Parent = character
    local covered = loadout.Outfit == "starter_outfit" or loadout.Outfit == "neon_phantom_outfit"
        or loadout.Outfit == "classic_outfit" or loadout.Outfit == "shadow_king_outfit"
        or loadout.Outfit == "legendary_animated_outfit"
        or loadout.Face == "ski_mask"
    if covered then coverHair(character, folder, loadout.Face == "ski_mask") end
    if loadout.Outfit then outfit(character, folder, loadout.Outfit, loadout.Face == "ski_mask") end
    if loadout.Face then
        if loadout.Face == "ski_mask" then
            for _, child in folder:GetChildren() do
                if child.Name == "KnitCap" or child.Name == "CapRib"
                    or child.Name == "LegendaryBrim" or child.Name == "LegendaryHatCrown"
                    or child.Name == "LegendaryHatBand" then
                    child:Destroy()
                end
            end
        end
        mask(character, folder, loadout.Face)
    elseif loadout.Outfit == "starter_outfit" then
        mask(character, folder, "starter_mask")
    end
    if loadout.Body == "getaway_bag" then bag(character, folder) end
    if loadout.Special == "phantom_glow" or loadout.Outfit == "neon_phantom_outfit" then
        glow(character, folder, loadout.Face == "ski_mask")
    end
end

return table.freeze(WardrobeAppearance)
