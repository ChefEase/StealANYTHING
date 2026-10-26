--!strict

local TweenService = game:GetService("TweenService")
local PhoneHudLayout = require(script.Parent.PhoneHudLayout)
local Theme = require(script.Parent.HudTheme)

local COLORS = {
    Success = Theme.Accent,
    Error = Color3.fromRGB(244, 68, 77),
    Warning = Color3.fromRGB(255, 184, 65),
    Info = Theme.Accent,
}

local NotificationHud = {}

function NotificationHud.Create(parent: ScreenGui, player: Player)
    local panel = Instance.new("Frame")
    panel.Name = "Notification"
    panel.AnchorPoint = Vector2.new(0, 0.5)
    panel.Position = UDim2.new(0, -330, 0.32, 0)
    panel.Size = UDim2.fromOffset(306, 62)
    panel.BackgroundColor3 = Theme.Ink
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = panel

    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 5, 1, 0)
    accent.BackgroundColor3 = COLORS.Info
    accent.BorderSizePixel = 0
    accent.Parent = panel

    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Position = UDim2.fromOffset(14, 11)
    icon.Size = UDim2.fromOffset(40, 40)
    icon.BackgroundColor3 = COLORS.Info
    icon.BackgroundTransparency = 0.85
    icon.Font = Enum.Font.GothamBold
    icon.Text = "i"
    icon.TextColor3 = COLORS.Info
    icon.TextSize = 21
    icon.Parent = panel

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = icon

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Position = UDim2.fromOffset(64, 8)
    title.Size = UDim2.new(1, -75, 0, 25)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = ""
    title.TextColor3 = Theme.Text
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Parent = panel

    local detail = Instance.new("TextLabel")
    detail.Name = "Detail"
    detail.Position = UDim2.fromOffset(64, 32)
    detail.Size = UDim2.new(1, -75, 0, 20)
    detail.BackgroundTransparency = 1
    detail.Font = Enum.Font.GothamMedium
    detail.Text = ""
    detail.TextColor3 = Theme.Muted
    detail.TextSize = 11
    detail.TextXAlignment = Enum.TextXAlignment.Left
    detail.TextTruncate = Enum.TextTruncate.AtEnd
    detail.Parent = panel

    local displayToken = 0

    local function positions(): (UDim2, UDim2)
        if PhoneHudLayout.IsPhone(parent) then
            local rect = PhoneHudLayout.Calculate(parent.AbsoluteSize).notice
            panel.AnchorPoint = Vector2.zero
            panel.Size = UDim2.fromOffset(rect.w, rect.h)
            title.TextSize = 13
            detail.TextSize = 10
            return UDim2.fromOffset(rect.x, -rect.h - 10),
                UDim2.fromOffset(rect.x, rect.y)
        end
        panel.AnchorPoint = Vector2.new(0, 0.5)
        panel.Size = UDim2.fromOffset(306, 62)
        title.TextSize = 15
        detail.TextSize = 11
        return UDim2.new(0, -330, 0.32, 0),
            UDim2.new(0, 24, 0.32, 0)
    end

    parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if panel.Visible then
            local _, shown = positions()
            panel.Position = shown
        end
    end)

    local function show(message: string, description: string, kind: string)
        displayToken += 1
        local token = displayToken
        local color = COLORS[kind] or COLORS.Info
        accent.BackgroundColor3 = color
        icon.BackgroundColor3 = color
        icon.TextColor3 = color
        icon.Text = if kind == "Success" then utf8.char(10003) elseif kind == "Error" then "!" else "i"
        title.Text = string.upper(message)
        detail.Text = description
        detail.Visible = description ~= ""
        local hidden, shown = positions()
        panel.Position = hidden
        panel.Visible = true
        TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = shown,
        }):Play()

        task.delay(3.2, function()
            if token ~= displayToken then return end
            local offscreen = positions()
            local tween = TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = offscreen,
            })
            tween:Play()
            tween.Completed:Wait()
            if token == displayToken then
                panel.Visible = false
            end
        end)
    end

    local function renderAttribute()
        local message = player:GetAttribute("HudNotificationText")
        if type(message) ~= "string" or message == "" then return end
        local description = player:GetAttribute("HudNotificationDetail")
        local kind = player:GetAttribute("HudNotificationKind")
        show(message, if type(description) == "string" then description else "",
            if type(kind) == "string" then kind else "Info")
    end

    player:GetAttributeChangedSignal("HudNotificationSerial"):Connect(renderAttribute)
end

return table.freeze(NotificationHud)
