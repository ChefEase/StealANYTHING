--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage.Shared.BalanceConfig)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
local ToasterVisual = require(ReplicatedStorage.Shared.ToasterVisual)
local ProfileService = require(script.Parent.ProfileService)
local PlotService = require(script.Parent.PlotService)
local TravelEffects = require(script.Parent.TravelEffects)
local TutorialCarryState = require(script.Parent.TutorialCarryState)

local TARGET_ID = "depot.tutorial_pedestal"
local PICKUP_TIMEOUT_SECONDS = Balance.PICKUP_HOLD_SECONDS + 2
local CHECK_INTERVAL_SECONDS = 0.1
local MAX_SAMPLE_SPEED = Balance.NORMAL_CARRY_SPEED * 1.5

local state = TutorialCarryState.New(os.clock, function(): string
    return HttpService:GenerateGUID(false)
end)

local started = false
local target: BasePart? = nil
local display: Model? = nil
local prompt: ProximityPrompt? = nil
local feedback: RemoteEvent? = nil
local visuals: {[number]: Model} = {}
local armPoses: {[number]: { { joint: Motor6D, original: CFrame } }} = {}
local carryTelemetry: {[number]: any} = {}
local deliveryLocked: {[number]: boolean} = {}
local lastBegin: {[number]: number} = {}
local lastFeedback: {[number]: number} = {}

local CarryService = {}

local function tell(player: Player, message: string, kind: string?)
    local now = os.clock()
    if now - (lastFeedback[player.UserId] or -math.huge) < 0.75 then return end
    lastFeedback[player.UserId] = now
    if feedback ~= nil and player.Parent == Players then
        feedback:FireClient(player, { text = message, kind = kind or "Info" })
    end
end

local function tutorialEligible(player: Player): boolean
    local profile = ProfileService.GetSnapshot(player)
    return profile ~= nil and PlotService.GetMuseum(player) ~= nil
        and (profile.tutorialStep == 0 and profile.exhibits.toaster == nil
        or player:GetAttribute("TutorialReplayActive") == true)
end

local function setPickupEligible(player: Player)
    if player.Parent == Players then
        local session = state:Get(player.UserId)
        player:SetAttribute("TutorialPickupEligible",
            tutorialEligible(player) and (session == nil or session.kind == "Pending"))
    end
end

local function livingCharacter(player: Player): (Model?, Humanoid?, BasePart?)
    local character = player.Character
    if character == nil then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if humanoid == nil or humanoid.Health <= 0 or root == nil or not root:IsA("BasePart") then
        return nil, nil, nil
    end
    return character, humanoid, root
end

local function insideZone(root: BasePart, zone: BasePart?): boolean
    if zone == nil or zone.Parent == nil then return false end
    local localPosition = zone.CFrame:PointToObjectSpace(root.Position)
    return math.abs(localPosition.X) <= zone.Size.X / 2
        and math.abs(localPosition.Z) <= zone.Size.Z / 2
        and math.abs(localPosition.Y) <= zone.Size.Y / 2 + 1
end

local function currentDeliveryZone(player: Player, root: BasePart): BasePart?
    local protected = PlotService.GetSocket(player, "ProtectedDisplaySocket", "protected")
    local receiving = PlotService.GetSocket(player, "ReceivingZone", "receiving")
    if insideZone(root, protected) then return protected end
    if insideZone(root, receiving) then return receiving end
    return nil
end

local function sampleCarryRoute(route: any, position: Vector3)
    local now = os.clock()
    local distance = (position - route.lastPosition).Magnitude
    local elapsed = math.max(0.001, now - route.lastTime)
    if distance > math.max(14, elapsed * MAX_SAMPLE_SPEED + 8) then
        route.invalid = true
    end
    route.distance += distance
    if route.distance > (now - route.startedAt)
        * Balance.NORMAL_CARRY_SPEED * 1.35 + 12 then
        route.invalid = true
    end
    route.lastPosition = position
    route.lastTime = now
end

