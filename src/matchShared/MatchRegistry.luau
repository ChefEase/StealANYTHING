--!strict
local MemoryStoreService = game:GetService("MemoryStoreService")
local Config = require(script.Parent.PlaceConfig)
local MatchState = require(script.Parent.MatchState)

local map = MemoryStoreService:GetHashMap(Config.RegistryName)
local Registry = {}

function Registry.Read(): (any?, string?)
    local ok, value = pcall(function()
        return map:GetAsync(Config.RegistryKey)
    end)
    if not ok then return nil, tostring(value) end
    return MatchState.Prune(value, os.time()), nil
end

function Registry.Update(transform: (any) -> any): (any?, string?)
    local ok, value = pcall(function()
        return map:UpdateAsync(Config.RegistryKey, function(old)
            return transform(old)
        end, Config.RegistryExpiration)
    end)
    if not ok then return nil, tostring(value) end
    return value, nil
end

return table.freeze(Registry)
