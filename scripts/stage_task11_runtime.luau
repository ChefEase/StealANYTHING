-- QA only: execute in Studio Server during Play. Stop Play removes this scene.
-- Six visual clones exercise replication and cleanup; they are not player-owned plots.
local assets = game.ServerStorage.Assets
local pack = assets.Task11MapTemplates
local plots = require(game.ReplicatedStorage.Shared.PlotDefinitions)
local definitions = require(game.ReplicatedStorage.Shared.Task11VisualDefinitions)
local CS = game:GetService("CollectionService")
local old = workspace:FindFirstChild("Task11VisualTestScene")
if old then old:Destroy() end
local function stage()
    local folder = Instance.new("Folder")
    folder.Name = "Task11VisualTestScene"
    folder.Parent = workspace
    local world = pack.SixPlotWorldTemplate:Clone()
    world.Name = "World"
    world:PivotTo(CFrame.new(2000,0,0))
    for _,d in world:GetDescendants() do if CS:HasTag(d,"MapSocket") then CS:RemoveTag(d,"MapSocket") end end
    world.Parent = folder
    task.wait()
    for i,slot in plots.Slots do
        local museum = pack.StarterMuseumTemplate:Clone()
        museum.Name = string.format("Museum%02d",i)
        local landscape = pack.LandscapePresets[definitions.Presets[i].id]:Clone()
        landscape.Name = "BackyardVisuals"
        landscape.Parent = museum
        museum:PivotTo(CFrame.new(Vector3.new(2000,0,0)+slot.center)*CFrame.Angles(0,math.rad(slot.yawDegrees),0))
        for _,d in museum:GetDescendants() do if CS:HasTag(d,"MapSocket") then CS:RemoveTag(d,"MapSocket") end end
        museum.Parent = folder
        task.wait()
    end
    return folder
end
local counts = {}
for i=1,3 do
    local f=stage()
    counts[i]=#f:GetDescendants()
    if i<3 then f:Destroy(); task.wait() end
end
assert(counts[1]==counts[2] and counts[2]==counts[3],"Visual clone count changed between cycles")
return game.HttpService:JSONEncode({cycles=3,descendantsPerCycle=counts,retainedScenes=1})
