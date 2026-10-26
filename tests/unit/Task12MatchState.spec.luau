--!strict
-- Run in Studio Edit mode after Rojo sync. All service calls are mocked.
local shared = game:GetService("ServerScriptService").MatchShared
local State = require(shared.MatchState)
local Referrals = require(shared.ReferralRules)
local TeleportRetry = require(shared.TeleportRetry)
local Rules = require(shared.MatchRules)
local Config = require(shared.PlaceConfig)
local now = 1000
local state = State.New()

local function update(transform)
    -- Mimics one atomic MemoryStoreHashMap UpdateAsync transaction.
    state = transform(state)
end
local function queue(userId, inviter)
    update(function(old) return State.Queue(old, userId, "lobby", inviter, now, 35) end)
end
local function pair(key, code)
    update(function(old)
        return State.ClaimPair(old, now, key, code, key .. "-a", key .. "-b", 75)
    end)
end

queue(1, 0)
assert(State.WaitingCount(state) == 1)
pair("s1", "code1")
assert(state.servers.s1 == nil and state.assignments["1"] == nil)
queue(2, 0)
queue(1, 0) -- Duplicate joins keep one queue entry.
assert(State.WaitingCount(state) == 2)
pair("s1", "code1")
assert(state.assignments["1"] and state.assignments["2"])
assert(state.assignments["1"].serverKey == "s1")
pair("s2", "code2") -- A racing coordinator cannot take the same pair.
assert(state.servers.s2 == nil)

local solo = State.Queue(State.New(), 50, "solo-lobby", 0, now, 35)
solo = State.ClaimFirstSolo(solo, now, "solo", "solo-code", "solo-ticket", 75)
assert(solo.assignments["50"].serverKey == "solo")
solo = State.Arrive(solo, 50, "solo", "solo-ticket", "solo-job", now, 35)
assert(solo.servers.solo.members["50"] and Config.MinimumPlayers == 1)
solo = State.Arrive(solo, 50, "solo", "solo-ticket", "solo-job", now + 1, 35)
assert(solo.servers.solo.members["50"] and solo.servers.solo.tickets["50"] == "solo-ticket")
solo = State.Arrive(solo, 50, "solo", "wrong-ticket", "solo-job", now + 2, 35)
assert(solo.servers.solo.tickets["50"] == "solo-ticket")
assert(State.ArrivalFailure(solo, 99, "solo", "missing", "solo-job") == "TICKET EXPIRED")
solo = State.Arrive(solo, 50, "solo", "solo-ticket", "replacement-phone-job",
    now + 3, 35)
assert(solo.servers.solo.jobId == "replacement-phone-job")
assert(solo.servers.solo.members["50"] == true)
solo = State.Leave(solo, "solo", 50, now + 4, "solo-job")
assert(solo.servers.solo.members["50"] == true)
solo = State.Heartbeat(solo, "solo", "replacement-phone-job", {50}, now + 20, 35,
    "solo-code")
solo = State.Queue(solo, 51, "lobby", 0, now + 20, 35)
solo = State.ClaimExisting(solo, 51, now + 20, "join-solo", 75)
assert(solo.assignments["51"].serverKey == "solo")

-- A failed solo teleport must release its unopened server immediately.
local failedSolo = State.Queue(State.New(), 60, "lobby", 0, now, 35)
failedSolo = State.ClaimFirstSolo(failedSolo, now, "failed-solo", "code",
    "ticket", 75)
failedSolo = State.Cancel(failedSolo, 60, now)
assert(failedSolo.servers["failed-solo"] == nil)
failedSolo = State.Queue(failedSolo, 60, "lobby", 0, now, 35)
failedSolo = State.ClaimFirstSolo(failedSolo, now, "replacement-solo", "code-2",
    "ticket-2", 75)
assert(failedSolo.assignments["60"].serverKey == "replacement-solo")

local failedPair = State.Queue(State.New(), 61, "lobby", 0, now, 35)
failedPair = State.Queue(failedPair, 62, "lobby", 0, now, 35)
failedPair = State.ClaimPair(failedPair, now, "failed-pair", "code",
    "ticket-a", "ticket-b", 75)
failedPair = State.Cancel(failedPair, 61, now)
assert(failedPair.servers["failed-pair"] ~= nil)
failedPair = State.Cancel(failedPair, 62, now)
assert(failedPair.servers["failed-pair"] == nil)

