--!strict

-- No Roblox assets have been published yet. Never pass these sentinels to an
-- asset-loading API. Replace only with owner-supplied, verified numeric IDs.
local UNASSIGNED = "UNASSIGNED_ASSET_ID"

return table.freeze({
    Unassigned = UNASSIGNED,
    CollectibleModels = table.freeze({
        toaster = UNASSIGNED, duck = UNASSIGNED, traffic_cone = UNASSIGNED,
        disco_bin = UNASSIGNED, gold_toilet = UNASSIGNED, jelly_lamp = UNASSIGNED,
        snack_machine = UNASSIGNED, moon_rock = UNASSIGNED, mini_ufo = UNASSIGNED,
        dinosaur_skull = UNASSIGNED, storm_jar = UNASSIGNED, giant_diamond = UNASSIGNED,
    }),
    CollectibleIcons = table.freeze({
        toaster = UNASSIGNED, duck = UNASSIGNED, traffic_cone = UNASSIGNED,
        disco_bin = UNASSIGNED, gold_toilet = UNASSIGNED, jelly_lamp = UNASSIGNED,
        snack_machine = UNASSIGNED, moon_rock = UNASSIGNED, mini_ufo = UNASSIGNED,
        dinosaur_skull = UNASSIGNED, storm_jar = UNASSIGNED, giant_diamond = UNASSIGNED,
    }),
    SupporterPass = UNASSIGNED,
})
