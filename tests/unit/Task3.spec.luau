--!strict
-- Run in Studio Edit mode after Rojo sync. Uses an in-memory DataStore fake only.
-- Fixture shapes mirror tests/fixtures/profile_*.json.

local Server = game:GetService("ServerScriptService").Server
local Repository = require(Server.Data.ProfileRepository)
local Schema = require(Server.Data.ProfileSchema)

local function copy(value: any): any
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

local function infoFor(record: any)
    local info = {}
    function info:GetMetadata() return copy(if record then record.metadata else {}) end
    function info:GetUserIds() return copy(if record then record.userIds else {}) end
    return info
end

local FakeStore = {}
FakeStore.__index = FakeStore
function FakeStore.new()
    return setmetatable({ records = {}, failBefore = 0, failAfter = 0, replayTransform = false }, FakeStore)
end
function FakeStore:UpdateAsync(key: string, transform: (any, any) -> ...any)
    if self.failBefore > 0 then
        self.failBefore -= 1
        error("simulated read failure")
    end
    local existing = self.records[key]
    local function invoke()
        return transform(copy(if existing then existing.value else nil), infoFor(existing))
    end
    if self.replayTransform then
        invoke() -- discarded retry, as UpdateAsync may repeat its callback
    end
    local value, userIds, metadata = invoke()
    if value == nil then
        return nil, infoFor(existing)
    end
    self.records[key] = { value = copy(value), userIds = copy(userIds), metadata = copy(metadata) }
    if self.failAfter > 0 then
        self.failAfter -= 1
        error("simulated lost response after commit")
    end
    return copy(value), infoFor(self.records[key])
end

local nowUnix = 1_700_000_500
local function clock(): number return nowUnix end
local function repository(store: any, token: string)
    return Repository.New(store, clock, function(): string return token end)
end

