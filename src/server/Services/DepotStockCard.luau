--!strict

local COLORS = {
    Common = Color3.fromRGB(64, 235, 193),
    Uncommon = Color3.fromRGB(106, 174, 255),
    Rare = Color3.fromRGB(201, 139, 255),
    Legendary = Color3.fromRGB(255, 195, 96),
}
local INK = Color3.fromRGB(9, 22, 26)
local Card = {}

local function round(parent: Instance, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local function line(parent: Instance, name: string, value: string, size: number,
    color: Color3, x: number, y: number, width: number, height: number): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = UDim2.fromOffset(x, y)
    label.Size = UDim2.new(1, -width, 0, height)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = value
    label.TextColor3 = color
    label.TextSize = size
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function setAccent(card: any, color: Color3)
    card.outline.Color = color
    card.stripe.BackgroundColor3 = color
    card.tier.BackgroundColor3 = color
    card.icon.BackgroundColor3 = color
    card.rate.BackgroundColor3 = color
end

function Card.Create(socket: BasePart, heading: string): any
    local gui = Instance.new("BillboardGui")
    gui.Name = "DepotStockCard"
    gui.Size = UDim2.fromOffset(179, 92)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
    gui.MaxDistance = 35
    gui.AlwaysOnTop = false
    gui.Parent = socket

    local canvas = Instance.new("Frame")
    canvas.Name = "ScaledCard"
    canvas.Size = UDim2.fromOffset(276, 142)
    canvas.BackgroundTransparency = 1
    canvas.Parent = gui
    local scale = Instance.new("UIScale")
    scale.Scale = 0.65
    scale.Parent = canvas

    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Position = UDim2.fromOffset(3, 4)
    shadow.Size = UDim2.fromScale(1, 1)
    shadow.BackgroundColor3 = Color3.fromRGB(3, 9, 12)
    shadow.BackgroundTransparency = 0.25
    shadow.BorderSizePixel = 0
    shadow.Parent = canvas
    round(shadow, 12)

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = Color3.fromRGB(13, 39, 42)
    panel.BorderSizePixel = 0
    panel.Parent = canvas
    round(panel, 12)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(Color3.fromRGB(18, 57, 58), INK)
    gradient.Rotation = 25
    gradient.Parent = panel
    local outline = Instance.new("UIStroke")
    outline.Color = COLORS.Common
    outline.Thickness = 2
    outline.Transparency = 0.1
    outline.Parent = panel

    local stripe = Instance.new("Frame")
    stripe.Name = "AccentStripe"
    stripe.Size = UDim2.fromOffset(6, 142)
    stripe.BackgroundColor3 = COLORS.Common
    stripe.BorderSizePixel = 0
    stripe.Parent = panel
    round(stripe, 3)
    local headingLabel = line(panel, "Heading", heading, 10,
        Color3.fromRGB(190, 219, 214), 16, 10, 105, 18)

    local tier = Instance.new("Frame")
    tier.Name = "TierBadge"
    tier.Position = UDim2.new(1, -80, 0, 9)
    tier.Size = UDim2.fromOffset(66, 20)
    tier.BackgroundColor3 = COLORS.Common
    tier.BorderSizePixel = 0
    tier.Parent = panel
    round(tier, 5)
    local tierText = line(tier, "TierText", "COMMON", 9, INK, 0, 0, 0, 20)
    tierText.TextXAlignment = Enum.TextXAlignment.Center

    local icon = Instance.new("Frame")
    icon.Name = "ItemIcon"
    icon.Position = UDim2.fromOffset(17, 39)
    icon.Size = UDim2.fromOffset(54, 68)
    icon.BackgroundColor3 = COLORS.Common
    icon.BorderSizePixel = 0
    icon.Parent = panel
    round(icon, 9)
    local iconGradient = Instance.new("UIGradient")
    iconGradient.Color = ColorSequence.new(Color3.new(1, 1, 1),
        Color3.fromRGB(95, 130, 125))
    iconGradient.Rotation = 70
    iconGradient.Parent = icon
    local glyph = line(icon, "Glyph", "?", 32, INK, 0, 0, 0, 68)
    glyph.TextXAlignment = Enum.TextXAlignment.Center

    local name = line(panel, "ItemName", "", 17,
        Color3.fromRGB(248, 252, 250), 82, 37, 96, 25)
    local rateCaption = line(panel, "RateCaption", "DISPLAY INCOME", 9,
        Color3.fromRGB(174, 205, 198), 83, 62, 98, 13)
    local rate = Instance.new("Frame")
    rate.Name = "IncomeTile"
    rate.Position = UDim2.fromOffset(81, 79)
    rate.Size = UDim2.new(1, -96, 0, 28)
    rate.BackgroundColor3 = COLORS.Common
    rate.BorderSizePixel = 0
    rate.Parent = panel
    round(rate, 6)
    local rateText = line(rate, "Income", "$0 / MIN", 18, INK, 9, 0, 18, 28)
    local separator = Instance.new("Frame")
    separator.Position = UDim2.fromOffset(17, 117)
    separator.Size = UDim2.new(1, -31, 0, 1)
    separator.BackgroundColor3 = Color3.fromRGB(95, 126, 121)
    separator.BackgroundTransparency = 0.45
    separator.BorderSizePixel = 0
    separator.Parent = panel
    local footer = line(panel, "Countdown", "", 10,
        Color3.fromRGB(204, 223, 216), 17, 120, 31, 17)

    return { gui = gui, outline = outline, stripe = stripe,
        heading = headingLabel, tier = tier, tierText = tierText,
        icon = icon, glyph = glyph, name = name,
        rate = rate, rateText = rateText, rateCaption = rateCaption,
        footer = footer }
end

function Card.ShowItem(card: any, item: any, incomePerMinute: number,
    footer: string)
    setAccent(card, COLORS[item.tier] or COLORS.Common)
    card.heading.Text = "PUBLIC ACQUISITION"
    card.tierText.Text = string.upper(item.tier)
    card.glyph.Text = string.upper(string.sub(item.name, 1, 1))
    card.glyph.TextSize = 32
    card.name.Text = item.name
    card.rateText.Text = "$" .. tostring(incomePerMinute) .. " / MIN"
    card.rateCaption.Text = "DISPLAY INCOME"
    card.footer.Text = footer
end

function Card.ShowTutorial(card: any, item: any, protectedRate: number)
    Card.ShowItem(card, item, protectedRate,
        "PROTECTED STAND  /  SAFE FROM RAIDS")
    setAccent(card, Color3.fromRGB(255, 195, 96))
    card.heading.Text = "YOUR FIRST HEIST"
    card.tierText.Text = "SAFE"
    card.rateCaption.Text = "PROTECTED INCOME"
end

function Card.ShowRestock(card: any, remaining: number)
    setAccent(card, Color3.fromRGB(210, 173, 103))
    card.heading.Text = "PUBLIC ACQUISITION"
    card.tierText.Text = "EMPTY"
    card.glyph.Text = "..."
    card.glyph.TextSize = 21
    card.name.Text = "Stock taken"
    card.rateText.Text = "RESTOCKING"
    card.rateCaption.Text = "NEXT EXHIBIT"
    card.footer.Text = "READY IN " .. tostring(remaining) .. "S"
end

return table.freeze(Card)
