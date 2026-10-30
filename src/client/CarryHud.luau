--!strict

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage.Shared.ItemCatalog)
local Balance = require(ReplicatedStorage.Shared.BalanceConfig)
local PhoneHudLayout = require(script.Parent.PhoneHudLayout)

local Theme = require(script.Parent.HudTheme)
local ACCENT = Theme.Accent
local WARM = Color3.fromRGB(255, 183, 71)
local TEXT = Theme.Text
local MUTED = Theme.Muted
local PANEL = Theme.Ink

local CarryHud = {}

local function newLabel(name: string, parent: Instance): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.TextColor3 = TEXT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

function CarryHud.Create(parent: ScreenGui, player: Player)
    local expanded = false
    local carrying = false
    local phoneLayout = false

    local panel = Instance.new("Frame")
    panel.Name = "CarryState"
    panel.AnchorPoint = Vector2.new(0, 1)
    panel.Position = UDim2.new(0, 28, 1, -34)
    panel.Size = UDim2.new(0.38, 0, 0, 130)
    panel.BackgroundColor3 = PANEL
    panel.BackgroundTransparency = 0.14
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = parent

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(285, 130)
    sizeConstraint.MaxSize = Vector2.new(370, 130)
    sizeConstraint.Parent = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = panel

    local outline = Instance.new("UIStroke")
    outline.Color = ACCENT
    outline.Thickness = 1
    outline.Transparency = 0.25
    outline.Parent = panel

    local accentBar = Instance.new("Frame")
    accentBar.Name = "Accent"
    accentBar.Size = UDim2.new(0, 4, 1, 0)
    accentBar.BackgroundColor3 = ACCENT
    accentBar.BorderSizePixel = 0
    accentBar.Parent = panel

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Position = UDim2.fromOffset(4, 0)
    header.Size = UDim2.new(1, -4, 0, 25)
    header.BackgroundColor3 = Color3.fromRGB(14, 30, 27)
    header.BackgroundTransparency = 0.12
    header.BorderSizePixel = 0
    header.Parent = panel

    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Position = UDim2.fromOffset(10, 9)
    statusDot.Size = UDim2.fromOffset(7, 7)
    statusDot.BackgroundColor3 = ACCENT
    statusDot.BorderSizePixel = 0
    statusDot.Parent = header

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = statusDot

    local carryingLabel = newLabel("State", header)
    carryingLabel.Position = UDim2.fromOffset(24, 0)
    carryingLabel.Size = UDim2.new(0.55, -24, 1, 0)
    carryingLabel.Font = Enum.Font.GothamBold
    carryingLabel.Text = "CARRYING"
    carryingLabel.TextColor3 = ACCENT
    carryingLabel.TextSize = 11

    local previewLabel = newLabel("Preview", header)
    previewLabel.AnchorPoint = Vector2.new(1, 0)
    previewLabel.Position = UDim2.new(1, -40, 0, 0)
    previewLabel.Size = UDim2.new(0.45, -31, 1, 0)
    previewLabel.Text = "LAYOUT PREVIEW"
    previewLabel.TextColor3 = MUTED
    previewLabel.TextSize = 10
    previewLabel.TextXAlignment = Enum.TextXAlignment.Right

    local collapseButton = Instance.new("TextButton")
    collapseButton.Name = "Collapse"
    collapseButton.AnchorPoint = Vector2.new(1, 0)
    collapseButton.Position = UDim2.new(1, 0, 0, 0)
    collapseButton.Size = UDim2.fromOffset(31, 25)
    collapseButton.BackgroundColor3 = Color3.fromRGB(26, 49, 43)
    collapseButton.BackgroundTransparency = 0.15
    collapseButton.BorderSizePixel = 0
    collapseButton.Font = Enum.Font.GothamBold
    collapseButton.Text = "v"
    collapseButton.TextColor3 = ACCENT
    collapseButton.TextSize = 15
    collapseButton.AutoButtonColor = true
    collapseButton.Selectable = true
    collapseButton.Parent = header

    local itemName = newLabel("ItemName", panel)
    itemName.Position = UDim2.fromOffset(15, 29)
    itemName.Size = UDim2.new(1, -125, 0, 26)
    itemName.Font = Enum.Font.GothamBold
    itemName.Text = "DRAMATIC TOASTER"
    itemName.TextSize = 17
    itemName.TextTruncate = Enum.TextTruncate.AtEnd

    local behavior = newLabel("Behavior", panel)
    behavior.AnchorPoint = Vector2.new(1, 0)
    behavior.Position = UDim2.new(1, -10, 0, 33)
    behavior.Size = UDim2.fromOffset(96, 19)
    behavior.BackgroundColor3 = WARM
    behavior.BackgroundTransparency = 0.08
    behavior.Font = Enum.Font.GothamBold
    behavior.Text = "NOISY"
    behavior.TextColor3 = Color3.fromRGB(25, 20, 10)
    behavior.TextSize = 10
    behavior.TextXAlignment = Enum.TextXAlignment.Center

    local behaviorCorner = Instance.new("UICorner")
    behaviorCorner.CornerRadius = UDim.new(0, 2)
    behaviorCorner.Parent = behavior

    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Position = UDim2.fromOffset(15, 99)
    divider.Size = UDim2.new(1, -30, 0, 1)
    divider.BackgroundColor3 = Color3.fromRGB(70, 91, 83)
    divider.BackgroundTransparency = 0.35
    divider.BorderSizePixel = 0
    divider.Parent = panel

    local itemDetails = newLabel("ItemDetails", panel)
    itemDetails.Position = UDim2.fromOffset(15, 57)
    itemDetails.Size = UDim2.new(1, -30, 0, 18)
    itemDetails.TextSize = 12
    itemDetails.TextColor3 = MUTED

    local incomeDetails = newLabel("IncomeDetails", panel)
    incomeDetails.Position = UDim2.fromOffset(15, 76)
    incomeDetails.Size = UDim2.new(1, -30, 0, 18)
    incomeDetails.TextSize = 12
    incomeDetails.TextColor3 = ACCENT

    local hint = newLabel("DropHint", panel)
    hint.Position = UDim2.fromOffset(15, 102)
    hint.Size = UDim2.new(1, -30, 0, 23)
    hint.Text = "[G]  HOLD AT STAND TO DELIVER"
    hint.TextColor3 = TEXT
    hint.TextSize = 12

    local collapsedButton = Instance.new("TextButton")
    collapsedButton.Name = "CarryStateCollapsed"
    collapsedButton.AnchorPoint = Vector2.new(0, 1)
    collapsedButton.Position = UDim2.new(0, 28, 1, -34)
    collapsedButton.Size = UDim2.fromOffset(52, 52)
    collapsedButton.BackgroundColor3 = PANEL
    collapsedButton.BackgroundTransparency = 0.08
    collapsedButton.BorderSizePixel = 0
    collapsedButton.Font = Enum.Font.GothamBold
    collapsedButton.Text = "CARRY\n+ INFO"
    collapsedButton.TextColor3 = ACCENT
    collapsedButton.TextSize = 10
    collapsedButton.AutoButtonColor = true
    collapsedButton.Selectable = true
    collapsedButton.Visible = false
    collapsedButton.Parent = parent

    local collapsedCorner = Instance.new("UICorner")
    collapsedCorner.CornerRadius = UDim.new(0, 5)
    collapsedCorner.Parent = collapsedButton

    local collapsedOutline = Instance.new("UIStroke")
    collapsedOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    collapsedOutline.Color = ACCENT
    collapsedOutline.Thickness = 1
    collapsedOutline.Transparency = 0.2
    collapsedOutline.Parent = collapsedButton

    local function updateLayout()
        phoneLayout = PhoneHudLayout.IsPhone(parent)
        if phoneLayout then
            local rect = PhoneHudLayout.Calculate(parent.AbsoluteSize).carry
            sizeConstraint.MinSize = Vector2.zero
            sizeConstraint.MaxSize = Vector2.new(1000, 1000)
            PhoneHudLayout.Apply(panel, rect)
            collapsedButton.AnchorPoint = Vector2.new(0, 0)
            collapsedButton.Position = UDim2.fromOffset(rect.x, rect.y)
            header.Size = UDim2.new(1, -4, 0, if rect.h < 90 then 19 else 23)
            itemName.Position = UDim2.fromOffset(15,
                if rect.h < 80 then 21 elseif rect.h < 90 then 23 else 25)
            itemName.Size = UDim2.new(1, -30, 0, 22)
            itemName.TextSize = if rect.h < 80 then 13 else 14
            itemDetails.Position = UDim2.fromOffset(15,
                if rect.h < 80 then 42 elseif rect.h < 90 then 45 else 48)
            itemDetails.Size = UDim2.new(1, -30, 0, 16)
            itemDetails.TextSize = if rect.h < 80 then 11 else 12
            incomeDetails.Position = UDim2.fromOffset(15,
                if rect.h < 80 then 58 elseif rect.h < 90 then 65 else 69)
            incomeDetails.Size = UDim2.new(1, -30, 0, 16)
            incomeDetails.TextSize = if rect.h < 80 then 11 else 12
            behavior.Visible = false
            divider.Visible = false
            hint.Visible = false
        else
            sizeConstraint.MinSize = Vector2.new(285, 130)
            sizeConstraint.MaxSize = Vector2.new(370, 130)
            panel.AnchorPoint = Vector2.new(0, 1)
            panel.Position = UDim2.new(0, 28, 1, -34)
            panel.Size = UDim2.new(0.38, 0, 0, 130)
            collapsedButton.AnchorPoint = Vector2.new(0, 1)
            collapsedButton.Position = UDim2.new(0, 28, 1, -34)
            header.Size = UDim2.new(1, -4, 0, 25)
            itemName.Position = UDim2.fromOffset(15, 29)
            itemName.Size = UDim2.new(1, -125, 0, 26)
            itemName.TextSize = 17
            itemDetails.Position = UDim2.fromOffset(15, 57)
            itemDetails.Size = UDim2.new(1, -30, 0, 18)
            itemDetails.TextSize = 12
            incomeDetails.Position = UDim2.fromOffset(15, 76)
            incomeDetails.Size = UDim2.new(1, -30, 0, 18)
            incomeDetails.TextSize = 12
            behavior.Visible = true
            divider.Visible = true
            hint.Visible = true
        end
    end

    local function updateVisibility()
        panel.Visible = carrying and expanded
        collapsedButton.Visible = carrying and not expanded
    end

    collapseButton.Activated:Connect(function()
        expanded = false
        updateVisibility()
    end)

    collapsedButton.Activated:Connect(function()
        expanded = true
        updateVisibility()
    end)

    local function render()
        local currentItem = player:GetAttribute("CurrentCarryItem")
        local wasCarrying = carrying
        carrying = type(currentItem) == "string" and currentItem ~= ""
        if carrying and not wasCarrying then expanded = true end
        if not carrying then expanded = false end
        itemName.Text = string.upper(if carrying then currentItem else "Dramatic Toaster")

        local itemId = player:GetAttribute("CarryItemId")
        local definition = if type(itemId) == "string" then Items.ById[itemId] else nil
        if definition ~= nil then
            local protected = definition.baseIncomePerMinute * Balance.PROTECTED_INCOME_MULTIPLIER
            local currentBehavior = player:GetAttribute("CarryBehavior")
            local publicStock = player:GetAttribute("CarrySource") == "Depot"
            if phoneLayout then
                itemDetails.Text = string.upper(definition.tier) .. " / "
                    .. string.upper(if type(currentBehavior) == "string" then currentBehavior else "Noisy")
                incomeDetails.Text = if publicStock
                    then "DISPLAY IF PLACED: $" .. tostring(definition.baseIncomePerMinute) .. "/MIN"
                    else "PROTECTED STAND: $" .. tostring(protected) .. "/MIN"
            else
                itemDetails.Text = string.upper(definition.tier) .. "  /  "
                    .. string.upper(if type(currentBehavior) == "string" then currentBehavior else "Noisy")
                incomeDetails.Text = if publicStock
                    then "DISPLAY IF PLACED: $" .. tostring(definition.baseIncomePerMinute) .. "/MIN"
                    else "PROTECTED DISPLAY: $" .. tostring(protected) .. "/MIN"
            end
            collapsedButton.Text = "CARRY\n+ INFO"
        else
            itemDetails.Text = ""
            incomeDetails.Text = ""
            collapsedButton.Text = "CARRY\n+ INFO"
        end

        local currentBehavior = player:GetAttribute("CarryBehavior")
        behavior.Text = string.upper(if type(currentBehavior) == "string" and currentBehavior ~= ""
            then currentBehavior
            else "Noisy")

        previewLabel.Visible = not carrying and not phoneLayout
        if UserInputService.TouchEnabled and UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
            hint.Text = "HOLD DELIVER AT THE EXHIBIT STAND"
        elseif UserInputService.GamepadEnabled and string.find(UserInputService:GetLastInputType().Name, "Gamepad") then
            hint.Text = "[B]  HOLD AT STAND TO DELIVER"
        else
            hint.Text = "[G]  HOLD AT STAND TO DELIVER"
        end
        updateVisibility()
    end

    player:GetAttributeChangedSignal("CurrentCarryItem"):Connect(render)
    player:GetAttributeChangedSignal("CarryBehavior"):Connect(render)
    player:GetAttributeChangedSignal("CarryItemId"):Connect(render)
    player:GetAttributeChangedSignal("CarrySource"):Connect(render)
    UserInputService.LastInputTypeChanged:Connect(render)
    parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        updateLayout()
        render()
    end)
    updateLayout()
    render()
end

return table.freeze(CarryHud)
