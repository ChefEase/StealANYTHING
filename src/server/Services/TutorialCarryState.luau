--!strict

local Balance = require(game:GetService("ReplicatedStorage").Shared.BalanceConfig)

type Pending = {
    kind: "Pending",
    requestId: string,
    runId: string,
    startedAt: number,
    triggered: boolean,
}

type Carry = {
    kind: "Carrying",
    carryId: string,
    runId: string,
    itemId: string,
}

type Session = Pending | Carry

local TutorialCarryState = {}
TutorialCarryState.__index = TutorialCarryState

function TutorialCarryState.New(now: () -> number, newId: () -> string)
    return setmetatable({
        now = now,
        newId = newId,
        sessions = {} :: {[number]: Session},
    }, TutorialCarryState)
end

function TutorialCarryState:Get(userId: number): Session?
    return self.sessions[userId]
end

function TutorialCarryState:Begin(userId: number, requestId: string): (Pending?, string)
    local existing = self.sessions[userId]
    if existing ~= nil then
        if existing.kind == "Pending" and existing.requestId == requestId then
            return existing, "Existing"
        end
        return nil, if existing.kind == "Carrying" then "AlreadyCarrying" else "Busy"
    end

    local pending: Pending = {
        kind = "Pending",
        requestId = requestId,
        runId = self.newId(),
        startedAt = self.now(),
        triggered = false,
    }
    self.sessions[userId] = pending
    return pending, "Started"
end

function TutorialCarryState:Trigger(userId: number): (Pending?, string)
    local session = self.sessions[userId]
    if session == nil or session.kind ~= "Pending" then
        return nil, "NoPickup"
    end
    session.triggered = true
    return session, "Triggered"
end

function TutorialCarryState:Complete(userId: number, requestId: string): (Carry?, string)
    local session = self.sessions[userId]
    if session == nil or session.kind ~= "Pending" or session.requestId ~= requestId then
        return nil, "NoPickup"
    end
    if not session.triggered then
        return nil, "NotTriggered"
    end
    if self.now() - session.startedAt < Balance.PICKUP_HOLD_SECONDS then
        return nil, "TooSoon"
    end

    local carry: Carry = {
        kind = "Carrying",
        carryId = self.newId(),
        runId = session.runId,
        itemId = "toaster",
    }
    self.sessions[userId] = carry
    return carry, "Carrying"
end

function TutorialCarryState:Cancel(userId: number, requestId: string): boolean
    local session = self.sessions[userId]
    if session == nil or session.kind ~= "Pending" or session.requestId ~= requestId then
        return false
    end
    self.sessions[userId] = nil
    return true
end

function TutorialCarryState:Drop(userId: number, carryId: string): boolean
    local session = self.sessions[userId]
    if session == nil or session.kind ~= "Carrying" or session.carryId ~= carryId then
        return false
    end
    self.sessions[userId] = nil
    return true
end

function TutorialCarryState:Clear(userId: number): Session?
    local session = self.sessions[userId]
    self.sessions[userId] = nil
    return session
end

return table.freeze(TutorialCarryState)
