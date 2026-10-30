--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Plots = require(ReplicatedStorage.Shared.PlotDefinitions)
local TierOne = require(ReplicatedStorage.Shared.Task11TierOneContract)
local Catalog = require(ReplicatedStorage.Shared.ItemCatalog)
local ItemVisuals = require(ReplicatedStorage.Shared.ItemVisuals)
local ProfileService = require(script.Parent.ProfileService)
local WorldCollision = require(script.Parent.WorldCollision)
local PlotProtection = require(script.Parent.PlotProtection)
local MuseumDoors = require(script.Parent.MuseumDoors)
local TravelEffects = require(script.Parent.TravelEffects)
local DistrictUrbanVisuals = require(script.Parent.DistrictUrbanVisuals)
local DistrictOutdoorDetail = require(script.Parent.DistrictOutdoorDetail)
local MatchRules = require(script.Parent.Parent.Parent.MatchShared.MatchRules)

type Assignment = { plotId: string, cloneId: string, museum: Model, spawn: BasePart }
local PlotService = {}
local started = false
local map: Model? = nil
local pack: Folder? = nil
local assignments: {[number]: Assignment} = {}
local occupied: {[string]: number} = {}
local districtOffset = Vector3.new(610, 0.5, 0)
local socket: (Model, string, string) -> BasePart?
local SAFE_BLUE = Color3.fromRGB(105, 175, 255)
local PUBLIC_GOLD = Color3.fromRGB(244, 197, 97)
local TIER_COLORS = {
    Common = Color3.fromRGB(80, 222, 188),
    Uncommon = Color3.fromRGB(106, 174, 255),
    Rare = Color3.fromRGB(199, 140, 255),
    Legendary = Color3.fromRGB(255, 201, 106),
}

local function updateStandPlaques(museum: Model)
    for _, entry in {
        { name = "ProtectedDisplaySocketLabel", text = "SAFE  /  HALF INCOME", color = SAFE_BLUE },
        { name = "Exposed01SocketLabel", text = "PUBLIC 1  /  FULL INCOME", color = PUBLIC_GOLD },
        { name = "Exposed02SocketLabel", text = "PUBLIC 2  /  FULL INCOME", color = PUBLIC_GOLD },
    } do
        local plaque = museum:FindFirstChild(entry.name, true)
        if plaque and plaque:IsA("BasePart") then
            plaque.Size = Vector3.new(plaque.Size.X, 0.9, plaque.Size.Z)
            plaque.CFrame *= CFrame.new(0, 0.17, 0)
        end
        local surface = plaque and plaque:FindFirstChildOfClass("SurfaceGui")
        local caption = surface and surface:FindFirstChildOfClass("TextLabel")
        if caption then
            caption.Text = entry.text
            caption.TextColor3 = entry.color
            caption.TextScaled = true
            caption.TextWrapped = true
        end
    end
end

local function addDisplayEffects(display: Model, target: BasePart,
    _slotId: string, itemId: string)
    local tier = Catalog.ById[itemId].tier
    local count = ({ Common = 1, Uncommon = 2, Rare = 3, Legendary = 4 })[tier] or 1
    local color = TIER_COLORS[tier] or TIER_COLORS.Common
    -- Discrete tier jewels sit on the plinth, leaving the exhibit unobstructed.
    for index = 1, count do
        local jewel = Instance.new("Part")
        jewel.Name = "ExhibitTierJewel"
        jewel.Size = Vector3.new(0.16, 0.16, 0.08)
        jewel.CFrame = target.CFrame * CFrame.new((index - (count + 1) / 2) * 0.27, -1.03, -1.3)
            * CFrame.Angles(0, 0, math.pi / 4)
        jewel.Material = Enum.Material.Neon
        jewel.Color = color
        jewel.Anchored = true
        jewel.CanCollide = false
        jewel.CanTouch = false
        jewel.CanQuery = false
        jewel.CastShadow = false
        jewel.Parent = display
    end
end

