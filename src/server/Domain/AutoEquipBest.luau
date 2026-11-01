--!strict
local Catalog = require(game.ReplicatedStorage.Shared.ItemCatalog)
local Rules = {}

function Rules.Apply(profile: any): boolean
    if profile.tutorialStep < 2 then return false end
    local candidates = {}
    for _, id in Catalog.OrderedIds do
        local exhibit = profile.exhibits[id]
        if exhibit and exhibit.state == "Available" then table.insert(candidates, id) end
    end
    table.sort(candidates, function(a, b)
        local aa, bb = Catalog.ById[a].baseIncomePerMinute, Catalog.ById[b].baseIncomePerMinute
        if aa ~= bb then return aa > bb end
        return a < b
    end)
    local protected = candidates[3]
    if not protected and #candidates > 0 then protected = candidates[#candidates] end
    local public = {}
    for _, id in candidates do
        if id ~= protected and #public < 2 then table.insert(public, id) end
    end
    local slots = profile.displaySlots
    if slots.protected == protected and slots.exposed_01 == public[1]
        and slots.exposed_02 == public[2] and profile.publicDisplayMode == "Auto" then
        if profile.settings.collectionTutorialDone then return false end
        profile.settings.collectionTutorialDone = true
        return true
    end
    slots.protected, slots.exposed_01, slots.exposed_02 = protected, public[1], public[2]
    for _, id in public do profile.publicDisplayApproved[id] = true end
    profile.publicDisplayMode = "Auto"
    profile.settings.collectionTutorialDone = true
    return true
end

return table.freeze(Rules)
