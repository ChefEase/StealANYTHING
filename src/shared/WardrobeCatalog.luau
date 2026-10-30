--!strict

-- Cash prices are initial tuning values. Robux looks are preview-only until
-- Tasks 37-38 approve exact offers, marketplace IDs, and durable fulfillment.
local items = {
    { id = "starter_outfit", name = "Starter Robber", slot = "Outfit", price = 0, currency = "Free",
        note = "A lightweight hooded jacket, dark trousers, and bandana." },
    { id = "ski_mask", name = "Black Ski Mask", slot = "Face", price = 400, currency = "Cash",
        note = "Full black balaclava with two eye openings." },
    { id = "classic_outfit", name = "Classic Burglar", slot = "Outfit", price = 1400, currency = "Cash",
        note = "Striped pullover, knit cap, belt, and dark gloves." },
    { id = "street_outfit", name = "Street Robber", slot = "Outfit", price = 5200, currency = "Cash",
        note = "Oversized bomber jacket, raised collar, cuffs, and crossbody pouch." },
    { id = "tactical_outfit", name = "Tactical Heist", slot = "Outfit", price = 15000, currency = "Cash",
        note = "Armored vest, shoulder plates, utility belt, and knee guards." },
    { id = "getaway_bag", name = "Getaway Bag", slot = "Body", price = 750, currency = "Cash",
        note = "A hand-carried duffel with a real handle; no extra carry capacity." },
    { id = "phantom_glow", name = "Phantom Glow", slot = "Special", price = 2200, currency = "Cash",
        note = "Living blue aura: pulsing halo, orbiting spirit wisps, a spinning rune circle, and rising sparks." },
}

local previewItems = {
    { id = "neon_phantom_outfit", name = "Neon Phantom", slot = "Outfit", price = 0,
        currency = "Robux", draftRobuxPrice = 99,
        note = "Cyan holographic contours, a moving scan plane and glitch fragments. Robux preview only." },
    { id = "shadow_king_outfit", name = "Shadow King", slot = "Outfit", price = 0,
        currency = "Robux", draftRobuxPrice = 199,
        note = "Violet crown and an unfolding throne of living shadow blades. Robux preview only." },
    { id = "legendary_animated_outfit", name = "Legendary Robber", slot = "Outfit", price = 0,
        currency = "Robux", draftRobuxPrice = 399,
        note = "Gold coat, a floating royal card fan and tumbling jackpot coins. Robux preview only." },
}

local byId: {[string]: any} = {}
local slotNames = { Outfit = true, Face = true, Body = true, Special = true }
for _, item in items do
    assert(byId[item.id] == nil and slotNames[item.slot])
    byId[item.id] = table.freeze(item)
end
for _, item in previewItems do
    assert(byId[item.id] == nil and slotNames[item.slot])
    byId[item.id] = table.freeze(item)
end
-- Older saves may have the free bandana equipped as a separate Face slot.
-- Keep that ID valid, but show one combined Starter Robber entry in the shop.
byId.starter_mask = table.freeze({ id = "starter_mask", name = "Bandit Mask",
    slot = "Face", price = 0, currency = "Free", note = "Starter bandana." })

local function starterOwned(): {[string]: boolean}
    return { starter_outfit = true, starter_mask = true }
end

local function validLoadout(loadout: any, owned: {[string]: boolean}): boolean
    if type(loadout) ~= "table" then return false end
    for slot, id in pairs(loadout) do
        if slotNames[slot] ~= true or type(id) ~= "string" then return false end
        local item = byId[id]
        if item == nil or item.slot ~= slot or (item.currency ~= "Free" and owned[id] ~= true) then
            return false
        end
    end
    return true
end

local displayItems = table.clone(items)
for _, item in previewItems do table.insert(displayItems, item) end

return table.freeze({ Items = table.freeze(items), PreviewItems = table.freeze(previewItems),
    DisplayItems = table.freeze(displayItems), ById = table.freeze(byId),
    Slots = table.freeze(slotNames), StarterOwned = starterOwned,
    ValidLoadout = validLoadout })
