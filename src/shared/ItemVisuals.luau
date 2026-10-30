--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToasterVisual = require(script.Parent.ToasterVisual)

local SignatureVfx = require(script.Parent.SignatureVfx)
local ExhibitRig = require(script.Parent.ExhibitRig)
local ItemVisuals = {}

local function addCollision(model: Model)
    local bounds, size = model:GetBoundingBox()
    local hull = Instance.new("Part")
    hull.Name = "DisplayCollision"
    hull.Size = Vector3.new(math.max(0.8, size.X * 0.78),
        math.max(0.8, size.Y * 0.84), math.max(0.8, size.Z * 0.78))
    hull.CFrame = bounds * CFrame.new(0, -(size.Y - hull.Size.Y) / 2, 0)
    hull.Transparency = 1
    hull.Anchored = true
    hull.CanCollide = true
    hull.CanTouch = false
    hull.CanQuery = false
    hull.CastShadow = false
    hull.Parent = model
end

local accents = {
    toaster = { color = Color3.fromRGB(255, 165, 83), second = Color3.fromRGB(255, 229, 153), rate = 2, motion = "rise" },
    duck = { color = Color3.fromRGB(89, 224, 241), second = Color3.fromRGB(255, 224, 94), rate = 3, motion = "bubble" },
    traffic_cone = { color = Color3.fromRGB(255, 130, 58), second = Color3.fromRGB(255, 213, 106), rate = 2, motion = "spark" },
    disco_bin = { color = Color3.fromRGB(240, 88, 219), second = Color3.fromRGB(88, 225, 255), rate = 5, motion = "burst" },
    gold_toilet = { color = Color3.fromRGB(255, 208, 86), second = Color3.fromRGB(255, 247, 170), rate = 3, motion = "glint" },
    jelly_lamp = { color = Color3.fromRGB(255, 113, 198), second = Color3.fromRGB(166, 141, 255), rate = 4, motion = "bubble" },
    snack_machine = { color = Color3.fromRGB(255, 103, 93), second = Color3.fromRGB(255, 211, 98), rate = 3, motion = "burst" },
    moon_rock = { color = Color3.fromRGB(141, 222, 255), second = Color3.fromRGB(184, 161, 255), rate = 3, motion = "dust" },
    mini_ufo = { color = Color3.fromRGB(95, 246, 220), second = Color3.fromRGB(118, 171, 255), rate = 4, motion = "orbit" },
    dinosaur_skull = { color = Color3.fromRGB(255, 209, 152), second = Color3.fromRGB(194, 149, 100), rate = 2, motion = "dust" },
    storm_jar = { color = Color3.fromRGB(119, 186, 255), second = Color3.fromRGB(225, 242, 255), rate = 5, motion = "spark" },
    giant_diamond = { color = Color3.fromRGB(105, 240, 255), second = Color3.fromRGB(250, 196, 255), rate = 6, motion = "glint" },
}

function ItemVisuals.EffectColor(itemId: string): Color3
    local spec = accents[itemId]
    return if spec then spec.color else Color3.fromRGB(220, 226, 208)
end

local function addArtifactEffects(root: BasePart, itemId: string)
    local model = root.Parent :: Model
    local bounds, size = model:GetBoundingBox()
    SignatureVfx.Attach(root, model, itemId, root.CFrame:ToObjectSpace(bounds), size)
end

local function fallback(name: string, center: CFrame, anchored: boolean): (Model, BasePart, number)
    local model = Instance.new("Model")
    model.Name = name
    local body = Instance.new("Part")
    body.Name = "MissingItemVisual"
    body.Shape = Enum.PartType.Ball
    body.Size = Vector3.new(1.5, 1.5, 1.5)
    body.CFrame = center
    body.Color = Color3.fromRGB(185, 148, 83)
    body.Material = Enum.Material.Metal
    body.Anchored = anchored
    body.CanCollide = false
    body.CanTouch = false
    body.CanQuery = false
    body.Massless = true
    body.Parent = model
    model.PrimaryPart = body
    return model, body, 1.5
end

function ItemVisuals.Height(itemId: string): number
    if itemId == "toaster" then return 1.9 end
    local assets = ReplicatedStorage:FindFirstChild("VisualAssets")
    local folder = assets and assets:FindFirstChild("ItemModels")
    local template = folder and folder:FindFirstChild(itemId)
    local height = template and template:GetAttribute("DisplayHeight")
    return if type(height) == "number" then height else 1.5
end

function ItemVisuals.Create(itemId: string, name: string, center: CFrame,
    anchored: boolean, scale: number?): (Model, BasePart, number)
    if itemId == "toaster" then
        local model, root = ToasterVisual.Create(name, center, anchored)
        if scale ~= nil and scale ~= 1 then
            model:ScaleTo(model:GetScale() * scale)
        end
        if anchored then
            ExhibitRig.Configure(model, itemId)
            addArtifactEffects(root, itemId)
            addCollision(model)
        end
        return model, root, 1.9 * (scale or 1)
    end
    local assets = ReplicatedStorage:FindFirstChild("VisualAssets")
    local folder = assets and assets:FindFirstChild("ItemModels")
    local template = folder and folder:FindFirstChild(itemId)
    if template == nil or not template:IsA("Model")
        or template:GetAttribute("PreparedItemTemplate") ~= true then
        return fallback(name, center, anchored)
    end
    local model = template:Clone()
    model.Name = name
    if scale ~= nil and scale ~= 1 then
        model:ScaleTo(model:GetScale() * scale)
    end
    local root = model.PrimaryPart
    if root == nil then
        model:Destroy()
        return fallback(name, center, anchored)
    end
    model:PivotTo(center)
    root.Anchored = anchored
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Massless = true
            if part ~= root then part.Anchored = false end
        end
    end
    if anchored then
        ExhibitRig.Configure(model, itemId)
        addArtifactEffects(root, itemId)
        addCollision(model)
    end
    return model, root, ItemVisuals.Height(itemId) * (scale or 1)
end

return table.freeze(ItemVisuals)