local expiredSolo = State.Queue(State.New(), 63, "lobby", 0, now, 35)
expiredSolo = State.ClaimFirstSolo(expiredSolo, now, "expired-solo", "code",
    "ticket", 75)
expiredSolo = State.Prune(expiredSolo, now + 76)
assert(expiredSolo.servers["expired-solo"] == nil)

local slowPhone = State.Queue(State.New(), 64, "lobby", 0, now, 35)
slowPhone = State.ClaimFirstSolo(slowPhone, now, "slow-phone", "code",
    "ticket", Config.ReservationSeconds)
slowPhone = State.Arrive(slowPhone, 64, "slow-phone", "ticket",
    "phone-job", now + 100, Config.ServerLeaseSeconds)
assert(slowPhone.servers["slow-phone"].members["64"] == true)
update(function(old) return State.Arrive(old, 1, "s1", "s1-a", "job1", now, 35) end)
assert(state.servers.s1.members["1"] and state.servers.s1.jobId == "job1")
update(function(old) return State.Arrive(old, 2, "s1", "bad-ticket", "job1", now, 35) end)
assert(state.servers.s1.members["2"] == nil)
update(function(old) return State.Arrive(old, 2, "s1", "s1-b", "job1", now, 35) end)
assert(state.servers.s1.members["2"])
update(function(old) return State.Arrive(old, 2, "s1", "s1-b", "other-job", now + 1, 35) end)
assert(state.servers.s1.jobId == "job1") -- Another player's server cannot be taken over.
update(function(old) return State.Arrive(old, 99, "s1", "forged", "job1", now, 35) end)
assert(state.servers.s1.members["99"] == nil) -- No ticket, no admission or plot.

assert(Config.MaximumPlayers == 6 and State.FreeSlots(state.servers.s1) == 4)
for userId = 3, 6 do
    queue(userId, 1)
    local ticket = "t" .. userId
    update(function(old) return State.ClaimExisting(old, userId, now, ticket, 75) end)
    assert(state.assignments[tostring(userId)].serverKey == "s1")
    update(function(old) return State.Arrive(old, userId, "s1", ticket, "job1", now, 35) end)
end
assert(State.FreeSlots(state.servers.s1) == 0)
queue(7, 1)
update(function(old) return State.ClaimExisting(old, 7, now, "t7", 75) end)
assert(state.assignments["7"] == nil)
pair("s2", "code2")
assert(state.servers.s2 == nil)
update(function(old)
    return State.ClaimFirstSolo(old, now, "wrong-solo", "code", "ticket", 75)
end)
assert(state.servers["wrong-solo"] == nil) -- Seventh still waits for eighth.
queue(8, 0)
pair("s2", "code2")
assert(state.assignments["7"].serverKey == "s2")
assert(state.assignments["8"].serverKey == "s2")

-- Pairing changes when arrival order changes; it is not tied to old plots.
local reordered = State.New()
reordered = State.Queue(reordered, 1, "new-lobby", 0, now, 35)
reordered = State.Queue(reordered, 3, "new-lobby", 0, now + 1, 35)
reordered = State.ClaimPair(reordered, now + 1, "reordered", "new-code",
    "new-a", "new-b", 75)
assert(reordered.assignments["1"].serverKey == "reordered")
assert(reordered.assignments["3"].serverKey == "reordered")
assert(reordered.assignments["2"] == nil)

-- A vacancy fills an existing server, including a one-player server.
update(function(old) return State.Leave(old, "s1", 2, now) end)
queue(2, 0)
update(function(old) return State.ClaimExisting(old, 2, now, "return-ticket", 75) end)
assert(state.assignments["2"].serverKey == "s1")
update(function(old) return State.Cancel(old, 2, now) end)
assert(state.assignments["2"] == nil and state.servers.s1.reservations["2"] == nil)

