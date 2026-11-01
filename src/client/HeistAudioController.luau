--!strict

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.HeistAudioConfig)

local HeistAudioController = {}

local function effectsGain(player: Player): number
    local master = player:GetAttribute("MasterVolume")
    local effects = player:GetAttribute("EffectsVolume")
    return math.clamp(if type(master) == "number" then master else 1, 0, 1)
        * math.clamp(if type(effects) == "number" then effects else 1, 0, 1)
end

function HeistAudioController.Start(player: Player, music: any)
    local sounds: {[string]: Sound} = {}
    for name, spec in Config.Effects do
        if name ~= "UiClick" and spec.SoundId ~= "" then
            local sound = Instance.new("Sound")
            sound.Name = "HeistCue_" .. name
            sound.SoundId = spec.SoundId
            sound.Volume = 0
            sound.Parent = SoundService
            sounds[name] = sound
            task.spawn(function()
                pcall(function() ContentProvider:PreloadAsync({ sound }) end)
            end)
        end
    end

    local played: {[string]: number} = {}
    local lastType: {[string]: number} = {}
    local lastAny = -math.huge
    local function play(name: string, uniqueId: string)
        local sound = sounds[name]
        local spec = Config.Effects[name]
        if sound == nil or spec == nil or not sound.IsLoaded then return end
        local now = os.clock()
        local key = name .. ":" .. uniqueId
        if played[key] ~= nil or now - lastAny < 0.12
            or now - (lastType[name] or -math.huge) < spec.MinInterval then return end
        played[key] = now
        lastType[name] = now
        lastAny = now
        for oldKey, at in played do
            if now - at > 90 then played[oldKey] = nil end
        end
        local volume = spec.Volume * effectsGain(player)
        if volume <= 0 then return end
        if sound.IsPlaying then sound:Stop() end
        sound.TimePosition = 0
        sound.Volume = volume
        sound:Play()
        if music and type(music.DuckFor) == "function" then music.DuckFor(0.9) end
    end

    local lastCarryId = player:GetAttribute("CarryId")
    local function pickupConfirmed()
        local carryId = player:GetAttribute("CarryId")
        local itemId = player:GetAttribute("CarryItemId")
        if type(carryId) ~= "string" or carryId == ""
            or type(itemId) ~= "string" or carryId == lastCarryId then return end
        lastCarryId = carryId
        play("Pickup", carryId)
    end
    player:GetAttributeChangedSignal("CarryId"):Connect(pickupConfirmed)
    player:GetAttributeChangedSignal("CarryItemId"):Connect(pickupConfirmed)

    local lastTutorialStep = player:GetAttribute("TutorialStep")
    player:GetAttributeChangedSignal("TutorialStep"):Connect(function()
        local step = player:GetAttribute("TutorialStep")
        if lastTutorialStep == 1 and step == 2 then
            play("FirstDollar", "first-tutorial-income")
        end
        lastTutorialStep = step
    end)

    local feedback = ReplicatedStorage.Network:WaitForChild("Feedback") :: RemoteEvent
    feedback.OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" or payload.kind ~= "Success"
            or type(payload.cueId) ~= "string" then return end
        if payload.cue == "DeliveredDisplayed" then
            play("Displayed", payload.cueId)
        elseif payload.cue == "DeliveredStored" then
            play("Stored", payload.cueId)
        elseif payload.cue == "CollectionChanged" then
            play("Equip", payload.cueId)
        end
    end)
end

return table.freeze(HeistAudioController)
