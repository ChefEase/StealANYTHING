--!strict

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Balance = require(game.ReplicatedStorage.Shared.BalanceConfig)
local Noise = require(script.Parent.GuardNoise)

local TravelEffects = {}
local canCarryTeleport: ((Player, Vector3, any?) -> boolean)? = nil
local recordCarryTeleport: ((Player, Vector3, Vector3) -> ())? = nil
local getCarry: ((Player) -> any?)? = nil
local active: {[Player]: boolean} = {}
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
    canTravel: (Player, Vector3, any?) -> boolean,
    recordTravel: (Player, Vector3, Vector3) -> (),
    snapshot: (Player) -> any?
)
    canCarryTeleport = canTravel
    recordCarryTeleport = recordTravel
    getCarry = snapshot
end

-- Anchor and access checks come only from server callers, never remote arguments.
function TravelEffects.Teleport(player: Player, destination: CFrame,
    anchor: BasePart?, range: number?, access: (() -> boolean)?): boolean
    if active[player] or not getCarry or not canCarryTeleport or not recordCarryTeleport then return false end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not root or not root:IsA("BasePart") then return false end
    local carry = getCarry(player)
    local extraction = carry ~= nil and not carry.tutorial and not carry.replay
    -- No alternate server travel entry point can silently skip public extraction.
    if extraction and not anchor then return false end
    local origin = root.Position
    local function valid(): boolean
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if player.Parent ~= Players or player.Character ~= character or not character.Parent
            or not root.Parent or not humanoid or humanoid.Health <= 0
            or player:GetAttribute("ProfileState") ~= "Ready"
            or (game:GetAttribute("MatchmakingEnabled") and player:GetAttribute("MatchActive") ~= true)
            or (access and not access()) then return false end
        if anchor and (not anchor:IsDescendantOf(workspace)
            or (root.Position-anchor.Position).Magnitude > (range or 12)) then return false end
        if extraction then
            if (root.Position-origin).Magnitude > Balance.PUBLIC_EXTRACTION_MOVE_STUDS then return false end
        elseif player:GetAttribute("GuardChased") == true then return false end
        return (canCarryTeleport :: any)(player, root.Position, carry)
    end
    if not valid() then return false end
    active[player] = true
    local marker: BillboardGui? = nil
    local ok, result = xpcall(function()
        local duration = if extraction then Balance.PUBLIC_EXTRACTION_SECONDS else 0.22
        local started = os.clock()
        local nextNoise = started
        if extraction then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ExtractionMarker"
            billboard.Size = UDim2.fromOffset(150, 30)
            billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
            billboard.MaxDistance = 60
            billboard.AlwaysOnTop = false
            billboard.Adornee = root
            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundColor3 = Color3.fromRGB(37, 28, 23)
            label.TextColor3 = Color3.fromRGB(255, 214, 126)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.Text = "EXTRACTING STOCK"
            label.Parent = billboard
            billboard.Parent = root
            marker = billboard
            player:SetAttribute("ExtractionOutcome", nil)
            -- Client VFX must use the validated machine, not the moving avatar.
            player:SetAttribute("ExtractionPadWorldPosition", (anchor :: BasePart).Position
                + Vector3.new(0, (anchor :: BasePart).Size.Y / 2 - .07, 0))
            player:SetAttribute("ExtractionEndsAt", workspace:GetServerTimeNow()+duration)
            player:SetAttribute("ExtractionDuration", duration)
            player:SetAttribute("ExtractionActive", true)
        else
            burst(origin - Vector3.new(0, 2.5, 0))
        end
        repeat
            if not valid() then return false end
            if extraction and os.clock() >= nextNoise then
                Noise.Emit(origin, "TeleportExtraction")
                nextNoise = os.clock()+Balance.PUBLIC_EXTRACTION_NOISE_SECONDS
            end
            task.wait(math.min(0.1, math.max(0.01, duration-(os.clock()-started))))
        until os.clock()-started >= duration
        -- No yield between final identity/access validation, movement and route credit.
        if not valid() then return false end
        local departure = root.Position
        character:PivotTo(destination)
        if carry then
            (recordCarryTeleport :: any)(player, departure, root.Position)
        end
        burst(destination.Position - Vector3.new(0, 2.5, 0))
        return true
    end, debug.traceback)
    if marker then marker:Destroy() end
    active[player] = nil
    if extraction then
        player:SetAttribute("ExtractionOutcome", if ok and result then "Completed" else "Cancelled")
        player:SetAttribute("ExtractionActive", nil)
        player:SetAttribute("ExtractionEndsAt", nil)
        player:SetAttribute("ExtractionDuration", nil)
        player:SetAttribute("ExtractionPadWorldPosition", nil)
    end
    if not ok then warn("[Travel] Activation failed: " .. tostring(result)) end
    return ok and result == true
end

return table.freeze(TravelEffects)
