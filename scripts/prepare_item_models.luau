-- Run in the museum game's Studio Edit mode after the Blender imports are present.
-- Keeps untouched originals in ServerStorage.Assets.ItemSourceImports.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local sources = {
    duck = { "C1_Spriny_Rubber_Ducky", "Small" },
    traffic_cone = { "c3_royal_traffic_cone", "Medium" },
    disco_bin = { "c4_DiscoDustbin", "Medium" },
    gold_toilet = { "c5_goldenToilet", "Medium" },
    jelly_lamp = { "c6_JellyLamp", "Small" },
    snack_machine = { "c7_RattlingSnackMachine", "Heavy" },
    moon_rock = { "c8_suspiciousMoonRock", "Medium" },
    mini_ufo = { "c9_SpringMiniUFO", "Medium" },
    dinosaur_skull = { "c10_TinyDinosauHeadSkull", "Heavy" },
    storm_jar = { "c11_Storm_In_A_Jar", "Small" },
    giant_diamond = { "c12_Absurd_Diamond", "Heavy" },
}
local heights = { Small = 2.3, Medium = 3.2, Heavy = 4.3 }
local widths = { Small = 2.8, Medium = 4.0, Heavy = 5.2 }
local C = {
    teal = Color3.fromRGB(48, 200, 184), deepTeal = Color3.fromRGB(20, 72, 76),
    cyan = Color3.fromRGB(101, 235, 239), blue = Color3.fromRGB(85, 149, 226),
    gold = Color3.fromRGB(232, 178, 73), ivory = Color3.fromRGB(244, 232, 200),
    white = Color3.fromRGB(245, 246, 239), charcoal = Color3.fromRGB(29, 41, 50),
    steel = Color3.fromRGB(142, 168, 180), silver = Color3.fromRGB(205, 219, 220),
    yellow = Color3.fromRGB(255, 210, 70), orange = Color3.fromRGB(238, 107, 42),
    red = Color3.fromRGB(179, 48, 70), pink = Color3.fromRGB(238, 106, 179),
    purple = Color3.fromRGB(124, 70, 188), violet = Color3.fromRGB(177, 109, 232),
    stone = Color3.fromRGB(112, 123, 139), darkStone = Color3.fromRGB(67, 75, 93),
    bone = Color3.fromRGB(222, 209, 171), wood = Color3.fromRGB(116, 73, 46),
}

local function contains(name, word)
    return string.find(name, word, 1, true) ~= nil
end

