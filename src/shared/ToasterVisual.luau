--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToasterVisual = {}
local missingTemplateWarned = false

type MeshStyle = { color: Color3, material: Enum.Material }
local enamel: MeshStyle = { color = Color3.fromRGB(119, 24, 36), material = Enum.Material.SmoothPlastic }
local enamelPanel: MeshStyle = { color = Color3.fromRGB(150, 34, 47), material = Enum.Material.SmoothPlastic }
local chrome: MeshStyle = { color = Color3.fromRGB(205, 213, 216), material = Enum.Material.Metal }
local darkMetal: MeshStyle = { color = Color3.fromRGB(70, 76, 81), material = Enum.Material.Metal }
local gold: MeshStyle = { color = Color3.fromRGB(213, 168, 74), material = Enum.Material.Metal }
local charcoal: MeshStyle = { color = Color3.fromRGB(34, 38, 42), material = Enum.Material.Metal }
local bread: MeshStyle = { color = Color3.fromRGB(224, 173, 108), material = Enum.Material.SmoothPlastic }
local crust: MeshStyle = { color = Color3.fromRGB(143, 82, 42), material = Enum.Material.SmoothPlastic }
local knob: MeshStyle = { color = Color3.fromRGB(43, 47, 50), material = Enum.Material.SmoothPlastic }

local meshStyles: {[string]: MeshStyle} = {
    Body = enamel,
    EnamelPanel_L = enamelPanel,
    EnamelPanel_R = enamelPanel,
    TopRim = chrome,
    BaseStrip = darkMetal,
    GoldBand = gold,
    StarCenter = gold,
    SlotPlate_0 = charcoal,
    SlotPlate_1 = charcoal,
    BreadSlice_0 = bread,
    BreadSlice_1 = bread,
    BreadCrust_0 = crust,
    BreadCrust_1 = crust,
    LeverArm = darkMetal,
    LeverRail = darkMetal,
    LeverKnob = knob,
}
for index = 0, 7 do
    meshStyles["StarSpike_" .. index] = gold
end

function ToasterVisual.ApplyAppearance(model: Model)
    for _, descendant in model:GetDescendants() do
        if descendant:IsA("MeshPart")
            and descendant.TextureID == ""
            and descendant:FindFirstChildOfClass("SurfaceAppearance") == nil then
            local style = meshStyles[descendant.Name]
            if style ~= nil then
                descendant.Color = style.color
                descendant.Material = style.material
                if style == gold then
                    descendant.MaterialVariant = "StealAnythingAntiqueGold"
                end
            end
        end
    end
end

local function makePart(name: string, size: Vector3, color: Color3, material: Enum.Material,
    frame: CFrame, anchored: boolean, parent: Instance): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material
    part.CFrame = frame
    part.Anchored = anchored
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function ToasterVisual.Create(name: string, base: CFrame, anchored: boolean): (Model, Part)
    local model = Instance.new("Model")
    model.Name = name
    local steel = Color3.fromRGB(175, 187, 182)
    local dark = Color3.fromRGB(41, 54, 53)
    local toast = Color3.fromRGB(206, 150, 75)
    local body = makePart("Body", Vector3.new(1.75, 1.25, 1.05), steel,
        Enum.Material.Metal, base, anchored, model)
    model.PrimaryPart = body

    local assets = ReplicatedStorage:FindFirstChild("VisualAssets")
    local template = assets and assets:FindFirstChild("DramaticToaster")
    local importedBody = template and template:FindFirstChild("Body")
    if template and template:IsA("Model") and importedBody and importedBody:IsA("MeshPart") then
        local cosmetics = template:Clone()
        cosmetics.Name = "Cosmetics"
        local cosmeticBody = cosmetics:FindFirstChild("Body") :: MeshPart
        local relativeBody = template:GetPivot():ToObjectSpace(importedBody.CFrame)
        cosmetics:PivotTo(base * relativeBody:Inverse())
        cosmetics.Parent = model
        ToasterVisual.ApplyAppearance(cosmetics)

        for _, part in cosmetics:GetDescendants() do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
                part.Massless = true
                if part ~= cosmeticBody and part:FindFirstChild("CosmeticWeld") == nil then
                    local weld = Instance.new("WeldConstraint")
                    weld.Name = "CosmeticWeld"
                    weld.Part0 = cosmeticBody
                    weld.Part1 = part
                    weld.Parent = part
                end
            end
        end
        local attachment = Instance.new("WeldConstraint")
        attachment.Name = "CosmeticAttachment"
        attachment.Part0 = body
        attachment.Part1 = cosmeticBody
        attachment.Parent = body
        body.Transparency = 1
    else
        if not missingTemplateWarned then
            missingTemplateWarned = true
            warn("[Steal Anything] ReplicatedStorage/VisualAssets/DramaticToaster is missing; using the basic toaster visual")
        end
        makePart("FrontPanel", Vector3.new(1.42, 0.2, 0.055), dark,
            Enum.Material.Metal, base * CFrame.new(0, -0.28, -0.55), anchored, model)
        makePart("LeftToast", Vector3.new(0.42, 0.8, 0.18), toast,
            Enum.Material.Wood, base * CFrame.new(-0.43, 0.78, 0), anchored, model)
        makePart("RightToast", Vector3.new(0.42, 0.8, 0.18), toast,
            Enum.Material.Wood, base * CFrame.new(0.43, 0.78, 0), anchored, model)
        makePart("Lever", Vector3.new(0.28, 0.12, 0.24), dark,
            Enum.Material.Metal, base * CFrame.new(1.02, 0.05, 0), anchored, model)
        if not anchored then
            for _, child in model:GetChildren() do
                if child:IsA("BasePart") and child ~= body then
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = body
                    weld.Part1 = child
                    weld.Parent = body
                end
            end
        end
    end
    return model, body
end

return table.freeze(ToasterVisual)