local function validPickupPosition(player: Player): boolean
    local anchor = target
    if anchor == nil or anchor.Parent == nil then return false end
    local character, _, root = livingCharacter(player)
    if character == nil or root == nil then return false end
    if (root.Position - anchor.Position).Magnitude > Balance.PICKUP_DISTANCE_STUDS then
        return false
    end

    local head = character:FindFirstChild("Head")
    local origin = if head ~= nil and head:IsA("BasePart") then head.Position else root.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local ignored: {Instance} = { character, anchor }
    if display ~= nil then table.insert(ignored, display) end
    rayParams.FilterDescendantsInstances = ignored
    rayParams.IgnoreWater = true
    rayParams.RespectCanCollide = true
    return workspace:Raycast(origin, anchor.Position - origin, rayParams) == nil
end

local function buildTarget(): boolean
    local map = workspace:FindFirstChild("Map")
    local district = map and map:FindFirstChild("ExpansionDistrict")
    local depot = district and district:FindFirstChild("Depot")
        or map and map:FindFirstChild("Depot")
    local socket = depot and depot:FindFirstChild("TutorialPedestalSocket")
    if socket == nil or not socket:IsA("BasePart")
        or socket:GetAttribute("SocketId") ~= TARGET_ID then
        warn("[Steal Anything] Tutorial pedestal socket is missing or has the wrong ID")
        return false
    end
    local runtime = Instance.new("Folder")
    runtime.Name = "TutorialRuntime"
    runtime.Parent = workspace

    local anchor = Instance.new("Part")
    anchor.Name = "TutorialPickupTarget"
    anchor.Size = Vector3.new(0.5, 0.5, 0.5)
    -- The tested route reaches the pedestal from its east edge (about -83, -72).
    anchor.CFrame = socket.CFrame * CFrame.new(5.5, 0, 0)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.Parent = runtime
    target = anchor

    local toaster = ToasterVisual.Create("TutorialToasterDisplay", socket.CFrame * CFrame.new(0, -0.6, 0), true)
    toaster.Parent = runtime
    display = toaster

    local pickupPrompt = Instance.new("ProximityPrompt")
    pickupPrompt.Name = "TutorialPickupPrompt"
    pickupPrompt.ActionText = "Pick up"
    pickupPrompt.ObjectText = "Dramatic Toaster"
    pickupPrompt.HoldDuration = Balance.PICKUP_HOLD_SECONDS
    pickupPrompt.MaxActivationDistance = Balance.PICKUP_DISTANCE_STUDS
    pickupPrompt.RequiresLineOfSight = true
    pickupPrompt.KeyboardKeyCode = Enum.KeyCode.E
    pickupPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    pickupPrompt.Style = Enum.ProximityPromptStyle.Custom
    pickupPrompt:SetAttribute("PickupTargetId", TARGET_ID)
    pickupPrompt.Parent = anchor
    prompt = pickupPrompt
    return true
end

local function destroyVisual(player: Player)
    local visual = visuals[player.UserId]
    if visual ~= nil then
        visuals[player.UserId] = nil
        visual:Destroy()
    end
end

local function restoreArmPose(player: Player)
    local poses = armPoses[player.UserId]
    armPoses[player.UserId] = nil
    if poses == nil then return end
    for _, pose in poses do
        if pose.joint.Parent ~= nil then pose.joint.C0 = pose.original end
    end
end

local function poseArms(player: Player, character: Model)
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if torso == nil then return end
    local poses: { { joint: Motor6D, original: CFrame } } = {}
    for _, side in { "Right", "Left" } do
        local joint = torso:FindFirstChild(side .. "Shoulder")
            or torso:FindFirstChild(side .. " Shoulder")
        if joint ~= nil and joint:IsA("Motor6D") then
            table.insert(poses, { joint = joint, original = joint.C0 })
            joint.C0 = joint.C0 * CFrame.Angles(math.rad(35), 0,
                math.rad(if side == "Right" then -10 else 10))
        end
    end
    armPoses[player.UserId] = poses
end

local function clearCarryDisplay(player: Player)
    player:SetAttribute("CarryId", nil)
    player:SetAttribute("CarryRunId", nil)
    player:SetAttribute("CarryItemId", nil)
    player:SetAttribute("CurrentCarryItem", nil)
    player:SetAttribute("CarryBehavior", nil)
    player:SetAttribute("CarryDestination", nil)
    player:SetAttribute("CarryDistance", nil)
    player:SetAttribute("AtDropOff", nil)
    player:SetAttribute("DeliveryInProgress", nil)
