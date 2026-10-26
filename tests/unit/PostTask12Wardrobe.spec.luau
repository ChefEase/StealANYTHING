--!strict
-- Run in Studio Edit after syncing the museum place. Uses only in-memory data.
local server = game.ServerScriptService.Server
local catalog = require(game.ReplicatedStorage.Shared.WardrobeCatalog)
local defaults = require(server.Data.ProfileDefaults)
local schema = require(server.Data.ProfileSchema)
local rules = require(server.Domain.WardrobePurchaseRules)

assert(#catalog.Items == 7)
assert(#catalog.PreviewItems == 3 and #catalog.DisplayItems == 10)
assert(catalog.ById.starter_mask ~= nil) -- saved free mask remains valid
local nextId = 0
local profile = defaults.Create(1800000000, function()
    nextId += 1
    return "wardrobe-test-" .. nextId
end)
assert(schema.Validate(profile))
assert(catalog.ValidLoadout({ Outfit = "starter_outfit", Face = "starter_mask" }, {}))
assert(not catalog.ValidLoadout({ Face = "ski_mask" }, {}))
assert(not catalog.ValidLoadout({ Speed = "starter_mask" }, {}))
assert(not catalog.ValidLoadout({ Outfit = "neon_phantom_outfit" }, {}))

local rejected, reason = rules.Apply(profile, "unknown")
assert(rejected == "Rejected" and reason == "InvalidItem" and profile.cash == 100)
rejected, reason = rules.Apply(profile, "ski_mask")
assert(rejected == "Rejected" and reason == "InsufficientCash" and profile.cash == 100)
rejected, reason = rules.Apply(profile, "neon_phantom_outfit")
assert(rejected == "Rejected" and reason == "InvalidItem" and profile.cash == 100)
profile.cash = 500
local result, code = rules.Apply(profile, "ski_mask")
assert(result == "Committed" and code == "Purchased")
assert(profile.cash == 100 and profile.cosmetics.ski_mask == true)
result, code = rules.Apply(profile, "ski_mask")
assert(result == "Rejected" and code == "AlreadyOwned" and profile.cash == 100)
assert(schema.Validate(profile))
assert(catalog.ValidLoadout({ Face = "ski_mask" }, profile.cosmetics))
print("Post-Task-12 wardrobe catalog and purchase rules: PASS")
