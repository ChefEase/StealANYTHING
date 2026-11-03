-- Short local pickup confirmation. Caller owns the confirmed carry gate and
-- destroys the supplied root after playback. Preview can add a mock hold.
local TweenService = game:GetService("TweenService")

local Prototype = {}
local TEAL = Color3.fromRGB(74, 235, 194)
local GOLD = Color3.fromRGB(255, 207, 115)
local PURPLE = Color3.fromRGB(183, 153, 255)
local PINK = Color3.fromRGB(255, 132, 198)
local COLORS = { Common = TEAL, Uncommon = GOLD, Rare = PURPLE, Legendary = PINK }

local function visual(root, name, size, cf, color, alpha)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = Enum.Material.Neon
    p.Transparency = alpha
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = root
    return p
end

local function ringFrame(center, radius, angle)
    return CFrame.new(center + Vector3.new(radius * math.cos(angle), 0,
        radius * math.sin(angle))) * CFrame.Angles(0, -angle - math.pi / 2, 0)
end

function Prototype.Play(root, target, tier, mode, live, skipHold)
    local low = mode == "Low effects"
    local reduced = mode == "Reduced motion"
    local color = COLORS[tier] or TEAL
    local tweens = {}
    local function animate(instance, duration, goal)
        local tween = TweenService:Create(instance,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
        table.insert(tweens, tween)
        tween:Play()
    end
    local function aliveAfter(seconds)
        local untilTime = os.clock() + seconds
        repeat
            if not live() then return false end
            task.wait(math.min(.04, math.max(.01, untilTime - os.clock())))
        until os.clock() >= untilTime
        return live()
    end
    local function flash(center, flashColor, radius, duration)
        local p = visual(root, "PickupCenterFlash", Vector3.new(.055, .45, .45),
            CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)), flashColor, .35)
        p.Shape = Enum.PartType.Cylinder
        animate(p, duration, { Size = Vector3.new(.055, radius, radius), Transparency = 1 })
    end
    local function sparks(center, amount)
        if amount <= 0 then return end
        local mount = visual(root, "PickupSparkMount", Vector3.new(.1, .1, .1),
            CFrame.new(center), color, 1)
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "ShortRarityAccent"
        emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        emitter.Color = ColorSequence.new(color)
        emitter.LightEmission = .45
        emitter.Lifetime = NumberRange.new(.18, .36)
        emitter.Speed = NumberRange.new(2, 4)
        emitter.SpreadAngle = Vector2.new(120, 120)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, .17),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Rate = 0
        emitter.Parent = mount
        emitter:Emit(amount)
    end
    local function upwardFlicks(center, count)
        for index = 1, count do
            local angle = (index - 1) * 2 * math.pi / count
            local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
            local start = center + radial * .25
            local p = visual(root, "UncommonUpwardFlick" .. index,
                Vector3.new(.09, .45, .09), CFrame.new(start), color, .12)
            animate(p, .38, {
                CFrame = CFrame.new(start + radial * .85 + Vector3.new(0, 1.05, 0)),
                Transparency = 1,
            })
        end
    end
    local function directionalStreaks(center, count, length)
        local camera = workspace.CurrentCamera
        local toward = if camera then camera.CFrame.Position - center else Vector3.zAxis
        toward = Vector3.new(toward.X, 0, toward.Z)
        toward = if toward.Magnitude > .01 then toward.Unit else Vector3.zAxis
        local right = toward:Cross(Vector3.yAxis).Unit
        for index = 1, count do
            local spread = (index - (count + 1) / 2) / count
            local direction = (Vector3.yAxis * .6 + right * spread * 1.8
                + toward * .25).Unit
            local start = center + direction * .25
            local p = visual(root, "DirectionalRarityStreak" .. index,
                Vector3.new(.09, .09, length), CFrame.lookAt(start, start + direction),
                if index % 3 == 0 then GOLD else color, .12)
            animate(p, .46, {
                CFrame = CFrame.lookAt(center + direction * 1.9,
                    center + direction * 1.9 + direction),
                Transparency = 1,
                Size = Vector3.new(.04, .04, length * .55),
            })
        end
    end
    local function centerStar(center)
        local camera = workspace.CurrentCamera
        local facing = if camera then camera.CFrame.Rotation else CFrame.identity
        for index = 1, 2 do
            local angle = math.rad(if index == 1 then 45 else -45)
            local star = visual(root, "PickupFourPointAccent" .. index,
                Vector3.new(.07, .78, .045),
                CFrame.new(center) * facing * CFrame.Angles(0, 0, angle),
                if tier == "Legendary" then GOLD else PURPLE, .08)
            animate(star, .24, {
                Size = Vector3.new(.025, 1.25, .025),
                Transparency = 1,
            })
        end
    end
    local function legendaryRing(center, count)
        for index = 1, count do
            local angle = (index - 1) * 2 * math.pi / count
            local p = visual(root, "LegendaryRingSegment" .. index,
                Vector3.new(.34, .055, .1), ringFrame(center, .68, angle),
                if index % 3 == 0 then GOLD else PURPLE, .15)
            animate(p, .52, {
                CFrame = ringFrame(center, 2.25, angle),
                Size = Vector3.new(.68, .055, .08),
                Transparency = 1,
            })
        end
    end

    task.spawn(function()
        if not live() then return end
        if not skipHold then
            local hold = Instance.new("Highlight")
            hold.Name = "MockPickupHold"
            hold.Adornee = target
            hold.DepthMode = Enum.HighlightDepthMode.Occluded
            hold.FillColor = color
            hold.OutlineColor = color
            hold.FillTransparency = if low then 1 else .9
            hold.OutlineTransparency = .28
            hold.Parent = root
            if not aliveAfter(.45) then return end
            hold:Destroy()
        end
        local center = target.Position + Vector3.new(0, 1.15, 0)
        if reduced then
            local still = Instance.new("Highlight")
            still.Name = "ReducedMotionConfirmation"
            still.Adornee = target
            still.FillColor = color
            still.OutlineColor = color
            still.FillTransparency = 1
            still.OutlineTransparency = .06
            still.Parent = root
            if aliveAfter(.24) then still:Destroy() end
            return
        end
        flash(center, if tier == "Legendary" then GOLD else color,
            if tier == "Common" then 1.25 else 1.7, .3)
        if tier == "Uncommon" then
            upwardFlicks(center, if low then 3 else 5)
        elseif tier == "Rare" then
            centerStar(center)
            directionalStreaks(center, if low then 3 else 6, .9)
            if not low then sparks(center, 3) end
        elseif tier == "Legendary" then
            centerStar(center)
            legendaryRing(center, if low then 8 else 12)
            if not low then
                directionalStreaks(center, 7, 1.1)
                sparks(center, 5)
            end
        end
    end)
    return function()
        for _, tween in tweens do tween:Cancel() end
    end
end

return table.freeze(Prototype)
