--!strict

local Defaults = require(script.Parent.ProfileDefaults)
local Migration = require(script.Parent.ProfileMigration)
local Schema = require(script.Parent.ProfileSchema)
local Balance = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").BalanceConfig)

local LEASE_SECONDS = 180
local LEASE_TOKEN_KEY = "sessionToken"
local LEASE_EXPIRES_KEY = "sessionExpiresAt"
local WRITE_ID_KEY = "lastWriteId"
local OPERATION_RETRY_SECONDS = 600

local function copy(value: any): any
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[key] = copy(child)
    end
    return result
end

local function same(a: any, b: any): boolean
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do
        if not same(value, b[key]) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

local function onlyRoutineFieldsChanged(before: any, after: any): boolean
    local left = copy(before)
    local right = copy(after)
    for _, key in ipairs({ "cash", "incomeRemainder", "beginnerActiveSeconds", "raidCycle" }) do
        left[key] = nil
        right[key] = nil
    end
    left.lifetime.totalCashEarned = nil
    right.lifetime.totalCashEarned = nil
    left.settings.travelTipsEnabled = nil
    right.settings.travelTipsEnabled = nil
    return same(left, right)
end

local function takeTurn(self: any, userId: number)
    local queue = self._queues[userId]
    if queue == nil then
        queue = {}
        self._queues[userId] = queue
    end
    local ticket = {}
    table.insert(queue, ticket)
    while queue[1] ~= ticket or self._busy[userId] do
        task.wait(0.03)
    end
    self._busy[userId] = true
end

local function finishTurn(self: any, userId: number)
    self._busy[userId] = nil
    local queue = self._queues[userId]
    table.remove(queue, 1)
    if #queue == 0 then
        self._queues[userId] = nil
    end
end

local function validId(value: any): boolean
    return type(value) == "string" and #value > 0 and #value <= 128
end

local function pruneOperations(profile: any, nowUnix: number): boolean
    while #profile.operationOrder >= Balance.MAX_OPERATION_HISTORY do
        local oldestId = profile.operationOrder[1]
        local oldest = profile.recentOperations[oldestId]
        if oldest == nil or nowUnix - oldest.committedAtUnix < OPERATION_RETRY_SECONDS then
            return false
        end
        table.remove(profile.operationOrder, 1)
        profile.recentOperations[oldestId] = nil
    end
    return true
end

local function metadataFrom(info: any): {[string]: any}
    local metadata: {[string]: any} = {}
    if info ~= nil then
        local original = info:GetMetadata()
        if type(original) == "table" then
            for key, value in pairs(original) do
                metadata[key] = value
            end
        end
    end
    return metadata
end

local function userIdsFrom(info: any, userId: number): {number}
    if info ~= nil then
        local existing = info:GetUserIds()
        if type(existing) == "table" and #existing > 0 then
            return existing
        end
    end
    return { userId }
end

local Repository = {}
Repository.__index = Repository

function Repository.new(store: any, clock: () -> number, newToken: () -> string)
    assert(store ~= nil and type(clock) == "function" and type(newToken) == "function")
    return setmetatable({
        _store = store,
        _clock = clock,
        _newToken = newToken,
        _sessions = {} :: {[number]: any},
        _pendingTokens = {} :: {[number]: string},
        _loading = {} :: {[number]: boolean},
        _busy = {} :: {[number]: boolean},
        _queues = {} :: {[number]: {any}},
    }, Repository)
end

