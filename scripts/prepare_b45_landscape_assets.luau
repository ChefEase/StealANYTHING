-- Run in Studio Edit after importing B4/B5 and syncing Rojo.
-- Preserves the four complete imported originals in server-only storage.
-- Rebuilds only marked cosmetic templates under ReplicatedStorage.VisualAssets.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local assets = ServerStorage.Assets
local visualAssets = assert(ReplicatedStorage:FindFirstChild("VisualAssets"))
local kit = visualAssets:FindFirstChild("LandscapeKit")
if not kit then
    kit = Instance.new("Folder")
    kit.Name = "LandscapeKit"
    kit.Parent = visualAssets
end

local sources = assets:FindFirstChild("LandscapeSourceImports")
if not sources then
    sources = kit:FindFirstChild("SourceImports")
    if sources then
        sources.Name = "LandscapeSourceImports"
        sources.Parent = assets
    else
        sources = Instance.new("Folder")
        sources.Name = "LandscapeSourceImports"
        sources.Parent = assets
    end
end

local importNames = {"B4TreeTall", "B4TreeRound", "B5PlanterShrub", "B5RoundPlanter"}
for _, name in importNames do
    local model = sources:FindFirstChild(name) or workspace:FindFirstChild(name)
    assert(model and model:IsA("Model"), "Missing B4/B5 imported Model: " .. name)
    if model.Parent == workspace then model.Parent = sources end
    for _, mesh in model:GetDescendants() do
        if mesh:IsA("MeshPart") then
            mesh.Anchored = true
            mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = false, false, false
            mesh.Massless = true
        end
    end
end

local module = assets.Task11VisualKit:Clone()
local visualKit = require(module)

local function prepare(sourceName, templateName, split, shrubOnly)
    local old = kit:FindFirstChild(templateName)
    if old then
        assert(old:GetAttribute("LandscapeTemplate") == true,
            "Refusing to replace unmanaged template: " .. templateName)
        old:Destroy()
    end

    local original = assert(sources:FindFirstChild(sourceName))
    local originalPivot = original:GetPivot()
    local copy = original:Clone()
    copy.Name = templateName
    if split then
        if shrubOnly then
            for _, child in copy:GetChildren() do
                if child:IsA("MeshPart") and not child.Name:find("Shrub") then
                    child:Destroy()
                end
            end
        else
            local planter = Instance.new("Model")
            planter.Name, planter.WorldPivot = "Planter", originalPivot
            planter.Parent = copy
            local shrub = Instance.new("Model")
            shrub.Name, shrub.WorldPivot = "Shrub", originalPivot
            shrub.Parent = copy
            for _, child in copy:GetChildren() do
                if child:IsA("MeshPart") then
                    child.Parent = if child.Name:find("Shrub") then shrub else planter
                end
            end
        end
        copy.WorldPivot = originalPivot
    end
    copy:SetAttribute("LandscapeTemplate", true)
    copy:SetAttribute("SourceImport", sourceName)
    visualKit.ApplyLandscapePalette(copy)
    copy.Parent = kit
end

prepare("B4TreeTall", "TreeTall", false, false)
prepare("B4TreeRound", "TreeRound", false, false)
prepare("B5PlanterShrub", "RectPlanterShrub", true, false)
prepare("B5PlanterShrub", "ShrubOnly", true, true)
prepare("B5RoundPlanter", "RoundPlanterShrub", true, false)

module:Destroy()
print("B4/B5 landscape templates prepared in ReplicatedStorage.VisualAssets.LandscapeKit")
