--!strict

local Contracts = require(game:GetService("ReplicatedStorage").Shared.ContractDefinitions)

local TutorialDeliveryRules = {}

local function advance(contract: any, path: string)
    local definition = Contracts.ById[contract.definitionId]
    local target = definition and definition.requirementPaths[path]
    if target ~= nil then
        contract.progress[path] = math.min(target, contract.progress[path] + 1)
        for requirementPath, required in definition.requirementPaths do
            if contract.progress[requirementPath] >= required then
                contract.completed = true
                break
            end
        end
    end
end

function TutorialDeliveryRules.Apply(profile: any, nowUnix: number): (string, string)
    if profile.exhibits.toaster ~= nil or profile.tutorialStep ~= 0
        or profile.displaySlots.protected ~= nil then
        return "Rejected", "AlreadyRegistered"
    end

    profile.exhibits.toaster = {
        state = "Available",
        registeredAtUnix = nowUnix,
        acquisition = "Tutorial",
        recoveryJobsDone = 0,
    }
    profile.displaySlots.protected = "toaster"
    profile.lifetime.npcDeliveries += 1
    profile.lifetime.distinctRegistered += 1
    profile.tutorialStep = 1
    for _, contract in profile.contracts do
        advance(contract, "npcDeliveries")
        advance(contract, "newRegistrations")
    end
    return "Committed", "TutorialRegistered"
end

return table.freeze(TutorialDeliveryRules)
