--!strict

-- Task 14F action cues are local one-shots. Passive exhibit clips stay in
-- ExhibitSoundConfig. IDs were loaded in both museum and lobby Studio Play.
local effects = {
    Pickup = { SoundId = "rbxassetid://444895479", Volume = 0.48, MinInterval = 0.4 },
    Displayed = { SoundId = "rbxassetid://9125557143", Volume = 0.46, MinInterval = 0.65 },
    Stored = { SoundId = "rbxassetid://226892749", Volume = 0.36, MinInterval = 0.65 }, -- provisional
    FirstDollar = { SoundId = "rbxassetid://17403146731", Volume = 0.42, MinInterval = 2 },
    Equip = { SoundId = "rbxassetid://1280748610", Volume = 0.38, MinInterval = 0.45 },
    UiClick = { SoundId = "rbxassetid://226892749", Volume = 0.12, MinInterval = 0.12 },
    -- Empty slots are deliberate. Supply and validate short owned clips in Studio.
    Drop = { SoundId = "", Volume = 0.38, MinInterval = 0.5 },
    QueueAccepted = { SoundId = "", Volume = 0.32, MinInterval = 0.7 },
    QueueFailed = { SoundId = "", Volume = 0.32, MinInterval = 0.7 },
    Deployment = { SoundId = "", Volume = 0.42, MinInterval = 1 },
    Restock = { SoundId = "", Volume = 0.30, MinInterval = 1.5 },
    ExtractionCancelled = { SoundId = "", Volume = 0.36, MinInterval = 0.6 },
}

local music = {
    Lobby = { SoundId = "rbxassetid://9043887091", Volume = 0.12 },
    Museum = { SoundId = "rbxassetid://1848354536", Volume = 0.11 },
    Carry = { SoundId = "rbxassetid://1837323245", Volume = 0.12 },
}

local mix = {
    ChaseMusicGain = 0.8,
    WarningMusicGain = 0.3,
    ExtractionMusicGain = 0.25,
    ActionMusicGain = 0.45,
}

return table.freeze({ Effects = table.freeze(effects), Music = table.freeze(music), Mix = table.freeze(mix) })
