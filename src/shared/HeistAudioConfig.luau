--!strict

-- Task 14F action cues are local one-shots. Passive exhibit clips stay in
-- ExhibitSoundConfig. IDs were loaded in both museum and lobby Studio Play.
local effects = {
    Pickup = { SoundId = "rbxassetid://444895479", Volume = 0.48, MinInterval = 0.4 },
    Displayed = { SoundId = "rbxassetid://9125557143", Volume = 0.46, MinInterval = 0.65 },
    Stored = { SoundId = "rbxassetid://226892749", Volume = 0.36, MinInterval = 0.65 }, -- provisional
    FirstDollar = { SoundId = "rbxassetid://17403146731", Volume = 0.42, MinInterval = 2 },
    Equip = { SoundId = "rbxassetid://1280748610", Volume = 0.38, MinInterval = 0.45 },
    UiClick = { SoundId = "rbxassetid://226892749", Volume = 0.28, MinInterval = 0.08 },
}

local music = {
    Lobby = { SoundId = "rbxassetid://9043887091", Volume = 0.12 },
    Museum = { SoundId = "rbxassetid://1848354536", Volume = 0.11 },
    Carry = { SoundId = "rbxassetid://1837323245", Volume = 0.12 },
}

return table.freeze({ Effects = table.freeze(effects), Music = table.freeze(music) })
