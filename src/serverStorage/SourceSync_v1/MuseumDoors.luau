--!strict

-- Double entrance doors for the original museum and each cloned museum.
-- The server picks a random state every so often: both open, one open, or
-- both closed. When both are closed, anyone can open them through Roblox's
-- default ProximityPrompt UI (the custom interaction HUD skips prompts that
-- carry the DefaultPromptStyle attribute).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

type Leaf = { part: BasePart, closed: CFrame, open: CFrame, isOpen: boolean }
type Door = {
    museum: Model,
    frame: CFrame,
    halfWidth: number,
    leaves: { Leaf },
    prompt: ProximityPrompt,
    nextChange: number,
}

local MuseumDoors = {}
local doors: { [Model]: Door } = {}
local lastOpen: { [number]: number } = {}
local started = false
local lastTick = 0
local random = Random.new()

local MIN_HOLD_SECONDS = 30
local MAX_HOLD_SECONDS = 90
local PLAYER_OPEN_HOLD_SECONDS = 60
local SWING = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DOOR_COLOR = Color3.fromRGB(92, 62, 40)
local PLAYER_OPEN_SOUND = "rbxassetid://9120839174" -- short wooden door creak

local function inLocal(frame: CFrame, part: Instance?): Vector3?
    if part ~= nil and part:IsA("BasePart") then
        return frame:PointToObjectSpace(part.Position)
    end
    return nil
end

local function doorwayOccupied(door: Door): boolean
    for _, player in Players:GetPlayers() do
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            local offset = door.frame:PointToObjectSpace(root.Position)
            if math.abs(offset.X) < door.halfWidth + 2 and math.abs(offset.Z) < door.halfWidth + 2
                and math.abs(offset.Y) < 12 then
                return true
            end
        end
    end
    return false
end

local function setLeaf(leaf: Leaf, open: boolean)
    if leaf.isOpen == open then return end
    leaf.isOpen = open
    -- An open leaf rests against the inside wall; only a closed leaf blocks.
    if open then leaf.part.CanCollide = false end
    local tween = TweenService:Create(leaf.part, SWING, { CFrame = if open then leaf.open else leaf.closed })
    tween.Completed:Connect(function()
        if not leaf.isOpen then leaf.part.CanCollide = true end
    end)
    tween:Play()
end

local function apply(door: Door, leftOpen: boolean, rightOpen: boolean)
    setLeaf(door.leaves[1], leftOpen)
    setLeaf(door.leaves[2], rightOpen)
    door.prompt.Enabled = not leftOpen and not rightOpen
    door.museum:SetAttribute("DoorState",
        if leftOpen and rightOpen then "Open" elseif leftOpen or rightOpen then "HalfOpen" else "Closed")
end

