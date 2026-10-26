--!strict

-- A small, experience-wide cosmetic record. The lobby never opens the museum
-- profile; earned-cash purchases are committed to that profile in the game.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Catalog = require(ReplicatedStorage.Shared.WardrobeCatalog)

local okStore, openedStore = pcall(function()
    return DataStoreService:GetDataStore(if RunService:IsStudio()
        then "StealAnything_Wardrobe_Dev_v1" else "StealAnything_Wardrobe_Prod_v1")
end)
local store: any = if okStore then openedStore else nil
if store == nil and RunService:IsStudio() and game.PlaceId == 0 then
    -- A local .rbxl has no cloud DataStore identity. This is only for a Play
    -- preview of that file; it deliberately resets when the session ends.
    local records: {[string]: any} = {}
    store = {
        GetAsync = function(_, key: string) return records[key] end,
        UpdateAsync = function(_, key: string, transform: (any) -> any)
            local nextValue = transform(records[key])
            if nextValue ~= nil then records[key] = nextValue end
            return nextValue
        end,
    }
end
local WardrobeStore = {}

local function fresh(): any
    return { version = 1, owned = {}, loadout = {} }
end

local function copy(record: any): any
    local result = fresh()
    for id, owned in pairs(record.owned) do result.owned[id] = owned end
    for slot, id in pairs(record.loadout) do result.loadout[slot] = id end
    return result
end

local function valid(record: any): boolean
    if type(record) ~= "table" or record.version ~= 1
        or type(record.owned) ~= "table" or type(record.loadout) ~= "table" then return false end
    for id, owned in pairs(record.owned) do
        if Catalog.ById[id] == nil or owned ~= true then return false end
    end
    return Catalog.ValidLoadout(record.loadout, record.owned)
end

function WardrobeStore.Read(userId: number): (any?, string?)
    if store == nil then return nil, "Unavailable" end
    local ok, result = pcall(function()
        return store:GetAsync("player:" .. userId)
    end)
    if not ok then return nil, "Unavailable" end
    local record = result or fresh()
    if not valid(record) then return nil, "InvalidWardrobeData" end
    return copy(record), nil
end

function WardrobeStore.SyncOwned(userId: number, profileOwned: {[string]: boolean}): (any?, string?)
    if store == nil then return nil, "Unavailable" end
    local current = WardrobeStore.Read(userId)
    if current then
        local missing = false
        for id, owned in pairs(profileOwned) do
            local item = Catalog.ById[id]
            if item and item.currency == "Cash" and owned == true and current.owned[id] ~= true then
                missing = true
                break
            end
        end
        if not missing then return current, nil end
    end
    local outcome = "Unavailable"
    local ok, result = pcall(function()
        return store:UpdateAsync("player:" .. userId, function(previous: any)
            local record = previous or fresh()
            if not valid(record) then outcome = "InvalidWardrobeData"; return nil end
            record = copy(record)
            for id, owned in pairs(profileOwned) do
                local item = Catalog.ById[id]
                if item and item.currency == "Cash" and owned == true then record.owned[id] = true end
            end
            outcome = "Ready"
            return record
        end)
    end)
    if not ok or result == nil then return nil, outcome end
    return copy(result), nil
end

function WardrobeStore.Equip(userId: number, slot: string, itemId: string?): (any?, string?)
    if store == nil then return nil, "Unavailable" end
    if Catalog.Slots[slot] ~= true then return nil, "InvalidSlot" end
    local item = itemId and Catalog.ById[itemId] or nil
    if itemId ~= nil and (item == nil or item.slot ~= slot) then return nil, "InvalidItem" end
    local outcome = "Unavailable"
    local ok, result = pcall(function()
        return store:UpdateAsync("player:" .. userId, function(previous: any)
            local record = previous or fresh()
            if not valid(record) then outcome = "InvalidWardrobeData"; return nil end
            record = copy(record)
            if item and item.currency ~= "Free" and record.owned[itemId :: string] ~= true then
                outcome = "NotOwned"
                return nil
            end
            record.loadout[slot] = itemId
            outcome = "Ready"
            return record
        end)
    end)
    if not ok or result == nil then return nil, outcome end
    return copy(result), nil
end

function WardrobeStore.Restore(userId: number): (any?, string?)
    if store == nil then return nil, "Unavailable" end
    local outcome = "Unavailable"
    local ok, result = pcall(function()
        return store:UpdateAsync("player:" .. userId, function(previous: any)
            local record = previous or fresh()
            if not valid(record) then outcome = "InvalidWardrobeData"; return nil end
            record = copy(record)
            record.loadout = {}
            outcome = "Ready"
            return record
        end)
    end)
    if not ok or result == nil then return nil, outcome end
    return copy(result), nil
end

function WardrobeStore.Valid(record: any): boolean
    return valid(record)
end

return table.freeze(WardrobeStore)