end

local function restoreSpeed(player: Player)
    local _, humanoid = livingCharacter(player)
    if humanoid ~= nil then
        humanoid.WalkSpeed = Balance.NORMAL_WALK_SPEED
    end
end

local function clearPlayer(player: Player)
    state:Clear(player.UserId)
    destroyVisual(player)
    restoreArmPose(player)
    carryTelemetry[player.UserId] = nil
    deliveryLocked[player.UserId] = nil
    clearCarryDisplay(player)
    restoreSpeed(player)
    setPickupEligible(player)
end

local function attachCarry(player: Player, carry: any): boolean
    local character, humanoid, root = livingCharacter(player)
    if character == nil or humanoid == nil or root == nil then return false end
    local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if hand == nil or not hand:IsA("BasePart") then return false end
    poseArms(player, character)
    local center = hand.Position - root.CFrame.RightVector * 0.55
        + root.CFrame.LookVector * 0.55 + Vector3.new(0, 0.25, 0)
    local visual, body = ToasterVisual.Create("CarriedToaster",
        CFrame.new(center) * root.CFrame.Rotation, false)
    local weld = Instance.new("WeldConstraint")
    weld.Name = "CarryAttachment"
    weld.Part0 = hand
    weld.Part1 = body
    weld.Parent = body
    visual.Parent = character
    visuals[player.UserId] = visual
    carryTelemetry[player.UserId] = {
        startedAt = os.clock(),
        startPosition = root.Position,
        lastPosition = root.Position,
        lastTime = os.clock(),
        distance = 0,
        authorizedDistance = 0,
        authorizedTime = 0,
        invalid = false,
    }
    humanoid.WalkSpeed = Balance.NORMAL_CARRY_SPEED
    player:SetAttribute("CarryId", carry.carryId)
    player:SetAttribute("CarryRunId", carry.runId)
    player:SetAttribute("CarryItemId", carry.itemId)
    player:SetAttribute("CurrentCarryItem", ItemCatalog.ById.toaster.name)
    player:SetAttribute("CarryBehavior", ItemCatalog.ById.toaster.carry)
    player:SetAttribute("CarryDestination", "Museum Protected Stand")
    setPickupEligible(player)
    return true
end

local function completePickup(player: Player, requestId: string)
    local session = state:Get(player.UserId)
    if session == nil or session.kind ~= "Pending" or session.requestId ~= requestId then return end
    if not tutorialEligible(player) or not validPickupPosition(player) then
        state:Cancel(player.UserId, requestId)
        setPickupEligible(player)
        tell(player, "Move closer to the toaster and keep it in sight.", "Error")
        return
    end
    local carry, status = state:Complete(player.UserId, requestId)
    if carry == nil then
        if status == "TooSoon" then
            task.delay(0.05, completePickup, player, requestId)
        end
        return
    end
    if not attachCarry(player, carry) then
        state:Drop(player.UserId, carry.carryId)
        setPickupEligible(player)
        return
    end
    tell(player, "Toaster secured. Carry it to your museum drop-off!", "Success")
end

local function beginPickup(player: Player, targetId: any, requestId: any)
    local now = os.clock()
    if now - (lastBegin[player.UserId] or -math.huge) < 0.15 then return end
    lastBegin[player.UserId] = now
    if type(targetId) ~= "string" or targetId ~= TARGET_ID
        or type(requestId) ~= "string" or #requestId < 8 or #requestId > 64
        or string.match(requestId, "^[%w%-]+$") == nil then return end
    if prompt == nil or prompt.Parent == nil or not tutorialEligible(player) then return end
    if not validPickupPosition(player) then
        tell(player, "Move closer to the toaster and keep it in sight.", "Error")
        return
    end
    local pending = state:Begin(player.UserId, requestId)
    if pending ~= nil then setPickupEligible(player) end
end

