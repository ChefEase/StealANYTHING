--!strict
-- Run in Studio Edit mode after Rojo sync. No real DataStore requests.

local Server = game:GetService("ServerScriptService").Server
local Repository = require(Server.Data.ProfileRepository)

local function copy(value: any): any
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

local function info(record: any)
    local answer = {}
    function answer:GetMetadata() return copy(if record then record.metadata else {}) end
    function answer:GetUserIds() return copy(if record then record.userIds else {}) end
    return answer
end

local FakeStore = {}
FakeStore.__index = FakeStore
function FakeStore.new()
    return setmetatable({ records = {}, failBefore = 0, failAfter = 0, replay = false,
        waitNext = 0 }, FakeStore)
end
function FakeStore:UpdateAsync(key: string, transform: (any, any) -> ...any)
    if self.waitNext > 0 then
        self.waitNext -= 1
        task.wait(0.1)
    end
    if self.failBefore > 0 then
        self.failBefore -= 1
        error("simulated failure before read")
    end
    local old = self.records[key]
    if self.replay then transform(copy(if old then old.value else nil), info(old)) end
    local value, userIds, metadata = transform(copy(if old then old.value else nil), info(old))
    if value == nil then return nil, info(old) end
    self.records[key] = { value = copy(value), userIds = copy(userIds), metadata = copy(metadata) }
    if self.failAfter > 0 then
        self.failAfter -= 1
        error("simulated lost response after commit")
    end
    return copy(value), info(self.records[key])
end

local nowUnix = 1_800_000_000
local function clock() return nowUnix end
local store = FakeStore.new()
local repo = Repository.New(store, clock, function() return "task4-session" end)
assert(select(2, repo:Load(401)) == "Ready")

-- The mutation runs once, even when UpdateAsync replays its transform or the ID repeats.
store.replay = true
local operationId = assert(repo:NewOperationId(401))
local mutateCalls = 0
local function award(profile: any): (string, string)
    mutateCalls += 1
    profile.cash += 10
    return "Committed", "Awarded"
end
local first, firstStatus = repo:ApplyOperation(401, operationId, "DepotDelivery", "run-401", award)
assert(firstStatus == "Committed" and first.result == "Committed")
local repeatResult, repeatStatus = repo:ApplyOperation(401, operationId, "DepotDelivery", "run-401", award)
assert(repeatStatus == "Repeated" and repeatResult.resultCode == "Awarded")
assert(mutateCalls == 1 and repo:GetSnapshot(401).cash == 110)
assert(store.records["player:401"].value.revision == 1)
assert(select(2, repo:ApplyOperation(401, operationId, "ShopPurchase", "run-401", award)) == "OperationConflict")

-- Routine state remains dirty until saved; release cannot discard it.
assert(repo:StageRoutine(401, function(profile: any) profile.cash += 5 end))
assert(repo:GetWriteState(401) == "Dirty")
assert(select(2, repo:Release(401)) == "PendingWrite")
assert(repo:SaveDirty(401))
assert(repo:GetWriteState(401) == "Saved")
assert(repo:Release(401))
local rejoin = Repository.New(store, clock, function() return "task4-rejoin" end)
local loaded, loadedStatus = rejoin:Load(401)
assert(loadedStatus == "Ready" and loaded.cash == 115 and loaded.revision == 2)
local replayAfterJoin, replayAfterJoinStatus = rejoin:ApplyOperation(401, operationId,
    "DepotDelivery", "run-401", function() error("must not run across joins") end)
assert(replayAfterJoinStatus == "Repeated" and replayAfterJoin.resultCode == "Awarded")
assert(select(2, rejoin:ApplyOperation(401, "task4-session:unused", "DepotDelivery",
    "run-402", award)) == "StaleOperation")
assert(rejoin:Release(401))

-- A failed write does not replace a stored profile; the same pending ID can retry.
local before = copy(store.records["player:401"].value)
repo = Repository.New(store, clock, function() return "task4-failure" end)
assert(select(2, repo:Load(401)) == "Ready")
operationId = assert(repo:NewOperationId(401))
store.failBefore = 1
local failed, failureStatus = repo:ApplyOperation(401, operationId, "ShopPurchase", "shop-401", function(profile: any)
    profile.cash -= 20
    return "Committed", "Bought"
end)
assert(failed == nil and failureStatus == "RetryableError")
assert(repo:GetWriteState(401) == "SaveError" and repo:GetSnapshot(401) == nil)
assert(store.records["player:401"].value.cash == before.cash)
assert(repo:Reconcile(401))
assert(repo:GetSnapshot(401).cash == before.cash - 20)
assert(repo:Release(401))

-- A response lost after commit reconciles by ID without a second spend.
repo = Repository.New(store, clock, function() return "task4-uncertain" end)
assert(select(2, repo:Load(401)) == "Ready")
operationId = assert(repo:NewOperationId(401))
store.failAfter = 1
local unknown, unknownStatus = repo:ApplyOperation(401, operationId, "ShopPurchase", "shop-402", function(profile: any)
    profile.cash -= 20
    return "Committed", "Bought"
end)
assert(unknown == nil and unknownStatus == "RetryableError")
local committedCash = store.records["player:401"].value.cash
assert(select(2, repo:Release(401)) == "PendingWrite")
local reconciled, reconciledStatus = repo:ApplyOperation(401, operationId, "ShopPurchase", "shop-402", function()
    error("mutator must not run again")
end)
assert(reconciledStatus == "Reconciled" and reconciled.resultCode == "Bought")
assert(repo:GetSnapshot(401).cash == committedCash)
assert(store.records["player:401"].value.cash == committedCash)
assert(repo:Release(401))

-- A lost response for routine autosave uses the write marker to reconcile.
repo = Repository.New(store, clock, function() return "task4-routine" end)
assert(select(2, repo:Load(401)) == "Ready")
assert(repo:StageRoutine(401, function(profile: any) profile.cash += 7 end))
store.failAfter = 1
assert(select(2, repo:SaveDirty(401)) == "RetryableError")
local savedCash = store.records["player:401"].value.cash
assert(repo:SaveDirty(401))
assert(repo:GetSnapshot(401).cash == savedCash and repo:GetWriteState(401) == "Saved")
assert(repo:Release(401))

-- Two concurrent operations enter the same per-profile queue and both survive.
repo = Repository.New(store, clock, function() return "task4-queue" end)
assert(select(2, repo:Load(401)) == "Ready")
local one = assert(repo:NewOperationId(401))
local two = assert(repo:NewOperationId(401))
local finished = 0
local outcomes = {}
store.waitNext = 1
task.spawn(function()
    outcomes[1] = select(2, repo:ApplyOperation(401, one, "DepotDelivery", "run-queue-1",
        function(profile: any)
            profile.cash += 1
            return "Committed", "One"
        end))
    finished += 1
end)
task.spawn(function()
    outcomes[2] = select(2, repo:ApplyOperation(401, two, "DepotDelivery", "run-queue-2",
        function(profile: any)
            profile.cash += 1
            return "Committed", "Two"
        end))
    finished += 1
end)
while finished < 2 do task.wait() end
assert(outcomes[1] == "Committed" and outcomes[2] == "Committed")
assert(store.records["player:401"].value.cash == savedCash + 2)
assert(repo:Release(401))

print("Task 4 serialized writes and reconciliation: PASS")
return "Task 4 serialized writes and reconciliation: PASS"
