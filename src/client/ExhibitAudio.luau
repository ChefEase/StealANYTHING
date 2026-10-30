-- Quiet local one-shots: never a room full of looping exhibit audio.
local Config = require(game:GetService("ReplicatedStorage").Shared.ExhibitSoundConfig)
local TweenService = game:GetService("TweenService")
local Audio = {}
local entries = {}
local nextAllowed = 0

function Audio.Add(joint)
    if joint:GetAttribute("MotionChannel") == "chassis" then return end
    local spec = Config.Items[joint:GetAttribute("ItemId")]
    if not spec or spec.SoundId == "" or not joint.Part0 then return end
    local sound = Instance.new("Sound")
    sound.Name = "ExhibitAccentSound"
    sound.SoundId = spec.SoundId
    sound.Volume = spec.Volume
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    -- Allow for the third-person camera behind the player.
    sound.RollOffMinDistance = 8
    sound.RollOffMaxDistance = 28
    sound.Looped = false
    sound.Parent = joint.Part0
    entries[joint] = { sound = sound, spec = spec, nextPlay = 0, near = false }
end

function Audio.Update(time)
    local camera = workspace.CurrentCamera
    for joint, entry in entries do
        local sound, spec = entry.sound, entry.spec
        if not joint:IsDescendantOf(workspace) or not joint.Part0 then
            sound:Destroy()
            entries[joint] = nil
            continue
        end
        local distance = if camera then (camera.CFrame.Position - joint.Part0.Position).Magnitude else math.huge
        local near = distance < (if entry.near then 28 else 24)
        if near and not entry.near then
            entry.nextPlay = math.max(time + 0.35, entry.nextPlay)
        end
        entry.near = near
        if near and time >= entry.nextPlay and time >= nextAllowed and sound.IsLoaded then
            nextAllowed = time + math.max(1.5, spec.MaxDuration + 0.15)
            entry.nextPlay = (math.floor(time / spec.Period) + 1) * spec.Period
            if entry.nextPlay - time < 2 then entry.nextPlay += spec.Period end
            sound.Volume = spec.Volume
            sound.TimePosition = spec.StartTime or 0
            sound:Play()
            task.delay(math.max(0, spec.MaxDuration - 0.12), function()
                if not sound.Parent or not sound.IsPlaying then return end
                local fade = TweenService:Create(sound, TweenInfo.new(0.12), { Volume = 0 })
                fade:Play()
                fade.Completed:Once(function()
                    if sound.Parent then sound:Stop(); sound.Volume = spec.Volume end
                end)
            end)
        end
    end
end

return Audio
