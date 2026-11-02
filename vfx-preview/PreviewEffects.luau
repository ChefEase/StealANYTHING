-- Preview-only visual stand-ins for the live result controllers. Never require
-- this module from the museum or lobby project.
local TweenService = game:GetService("TweenService")
local SignatureVfx = require(game:GetService("ReplicatedStorage").Shared.SignatureVfx)

local Effects = {}
local TEAL = Color3.fromRGB(74, 235, 194)
local GOLD = Color3.fromRGB(255, 207, 115)
local AMBER = Color3.fromRGB(255, 176, 88)

local function part(parent, name, size, cf, color, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = Enum.Material.Neon
    p.Transparency = transparency or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = parent
    return p
end

local function burst(root, position, color, amount, speed, lifetime)
    local mount = part(root, "BurstMount", Vector3.new(.1, .1, .1),
        CFrame.new(position), color, 1)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "PreviewBurst"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new(color)
    emitter.LightEmission = .6
    emitter.Lifetime = NumberRange.new(lifetime * .6, lifetime)
    emitter.Speed = NumberRange.new(speed * .5, speed)
    emitter.SpreadAngle = Vector2.new(150, 150)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, .32),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Rate = 0
    emitter.Parent = mount
    emitter:Emit(amount)
end

local function highlight(root, target, color, low)
    local h = Instance.new("Highlight")
    h.Name = "PreviewHighlight"
    h.Adornee = target
    h.DepthMode = Enum.HighlightDepthMode.Occluded
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = if low then 1 else .85
    h.OutlineTransparency = .22
    h.Parent = root
    return h
end

local function ring(root, position, color, duration)
    local p = part(root, "PreviewWarpRing", Vector3.new(.12, 4, 4),
        CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), color, .25)
    p.Shape = Enum.PartType.Cylinder
    local tween = TweenService:Create(p,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(.12, 18, 18), Transparency = 1 })
    tween:Play()
    return tween
end

function Effects.Play(kind, target, root, mode, itemId, live)
    local low = mode == "Low effects"
    local reduced = mode == "Reduced motion"
    local tweens = {}
    local function waitFor(seconds)
        local endAt = os.clock() + seconds
        repeat
            if not live() then return false end
            task.wait(math.min(.08, math.max(.01, endAt - os.clock())))
        until os.clock() >= endAt
        return live()
    end
    local function track(tween)
        table.insert(tweens, tween)
    end
    local function play()
        if not live() then return end
        if kind == "Pickup" then
            local glow = highlight(root, target, TEAL, low)
            if not waitFor(.7) then return end
            glow:Destroy()
            if not reduced then
                burst(root, target.Position + Vector3.new(0, 1.7, 0),
                    GOLD, if low then 2 else 7, 5, .5)
            end
        elseif kind == "Extraction" then
            local sign = Instance.new("BillboardGui")
            sign.Name = "PreviewExtractionMarker"
            sign.Adornee = target
            sign.Size = UDim2.fromOffset(160, 32)
            sign.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
            sign.MaxDistance = 80
            sign.AlwaysOnTop = false
            sign.Parent = root
            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundColor3 = Color3.fromRGB(37, 28, 23)
            label.TextColor3 = GOLD
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.Text = "EXTRACTING STOCK"
            label.Parent = sign
            if not waitFor(3.5) then return end
            sign:Destroy()
            if not reduced then
                local center = target.Position + Vector3.new(0, 1, 0)
                track(ring(root, center, TEAL, .65))
                if not low then track(ring(root, center + Vector3.new(0, 1.2, 0), GOLD, .65)) end
                burst(root, center, TEAL, if low then 3 else 12, 12, .65)
            end
        elseif kind == "Restock" then
            local glow = highlight(root, target, AMBER, low)
            if not reduced then
                burst(root, target.Position + Vector3.new(0, 1.3, 0),
                    AMBER, if low then 2 else 7, 2, .6)
            end
            if not waitFor(.85) then return end
            glow:Destroy()
        elseif kind == "Exhibit" then
            local artifact = part(root, "PreviewExhibit", Vector3.new(2, 2, 2),
                CFrame.new(target.Position + Vector3.new(0, 2.2, 0)), TEAL, .2)
            SignatureVfx.Attach(artifact, root, itemId,
                CFrame.identity, Vector3.new(2, 2, 2))
            local rigs = SignatureVfx.Preview(root)
            local started = os.clock()
            if low then
                for _, rig in rigs do
                    for _, visual in rig.folder:GetDescendants() do
                        if visual:IsA("BasePart") then visual.Transparency = 1 end
                    end
                end
            end
            while live() do
                if not low then
                    SignatureVfx.UpdatePreview(rigs, os.clock() - started, reduced)
                end
                task.wait(if low then .1 else 1 / 30)
            end
            return
        end
        waitFor(1)
    end
    task.spawn(play)
    return function()
        for _, tween in tweens do tween:Cancel() end
    end
end

return table.freeze(Effects)
