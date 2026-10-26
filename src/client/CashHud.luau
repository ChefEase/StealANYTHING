--!strict

local Theme = require(script.Parent.HudTheme)
local CASH_GREEN = Theme.Accent
local TEXT = Theme.Text
local MUTED = Theme.Muted
local PANEL = Theme.Ink
local PhoneHudLayout = require(script.Parent.PhoneHudLayout)

local CashHud = {}

local function formatCash(value: number): string
    local amount = math.max(0, math.floor(value))
    local digits = tostring(amount)
    local formatted = digits
    repeat
        local replacements
        formatted, replacements = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
    until replacements == 0
    return "$" .. formatted
end

function CashHud.Create(parent: ScreenGui, player: Player)
    local panel = Instance.new("Frame")
    panel.Name = "CashBalance"
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.Position = UDim2.new(1, -28, 0, 28)
    panel.Size = UDim2.fromOffset(184, 72)
    panel.BackgroundColor3 = PANEL
    panel.BackgroundTransparency = 0.12
    panel.BorderSizePixel = 0
    panel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = panel

    local outline = Instance.new("UIStroke")
    outline.Color = Theme.Outline
    outline.Thickness = 1
    outline.Transparency = 0.3
    outline.Parent = panel

    local icon = Instance.new("Frame")
    icon.Name = "Icon"
    icon.Position = UDim2.fromOffset(10, 10)
    icon.Size = UDim2.fromOffset(32, 32)
    icon.BackgroundColor3 = CASH_GREEN
    icon.BorderSizePixel = 0
    icon.Parent = panel

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = icon

    local iconText = Instance.new("TextLabel")
    iconText.Name = "Symbol"
    iconText.Size = UDim2.fromScale(1, 1)
    iconText.BackgroundTransparency = 1
    iconText.Font = Enum.Font.GothamBold
    iconText.Text = "$"
    iconText.TextColor3 = Theme.Ink
    iconText.TextSize = 18
    iconText.Parent = icon

    local caption = Instance.new("TextLabel")
    caption.Name = "Caption"
    caption.Position = UDim2.fromOffset(51, 6)
    caption.Size = UDim2.new(1, -59, 0, 16)
    caption.BackgroundTransparency = 1
    caption.Font = Enum.Font.GothamBold
    caption.Text = "CASH"
    caption.TextColor3 = MUTED
    caption.TextSize = 10
    caption.TextXAlignment = Enum.TextXAlignment.Left
    caption.Parent = panel

    local balance = Instance.new("TextLabel")
    balance.Name = "Amount"
    balance.Position = UDim2.fromOffset(49, 20)
    balance.Size = UDim2.new(1, -57, 0, 27)
    balance.BackgroundTransparency = 1
    balance.Font = Enum.Font.GothamBold
    balance.Text = "$---"
    balance.TextColor3 = TEXT
    balance.TextSize = 21
    balance.TextXAlignment = Enum.TextXAlignment.Left
    balance.TextTruncate = Enum.TextTruncate.AtEnd
    balance.Parent = panel

    local income = Instance.new("TextLabel")
    income.Name = "IncomeRate"
    income.Position = UDim2.fromOffset(50, 48)
    income.Size = UDim2.new(1, -58, 0, 18)
    income.BackgroundTransparency = 1
    income.Font = Enum.Font.GothamBold
    income.TextColor3 = CASH_GREEN
    income.TextSize = 11
    income.TextXAlignment = Enum.TextXAlignment.Left
    income.Parent = panel

    local function render()
        local cash = player:GetAttribute("Cash")
        balance.Text = if type(cash) == "number" then formatCash(cash) else "$---"
        balance.TextColor3 = if type(cash) == "number" then CASH_GREEN else TEXT
        local rate = player:GetAttribute("IncomePerMinute")
        income.Text = if type(rate) == "number" and rate > 0
            then "+$" .. tostring(rate) .. (if PhoneHudLayout.IsPhone(parent) then "/MIN ACTIVE" else "/MIN WHILE HERE")
            else "NO ACTIVE INCOME"
    end

    local function updateLayout()
        if PhoneHudLayout.IsPhone(parent) then
            PhoneHudLayout.Apply(panel, PhoneHudLayout.Calculate(parent.AbsoluteSize).cash)
            icon.Position = UDim2.fromOffset(8, 8)
            icon.Size = UDim2.fromOffset(28, 28)
            caption.Position = UDim2.fromOffset(44, 4)
            caption.Size = UDim2.new(1, -50, 0, 14)
            balance.Position = UDim2.fromOffset(42, 17)
            balance.Size = UDim2.new(1, -48, 0, 25)
            balance.TextSize = 19
            income.Position = UDim2.fromOffset(44, 43)
            income.Size = UDim2.new(1, -50, 0, 15)
            income.TextSize = 11
        else
            panel.AnchorPoint = Vector2.new(1, 0)
            panel.Position = UDim2.new(1, -28, 0, 28)
            panel.Size = UDim2.fromOffset(184, 72)
            icon.Position = UDim2.fromOffset(10, 10)
            icon.Size = UDim2.fromOffset(32, 32)
            caption.Position = UDim2.fromOffset(51, 6)
            caption.Size = UDim2.new(1, -59, 0, 16)
            balance.Position = UDim2.fromOffset(49, 20)
            balance.Size = UDim2.new(1, -57, 0, 27)
            balance.TextSize = 21
            income.Position = UDim2.fromOffset(50, 48)
            income.Size = UDim2.new(1, -58, 0, 18)
            income.TextSize = 11
        end
    end

    player:GetAttributeChangedSignal("Cash"):Connect(render)
    player:GetAttributeChangedSignal("IncomePerMinute"):Connect(render)
    parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        updateLayout()
        render()
    end)
    updateLayout()
    render()
end

return table.freeze(CashHud)
