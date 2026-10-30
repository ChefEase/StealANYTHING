--!strict

local Balance = require(game:GetService("ReplicatedStorage").Shared.BalanceConfig)

local PublicStockState = {}
PublicStockState.__index = PublicStockState

function PublicStockState.New(now: () -> number, choose: (string?) -> string,
    pedestalIds: {string})
    local self = setmetatable({
        now = now,
        choose = choose,
        pedestals = {} :: {[string]: any},
        runs = {} :: {[string]: any},
    }, PublicStockState)
    for _, id in pedestalIds do
        self.pedestals[id] = {
            itemId = choose(nil),
            rotateAt = now() + Balance.DEPOT_ROTATION_SECONDS,
            restockAt = 0,
            holds = {} :: {[number]: string},
        }
    end
    return self
end

function PublicStockState:Get(id: string): any?
    return self.pedestals[id]
end

function PublicStockState:Begin(id: string, userId: number, requestId: string): (boolean, string)
    local pedestal = self.pedestals[id]
    if pedestal == nil or pedestal.itemId == nil then return false, "Empty" end
    pedestal.holds[userId] = requestId
    return true, "Ready"
end

function PublicStockState:Cancel(id: string, userId: number, requestId: string)
    local pedestal = self.pedestals[id]
    if pedestal ~= nil and pedestal.holds[userId] == requestId then
        pedestal.holds[userId] = nil
    end
end

function PublicStockState:Claim(id: string, userId: number, requestId: string,
    runId: string): (string?, string)
    local pedestal = self.pedestals[id]
    if pedestal == nil or pedestal.itemId == nil then return nil, "AlreadyTaken" end
    if pedestal.holds[userId] ~= requestId or self.runs[runId] ~= nil then
        return nil, "InvalidReservation"
    end
    local itemId = pedestal.itemId
    pedestal.itemId = nil
    pedestal.rotateAt = 0
    pedestal.restockAt = self.now() + Balance.DEPOT_RESTOCK_SECONDS
    pedestal.holds = {}
    self.runs[runId] = { pedestalId = id, itemId = itemId }
    return itemId, "Claimed"
end

function PublicStockState:Finish(runId: string): boolean
    if self.runs[runId] == nil then return false end
    self.runs[runId] = nil
    return true
end

function PublicStockState:Fail(runId: string): boolean
    local run = self.runs[runId]
    if run == nil then return false end
    self.runs[runId] = nil
    local pedestal = self.pedestals[run.pedestalId]
    if pedestal ~= nil and pedestal.itemId == nil then
        pedestal.restockAt = self.now() + Balance.DEPOT_RESTOCK_SECONDS
    end
    return true
end

function PublicStockState:Tick(): boolean
    local changed = false
    local now = self.now()
    for _, pedestal in pairs(self.pedestals) do
        if pedestal.itemId == nil then
            if now >= pedestal.restockAt then
                pedestal.itemId = self.choose(nil)
                pedestal.rotateAt = now + Balance.DEPOT_ROTATION_SECONDS
                pedestal.restockAt = 0
                changed = true
            end
        elseif now >= pedestal.rotateAt and next(pedestal.holds) == nil then
            pedestal.itemId = self.choose(pedestal.itemId)
            pedestal.rotateAt = now + Balance.DEPOT_ROTATION_SECONDS
            changed = true
        end
    end
    return changed
end

return table.freeze(PublicStockState)
