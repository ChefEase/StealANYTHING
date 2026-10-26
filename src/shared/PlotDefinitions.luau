--!strict

-- Fixed maximum reservations. PlotService (Task 12) will assign these slots;
-- temporary ownership and clone identity must not be saved in player profiles.
local tiers = {
    { tier = 1, name = "Starter", buildingStuds = 60, standCount = 3, groundsStuds = 120 },
    { tier = 2, name = "Growing", buildingStuds = 80, standCount = 6, groundsStuds = 160 },
    { tier = 3, name = "Expanded", buildingStuds = 110, standCount = 10, groundsStuds = 200 },
    { tier = 4, name = "Prestigious", buildingStuds = 140, standCount = 15, groundsStuds = 240 },
    { tier = 5, name = "Grand", buildingStuds = 170, standCount = 20, groundsStuds = 280 },
}

-- Yaw rotates the template's south-facing entrance toward the depot.
-- The hexagonal arrangement keeps every starter gate 300–317 studs from it.
local slots = {
    { id = "plot_01", center = Vector3.new(0, 0, 360), yawDegrees = 0 },
    { id = "plot_02", center = Vector3.new(320, 0, 180), yawDegrees = 90 },
    { id = "plot_03", center = Vector3.new(320, 0, -180), yawDegrees = 90 },
    { id = "plot_04", center = Vector3.new(0, 0, -360), yawDegrees = 180 },
    { id = "plot_05", center = Vector3.new(-320, 0, -180), yawDegrees = -90 },
    { id = "plot_06", center = Vector3.new(-320, 0, 180), yawDegrees = -90 },
}

for _, tier in tiers do table.freeze(tier) end
for _, slot in slots do table.freeze(slot) end

return table.freeze({
    MaximumEnvelopeStuds = 280,
    DepotCenter = Vector3.new(0, 0, 0),
    WorldGroundStuds = Vector2.new(1_000, 1_080),
    Tiers = table.freeze(tiers),
    Slots = table.freeze(slots),
})
