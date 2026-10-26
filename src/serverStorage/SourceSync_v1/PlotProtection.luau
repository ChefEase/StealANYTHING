--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Plots = require(game:GetService("ReplicatedStorage").Shared.PlotDefinitions)

type Beacon = { lamp: BasePart, light: PointLight, text: TextLabel }
type Record = {
    center: Vector3,
    parts: {BasePart},
    ownerGroup: string,
    museum: Instance,
    beacon: Beacon?,
    graceEnds: number,
    status: string,
}

local PlotProtection = {}
local records: {[number]: Record} = {}
local lastTick = 0
local HALF = Plots.Tiers[1].groundsStuds / 2
-- After the owner leaves the building, the grounds stay secured this long so
-- visitors can see the change coming before the property opens.
local DEPARTURE_GRACE_SECONDS = 10
local STATUS_STYLE: {[string]: {color: Color3, text: string}} = {
    Secured = { color = Color3.fromRGB(235, 74, 74), text = "OWNER HOME — SECURED" },
    Leaving = { color = Color3.fromRGB(240, 176, 64), text = "OWNER LEFT — OPENS IN %ds" },
    Open = { color = Color3.fromRGB(74, 235, 194), text = "OWNER AWAY" },
}

local function makeBeacon(museum: Instance, center: Vector3): Beacon?
    local entrance = museum:FindFirstChild("RaidEntrance", true)
    if entrance == nil or not entrance:IsA("BasePart") then return nil end
    -- Sit the lamp on the roof edge above the doorway, readable from the garden edge.
    local inward = if entrance.CFrame:PointToObjectSpace(center).Z >= 0 then 1 else -1
    local lamp = Instance.new("Part")
    lamp.Name = "SecurityLight"
    lamp.Shape = Enum.PartType.Ball
    lamp.Size = Vector3.new(1.8, 1.8, 1.8)
    lamp.CFrame = entrance.CFrame * CFrame.new(0, entrance.Size.Y / 2 + 6.5, inward * 0.5)
    lamp.Material = Enum.Material.Neon
    lamp.Anchored = true
    lamp.CanCollide = false
    lamp.CanQuery = false
    lamp.CanTouch = false
    lamp.Parent = museum
    local light = Instance.new("PointLight")
    light.Range = 16
    light.Brightness = 2
    light.Parent = lamp
    local sign = Instance.new("BillboardGui")
    sign.Name = "SecurityStatus"
    sign.Size = UDim2.fromOffset(220, 34)
    sign.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
    sign.MaxDistance = 160
    sign.LightInfluence = 0
    sign.Parent = lamp
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = Color3.fromRGB(14, 18, 20)
    text.BackgroundTransparency = 0.2
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.Parent = sign
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = text
    return { lamp = lamp, light = light, text = text }
end

local function showStatus(record: Record, status: string, secondsLeft: number)
    local style = STATUS_STYLE[status]
    local label = if status == "Leaving" then string.format(style.text, secondsLeft) else style.text
    local key = status .. label
    if record.status == key then return end
    record.status = key
    record.museum:SetAttribute("SecurityState", status)
    local beacon = record.beacon
    if beacon == nil then return end
    beacon.lamp.Color = style.color
    beacon.light.Color = style.color
    beacon.text.TextColor3 = style.color
    beacon.text.Text = label
end

local function insideGrounds(center: Vector3, position: Vector3): boolean
    return math.abs(position.X - center.X) < HALF
        and math.abs(position.Z - center.Z) < HALF
        and position.Y > center.Y - 8 and position.Y < center.Y + 48
end

local function ownerInsideMuseum(center: Vector3, position: Vector3): boolean
    return math.abs(position.X - center.X) < 30
        and math.abs(position.Z - center.Z) < 30
        and position.Y > center.Y - 8 and position.Y < center.Y + 27
end

local function rootOf(player: Player): BasePart?
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root else nil
end

local function setCharacterGroup(character: Model, group: string)
    local function set(instance: Instance)
        if instance:IsA("BasePart") then instance.CollisionGroup = group end
    end
    for _, instance in character:GetDescendants() do set(instance) end
    character.DescendantAdded:Connect(set)