-- Expiring an unarrived second player leaves the first server available.
local partial = State.New()
partial = State.Queue(partial, 10, "a", 0, now, 35)
partial = State.Queue(partial, 11, "b", 0, now, 35)
partial = State.ClaimPair(partial, now, "partial", "code", "a", "b", 75)
partial = State.Arrive(partial, 10, "partial", "a", "job", now, 35)
partial = State.Heartbeat(partial, "partial", "job", {10}, now + 20, 35)
partial = State.Heartbeat(partial, "partial", "job", {10}, now + 50, 35)
partial = State.Heartbeat(partial, "partial", "job", {10}, now + 70, 35)
partial = State.Heartbeat(partial, "partial", "job", {10}, now + 80, 35)
assert(partial.servers.partial.members["10"])
assert(partial.servers.partial.reservations["11"] == nil)
partial = State.Queue(partial, 12, "a", 0, now + 80, 35)
partial = State.ClaimExisting(partial, 12, now + 80, "replacement", 75)
assert(partial.assignments["12"].serverKey == "partial")
local expired = State.Queue(State.New(), 14, "stale-lobby", 0, now, 35)
expired = State.Prune(expired, now + 36)
assert(State.WaitingCount(expired) == 0)
local hinted = State.ReferralHint(State.New(), 40, 21, now, 90)
assert(State.WaitingCount(hinted) == 0) -- A player still travelling is not queued.
hinted = State.Queue(hinted, 40, "lobby", 0, now + 5, 35)
assert(hinted.queue["40"].inviter == 21)
local recovered = State.Heartbeat(State.New(), "recovered", "job-r", {10},
    now, 35, "code-r")
assert(recovered.servers.recovered.members["10"])
assert(recovered.servers.recovered.code == "code-r")

-- Friend priority beats another eligible server.
local friends = State.New()
friends = State.Queue(friends, 21, "l", 0, now, 35)
friends = State.ClaimFirstSolo(friends, now, "friends", "code-f", "fa", 75)
friends = State.Arrive(friends, 21, "friends", "fa", "job-f", now, 35)
friends.servers.other = { code = "other", jobId = "job-o", untilTime = now + 35,
    members = { ["31"] = true }, reservations = {} }
friends = State.Queue(friends, 23, "l", 21, now, 35)
friends = State.ClaimExisting(friends, 23, now, "fc", 75)
assert(friends.assignments["23"].serverKey == "friends")

local rewards = nil
for friend = 101, 104 do
    local granted
    rewards, granted = Referrals.Qualify(rewards, 1, friend)
    assert(granted)
end
local granted
rewards, granted = Referrals.Qualify(rewards, 1, 104)
assert(not granted)

local calls = 0
local waited = 0
local ok, attempts = TeleportRetry.Run(3, function()
    calls += 1
    if calls < 3 then error("mock teleport failure") end
end, function(seconds)
    waited += seconds
end, function() return true end)
assert(ok and attempts == 3 and calls == 3 and waited == 6)
calls = 0
local retryError
ok, attempts, retryError = TeleportRetry.Run(3, function()
    calls += 1
    error("permanent mock failure")
end, function() end, function() return true end)
assert(not ok and attempts == 3 and calls == 3)
assert(string.find(retryError, "permanent mock failure") ~= nil)

assert(not Rules.CanLoadProfile(true, "Pending"))
assert(not Rules.CanLoadProfile(true, "Denied"))
assert(Rules.CanLoadProfile(true, "Accepted"))
assert(Rules.CanLoadProfile(false, nil))
assert(not Rules.CanPlay(true, false))
assert(not Rules.CanPlay(true, nil))
assert(Rules.CanPlay(true, true))
assert(Rules.ReadyCount({
    { admitted = true, profile = "Ready", plot = "Ready" },
    { admitted = true, profile = "Loading", plot = "Ready" },
}) == 1) -- A lone ready player may play with the one-player minimum.
assert(Rules.ReadyCount({
    { admitted = true, profile = "Ready", plot = "Ready" },
    { admitted = true, profile = "Ready", plot = "Ready" },
}) == 2) -- The second loaded player resumes the match.

local Defaults = require(game.ServerScriptService.Server.Data.ProfileDefaults)
local HttpService = game:GetService("HttpService")
local profile = Defaults.Create(1_700_000_000, function() return "contract-id" end)
local saved = HttpService:JSONEncode(profile)
assert(profile.plotId == nil and profile.cloneId == nil and profile.serverKey == nil)
local anotherMatch = State.New()
anotherMatch = State.Queue(anotherMatch, 6, "new-lobby", 0, now, 35)
anotherMatch = State.Queue(anotherMatch, 13, "new-lobby", 0, now, 35)
anotherMatch = State.ClaimPair(anotherMatch, now, "different-server", "code",
    "new-ticket", "friend-ticket", 75)
assert(anotherMatch.assignments["6"].serverKey == "different-server")
assert(HttpService:JSONEncode(profile) == saved)
rewards, granted = Referrals.Qualify(rewards, 1, 105)
assert(not granted and rewards.count == 4)
rewards, granted = Referrals.Qualify(rewards, 1, 1)
assert(not granted)

print("Task12MatchState passed")
