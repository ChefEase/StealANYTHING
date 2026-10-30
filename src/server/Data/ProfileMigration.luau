--!strict

local Defaults = require(script.Parent.ProfileDefaults)
local Schema = require(script.Parent.ProfileSchema)
local TierOne = require(game:GetService("ReplicatedStorage").Shared.Task11TierOneContract)

local function copy(value: any): any
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[copy(key)] = copy(child)
    end
    return result
end

local function migrateV0(old: {[string]: any}, nowUnix: number, nextId: () -> string): (any?, string?)
    -- Version 0 is the pre-implementation shape described in the first design
    -- draft: `registered` entries used `status` and `registeredAt`.
    local profile = Defaults.Create(nowUnix, nextId) :: any
    local allowed = {
        schemaVersion = true, revision = true, createdAtUnix = true, lastSavedAtUnix = true,
        cash = true, incomeRemainder = true, registered = true, displaySlots = true,
        accreditation = true, lifetime = true, tutorialStep = true,
        beginnerActiveSeconds = true, settings = true, cosmetics = true,
        raidCycle = true, activeRecoveryType = true, contracts = true,
        pinnedContractId = true, recentOperations = true, operationOrder = true,
    }
    for key in pairs(old) do
        if type(key) ~= "string" or not allowed[key] then
            return nil, "unknown version-0 field"
        end
    end
    for _, field in ipairs({ "revision", "createdAtUnix", "lastSavedAtUnix", "cash",
        "incomeRemainder", "accreditation", "tutorialStep", "beginnerActiveSeconds" }) do
        if old[field] ~= nil then
            profile[field] = copy(old[field])
        end
    end
    if type(old.lifetime) == "table" then
        local allowedLifetime = {
            npcDeliveries = true, pvpDeliveries = true, recoveryParcels = true,
            distinctRegistered = true, totalCashEarned = true,
        }
        for key, value in pairs(old.lifetime) do
            if not allowedLifetime[key] then
                return nil, "unknown version-0 lifetime field"
            end
            profile.lifetime[key] = copy(value)
        end
    elseif old.lifetime ~= nil then
        return nil, "invalid version-0 lifetime"
    end
    if type(old.settings) == "table" then
        local allowedSettings = {
            masterVolume = true, musicVolume = true, effectsVolume = true,
            reduceMotion = true, lowEffects = true,
        }
        for key, value in pairs(old.settings) do
            if not allowedSettings[key] then
                return nil, "unknown version-0 setting"
            end
            profile.settings[key] = copy(value)
        end
    elseif old.settings ~= nil then
        return nil, "invalid version-0 settings"
    end
    if old.cosmetics ~= nil then
        profile.cosmetics = copy(old.cosmetics)
    end
    if old.raidCycle ~= nil then
        profile.raidCycle = copy(old.raidCycle)
    end
    for _, field in ipairs({ "activeRecoveryType", "contracts", "pinnedContractId",
        "recentOperations", "operationOrder" }) do
        if old[field] ~= nil then
            profile[field] = copy(old[field])
        end
    end

    local registered = old.registered or {}
    if type(registered) ~= "table" then
        return nil, "invalid version-0 registered catalog"
    end
    for itemId, entry in pairs(registered) do
        if type(itemId) ~= "string" or type(entry) ~= "table" then
            return nil, "invalid version-0 exhibit"
        end
        local state = entry.status
        if state ~= "Available" and state ~= "Missing" then
            return nil, "unknown version-0 exhibit status"
        end
        profile.exhibits[itemId] = {
            state = state,
            registeredAtUnix = entry.registeredAt or profile.createdAtUnix,
            acquisition = "Depot",
            missingOperationId = if state == "Missing" then (entry.missingOperationId or ("legacy-missing:" .. itemId)) else nil,
            previousSlotId = nil,
            recoveryJobsDone = if state == "Missing" then (entry.recoveryJobsDone or 0) else 0,
        }
    end
    local slotMap = old.displaySlots or {}
    if type(slotMap) ~= "table" then
        return nil, "invalid version-0 display slots"
    end
    for slotId, itemId in pairs(slotMap) do
        local exhibit = profile.exhibits[itemId]
        if exhibit == nil then
            return nil, "version-0 slot references unregistered item"
        end
        if exhibit.state == "Missing" then
            exhibit.previousSlotId = slotId
        else
            profile.displaySlots[slotId] = itemId
        end
    end
    local count = 0
    for _ in pairs(profile.exhibits) do
        count += 1
    end
    profile.lifetime.distinctRegistered = count
    return profile, nil
end

local function migrate(raw: any, nowUnix: number, nextId: () -> string): (any?, string?)
    if type(raw) ~= "table" then
        return nil, "profile is not a table"
    end
    local candidate: any
    if raw.schemaVersion == Defaults.CurrentSchemaVersion then
        candidate = copy(raw)
    elseif raw.schemaVersion == 4 then
        candidate = copy(raw)
        candidate.schemaVersion = Defaults.CurrentSchemaVersion
    elseif raw.schemaVersion == 3 then
        candidate = copy(raw)
        candidate.schemaVersion = Defaults.CurrentSchemaVersion
    elseif raw.schemaVersion == 2 then
        candidate = copy(raw)
        candidate.schemaVersion = Defaults.CurrentSchemaVersion
        candidate.settings.travelTipsEnabled = true
    elseif raw.schemaVersion == 1 then
        candidate = copy(raw)
    elseif raw.schemaVersion == 0 then
        local migrated, reason = migrateV0(raw, nowUnix, nextId)
        if migrated == nil then
            return nil, reason
        end
        candidate = migrated
    else
        return nil, "unsupported profile version"
    end
    if raw.schemaVersion == 0 or raw.schemaVersion == 1 then
        candidate.schemaVersion = Defaults.CurrentSchemaVersion
        candidate.museum = copy(TierOne.Contract.defaults)
        candidate.settings.travelTipsEnabled = true
        -- The old prototype had a fourth stand. Keep the registered item in
        -- storage until a later tier provides a legal display position.
        candidate.displaySlots.exposed_03 = nil
        for _, exhibit in pairs(candidate.exhibits) do
            if type(exhibit) == "table" and exhibit.previousSlotId == "exposed_03" then
                exhibit.previousSlotId = nil
            end
        end
    end
    if raw.schemaVersion < 4 then
        candidate.collectionIndex = {}
        for itemId in pairs(candidate.exhibits) do
            candidate.collectionIndex[itemId] = true
        end
        candidate.publicDisplayApproved = {}
        for slotId, itemId in pairs(candidate.displaySlots) do
            if slotId ~= "protected" then
                candidate.publicDisplayApproved[itemId] = true
            end
        end
        candidate.publicDisplayMode = "Auto"
    end
    if raw.schemaVersion < 5 then
        candidate.settings.collectionTutorialDone = false
    end
    local valid, reason = Schema.Validate(candidate)
    if not valid then
        return nil, reason
    end
    return candidate, nil
end

return table.freeze({
    Migrate = migrate,
})
