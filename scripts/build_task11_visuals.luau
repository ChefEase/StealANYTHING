-- Studio Edit, after structural templates and Rojo sync.
-- Reproducible staged build; functional template parts are not rebuilt.
local assets = game.ServerStorage.Assets
local pack = assert(assets:FindFirstChild("Task11MapTemplates"), "Build Task 11 templates first")
local module = assets.Task11VisualKit:Clone()
local kit = require(module)
local museum = pack.StarterMuseumTemplate
kit.BuildExterior(museum)
task.wait()
kit.BuildInterior(museum)
task.wait()
local prior = pack:FindFirstChild("LandscapePresets")
if prior then prior:Destroy() end
local presets = Instance.new("Folder")
presets.Name = "LandscapePresets"
presets:SetAttribute("GeneratedBy", "Task11VisualKit")
presets.Parent = pack
for index = 1, 6 do
    kit.BuildLandscape(index, museum).Parent = presets
    task.wait()
end
kit.BuildWorld(pack.SixPlotWorldTemplate)
pack:SetAttribute("VisualKitVersion", kit.Version)
module:Destroy()
print("Task 11 visual kit v" .. kit.Version .. " built")