local function addStandRulePrompts(museum: Model)
    for _, slotId in TierOne.Contract.socketIds do
        local name = TierOne.Contract.socketNamesById[slotId]
        local target = socket(museum, name, slotId)
        if target == nil then continue end
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "StandRulesPrompt"
        prompt.ActionText = "How stands work"
        prompt.ObjectText = if slotId == "protected" then "Protected stand" else "Public stand"
        prompt.KeyboardKeyCode = Enum.KeyCode.F
        prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Style = Enum.ProximityPromptStyle.Default
        prompt:SetAttribute("DefaultPromptStyle", true)
        prompt:SetAttribute("StandRuleSlot", slotId)
        local helpPoint = Instance.new("Attachment")
        helpPoint.Name = "StandRulesHelpPoint"
        local side = if slotId == "exposed_01" then -7 else 7
        helpPoint.Position = Vector3.new(side, -2.2, -5)
        helpPoint.Parent = target
        prompt.Parent = helpPoint
    end
end

local function clearEntranceBlockers(museum: Instance)
    for _, name in { "RaidEntrance", "Approach" } do
        local marker = museum:FindFirstChild(name, true)
        if marker and marker:IsA("BasePart") then
            marker.CanCollide = false
            marker.CanQuery = false
        end
    end
end

local function makePart(parent: Instance, name: string, position: Vector3,
    size: Vector3, color: Color3): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Position = position
    part.Size = size
    part.Color = color
    part.Material = Enum.Material.Slate
    part.Anchored = true
    part.CanCollide = true
    part.Parent = parent
    return part
end

local function splitLongStrip(part: BasePart, gapCenterZ: number, gapHalfWidth: number)
    local low = part.Position.Z - part.Size.Z / 2
    local high = part.Position.Z + part.Size.Z / 2
    for _, span in {
        {low, gapCenterZ - gapHalfWidth},
        {gapCenterZ + gapHalfWidth, high},
    } do
        local length = span[2] - span[1]
        if length > 0 then
            local piece = part:Clone()
            piece.Name = part.Name .. (if span[1] == low then "North" else "South")
            piece.Size = Vector3.new(part.Size.X, part.Size.Y, length)
            piece.Position = Vector3.new(part.Position.X, part.Position.Y,
                (span[1] + span[2]) / 2)
            piece.Parent = part.Parent
        end
    end
    part:Destroy()
end

local function openDistrictGate(current: Model, expansion: Model)
    local boundary = current:FindFirstChild("BoundaryArt")
    local east = boundary and boundary:FindFirstChild("InvWall_East")
    if east == nil or not east:IsA("BasePart") then return end
    east.CanCollide = false
    east.CanQuery = false
    for _, side in { -1, 1 } do
        local wall = east:Clone()
        wall.Name = if side < 0 then "InvWall_EastNorth" else "InvWall_EastSouth"
        wall.Size = Vector3.new(east.Size.X, east.Size.Y, 68)
        wall.Position = east.Position + Vector3.new(0, 0, side * 56)
        wall.CanCollide = true
        wall.CanQuery = true
        wall.Parent = boundary
    end
    local perimeter = expansion:FindFirstChild("PerimeterDecor")
    local edge = perimeter and perimeter:FindFirstChild("EstateEdge")
    if edge and edge:IsA("BasePart") and edge.Size.Z > 100
        and math.abs(edge.Position.X - east.Position.X) < 5 then
        splitLongStrip(edge, east.Position.Z, 23)
    end
    local ridges = perimeter and perimeter:FindFirstChild("SculptedRidges")
    local groundExtension = ridges and ridges:FindFirstChild("EastWestGroundExtension")
    local originalGround = current:FindFirstChild("Ground")
    if groundExtension and groundExtension:IsA("BasePart")
        and originalGround and originalGround:IsA("BasePart") then
        splitLongStrip(groundExtension, originalGround.Position.Z,
            originalGround.Size.Z / 2)
    end
end

local function stopSurfaceY(expansion: Model, x: number, z: number): number
    -- The museum-district stop sits on the depot platform, which is raised
    -- above the ground. Rest the pad on that surface so it is not buried.
    local depot = expansion:FindFirstChild("Depot")
    local platform = depot and depot:FindFirstChild("Platform")
    if platform and platform:IsA("BasePart") then
        local offset = platform.CFrame:PointToObjectSpace(Vector3.new(x, platform.Position.Y, z))
        if math.abs(offset.X) <= platform.Size.X / 2 and math.abs(offset.Z) <= platform.Size.Z / 2 then
            return platform.Position.Y + platform.Size.Y / 2
        end
    end
    return 0.46
