-- Preview-only visual stand-ins for the live result controllers. Never require
-- this module from the museum or lobby project.
local SignatureVfx = require(game:GetService("ReplicatedStorage").Shared.SignatureVfx)
local Catalog = require(game:GetService("ReplicatedStorage").Shared.ItemCatalog)

local Effects = {}
local TEAL = Color3.fromRGB(74, 235, 194)
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

function Effects.Play(kind, target, root, mode, itemId, live)
    local low = mode == "Low effects"
    local reduced = mode == "Reduced motion"
    local function waitFor(seconds)
        local endAt = os.clock() + seconds
        repeat
            if not live() then return false end
            task.wait(math.min(.08, math.max(.01, endAt - os.clock())))
        until os.clock() >= endAt
        return live()
    end
    local function play()
        if not live() then return end
        if kind == "Restock" then
            local glow = highlight(root, target, AMBER, low)
            if not reduced then
                burst(root, target.Position + Vector3.new(0, 1.3, 0),
                    AMBER, if low then 2 else 7, 2, .6)
            end
            if not waitFor(.85) then return end
            glow:Destroy()
        elseif kind == "Exhibit" or kind == "Gallery" then
            if kind == "Gallery" then
                for index, galleryItemId in Catalog.OrderedIds do
                    local column = (index - 1) % 4
                    local row = math.floor((index - 1) / 4)
                    local position = target.Position + Vector3.new(
                        (column - 1.5) * 8, 0, (row - 1) * 8)
                    local pedestal = part(root, "GalleryStand" .. index,
                        Vector3.new(4, .6, 4), CFrame.new(position),
                        Color3.fromRGB(44, 61, 65), 0)
                    pedestal.Material = Enum.Material.Metal
                    local proxy = part(root, "GalleryProxy" .. galleryItemId,
                        Vector3.new(1.8, 1.8, 1.8),
                        CFrame.new(position + Vector3.new(0, 1.45, 0)),
                        Color3.fromRGB(97, 108, 110), 0)
                    proxy.Material = Enum.Material.SmoothPlastic
                    SignatureVfx.Attach(proxy, root, galleryItemId,
                        CFrame.identity, Vector3.new(2, 2, 2))
                    local sign = Instance.new("BillboardGui")
                    sign.Name = "GalleryItemLabel"
                    sign.Adornee = pedestal
                    sign.Size = UDim2.fromOffset(110, 22)
                    sign.StudsOffsetWorldSpace = Vector3.new(0, 3.8, 0)
                    sign.MaxDistance = 25
                    sign.Parent = root
                    local text = Instance.new("TextLabel")
                    text.Size = UDim2.fromScale(1, 1)
                    text.BackgroundColor3 = Color3.fromRGB(17, 30, 34)
                    text.TextColor3 = Color3.fromRGB(237, 246, 242)
                    text.TextSize = 10
                    text.Font = Enum.Font.GothamBold
                    text.Text = string.upper(galleryItemId)
                    text.Parent = sign
                end
            else
                local artifact = part(root, "PreviewExhibit", Vector3.new(2, 2, 2),
                    CFrame.new(target.Position + Vector3.new(0, 2.2, 0)), TEAL, .2)
                SignatureVfx.Attach(artifact, root, itemId,
                    CFrame.identity, Vector3.new(2, 2, 2))
            end
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
    return function() end
end

return table.freeze(Effects)
