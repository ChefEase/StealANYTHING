--!strict

local Catalog = require(game:GetService("ReplicatedStorage").Shared.WardrobeCatalog)
local WardrobePurchaseRules = {}

function WardrobePurchaseRules.Apply(profile: any, itemId: string): (string, string)
    local item = Catalog.ById[itemId]
    if item == nil or item.currency ~= "Cash" or item.price <= 0 then
        return "Rejected", "InvalidItem"
    end
    if profile.cosmetics[itemId] == true then return "Rejected", "AlreadyOwned" end
    if profile.cash < item.price then return "Rejected", "InsufficientCash" end
    profile.cash -= item.price
    profile.cosmetics[itemId] = true
    return "Committed", "Purchased"
end

return table.freeze(WardrobePurchaseRules)
