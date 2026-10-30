-- Run in the museum game's Studio Edit mode after prepare_item_models.luau.
local Catalog = require(game.ReplicatedStorage.Shared.ItemCatalog)
local templates = game.ReplicatedStorage.VisualAssets:FindFirstChild("ItemModels")
local backups = game.ServerStorage.Assets:FindFirstChild("ItemSourceImports")
assert(templates and backups, "item templates or source backups missing")
assert(#templates:GetChildren() == 11 and #backups:GetChildren() == 11,
    "expected eleven imported models and backups")

local maximums = {
    Small = { height = 2.3, width = 2.8 },
    Medium = { height = 3.2, width = 4.0 },
    Heavy = { height = 4.3, width = 5.2 },
}
local checked = 0
for _, itemId in Catalog.OrderedIds do
    if itemId == "toaster" then continue end
    local model = templates:FindFirstChild(itemId)
    assert(model and model:IsA("Model") and model.PrimaryPart,
        "missing prepared model: " .. itemId)
    assert(model:GetAttribute("PreparedItemTemplate") == true)
    local class = model:GetAttribute("FootprintClass")
    assert(class == Catalog.ById[itemId].sizeClass,
        "template and catalog size classes differ: " .. itemId)
    local limit = maximums[class]
    assert(limit, "unknown footprint class: " .. itemId)
    local bounds = model:GetExtentsSize()
    assert(bounds.Y <= limit.height + 0.12
        and math.max(bounds.X, bounds.Z) <= limit.width + 0.12,
        "item exceeds its display footprint: " .. itemId)
    local meshes, welds, textured = 0, 0, 0
    for _, part in model:GetDescendants() do
        if part:IsA("MeshPart") then
            meshes += 1
            assert(not part.Anchored and not part.CanCollide and not part.CanQuery,
                "unsafe cosmetic part: " .. itemId .. "/" .. part.Name)
            if part.MaterialVariant ~= "" then
                textured += 1
                assert(game.MaterialService:GetMaterialVariant(part.Material,
                    part.MaterialVariant) ~= nil,
                    "unresolved material variant: " .. part.MaterialVariant)
            end
        elseif part:IsA("WeldConstraint") then
            welds += 1
            assert(part.Part0 and part.Part1, "incomplete weld on " .. itemId)
        end
    end
    assert(meshes > 0 and welds == meshes and textured > 0,
        "mesh, weld or texture coverage missing: " .. itemId)
    assert(model:FindFirstChild("MotionJoint", true), "animation rig missing: " .. itemId)
    checked += 1
end
assert(checked == 11)
print("Imported item model scale, weld, material and animation checks: PASS")