local function cancelPickup(player: Player, requestId: any)
    if type(requestId) ~= "string" then return end
    if state:Cancel(player.UserId, requestId) then
        setPickupEligible(player)
    end
end

local function dropCarry(player: Player, carryId: any)
    if type(carryId) ~= "string" then return end
    if deliveryLocked[player.UserId] then return end
    if not state:Drop(player.UserId, carryId) then return end
    destroyVisual(player)
    restoreArmPose(player)
    carryTelemetry[player.UserId] = nil
    clearCarryDisplay(player)
    restoreSpeed(player)
    setPickupEligible(player)
    tell(player, "Toaster returned to the depot. You can try again.", "Info")
end

local function characterAdded(player: Player, character: Model)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid == nil or not humanoid:IsA("Humanoid") then return end
    humanoid.WalkSpeed = Balance.NORMAL_WALK_SPEED
    humanoid.Died:Connect(function()
        if player.Character == character then clearPlayer(player) end
    end)
end

local function playerAdded(player: Player)
    player:GetAttributeChangedSignal("MatchActive"):Connect(function()
        if game:GetAttribute("MatchmakingEnabled") and player:GetAttribute("MatchActive") ~= true then
            clearPlayer(player)
        else
            setPickupEligible(player)
        end
    end)
    player:GetAttributeChangedSignal("ProfileState"):Connect(function()
        if player:GetAttribute("ProfileState") ~= "Ready" then
            player:SetAttribute("TutorialReplayActive", false)
            clearPlayer(player)
        else
            setPickupEligible(player)
        end
    end)
    player.CharacterAdded:Connect(function(character)
        task.spawn(characterAdded, player, character)
    end)
    player.CharacterRemoving:Connect(function()
        clearPlayer(player)
    end)
    if player.Character ~= nil then task.spawn(characterAdded, player, player.Character) end
    setPickupEligible(player)
end

function CarryService.GetActiveCarry(player: Player): any?
    local session = state:Get(player.UserId)
    if session == nil or session.kind ~= "Carrying" then return nil end
    return {
        carryId = session.carryId,
        runId = session.runId,
        itemId = session.itemId,
        tutorial = true,
        replay = player:GetAttribute("TutorialReplayActive") == true,
    }
end

local function startTutorialReplay(player: Player)
    local profile = ProfileService.GetSnapshot(player)
    if player:GetAttribute("ProfileState") ~= "Ready" or profile == nil then return end
    if profile.tutorialStep == 0 and profile.exhibits.toaster == nil then
        -- New players already have the real tutorial available.
        setPickupEligible(player)
        return
    end
    if state:Get(player.UserId) ~= nil or deliveryLocked[player.UserId] then
        tell(player, "Finish or drop your current toaster before replaying.", "Info")
        return
    end
    player:SetAttribute("TutorialReplayActive", true)
    setPickupEligible(player)
end

function CarryService.CheckDelivery(player: Player, carryId: string): (boolean, string, any?)
    local session = state:Get(player.UserId)
    if session == nil or session.kind ~= "Carrying" or session.carryId ~= carryId then
        return false, "NoCarry", nil
    end
    local _, _, root = livingCharacter(player)
    if root == nil then
        return false, "NotAtDropOff", nil
    end
    local zone = currentDeliveryZone(player, root)
    if zone == nil then return false, "NotAtDropOff", nil end
    local route = carryTelemetry[player.UserId]
    -- The remote can arrive before the next periodic position sample.
    if route ~= nil then sampleCarryRoute(route, root.Position) end
    if route == nil or route.invalid then return false, "InvalidRoute", nil end
    local straight = (Vector3.new(route.startPosition.X, 0, route.startPosition.Z)
        - Vector3.new(zone.Position.X, 0, zone.Position.Z)).Magnitude
    if os.clock() - route.startedAt + route.authorizedTime < math.max(5,
        straight / Balance.NORMAL_CARRY_SPEED - 1.5)
        or route.distance + route.authorizedDistance < straight * 0.75 then
        return false, "TooFast", nil
    end
    return true, "Ready", CarryService.GetActiveCarry(player)
end

