-- Run in Studio Edit after syncing the game project.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Server = game:GetService("ServerScriptService").Server
local Balance = require(ReplicatedStorage.Shared.BalanceConfig)
local Catalog = require(ReplicatedStorage.Shared.ItemCatalog)
local Defaults = require(Server.Data.ProfileDefaults)
local TutorialDelivery = require(Server.Domain.TutorialDeliveryRules)
local IncomeMath = require(Server.Domain.IncomeMath)
local Stock = require(Server.Services.PublicStockState)
local CarryState = require(Server.Services.TutorialCarryState)
local Delivery = require(Server.Domain.PublicDeliveryRules)
local BestDisplays = require(Server.Domain.BestPublicDisplays)
local Arrangement = require(Server.Domain.ExhibitArrangementRules)
local Schema = require(Server.Data.ProfileSchema)

local now = 0
local choices = { "duck", "traffic_cone", "jelly_lamp", "mini_ufo" }
local nextChoice = 0
local function choose()
    nextChoice += 1
    return choices[nextChoice] or "duck"
end
local stock = Stock.New(function() return now end, choose,
    { "depot.public_01", "depot.public_02", "depot.public_03" })
local id = "depot.public_01"
assert(stock:Get(id).itemId == "duck")
assert(stock:Begin(id, 101, "a"))
assert(stock:Begin(id, 202, "b"))
local first = stock:Claim(id, 202, "b", "run-b")
local second = stock:Claim(id, 101, "a", "run-a")
assert(first == "duck" and second == nil, "only first valid finisher gets stock")
assert(stock:Get(id).itemId == nil)
assert(stock:Claim(id, 202, "b", "run-b") == nil, "run cannot claim twice")
now = 5
assert(stock:Fail("run-b"))
assert(not stock:Fail("run-b"), "failed run can be cleaned only once")
now = 24
stock:Tick()
assert(stock:Get(id).itemId == nil, "failed run must wait for restock")
now = 25
stock:Tick()
assert(stock:Get(id).itemId ~= nil)

local rotated = stock:Get(id).itemId
assert(stock:Begin(id, 101, "hold"))
now += Balance.DEPOT_ROTATION_SECONDS + 1
stock:Tick()
assert(stock:Get(id).itemId == rotated, "pickup hold blocks rotation")
stock:Cancel(id, 101, "hold")
stock:Tick()
assert(stock:Get(id).itemId ~= rotated, "untouched stock rotates after hold ends")

local serial = 0
local carries = CarryState.New(function() return now end, function()
    serial += 1
    return "server-id-" .. tostring(serial)
end)
local pending = carries:Begin(101, "pickup-a", id, "duck")
assert(pending ~= nil)
carries:Trigger(101)
now += Balance.PICKUP_HOLD_SECONDS
local firstCarry = carries:Complete(101, "pickup-a")
assert(firstCarry ~= nil and firstCarry.itemId == "duck")
assert(carries:Drop(101, firstCarry.carryId))
local nextPending = carries:Begin(101, "pickup-b", id, "jelly_lamp")
assert(nextPending ~= nil and nextPending.runId ~= firstCarry.runId)
assert(not carries:Drop(101, firstCarry.carryId),
    "an old carry ID cannot remove or deliver a later run")

local nextId = 0
local profile = Defaults.Create(1000, function()
    nextId += 1
    return "contract-" .. tostring(nextId)
end)
profile.tutorialStep = 1
assert(Delivery.Apply(profile, "duck", 1000) == "Rejected",
    "public stock stays locked until the first displayed dollar")
profile.tutorialStep = 2
local result, code = Delivery.Apply(profile, "duck", 1001)
assert(result == "Committed" and code == "DepotRegistered")
assert(profile.lifetime.npcDeliveries == 1 and profile.lifetime.distinctRegistered == 1)
assert(profile.collectionIndex.duck and profile.displaySlots.exposed_01 == "duck"
    and profile.publicDisplayApproved.duck == true,
    "new items fill an empty public stand on delivery")
assert(Schema.Validate(profile), "registered public item must keep profile valid")
local before = profile.cash
result, code = Delivery.Apply(profile, "duck", 1002)
assert(result == "Committed" and code == "DuplicateSalvaged")
assert(profile.cash == before + Catalog.ById.duck.baseIncomePerMinute
    * Balance.DUPLICATE_SALVAGE_MINUTES)
assert(profile.lifetime.npcDeliveries == 2 and profile.lifetime.distinctRegistered == 1)
assert(Schema.Validate(profile), "duplicate public delivery must keep profile valid")
assert(Delivery.Apply(profile, "traffic_cone", 1003) == "Committed")
assert(Delivery.Apply(profile, "moon_rock", 1004) == "Committed")
assert(Arrangement.Apply(profile, "Allow", "moon_rock") == "Committed")
assert(profile.displaySlots.exposed_01 == "moon_rock"
    and profile.displaySlots.exposed_02 == "traffic_cone",
    "full stands must display the two highest earners")