function Repository:Load(userId: number): (any?, string)
    if type(userId) ~= "number" or userId < 1 or userId % 1 ~= 0 then
        return nil, "InvalidUserId"
    end
    if self._sessions[userId] ~= nil then
        return nil, "AlreadyLoaded"
    end
    if self._loading[userId] then
        return nil, "AlreadyLoading"
    end
    if self._busy[userId] then
        return nil, "Busy"
    end
    local token = self._pendingTokens[userId]
    if token == nil then
        token = self._newToken()
        assert(type(token) == "string" and #token > 0 and #token <= 80, "invalid server token")
        self._pendingTokens[userId] = token
    end
    self._loading[userId] = true
    self._busy[userId] = true

    local outcome = "RetryableError"
    local success, stored = pcall(function()
        return self._store:UpdateAsync("player:" .. userId, function(raw: any, info: any)
            outcome = "RetryableError"
            local nowUnix = self._clock()
            local metadata = metadataFrom(info)
            local existingToken = metadata[LEASE_TOKEN_KEY]
            local expiresAt = metadata[LEASE_EXPIRES_KEY]
            if existingToken ~= nil and existingToken ~= token then
                if type(existingToken) ~= "string" or type(expiresAt) ~= "number"
                    or expiresAt ~= expiresAt or expiresAt < 0 or expiresAt % 1 ~= 0 then
                    outcome = "CorruptLease"
                    return nil
                end
                if expiresAt > nowUnix then
                    outcome = "Locked"
                    return nil
                end
            end

            local generated = 0
            local function deterministicId(): string
                generated += 1
                return "start:" .. userId .. ":" .. token .. ":" .. generated
            end
            local profile: any
            if raw == nil then
                -- Only an invoked, successful UpdateAsync callback proves absence.
                profile = Defaults.Create(nowUnix, deterministicId)
            else
                local migrated, candidate = pcall(Migration.Migrate, raw, nowUnix, deterministicId)
                profile = candidate
                if not migrated or profile == nil then
                    outcome = "CorruptProfile"
                    return nil
                end
            end
            local valid = Schema.Validate(profile)
            if not valid then
                outcome = "CorruptProfile"
                return nil
            end
            metadata[LEASE_TOKEN_KEY] = token
            metadata[LEASE_EXPIRES_KEY] = nowUnix + LEASE_SECONDS
            outcome = "Ready"
            return profile, userIdsFrom(info, userId), metadata
        end)
    end)

    self._loading[userId] = nil
    self._busy[userId] = nil
    if not success or outcome == "RetryableError" or (outcome == "Ready" and stored == nil) then
        -- Keep the token. The write may have committed even when its response was lost.
        return nil, "RetryableError"
    end
    if outcome ~= "Ready" then
        if outcome == "CorruptProfile" or outcome == "CorruptLease" then
            self._pendingTokens[userId] = nil
        end
        return nil, outcome
    end
    self._sessions[userId] = {
        token = token, profile = copy(stored), working = copy(stored),
        state = "Ready", dirty = false, pending = nil, nextWrite = 0,
        seenOperations = {}, issuedOperations = {},
    }
    self._pendingTokens[userId] = nil
    return copy(stored), "Ready"
end

function Repository:GetSnapshot(userId: number): any?
    local session = self._sessions[userId]
    if session == nil or session.state ~= "Ready" then
        return nil
    end
    return copy(session.working)
end

function Repository:GetWriteState(userId: number): string
    local session = self._sessions[userId]
    if session == nil then return "NotLoaded" end
    if session.pending ~= nil then return "SaveError" end
    if session.state ~= "Ready" then return session.state end
    return if session.dirty then "Dirty" else "Saved"
end

function Repository:NewOperationId(userId: number): string?
    local session = self._sessions[userId]
    if session == nil or session.state ~= "Ready" or session.pending ~= nil then return nil end
    session.nextWrite += 1
    local operationId = session.token .. ":" .. session.nextWrite
    session.issuedOperations[operationId] = true
    return operationId
end

function Repository:StageRoutine(userId: number, mutate: (any) -> ()): (boolean, string)
    takeTurn(self, userId)
    local session = self._sessions[userId]
    if session == nil then finishTurn(self, userId); return false, "NotLoaded" end
    if session.state ~= "Ready" or session.pending ~= nil then
        finishTurn(self, userId)
        return false, "SaveError"
    end
    local candidate = copy(session.working)
    local ok = pcall(mutate, candidate)
    if not ok or not Schema.Validate(candidate)
        or not onlyRoutineFieldsChanged(session.working, candidate) then
        finishTurn(self, userId)
        return false, "InvalidMutation"
    end
    session.working = candidate
    session.dirty = true
    finishTurn(self, userId)
    return true, "Dirty"
end

local function commitPending(self: any, userId: number, session: any): (boolean, string)
    local pending = session.pending
    if pending == nil then return true, "Saved" end
    local outcome = "RetryableError"
    local observed: any = nil
    local success, stored = pcall(function()
        return self._store:UpdateAsync("player:" .. userId, function(raw: any, info: any)
            outcome = "RetryableError"
            observed = nil
            local metadata = metadataFrom(info)
            if metadata[LEASE_TOKEN_KEY] ~= session.token then
                outcome = "Lost"
                return nil
            end
            if raw == nil or not Schema.Validate(raw) then
                outcome = "CorruptProfile"
                return nil
            end
            if pending.operationId ~= nil then
                local previous = raw.recentOperations[pending.operationId]
                if previous ~= nil then
                    observed = copy(raw)
                    outcome = "AlreadyCommitted"
                    return nil
                end
            end
            if metadata[WRITE_ID_KEY] == pending.writeId
                and raw.revision == pending.candidate.revision then
                observed = copy(raw)
                outcome = "AlreadyCommitted"
                return nil
            end
            if raw.revision ~= pending.expectedRevision then
                outcome = "Conflict"
                return nil
            end
            metadata[WRITE_ID_KEY] = pending.writeId
            metadata[LEASE_EXPIRES_KEY] = self._clock() + LEASE_SECONDS
            outcome = "Saved"
            return pending.candidate, userIdsFrom(info, userId), metadata
        end)
    end)
    if not success or outcome == "RetryableError" or (outcome == "Saved" and stored == nil) then
        session.state = "Uncertain"
        return false, "RetryableError"
    end
    if outcome == "Saved" or outcome == "AlreadyCommitted" then
        local confirmed = if outcome == "Saved" then stored else observed
        if confirmed == nil or not Schema.Validate(confirmed) then
            session.state = "Uncertain"
            return false, "CorruptProfile"
        end
        if pending.operationId ~= nil then
            local operation = confirmed.recentOperations[pending.operationId]
            if operation == nil or operation.kind ~= pending.kind
                or operation.requestScope ~= pending.requestScope then
                session.state = "Lost"
                return false, "Conflict"
            end
            session.seenOperations[pending.operationId] = copy(operation)
        end
        session.profile = copy(confirmed)
        session.working = copy(confirmed)
        session.dirty = false
        session.pending = nil
        session.state = "Ready"
        return true, if outcome == "Saved" then "Saved" else "Reconciled"
    end
    session.state = if outcome == "Lost" or outcome == "Conflict" then "Lost" else "Uncertain"
    return false, outcome
end

function Repository:Reconcile(userId: number): (boolean, string)
    takeTurn(self, userId)
    local session = self._sessions[userId]
    local ok: boolean
    local status: string
    if session == nil then
        ok, status = false, "NotLoaded"
    else
        ok, status = commitPending(self, userId, session)
    end
    finishTurn(self, userId)
    return ok, status
end

function Repository:SaveDirty(userId: number): (boolean, string)
    takeTurn(self, userId)
    local session = self._sessions[userId]
    if session == nil then finishTurn(self, userId); return false, "NotLoaded" end
    if session.pending ~= nil then
        local ok, status = commitPending(self, userId, session)
        finishTurn(self, userId)
        return ok, status
    end
    if session.state ~= "Ready" then finishTurn(self, userId); return false, "SaveError" end
    if not session.dirty then finishTurn(self, userId); return true, "Saved" end
    local candidate = copy(session.working)
    if session.profile.revision >= Balance.MAX_COUNTER then
        finishTurn(self, userId)
        return false, "RevisionLimit"
    end
    candidate.revision = session.profile.revision + 1
    candidate.lastSavedAtUnix = math.max(candidate.lastSavedAtUnix, self._clock())
    if not Schema.Validate(candidate) then
        finishTurn(self, userId)
        return false, "InvalidMutation"
    end
    session.nextWrite += 1
    session.pending = {
        writeId = session.token .. ":" .. session.nextWrite,
        candidate = candidate, expectedRevision = session.profile.revision,
    }
    local ok, status = commitPending(self, userId, session)
    finishTurn(self, userId)
    return ok, status
end

function Repository:ApplyOperation(userId: number, operationId: string, kind: string,
    requestScope: string, mutate: (any) -> (string, string)): (any?, string)
    takeTurn(self, userId)
    local session = self._sessions[userId]
    if session == nil then finishTurn(self, userId); return nil, "NotLoaded" end
    if not validId(operationId) or not validId(requestScope) or type(mutate) ~= "function" then
        finishTurn(self, userId)
        return nil, "InvalidOperation"
    end
    local previous = session.seenOperations[operationId] or session.profile.recentOperations[operationId]
    if previous ~= nil then
        finishTurn(self, userId)
        if previous.kind ~= kind or previous.requestScope ~= requestScope then
            return nil, "OperationConflict"
        end
        return copy(previous), "Repeated"
    end
    if session.pending ~= nil then
        if session.pending.operationId ~= operationId then
            finishTurn(self, userId)
            return nil, "SaveError"
        end
        if session.pending.kind ~= kind or session.pending.requestScope ~= requestScope then
            finishTurn(self, userId)
            return nil, "OperationConflict"
        end
        local ok, status = commitPending(self, userId, session)
        local result = if ok then copy(session.seenOperations[operationId]) else nil
        finishTurn(self, userId)
        return result, if ok then "Reconciled" else status
    end
    if session.state ~= "Ready" then finishTurn(self, userId); return nil, "SaveError" end
    if string.sub(operationId, 1, #session.token + 1) ~= session.token .. ":"
        or session.issuedOperations[operationId] ~= true then
        finishTurn(self, userId)
        return nil, "StaleOperation"
    end
    if session.profile.revision >= Balance.MAX_COUNTER then
        finishTurn(self, userId)
        return nil, "RevisionLimit"
    end
    local candidate = copy(session.working)
    local ok, result, resultCode = pcall(mutate, candidate)
    if not ok or (result ~= "Committed" and result ~= "Rejected") or not validId(resultCode) then
        finishTurn(self, userId)
        return nil, "InvalidMutation"
    end
    if result == "Rejected" then candidate = copy(session.working) end
    local nowUnix = self._clock()
    if not pruneOperations(candidate, nowUnix) then
        finishTurn(self, userId)
        return nil, "HistoryFull"
    end
    local operation = {
        kind = kind, result = result, committedAtUnix = nowUnix,
        requestScope = requestScope, resultCode = resultCode,
    }
    candidate.recentOperations[operationId] = operation
    table.insert(candidate.operationOrder, operationId)
    candidate.revision = session.profile.revision + 1
    candidate.lastSavedAtUnix = math.max(candidate.lastSavedAtUnix, nowUnix)
    if not Schema.Validate(candidate) then
        finishTurn(self, userId)
        return nil, "InvalidMutation"
    end
    session.pending = {
        writeId = operationId, operationId = operationId, kind = kind,
        requestScope = requestScope, candidate = candidate,
        expectedRevision = session.profile.revision,
    }
    local saved, status = commitPending(self, userId, session)
    local confirmed = if saved then copy(session.seenOperations[operationId]) else nil
    finishTurn(self, userId)
    return confirmed, if saved then "Committed" else status
end

function Repository:Refresh(userId: number): (boolean, string)
    takeTurn(self, userId)
    local session = self._sessions[userId]
    if session == nil then
        finishTurn(self, userId)
        return false, "NotLoaded"
    end
    if session.pending ~= nil then
        finishTurn(self, userId)
        return false, "PendingWrite"
    end
    local outcome = "RetryableError"
    local success = pcall(function()
        self._store:UpdateAsync("player:" .. userId, function(raw: any, info: any)
            outcome = "RetryableError"
            local metadata = metadataFrom(info)
            if metadata[LEASE_TOKEN_KEY] ~= session.token then
                outcome = "Lost"
                return nil
            end
            if raw == nil or not Schema.Validate(raw) then
                outcome = "CorruptProfile"
                return nil
            end
            metadata[LEASE_EXPIRES_KEY] = self._clock() + LEASE_SECONDS
            outcome = "Ready"
            return raw, userIdsFrom(info, userId), metadata
        end)
    end)
    finishTurn(self, userId)
    if success and outcome == "Ready" then
        session.state = "Ready"
        return true, "Ready"
    end
    session.state = if success and outcome == "Lost" then "Lost" else "Uncertain"
    return false, if success then outcome else "RetryableError"
end

function Repository:Release(userId: number): (boolean, string)
    takeTurn(self, userId)
    local session = self._sessions[userId]
    if session == nil then
        finishTurn(self, userId)
        return false, "NotLoaded"
    end
    if session.pending ~= nil or session.dirty then
        finishTurn(self, userId)
        return false, "PendingWrite"
    end
    session.state = "Releasing"
    local outcome = "RetryableError"
    local success = pcall(function()
        self._store:UpdateAsync("player:" .. userId, function(raw: any, info: any)
            outcome = "RetryableError"
            local metadata = metadataFrom(info)
            if metadata[LEASE_TOKEN_KEY] ~= session.token then
                outcome = "Lost"
                return nil
            end
            if raw == nil or not Schema.Validate(raw) then
                outcome = "CorruptProfile"
                return nil
            end
            metadata[LEASE_TOKEN_KEY] = nil
            metadata[LEASE_EXPIRES_KEY] = nil
            outcome = "Released"
            return raw, userIdsFrom(info, userId), metadata
        end)
    end)
    finishTurn(self, userId)
    if success and outcome == "Released" then
        self._sessions[userId] = nil
        return true, "Released"
    end
    if success and outcome == "Lost" then
        self._sessions[userId] = nil
        return false, "Lost"
    end
    session.state = "Uncertain"
    return false, if success then outcome else "RetryableError"
end

return table.freeze({
    New = Repository.new,
    LeaseSeconds = LEASE_SECONDS,
})
