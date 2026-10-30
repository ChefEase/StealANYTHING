--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Balance = require(Shared.BalanceConfig)
local Contracts = require(Shared.ContractDefinitions)
local Types = require(Shared.Types)
local TierOne = require(Shared.Task11TierOneContract)

type PlayerProfile = Types.PlayerProfile

local CURRENT_SCHEMA_VERSION = 5

local function newContract(definitionId: string, nowUnix: number, newId: () -> string): Types.Contract
    local definition = Contracts.ById[definitionId]
    assert(definition ~= nil, "unknown starter contract")
    local progress: {[string]: number} = {}
    for path in pairs(definition.requirementPaths) do
        progress[path] = 0
    end
    return {
        instanceId = newId(),
        definitionId = definitionId,
        progress = progress,
        assignedAtUnix = nowUnix,
        completed = false,
        claimed = false,
    }
end

local function create(nowUnix: number, newId: () -> string): PlayerProfile
    assert(type(nowUnix) == "number" and nowUnix == nowUnix
        and nowUnix >= 0 and nowUnix <= Balance.MAX_COUNTER and nowUnix % 1 == 0,
        "invalid server time")
    local activeContracts: {Types.Contract} = {}
    for _, definitionId in ipairs(Contracts.StarterIds) do
        table.insert(activeContracts, newContract(definitionId, nowUnix, newId))
    end

    return {
        schemaVersion = CURRENT_SCHEMA_VERSION,
        revision = 0,
        createdAtUnix = nowUnix,
        lastSavedAtUnix = nowUnix,
        cash = Balance.STARTING_CASH,
        incomeRemainder = 0,
        exhibits = {},
        displaySlots = {},
        collectionIndex = {},
        publicDisplayApproved = {},
        publicDisplayMode = "Auto",
        museum = table.clone(TierOne.Contract.defaults),
        accreditation = 0,
        lifetime = {
            npcDeliveries = 0,
            pvpDeliveries = 0,
            recoveryParcels = 0,
            distinctRegistered = 0,
            totalCashEarned = 0,
        },
        tutorialStep = 0,
        beginnerActiveSeconds = 0,
        contracts = activeContracts,
        pinnedContractId = nil,
        activeRecoveryType = nil,
        settings = {
            masterVolume = 1,
            musicVolume = 1,
            effectsVolume = 1,
            reduceMotion = false,
            lowEffects = false,
            travelTipsEnabled = true,
            collectionTutorialDone = false,
        },
        cosmetics = {},
        recentOperations = {},
        operationOrder = {},
        raidCycle = {
            phase = "Protected",
            remainingSeconds = Balance.RAID_PROTECTED_SECONDS,
        },
    }
end

return table.freeze({
    CurrentSchemaVersion = CURRENT_SCHEMA_VERSION,
    Create = create,
})