local function appearance(id, name)
    local n = string.lower(name)
    local color, material, transparency = C.teal, Enum.Material.SmoothPlastic, 0
    if id == "duck" then
        color = C.yellow
        if contains(n, "beak") then color = C.orange
        elseif contains(n, "cheek") then color = C.pink
        elseif contains(n, "sclera") or contains(n, "highlight") then color = C.white
        elseif contains(n, "pupil") or contains(n, "beakline") then color = C.charcoal
        elseif contains(n, "spring") then color, material = C.silver, Enum.Material.Metal
        elseif contains(n, "base") then color, material = C.deepTeal, Enum.Material.Metal
        elseif contains(n, "collar") or contains(n, "accent") then color, material = C.gold, Enum.Material.Metal end
    elseif id == "traffic_cone" then
        color = C.orange
        if contains(n, "white") or contains(n, "cream") then color = C.ivory
        elseif contains(n, "gem") or contains(n, "teal") then color, material = C.cyan, Enum.Material.Neon
        elseif contains(n, "gold") or contains(n, "stud") or contains(n, "crest")
            or contains(n, "crown") or contains(n, "finial") then color, material = C.gold, Enum.Material.Metal
        elseif contains(n, "velvet") then color = C.purple
        elseif contains(n, "base") then color, material = C.charcoal, Enum.Material.Metal end
    elseif id == "disco_bin" then
        color, material = C.deepTeal, Enum.Material.Metal
        if contains(n, "discotile") or contains(n, "lidtile") then
            local hash = 0
            for index = 1, #name do hash += string.byte(name, index) end
            color = ({ C.cyan, C.pink, C.violet, C.gold })[hash % 4 + 1]
            material = Enum.Material.Neon
        elseif contains(n, "gold") or contains(n, "rim") or contains(n, "knob") then color = C.gold
        elseif contains(n, "plaque") then color, material = C.ivory, Enum.Material.SmoothPlastic
        elseif contains(n, "inner") then color = C.charcoal
        elseif contains(n, "teal") then color = C.teal end
    elseif id == "gold_toilet" then
        color, material = C.ivory, Enum.Material.SmoothPlastic
        if contains(n, "gem") then color, material = C.cyan, Enum.Material.Neon
        elseif contains(n, "crown") or contains(n, "trim") or contains(n, "scroll")
            or contains(n, "flush") or contains(n, "hinge") then color, material = C.gold, Enum.Material.Metal
        elseif contains(n, "seat") or contains(n, "lid") then color = C.red
        elseif contains(n, "interior") then color = C.white
        elseif contains(n, "pipe") then color, material = C.steel, Enum.Material.Metal end
    elseif id == "jelly_lamp" then
        color, material = C.deepTeal, Enum.Material.Metal
        if contains(n, "domeinner") then color, material = C.pink, Enum.Material.Neon
        elseif contains(n, "dome") then color, material, transparency = C.cyan, Enum.Material.Glass, 0.28
        elseif contains(n, "tentacle") or contains(n, "fringe") then color, material = C.violet, Enum.Material.Neon
        elseif contains(n, "rib") then color, material = C.teal, Enum.Material.Neon
        elseif contains(n, "gold") or contains(n, "finial") then color, material = C.gold, Enum.Material.Metal end
    elseif id == "snack_machine" then
        color, material = C.purple, Enum.Material.Metal
        if contains(n, "glass") then color, material, transparency = C.blue, Enum.Material.Glass, 0.48
        elseif contains(n, "screen") or contains(n, "logoaccent") then color, material = C.cyan, Enum.Material.Neon
        elseif contains(n, "gold") or contains(n, "coin") then color, material = C.gold, Enum.Material.Metal
        elseif contains(n, "snack") then
            color = if contains(n, "chip") then C.orange elseif contains(n, "candy") then C.pink
                elseif contains(n, "gummy") then C.teal else C.ivory
            material = Enum.Material.SmoothPlastic
        elseif contains(n, "shelf") or contains(n, "interior") or contains(n, "vent") then color = C.charcoal
        elseif contains(n, "button") then color, material = C.yellow, Enum.Material.Neon end
    elseif id == "moon_rock" then
        color, material = C.stone, Enum.Material.Slate
        if contains(n, "crystalb") then color, material = C.violet, Enum.Material.Neon
        elseif contains(n, "crystal") or contains(n, "glow") then color, material = C.cyan, Enum.Material.Neon
        elseif contains(n, "rune") or contains(n, "gold") then color, material = C.gold, Enum.Material.Metal
        elseif contains(n, "crater") then color = C.darkStone end
    elseif id == "mini_ufo" then
        color, material = C.steel, Enum.Material.Metal
        if contains(n, "aliendome") then color, material, transparency = C.cyan, Enum.Material.Glass, 0.2
        elseif contains(n, "glow") or contains(n, "antenna") then color, material = C.pink, Enum.Material.Neon
        elseif contains(n, "gold") or contains(n, "nub") or contains(n, "porthole") then color, material = C.gold, Enum.Material.Metal
        elseif contains(n, "saucer") or contains(n, "rim") then color = C.deepTeal end
    elseif id == "dinosaur_skull" then
        color, material = C.bone, Enum.Material.Slate
        if contains(n, "eye") or contains(n, "fossa") or contains(n, "nasalcavity") then color = C.charcoal
        elseif contains(n, "gold") then color, material = C.gold, Enum.Material.Metal
        elseif contains(n, "teal") then color, material = C.teal, Enum.Material.Metal
        elseif contains(n, "tooth") then color, material = C.ivory, Enum.Material.SmoothPlastic end
    elseif id == "storm_jar" then
        color, material = C.steel, Enum.Material.Metal
        if contains(n, "jar_body") then color, material, transparency = C.cyan, Enum.Material.Glass, 0.5
        elseif contains(n, "bolt") then color, material = C.yellow, Enum.Material.Neon
        elseif contains(n, "cloud_light") then color, material = C.cyan, Enum.Material.Neon
        elseif contains(n, "cloud") then color, material = C.darkStone, Enum.Material.SmoothPlastic
        elseif contains(n, "cork") then color, material = C.wood, Enum.Material.Wood
        elseif contains(n, "gold") then color, material = C.gold, Enum.Material.Metal
        elseif contains(n, "teal") then color = C.teal end
    elseif id == "giant_diamond" then
        color, material = C.gold, Enum.Material.Metal
        if contains(n, "diamond") or contains(n, "facet") then
            color, material, transparency = C.cyan, Enum.Material.Glass, 0.08
        elseif contains(n, "innerglow") or contains(n, "tealshard") then color, material = C.cyan, Enum.Material.Neon
        elseif contains(n, "cartouche") then color, material = C.ivory, Enum.Material.SmoothPlastic end
    end
    return color, material, transparency
end

local function movingPart(id, name)
    if id == "duck" then return name:match("^Duck_") ~= nil
        and not contains(name, "Base") and not contains(name, "Spring") end
    if id == "traffic_cone" then return contains(name, "Crown") or contains(name, "Crest") or contains(name, "Finial") end
    if id == "disco_bin" then return contains(name, "Lid") or contains(name, "Handle") end
    if id == "gold_toilet" then return name == "Toilet_Lid" end
    if id == "jelly_lamp" then return contains(name, "Tentacle") end
    if id == "snack_machine" then return contains(name, "SM_Snack") end
    if id == "moon_rock" then return contains(name, "Crystal") end
    if id == "mini_ufo" then return not contains(name, "BasePlate")
        and not contains(name, "CoilSpring") and not contains(name, "SpringCollar") end
    if id == "dinosaur_skull" then return contains(name, "Jaw") or contains(name, "Tooth") end
    if id == "storm_jar" then return name:match("^FX_") ~= nil end
    if id == "giant_diamond" then return contains(name, "Diamond")
        or contains(name, "Facet") or contains(name, "InnerGlow") or contains(name, "TealShard") end
    return false