end

local function addStopMarker(pad: BasePart, destination: string)
    local glow = Instance.new("Part")
    glow.Name = "StopBeacon"
    glow.Shape = Enum.PartType.Cylinder
    glow.Size = Vector3.new(0.2, 14, 14)
    glow.CFrame = pad.CFrame * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90))
    glow.Color = Color3.fromRGB(74, 235, 194)
    glow.Material = Enum.Material.Neon
    glow.Transparency = 0.55
    glow.Anchored = true
    glow.CanCollide = false
    glow.CanQuery = false
    glow.CanTouch = false
    glow.Parent = pad
    local light = Instance.new("PointLight")
    light.Color = glow.Color
    light.Range = 14
    light.Brightness = 1.5
    light.Parent = glow
    local sign = Instance.new("BillboardGui")
    sign.Name = "StopSign"
    sign.Size = UDim2.fromOffset(190, 46)
    sign.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
    sign.MaxDistance = 140
    sign.LightInfluence = 0
    sign.Parent = pad
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = Color3.fromRGB(12, 30, 26)
    text.BackgroundTransparency = 0.15
    text.TextColor3 = Color3.fromRGB(74, 235, 194)
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.Text = "SHUTTLE\nto " .. destination
    text.Parent = sign
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = text
end

local function buildConnector(current: Model, expansion: Model)
    local connector = Instance.new("Folder")
    connector.Name = "DistrictConnector"
    connector.Parent = current
    local road = Color3.fromRGB(91, 91, 84)
    for index = 1, 5 do
        makePart(connector, "Walkway" .. index,
            Vector3.new(110 + (index - 0.5) * 100, 0.48, 0),
            Vector3.new(100, 0.12, 22), road)
    end
    for _, stop in {
        { name = "OldDistrictStop", x = 150, destination = Vector3.new(590, 5, 0) },
        { name = "MuseumDistrictStop", x = 590, destination = Vector3.new(150, 5, 0) },
    } do
        local surface = stopSurfaceY(expansion, stop.x, -16)
        local pad = makePart(connector, stop.name,
            Vector3.new(stop.x, surface + 0.2, -16), Vector3.new(12, 0.4, 8),
            Color3.fromRGB(74, 235, 194))
        pad.Material = Enum.Material.Neon
        local destinationName = if stop.x < 300 then "Six-museum district" else "Original museum"
        addStopMarker(pad, destinationName)
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Ride district shuttle"
        prompt.ObjectText = destinationName
        prompt.HoldDuration = 0.5
        prompt.MaxActivationDistance = 12
        prompt.RequiresLineOfSight = false
        prompt.Style = Enum.ProximityPromptStyle.Custom
        prompt.Parent = pad
        local lastRide: {[number]: number} = {}
        prompt.Triggered:Connect(function(player)
            if game:GetAttribute("MatchmakingEnabled") and player:GetAttribute("MatchActive") ~= true then return end
            local now = os.clock()
            if now - (lastRide[player.UserId] or -10) < 3 then return end
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root == nil or not root:IsA("BasePart") then return end
            lastRide[player.UserId] = now
            TravelEffects.Teleport(player, CFrame.new(stop.destination))
        end)
    end
end

