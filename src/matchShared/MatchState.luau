--!strict
-- Pure transforms. Every operation runs inside one MemoryStoreHashMap:UpdateAsync.
local MatchState = {}
local MAXIMUM = require(script.Parent.PlaceConfig).MaximumPlayers

function MatchState.New(): any
    return { queue = {}, servers = {}, assignments = {}, hints = {} }
end

local function copyState(old: any): any
    local state = old or MatchState.New()
    state.queue = state.queue or {}
    state.servers = state.servers or {}
    state.assignments = state.assignments or {}
    state.hints = state.hints or {}
    return state
end

function MatchState.Prune(old: any, now: number): any
    local state = copyState(old)
    for userId, entry in pairs(state.queue) do
        if entry.untilTime <= now then state.queue[userId] = nil end
    end
    for userId, assignment in pairs(state.assignments) do
        if assignment.untilTime <= now then state.assignments[userId] = nil end
    end
    for userId, hint in pairs(state.hints) do
        if hint.untilTime <= now then state.hints[userId] = nil end
    end
    for key, server in pairs(state.servers) do
        if server.untilTime <= now then
            state.servers[key] = nil
        else
            server.members = server.members or {}
            server.reservations = server.reservations or {}
            server.tickets = server.tickets or {}
            for userId, expires in pairs(server.reservations) do
                if expires <= now or state.assignments[userId] == nil then
                    server.reservations[userId] = nil
                end
            end
            if server.jobId == nil and next(server.reservations) == nil then
                state.servers[key] = nil
            end
        end
    end
    for userId, assignment in pairs(state.assignments) do
        if state.servers[assignment.serverKey] == nil then
            state.assignments[userId] = nil
        end
    end
    return state
end

local function slotsUsed(server: any): number
    local count = 0
    for _ in pairs(server.members) do count += 1 end
    for userId in pairs(server.reservations) do
        if server.members[userId] == nil then count += 1 end
    end
    return count
end

function MatchState.FreeSlots(server: any): number
    return math.max(0, MAXIMUM - slotsUsed(server))
end

function MatchState.Queue(old: any, userId: number, lobbyId: string,
    inviterId: number?, now: number, lease: number): any
    local state = MatchState.Prune(old, now)
    local key = tostring(userId)
    if state.assignments[key] == nil then
        local previous = state.queue[key]
        local hint = state.hints[key]
        state.queue[key] = {
            lobby = lobbyId,
            inviter = if inviterId and inviterId > 0 then inviterId
                else (previous and previous.inviter or (hint and hint.inviter or 0)),
            joined = previous and previous.joined or now,
            untilTime = now + lease,
        }
        state.hints[key] = nil
    end
    return state
end

function MatchState.ReferralHint(old: any, userId: number, inviterId: number,
    now: number, lease: number): any
    local state = MatchState.Prune(old, now)
    if inviterId > 0 and inviterId ~= userId then
        state.hints[tostring(userId)] = { inviter = inviterId, untilTime = now + lease }
    end
    return state
end

function MatchState.Cancel(old: any, userId: number, now: number): any
    local state = MatchState.Prune(old, now)
    local key = tostring(userId)
    state.queue[key] = nil
    state.hints[key] = nil
    local assignment = state.assignments[key]
    if assignment then
        local server = state.servers[assignment.serverKey]
        if server then
            server.reservations[key] = nil
            if server.jobId == nil and next(server.reservations) == nil then
                state.servers[assignment.serverKey] = nil
            end
        end
        state.assignments[key] = nil
    end
    return state
end

function MatchState.Withdraw(old: any, userId: number, now: number): any
    local state = MatchState.Prune(old, now)
    state.queue[tostring(userId)] = nil
    return state
end

local function bestServer(state: any, inviterId: number): (string?, any?)
    local friendKey = tostring(inviterId)
    local selectedKey, selectedServer = nil, nil
    for key, server in pairs(state.servers) do
        if server.jobId ~= nil and slotsUsed(server) < MAXIMUM then
            if inviterId > 0 and server.members[friendKey] then return key, server end
            if selectedServer == nil or slotsUsed(server) > slotsUsed(selectedServer) then
                selectedKey, selectedServer = key, server
            end
        end
    end
    return selectedKey, selectedServer
end

local function reserve(state: any, userId: string, serverKey: string,
    server: any, now: number, ticket: string, lease: number)
    server.reservations[userId] = now + lease
    state.assignments[userId] = {
        serverKey = serverKey, code = server.code, ticket = ticket,
        untilTime = now + lease,
    }
    state.queue[userId] = nil
end

function MatchState.ClaimExisting(old: any, userId: number, now: number,
    ticket: string, lease: number): any
    local state = MatchState.Prune(old, now)
    local key = tostring(userId)
    local queued = state.queue[key]
    if queued == nil or state.assignments[key] ~= nil then return state end
    local serverKey, server = bestServer(state, queued.inviter or 0)
    if serverKey and server then reserve(state, key, serverKey, server, now, ticket, lease) end
    return state
end

