--!strict

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local TravelEffects = {}
local canCarryTeleport: ((Player, Vector3) -> boolean)? = nil
local recordCarryTeleport: ((Player, Vector3, Vector3) -> ())? = nil
local TEAL = Color3.fromRGB(74, 235, 194)
local GOLD = Color3.fromRGB(255, 207, 115)
local MAGIC_SOUND = "rbxassetid://248435147" -- Roblox-owned Magic Sound

local function burst(position: Vector3)
    local anchor = Instance.new("Part")
    anchor.Name = "ShuttleBurst"
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.CFrame = CFrame.new(position)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.Parent = workspace
    Debris:AddItem(anchor, 2)

    local sound = Instance.new("Sound")
    sound.Name = "WarpSound"
    sound.SoundId = MAGIC_SOUND
    sound.Volume = 0.8
    sound.RollOffMaxDistance = 100
    sound.Parent = anchor
    sound:Play()

    local sparks = Instance.new("ParticleEmitter")
    sparks.Name = "WarpSparks"
    sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparks.Color = ColorSequence.new(TEAL, GOLD)
    sparks.LightEmission = 0.85
    sparks.Lifetime = NumberRange.new(0.3, 0.65)
    sparks.Speed = NumberRange.new(6, 12)
    sparks.SpreadAngle = Vector2.new(180, 180)
    sparks.Rate = 90
    sparks.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.6),
        NumberSequenceKeypoint.new(1, 0),
    })
    sparks.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    sparks.Parent = anchor
    task.delay(0.4, function()
        if sparks.Parent then sparks.Enabled = false end
    end)

    for index = 1, 2 do
        local ring = Instance.new("Part")
        ring.Name = "WarpRing"
        ring.Shape = Enum.PartType.Cylinder
        ring.Size = Vector3.new(0.12, 4, 4)
        ring.CFrame = CFrame.new(position + Vector3.new(0, (index - 1) * 1.2, 0))
            * CFrame.Angles(0, 0, math.rad(90))
        ring.Color = if index == 1 then TEAL else GOLD
        ring.Material = Enum.Material.Neon
        ring.Transparency = 0.25
        ring.Anchored = true
        ring.CanCollide = false
        ring.CanTouch = false
        ring.CanQuery = false
        ring.Parent = anchor
        TweenService:Create(ring, TweenInfo.new(0.65, Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out), {
            Size = Vector3.new(0.12, 18, 18),
            Transparency = 1,
        }):Play()
    end
end

function TravelEffects.SetCarryTeleportHandlers(
    canTravel: (Player, Vector3) -> boolean,
    recordTravel: (Player, Vector3, Vector3) -> ()
)
    canCarryTeleport = canTravel
    recordCarryTeleport = recordTravel
end

function TravelEffects.Teleport(player: Player, destination: CFrame): boolean
    if player:GetAttribute("GuardChased") == true then return false end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not root or not root:IsA("BasePart") then return false end
    local carriedItem = player:GetAttribute("CurrentCarryItem")
    if carriedItem ~= nil and (canCarryTeleport == nil or recordCarryTeleport == nil) then
        return false
    end
    burst(root.Position - Vector3.new(0, 2.5, 0))
    task.wait(0.22)
    if player.Character ~= character or not character.Parent or not root.Parent
        or player:GetAttribute("CurrentCarryItem") ~= carriedItem
        or player:GetAttribute("GuardChased") == true then return false end
    local origin = root.Position
    if carriedItem ~= nil and not (canCarryTeleport :: (Player, Vector3) -> boolean)(player, origin) then
        return false
    end
    character:PivotTo(destination)
    if carriedItem ~= nil then
        (recordCarryTeleport :: (Player, Vector3, Vector3) -> ())(player, origin, root.Position)
    end
    burst(destination.Position - Vector3.new(0, 2.5, 0))
    return true
end

return table.freeze(TravelEffects)