local function addMuseumReturnPad(expansion: Model)
    local depot = expansion:FindFirstChild("Depot")
    local platform = depot and depot:FindFirstChild("Platform")
    if depot == nil or platform == nil or not platform:IsA("BasePart") then return end

    -- The gap between the tutorial pedestal and the public pedestals is clear.
    local pad = makePart(depot, "MuseumReturnPad",
        platform.CFrame:PointToWorldSpace(Vector3.new(0, platform.Size.Y / 2 + 0.2, -2)),
        Vector3.new(12, 0.4, 8), Color3.fromRGB(74, 235, 194))
    pad.Material = Enum.Material.Neon
    addStopMarker(pad, "YOUR MUSEUM")
    local returnSign = pad:FindFirstChild("StopSign")
    if returnSign and returnSign:IsA("BillboardGui") then
        returnSign.Size = UDim2.fromOffset(170, 30)
        returnSign.StudsOffsetWorldSpace = Vector3.new(0, 0.5, -3)
        returnSign.MaxDistance = 50
        local signText = returnSign:FindFirstChildOfClass("TextLabel")
        if signText then signText.Text = "RIDE TO MUSEUM" end
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "ReturnToMuseum"
    prompt.ActionText = "Ride to my museum"
    prompt.ObjectText = "Museum return shuttle"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.Parent = pad

    local lastRide: {[number]: number} = {}
    prompt.Triggered:Connect(function(player)
        if game:GetAttribute("MatchmakingEnabled") and player:GetAttribute("MatchActive") ~= true then return end
        local now = os.clock()
        if now - (lastRide[player.UserId] or -10) < 3 then return end
        local assignment = assignments[player.UserId]
        if assignment == nil or assignment.museum.Parent == nil or assignment.spawn.Parent == nil then return end
        lastRide[player.UserId] = now
        -- Use the same clear interior arrival point as the assigned spawn.
        TravelEffects.Teleport(player, assignment.spawn.CFrame * CFrame.new(0, 3, -20))
    end)
end

local function addDispatchPrompts(expansion: Model)
    local plots = expansion:FindFirstChild("PlotSlots")
    if plots == nil then return end
    for _, plot in plots:GetChildren() do
        local gate = plot:FindFirstChild("GateTier1")
        if gate and gate:IsA("BasePart") then
            local prompt = Instance.new("ProximityPrompt")
            prompt.Name = "ScoutRoute"
            prompt.ActionText = "Ride to depot"
            prompt.ObjectText = "Museum dispatch"
            prompt.HoldDuration = 0.4
            prompt.MaxActivationDistance = 12
            prompt.RequiresLineOfSight = false
            prompt.Style = Enum.ProximityPromptStyle.Custom
            prompt.Parent = gate
            prompt.Triggered:Connect(function(player)
                if game:GetAttribute("MatchmakingEnabled") and player:GetAttribute("MatchActive") ~= true then return end
                local character = player.Character
                if character == nil then return end
                local depot = expansion:FindFirstChild("Depot")
                local platform = depot and depot:FindFirstChild("Platform")
                if platform == nil or not platform:IsA("BasePart") then return end
                if TravelEffects.Teleport(player,
                    CFrame.new(platform.Position + Vector3.new(0, 4, -16))) then
                    player:SetAttribute("RouteScouted", true)
                    player:SetAttribute("HudNotificationText", "AT THE DEPOT")
                    player:SetAttribute("HudNotificationDetail",
                        "Pick up your item, then choose the open or covered path back to your museum.")
                    player:SetAttribute("HudNotificationKind", "Info")
                    player:SetAttribute("HudNotificationSerial",
                        (player:GetAttribute("HudNotificationSerial") or 0) + 1)
                end
            end)
        end
    end
end

socket = function(model: Model, name: string, anchorId: string): BasePart?
    local part = model:FindFirstChild(name, true)
    if part ~= nil and part:IsA("BasePart") and part:GetAttribute("AnchorId") == anchorId then
        return part
    end
    return nil
end

local function validateClone(model: Model): (boolean, BasePart?)
    local spawn = socket(model, "PlayerSpawn", "spawn")
    if spawn == nil or socket(model, "ReceivingZone", "receiving") == nil then
        return false, nil
    end
    for slotId, partName in pairs(TierOne.Contract.socketNamesById) do
        if socket(model, partName, slotId) == nil then return false, nil end
    end
    return true, spawn
end

local function clear(player: Player)
    local assignment = assignments[player.UserId]
    if assignment == nil then return end
    assignments[player.UserId] = nil
    occupied[assignment.plotId] = nil
    player:SetAttribute("AssignedPlotId", nil)
    player:SetAttribute("MuseumCloneId", nil)
    player:SetAttribute("PlotState", nil)
    PlotProtection.Clear(player)
    assignment.museum:Destroy()
    local expansion = map and map:FindFirstChild("ExpansionDistrict")
    if expansion and expansion:IsA("Model") then
        DistrictOutdoorDetail.Show(expansion, assignment.plotId)
    end
