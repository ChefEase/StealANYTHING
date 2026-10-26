--!strict

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PhoneHudLayout = require(script.Parent.PhoneHudLayout)
local Theme = require(script.Parent.HudTheme)

local ACTION = "StealAnythingDeliverCarry"
local HOLD_SECONDS = 0.5

local CarryInputController = {}

function CarryInputController.Start(player: Player, screen: ScreenGui)
    local network = ReplicatedStorage:WaitForChild("Network")
    local deliverRemote = network:WaitForChild("DeliverCarry") :: RemoteEvent
    local heldId: string? = nil
    local pressSerial = 0
    local bound = false
    local heldTouch: InputObject? = nil
    local touchSerial = 0
    local touchStarted = 0

    local panel = Instance.new("Frame")
    panel.Name = "TouchDelivery"
    panel.BackgroundColor3 = Theme.Ink
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 20
    panel.Parent = screen
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = panel
    local outline = Instance.new("UIStroke")
    outline.Color = Theme.Outline
    outline.Thickness = 2
    outline.Parent = panel

    local button = Instance.new("TextButton")
    button.Name = "HoldToDeliver"
    button.Size = UDim2.fromScale(1, 1)
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.Active = true
    button.AutoButtonColor = true
    button.Text = ""
    button.ZIndex = 21
    button.Parent = panel

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Position = UDim2.fromOffset(8, 7)
    title.Size = UDim2.new(1, -16, 0, 27)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "HOLD TO DELIVER"
    title.TextColor3 = Theme.Text
    title.TextSize = 17
    title.ZIndex = 22
    title.Parent = button

    local detail = Instance.new("TextLabel")
    detail.Name = "Detail"
    detail.Position = UDim2.fromOffset(8, 34)
    detail.Size = UDim2.new(1, -16, 0, 16)
    detail.BackgroundTransparency = 1
    detail.Font = Enum.Font.GothamMedium
    detail.Text = "AT MUSEUM DROP-OFF"
    detail.TextColor3 = Theme.Muted
    detail.TextSize = 10
    detail.ZIndex = 22
    detail.Parent = button

    local progressTrack = Instance.new("Frame")
    progressTrack.Name = "ProgressTrack"
    progressTrack.Position = UDim2.new(0, 9, 1, -6)
    progressTrack.Size = UDim2.new(1, -18, 0, 3)
    progressTrack.BackgroundColor3 = Color3.fromRGB(43, 96, 78)
    progressTrack.BorderSizePixel = 0
    progressTrack.ZIndex = 22
    progressTrack.Parent = button
    local progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.fromScale(0, 1)
    progressFill.BackgroundColor3 = Theme.Accent
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 23
    progressFill.Parent = progressTrack

    local function deliverableId(): string?
        local currentId = player:GetAttribute("CarryId")
        if type(currentId) == "string" and currentId ~= ""
            and player:GetAttribute("AtDropOff") == true
            and player:GetAttribute("DeliveryInProgress") ~= true then
            return currentId
        end
        return nil
    end

    local function cancelTouch()
        heldTouch = nil
        touchSerial += 1
        progressFill.Size = UDim2.fromScale(0, 1)
    end

    local function onAction(_: string, inputState: Enum.UserInputState): Enum.ContextActionResult
        if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
            local hadHold = heldId ~= nil
            heldId = nil
            pressSerial += 1
            return if hadHold then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
        end
        local currentId = deliverableId()
        if currentId == nil then return Enum.ContextActionResult.Pass end
        if inputState == Enum.UserInputState.Begin then
            pressSerial += 1
            local serial = pressSerial
            heldId = currentId
            task.delay(HOLD_SECONDS, function()
                if pressSerial == serial and heldId == currentId
                    and deliverableId() == currentId then
                    heldId = nil
                    deliverRemote:FireServer(currentId)
                end
            end)
        end
        return Enum.ContextActionResult.Sink
    end

    local function updateLayout()
        if PhoneHudLayout.IsPhone(screen) then
            PhoneHudLayout.Apply(panel, PhoneHudLayout.Calculate(screen.AbsoluteSize).deliver)
        end
    end

    local function refresh()
        local currentId = player:GetAttribute("CarryId")
        local carrying = type(currentId) == "string" and currentId ~= ""
        if carrying and not bound then
            bound = true
            ContextActionService:BindAction(ACTION, onAction, false, Enum.KeyCode.G, Enum.KeyCode.ButtonB)
        elseif not carrying and bound then
            bound = false
            heldId = nil
            pressSerial += 1
            ContextActionService:UnbindAction(ACTION)
        end
        local show = PhoneHudLayout.IsPhone(screen) and deliverableId() ~= nil
        panel.Visible = show
        if not show then cancelTouch() end
        updateLayout()
    end

    button.InputBegan:Connect(function(input)
        if not panel.Visible or heldTouch ~= nil then return end
        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local currentId = deliverableId()
        if currentId == nil then return end
        heldTouch = input
        touchSerial += 1
        local serial = touchSerial
        touchStarted = os.clock()
        task.delay(HOLD_SECONDS, function()
            if touchSerial == serial and heldTouch == input
                and panel.Visible and deliverableId() == currentId then
                cancelTouch()
                deliverRemote:FireServer(currentId)
            end
        end)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == heldTouch then cancelTouch() end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input ~= heldTouch or input.UserInputType ~= Enum.UserInputType.Touch then return end
        local position = input.Position
        local topLeft = button.AbsolutePosition
        local size = button.AbsoluteSize
        if position.X < topLeft.X or position.X > topLeft.X + size.X
            or position.Y < topLeft.Y or position.Y > topLeft.Y + size.Y then
            cancelTouch()
        end
    end)
    RunService.RenderStepped:Connect(function()
        if heldTouch ~= nil then
            progressFill.Size = UDim2.fromScale(
                math.clamp((os.clock() - touchStarted) / HOLD_SECONDS, 0, 1), 1)
        end
    end)

    player:GetAttributeChangedSignal("CarryId"):Connect(refresh)
    player:GetAttributeChangedSignal("AtDropOff"):Connect(refresh)
    player:GetAttributeChangedSignal("DeliveryInProgress"):Connect(refresh)
    screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)
    refresh()
end

return table.freeze(CarryInputController)