-- New profile: defaults are written only after a successful, absent-key read.
local store = FakeStore.new()
store.replayTransform = true
local serverA = repository(store, "server-A")
local fresh, status = serverA:Load(101)
assert(status == "Ready" and fresh.cash == 100 and #fresh.contracts == 3)
assert(Schema.Validate(fresh))
assert(store.records["player:101"].metadata.sessionToken == "server-A")
assert(store.records["player:101"].userIds[1] == 101)
assert(serverA:Load(101) == nil) -- no duplicate writable session on one server

local serverB = repository(store, "server-B")
local blocked, blockedStatus = serverB:Load(101)
assert(blocked == nil and blockedStatus == "Locked")
assert(serverA:Refresh(101))
assert(serverA:Release(101))
assert(store.records["player:101"].metadata.sessionToken == nil)
local rejoined, rejoinedStatus = serverB:Load(101)
assert(rejoinedStatus == "Ready" and rejoined.cash == 100)
assert(rejoined.contracts[1].instanceId == fresh.contracts[1].instanceId)
assert(serverB:Release(101))

-- A failed read must not become a new profile or overwrite an old one.
store = FakeStore.new()
store.records["player:102"] = {
    value = copy(fresh), metadata = {}, userIds = { 102 },
}
store.records["player:102"].value.cash = 731
store.failBefore = 1
serverA = repository(store, "read-failure")
local unavailable, unavailableStatus = serverA:Load(102)
assert(unavailable == nil and unavailableStatus == "RetryableError")
assert(store.records["player:102"].value.cash == 731)
local loaded, loadedStatus = serverA:Load(102)
assert(loadedStatus == "Ready" and loaded.cash == 731)
assert(serverA:Release(102))

store = FakeStore.new()
store.failBefore = 1
serverA = repository(store, "absent-read-failure")
assert(select(2, serverA:Load(202)) == "RetryableError")
assert(store.records["player:202"] == nil)
assert(select(2, serverA:Load(202)) == "Ready")
assert(serverA:Release(202))

-- Unknown commit outcome retries with the same token, not a second default.
store = FakeStore.new()
store.failAfter = 1
serverA = repository(store, "uncertain-token")
local uncertain, uncertainStatus = serverA:Load(103)
assert(uncertain == nil and uncertainStatus == "RetryableError")
local originalId = store.records["player:103"].value.contracts[1].instanceId
local reconciled, reconciledStatus = serverA:Load(103)
assert(reconciledStatus == "Ready" and reconciled.contracts[1].instanceId == originalId)
assert(serverA:Release(103))

-- Expired lease may be taken over; old owner then loses write access.
store = FakeStore.new()
serverA = repository(store, "stale-A")
serverB = repository(store, "stale-B")
assert(select(2, serverA:Load(104)) == "Ready")
nowUnix += Repository.LeaseSeconds + 1
assert(select(2, serverB:Load(104)) == "Ready")
local refreshed, refreshStatus = serverA:Refresh(104)
assert(not refreshed and refreshStatus == "Lost")
assert(serverA:GetSnapshot(104) == nil)
assert(select(2, serverA:Release(104)) == "Lost")
assert(serverB:Release(104))

-- Explicit version-0 fixture preserves cash, entitlements, recovery and settings.
local fullV0 = {
    schemaVersion = 0, revision = 7, createdAtUnix = 1_700_000_000,
    lastSavedAtUnix = 1_700_000_100, cash = 975, incomeRemainder = 0.25,
    registered = {
        toaster = { status = "Available", registeredAt = 1_700_000_001, recoveryJobsDone = 0 },
        gold_toilet = { status = "Missing", registeredAt = 1_700_000_002,
            missingOperationId = "legacy-raid-1", recoveryJobsDone = 2 },
    },
    displaySlots = { protected = "toaster", exposed_01 = "gold_toilet" },
    accreditation = 1,
    lifetime = { npcDeliveries = 6, pvpDeliveries = 1, recoveryParcels = 2,
        distinctRegistered = 2, totalCashEarned = 1400 },
    tutorialStep = 9, beginnerActiveSeconds = 600,
    settings = { masterVolume = 0.8, musicVolume = 0.5, effectsVolume = 1,
        reduceMotion = true, lowEffects = false },
    cosmetics = { wall_palette = true },
    raidCycle = { phase = "Protected", remainingSeconds = 42 },
}
store = FakeStore.new()
store.records["player:105"] = { value = copy(fullV0), metadata = { auditTag = "keep" }, userIds = { 105 } }
serverA = repository(store, "migration")
local migrated, migrationStatus = serverA:Load(105)
assert(migrationStatus == "Ready" and migrated.schemaVersion == 5)
assert(migrated.cash == 975 and migrated.accreditation == 1)
assert(migrated.displaySlots.protected == "toaster")
assert(migrated.displaySlots.exposed_01 == nil)
assert(migrated.exhibits.gold_toilet.state == "Missing")
assert(migrated.exhibits.gold_toilet.previousSlotId == "exposed_01")
assert(migrated.exhibits.gold_toilet.recoveryJobsDone == 2)
assert(migrated.settings.musicVolume == 0.5 and migrated.lifetime.npcDeliveries == 6)
assert(store.records["player:105"].metadata.auditTag == "keep")
assert(Schema.Validate(migrated))
assert(serverA:Release(105))

-- Partial old records receive only defined defaults; valid progress remains.
store = FakeStore.new()
store.records["player:106"] = { value = { schemaVersion = 0, cash = 47,
    registered = { duck = { status = "Available", registeredAt = 1_700_000_003 } } },
    metadata = {}, userIds = { 106 } }
serverA = repository(store, "partial")
local partial, partialStatus = serverA:Load(106)
assert(partialStatus == "Ready" and partial.cash == 47)
assert(partial.exhibits.duck.state == "Available" and partial.lifetime.distinctRegistered == 1)
assert(partial.settings.masterVolume == 1 and #partial.contracts == 3)
assert(serverA:Release(106))

-- A future or malformed profile is left untouched, never reset to defaults.
store = FakeStore.new()
store.records["player:107"] = { value = { schemaVersion = 6, cash = 99999,
    registered = {} }, metadata = {}, userIds = { 107 } }
serverA = repository(store, "future")
local bad, badStatus = serverA:Load(107)
assert(bad == nil and badStatus == "CorruptProfile")
assert(store.records["player:107"].value.cash == 99999)
assert(store.records["player:107"].metadata.sessionToken == nil)

print("Task 3 profile load, lease, and migration: PASS")
return "Task 3 profile load, lease, and migration: PASS"
