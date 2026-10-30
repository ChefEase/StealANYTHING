--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance = require(ReplicatedStorage.Shared.BalanceConfig)
local Catalog = require(ReplicatedStorage.Shared.ItemCatalog)
local Contracts = require(ReplicatedStorage.Shared.ContractDefinitions)

local PublicDeliveryRules = {}

local function advance(contract: any, path: string)
    local definition = Contracts.ById[contract.definitionId]
    local target = definition and definition.requirementPaths[path]
    if target == nil then return end
    contract.progress[path] = math.min(target, contract.progress[path] + 1)
    for requirementPath, required in definition.requirementPaths do
        if contract.progress[requirementPath] >= required then
            contract.completed = true
            break
        end
    end
end

function PublicDeliveryRules.Apply(profile: any, itemId: string,
    nowUnix: number): (string, string)
    local item = Catalog.ById[itemId]
    if item == nil or profile.tutorialStep < 2 then return "Rejected", "NotEligible" end
    local duplicate = profile.exhibits[itemId] ~= nil
    if duplicate then
        local salvage = item.baseIncomePerMinute * Balance.DUPLICATE_SALVAGE_MINUTES
        if profile.cash > Balance.MAX_CASH - salvage
            or profile.lifetime.totalCashEarned > Balance.MAX_COUNTER - salvage then
            return "Rejected", "CashLimit"
        end
        profile.cash += salvage
        profile.lifetime.totalCashEarned += salvage
    else
        local stored = 0
        for ownedId, exhibit in pairs(profile.exhibits) do
            if exhibit.state == "Available" then
                local displayed = false
                for _, placedId in pairs(profile.displaySlots) do
                    if placedId == ownedId then displayed = true break end
                end
                if not displayed then stored += 1 end
            end
        end
        local capacity = Balance.STORAGE_SLOTS_BY_MUSEUM_TIER[profile.museum.tier]
            or Balance.STARTING_STORAGE_SLOTS
        local openSlot = if profile.displaySlots.exposed_01 == nil then "exposed_01"
            elseif profile.displaySlots.exposed_02 == nil then "exposed_02" else nil
        if stored >= capacity and openSlot == nil then
            return "Rejected", "StorageFull"
        end
        profile.exhibits[itemId] = {
            state = "Available",
            registeredAtUnix = nowUnix,
            acquisition = "Depot",
            recoveryJobsDone = 0,
        }
        profile.collectionIndex[itemId] = true
        profile.lifetime.distinctRegistered += 1
        if openSlot ~= nil then
            profile.publicDisplayApproved[itemId] = true
            profile.displaySlots[openSlot] = itemId
        end
    end
    profile.lifetime.npcDeliveries += 1
    for _, contract in profile.contracts do
        advance(contract, "npcDeliveries")
        if not duplicate then advance(contract, "newRegistrations") end
    end
    return "Committed", if duplicate then "DuplicateSalvaged" else "DepotRegistered"
end

return table.freeze(PublicDeliveryRules)
