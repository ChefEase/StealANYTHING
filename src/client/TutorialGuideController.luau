--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
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

    local marker = Instance.new("BillboardGui")
    marker.Name = "TutorialWorldMarker"
    marker.Size = UDim2.fromOffset(176, 42)
    marker.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
    marker.AlwaysOnTop = true
    marker.MaxDistance = 500
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
    task.spawn(function()
        local runtime = workspace:WaitForChild("TutorialRuntime", 20)
        local anchor = runtime and runtime:WaitForChild("TutorialPickupTarget", 10)
        if anchor ~= nil and anchor:IsA("BasePart") then depotTarget = anchor end
    end)

    local function refreshMuseumTarget()
        museumTarget = nil
        local plotId = player:GetAttribute("AssignedPlotId")
        local cloneId = player:GetAttribute("MuseumCloneId")
        if type(plotId) ~= "string" or type(cloneId) ~= "string" then return end
        local map = workspace:FindFirstChild("Map")
        local owned = map and map:FindFirstChild("OwnedMuseums")
        local museum = owned and owned:FindFirstChild("Museum_" .. plotId)
        if museum == nil or museum:GetAttribute("CloneId") ~= cloneId
            or museum:GetAttribute("OwnerUserId") ~= player.UserId then return end
        local target = museum:FindFirstChild("ProtectedDisplaySocket", true)
        if target ~= nil and target:IsA("BasePart") then museumTarget = target end
    end
    player:GetAttributeChangedSignal("AssignedPlotId"):Connect(refreshMuseumTarget)
    player:GetAttributeChangedSignal("MuseumCloneId"):Connect(refreshMuseumTarget)
    task.defer(refreshMuseumTarget)

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
            return
        end
        local replaying = player:GetAttribute("TutorialReplayActive") == true
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
                step.Text = "TUTORIAL 3/3  -  WATCH YOUR REWARD"
                instruction.Text = "Your saved exhibits keep earning."
                distance.Text = "Watch your cash increase."
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
        local tutorialStep = player:GetAttribute("TutorialStep")
        if not replaying and type(tutorialStep) == "number" and tutorialStep >= 1 then
            local show = tutorialStep == 1 or os.clock() < celebrationUntil
            panel.Visible = tutorialStep <= 2 and show and not noticeVisible
            marker.Enabled = false
            if tutorialStep <= 2 and show then
                arrow.Rotation = 0
                arrow.Text = utf8.char(10003)
                if tutorialStep == 1 then
                    step.Text = "TUTORIAL 3/3  -  WATCH YOUR REWARD"
                    instruction.Text = "Your toaster earns while you play."
                    distance.Text = "Watch your cash rise by $1."
                else
                    step.Text = "FIRST HEIST COMPLETE"
                    instruction.Text = "Next: a public depot heist."
                    distance.Text = "Public stock opens in a later build."
                end
            end
            return
        end

        arrow.Text = utf8.char(9650)
        local carrying = player:GetAttribute("CarryId") ~= nil
        if museumTarget == nil or museumTarget.Parent == nil then refreshMuseumTarget() end
        local target = if carrying then museumTarget else depotTarget
        local hiddenForAction = phone and (noticeVisible
            or (not carrying and activePickupPrompt ~= nil)
            or (carrying and player:GetAttribute("AtDropOff") == true))
        panel.Visible = not hiddenForAction
        -- The floating stand label obscures the route and duplicates the
        -- directional guide. Keep only the depot marker for the first pickup.
        marker.Enabled = not carrying and target ~= nil and not hiddenForAction
        marker.Adornee = target
        markerText.Text = "DEPOT: TUTORIAL TOASTER"
        step.Text = if carrying then "TUTORIAL 2/3  -  BRING IT HOME" else "TUTORIAL 1/3  -  YOUR FIRST PICKUP"
        if target == nil then
            instruction.Text = "Finding your route..."
            distance.Text = ""
            return
        end
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
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
        distance.Text = tostring(studs) .. " STUDS TO " .. (if carrying then "PROTECTED STAND" else "DEPOT")
        if carrying then
            instruction.Text = if player:GetAttribute("AtDropOff") == true
                then "Hold " .. deliverName() .. " to deliver the toaster."
                elseif phone then "Follow arrow to the exhibit stand."
                else "Follow the arrow to the exhibit stand."
        else
            instruction.Text = if studs <= 12
                then "Hold " .. interactName() .. " to take the toaster."
                else "Follow the arrow to the depot."
        end
    end)
end

return table.freeze(TutorialGuideController)
