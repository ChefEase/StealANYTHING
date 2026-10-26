--!strict
-- Run in Studio Edit mode after Rojo sync. Uses an in-memory DataStore adapter.

local Server = game:GetService("ServerScriptService").Server
local Repository = require(Server.Data.ProfileRepository)
local Schema = require(Server.Data.ProfileSchema)
local IncomeMath = require(Server.Domain.IncomeMath)
local DeliveryRules = require(Server.Domain.TutorialDeliveryRules)
local TutorialProgress = require(Server.Domain.TutorialProgress)

local function copy(value: any): any
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in value do result[key] = copy(child) end
    return result
end

local function info(record: any)
    local result = {}
    function result:GetMetadata() return copy(if record then record.metadata else {}) end
    function result:GetUserIds() return copy(if record then record.userIds else {}) end
    return result
end

local store: any = { records = {} }
function store:UpdateAsync(key: string, transform: (any, any) -> ...any)
    local old = self.records[key]
    local value, userIds, metadata = transform(copy(if old then old.value else nil), info(old))
    if value == nil then return nil, info(old) end
    self.records[key] = { value = copy(value), userIds = copy(userIds), metadata = copy(metadata) }
    return copy(value), info(self.records[key])
end

local unix = 1_800_000_000
local repo = Repository.New(store, function() return unix end, function() return "tutorial-session" end)
local initial, status = repo:Load(707)
assert(status == "Ready" and initial.cash == 100 and initial.tutorialStep == 0)
assert(IncomeMath.RatePerMinute(initial) == 0)
assert(TutorialProgress.FirstItemGuardProtected(initial))

local operationId = assert(repo:NewOperationId(707))
local result, committed = repo:ApplyOperation(707, operationId, "DepotDelivery", "personal-run-707",
    function(profile: any)
        return DeliveryRules.Apply(profile, unix)
    end)
assert(committed == "Committed" and result.resultCode == "TutorialRegistered")
local delivered = assert(repo:GetSnapshot(707))
assert(Schema.Validate(delivered))
assert(delivered.tutorialStep == 1 and delivered.lifetime.npcDeliveries == 1)
assert(delivered.lifetime.distinctRegistered == 1)
assert(delivered.exhibits.toaster.acquisition == "Tutorial")
assert(delivered.displaySlots.protected == "toaster")
assert(delivered.cash == 100 and IncomeMath.RatePerMinute(delivered) == 6)
assert(not TutorialProgress.FirstItemGuardProtected(delivered))
assert(delivered.contracts[1].progress.npcDeliveries == 1)
assert(delivered.contracts[2].progress.newRegistrations == 1)
assert(delivered.contracts[2].completed)

-- The museum tier is a future profile field. Exercise the pure income rule with
-- both target tier values before the schema migration in Task 12.
local tierOne = copy(delivered)
tierOne.museumTier = 1
local tierFive = copy(delivered)
tierFive.museumTier = 5
assert(IncomeMath.RatePerMinute(tierOne) == 6)
assert(IncomeMath.RatePerMinute(tierFive) == 6)
assert(IncomeMath.Accrue(tierOne, 10) == 1)
assert(IncomeMath.Accrue(tierFive, 10) == 1)
local stored = copy(tierFive)
stored.displaySlots.protected = nil
assert(IncomeMath.RatePerMinute(stored) == 0)
local missing = copy(tierFive)
missing.exhibits.toaster.state = "Missing"
assert(IncomeMath.RatePerMinute(missing) == 0)

local repeatResult, repeated = repo:ApplyOperation(707, operationId, "DepotDelivery",
    "personal-run-707", function() error("a repeated delivery must not mutate") end)
assert(repeated == "Repeated" and repeatResult.resultCode == "TutorialRegistered")
local secondId = assert(repo:NewOperationId(707))
local duplicate, duplicateStatus = repo:ApplyOperation(707, secondId, "DepotDelivery", "another-run",
    function(profile: any) return DeliveryRules.Apply(profile, unix) end)
assert(duplicateStatus == "Committed" and duplicate.result == "Rejected")
assert(repo:GetSnapshot(707).lifetime.npcDeliveries == 1)

assert(repo:StageRoutine(707, function(profile: any)
    local earned = IncomeMath.Accrue(profile, 5)
    assert(earned == 0)
    assert(profile.tutorialStep == 1)
    assert(profile.incomeRemainder == 0.5)
end))
assert(repo:StageRoutine(707, function(profile: any)
    local earned = IncomeMath.Accrue(profile, 5)
    assert(earned == 1)
    assert(profile.tutorialStep == 1)
end))
local firstIncomeOperation = assert(repo:NewOperationId(707))
local firstIncomeResult, firstIncomeStatus = repo:ApplyOperation(707, firstIncomeOperation,
    "TutorialProgress", "first-display-income", function(profile: any)
        assert(TutorialProgress.OnIncomeSettled(profile, profile.lifetime.totalCashEarned))
        return "Committed", "FirstIncomeSeen"
    end)
assert(firstIncomeStatus == "Committed" and firstIncomeResult.resultCode == "FirstIncomeSeen")
local firstIncomeRepeat, firstIncomeRepeatStatus = repo:ApplyOperation(707,
    firstIncomeOperation, "TutorialProgress", "first-display-income",
    function() error("tutorial step must not advance twice") end)
assert(firstIncomeRepeatStatus == "Repeated" and firstIncomeRepeat.resultCode == "FirstIncomeSeen")
assert(not TutorialProgress.OnIncomeSettled(repo:GetSnapshot(707), 1))
assert(repo:GetSnapshot(707).cash == 101)
assert(repo:GetSnapshot(707).lifetime.totalCashEarned == 1)
local illegalAdvance, illegalReason = repo:StageRoutine(707, function(profile: any)
    profile.tutorialStep = 3
end)
assert(not illegalAdvance and illegalReason == "InvalidMutation")
assert(repo:SaveDirty(707))
assert(repo:Release(707))

unix += 3_600 -- Time offline must not generate income.
local rejoin = Repository.New(store, function() return unix end, function() return "tutorial-rejoin" end)
local loaded, loadedStatus = rejoin:Load(707)
assert(loadedStatus == "Ready" and Schema.Validate(loaded))
assert(loaded.cash == 101 and IncomeMath.RatePerMinute(loaded) == 6)
assert(loaded.lifetime.totalCashEarned == 1)
assert(loaded.tutorialStep == 2 and loaded.displaySlots.protected == "toaster")
assert(loaded.lifetime.npcDeliveries == 1 and loaded.lifetime.distinctRegistered == 1)
assert(rejoin:Release(707))

print("Tutorial delivery, income, and rejoin: PASS")
return "Tutorial delivery, income, and rejoin: PASS"