assert(profile.exhibits.duck ~= nil and profile.displaySlots.exposed_01 ~= "duck"
    and profile.displaySlots.exposed_02 ~= "duck",
    "replaced item must remain registered in storage")
profile.displaySlots.exposed_01 = "duck"
profile.displaySlots.exposed_02 = "traffic_cone"
assert(BestDisplays.Apply(profile), "saved profiles with stored high earners are reconciled")
assert(profile.displaySlots.exposed_01 == "moon_rock")
assert(not BestDisplays.Apply(profile), "reconciliation is stable")
assert(Arrangement.Apply(profile, "Place", "duck", "exposed_01") == "Committed")
assert(profile.publicDisplayMode == "Manual" and profile.displaySlots.exposed_01 == "duck"
    and profile.exhibits.moon_rock ~= nil, "manual placement keeps displaced ownership")
assert(Arrangement.Apply(profile, "Store", "duck") == "Committed")
assert(profile.displaySlots.exposed_01 == nil and profile.publicDisplayApproved.duck == nil,
    "stored items leave public display and lose approval")
assert(Arrangement.Apply(profile, "Auto") == "Committed")
assert(profile.displaySlots.exposed_01 == "moon_rock"
    and profile.displaySlots.exposed_02 == "traffic_cone",
    "automatic mode uses only approved items")
assert(Schema.Validate(profile), "automatic display selection must keep profile valid")

local protectedProfile = Defaults.Create(1500, function()
    nextId += 1
    return "protected-contract-" .. tostring(nextId)
end)
assert(TutorialDelivery.Apply(protectedProfile, 1501) == "Committed")
assert(Arrangement.Apply(protectedProfile, "Store", "toaster") == "Rejected",
    "tutorial toaster must stay displayed until first income")
protectedProfile.tutorialStep = 2
assert(Delivery.Apply(protectedProfile, "moon_rock", 1502) == "Committed")
assert(Arrangement.Apply(protectedProfile, "Place", "moon_rock", "protected")
    == "Committed")
assert(protectedProfile.displaySlots.protected == "moon_rock"
    and protectedProfile.exhibits.toaster ~= nil
    and Arrangement.StorageCount(protectedProfile) == 1,
    "replacing protected toaster stores it without losing ownership")
assert(IncomeMath.RatePerMinute(protectedProfile) == 16,
    "protected replacement earns half its base rate")
assert(Arrangement.Apply(protectedProfile, "Place", "toaster", "protected")
    == "Committed")
assert(protectedProfile.displaySlots.protected == "toaster"
    and protectedProfile.exhibits.moon_rock ~= nil
    and Schema.Validate(protectedProfile), "toaster can return to protected stand")
assert(Arrangement.Apply(protectedProfile, "Store", "toaster") == "Committed")
assert(protectedProfile.displaySlots.protected == nil
    and protectedProfile.exhibits.toaster ~= nil
    and protectedProfile.collectionIndex.toaster,
    "toaster may be stored after the tutorial without losing its ownership")
assert(Arrangement.Apply(protectedProfile, "Place", "toaster", "exposed_01")
    == "Committed")
assert(protectedProfile.displaySlots.protected == nil
    and protectedProfile.displaySlots.exposed_01 == "toaster"
    and protectedProfile.publicDisplayApproved.toaster == true,
    "owner may explicitly expose the toaster on a public stand")
assert(Schema.Validate(protectedProfile))

local capacityProfile = Defaults.Create(2000, function()
    nextId += 1
    return "capacity-contract-" .. tostring(nextId)
end)
assert(TutorialDelivery.Apply(capacityProfile, 2001) == "Committed")
capacityProfile.tutorialStep = 2
for index = 2, 11 do
    assert(Delivery.Apply(capacityProfile, Catalog.OrderedIds[index], 2000 + index)
        == "Committed")
end
local storedPublicId = capacityProfile.displaySlots.exposed_01
assert(storedPublicId ~= nil)
assert(Arrangement.Apply(capacityProfile, "Store", storedPublicId) == "Committed")
assert(Arrangement.Apply(capacityProfile, "Store", "toaster") == "Committed")
assert(Arrangement.StorageCount(capacityProfile) == Balance.STARTING_STORAGE_SLOTS)
local lastPublicItem = Catalog.OrderedIds[12]
assert(Delivery.Apply(capacityProfile, lastPublicItem, 2020) == "Committed",
    "an open stand can receive a new type even while storage is full")
assert(capacityProfile.publicDisplayApproved[lastPublicItem]
    and (capacityProfile.displaySlots.exposed_01 == lastPublicItem
        or capacityProfile.displaySlots.exposed_02 == lastPublicItem)
    and Arrangement.StorageCount(capacityProfile) == Balance.STARTING_STORAGE_SLOTS,
    "new type must use the open stand without exceeding storage capacity")
assert(Schema.Validate(capacityProfile))
print("Task 13 stock arbitration and public delivery rules: PASS")
