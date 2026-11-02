-- Development-only receiving platform. State changes are mock preview inputs.
-- No gameplay remotes, inventory state, or server delivery code run here.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Prototype = {}
local TEAL = Color3.fromRGB(74, 235, 194)
local PALE = Color3.fromRGB(143, 255, 231)
local GOLD = Color3.fromRGB(255, 207, 115)
local AMBER = Color3.fromRGB(255, 164, 82)
local RED = Color3.fromRGB(247, 97, 76)
local STEEL = Color3.fromRGB(32, 48, 55)

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

local function segmentCFrame(center, radius, angle)
    return CFrame.new(center + Vector3.new(radius * math.cos(angle), 0,
        radius * math.sin(angle))) * CFrame.Angles(0, -angle - math.pi / 2, 0)
end

local function segmentedRing(parent, name, center, radius, count, width, color)
    local pieces = {}
    local length = 2 * math.pi * radius / count * .82
    for index = 1, count do
        local angle = (index - 1) * 2 * math.pi / count
        pieces[index] = part(parent, name .. index,
            Vector3.new(length, .055, width),
            segmentCFrame(center, radius, angle), color,
            Enum.Material.Neon, .5)
    end
    return pieces
end

function Prototype.Create(root, target, mode)
    local low = mode == "Low effects"
    local reduced = mode == "Reduced motion"
    local center = target.Position + Vector3.new(0, .22, 0)
    local model = Instance.new("Model")
    model.Name = "ReceivingPlatformPrototype"
    model.Parent = root

    disk(model, "DarkOuterPlinth", center, 10.4, .38,
        Color3.fromRGB(19, 32, 38), Enum.Material.Metal, 0)
    disk(model, "RaisedSteelDeck", center + Vector3.new(0, .22, 0), 8.8, .16,
        STEEL, Enum.Material.Metal, 0)
    local core = disk(model, "RecessedEnergyCore", center + Vector3.new(0, .32, 0), 3.1, .035,
        TEAL, Enum.Material.Neon, .72)

    local ringY = center + Vector3.new(0, .33, 0)
    local outer = segmentedRing(model, "OuterGuideSegment", ringY, 4.55,
        if low then 12 else 20, .16, TEAL)
    local inner = segmentedRing(model, "InnerReceiverSegment", ringY, 2.55,
        if low then 8 else 16, .1, PALE)
    local ticks = {}
    for index = 1, (if low then 4 else 8) do
        local angle = (index - 1) * 2 * math.pi / (if low then 4 else 8)
        ticks[index] = part(model, "InwardDirectionTick" .. index,
            Vector3.new(.5, .045, .1),
            segmentCFrame(ringY, 3.5, angle) * CFrame.Angles(0, math.pi / 2, 0),
            TEAL, Enum.Material.Neon, .72)
    end

    local light = Instance.new("PointLight")
    light.Name = "ControlledReceiverLight"
    light.Color = TEAL
    light.Range = 12
    light.Brightness = if low then .15 else .35
    light.Parent = core

    local bottom = part(model, "BeamAnchorBottom", Vector3.new(.1, .1, .1),
        CFrame.new(center + Vector3.new(0, .36, 0)), TEAL,
        Enum.Material.SmoothPlastic, 1)
    local top = part(model, "BeamAnchorTop", Vector3.new(.1, .1, .1),
        CFrame.new(center + Vector3.new(0, 2.7, 0)), TEAL,
        Enum.Material.SmoothPlastic, 1)
    local a0 = Instance.new("Attachment")
    a0.Parent = bottom
    local a1 = Instance.new("Attachment")
    a1.Parent = top
    local beam = Instance.new("Beam")
    beam.Name = "ProcessingBeam"
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Width0 = .16
    beam.Width1 = .07
    beam.Color = ColorSequence.new(TEAL)
    beam.Transparency = NumberSequence.new(.68)
    beam.LightEmission = .45
    beam.FaceCamera = true
    beam.Enabled = false
    beam.Parent = model

    local successFolder = Instance.new("Folder")
    successFolder.Name = "ConfirmedSuccessOnly"
    successFolder.Parent = model
    local packetFolder = Instance.new("Folder")
    packetFolder.Name = "ProcessingPackets"
    packetFolder.Parent = model
    local tweens = {}
    local generation = 0
    local state = "Idle"
    local intensity = .16
    local currentColor = TEAL
    local alive = true
    local elapsed = 0

    local function clearPackets()
        for _, tween in tweens do tween:Cancel() end
        table.clear(tweens)
        packetFolder:ClearAllChildren()
    end

    local function emitSuccess()
        local mount = part(successFolder, "SuccessParticleMount",
            Vector3.new(.1, .1, .1),
            CFrame.new(center + Vector3.new(0, .8, 0)), GOLD,
            Enum.Material.SmoothPlastic, 1)
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "ConfirmedGoldAccent"
        emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        emitter.Color = ColorSequence.new(GOLD)
        emitter.LightEmission = .45
        emitter.Lifetime = NumberRange.new(.28, .5)
        emitter.Speed = NumberRange.new(1.5, 3.5)
        emitter.SpreadAngle = Vector2.new(150, 150)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, .22),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Rate = 0
        emitter.Parent = mount
        emitter:Emit(if low then 3 else 10)
    end

    local function processingLoop(token)
        while alive and state == "Processing" and generation == token do
            clearPackets()
            local count = if low then 4 else 8
            for index = 1, count do
                local angle = (index - 1) * 2 * math.pi / count
                local packet = part(packetFolder, "InwardPacket" .. index,
                    Vector3.new(.42, .05, .13),
                    segmentCFrame(ringY + Vector3.new(0, .045, 0), 4.05, angle),
                    PALE, Enum.Material.Neon, .18)
                local tween = TweenService:Create(packet,
                    TweenInfo.new(.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        CFrame = segmentCFrame(ringY + Vector3.new(0, .045, 0), .7, angle),
                        Transparency = .92,
                    })
                table.insert(tweens, tween)
                tween:Play()
            end
            task.wait(.73)
        end
    end

    local controller = {}
    function controller:SetState(nextState)
        if not alive then return end
        generation += 1
        local token = generation
        clearPackets()
        successFolder:ClearAllChildren()
        state = nextState
        beam.Enabled = nextState == "Processing" and not low and not reduced
        if nextState == "Processing" and not reduced then
            task.spawn(processingLoop, token)
        elseif nextState == "Success" then
            if not reduced then emitSuccess() end
            task.delay(.7, function()
                if alive and generation == token then controller:SetState("Idle") end
            end)
        elseif nextState == "Cancel" or nextState == "Failure" then
            task.delay(.5, function()
                if alive and generation == token then controller:SetState("Idle") end
            end)
        end
    end

    local connection = RunService.Heartbeat:Connect(function(dt)
        if not alive then return end
        elapsed += dt
        if elapsed < 1 / 20 then return end
        local step = elapsed
        elapsed = 0
        local desiredColor = if state == "Success" then GOLD
            elseif state == "Cancel" then AMBER
            elseif state == "Failure" then RED else TEAL
        local targetIntensity = if state == "Idle" then .16
            elseif state == "Approach" then .62 else .9
        intensity += (targetIntensity - intensity) * math.min(1, step * 7)
        currentColor = currentColor:Lerp(desiredColor, math.min(1, step * 8))
        local idlePulse = if state == "Idle" and not low and not reduced
            then math.sin(os.clock() * 1.6) * .025 else 0
        for _, segment in outer do
            segment.Color = currentColor
            segment.Transparency = math.clamp(.64 - intensity * .47 + idlePulse, .1, .8)
        end
        for _, segment in inner do
            segment.Color = if state == "Idle" then PALE else currentColor
            segment.Transparency = math.clamp(.76 - intensity * .48, .15, .85)
        end
        for _, tick in ticks do
            tick.Color = currentColor
            tick.Transparency = math.clamp(.9 - intensity * .65, .2, .9)
        end
        core.Color = currentColor
        core.Transparency = math.clamp(.83 - intensity * .42, .35, .88)
        light.Color = currentColor
        light.Brightness = if low then .15 else .25 + intensity * .75
    end)

    function controller:Destroy()
        if not alive then return end
        alive = false
        generation += 1
        connection:Disconnect()
        clearPackets()
        root:Destroy()
    end

    controller:SetState("Idle")
    return controller
end

return table.freeze(Prototype)