local function randomize(door: Door)
    local left, right = door.leaves[1].isOpen, door.leaves[2].isOpen
    local options: { { boolean } } = {}
    for _, state in { { true, true }, { true, false }, { false, true }, { false, false } } do
        if state[1] ~= left or state[2] ~= right then table.insert(options, state) end
    end
    local choice = options[random:NextInteger(1, #options)]
    local closing = (left and not choice[1]) or (right and not choice[2])
    if closing and doorwayOccupied(door) then
        -- Never swing a leaf shut on someone; try again shortly.
        door.nextChange = os.clock() + 5
        return
    end
    apply(door, choice[1], choice[2])
    door.nextChange = os.clock() + random:NextNumber(MIN_HOLD_SECONDS, MAX_HOLD_SECONDS)
end

function MuseumDoors.Attach(museum: Model)
    if doors[museum] ~= nil then return end
    local entrance = museum:FindFirstChild("RaidEntrance", true)
    if entrance == nil or not entrance:IsA("BasePart") then
        warn("[Steal Anything] Museum has no RaidEntrance for doors: " .. museum:GetFullName())
        return
    end
    -- The RaidEntrance marker spans the doorway: X is width, Y is height.
    local marker = entrance.CFrame
    local width = entrance.Size.X
    local bottom = -entrance.Size.Y / 2 + 0.4
    local top = entrance.Size.Y / 2
    local plane = 0
    -- Prefer the real wall plane and lintel underside when they sit at this
    -- doorway; otherwise fall back to the marker's own volume.
    local wall = inLocal(marker, museum:FindFirstChild("SouthWallLeft", true))
    if wall ~= nil and math.abs(wall.Z) < 2 then plane = wall.Z end
    local lintel = museum:FindFirstChild("DoorLintel", true)
    local lintelOffset = inLocal(marker, lintel)
    if lintel ~= nil and lintel:IsA("BasePart") and lintelOffset ~= nil
        and math.abs(lintelOffset.X) < width / 2 and math.abs(lintelOffset.Z) < 2 then
        local underside = lintelOffset.Y - lintel.Size.Y / 2
        if underside > bottom + 8 and underside < bottom + 20 then top = underside end
    end
    local height = top - bottom - 0.05
    local frame = marker * CFrame.new(0, (top + bottom) / 2, plane)
    -- Swing the leaves inward. The receiving zone is always inside the hall;
    -- an imported model's pivot may not be.
    local interior = museum:FindFirstChild("ReceivingZone", true)
    local inside = if interior ~= nil and interior:IsA("BasePart")
        then interior.Position else museum:GetPivot().Position
    local inward = if frame:PointToObjectSpace(inside).Z >= 0 then 1 else -1

    local model = Instance.new("Model")
    model.Name = "EntranceDoors"
    local leaves: { Leaf } = {}
    for index, side in { -1, 1 } do
        local hinge = frame * CFrame.new(side * width / 2, 0, 0)
        local offset = CFrame.new(-side * width / 4, 0, 0)
        local part = Instance.new("Part")
        part.Name = if index == 1 then "LeftLeaf" else "RightLeaf"
        part.Size = Vector3.new(width / 2 - 0.1, height, 0.4)
        part.Color = DOOR_COLOR
        part.Material = Enum.Material.Wood
        part.Anchored = true
        part.CanCollide = true
        part.CanTouch = false
        local closed = hinge * offset
        part.CFrame = closed
        part.Parent = model
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(0.25, 1.6, 0.9)
        handle.Color = Color3.fromRGB(196, 160, 92)
        handle.Material = Enum.Material.Metal
        handle.Anchored = true
        handle.CanCollide = false
        handle.CanQuery = false
        handle.CanTouch = false
        handle.CFrame = closed * CFrame.new(-side * (width / 4 - 0.6), 0, 0)
        handle.Parent = model
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = part
        weld.Part1 = handle
        weld.Parent = handle
        handle.Anchored = false
        handle.Massless = true
        table.insert(leaves, {
            part = part,
            closed = closed,
            open = hinge * CFrame.Angles(0, side * inward * math.pi / 2, 0) * offset,
            isOpen = false,
        })
    end
    local anchor = Instance.new("Part")
    anchor.Name = "DoorPromptAnchor"
    anchor.Size = Vector3.new(1, 1, 1)
    anchor.CFrame = frame
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanQuery = false
    anchor.CanTouch = false
    anchor.Parent = model
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "OpenDoors"
    prompt.ActionText = "Open"
    prompt.ObjectText = "Museum doors"
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Style = Enum.ProximityPromptStyle.Default
    prompt:SetAttribute("DefaultPromptStyle", true)
    prompt.Parent = anchor
    local openSound = Instance.new("Sound")
    openSound.Name = "PlayerDoorOpenSound"
    openSound.SoundId = PLAYER_OPEN_SOUND
    openSound.Volume = 0.7
    openSound.PlaybackSpeed = 1.5
    openSound.RollOffMaxDistance = 55
    openSound.Parent = anchor
    model.Parent = museum

    local door: Door = {
        museum = museum,
        frame = frame,
        halfWidth = width / 2,
        leaves = leaves,
        prompt = prompt,
        nextChange = 0,
    }
    doors[museum] = door
    prompt.Triggered:Connect(function(player)
        if game:GetAttribute("MatchmakingEnabled") and player:GetAttribute("MatchActive") ~= true then return end
        local now = os.clock()
        if now - (lastOpen[player.UserId] or -10) < 0.5 then return end
        lastOpen[player.UserId] = now
        apply(door, true, true)
        openSound:Stop()
        openSound:Play()
        door.nextChange = now + PLAYER_OPEN_HOLD_SECONDS
    end)
    museum.Destroying:Connect(function()
        doors[museum] = nil
    end)
    randomize(door)
end

function MuseumDoors.Start()
    if started then return end
    started = true
    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - lastTick < 0.5 then return end
        lastTick = now
        for museum, door in doors do
            if museum.Parent == nil then
                doors[museum] = nil
            elseif now >= door.nextChange then
                randomize(door)
            end
        end
    end)
    Players.PlayerRemoving:Connect(function(player)
        lastOpen[player.UserId] = nil
    end)
end

return table.freeze(MuseumDoors)
