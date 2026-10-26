--!strict

local Types = require(script.Parent.Types)
type UpgradeDefinition = Types.UpgradeDefinition

local orderedIds = { "local_attraction", "town_landmark", "grand_collection" }
local byId: {[string]: UpgradeDefinition} = {
    local_attraction = {
        id = "local_attraction", tier = 1, name = "Local Attraction", cost = 1_200,
        requirementPaths = { successfulDeliveries = 6 },
        unlockedSlots = { "exposed_04", "exposed_05" }, cosmeticId = "wall_palette",
    },
    town_landmark = {
        id = "town_landmark", tier = 2, name = "Town Landmark", cost = 4_000,
        requirementPaths = { npcDeliveries = 12, distinctRegistered = 6 },
        unlockedSlots = { "exposed_06", "exposed_07" }, cosmeticId = "sign_style",
    },
    grand_collection = {
        id = "grand_collection", tier = 3, name = "Grand Collection", cost = 10_000,
        requirementPaths = { npcDeliveries = 25, distinctRegistered = 10 },
        unlockedSlots = { "exposed_08", "exposed_09" }, cosmeticId = "frame_style",
    },
}

for _, definition in pairs(byId) do
    table.freeze(definition.requirementPaths)
    table.freeze(definition.unlockedSlots)
    table.freeze(definition)
end

return table.freeze({
    OrderedIds = table.freeze(orderedIds),
    ById = table.freeze(byId),
})
