--!strict

local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhoneHudLayout = require(script.Parent.PhoneHudLayout)

local Theme = require(script.Parent.HudTheme)
local ACCENT = Theme.Text
local PROGRESS = Theme.Accent
local MUTED = Theme.Muted
local PANEL = Theme.Ink

local InteractionHud = {}

local function inputName(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType?): string
    if inputType == Enum.ProximityPromptInputType.Touch then
        return "TAP"
    end
    if inputType == Enum.ProximityPromptInputType.Gamepad then
        return prompt.GamepadKeyCode.Name
    end
    return prompt.KeyboardKeyCode.Name
end

function InteractionHud.Create(parent: ScreenGui, player: Player)
    local root = Instance.new("Frame")
    root.Name = "InteractionPrompt"
    root.AnchorPoint = Vector2.new(0.5, 1)
    root.Position = UDim2.new(0.5, 0, 1, -32)
    root.Size = UDim2.fromOffset(280, 76)
    root.BackgroundColor3 = PANEL
    root.BackgroundTransparency = 0.2
    root.BorderSizePixel = 0
    root.Visible = false
    root.Parent = parent

    local rootCorner = Instance.new("UICorner")
    rootCorner.CornerRadius = UDim.new(0, 7)
    rootCorner.Parent = root

    local rootOutline = Instance.new("UIStroke")
    rootOutline.Color = Theme.Outline
    rootOutline.Thickness = 1
    rootOutline.Transparency = 0.45
    rootOutline.Parent = root

    local keyButton = Instance.new("TextButton")
    keyButton.Name = "Key"
    keyButton.Position = UDim2.fromOffset(10, 7)
    keyButton.Size = UDim2.fromOffset(50, 50)
    keyButton.BackgroundColor3 = Theme.Accent
    keyButton.BackgroundTransparency = 0
    keyButton.BorderSizePixel = 0
    keyButton.Font = Enum.Font.GothamBold
    keyButton.Text = "E"
    keyButton.TextColor3 = Theme.Ink
    keyButton.TextSize = 24
    keyButton.AutoButtonColor = true
    keyButton.Selectable = true
    keyButton.Parent = root

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(1, 0)
    keyCorner.Parent = keyButton

    local keyOutline = Instance.new("UIStroke")
    keyOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    keyOutline.Color = PROGRESS
    keyOutline.Thickness = 3
    keyOutline.Transparency = 0
    keyOutline.Parent = keyButton

    local collapseButton = Instance.new("TextButton")
    collapseButton.Name = "Collapse"
    collapseButton.AnchorPoint = Vector2.new(1, 0)
    collapseButton.Position = UDim2.new(1, -7, 0, 7)
    collapseButton.Size = UDim2.fromOffset(28, 24)
    collapseButton.BackgroundColor3 = Color3.fromRGB(24, 38, 33)
    collapseButton.BackgroundTransparency = 0.05
    collapseButton.BorderSizePixel = 0
    collapseButton.Font = Enum.Font.GothamBold
    collapseButton.Text = "v"
    collapseButton.TextColor3 = PROGRESS
    collapseButton.TextSize = 14
    collapseButton.AutoButtonColor = true
    collapseButton.Selectable = true
    collapseButton.Parent = root

    local collapseCorner = Instance.new("UICorner")
    collapseCorner.CornerRadius = UDim.new(0, 4)
    collapseCorner.Parent = collapseButton

    local holdText = Instance.new("TextLabel")
    holdText.Name = "Hold"
    holdText.Position = UDim2.fromOffset(8, 59)
    holdText.Size = UDim2.fromOffset(54, 14)
    holdText.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    holdText.BackgroundTransparency = 0.25
    holdText.Font = Enum.Font.GothamBold
    holdText.Text = "HOLD"
    holdText.TextColor3 = ACCENT
    holdText.TextSize = 10
    holdText.Parent = root

    local action = Instance.new("TextLabel")
    action.Name = "Action"
    action.Position = UDim2.fromOffset(75, 8)
    action.Size = UDim2.new(1, -118, 0, 24)
    action.BackgroundTransparency = 1
    action.Font = Enum.Font.GothamBold
    action.Text = "PICK UP"
    action.TextColor3 = ACCENT
    action.TextSize = 16
    action.TextXAlignment = Enum.TextXAlignment.Left
    action.TextTruncate = Enum.TextTruncate.AtEnd
    action.Parent = root

    local object = Instance.new("TextLabel")
    object.Name = "Object"
    object.Position = UDim2.fromOffset(75, 31)
    object.Size = UDim2.new(1, -85, 0, 20)
    object.BackgroundTransparency = 1
    object.Font = Enum.Font.GothamBold
    object.Text = "Dramatic Toaster  /  Preview"
    object.TextColor3 = Color3.fromRGB(214, 224, 217)
    object.TextSize = 12
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.TextTruncate = Enum.TextTruncate.AtEnd
    object.Parent = root

    local progressTrack = Instance.new("Frame")
    progressTrack.Name = "ProgressTrack"
    progressTrack.Position = UDim2.fromOffset(75, 58)
    progressTrack.Size = UDim2.new(1, -85, 0, 6)
    progressTrack.BackgroundColor3 = Color3.fromRGB(65, 73, 68)
    progressTrack.BackgroundTransparency = 0.2
    progressTrack.BorderSizePixel = 0
    progressTrack.Parent = root

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = progressTrack

    local progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.fromScale(0.42, 1)
    progressFill.BackgroundColor3 = PROGRESS
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressTrack

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = progressFill

    local collapsedButton = Instance.new("TextButton")
    collapsedButton.Name = "InteractionPromptCollapsed"
    collapsedButton.AnchorPoint = Vector2.new(0.5, 1)
    collapsedButton.Position = UDim2.new(0.5, 0, 1, -32)
    collapsedButton.Size = UDim2.fromOffset(196, 38)
    collapsedButton.BackgroundColor3 = PANEL
    collapsedButton.BackgroundTransparency = 0.05
    collapsedButton.BorderSizePixel = 0
    collapsedButton.Font = Enum.Font.GothamBold
    collapsedButton.RichText = true
    collapsedButton.Text = "HOLD  <font color=\"#4AEBc2\">[ E ]</font>  TO INTERACT"
    collapsedButton.TextColor3 = Theme.Accent
    collapsedButton.TextSize = 11
    collapsedButton.AutoButtonColor = false
    collapsedButton.Selectable = false
    collapsedButton.Visible = true
    collapsedButton.Parent = parent

    local collapsedCorner = Instance.new("UICorner")
    collapsedCorner.CornerRadius = UDim.new(0, 6)
    collapsedCorner.Parent = collapsedButton

    local collapsedOutline = Instance.new("UIStroke")
    collapsedOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    collapsedOutline.Color = PROGRESS
    collapsedOutline.Thickness = 2
    collapsedOutline.Transparency = 0
    collapsedOutline.Parent = collapsedButton

    local function updateLayout()
        if PhoneHudLayout.IsPhone(parent) then
            local rect = PhoneHudLayout.Calculate(parent.AbsoluteSize).prompt
            PhoneHudLayout.Apply(root, rect)
            keyButton.Position = UDim2.fromOffset(8, 7)
            keyButton.Size = UDim2.fromOffset(44, 44)
            keyButton.TextSize = 17
            holdText.Position = UDim2.fromOffset(8, 54)
            holdText.Size = UDim2.fromOffset(44, 12)
            holdText.TextSize = 11
            action.Position = UDim2.fromOffset(62, 6)
            action.Size = UDim2.new(1, -97, 0, 22)
            action.TextSize = 14
            object.Position = UDim2.fromOffset(62, 28)
            object.Size = UDim2.new(1, -72, 0, 18)
            object.TextSize = 12
            progressTrack.Position = UDim2.fromOffset(62, 54)
            progressTrack.Size = UDim2.new(1, -72, 0, 5)
            collapsedButton.AnchorPoint = Vector2.zero
            collapsedButton.Position = UDim2.fromOffset(rect.x + math.floor((rect.w - 180) / 2), rect.y + 18)
            collapsedButton.Size = UDim2.fromOffset(180, 34)
        else
            root.AnchorPoint = Vector2.new(0.5, 1)
            root.Position = UDim2.new(0.5, 0, 1, -32)
            root.Size = UDim2.fromOffset(280, 76)
            keyButton.Position = UDim2.fromOffset(10, 7)
            keyButton.Size = UDim2.fromOffset(50, 50)
            keyButton.TextSize = 24
            holdText.TextSize = 10
            holdText.Position = UDim2.fromOffset(8, 59)
            holdText.Size = UDim2.fromOffset(54, 14)
            action.Position = UDim2.fromOffset(75, 8)
            action.Size = UDim2.new(1, -118, 0, 24)
            action.TextSize = 16
            object.Position = UDim2.fromOffset(75, 31)
            object.Size = UDim2.new(1, -85, 0, 20)
            object.TextSize = 12
            progressTrack.Position = UDim2.fromOffset(75, 58)
            progressTrack.Size = UDim2.new(1, -85, 0, 6)
            collapsedButton.AnchorPoint = Vector2.new(0.5, 1)
            collapsedButton.Position = UDim2.new(0.5, 0, 1, -32)
            collapsedButton.Size = UDim2.fromOffset(196, 38)
        end
    end
    parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
    updateLayout()

    local currentPrompt: ProximityPrompt? = nil
    local currentRemoteAction: string? = nil
    local holdStarted: number? = nil
    local lastInputType: Enum.ProximityPromptInputType? = nil
    local networkFolder = ReplicatedStorage:WaitForChild("Network", 10)
    local beginPickup = if networkFolder ~= nil then networkFolder:FindFirstChild("BeginPickup") else nil
    local cancelPickup = if networkFolder ~= nil then networkFolder:FindFirstChild("CancelPickup") else nil
    local pickupRequestId: string? = nil
    local pickupPrompt: ProximityPrompt? = nil
    local pickupTriggered = false
    local seatedOnBench = false
    local activeHumanoid: Humanoid? = nil
    local standPrompt: ProximityPrompt? = nil
    local standSeat: Seat? = nil

    local function cancelUnfinishedPickup()
        local requestId = pickupRequestId
        if requestId == nil then return end
        task.delay(0.15, function()
            if pickupRequestId == requestId and not pickupTriggered then
                pickupRequestId = nil
                if cancelPickup ~= nil and cancelPickup:IsA("RemoteEvent") then
                    cancelPickup:FireServer(requestId)
                end
            end
        end)
    end
    local function showPreview()
        currentPrompt = nil
        currentRemoteAction = nil
        holdStarted = nil
        root.Visible = false
        collapsedButton.Visible = false
        keyButton.Text = "E"
        holdText.Text = "HOLD"
        action.Text = "PICK UP"
        object.Text = "Dramatic Toaster  /  Preview"
        progressFill.Size = UDim2.fromScale(0.42, 1)
    end

    ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
        if prompt:GetAttribute("Task11SitPrompt") == true
            or prompt:GetAttribute("Task11StandPrompt") == true
            or prompt:GetAttribute("DefaultPromptStyle") == true then return end
        if seatedOnBench then return end
        prompt.Style = Enum.ProximityPromptStyle.Custom
        currentPrompt = prompt
        currentRemoteAction = nil
        lastInputType = inputType
        holdStarted = nil
        root.Visible = true
        collapsedButton.Visible = false
        keyButton.Text = if PhoneHudLayout.IsPhone(parent) then "TAP" else inputName(prompt, inputType)
        collapsedButton.Text = if PhoneHudLayout.IsPhone(parent)
            then "HOLD  <font color=\"#4AEBc2\">[ TAP ]</font>  TO INTERACT"
            else "HOLD  <font color=\"#4AEBc2\">[ " .. inputName(prompt, inputType) .. " ]</font>  TO INTERACT"
        holdText.Text = if prompt.HoldDuration > 0 then "HOLD" else "PRESS"
        action.Text = string.upper(if prompt.ActionText ~= "" then prompt.ActionText else "INTERACT")
        object.Text = if prompt.ObjectText ~= "" then prompt.ObjectText else ""
        progressFill.Size = UDim2.fromScale(if prompt.HoldDuration > 0 then 0 else 1, 1)
    end)

    ProximityPromptService.PromptHidden:Connect(function(prompt)
        if prompt == currentPrompt then
            cancelUnfinishedPickup()
            showPreview()
        end
    end)

    ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
        if prompt == currentPrompt then
            holdStarted = os.clock()
            local targetId = prompt:GetAttribute("PickupTargetId")
            if type(targetId) == "string" and beginPickup ~= nil and beginPickup:IsA("RemoteEvent") then
                if pickupRequestId ~= nil and cancelPickup ~= nil and cancelPickup:IsA("RemoteEvent") then
                    cancelPickup:FireServer(pickupRequestId)
                end
                pickupPrompt = prompt
                pickupTriggered = false
                pickupRequestId = HttpService:GenerateGUID(false)
                beginPickup:FireServer(targetId, pickupRequestId)
            end
        end
    end)

    ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
        if prompt == currentPrompt then
            holdStarted = nil
            progressFill.Size = UDim2.fromScale(0, 1)
        end
        if prompt == pickupPrompt then cancelUnfinishedPickup() end
    end)

    ProximityPromptService.PromptTriggered:Connect(function(prompt)
        if prompt == pickupPrompt then
            pickupTriggered = true
            pickupRequestId = nil
        end
    end)

    keyButton.InputBegan:Connect(function(input)
        if currentPrompt ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            currentPrompt:InputHoldBegin()
        end
    end)

    local promptSync = if networkFolder ~= nil then networkFolder:FindFirstChild("PromptSync") else nil

    local function triggerRemoteAction()
        local actionName = currentRemoteAction
        if actionName == nil or actionName == "" then return end
        local event = if networkFolder ~= nil then networkFolder:FindFirstChild(actionName) else nil
        if event ~= nil and event:IsA("RemoteEvent") then
            event:FireServer()
        end
    end

    if promptSync ~= nil and promptSync:IsA("RemoteEvent") then promptSync.OnClientEvent:Connect(function(prompt)
        if seatedOnBench then
            showPreview()
            return
        end
        if type(prompt) ~= "table" or prompt.visible == false then
            showPreview()
            return
        end

        currentPrompt = nil
        currentRemoteAction = if type(prompt.action) == "string" then prompt.action else "BeginPickup"
        holdStarted = nil
        root.Visible = true
        collapsedButton.Visible = false
        keyButton.Text = if PhoneHudLayout.IsPhone(parent) then "TAP" else "E"
        collapsedButton.Text = if PhoneHudLayout.IsPhone(parent)
            then "<font color=\"#4AEBc2\">[ TAP ]</font>  TO INTERACT"
            else "<font color=\"#4AEBc2\">[ E ]</font>  TO INTERACT"
        holdText.Text = "PRESS"
        action.Text = string.upper(if type(prompt.text) == "string" then prompt.text else "INTERACT")
        object.Text = if type(prompt.objectText) == "string" then prompt.objectText else ""
        progressFill.Size = UDim2.fromScale(1, 1)
    end) end

    keyButton.Activated:Connect(triggerRemoteAction)

    local function standFromBench()
        local humanoid = activeHumanoid
        if not seatedOnBench or humanoid == nil then return end
        humanoid.Sit = false
        humanoid.Jump = true
    end

    local seatConnection: RBXScriptConnection? = nil
    local sitConnection: RBXScriptConnection? = nil
    local function refreshBenchSeat()
        local humanoid = activeHumanoid
        local seat = if humanoid then humanoid.SeatPart else nil
        local isBench = humanoid ~= nil and humanoid.Sit and seat ~= nil
            and seat:GetAttribute("Task11SitOnly") == true
        local nextSeat = if isBench and seat ~= nil and seat:IsA("Seat") then seat else nil
        if isBench == seatedOnBench and nextSeat == standSeat then return end
        if standPrompt then standPrompt:Destroy() end
        standPrompt = nil
        standSeat = nextSeat
        seatedOnBench = isBench
        showPreview()
        if nextSeat then
            local prompt = Instance.new("ProximityPrompt")
            prompt.Name = "StandPrompt"
            prompt.ActionText, prompt.ObjectText = "Stand", "Bench"
            prompt.KeyboardKeyCode = Enum.KeyCode.G
            prompt.GamepadKeyCode = Enum.KeyCode.ButtonB
            prompt.MaxActivationDistance = 7
            prompt.HoldDuration = 0
            prompt.RequiresLineOfSight = false
            prompt.Style = Enum.ProximityPromptStyle.Default
            prompt:SetAttribute("Task11StandPrompt", true)
            prompt.Triggered:Connect(standFromBench)
            prompt.Parent = nextSeat
            standPrompt = prompt
        end
    end
    local function attachCharacter(character: Model)
        if seatConnection then seatConnection:Disconnect() end
        if sitConnection then sitConnection:Disconnect() end
        if standPrompt then standPrompt:Destroy() end
        standPrompt, standSeat = nil, nil
        seatedOnBench = false
        activeHumanoid = character:WaitForChild("Humanoid") :: Humanoid
        seatConnection = activeHumanoid:GetPropertyChangedSignal("SeatPart"):Connect(refreshBenchSeat)
        sitConnection = activeHumanoid:GetPropertyChangedSignal("Sit"):Connect(refreshBenchSeat)
        refreshBenchSeat()
    end
    ContextActionService:BindAction("StealAnythingInteract", function(_, inputState)
        if inputState == Enum.UserInputState.Begin and currentRemoteAction ~= nil then
            triggerRemoteAction()
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonX)

    collapseButton.Activated:Connect(function()
        root.Visible = false
        collapsedButton.Visible = true
    end)

    keyButton.InputEnded:Connect(function(input)
        if currentPrompt ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            currentPrompt:InputHoldEnd()
        end
    end)

    RunService.RenderStepped:Connect(function()
        local prompt = currentPrompt
        local started = holdStarted
        if prompt ~= nil and started ~= nil then
            local duration = math.max(prompt.HoldDuration, 0.01)
            progressFill.Size = UDim2.fromScale(math.clamp((os.clock() - started) / duration, 0, 1), 1)
        elseif prompt ~= nil and (PhoneHudLayout.IsPhone(parent)
            or lastInputType == Enum.ProximityPromptInputType.Touch) then
            keyButton.Text = "TAP"
        end
    end)

    showPreview()
    player.CharacterAdded:Connect(attachCharacter)
    if player.Character then task.spawn(attachCharacter, player.Character) end
end

return table.freeze(InteractionHud)
