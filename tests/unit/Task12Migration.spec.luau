--!strict
-- Run in Studio Edit mode after Rojo sync. No DataStore access.
local Server = game:GetService("ServerScriptService").Server
local Defaults = require(Server.Data.ProfileDefaults)
local Migration = require(Server.Data.ProfileMigration)
local Schema = require(Server.Data.ProfileSchema)
local IncomeMath = require(Server.Domain.IncomeMath)

local counter = 0
local function nextId(): string
    counter += 1
    return "task12:" .. counter
end
local function legacy(): any
    local profile = Defaults.Create(1_700_000_000, nextId)
    profile.schemaVersion = 1
    profile.museum = nil
    return profile
end

local empty = legacy()
empty.cash = 791
empty.incomeRemainder = 0.4
local migrated = assert(Migration.Migrate(empty, 1_700_000_100, nextId))
assert(Schema.Validate(migrated))
assert(migrated.schemaVersion == 5 and migrated.museum.tier == 1)
assert(migrated.settings.travelTipsEnabled == true)
assert(migrated.cash == 791 and migrated.incomeRemainder == 0.4)
assert(migrated.contracts[1].instanceId == empty.contracts[1].instanceId)
assert(migrated.createdAtUnix == empty.createdAtUnix)

local displayed = legacy()
displayed.exhibits.toaster = { state = "Available", registeredAtUnix = 1_700_000_001,
    acquisition = "Tutorial", recoveryJobsDone = 0 }
displayed.lifetime.distinctRegistered = 1
displayed.displaySlots.protected = "toaster"
local restored = assert(Migration.Migrate(displayed, 1_700_000_100, nextId))
assert(restored.displaySlots.protected == "toaster" and IncomeMath.RatePerMinute(restored) == 6)

local unavailable = legacy()
unavailable.exhibits.duck = { state = "Available", registeredAtUnix = 1_700_000_001,
    acquisition = "Depot", recoveryJobsDone = 0 }
unavailable.lifetime.distinctRegistered = 1
unavailable.displaySlots.exposed_03 = "duck"
local stored = assert(Migration.Migrate(unavailable, 1_700_000_100, nextId))
assert(Schema.Validate(stored))
assert(stored.exhibits.duck.state == "Available" and stored.displaySlots.exposed_03 == nil)
assert(IncomeMath.RatePerMinute(stored) == 0)

local missing = legacy()
missing.exhibits.duck = { state = "Missing", registeredAtUnix = 1_700_000_001,
    acquisition = "Depot", missingOperationId = "raid:1", previousSlotId = "exposed_03",
    recoveryJobsDone = 1 }
missing.lifetime.distinctRegistered = 1
missing.activeRecoveryType = "duck"
local recovered = assert(Migration.Migrate(missing, 1_700_000_100, nextId))
assert(Schema.Validate(recovered))
assert(recovered.exhibits.duck.previousSlotId == nil)
assert(recovered.exhibits.duck.missingOperationId == "raid:1")
assert(recovered.activeRecoveryType == "duck")

local invalid = legacy()
invalid.exhibits.not_real = { state = "Available", registeredAtUnix = 0,
    acquisition = "Depot", recoveryJobsDone = 0 }
assert(Migration.Migrate(invalid, 1_700_000_100, nextId) == nil)
local previous = Defaults.Create(1_700_000_000, nextId)
previous.schemaVersion = 2
previous.settings.travelTipsEnabled = nil
local upgraded = assert(Migration.Migrate(previous, 1_700_000_100, nextId))
assert(upgraded.schemaVersion == 5 and upgraded.settings.travelTipsEnabled == true)
local v4 = Defaults.Create(1_700_000_000, nextId)
v4.schemaVersion = 4
v4.settings.collectionTutorialDone = nil
local v5 = assert(Migration.Migrate(v4, 1_700_000_100, nextId))
assert(v5.schemaVersion == 5 and v5.settings.collectionTutorialDone == false)
local oldCurrent = Defaults.Create(1_700_000_000, nextId)
oldCurrent.schemaVersion = 3
oldCurrent.collectionIndex = nil
oldCurrent.publicDisplayApproved = nil
oldCurrent.publicDisplayMode = nil
oldCurrent.exhibits.toaster = { state = "Available", registeredAtUnix = 1_700_000_001,
    acquisition = "Tutorial", recoveryJobsDone = 0 }
oldCurrent.exhibits.duck = { state = "Available", registeredAtUnix = 1_700_000_001,
    acquisition = "Depot", recoveryJobsDone = 0 }
oldCurrent.lifetime.distinctRegistered = 2
oldCurrent.displaySlots.protected = "toaster"
oldCurrent.displaySlots.exposed_01 = "duck"
local newCurrent = assert(Migration.Migrate(oldCurrent, 1_700_000_100, nextId))
assert(newCurrent.collectionIndex.toaster and newCurrent.collectionIndex.duck)
assert(newCurrent.publicDisplayApproved.duck and newCurrent.publicDisplayMode == "Auto")
assert(Schema.Validate(newCurrent))
assert(Migration.Migrate({ schemaVersion = 6 }, 1_700_000_100, nextId) == nil)

print("Task 12 profile migration: PASS")
return "Task 12 profile migration: PASS"