end

local function placeCharacter(player: Player, character: Model)
    local assignment = assignments[player.UserId]
    if assignment == nil or player:GetAttribute("ProfileState") ~= "Ready" then return end
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if root == nil or not root:IsA("BasePart") then return end
    if assignments[player.UserId] ~= assignment then return end
    -- The authored spawn socket is close to the rear wall. Move the avatar
    -- toward the middle aisle so the follow camera starts inside the hall.
    character:PivotTo(assignment.spawn.CFrame * CFrame.new(0, 3, -20))
end

local function assign(player: Player)
    if assignments[player.UserId] ~= nil or player.Parent ~= Players then return end
    local profile = ProfileService.GetSnapshot(player)
    if profile == nil or profile.museum == nil or profile.museum.tier ~= 1
        or map == nil or pack == nil then return end
    local source = pack:FindFirstChild("StarterMuseumTemplate")
    local presets = pack:FindFirstChild("LandscapePresets")
    local preset = presets and presets:FindFirstChild(profile.museum.groundsPresetId)
    if source == nil or not source:IsA("Model") or source:GetAttribute("TemplateVersion") ~= 1
        or preset == nil or not preset:IsA("Model") then
        warn("[Steal Anything] Task 12 museum template or landscape is missing")
        player:SetAttribute("PlotState", "Unavailable")
        return
    end
    local free = nil
    for _, slot in Plots.Slots do
        if occupied[slot.id] == nil then free = slot; break end
    end
    if free == nil then
        player:SetAttribute("PlotState", "Full")
        return
    end
    local clone = source:Clone()
    local valid, spawn = validateClone(clone)
    if not valid or spawn == nil then
        clone:Destroy()
        player:SetAttribute("PlotState", "Unavailable")
        return
    end
    local cloneId = HttpService:GenerateGUID(false)
    local plotId = free.id
    local transform = CFrame.new(free.center + districtOffset)
        * CFrame.Angles(0, math.rad(free.yawDegrees), 0)
    clone.Name = "Museum_" .. plotId
    clone:PivotTo(transform)
    clone:SetAttribute("OwnerUserId", player.UserId)
    clone:SetAttribute("PlotId", plotId)
    clone:SetAttribute("CloneId", cloneId)
    updateStandPlaques(clone)
    for _, descendant in clone:GetDescendants() do
        if descendant:IsA("BasePart") and descendant:GetAttribute("AnchorId") ~= nil then
            descendant:SetAttribute("SocketId", plotId .. "." .. cloneId .. "."
                .. tostring(descendant:GetAttribute("AnchorId")))
        end
    end
    addStandRulePrompts(clone)
    local grounds = preset:Clone()
    grounds:PivotTo(transform * preset:GetPivot())
    grounds.Parent = clone
    WorldCollision.Prepare(clone)
    clearEntranceBlockers(clone)
    local displayFolder = Instance.new("Folder")
    displayFolder.Name = "RegisteredDisplays"
    displayFolder.Parent = clone
    local owned = map:FindFirstChild("OwnedMuseums")
    if owned == nil then
        clone:Destroy()
        player:SetAttribute("PlotState", "Unavailable")
        return
    end
    occupied[plotId] = player.UserId
    assignments[player.UserId] = { plotId = plotId, cloneId = cloneId,
        museum = clone, spawn = spawn }
    DistrictOutdoorDetail.Hide(plotId)
    clone.Parent = owned
    MuseumDoors.Attach(clone)
    PlotProtection.Assign(player, plotId, free.center + districtOffset, clone)
    player:SetAttribute("AssignedPlotId", plotId)
    player:SetAttribute("MuseumCloneId", cloneId)
    player:SetAttribute("PlotState", "Ready")
    PlotService.RefreshDisplays(player)
    if player.Character ~= nil then task.spawn(placeCharacter, player, player.Character) end
end

local function playerAdded(player: Player)
    player:GetAttributeChangedSignal("ProfileState"):Connect(function()
        if player:GetAttribute("ProfileState") == "Ready" then
            assign(player)
        else
            clear(player)
        end
    end)
    player.CharacterAdded:Connect(function(character)
        PlotProtection.CharacterAdded(player, character)
        task.spawn(placeCharacter, player, character)
    end)
    if player:GetAttribute("ProfileState") == "Ready" then assign(player) end
