-- Studio Edit: refresh visual roots on measured starter clones.
-- The old prototype is deliberately rejected by its floor dimensions.
local assets = game.ServerStorage.Assets
local pack = assert(assets:FindFirstChild("Task11MapTemplates"), "Build Task 11 templates first")
assert((pack:GetAttribute("VisualKitVersion") or 0) >= 5, "Build visual kit v5 or newer first")
local source = pack.StarterMuseumTemplate
local definitions = require(game.ReplicatedStorage.Shared.Task11VisualDefinitions)
local plots = require(game.ReplicatedStorage.Shared.PlotDefinitions)
local preview = workspace:FindFirstChild("Task11InspectionPreview")
local root = workspace:FindFirstChild("ActiveMuseums")
    or (preview and preview:FindFirstChild("Museums")) or workspace:FindFirstChild("Map")
assert(root, "No museum container")
local applied = 0
for _, museum in root:GetChildren() do
    if museum:IsA("Model") and string.match(museum.Name, "^Museum%d+$") then
        local hall = museum:FindFirstChild("StarterHall")
        local floor = hall and hall:FindFirstChild("Floor")
        if floor and floor.Size == Vector3.new(60, 1, 60)
            and museum:FindFirstChild("ReceivingZone")
            and museum:FindFirstChild("ProtectedDisplaySocket") then
            local index = tonumber(string.match(museum.Name, "%d+")) or 1
            local id = museum:GetAttribute("PlotId") or museum:GetAttribute("PreviewPlotId")
            for i, slot in plots.Slots do if slot.id == id then index = i end end
            assert(definitions.Presets[index], "Unrecognized plot")
            for _, name in {"ArchitectureVisuals", "InteriorVisuals", "BackyardVisuals", "Task11LiveVisuals"} do
                local prior = museum:FindFirstChild(name)
                if prior then prior:Destroy() end
            end
            for _, child in museum:GetChildren() do
                if child:GetAttribute("CosmeticOnly") and string.match(child.Name, "^Landscape_") then child:Destroy() end
            end
            for _, name in {"ArchitectureVisuals", "InteriorVisuals"} do
                local copy = source[name]:Clone()
                for _, item in copy:GetDescendants() do
                    if item:IsA("BasePart") then
                        item.CFrame = museum:GetPivot() * source:GetPivot():ToObjectSpace(item.CFrame)
                    end
                end
                copy.Parent = museum
            end
            local landscape = pack.LandscapePresets[definitions.Presets[index].id]:Clone()
            landscape.Name = "BackyardVisuals"
            landscape:PivotTo(museum:GetPivot())
            landscape.Parent = museum
            museum:SetAttribute("VisualKitVersion", pack:GetAttribute("VisualKitVersion"))
            applied += 1
            task.wait()
        else
            warn("[Task11] Skipped " .. museum.Name .. ": not the audited starter geometry")
        end
    end
end
print("[Task11] refreshed " .. applied .. " starter museums without duplicate visual layers")
