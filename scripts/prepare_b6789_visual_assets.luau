-- Run in Studio Edit after importing B6-B9 and syncing Rojo.
-- Moves complete originals to server-only storage and rebuilds marked templates.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local assets = ServerStorage.Assets
local visualAssets = assert(ReplicatedStorage:FindFirstChild("VisualAssets"))
local sources = assets:FindFirstChild("B6789SourceImports")
if not sources then
    sources = Instance.new("Folder")
    sources.Name = "B6789SourceImports"
    sources.Parent = assets
end

local specs = {
    {"B6RockLow", "RockKit", "Rock"},
    {"B6RockTall", "RockKit", "Rock"},
    {"B6RockArch", "RockKit", "Rock"},
    {"B7SpotlightHousing", "LightingKit", "Light"},
    {"B8PedestalDetailedRing", "DisplayKit", "Pedestal"},
    {"B9Pallet", "ServiceKit", "Pallet"},
    {"B9ServiceCrate", "ServiceKit", "Crate"},
    {"B9Generator", "ServiceKit", "Generator"},
}

local module = assets.Task11VisualKit:Clone()
local kit = require(module)
for _, spec in specs do
    local name, folderName, kind = spec[1], spec[2], spec[3]
    local original = sources:FindFirstChild(name) or workspace:FindFirstChild(name)
    assert(original and original:IsA("Model"), "Missing imported B6-B9 Model: " .. name)
    if original.Parent == workspace then original.Parent = sources end
    for _, mesh in original:GetDescendants() do
        if mesh:IsA("MeshPart") then
            mesh.Anchored, mesh.Massless = true, true
            mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = false, false, false
        end
    end
    local folder = visualAssets:FindFirstChild(folderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = visualAssets
    end
    local old = folder:FindFirstChild(name)
    if old then
        assert(old:GetAttribute("B6789Template") == true,
            "Refusing to replace unmanaged template: " .. name)
        old:Destroy()
    end
    local copy = original:Clone()
    copy:SetAttribute("B6789Template", true)
    copy:SetAttribute("SourceImport", name)
    kit.ApplyB6789Palette(copy, kind)
    copy.Parent = folder
end
module:Destroy()
warn("B7 wall sconce import was not found; existing A2 sconce backplates and lit fixtures remain active")
print("B6-B9 cosmetic templates prepared; originals kept in ServerStorage.Assets.B6789SourceImports")
