--!strict

-- Shared shell palette for every gameplay HUD and the operations menu.
-- Map parchment and warning/error states keep their semantic colors.
return table.freeze({
    Ink = Color3.fromRGB(8, 15, 14),
    Panel = Color3.fromRGB(15, 28, 25),
    Accent = Color3.fromRGB(74, 235, 194),
    Text = Color3.fromRGB(238, 244, 237),
    Muted = Color3.fromRGB(154, 173, 164),
    Outline = Color3.fromRGB(51, 82, 68),
    Selected = Color3.fromRGB(39, 80, 63),
})
