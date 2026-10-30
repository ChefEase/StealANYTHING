--!strict

local Theme = require(script.Parent.HudTheme)
local HttpService = game:GetService("HttpService")
local ItemCatalog = require(game:GetService("ReplicatedStorage").Shared.ItemCatalog)
local Balance = require(game:GetService("ReplicatedStorage").Shared.BalanceConfig)
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

    local income = Instance.new("TextButton")
    income.Name = "IncomeRate"
    income.Position = UDim2.fromOffset(50, 48)
    income.Size = UDim2.new(1, -58, 0, 18)
    income.BackgroundTransparency = 1
    income.Font = Enum.Font.GothamBold
    income.TextColor3 = CASH_GREEN
    income.TextSize = 11
    income.TextXAlignment = Enum.TextXAlignment.Left
    income.TextTruncate = Enum.TextTruncate.AtEnd
    income.AutoButtonColor = false
    income.Parent = panel

    local phoneRate = Instance.new("TextLabel")
    phoneRate.Name = "PhoneIncomeRate"
    phoneRate.BackgroundTransparency = 1
    phoneRate.Font = Enum.Font.GothamBold
    phoneRate.TextColor3 = CASH_GREEN
    phoneRate.TextSize = 11
    phoneRate.TextXAlignment = Enum.TextXAlignment.Left
    phoneRate.TextTruncate = Enum.TextTruncate.AtEnd
    phoneRate.Visible = false
    phoneRate.Parent = panel

    local details = Instance.new("Frame")
    details.Name = "DisplayedIncome"
    details.Position = UDim2.fromOffset(9, 75)
    details.Size = UDim2.new(1, -18, 0, 75)
    details.BackgroundColor3 = Color3.fromRGB(17, 47, 48)
    details.BorderSizePixel = 0
    details.Parent = panel
    local detailCorner = Instance.new("UICorner")
    detailCorner.CornerRadius = UDim.new(0, 6)
    detailCorner.Parent = details
    local detailStroke = Instance.new("UIStroke")
    detailStroke.Color = CASH_GREEN
    detailStroke.Transparency = 0.35
    detailStroke.Parent = details
    local detailTitle = Instance.new("TextLabel")
    detailTitle.Name = "DetailsTitle"
    detailTitle.Position = UDim2.fromOffset(8, 3)
    detailTitle.Size = UDim2.new(1, -16, 0, 15)
    detailTitle.BackgroundTransparency = 1
    detailTitle.Font = Enum.Font.GothamBold
    detailTitle.Text = "DISPLAYED EXHIBITS"
    detailTitle.TextSize = 10
    detailTitle.TextColor3 = CASH_GREEN
    detailTitle.TextXAlignment = Enum.TextXAlignment.Left
    detailTitle.Parent = details
    local rows = {}
    for index = 1, 3 do
        local row = Instance.new("TextLabel")
        row.Name = "IncomeItem" .. tostring(index)
        row.Position = UDim2.fromOffset(8, 17 + (index - 1) * 17)
        row.Size = UDim2.new(1, -16, 0, 17)
        row.BackgroundTransparency = 1
        row.Font = Enum.Font.GothamMedium
        row.TextSize = 10
        row.TextColor3 = TEXT
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.TextTruncate = Enum.TextTruncate.AtEnd
        row.Parent = details
        table.insert(rows, row)
    end

    local phoneDetailsOpen = false
    income.Activated:Connect(function()
        if PhoneHudLayout.IsPhone(parent) then
            phoneDetailsOpen = not phoneDetailsOpen
            details.Visible = phoneDetailsOpen
        end
    end)

    local lastCash: number? = nil
    local gainToken = 0
    local function render()
        local cash = player:GetAttribute("Cash")
        balance.Text = if type(cash) == "number" then formatCash(cash) else "$---"
        balance.TextColor3 = if type(cash) == "number" then CASH_GREEN else TEXT
        if type(cash) == "number" then
            if lastCash ~= nil and cash > lastCash then
                gainToken += 1
                local token = gainToken
                caption.Text = "+" .. formatCash(cash - lastCash) .. " EARNED"
                caption.TextColor3 = CASH_GREEN
                task.delay(1.8, function()
                    if token ~= gainToken then return end
                    caption.Text = "CASH"
                    caption.TextColor3 = MUTED
                end)
            elseif lastCash ~= nil and cash < lastCash then
                gainToken += 1
                caption.Text = "CASH"
                caption.TextColor3 = MUTED
            end
            lastCash = cash
        else
            lastCash = nil
            gainToken += 1
            caption.Text = "CASH"
            caption.TextColor3 = MUTED
        end
        local rate = player:GetAttribute("IncomePerMinute")
        local rateText = if type(rate) == "number" and rate > 0
            then "+$" .. tostring(rate) .. "/MIN" else "NO ACTIVE INCOME"
        phoneRate.Text = rateText
        income.Text = if PhoneHudLayout.IsPhone(parent)
            then "TAP TO VIEW ITEMS"
            else rateText .. " WHILE HERE"
        local raw = player:GetAttribute("CollectionState")
        local parsed: any = nil
        if type(raw) == "string" then
            local ok, value = pcall(HttpService.JSONDecode, HttpService, raw)
            if ok then parsed = value end
        end
        local displayed = {}
        if parsed ~= nil and type(parsed.items) == "table" then
            for _, entry in parsed.items do
                if entry.slot ~= nil then
                    local item = ItemCatalog.ById[entry.id]
                    if item ~= nil then
                        local itemRate = item.baseIncomePerMinute
                            * (if entry.slot == "protected"
                                then Balance.PROTECTED_INCOME_MULTIPLIER else 1)
                        table.insert(displayed, item.name .. "  +$" .. tostring(itemRate) .. "/min")
                    end
                end
            end
        end
        for index, row in rows do
            row.Text = displayed[index] or ""
        end
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
            phoneRate.Position = UDim2.fromOffset(44, 43)
            phoneRate.Size = UDim2.new(1, -50, 0, 15)
            phoneRate.Visible = true
            income.Position = UDim2.fromOffset(8, 57)
            income.Size = UDim2.new(1, -16, 0, 18)
            income.TextSize = 10
            details.Position = UDim2.fromOffset(-54, 82)
            details.Size = UDim2.fromOffset(208, 75)
            details.Visible = phoneDetailsOpen
        else
            panel.AnchorPoint = Vector2.new(1, 0)
            panel.Position = UDim2.new(1, -28, 0, 28)
            panel.Size = UDim2.fromOffset(230, 160)
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
            phoneRate.Visible = false
            details.Position = UDim2.fromOffset(9, 75)
            details.Size = UDim2.new(1, -18, 0, 75)
            details.Visible = true
        end
    end

    player:GetAttributeChangedSignal("Cash"):Connect(render)
    player:GetAttributeChangedSignal("IncomePerMinute"):Connect(render)
    player:GetAttributeChangedSignal("CollectionState"):Connect(render)
    parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        updateLayout()
        render()
    end)
    updateLayout()
    render()
end

return table.freeze(CashHud)
