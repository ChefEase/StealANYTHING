--!strict

local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(script.Parent.HeistAudioConfig)

local HeistMusic = {}

local function gain(player: Player): number
    local master = player:GetAttribute("MasterVolume")
    local music = player:GetAttribute("MusicVolume")
    return math.clamp(if type(master) == "number" then master else 1, 0, 1)
        * math.clamp(if type(music) == "number" then music else 1, 0, 1)
end

function HeistMusic.Start(player: Player, place: string, screen: ScreenGui?)
    local sounds: {[string]: Sound} = {}
    for name, spec in Config.Music do
        if (place == "Lobby" and name == "Lobby")
            or (place ~= "Lobby" and name ~= "Lobby") then
            local sound = Instance.new("Sound")
            sound.Name = "HeistMusic_" .. name
            sound.SoundId = spec.SoundId
            sound.Volume = 0
            sound.Looped = true
            sound.Parent = SoundService
            sounds[name] = sound
            task.spawn(function()
                pcall(function() ContentProvider:PreloadAsync({ sound }) end)
            end)
        end
    end

    local duckUntil = 0
    local elapsed = 0
    local handle = {}
    function handle.DuckFor(seconds: number)
        duckUntil = math.max(duckUntil, os.clock() + seconds)
    end

    RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 0.12 then return end
        local step = elapsed
        elapsed = 0
        local desired = if place == "Lobby" then "Lobby"
            elseif type(player:GetAttribute("CarryId")) == "string" then "Carry"
            else "Museum"
        local chase = player:GetAttribute("GuardState") == "Chase"
            or player:GetAttribute("GuardState") == "Capture"
        local extraction = player:GetAttribute("ExtractionActive") == true
        local warning = screen ~= nil and screen:GetAttribute("GuardWarningVisible") == true
        local duck = if extraction then Config.Mix.ExtractionMusicGain
            elseif chase then Config.Mix.ChaseMusicGain
            elseif warning then Config.Mix.WarningMusicGain
            elseif os.clock() < duckUntil then Config.Mix.ActionMusicGain else 1
        local multiplier = gain(player)
        for name, sound in sounds do
            local spec = Config.Music[name]
            local target = if name == desired then spec.Volume * multiplier * duck else 0
            if target > 0 and sound.IsLoaded and not sound.IsPlaying then sound:Play() end
            sound.Volume += (target - sound.Volume) * math.min(1, step * 3.5)
            if target == 0 and sound.IsPlaying and sound.Volume < 0.001 then sound:Stop() end
        end
    end)
    return handle
end

return table.freeze(HeistMusic)
