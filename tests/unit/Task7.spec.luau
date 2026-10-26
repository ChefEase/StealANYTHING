--!strict
-- Run in Studio Edit mode after Rojo sync. Session-only state; no DataStore writes.

local Server = game:GetService("ServerScriptService").Server
local State = require(Server.Services.TutorialCarryState)
local Balance = require(game:GetService("ReplicatedStorage").Shared.BalanceConfig)

local now = 100
local serial = 0
local sessions = State.New(function(): number return now end, function(): string
    serial += 1
    return "server-id-" .. serial
end)

local first = assert(sessions:Begin(101, "request-a"))
local second = assert(sessions:Begin(202, "request-b"))
assert(first.runId ~= second.runId, "tutorial runs must be personal")
assert(sessions:Begin(101, "request-a") == first, "retry must retain the original hold start")
assert(sessions:Begin(101, "request-other") == nil, "second concurrent pickup must fail")
assert(sessions:Complete(101, "request-a") == nil, "completion needs a prompt trigger")
assert(sessions:Trigger(101) == first)
assert(sessions:Trigger(202) == second)
now += Balance.PICKUP_HOLD_SECONDS - 0.01
assert(sessions:Complete(101, "request-a") == nil, "hold cannot finish early")
now += 0.02
local carryA = assert(sessions:Complete(101, "request-a"))
local carryB = assert(sessions:Complete(202, "request-b"))
assert(carryA.runId == first.runId and carryB.runId == second.runId)
assert(carryA.carryId ~= carryB.carryId)
assert(sessions:Complete(101, "request-a") == nil, "duplicate trigger cannot create another carry")
assert(sessions:Begin(101, "request-c") == nil, "carrier cannot start another pickup")
assert(not sessions:Drop(101, carryB.carryId), "another player's carry ID cannot drop this carry")
assert(not sessions:Cancel(101, "request-a"), "late cancel cannot erase a carried item")
assert(sessions:Get(101) == carryA and sessions:Get(202) == carryB)

assert(sessions:Drop(101, carryA.carryId))
assert(not sessions:Drop(101, carryA.carryId), "drop is one-time")
local retry = assert(sessions:Begin(101, "request-retry"))
assert(not sessions:Cancel(101, "request-a"), "stale cancel cannot clear a new run")
assert(sessions:Cancel(101, "request-retry"))
assert(sessions:Get(101) == nil)
assert(sessions:Clear(202) == carryB, "reset or leave clears the active carry")
assert(sessions:Get(202) == nil)
assert(retry.runId ~= first.runId, "retry gets a fresh server run ID")

print("Task 7 personal tutorial carry state: PASS")
return "Task 7 personal tutorial carry state: PASS"
