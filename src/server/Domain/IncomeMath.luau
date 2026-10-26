--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance = require(ReplicatedStorage.Shared.BalanceConfig)
local Items = require(ReplicatedStorage.Shared.ItemCatalog)

local IncomeMath = {}

function IncomeMath.RatePerMinute(profile: any): number
    local rate = 0
    for slotId, itemId in profile.displaySlots do
        local exhibit = profile.exhibits[itemId]
        local item = Items.ById[itemId]
        if exhibit ~= nil and exhibit.state == "Available" and item ~= nil then
            rate += item.baseIncomePerMinute
                * (if slotId == "protected" then Balance.PROTECTED_INCOME_MULTIPLIER else 1)
        end
    end
    return rate
end

function IncomeMath.Accrue(profile: any, elapsedSeconds: number): number
    if elapsedSeconds <= 0 then return 0 end
    local rate = IncomeMath.RatePerMinute(profile)
    if rate <= 0 or profile.cash >= Balance.MAX_CASH then return 0 end
    local total = profile.incomeRemainder + rate * elapsedSeconds / 60
    local earned = math.min(math.floor(total), Balance.MAX_CASH - profile.cash)
    profile.cash += earned
    profile.lifetime.totalCashEarned = math.min(Balance.MAX_COUNTER,
        profile.lifetime.totalCashEarned + earned)
    profile.incomeRemainder = if profile.cash >= Balance.MAX_CASH then 0 else total - earned
    return earned
end

return table.freeze(IncomeMath)