function MatchState.ClaimPair(old: any, now: number, serverKey: string,
    code: string, ticketA: string, ticketB: string, lease: number): any
    local state = MatchState.Prune(old, now)
    -- Existing places take priority, even if a concurrent lobby reserved a code.
    if bestServer(state, 0) ~= nil then return state end
    local waiting = {}
    for userId, entry in pairs(state.queue) do
        if state.assignments[userId] == nil then
            table.insert(waiting, { userId = userId, joined = entry.joined })
        end
    end
    table.sort(waiting, function(a, b)
        if a.joined == b.joined then return a.userId < b.userId end
        return a.joined < b.joined
    end)
    if #waiting < 2 then return state end
    local server = {
        code = code, jobId = nil, members = {}, reservations = {}, tickets = {},
        untilTime = now + lease,
    }
    state.servers[serverKey] = server
    reserve(state, waiting[1].userId, serverKey, server, now, ticketA, lease)
    reserve(state, waiting[2].userId, serverKey, server, now, ticketB, lease)
    return state
end

function MatchState.ClaimFirstSolo(old: any, now: number, serverKey: string,
    code: string, ticket: string, lease: number): any
    local state = MatchState.Prune(old, now)
    -- Only the first server may launch with one player. Once every existing
    -- server is full, the next two arrivals still form a new server together.
    if next(state.servers) ~= nil then return state end
    local waiting = {}
    for userId, entry in pairs(state.queue) do
        if state.assignments[userId] == nil then
            table.insert(waiting, { userId = userId, joined = entry.joined })
        end
    end
    if #waiting ~= 1 then return state end
    local server = {
        code = code, jobId = nil, members = {}, reservations = {}, tickets = {},
        untilTime = now + lease,
    }
    state.servers[serverKey] = server
    reserve(state, waiting[1].userId, serverKey, server, now, ticket, lease)
    return state
end

function MatchState.Arrive(old: any, userId: number, serverKey: string,
    ticket: string, jobId: string, now: number, lease: number): any
    local state = MatchState.Prune(old, now)
    local key = tostring(userId)
    local assignment = state.assignments[key]
    local server = state.servers[serverKey]
    if server and server.jobId ~= nil and server.jobId ~= jobId then
        local otherPlayer = false
        for memberId in pairs(server.members) do
            if memberId ~= key then
                otherPlayer = true
                break
            end
        end
        for reservedId in pairs(server.reservations) do
            if reservedId ~= key then
                otherPlayer = true
                break
            end
        end
        local sameTicket = server.tickets[key] == ticket
        local assignedHere = assignment ~= nil and assignment.serverKey == serverKey
            and assignment.ticket == ticket
        if not otherPlayer and (sameTicket or assignedHere) then
            -- The previous instance held only this player. A new instance
            -- reached with the same server-issued ticket may take its lease.
            server.jobId = jobId
            server.members = {}
            server.tickets = {}
            if sameTicket and not assignedHere then
                server.members[key] = true
                server.tickets[key] = ticket
                server.untilTime = now + lease
                return state
            end
        end
    end
    if server and server.jobId == jobId and server.members[key] == true
        and server.tickets[key] == ticket then
        return state
    end
    if assignment == nil or server == nil or assignment.serverKey ~= serverKey
        or assignment.ticket ~= ticket or (server.jobId ~= nil and server.jobId ~= jobId)
        or slotsUsed(server) > MAXIMUM then return state end
    server.jobId = jobId
    server.members[key] = true
    server.tickets[key] = ticket
    server.reservations[key] = nil
    server.untilTime = now + lease
    state.assignments[key] = nil
    return state
end

function MatchState.ArrivalFailure(state: any, userId: number, serverKey: string,
    ticket: string, jobId: string): string
    local key = tostring(userId)
    local server = state.servers[serverKey]
    if server == nil then return "SERVER EXPIRED" end
    if server.jobId ~= nil and server.jobId ~= jobId then
        return "WRONG SERVER INSTANCE"
    end
    local assignment = state.assignments[key]
    if assignment == nil then return "TICKET EXPIRED" end
    if assignment.serverKey ~= serverKey then return "SERVER MISMATCH" end
    if assignment.ticket ~= ticket then return "TICKET MISMATCH" end
    if slotsUsed(server) > MAXIMUM then return "SERVER FULL" end
    return "ENTRY NOT CONFIRMED"
end

function MatchState.Heartbeat(old: any, serverKey: string, jobId: string,
    members: {number}, now: number, lease: number, code: string?): any
    local state = MatchState.Prune(old, now)
    local server = state.servers[serverKey]
    if server == nil and code and #members > 0 then
        server = { code = code, jobId = jobId, members = {}, reservations = {},
            tickets = {},
            untilTime = now + lease }
        state.servers[serverKey] = server
    end
    if server and server.jobId == jobId then
        local current = {}
        for _, userId in members do current[tostring(userId)] = true end
        server.members = current
        for userId in pairs(server.tickets) do
            if not current[userId] then server.tickets[userId] = nil end
        end
        server.untilTime = now + lease
    end
    return state
end

function MatchState.Leave(old: any, serverKey: string, userId: number,
    now: number, jobId: string?): any
    local state = MatchState.Prune(old, now)
    local server = state.servers[serverKey]
    if server and (jobId == nil or server.jobId == jobId) then
        server.members[tostring(userId)] = nil
        server.tickets[tostring(userId)] = nil
        if next(server.members) == nil and next(server.reservations) == nil then
            state.servers[serverKey] = nil
        end
    end
    return state
end

function MatchState.WaitingCount(state: any): number
    local count = 0
    for _ in pairs(state.queue or {}) do count += 1 end
    return count
end

return table.freeze(MatchState)
