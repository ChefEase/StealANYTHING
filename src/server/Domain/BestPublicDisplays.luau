--!strict

local Catalog = require(game:GetService("ReplicatedStorage").Shared.ItemCatalog)

local BestPublicDisplays = {}

function BestPublicDisplays.Apply(profile: any): boolean
    if profile.publicDisplayMode ~= "Auto" then return false end
    local available = {}
    for _, itemId in Catalog.OrderedIds do
        local exhibit = profile.exhibits[itemId]
        if itemId ~= profile.displaySlots.protected
            and exhibit ~= nil and exhibit.state == "Available"
            and profile.publicDisplayApproved[itemId] == true then
            table.insert(available, itemId)
        end
    end
    table.sort(available, function(a: string, b: string): boolean
        local left = Catalog.ById[a].baseIncomePerMinute
        local right = Catalog.ById[b].baseIncomePerMinute
        return if left == right then a < b else left > right
    end)
    local first = available[1]
    local second = available[2]
    if profile.displaySlots.exposed_01 == first
        and profile.displaySlots.exposed_02 == second then return false end
    profile.displaySlots.exposed_01 = first
    profile.displaySlots.exposed_02 = second
    return true
end

return table.freeze(BestPublicDisplays)