end

function PlotProtection.Assign(player: Player, plotId: string, center: Vector3, parent: Instance)
    PlotProtection.Clear(player)
    local ownerGroup = "MuseumOwner_" .. plotId
    local barrierGroup = "MuseumBarrier_" .. plotId
    if not workspace:IsCollisionGroupRegistered(ownerGroup) then
        workspace:RegisterCollisionGroup(ownerGroup)
    end
    if not workspace:IsCollisionGroupRegistered(barrierGroup) then
        workspace:RegisterCollisionGroup(barrierGroup)
    end
    workspace:CollisionGroupSetCollidable(ownerGroup, barrierGroup, false)
    local walls: {BasePart} = {}
    for _, wall in {
        { "North", Vector3.new(0, 18, HALF), Vector3.new(HALF * 2 + 4, 36, 3) },
        { "South", Vector3.new(0, 18, -HALF), Vector3.new(HALF * 2 + 4, 36, 3) },
        { "East", Vector3.new(HALF, 18, 0), Vector3.new(3, 36, HALF * 2 + 4) },
        { "West", Vector3.new(-HALF, 18, 0), Vector3.new(3, 36, HALF * 2 + 4) },
    } do
        local part = Instance.new("Part")
        part.Name = "VisitorBarrier_" .. wall[1]
        part.Position = center + wall[2]
        part.Size = wall[3]
        part.Anchored = true
        part.Transparency = 1
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CollisionGroup = barrierGroup
        part.Parent = parent
        table.insert(walls, part)
    end
    records[player.UserId] = {
        center = center, parts = walls, ownerGroup = ownerGroup, museum = parent,
        beacon = makeBeacon(parent, center), graceEnds = 0, status = "",
    }
    if player.Character then setCharacterGroup(player.Character, ownerGroup) end
end

function PlotProtection.CharacterAdded(player: Player, character: Model)
    local record = records[player.UserId]
    if record then setCharacterGroup(character, record.ownerGroup) end
end

function PlotProtection.Clear(player: Player)
    local record = records[player.UserId]
    if not record then return end
    records[player.UserId] = nil
    for _, part in record.parts do part:Destroy() end
    if record.beacon then record.beacon.lamp:Destroy() end
    if player.Character then
        for _, part in player.Character:GetDescendants() do
            if part:IsA("BasePart") then part.CollisionGroup = "Default" end
        end
    end
end

function PlotProtection.Start()
    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - lastTick < 0.25 then return end
        lastTick = now
        for ownerId, record in records do
            local owner = Players:GetPlayerByUserId(ownerId)
            local ownerRoot = owner and rootOf(owner)
            local home = ownerRoot ~= nil and ownerInsideMuseum(record.center, ownerRoot.Position)
            if home then record.graceEnds = now + DEPARTURE_GRACE_SECONDS end
            local leaving = not home and owner ~= nil and now < record.graceEnds
            local active = home or leaving
            showStatus(record, if home then "Secured" elseif leaving then "Leaving" else "Open",
                math.ceil(record.graceEnds - now))
            for _, wall in record.parts do wall.CanCollide = active end
            if active then
                for _, visitor in Players:GetPlayers() do
                    if visitor.UserId == ownerId then continue end
                    local visitorRoot = rootOf(visitor)
                    if visitorRoot and insideGrounds(record.center, visitorRoot.Position) then
                        local offset = visitorRoot.Position - record.center
                        local x = math.abs(offset.X)
                        local z = math.abs(offset.Z)
                        local exitPosition = if x > z
                            then Vector3.new(record.center.X + math.sign(offset.X) * (HALF + 7), visitorRoot.Position.Y, visitorRoot.Position.Z)
                            else Vector3.new(visitorRoot.Position.X, visitorRoot.Position.Y,
                                record.center.Z + math.sign(if offset.Z == 0 then 1 else offset.Z) * (HALF + 7))
                        if visitor.Character then visitor.Character:PivotTo(CFrame.new(exitPosition)) end
                    end
                end
            end
        end
    end)
end

return table.freeze(PlotProtection)
