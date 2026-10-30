--!strict
-- Run in Studio's Edit command context after Rojo sync. No profile is written.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Shared = ReplicatedStorage.Shared
local Server = ServerScriptService.Server

local Balance = require(Shared.BalanceConfig)
local Items = require(Shared.ItemCatalog)
local Contracts = require(Shared.ContractDefinitions)
local Upgrades = require(Shared.UpgradeDefinitions)
local Remotes = require(Shared.RemoteDefinitions)
local Defaults = require(Server.Data.ProfileDefaults)
local Schema = require(Server.Data.ProfileSchema)
local Environment = require(Server.Config.EnvironmentConfig)
local Flags = require(Server.Config.FeatureFlags)
local AssetIds = require(Server.Config.AssetIds)

local nextId = 0
local function newId(): string
    nextId += 1
    return "task2-test-" .. nextId
end

local function fresh(): any
    return Defaults.Create(1_700_000_000, newId)
end

local function mustReject(profile: any, expectedPath: string)
    local valid, reason = Schema.Validate(profile)
    assert(not valid and type(reason) == "string" and string.find(reason, expectedPath, 1, true),
        "expected rejection at " .. expectedPath .. ", got " .. tostring(reason))
end

assert(Defaults.CurrentSchemaVersion == 5)
assert(Balance.STARTING_CASH == 100)
assert(Environment.Environment == "development")
assert(Environment.StoreName == "StealAnything_Dev_v1")
assert(Environment.StoreNames.development ~= Environment.StoreNames.production)
assert(Flags.PvpEnabled == false and Flags.MonetizationEnabled == false)
assert(AssetIds.SupporterPass == AssetIds.Unassigned)

local itemCount = 0
local depotWeight = 0
local shopCount = 0
local itemIds: {[string]: boolean} = {}
for _, itemId in ipairs(Items.OrderedIds) do
    local item = Items.ById[itemId]
    assert(not itemIds[itemId] and item ~= nil and item.id == itemId)
    itemIds[itemId] = true
    assert(item.modelKey == itemId and item.iconKey == itemId)
    assert(AssetIds.CollectibleModels[itemId] == AssetIds.Unassigned)
    assert(AssetIds.CollectibleIcons[itemId] == AssetIds.Unassigned)
    itemCount += 1
    depotWeight += item.depotWeight
    if item.shopPrice ~= nil then
        shopCount += 1
    end
end
assert(itemCount == 12 and depotWeight == 100 and shopCount == 4)

local contractIds: {[string]: boolean} = {}
for _, contractId in ipairs(Contracts.OrderedIds) do
    assert(not contractIds[contractId] and Contracts.ById[contractId].id == contractId)
    contractIds[contractId] = true
end
assert(#Contracts.OrderedIds == 6)

local unlockedSlots: {[string]: boolean} = {}
local upgradeIds: {[string]: boolean} = {}
for tier, upgradeId in ipairs(Upgrades.OrderedIds) do
    local upgrade = Upgrades.ById[upgradeId]
    assert(not upgradeIds[upgradeId] and upgrade.id == upgradeId and upgrade.tier == tier)
    upgradeIds[upgradeId] = true
    for _, slotId in ipairs(upgrade.unlockedSlots) do
        assert(not unlockedSlots[slotId])
        unlockedSlots[slotId] = true
    end
end
assert(#Upgrades.OrderedIds == 3)
local slotCount = 0
for _ in pairs(unlockedSlots) do slotCount += 1 end
assert(slotCount == 6)

local requestCount = 0
for key, name in pairs(Remotes.Requests) do
    assert(key == name)
    requestCount += 1
end
assert(requestCount == 17) -- Collection reads, arrangements and tutorial completion are owner-scoped.

local valid, reason = Schema.Validate(fresh())
assert(valid, tostring(reason))

local profile = fresh()
profile.cash = math.huge
mustReject(profile, "cash")

profile = fresh()
profile.cash = 0 / 0
mustReject(profile, "cash")

profile = fresh()
profile.raidCycle.phase = "Invisible"
mustReject(profile, "raidCycle")

profile = fresh()
profile.exhibits.toaster = { state = "Invalid", registeredAtUnix = 1_700_000_000,
    acquisition = "Tutorial", recoveryJobsDone = 0 }
profile.lifetime.distinctRegistered = 1
mustReject(profile, "exhibits.toaster.state")

profile = fresh()
profile.exhibits.toaster = { state = "Available", registeredAtUnix = 1_700_000_000,
    acquisition = "Tutorial", recoveryJobsDone = 0 }
profile.lifetime.distinctRegistered = 1
profile.collectionIndex.toaster = true
profile.publicDisplayApproved.toaster = true
profile.displaySlots.protected = "toaster"
profile.displaySlots.exposed_01 = "toaster"
mustReject(profile, "duplicate item placement")

profile = fresh()
profile.contracts[1].progress.npcDeliveries = math.huge
mustReject(profile, "contracts[1].progress.npcDeliveries")

print("Task 2 definitions and profile schema: PASS")
return "Task 2 definitions and profile schema: PASS"
