--!strict

local Types = require(script.Parent.Types)
type ContractDefinition = Types.ContractDefinition

local orderedIds = {
    "local_courier", "awkward_cargo", "quiet_route", "new_exhibit", "museum_worker", "daring_run",
}

local byId: {[string]: ContractDefinition} = {
    local_courier = {
        id = "local_courier", name = "Local Courier", requirementPaths = { npcDeliveries = 2 }, cashReward = 100, eligibility = "Always",
    },
    awkward_cargo = {
        id = "awkward_cargo", name = "Awkward Cargo", requirementPaths = { heavyNpcDeliveries = 1 }, cashReward = 80, eligibility = "Always",
    },
    quiet_route = {
        id = "quiet_route", name = "Quiet Route", requirementPaths = { quietNpcDeliveries = 1 }, cashReward = 100, eligibility = "Always",
    },
    new_exhibit = {
        id = "new_exhibit", name = "New Exhibit", requirementPaths = { newRegistrations = 1 }, cashReward = 150, eligibility = "UnownedObtainableItem",
    },
    museum_worker = {
        id = "museum_worker", name = "Museum Worker", requirementPaths = { recoveryParcels = 1, npcDeliveries = 2 }, cashReward = 80, eligibility = "Always",
    },
    daring_run = {
        id = "daring_run", name = "Daring Run", requirementPaths = { eligiblePvpDeliveries = 1, npcDeliveries = 3 }, cashReward = 160, eligibility = "Always",
    },
}

for _, definition in pairs(byId) do
    table.freeze(definition.requirementPaths)
    table.freeze(definition)
end

return table.freeze({
    OrderedIds = table.freeze(orderedIds),
    StarterIds = table.freeze({ "local_courier", "new_exhibit", "museum_worker" }),
    ById = table.freeze(byId),
})