end

function PlotService.GetMuseum(player: Player): Model?
    if not MatchRules.CanPlay(game:GetAttribute("MatchmakingEnabled") == true,
        player:GetAttribute("MatchActive")) then
        return nil
    end
    local assignment = assignments[player.UserId]
    if assignment == nil or player:GetAttribute("ProfileState") ~= "Ready"
        or assignment.museum.Parent == nil then return nil end
    return assignment.museum
end

function PlotService.GetSocket(player: Player, name: string, anchorId: string): BasePart?
    local museum = PlotService.GetMuseum(player)
    if museum == nil then return nil end
    return socket(museum, name, anchorId)
end

function PlotService.RefreshDisplays(player: Player)
    -- Display reconstruction still runs while a lone player waits for a match.
    local assignment = assignments[player.UserId]
    local museum = assignment and assignment.museum or nil
    local profile = ProfileService.GetSnapshot(player)
    if museum == nil or profile == nil then return end
    local folder = museum:FindFirstChild("RegisteredDisplays")
    if folder == nil then return end
    folder:ClearAllChildren()
    for slotId, partName in pairs(TierOne.Contract.socketNamesById) do
        local itemId = profile.displaySlots[slotId]
        local exhibit = itemId and profile.exhibits[itemId]
        local target = socket(museum, partName, slotId)
        if itemId ~= nil and exhibit ~= nil and exhibit.state == "Available"
            and target ~= nil then
            local center = if itemId == "toaster"
                then target.CFrame * CFrame.new(0, -0.175, 0)
                else target.CFrame * CFrame.new(0, ItemVisuals.Height(itemId) / 2 - 1.1, 0)
            local display = ItemVisuals.Create(itemId, "Display_" .. slotId, center, true)
            display:SetAttribute("ItemId", itemId)
            display:SetAttribute("SlotId", slotId)
            addDisplayEffects(display, target, slotId, itemId)
            display.Parent = folder
        end
    end
end

function PlotService.Start()
    if started then return end
    started = true
    local assets = ServerStorage:FindFirstChild("Assets")
    pack = assets and assets:FindFirstChild("Task11MapTemplates") :: Folder?
    local world = pack and pack:FindFirstChild("SixPlotWorldTemplate")
    if world == nil or not world:IsA("Model") or world:GetAttribute("TemplateVersion") ~= 1 then
        warn("[Steal Anything] Task 12 world template is missing")
        return
    end
    local prior = workspace:FindFirstChild("Map")
    if prior == nil or not prior:IsA("Model") then
        warn("[Steal Anything] Original district map is missing")
        return
    end
    WorldCollision.Prepare(prior)
    local oldMuseum = prior:FindFirstChild("Museum01")
    MuseumDoors.Start()
    if oldMuseum then clearEntranceBlockers(oldMuseum) end
    if oldMuseum and oldMuseum:IsA("Model") then MuseumDoors.Attach(oldMuseum) end
    PlotProtection.Start()
    local runtime = world:Clone()
    runtime.Name = "ExpansionDistrict"
    runtime:PivotTo(CFrame.new(districtOffset) * world:GetPivot())
    DistrictUrbanVisuals.Build(runtime)
    WorldCollision.Prepare(runtime)
    local owned = Instance.new("Folder")
    owned.Name = "OwnedMuseums"
    owned.Parent = prior
    DistrictOutdoorDetail.Build(runtime)
    runtime.Parent = prior
    addDispatchPrompts(runtime)
    openDistrictGate(prior, runtime)
    buildConnector(prior, runtime)
    addMuseumReturnPad(runtime)
    map = prior
    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(function(player)
        clear(player)
        task.defer(function()
            for _, waiting in Players:GetPlayers() do
                if waiting:GetAttribute("ProfileState") == "Ready"
                    and waiting:GetAttribute("PlotState") == "Full" then
                    assign(waiting)
                end
            end
        end)
    end)
    for _, player in Players:GetPlayers() do playerAdded(player) end
end

return table.freeze(PlotService)