end

local backup = ServerStorage.Assets:FindFirstChild("ItemSourceImports")
if backup == nil then
    backup = Instance.new("Folder")
    backup.Name = "ItemSourceImports"
    backup.Parent = ServerStorage.Assets
end
local old = ReplicatedStorage.VisualAssets:FindFirstChild("ItemModels")
if old and old:GetAttribute("ImportedItemTemplates") ~= true then
    error("VisualAssets.ItemModels exists but is not owned by this preparation script")
end
local prepared = Instance.new("Folder")
prepared.Name = "ItemModels"
prepared:SetAttribute("ImportedItemTemplates", true)

local originalsToMove = {}
local preparedCount = 0
for id, spec in pairs(sources) do
    local original = workspace:FindFirstChild(spec[1]) or backup:FindFirstChild(spec[1])
    assert(original and original:IsA("Model"), "Missing imported model: " .. spec[1])
    local model = original:Clone()
    model.Name = id
    local _, size = model:GetBoundingBox()
    local scale = math.min(heights[spec[2]] / size.Y,
        widths[spec[2]] / math.max(size.X, size.Z))
    model:ScaleTo(scale)
    local bounds = model:GetBoundingBox()
    local relative = model:GetPivot():ToObjectSpace(bounds)
    model:PivotTo(relative:Inverse())

    local root = Instance.new("Part")
    root.Name = "VisualRoot"
    root.Size = Vector3.new(0.2, 0.2, 0.2)
    root.CFrame = CFrame.identity
    root.Transparency = 1
    root.Anchored = false
    root.CanCollide = false
    root.CanTouch = false
    root.CanQuery = false
    root.Massless = true
    root.Parent = model
    model.PrimaryPart = root

    local moving = {}
    local pieces = {}
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") and part ~= root then
            part.Anchored = false
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Massless = true
            local color, material, transparency = appearance(id, part.Name)
            part.Color = color
            part.Material = material
            part.MaterialVariant = if material == Enum.Material.Metal and color == C.gold
                then "StealAnythingAntiqueGold"
                elseif material == Enum.Material.Metal
                    and (id == "disco_bin" or id == "snack_machine"
                        or id == "mini_ufo" or id == "jelly_lamp" or id == "storm_jar")
                then "StealAnythingPaintedMetal"
                elseif id == "moon_rock" and material == Enum.Material.Slate
                then "StealAnythingLunarStone"
                elseif id == "dinosaur_skull" and material == Enum.Material.Slate
                then "StealAnythingFossilBone"
                elseif id == "gold_toilet" and material == Enum.Material.SmoothPlastic
                then "StealAnythingRoyalCeramic"
                elseif material == Enum.Material.SmoothPlastic
                    and (id == "duck" or id == "traffic_cone")
                then "StealAnythingToyRubber"
                else ""
            part.Transparency = transparency
            part.Reflectance = if material == Enum.Material.Metal then 0.12 else 0
            table.insert(pieces, part)
            if movingPart(id, part.Name) then table.insert(moving, part) end
        end
    end
    local mover = nil
    if #moving > 0 then
        local center = Vector3.zero
        for _, part in moving do center += part.Position end
        center /= #moving
        mover = Instance.new("Part")
        mover.Name = "AnimatedRoot"
        mover.Size = Vector3.new(0.1, 0.1, 0.1)
        mover.CFrame = CFrame.new(center)
        mover.Transparency = 1
        mover.Anchored = false
        mover.CanCollide = false
        mover.CanTouch = false
        mover.CanQuery = false
        mover.Massless = true
        mover.Parent = model
        local joint = Instance.new("Motor6D")
        joint.Name = "MotionJoint"
        joint.Part0 = root
        joint.Part1 = mover
        joint.C0 = root.CFrame:ToObjectSpace(mover.CFrame)
        joint.C1 = CFrame.identity
        joint:SetAttribute("ItemId", id)
        joint.Parent = root
    end
    local movingSet = {}
    for _, part in moving do movingSet[part] = true end
    for _, part in pieces do
        local weld = Instance.new("WeldConstraint")
        weld.Name = "VisualWeld"
        weld.Part0 = if movingSet[part] then mover else root
        weld.Part1 = part
        weld.Parent = part
    end
    local finalSize = model:GetExtentsSize()
    model:SetAttribute("ItemId", id)
    model:SetAttribute("FootprintClass", spec[2])
    model:SetAttribute("PreparedItemTemplate", true)
    model:SetAttribute("DisplayHeight", finalSize.Y)
    model.Parent = prepared
    preparedCount += 1
    if original.Parent == workspace then table.insert(originalsToMove, original) end
    task.wait()
end
assert(preparedCount == 11)
if old then old:Destroy() end
prepared.Parent = ReplicatedStorage.VisualAssets
for _, original in originalsToMove do original.Parent = backup end
print("Prepared " .. preparedCount .. " styled, scaled, welded item models; originals backed up")
