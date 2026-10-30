--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Balance = require(Shared.BalanceConfig)
local Items = require(Shared.ItemCatalog)
local Contracts = require(Shared.ContractDefinitions)
local Upgrades = require(Shared.UpgradeDefinitions)
local Defaults = require(script.Parent.ProfileDefaults)
local TierOne = require(game:GetService("ReplicatedStorage").Shared.Task11TierOneContract)

local TOP_LEVEL_KEYS = {
    schemaVersion = true, revision = true, createdAtUnix = true, lastSavedAtUnix = true,
    cash = true, incomeRemainder = true, exhibits = true, displaySlots = true,
    collectionIndex = true, publicDisplayApproved = true, publicDisplayMode = true,
    accreditation = true, lifetime = true, tutorialStep = true,
    beginnerActiveSeconds = true, contracts = true, pinnedContractId = true,
    activeRecoveryType = true, settings = true, cosmetics = true,
    recentOperations = true, operationOrder = true, raidCycle = true, museum = true,
}
local EXHIBIT_KEYS = { state = true, registeredAtUnix = true, acquisition = true, missingOperationId = true, previousSlotId = true, recoveryJobsDone = true }
local CONTRACT_KEYS = { instanceId = true, definitionId = true, progress = true, assignedAtUnix = true, completed = true, claimed = true }
local OPERATION_KEYS = { kind = true, result = true, committedAtUnix = true, requestScope = true, resultCode = true }
local LIFETIME_KEYS = { npcDeliveries = true, pvpDeliveries = true, recoveryParcels = true, distinctRegistered = true, totalCashEarned = true }
local SETTINGS_KEYS = { masterVolume = true, musicVolume = true, effectsVolume = true, reduceMotion = true, lowEffects = true, travelTipsEnabled = true, collectionTutorialDone = true }
local RAID_KEYS = { phase = true, remainingSeconds = true }
local MUSEUM_KEYS = { version = true, tier = true, styleId = true,
    groundsPresetId = true, securityLevel = true }
local OPERATION_KINDS = {
    DepotDelivery = true, TutorialProgress = true, ShopPurchase = true, UpgradePurchase = true,
    RaidLoss = true, RecoveryParcel = true, RecoveryRestore = true,
    ContractClaim = true, ExhibitArrangement = true, WardrobePurchase = true,
}
local COSMETIC_IDS = { wall_palette = true, sign_style = true, frame_style = true,
    ski_mask = true, classic_outfit = true, street_outfit = true,
    tactical_outfit = true, getaway_bag = true, phantom_glow = true }
local SLOT_MIN_TIER = { protected = 0, exposed_01 = 0, exposed_02 = 0, exposed_03 = 0,
    exposed_04 = 1, exposed_05 = 1, exposed_06 = 2, exposed_07 = 2,
    exposed_08 = 3, exposed_09 = 3 }
local RAID_PHASE_MAX = {
    Protected = Balance.RAID_PROTECTED_SECONDS,
    Open = Balance.RAID_OPEN_SECONDS,
    RetryShield = Balance.RAID_RETRY_SHIELD_SECONDS,
}

local function reject(path: string, reason: string): (boolean, string)
    return false, path .. ": " .. reason
end

local function isFiniteNumber(value: any): boolean
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function isInteger(value: any, minimum: number, maximum: number): boolean
    return isFiniteNumber(value) and value % 1 == 0 and value >= minimum and value <= maximum
end

local function isShortId(value: any): boolean
    return type(value) == "string" and #value > 0 and #value <= 128
end

local function hasOnlyKeys(value: any, allowed: {[string]: boolean}): boolean
    if type(value) ~= "table" then
        return false
    end
    for key in pairs(value) do
        if type(key) ~= "string" or allowed[key] == nil then
            return false
        end
    end
    return true
end

local function isDenseArray(value: any, expectedLength: number): boolean
    if type(value) ~= "table" or #value ~= expectedLength then
        return false
    end
    local count = 0
    for key in pairs(value) do
        if not isInteger(key, 1, expectedLength) then
            return false
        end
        count += 1
    end
    return count == expectedLength
end

