--!strict

-- Emotes for the character preview in the menu (M). While the preview is
-- visible, it plays one emote, pauses briefly, then plays another. Each emote
-- plays once before any repeats.
--
-- Roblox's default R15 gestures and dances. These are animation asset IDs,
-- not the catalog IDs of emote items. Replace them here to change the set.
return table.freeze({
    INTERVAL_SECONDS = 2,
    -- Stop a long or looping emote after this many seconds.
    MAX_PLAY_SECONDS = 12,
    ANIMATION_IDS = table.freeze({
        507770239, -- Wave
        507770453, -- Point
        507770677, -- Cheer
        507770818, -- Laugh
        507771019, -- Dance A1
        507771955, -- Dance A2
        507772104, -- Dance A3
        507776043, -- Dance B1
        507776720, -- Dance B2
        507777268, -- Dance C1
    }),
})
