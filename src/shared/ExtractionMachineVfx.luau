-- Client-only extraction presentation. The caller supplies server-owned states.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Balance = require(game:GetService("ReplicatedStorage").Shared.BalanceConfig)
local Audio = require(script.Parent.ExtractionAudioConfig)

local Prototype = {}
local TEAL = Color3.fromRGB(74, 235, 194)
local PALE = Color3.fromRGB(160, 255, 239)
local AMBER = Color3.fromRGB(255, 170, 83)
local STEEL = Color3.fromRGB(26, 43, 49)
local CHARGE_SECONDS = math.max(.1, Balance.PUBLIC_EXTRACTION_SECONDS - .35)

local function part(parent, name, size, cf, color, material, alpha)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material
    p.Transparency = alpha or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = parent
    return p
end

local function disk(parent, name, center, diameter, height, color, material, alpha)
    local p = part(parent, name, Vector3.new(height, diameter, diameter),
        CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)),
        color, material, alpha)
    p.Shape = Enum.PartType.Cylinder
    return p
end

local function ringFrame(center, radius, angle)
    return CFrame.new(center + Vector3.new(radius * math.cos(angle), 0,
        radius * math.sin(angle))) * CFrame.Angles(0, -angle - math.pi / 2, 0)
end

function Prototype.Create(root, target, mode, effectsGain)
    local low = mode == "Low effects"
    local reduced = mode == "Reduced motion"
    local center = target.Position + Vector3.new(0, .24, 0)
    local model = Instance.new("Model")
    model.Name = "ExtractionMachinePrototype"
    model.Parent = root
    disk(model, "MachineBase", center, 9.4, .34, STEEL, Enum.Material.Metal, 0)
    disk(model, "InsetDeck", center + Vector3.new(0, .2, 0), 7.5, .11,
        Color3.fromRGB(43, 65, 70), Enum.Material.Metal, 0)
    local core = disk(model, "EnergyCore", center + Vector3.new(0, .27, 0), 2.3, .04,
        TEAL, Enum.Material.Neon, .85)
    local ringCenter = center + Vector3.new(0, .29, 0)
    local outer = {}
    local inner = {}
    for _, spec in { { outer, if low then 12 else 18, 4.1, .17, "Outer" },
        { inner, if low then 8 else 12, 2.65, .11, "Charging" } } do
        local pieces, count, radius, width, prefix = spec[1], spec[2], spec[3], spec[4], spec[5]
        for index = 1, count do
            local angle = (index - 1) * 2 * math.pi / count
            pieces[index] = part(model, prefix .. "Ring" .. index,
                Vector3.new(2 * math.pi * radius / count * .8, .055, width),
                ringFrame(ringCenter, radius, angle), TEAL,
                Enum.Material.Neon, .78)
        end
    end
    -- Reference A's recognizable elevated ring, scaled down so a player and
    -- the guard remain readable through the charging machine.
    local crown = {}
    local crownCenter = center + Vector3.new(0, 4.35, 0)
    local crownCount = if low then 8 else 14
    for index = 1, crownCount do
        local angle = (index - 1) * 2 * math.pi / crownCount
        crown[index] = part(model, "ElevatedEnergyRing" .. index,
            Vector3.new(2 * math.pi * 3.7 / crownCount * .78, .065, .12),
            ringFrame(crownCenter, 3.7, angle), PALE, Enum.Material.Neon, .94)
    end
    local filaments = {}
    if not low and not reduced then
        for index = 1, 3 do
            local angle = (index - 1) * 2 * math.pi / 3
            local lower = part(model, "FilamentLower" .. index, Vector3.new(.1, .1, .1),
                CFrame.new(ringCenter + Vector3.new(math.cos(angle) * 2, 0,
                    math.sin(angle) * 2)), TEAL, Enum.Material.SmoothPlastic, 1)
            local upper = part(model, "FilamentUpper" .. index, Vector3.new(.1, .1, .1),
                CFrame.new(crownCenter + Vector3.new(math.cos(angle + .4) * 2.8, 0,
                    math.sin(angle + .4) * 2.8)), PALE, Enum.Material.SmoothPlastic, 1)
            local a0 = Instance.new("Attachment")
            a0.Parent = lower
            local a1 = Instance.new("Attachment")
            a1.Parent = upper
            local beam = Instance.new("Beam")
            beam.Name = "ChargingFilament"
            beam.Attachment0 = a0
            beam.Attachment1 = a1
            beam.Width0 = .055
            beam.Width1 = .035
            beam.CurveSize0 = .35
            beam.CurveSize1 = -.35
            beam.Color = ColorSequence.new(TEAL, PALE)
            beam.Transparency = NumberSequence.new(.72)
            beam.LightEmission = .35
            beam.Enabled = false
            beam.Parent = model
            filaments[index] = beam
        end
    end
    local shutters = {}
    for index = 1, (if low then 4 else 6) do
        local angle = (index - 1) * 2 * math.pi / (if low then 4 else 6)
        shutters[index] = part(model, "MechanicalPulseShutter" .. index,
            Vector3.new(.65, .09, .22), ringFrame(ringCenter, 3.35, angle),
            Color3.fromRGB(101, 135, 142), Enum.Material.Metal, .12)
    end
    local light = Instance.new("PointLight")
    light.Color = TEAL
    light.Range = 11
    light.Brightness = .15
    light.Parent = core
    local hum = nil
    if Audio.HumSoundId ~= "" then
        hum = Instance.new("Sound")
        hum.Name = "PreviewPositionalMachineHum"
        hum.SoundId = Audio.HumSoundId
        hum.Volume = 0
        hum.Looped = true
        hum.RollOffMaxDistance = Audio.RollOffMaxDistance
        hum.Parent = core
    end

    local transient = Instance.new("Folder")
    transient.Name = "CompletionOnly"
    transient.Parent = model
    local state = "Idle"
    local generation = 0
    local chargeStart = 0
    local phase = 0
    local intensity = .08
    local alive = true
    local tweens = {}
    local elapsed = 0
    local controller = {}

    local function clearTransient()
        for _, tween in tweens do tween:Cancel() end
        table.clear(tweens)
        transient:ClearAllChildren()
    end
    local function animate(p, duration, goal)
        local tween = TweenService:Create(p,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
        table.insert(tweens, tween)
        tween:Play()
    end
    local function complete()
        if reduced then return end
        for index, segment in inner do
            local angle = (index - 1) * 2 * math.pi / #inner + phase
            local copy = part(transient, "ConvergingSegment" .. index,
                segment.Size, segment.CFrame, PALE, Enum.Material.Neon, .12)
            animate(copy, .24, {
                CFrame = ringFrame(ringCenter, .55, angle), Transparency = 1,
            })
        end
        local flash = disk(transient, "CompletionFlash", center + Vector3.new(0, .33, 0),
            .6, .045, PALE, Enum.Material.Neon, .18)
        animate(flash, .28, {
            Size = Vector3.new(.045, 3.7, 3.7), Transparency = 1,
        })
    end
    function controller:SetState(nextState, initialProgress)
        if not alive then return end
        generation += 1
        local token = generation
        clearTransient()
        state = nextState
        if nextState == "Activation" then
            if hum and not hum.IsPlaying then hum:Play() end
            for index, shutter in shutters do
                local angle = (index - 1) * 2 * math.pi / #shutters
                animate(shutter, .24, { CFrame = ringFrame(ringCenter, 3.85, angle) })
            end
        elseif nextState == "Charging" then
            chargeStart = os.clock() - math.clamp(initialProgress or 0, 0, 1) * CHARGE_SECONDS
            if hum and not hum.IsPlaying then hum:Play() end
        elseif nextState == "Completion" then
            complete()
            task.delay(.45, function()
                if alive and generation == token then controller:SetState("Idle") end
            end)
        elseif nextState == "Cancellation" then
            task.delay(.45, function()
                if alive and generation == token then controller:SetState("Idle") end
            end)
        end
        if nextState ~= "Activation" then
            for index, shutter in shutters do
                local angle = (index - 1) * 2 * math.pi / #shutters
                shutter.CFrame = ringFrame(ringCenter, 3.35, angle)
            end
        end
        for _, filament in filaments do
            filament.Enabled = nextState == "Charging"
        end
    end
    local connection = RunService.Heartbeat:Connect(function(dt)
        if not alive then return end
        elapsed += dt
        if elapsed < (if low then .1 else .05) then return end
        local step = elapsed
        elapsed = 0
        local progress = if state == "Charging"
            then math.clamp((os.clock() - chargeStart) / CHARGE_SECONDS, 0, 1) else 0
        local wanted = if state == "Idle" then .08
            elseif state == "Activation" then .45
            elseif state == "Charging" then .45 + progress * .5
            elseif state == "Completion" then 1 else .05
        intensity += (wanted - intensity) * math.min(1, step * 8)
        if state == "Charging" and not reduced then
            phase += step * (.35 + progress * 2.1)
        end
        local color = if state == "Cancellation" then AMBER else TEAL
        for _, segment in outer do
            segment.Color = color
            segment.Transparency = math.clamp(.85 - intensity * .7, .12, .88)
        end
        for index, segment in inner do
            segment.Color = color
            segment.Transparency = math.clamp(.88 - intensity * .7, .15, .9)
            if state == "Charging" and not reduced then
                local angle = (index - 1) * 2 * math.pi / #inner + phase
                segment.CFrame = ringFrame(ringCenter, 2.65, angle)
            end
        end
        for index, segment in crown do
            segment.Color = color
            segment.Transparency = if low or reduced then .95
                else math.clamp(.96 - intensity * .64, .31, .96)
            if state == "Charging" and not reduced then
                local angle = (index - 1) * 2 * math.pi / #crown - phase * .22
                segment.CFrame = ringFrame(crownCenter, 3.7, angle)
            end
        end
        core.Color = color
        core.Transparency = math.clamp(.9 - intensity * .5, .38, .92)
        light.Color = color
        light.Brightness = if low then .15 else .12 + intensity * .8
        if hum then
            local wantedVolume = if state == "Activation" then Audio.BaseVolume
                elseif state == "Charging" then
                    Audio.BaseVolume + (Audio.PeakVolume - Audio.BaseVolume) * progress
                else 0
            local targetVolume = wantedVolume * math.clamp(effectsGain or 1, 0, 1)
            hum.Volume += (targetVolume - hum.Volume) * math.min(1, step * 9)
            if targetVolume == 0 and hum.IsPlaying and hum.Volume < .005 then hum:Stop() end
        end
    end)
    function controller:Destroy()
        if not alive then return end
        alive = false
        generation += 1
        connection:Disconnect()
        clearTransient()
        root:Destroy()
    end
    controller:SetState("Idle")
    return controller
end

return table.freeze(Prototype)
