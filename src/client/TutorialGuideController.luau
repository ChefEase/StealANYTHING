--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhoneHudLayout = require(script.Parent.PhoneHudLayout)
local Theme = require(script.Parent.HudTheme)

local TutorialGuideController = {}

local function makeLabel(name: string, parent: Instance, y: number, height: number,
    size: number, color: Color3): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = UDim2.fromOffset(70, y)
    label.Size = UDim2.new(1, -78, 0, height)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = color
    label.TextSize = size
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = parent
    return label
end

function TutorialGuideController.Start(player: Player, screen: ScreenGui)
    local accent = Theme.Accent
    local panel = Instance.new("Frame")
    panel.Name = "TutorialGuide"
    panel.AnchorPoint = Vector2.new(0.5, 0)
    panel.Position = UDim2.new(0.5, 0, 0, 84)
    panel.Size = UDim2.fromOffset(390, 92)
    panel.BackgroundColor3 = Theme.Ink
    panel.BackgroundTransparency = 0.1
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = screen
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel
    local outline = Instance.new("UIStroke")
    outline.Color = accent
    outline.Thickness = 2
    outline.Transparency = 0.15
    outline.Parent = panel

    local arrow = Instance.new("TextLabel")
    arrow.Name = "DirectionArrow"
    arrow.Position = UDim2.fromOffset(9, 14)
    arrow.Size = UDim2.fromOffset(54, 62)
    arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.GothamBlack
    arrow.Text = utf8.char(9650)
    arrow.TextColor3 = accent
    arrow.TextSize = 45
    arrow.Parent = panel

    local step = makeLabel("Step", panel, 8, 19, 12, accent)
    local instruction = makeLabel("Instruction", panel, 29, 30, 15,
        Theme.Text)
    local distance = makeLabel("Distance", panel, 63, 20, 12,
        Theme.Muted)

    local ride = Instance.new("TextButton")
    ride.Name = "TutorialRideToDepot"
    ride.Size = UDim2.fromOffset(210, 48)
    ride.BackgroundColor3 = accent
    ride.TextColor3 = Theme.Ink
    ride.Font = Enum.Font.GothamBlack
    ride.TextSize = 16
    ride.Text = "RIDE TO DEPOT  »"
    ride.Visible = false
    ride.ZIndex = 18
    ride.Parent = screen
    local rideCorner = Instance.new("UICorner")
    rideCorner.CornerRadius = UDim.new(0, 8)
    rideCorner.Parent = ride
    local rideRemote = ReplicatedStorage:WaitForChild("Network"):WaitForChild("RideToDepot") :: RemoteEvent
    local rideRequestedAt = -math.huge
    ride.Activated:Connect(function()
        if os.clock() - rideRequestedAt < 2 then return end
        rideRequestedAt = os.clock()
        rideRemote:FireServer()
    end)

    local marker = Instance.new("BillboardGui")
    marker.Name = "TutorialWorldMarker"
    marker.Size = UDim2.fromOffset(176, 42)
    marker.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
    marker.AlwaysOnTop = false
    marker.MaxDistance = 150
    marker.Enabled = false
    marker.ResetOnSpawn = false
    marker.Parent = player:WaitForChild("PlayerGui")
    local markerText = Instance.new("TextLabel")
    markerText.Size = UDim2.fromScale(1, 1)
    markerText.BackgroundColor3 = Theme.Ink
    markerText.BackgroundTransparency = 0.12
    markerText.BorderSizePixel = 0
    markerText.Font = Enum.Font.GothamBold
    markerText.TextColor3 = accent
    markerText.TextSize = 13
    markerText.Parent = marker
    local markerCorner = Instance.new("UICorner")
    markerCorner.CornerRadius = UDim.new(0, 7)
    markerCorner.Parent = markerText

    local depotTarget: BasePart? = nil
    local museumTarget: BasePart? = nil
    local museumModel: Model? = nil
    local departureWaypoint: BasePart? = nil
    local escapeWaypoint: BasePart? = nil
    local guidedCarryId: any = nil
    local reachedSideLane = false
    local escapedDepot = false
    local function refreshDepotTarget()
        if depotTarget ~= nil and depotTarget.Parent ~= nil then return end
        local runtime = workspace:FindFirstChild("TutorialRuntime")
        local anchor = runtime and runtime:FindFirstChild("TutorialPickupTarget")
        if anchor ~= nil and anchor:IsA("BasePart") then depotTarget = anchor end
    end
    task.spawn(function()
        local runtime = workspace:WaitForChild("TutorialRuntime", 20)
        local anchor = runtime and runtime:WaitForChild("TutorialPickupTarget", 10)
        if anchor ~= nil and anchor:IsA("BasePart") then depotTarget = anchor end
    end)

    local function refreshMuseumTarget()
        museumTarget = nil
        museumModel = nil
        local plotId = player:GetAttribute("AssignedPlotId")
        local cloneId = player:GetAttribute("MuseumCloneId")
        if type(plotId) ~= "string" or type(cloneId) ~= "string" then return end
        local map = workspace:FindFirstChild("Map")
        local owned = map and map:FindFirstChild("OwnedMuseums")
        local museum = owned and owned:FindFirstChild("Museum_" .. plotId)
        if museum == nil or museum:GetAttribute("CloneId") ~= cloneId
            or museum:GetAttribute("OwnerUserId") ~= player.UserId then return end
        local target = museum:FindFirstChild("ReceivingZone", true)
        if target ~= nil and target:IsA("BasePart") then
            museumTarget = target
            museumModel = museum
        end
    end
    player:GetAttributeChangedSignal("AssignedPlotId"):Connect(refreshMuseumTarget)
    player:GetAttributeChangedSignal("MuseumCloneId"):Connect(refreshMuseumTarget)
    task.defer(refreshMuseumTarget)

    local function getEscapeWaypoint(): BasePart?
        if escapeWaypoint ~= nil and escapeWaypoint.Parent ~= nil then return escapeWaypoint end
        if museumModel == nil then return nil end
        local map = workspace:FindFirstChild("Map")
        local expansion = map and map:FindFirstChild("ExpansionDistrict")
        local depot = expansion and expansion:FindFirstChild("Depot")
        local platform = depot and depot:FindFirstChild("Platform")
        if platform == nil or not platform:IsA("BasePart")
            or museumModel:GetPivot().Position.Z <= platform.Position.Z then return nil end
        local side = if museumModel:GetPivot().Position.X < platform.Position.X then -1 else 1
        local point = Instance.new("Part")
        point.Name = "LocalTutorialDepotExit"
        point.Size = Vector3.new(0.2, 0.2, 0.2)
        point.Position = platform.Position + Vector3.new(
            side * (platform.Size.X / 2 + 15), 3, platform.Size.Z / 2 + 5)
        point.Transparency = 1
        point.Anchored = true
        point.CanCollide = false
        point.CanQuery = false
        point.CanTouch = false
        point.Parent = workspace
        escapeWaypoint = point
        return point
    end
    local function getDepartureWaypoint(exit: BasePart): BasePart?
        if departureWaypoint ~= nil and departureWaypoint.Parent ~= nil then
            return departureWaypoint
        end
        if depotTarget == nil then return nil end
        local point = Instance.new("Part")
        point.Name = "LocalTutorialSideLane"
        point.Size = Vector3.new(0.2, 0.2, 0.2)
        point.Position = Vector3.new(exit.Position.X, exit.Position.Y,
            depotTarget.Position.Z + 2)
        point.Transparency = 1
        point.Anchored = true
        point.CanCollide = false
        point.CanQuery = false
        point.CanTouch = false
        point.Parent = workspace
        departureWaypoint = point
        return point
    end
    screen.Destroying:Connect(function()
        if departureWaypoint then departureWaypoint:Destroy() end
        if escapeWaypoint then escapeWaypoint:Destroy() end
    end)

    local previousStep: number? = nil
    local celebrationUntil = 0
    local replayCompletedUntil = 0
    local replayWatchUntil = 0
    local replayCashAtStart = 0
    player:GetAttributeChangedSignal("TutorialReplayCompleted"):Connect(function()
        replayCashAtStart = player:GetAttribute("Cash") or 0
        replayWatchUntil = os.clock() + 30
        replayCompletedUntil = 0
    end)
    player:GetAttributeChangedSignal("TutorialStep"):Connect(function()
        local current = player:GetAttribute("TutorialStep")
        if (previousStep == 0 and current == 1)
            or (previousStep == 1 and current == 2) then
            celebrationUntil = os.clock() + 16
        end
        if type(current) == "number" then previousStep = current end
    end)
    local initial = player:GetAttribute("TutorialStep")
    if type(initial) == "number" then previousStep = initial end

    local activePickupPrompt: ProximityPrompt? = nil
    ProximityPromptService.PromptShown:Connect(function(shownPrompt)
        if shownPrompt:GetAttribute("PickupTargetId") == "depot.tutorial_pedestal" then
            activePickupPrompt = shownPrompt
        end
    end)
    ProximityPromptService.PromptHidden:Connect(function(hiddenPrompt)
        if hiddenPrompt == activePickupPrompt then activePickupPrompt = nil end
    end)

    local function interactName(): string
        local input = UserInputService:GetLastInputType()
        if PhoneHudLayout.IsPhone(screen) or input == Enum.UserInputType.Touch then return "TAP" end
        if string.find(input.Name, "Gamepad") then return "X" end
        return "E"
    end

    local function deliverName(): string
        local input = UserInputService:GetLastInputType()
        if input == Enum.UserInputType.Touch then return "DELIVER" end
        if string.find(input.Name, "Gamepad") then return "B" end
        return "G"
    end

    RunService.RenderStepped:Connect(function()
        local phone = PhoneHudLayout.IsPhone(screen)
        local layout = if phone then PhoneHudLayout.Calculate(screen.AbsoluteSize) else nil
        if layout then
            ride.AnchorPoint = Vector2.zero
            ride.Size = UDim2.fromOffset(math.min(210, layout.carry.w), 48)
            ride.Position = if layout.landscape
                then UDim2.fromOffset(layout.carry.x, layout.carry.y + layout.carry.h + 5)
                else UDim2.fromOffset(math.floor((screen.AbsoluteSize.X - 210) / 2),
                    layout.guide.y + layout.guide.h + 8)
        else
            ride.AnchorPoint = Vector2.new(.5, 1)
            ride.Position = UDim2.new(.5, 0, 1, -92)
        end
        local notice = screen:FindFirstChild("Notification")
        local noticeVisible = phone and notice ~= nil and notice:IsA("GuiObject") and notice.Visible
        if phone then
            local guide = PhoneHudLayout.Calculate(screen.AbsoluteSize).guide
            PhoneHudLayout.Apply(panel, guide)
            arrow.Position = UDim2.fromOffset(6, 11)
            arrow.Size = UDim2.fromOffset(45, 48)
            arrow.TextSize = 37
            step.Position = UDim2.fromOffset(58, 3)
            step.Size = UDim2.new(1, -64, 0, 17)
            step.TextSize = 11
            instruction.Position = UDim2.fromOffset(58, 22)
            instruction.Size = UDim2.new(1, -64, 0, 27)
            instruction.TextSize = 14
            distance.Position = UDim2.fromOffset(58, 49)
            distance.Size = UDim2.new(1, -64, 0, 16)
            distance.TextSize = 11
        else
            -- Keep the guide beside the action on desktop instead of covering
            -- the character in the middle of a short laptop viewport.
            panel.AnchorPoint = Vector2.zero
            panel.Size = UDim2.fromOffset(390, 92)
            panel.Position = UDim2.fromOffset(28, 30)
            arrow.Position = UDim2.fromOffset(9, 14)
            arrow.Size = UDim2.fromOffset(54, 62)
            arrow.TextSize = 45
            step.Position = UDim2.fromOffset(70, 8)
            step.Size = UDim2.new(1, -78, 0, 19)
            step.TextSize = 12
            instruction.Position = UDim2.fromOffset(70, 29)
            instruction.Size = UDim2.new(1, -78, 0, 30)
            instruction.TextSize = 15
            distance.Position = UDim2.fromOffset(70, 63)
            distance.Size = UDim2.new(1, -78, 0, 20)
            distance.TextSize = 12
        end

        if player:GetAttribute("ProfileState") ~= "Ready"
            or player:GetAttribute("PlotState") ~= "Ready" then
            panel.Visible = false
            marker.Enabled = false
            ride.Visible = false
            return
        end
        if museumModel == nil or museumModel.Parent == nil then refreshMuseumTarget() end
        local replaying = player:GetAttribute("TutorialReplayActive") == true
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local atMuseum = root ~= nil and root:IsA("BasePart") and museumModel ~= nil
            and (Vector3.new(root.Position.X, 0, root.Position.Z)
                - Vector3.new(museumModel:GetPivot().Position.X, 0,
                    museumModel:GetPivot().Position.Z)).Magnitude <= 60
        local tutorialStep = player:GetAttribute("TutorialStep")
        local firstRide = tutorialStep == 0 or replaying
        local repeatRide = tutorialStep == 2 and os.clock() < celebrationUntil
        ride.Visible = (firstRide or repeatRide)
            and player:GetAttribute("CarryId") == nil
            and atMuseum and os.clock() - rideRequestedAt >= 2
        ride.Text = if repeatRide then "STEAL AGAIN  >>" else "RIDE TO DEPOT  >>"
        if not replaying and replayWatchUntil > 0 then
            if (player:GetAttribute("Cash") or 0) > replayCashAtStart
                or os.clock() >= replayWatchUntil then
                replayWatchUntil = 0
                replayCompletedUntil = os.clock() + 12
            else
                panel.Visible = true
                marker.Enabled = false
                arrow.Rotation = 0
                arrow.Text = utf8.char(10003)
                step.Text = "EARN  /  FIRST REWARD"
                instruction.Text = "Your displayed exhibit earns cash."
                distance.Text = "Watch the first $1 appear."
                return
            end
        end
        if not replaying and os.clock() < replayCompletedUntil then
            panel.Visible = true
            marker.Enabled = false
            arrow.Rotation = 0
            arrow.Text = utf8.char(10003)
            step.Text = "TUTORIAL REPLAY COMPLETE"
            instruction.Text = "You delivered the practice toaster."
            distance.Text = "Your collection and rewards are unchanged."
            return
        end
        if not replaying and type(tutorialStep) == "number" and tutorialStep >= 1 then
            local show = tutorialStep == 1 or os.clock() < celebrationUntil
            panel.Visible = tutorialStep <= 2 and show and not noticeVisible
            marker.Enabled = false
            if tutorialStep <= 2 and show then
                arrow.Rotation = 0
                arrow.Text = utf8.char(10003)
                if tutorialStep == 1 then
                    step.Text = "EARN  /  YOUR MUSEUM IS WORKING"
                    instruction.Text = "Your toaster earns $6/min."
                    distance.Text = "First $1 arrives in about 10 seconds."
                else
                    step.Text = "FIRST HEIST COMPLETE"
                    instruction.Text = "Now steal public stock for your museum."
                    distance.Text = if ride.Visible then "Tap STEAL AGAIN for public stock."
                        else "Choose a new item at the depot."
                end
            end
            return
        end

        arrow.Text = utf8.char(9650)
        local carrying = player:GetAttribute("CarryId") ~= nil
        refreshDepotTarget()
        if museumTarget == nil or museumTarget.Parent == nil then refreshMuseumTarget() end
        local carryId = player:GetAttribute("CarryId")
        if carryId ~= guidedCarryId then
            guidedCarryId = carryId
            reachedSideLane = false
            escapedDepot = false
        end
        local exit = if carrying and not escapedDepot then getEscapeWaypoint() else nil
        local routeWaypoint: BasePart? = nil
        if exit ~= nil and root ~= nil and root:IsA("BasePart") then
            if root.Position.Z >= exit.Position.Z + 5 then
                reachedSideLane = true
                escapedDepot = true
            end
            local sideLane = getDepartureWaypoint(exit)
            if sideLane ~= nil and not reachedSideLane then
                if (Vector3.new(root.Position.X, 0, root.Position.Z)
                    - Vector3.new(sideLane.Position.X, 0, sideLane.Position.Z)).Magnitude <= 5
                    or math.abs(root.Position.X - exit.Position.X) <= 5 then
                    reachedSideLane = true
                else
                    routeWaypoint = sideLane
                end
            end
            local platformZ = exit.Position.Z - 40
            if reachedSideLane and not escapedDepot then
                if (Vector3.new(root.Position.X, 0, root.Position.Z)
                    - Vector3.new(exit.Position.X, 0, exit.Position.Z)).Magnitude <= 14
                    or root.Position.Z >= platformZ + 45 then
                    escapedDepot = true
                else
                    routeWaypoint = exit
                end
            end
        end
        local target = if routeWaypoint ~= nil then routeWaypoint
            elseif carrying then museumTarget else depotTarget
        local hiddenForAction = phone and (noticeVisible
            or (not carrying and activePickupPrompt ~= nil)
            or (carrying and player:GetAttribute("AtDropOff") == true))
        panel.Visible = not hiddenForAction
        -- A short world sign confirms the destination without drawing through walls.
        marker.Enabled = target ~= nil and not hiddenForAction
        marker.Adornee = target
        markerText.Text = if routeWaypoint ~= nil and routeWaypoint == departureWaypoint then "CLEAR STOCK STANDS"
            elseif routeWaypoint ~= nil and routeWaypoint == exit then "EXIT DEPOT"
            elseif carrying then "▼ DISPLAY HERE" else "▼ STEAL HERE"
        step.Text = if carrying then "ESCAPE  /  DISPLAY IT" else "STEAL  /  YOUR FIRST ITEM"
        if target == nil then
            instruction.Text = "Finding your route..."
            distance.Text = ""
            return
        end
        local character = player.Character
        root = character and character:FindFirstChild("HumanoidRootPart")
        local camera = workspace.CurrentCamera
        if root == nil or not root:IsA("BasePart") or camera == nil then return end

        local toTarget = Vector3.new(target.Position.X - root.Position.X, 0,
            target.Position.Z - root.Position.Z)
        local studs = math.floor(toTarget.Magnitude + 0.5)
        local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
        local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)
        if toTarget.Magnitude > 0.01 and forward.Magnitude > 0.01 and right.Magnitude > 0.01 then
            local direction = toTarget.Unit
            arrow.Rotation = math.deg(math.atan2(direction:Dot(right.Unit), direction:Dot(forward.Unit)))
        end
        distance.Text = tostring(studs) .. " STUDS TO " .. (if routeWaypoint ~= nil and routeWaypoint == departureWaypoint then "SIDE LANE"
            elseif routeWaypoint ~= nil and routeWaypoint == exit then "DEPOT EXIT"
            elseif carrying then "GREEN DROP-OFF CARPET" else "TOASTER")
        if carrying then
            instruction.Text = if player:GetAttribute("AtDropOff") == true
                then (if phone then "Stand here to deliver the toaster."
                    else "Press " .. deliverName() .. " to deliver the toaster.")
                elseif routeWaypoint ~= nil then "Go around the stock stands, then head home."
                else "Follow the arrow. Stand on green to display."
        else
            instruction.Text = if studs <= 12
                then "Hold " .. interactName() .. " to take the toaster."
                else (if ride.Visible then "Tap RIDE to start your heist." else "Follow the arrow to the depot.")
        end
    end)
end

return table.freeze(TutorialGuideController)