function CarryService.SetDeliveryLocked(player: Player, carryId: string, locked: boolean)
    local session = state:Get(player.UserId)
    if session ~= nil and session.kind == "Carrying" and session.carryId == carryId then
        deliveryLocked[player.UserId] = if locked then true else nil
        player:SetAttribute("DeliveryInProgress", locked)
    end
end

function CarryService.FinishDelivery(player: Player, carryId: string)
    if not state:Drop(player.UserId, carryId) then return end
    deliveryLocked[player.UserId] = nil
    carryTelemetry[player.UserId] = nil
    destroyVisual(player)
    restoreArmPose(player)
    clearCarryDisplay(player)
    restoreSpeed(player)
    setPickupEligible(player)
end

function CarryService.EndReplay(player: Player)
    player:SetAttribute("TutorialReplayActive", false)
    setPickupEligible(player)
end

function CarryService.AbortCarry(player: Player, carryId: string)
    dropCarry(player, carryId)
end

function CarryService.Start()
    if started then return end
    started = true
    TravelEffects.SetCarryTeleportHandlers(function(player: Player, origin: Vector3): boolean
        local session = state:Get(player.UserId)
        local route = carryTelemetry[player.UserId]
        if session == nil or session.kind ~= "Carrying" or route == nil
            or deliveryLocked[player.UserId] then return false end
        sampleCarryRoute(route, origin)
        return not route.invalid
    end, function(player: Player, origin: Vector3, destination: Vector3)
        local route = carryTelemetry[player.UserId]
        if route == nil then return end
        local horizontal = (Vector3.new(origin.X, 0, origin.Z)
            - Vector3.new(destination.X, 0, destination.Z)).Magnitude
        route.authorizedDistance += horizontal
        route.authorizedTime += horizontal / Balance.NORMAL_CARRY_SPEED
        route.lastPosition = destination
        route.lastTime = os.clock()
    end)
    local network = ReplicatedStorage:WaitForChild("Network")
    feedback = network:WaitForChild("Feedback") :: RemoteEvent
    local beginRemote = network:WaitForChild("BeginPickup") :: RemoteEvent
    local cancelRemote = network:WaitForChild("CancelPickup") :: RemoteEvent
    local dropRemote = network:WaitForChild("DropCarry") :: RemoteEvent
    local replayRemote = network:WaitForChild("StartTutorialReplay") :: RemoteEvent

    buildTarget()
    beginRemote.OnServerEvent:Connect(beginPickup)
    cancelRemote.OnServerEvent:Connect(cancelPickup)
    dropRemote.OnServerEvent:Connect(dropCarry)
    replayRemote.OnServerEvent:Connect(startTutorialReplay)
    if prompt ~= nil then
        prompt.Triggered:Connect(function(player: Player)
            local pending = state:Trigger(player.UserId)
            if pending == nil then return end
            local remaining = math.max(0, Balance.PICKUP_HOLD_SECONDS - (os.clock() - pending.startedAt))
            task.delay(remaining, completePickup, player, pending.requestId)
        end)
    end

    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(function(player)
        clearPlayer(player)
        lastBegin[player.UserId] = nil
        lastFeedback[player.UserId] = nil
    end)
    for _, player in Players:GetPlayers() do playerAdded(player) end

    task.spawn(function()
        while started do
            task.wait(CHECK_INTERVAL_SECONDS)
            for _, player in Players:GetPlayers() do
                local session = state:Get(player.UserId)
                if session ~= nil and session.kind == "Pending" then
                    if os.clock() - session.startedAt > PICKUP_TIMEOUT_SECONDS
                        or not tutorialEligible(player) or not validPickupPosition(player) then
                        state:Cancel(player.UserId, session.requestId)
                        setPickupEligible(player)
                    end
                elseif session ~= nil and session.kind == "Carrying" then
                    local _, _, root = livingCharacter(player)
                    local route = carryTelemetry[player.UserId]
                    if root ~= nil and route ~= nil then
                        sampleCarryRoute(route, root.Position)
                        player:SetAttribute("AtDropOff", currentDeliveryZone(player, root) ~= nil)
                    end
                end
            end
        end
    end)
end

return table.freeze(CarryService)
