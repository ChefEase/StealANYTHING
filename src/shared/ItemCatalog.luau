--!strict

local Types = require(script.Parent.Types)
type ItemDefinition = Types.ItemDefinition

local orderedIds = {
    "toaster", "duck", "traffic_cone", "disco_bin", "gold_toilet", "jelly_lamp",
    "snack_machine", "moon_rock", "mini_ufo", "dinosaur_skull", "storm_jar", "giant_diamond",
}

local byId: {[string]: ItemDefinition} = {
    toaster = { id = "toaster", name = "Dramatic Toaster", tier = "Common", carry = "Noisy", sizeClass = "Small", baseIncomePerMinute = 12, shopPrice = 180, depotWeight = 20, modelKey = "toaster", iconKey = "toaster" },
    duck = { id = "duck", name = "Springy Rubber Duck", tier = "Common", carry = "Bouncy", sizeClass = "Small", baseIncomePerMinute = 14, shopPrice = 220, depotWeight = 18, modelKey = "duck", iconKey = "duck" },
    traffic_cone = { id = "traffic_cone", name = "Royal Traffic Cone", tier = "Common", carry = "Heavy", sizeClass = "Medium", baseIncomePerMinute = 16, shopPrice = 280, depotWeight = 16, modelKey = "traffic_cone", iconKey = "traffic_cone" },
    disco_bin = { id = "disco_bin", name = "Disco Dustbin", tier = "Common", carry = "Noisy", sizeClass = "Medium", baseIncomePerMinute = 18, shopPrice = 340, depotWeight = 14, modelKey = "disco_bin", iconKey = "disco_bin" },
    gold_toilet = { id = "gold_toilet", name = "Golden Toilet", tier = "Uncommon", carry = "Heavy", sizeClass = "Medium", baseIncomePerMinute = 26, depotWeight = 8, modelKey = "gold_toilet", iconKey = "gold_toilet" },
    jelly_lamp = { id = "jelly_lamp", name = "Jelly Lamp", tier = "Uncommon", carry = "Bouncy", sizeClass = "Small", baseIncomePerMinute = 28, depotWeight = 7, modelKey = "jelly_lamp", iconKey = "jelly_lamp" },
    snack_machine = { id = "snack_machine", name = "Rattling Snack Machine", tier = "Uncommon", carry = "Noisy", sizeClass = "Heavy", baseIncomePerMinute = 30, depotWeight = 6, modelKey = "snack_machine", iconKey = "snack_machine" },
    moon_rock = { id = "moon_rock", name = "Suspicious Moon Rock", tier = "Uncommon", carry = "Heavy", sizeClass = "Medium", baseIncomePerMinute = 32, depotWeight = 5, modelKey = "moon_rock", iconKey = "moon_rock" },
    mini_ufo = { id = "mini_ufo", name = "Spring-Mounted Mini UFO", tier = "Rare", carry = "Bouncy", sizeClass = "Medium", baseIncomePerMinute = 44, depotWeight = 2, modelKey = "mini_ufo", iconKey = "mini_ufo" },
    dinosaur_skull = { id = "dinosaur_skull", name = "Tiny Dinosaur’s Giant Skull", tier = "Rare", carry = "Heavy", sizeClass = "Heavy", baseIncomePerMinute = 48, depotWeight = 2, modelKey = "dinosaur_skull", iconKey = "dinosaur_skull" },
    storm_jar = { id = "storm_jar", name = "Storm in a Jar", tier = "Rare", carry = "Noisy", sizeClass = "Small", baseIncomePerMinute = 52, depotWeight = 1.5, modelKey = "storm_jar", iconKey = "storm_jar" },
    giant_diamond = { id = "giant_diamond", name = "Absurdly Large Diamond", tier = "Legendary", carry = "Heavy", sizeClass = "Heavy", baseIncomePerMinute = 70, depotWeight = 0.5, modelKey = "giant_diamond", iconKey = "giant_diamond" },
}

for _, definition in pairs(byId) do
    table.freeze(definition)
end

return table.freeze({
    OrderedIds = table.freeze(orderedIds),
    ById = table.freeze(byId),
})
