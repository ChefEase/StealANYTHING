--!strict

-- Cosmetic-only data for the Task 11 visual kit. Coordinates are local to a
-- starter plot whose entrance faces local -Z; the plot pivot supplies rotation.
local palette = {

    ivory = Color3.fromRGB(224, 218, 205),
    stone = Color3.fromRGB(192, 190, 181),
    charcoal = Color3.fromRGB(49, 53, 57),
    bronze = Color3.fromRGB(137, 105, 67),
    walnut = Color3.fromRGB(111, 78, 54),
    paving = Color3.fromRGB(135, 141, 144),
    lawn = Color3.fromRGB(88, 125, 79),
    hedge = Color3.fromRGB(49, 91, 61),
    soil = Color3.fromRGB(79, 66, 54),
    glass = Color3.fromRGB(157, 203, 202),
    warmLight = Color3.fromRGB(255, 226, 170),
    entranceGold = Color3.fromRGB(194, 150, 68),
    entranceTeal = Color3.fromRGB(58, 112, 116),
}

local presets = {
    { id = "formal_garden", label = "Formal Garden" },
    { id = "naturalistic_garden", label = "Naturalistic Garden" },
    { id = "sculpture_garden", label = "Sculpture Garden" },
    { id = "classical_estate", label = "Classical Estate" },
    { id = "contemporary_minimalist", label = "Contemporary Minimalist" },
    { id = "urban_collectors_estate", label = "Urban Collector's Estate" },
}

for _, preset in presets do
    table.freeze(preset)
end

return table.freeze({
    Palette = table.freeze(palette),
    Presets = table.freeze(presets),
})
