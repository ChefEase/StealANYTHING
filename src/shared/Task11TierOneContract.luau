--!strict

-- Task 11b handoff only. Task 12 applies this contract when it migrates
-- profiles and creates player-owned museum clones. No live profile is changed.
local Plots = require(script.Parent.PlotDefinitions)
local Visuals = require(script.Parent.Task11VisualDefinitions)

local socketNamesById = table.freeze({
    protected = "ProtectedDisplaySocket",
    exposed_01 = "Exposed01Socket",
    exposed_02 = "Exposed02Socket",
})
local socketIds = table.freeze({ "protected", "exposed_01", "exposed_02" })
local defaults = table.freeze({
    version = 1,
    tier = 1,
    styleId = "starter",
    groundsPresetId = Visuals.Presets[1].id,
    securityLevel = 0,
})

local function validate(manifest: any): (boolean, string?)
    if type(manifest) ~= "table" or type(manifest.defaults) ~= "table"
        or type(manifest.socketIds) ~= "table"
        or type(manifest.socketNamesById) ~= "table" then
        return false, "missing tier-one manifest fields"
    end
    local d = manifest.defaults
    if d.version ~= 1 or d.tier ~= 1 or Plots.Tiers[d.tier] == nil
        or Plots.Tiers[d.tier].standCount ~= 3
        or d.styleId ~= "starter" or d.groundsPresetId ~= Visuals.Presets[1].id
        or d.securityLevel ~= 0 then
        return false, "invalid tier-one defaults"
    end
    if #manifest.socketIds ~= 3 then return false, "expected three tier-one sockets" end
    local seen: {[string]: boolean} = {}
    for _, id in ipairs(manifest.socketIds) do
        if type(id) ~= "string" or seen[id] or socketNamesById[id] == nil
            or manifest.socketNamesById[id] ~= socketNamesById[id] then
            return false, "duplicate or unknown tier-one socket"
        end
        seen[id] = true
    end
    for id in pairs(socketNamesById) do
        if not seen[id] then return false, "missing tier-one socket" end
    end
    return true, nil
end

local contract = table.freeze({
    defaults = defaults,
    socketIds = socketIds,
    socketNamesById = socketNamesById,
})
assert(validate(contract))
return table.freeze({ Contract = contract, Validate = validate })
