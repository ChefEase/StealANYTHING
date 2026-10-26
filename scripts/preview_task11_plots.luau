-- Run in the connected place's Studio Edit command context after Task 11 templates exist.
-- Inspection only: the active prototype remains at Workspace/Map.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")

local plots = require(ReplicatedStorage.Shared.PlotDefinitions)
local visualDefinitions = require(ReplicatedStorage.Shared.Task11VisualDefinitions)
local pack = assert(ServerStorage.Assets:FindFirstChild("Task11MapTemplates"),
    "Build Task 11 templates first")
local existing = workspace:FindFirstChild("Task11InspectionPreview")
if existing then
    assert(existing:GetAttribute("GeneratedBy") == "scripts/preview_task11_plots.luau",
        "Refusing to replace unrelated Workspace content")
    existing:Destroy()
end

local offset = Vector3.new(2_000, 0, 0)
local preview = Instance.new("Folder")
preview.Name = "Task11InspectionPreview"
preview:SetAttribute("GeneratedBy", "scripts/preview_task11_plots.luau")
preview:SetAttribute("InspectionOnly", true)
preview.Archivable = false -- Studio can display it, but save/publish excludes it.
preview.Parent = workspace

local world = pack.SixPlotWorldTemplate:Clone()
world.Name = "World"
world:PivotTo(CFrame.new(offset))
world.Parent = preview

local museums = Instance.new("Folder")
museums.Name = "Museums"
museums.Parent = preview

local firstMuseum
local landscapePresets = pack:FindFirstChild("LandscapePresets")
for index, slot in plots.Slots do
    local museum = pack.StarterMuseumTemplate:Clone()
    museum.Name = string.format("Museum%02d", index)
    museum:SetAttribute("PreviewPlotId", slot.id)
    museum:PivotTo(CFrame.new(offset + slot.center)
        * CFrame.Angles(0, math.rad(slot.yawDegrees), 0))
    museum.Parent = museums
    if landscapePresets then
        local preset = landscapePresets:FindFirstChild(visualDefinitions.Presets[index].id)
        if preset then
            local landscape = preset:Clone()
            landscape.Name = "BackyardVisuals"
            landscape:PivotTo(museum:GetPivot())
            landscape.Parent = museum
        end
    end
    if index == 1 then firstMuseum = museum end
    task.wait()
end

-- Tagged map sockets in this duplicate should never be considered live targets.
for _, descendant in preview:GetDescendants() do
    if CollectionService:HasTag(descendant, "MapSocket") then
        CollectionService:RemoveTag(descendant, "MapSocket")
    end
    if descendant:IsA("BasePart") then
        descendant.CanTouch = false
    end
end

Selection:Set({ firstMuseum })
workspace.CurrentCamera.CFrame = CFrame.lookAt(
    offset + Vector3.new(0, 30, 250),
    offset + Vector3.new(0, 8, 360))
print("Task 11 inspection preview ready. Select any Museum01–Museum06 in"
    .. " Workspace/Task11InspectionPreview/Museums and press F to focus.")
