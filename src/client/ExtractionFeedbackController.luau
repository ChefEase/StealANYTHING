--!strict

-- Presents only the server-owned extraction state. No travel request is sent here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local Machine = require(ReplicatedStorage.Shared.ExtractionMachineVfx)
local Audio = require(ReplicatedStorage.Shared.HeistAudioConfig)
local ExtractionAudio = require(ReplicatedStorage.Shared.ExtractionAudioConfig)

local ExtractionFeedbackController = {}

function ExtractionFeedbackController.Start(player: Player)
    if ExtractionAudio.HumSoundId ~= "" then
        task.spawn(function()
            local preload = Instance.new("Sound")
            preload.Name = "ExtractionHumPreload"
            preload.SoundId = ExtractionAudio.HumSoundId
            preload.Volume = 0
            preload.Parent = SoundService
            pcall(function() ContentProvider:PreloadAsync({ preload }) end)
            preload:Destroy()
        end)
    end
    local controller: any = nil
    local target: BasePart? = nil
    local visualRoot: Folder? = nil
    local generation = 0
    local wasActive = false
    local finished = false

    local function destroy()
        generation += 1
        if controller then controller:Destroy(); controller = nil end
        if target then target:Destroy(); target = nil end
        visualRoot = nil
    end

    local function begin()
        if controller or player:GetAttribute("ExtractionActive") ~= true then return end
        finished = false
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then return end
        local padPosition = player:GetAttribute("ExtractionPadWorldPosition")
        if typeof(padPosition) ~= "Vector3" then return end
        local marker = Instance.new("Part")
        marker.Name = "LocalExtractionVisualTarget"
        marker.Size = Vector3.new(.2, .2, .2)
        marker.CFrame = CFrame.new(padPosition)
        marker.Anchored = true
        marker.Transparency = 1
        marker.CanCollide = false
        marker.CanTouch = false
        marker.CanQuery = false
        marker.Parent = workspace
        target = marker
        local folder = Instance.new("Folder")
        folder.Name = "LocalExtractionMachine"
        folder.Parent = workspace
        visualRoot = folder
        local mode = if player:GetAttribute("ReduceMotion") == true then "Reduced motion"
            elseif player:GetAttribute("LowEffects") == true then "Low effects" else "Normal"
        local master = player:GetAttribute("MasterVolume")
        local effects = player:GetAttribute("EffectsVolume")
        local gain = (if type(master) == "number" then math.clamp(master, 0, 1) else 1)
            * (if type(effects) == "number" then math.clamp(effects, 0, 1) else 1)
        controller = Machine.Create(folder, marker, mode, gain)
        controller:SetState("Activation")
        local token = generation
        task.delay(.18, function()
            if token ~= generation or not controller
                or player:GetAttribute("ExtractionActive") ~= true then return end
            local endsAt = player:GetAttribute("ExtractionEndsAt")
            local duration = player:GetAttribute("ExtractionDuration")
            local progress = if type(endsAt) == "number" and type(duration) == "number"
                and duration > 0 then math.clamp(1 - (endsAt - workspace:GetServerTimeNow()) / duration, 0, 1)
                else 0
            controller:SetState("Charging", progress)
        end)
    end

    local function finish()
        if not controller or finished then return end
        local outcome = player:GetAttribute("ExtractionOutcome")
        if outcome ~= "Completed" and outcome ~= "Cancelled" then return end
        finished = true
        controller:SetState(if outcome == "Completed" then "Completion" else "Cancellation")
        if outcome == "Cancelled" and target then
            local spec = Audio.Effects.ExtractionCancelled
            if spec.SoundId ~= "" then
                local sound = Instance.new("Sound")
                sound.SoundId = spec.SoundId
                local master = player:GetAttribute("MasterVolume")
                local effects = player:GetAttribute("EffectsVolume")
                sound.Volume = spec.Volume
                    * (if type(master) == "number" then math.clamp(master, 0, 1) else 1)
                    * (if type(effects) == "number" then math.clamp(effects, 0, 1) else 1)
                sound.RollOffMaxDistance = 32
                sound.Parent = target
                sound:Play()
                Debris:AddItem(sound, .45)
            end
        end
        local token = generation
        task.delay(.48, function()
            if token == generation and player:GetAttribute("ExtractionActive") ~= true then destroy() end
        end)
    end

    player:GetAttributeChangedSignal("ExtractionActive"):Connect(function()
        local active = player:GetAttribute("ExtractionActive") == true
        if active then
            destroy()
            begin()
        elseif wasActive then
            -- Outcome may replicate just after Active; defer to read the final result.
            task.defer(finish)
            local token = generation
            task.delay(.35, function()
                if token == generation and controller and not finished
                    and player:GetAttribute("ExtractionActive") ~= true then
                    if player:GetAttribute("ExtractionOutcome") == nil then
                        finished = true
                        controller:SetState("Cancellation")
                        task.delay(.48, destroy)
                    else
                        finish()
                    end
                end
            end)
        end
        wasActive = active
    end)
    player.CharacterRemoving:Connect(destroy)
    player:GetAttributeChangedSignal("ExtractionOutcome"):Connect(function()
        if wasActive and player:GetAttribute("ExtractionActive") ~= true then finish() end
    end)
    player:GetAttributeChangedSignal("ExtractionPadWorldPosition"):Connect(function()
        if player:GetAttribute("ExtractionActive") == true then begin() end
    end)
    if player:GetAttribute("ExtractionActive") == true then
        wasActive = true
        begin()
    end
end

return table.freeze(ExtractionFeedbackController)
