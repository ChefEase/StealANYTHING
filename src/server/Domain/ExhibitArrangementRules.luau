--!strict

local Balance = require(game:GetService("ReplicatedStorage").Shared.BalanceConfig)
local BestPublicDisplays = require(script.Parent.BestPublicDisplays)

local Rules = {}

local function slotOf(profile: any, itemId: string): string?
    for slotId, placedId in pairs(profile.displaySlots) do
        if placedId == itemId then return slotId end
    end
    return nil
end

local function storageCount(profile: any): number
    local count = 0
    for itemId, exhibit in pairs(profile.exhibits) do
        if exhibit.state == "Available" and slotOf(profile, itemId) == nil then
            count += 1
        end
    end
    return count
end

function Rules.StorageCount(profile: any): number
    return storageCount(profile)
end

function Rules.StorageCapacity(profile: any): number
    return Balance.STORAGE_SLOTS_BY_MUSEUM_TIER[profile.museum.tier]
        or Balance.STARTING_STORAGE_SLOTS
end

function Rules.Apply(profile: any, action: string, itemId: string?,
    slotId: string?): (string, string)
    if action == "Auto" then
        if profile.publicDisplayMode == "Auto" then return "Rejected", "AlreadyAuto" end
        profile.publicDisplayMode = "Auto"
        BestPublicDisplays.Apply(profile)
        return "Committed", "AutoEnabled"
    elseif action == "Manual" then
        if profile.publicDisplayMode == "Manual" then return "Rejected", "AlreadyManual" end
        profile.publicDisplayMode = "Manual"
        return "Committed", "ManualEnabled"
    end

    if profile.tutorialStep < 2 then
        return "Rejected", "FinishTutorial"
    end
    if type(itemId) ~= "string" then
        return "Rejected", "InvalidItem"
    end
    local exhibit = profile.exhibits[itemId]
    if exhibit == nil or exhibit.state ~= "Available" then
        return "Rejected", "NotOwned"
    end

    if action == "Allow" then
        if profile.publicDisplayApproved[itemId] == true then
            return "Rejected", "AlreadyAllowed"
        end
        profile.publicDisplayApproved[itemId] = true
        BestPublicDisplays.Apply(profile)
        return "Committed", "Allowed"
    elseif action == "Store" then
        local currentSlot = slotOf(profile, itemId)
        if currentSlot == nil and profile.publicDisplayApproved[itemId] ~= true then
            return "Rejected", "AlreadyStored"
        end
        if currentSlot ~= nil then profile.displaySlots[currentSlot] = nil end
        profile.publicDisplayApproved[itemId] = nil
        BestPublicDisplays.Apply(profile)
        if storageCount(profile) > Rules.StorageCapacity(profile) then
            return "Rejected", "StorageFull"
        end
        return "Committed", "StoredSafe"
    elseif action == "Place" then
        if slotId ~= "protected" and slotId ~= "exposed_01"
            and slotId ~= "exposed_02" then
            return "Rejected", "InvalidSlot"
        end
        local currentSlot = slotOf(profile, itemId)
        if currentSlot == slotId then return "Rejected", "AlreadyPlaced" end
        local displaced = profile.displaySlots[slotId]
        profile.publicDisplayMode = "Manual"
        profile.publicDisplayApproved[itemId] = if slotId == "protected" then nil else true
        profile.displaySlots[slotId] = itemId
        if currentSlot ~= nil and currentSlot ~= "protected" and slotId ~= "protected" then
            profile.displaySlots[currentSlot] = displaced
        elseif currentSlot ~= nil then
            profile.displaySlots[currentSlot] = nil
        end
        if storageCount(profile) > Rules.StorageCapacity(profile) then
            return "Rejected", "StorageFull"
        end
        return "Committed", if slotId == "protected" then "PlacedProtected" else "Placed"
    end
    return "Rejected", "InvalidAction"
end

return table.freeze(Rules)