local function validate(value: any): (boolean, string?)
    if not hasOnlyKeys(value, TOP_LEVEL_KEYS) then
        return reject("profile", "not a plain current-schema record")
    end
    local profile = value :: {[string]: any}
    if profile.schemaVersion ~= Defaults.CurrentSchemaVersion then
        return reject("schemaVersion", "migration required or unknown version")
    end
    if not hasOnlyKeys(profile.museum, MUSEUM_KEYS) then
        return reject("museum", "invalid fields")
    end
    for key, expected in pairs(TierOne.Contract.defaults) do
        if profile.museum[key] ~= expected then
            return reject("museum." .. key, "unsupported tier-one configuration")
        end
    end
    if not isInteger(profile.revision, 0, Balance.MAX_COUNTER) then
        return reject("revision", "invalid counter")
    end
    if not isInteger(profile.createdAtUnix, 0, Balance.MAX_COUNTER)
        or not isInteger(profile.lastSavedAtUnix, profile.createdAtUnix, Balance.MAX_COUNTER) then
        return reject("timestamps", "invalid creation or save time")
    end
    if not isInteger(profile.cash, 0, Balance.MAX_CASH) then
        return reject("cash", "invalid balance")
    end
    if not isFiniteNumber(profile.incomeRemainder)
        or profile.incomeRemainder < 0 or profile.incomeRemainder >= 1 then
        return reject("incomeRemainder", "must be finite and in [0, 1)")
    end
    if not isInteger(profile.accreditation, 0, #Upgrades.OrderedIds) then
        return reject("accreditation", "invalid tier")
    end
    if not isInteger(profile.tutorialStep, 0, Balance.MAX_TUTORIAL_STEP)
        or not isInteger(profile.beginnerActiveSeconds, 0, Balance.MAX_COUNTER) then
        return reject("onboarding", "invalid step or active time")
    end

    if not hasOnlyKeys(profile.lifetime, LIFETIME_KEYS) then
        return reject("lifetime", "invalid fields")
    end
    for name in pairs(LIFETIME_KEYS) do
        if not isInteger(profile.lifetime[name], 0, Balance.MAX_COUNTER) then
            return reject("lifetime." .. name, "invalid counter")
        end
    end

    if type(profile.exhibits) ~= "table" then
        return reject("exhibits", "expected dictionary")
    end
    local exhibitCount = 0
    for itemId, exhibit in pairs(profile.exhibits) do
        if type(itemId) ~= "string" or Items.ById[itemId] == nil then
            return reject("exhibits", "unknown item ID")
        end
        exhibitCount += 1
        if not hasOnlyKeys(exhibit, EXHIBIT_KEYS) then
            return reject("exhibits." .. itemId, "invalid fields")
        end
        if exhibit.state ~= "Available" and exhibit.state ~= "Missing" then
            return reject("exhibits." .. itemId .. ".state", "unknown state")
        end
        if not isInteger(exhibit.registeredAtUnix, 0, Balance.MAX_COUNTER) then
            return reject("exhibits." .. itemId .. ".registeredAtUnix", "invalid time")
        end
        if exhibit.acquisition ~= "Tutorial" and exhibit.acquisition ~= "Depot" and exhibit.acquisition ~= "Shop" then
            return reject("exhibits." .. itemId .. ".acquisition", "unknown source")
        end
        if exhibit.acquisition == "Tutorial" and itemId ~= "toaster" then
            return reject("exhibits." .. itemId, "only toaster is a tutorial item")
        end
        if exhibit.acquisition == "Shop" and Items.ById[itemId].shopPrice == nil then
            return reject("exhibits." .. itemId, "item is not sold in shop")
        end
        if exhibit.previousSlotId ~= nil and SLOT_MIN_TIER[exhibit.previousSlotId] == nil then
            return reject("exhibits." .. itemId .. ".previousSlotId", "unknown slot")
        end
        if exhibit.state == "Missing" then
            if not isShortId(exhibit.missingOperationId) then
                return reject("exhibits." .. itemId, "missing operation ID required")
            end
            if not isInteger(exhibit.recoveryJobsDone, 0, Balance.RECOVERY_JOBS_REQUIRED - 1) then
                return reject("exhibits." .. itemId, "invalid recovery progress")
            end
        elseif exhibit.missingOperationId ~= nil or exhibit.previousSlotId ~= nil or exhibit.recoveryJobsDone ~= 0 then
            return reject("exhibits." .. itemId, "available exhibit retains missing-state fields")
        end
    end
    if exhibitCount > #Items.OrderedIds then
        return reject("exhibits", "too many owned types")
    end

    if type(profile.collectionIndex) ~= "table"
        or type(profile.publicDisplayApproved) ~= "table"
        or (profile.publicDisplayMode ~= "Auto" and profile.publicDisplayMode ~= "Manual") then
        return reject("collection", "invalid index or display preferences")
    end
    local indexCount = 0
    for itemId, discovered in pairs(profile.collectionIndex) do
        if Items.ById[itemId] == nil or discovered ~= true then
            return reject("collectionIndex", "unknown or invalid discovery")
        end
        indexCount += 1
    end
    for itemId, approved in pairs(profile.publicDisplayApproved) do
        if Items.ById[itemId] == nil or approved ~= true
            or profile.exhibits[itemId] == nil then
            return reject("publicDisplayApproved", "unknown or unowned item")
        end
    end
    if indexCount > #Items.OrderedIds
        or profile.lifetime.distinctRegistered ~= indexCount then
        return reject("collectionIndex", "discovery count mismatch")
    end
    for itemId in pairs(profile.exhibits) do
        if profile.collectionIndex[itemId] ~= true then
            return reject("collectionIndex", "owned item is undiscovered")
        end
    end

    if type(profile.displaySlots) ~= "table" then
        return reject("displaySlots", "expected dictionary")
    end
    local placedItems: {[string]: boolean} = {}
    for slotId, itemId in pairs(profile.displaySlots) do
        if type(slotId) ~= "string" or TierOne.Contract.socketNamesById[slotId] == nil then
            return reject("displaySlots", "unknown or locked slot")
        end
        if type(itemId) ~= "string" or profile.exhibits[itemId] == nil
            or profile.exhibits[itemId].state ~= "Available" then
            return reject("displaySlots." .. slotId, "item is not available")
        end
        if placedItems[itemId] then
            return reject("displaySlots." .. slotId, "duplicate item placement")
        end
        placedItems[itemId] = true
        if slotId ~= "protected" and profile.publicDisplayApproved[itemId] ~= true then
            return reject("displaySlots." .. slotId, "public display lacks approval")
        end
    end
    if profile.tutorialStep == 1 and profile.displaySlots.protected ~= "toaster" then
        return reject("displaySlots.protected", "tutorial toaster must earn first income")
    end
    local storedCount = 0
    for itemId, exhibit in pairs(profile.exhibits) do
        if exhibit.state == "Available" and not placedItems[itemId] then
            storedCount += 1
        end
    end
    local storageCapacity = Balance.STORAGE_SLOTS_BY_MUSEUM_TIER[profile.museum.tier]
    if storageCapacity == nil or storedCount > storageCapacity then
        return reject("storage", "capacity exceeded")
    end
    for itemId, exhibit in pairs(profile.exhibits) do
        if exhibit.previousSlotId ~= nil
            and TierOne.Contract.socketNamesById[exhibit.previousSlotId] == nil then
            return reject("exhibits." .. itemId .. ".previousSlotId", "unavailable slot")
        end
    end
    if profile.activeRecoveryType ~= nil then
        if type(profile.activeRecoveryType) ~= "string"
            or profile.exhibits[profile.activeRecoveryType] == nil
            or profile.exhibits[profile.activeRecoveryType].state ~= "Missing" then
            return reject("activeRecoveryType", "must identify a missing exhibit")
        end
    end

    if not isDenseArray(profile.contracts, 3) then
        return reject("contracts", "expected three active instances")
    end
    local contractInstances: {[string]: boolean} = {}
    local contractDefinitions: {[string]: boolean} = {}
    for index, contract in ipairs(profile.contracts) do
        local path = "contracts[" .. index .. "]"
        if not hasOnlyKeys(contract, CONTRACT_KEYS) then
            return reject(path, "invalid fields")
        end
        local definition = Contracts.ById[contract.definitionId]
        if not isShortId(contract.instanceId) or definition == nil then
            return reject(path, "unknown definition or invalid instance ID")
        end
        if contractInstances[contract.instanceId] or contractDefinitions[contract.definitionId] then
            return reject(path, "duplicate contract")
        end
        contractInstances[contract.instanceId] = true
        contractDefinitions[contract.definitionId] = true
        if not isInteger(contract.assignedAtUnix, 0, Balance.MAX_COUNTER)
            or type(contract.completed) ~= "boolean" or contract.claimed ~= false then
            return reject(path, "invalid assignment or claim state")
        end
        if not hasOnlyKeys(contract.progress, definition.requirementPaths) then
            return reject(path .. ".progress", "unknown requirement path")
        end
        local completed = false
        for requirementPath, target in pairs(definition.requirementPaths) do
            local count = contract.progress[requirementPath]
            if not isInteger(count, 0, target) then
                return reject(path .. ".progress." .. requirementPath, "invalid count")
            end
            if count == target then
                completed = true
            end
        end
        if contract.completed ~= completed then
            return reject(path .. ".completed", "does not match progress")
        end
    end
    if profile.pinnedContractId ~= nil and not contractInstances[profile.pinnedContractId] then
        return reject("pinnedContractId", "not an active instance")
    end

    if not hasOnlyKeys(profile.settings, SETTINGS_KEYS) then
        return reject("settings", "invalid fields")
    end
    for _, name in ipairs({ "masterVolume", "musicVolume", "effectsVolume" }) do
        local volume = profile.settings[name]
        if not isFiniteNumber(volume) or volume < 0 or volume > 1 then
            return reject("settings." .. name, "volume must be in [0, 1]")
        end
    end
    if type(profile.settings.reduceMotion) ~= "boolean" or type(profile.settings.lowEffects) ~= "boolean"
        or type(profile.settings.travelTipsEnabled) ~= "boolean"
        or type(profile.settings.collectionTutorialDone) ~= "boolean" then
        return reject("settings", "invalid accessibility flags")
    end
    if not hasOnlyKeys(profile.cosmetics, COSMETIC_IDS) then
        return reject("cosmetics", "unknown cosmetic ID")
    end
    for _, owned in pairs(profile.cosmetics) do
        if owned ~= true then
            return reject("cosmetics", "owned entries must be true")
        end
    end

    if type(profile.recentOperations) ~= "table" or type(profile.operationOrder) ~= "table" then
        return reject("recentOperations", "invalid operation ledger")
    end
    local operationCount = 0
    for operationId, operation in pairs(profile.recentOperations) do
        operationCount += 1
        if not isShortId(operationId) or not hasOnlyKeys(operation, OPERATION_KEYS) then
            return reject("recentOperations", "invalid operation entry")
        end
        if OPERATION_KINDS[operation.kind] ~= true
            or (operation.result ~= "Committed" and operation.result ~= "Rejected")
            or not isInteger(operation.committedAtUnix, 0, Balance.MAX_COUNTER)
            or not isShortId(operation.requestScope)
            or not isShortId(operation.resultCode) then
            return reject("recentOperations." .. operationId, "invalid operation result")
        end
    end
    if operationCount > Balance.MAX_OPERATION_HISTORY or not isDenseArray(profile.operationOrder, operationCount) then
        return reject("operationOrder", "invalid ledger length")
    end
    local orderedOperations: {[string]: boolean} = {}
    for _, operationId in ipairs(profile.operationOrder) do
        if not isShortId(operationId) or orderedOperations[operationId]
            or profile.recentOperations[operationId] == nil then
            return reject("operationOrder", "missing or repeated operation ID")
        end
        orderedOperations[operationId] = true
    end

    if not hasOnlyKeys(profile.raidCycle, RAID_KEYS) then
        return reject("raidCycle", "invalid fields")
    end
    local phaseMaximum = RAID_PHASE_MAX[profile.raidCycle.phase]
    if phaseMaximum == nil or not isFiniteNumber(profile.raidCycle.remainingSeconds)
        or profile.raidCycle.remainingSeconds < 0
        or profile.raidCycle.remainingSeconds > phaseMaximum then
        return reject("raidCycle", "invalid phase or remaining time")
    end

    return true, nil
end

return table.freeze({
    Validate = validate,
    SlotMinimumTier = table.freeze(SLOT_MIN_TIER),
})
