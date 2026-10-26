--!strict

local PhoneHudLayout = require(script.Parent.PhoneHudLayout)
local Theme = require(script.Parent.HudTheme)

local ACCENT = Theme.Accent
local TEXT = Theme.Text
local MUTED = Theme.Muted
local PANEL = Theme.Ink

local CarryDestinationHud = {}

local function addGridLine(parent: Instance, position: UDim2, size: UDim2)
    local line = Instance.new("Frame")
    line.BackgroundColor3 = Theme.Outline
    line.BackgroundTransparency = 0.78
    line.BorderSizePixel = 0
    line.Position = position
    line.Size = size
    line.Parent = parent
end

function CarryDestinationHud.Create(parent: ScreenGui, player: Player)
    local panel = Instance.new("Frame")
    panel.Name = "CarryDestination"
    panel.AnchorPoint = Vector2.new(1, 1)
    panel.Position = UDim2.new(1, -28, 1, -34)
    panel.Size = UDim2.fromOffset(250, 92)
    panel.BackgroundColor3 = PANEL
    panel.BackgroundTransparency = 0.12
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Visible = false
    panel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = panel

    local outline = Instance.new("UIStroke")
    outline.Color = ACCENT
    outline.Thickness = 1
    outline.Transparency = 0.32
    outline.Parent = panel

    addGridLine(panel, UDim2.fromScale(0.25, 0), UDim2.new(0, 1, 1, 0))
    addGridLine(panel, UDim2.fromScale(0.5, 0), UDim2.new(0, 1, 1, 0))
    addGridLine(panel, UDim2.fromScale(0.75, 0), UDim2.new(0, 1, 1, 0))
    addGridLine(panel, UDim2.fromScale(0, 0.5), UDim2.new(1, 0, 0, 1))

    local marker = Instance.new("Frame")
    marker.Name = "WaypointMarker"
    marker.AnchorPoint = Vector2.new(0.5, 0.5)
    marker.Position = UDim2.fromOffset(39, 46)
    marker.Size = UDim2.fromOffset(27, 27)
    marker.Rotation = 45
    marker.BackgroundColor3 = ACCENT
    marker.BackgroundTransparency = 0.08
    marker.BorderSizePixel = 0
    marker.Parent = panel

    local markerInset = Instance.new("Frame")
    markerInset.AnchorPoint = Vector2.new(0.5, 0.5)
    markerInset.Position = UDim2.fromScale(0.5, 0.5)
    markerInset.Size = UDim2.fromOffset(11, 11)
    markerInset.BackgroundColor3 = PANEL
    markerInset.BorderSizePixel = 0
    markerInset.Parent = marker

    local caption = Instance.new("TextLabel")
    caption.Name = "Caption"
    caption.Position = UDim2.fromOffset(69, 10)
    caption.Size = UDim2.new(1, -78, 0, 15)
    caption.BackgroundTransparency = 1
    caption.Font = Enum.Font.GothamBold
    caption.Text = "CARRY DESTINATION"
    caption.TextColor3 = MUTED
    caption.TextSize = 10
    caption.TextXAlignment = Enum.TextXAlignment.Left
    caption.Parent = panel

    local destination = Instance.new("TextLabel")
    destination.Name = "Destination"
    destination.Position = UDim2.fromOffset(69, 25)
    destination.Size = UDim2.new(1, -78, 0, 28)
    destination.BackgroundTransparency = 1
    destination.Font = Enum.Font.GothamBold
    destination.Text = "MUSEUM DROP-OFF"
    destination.TextColor3 = TEXT
    destination.TextSize = 15
    destination.TextXAlignment = Enum.TextXAlignment.Left
    destination.TextTruncate = Enum.TextTruncate.AtEnd
    destination.Parent = panel

    local direction = Instance.new("TextLabel")
    direction.Name = "Direction"
    direction.Position = UDim2.fromOffset(69, 56)
    direction.Size = UDim2.new(1, -78, 0, 23)
    direction.BackgroundTransparency = 1
    direction.Font = Enum.Font.Code
    direction.Text = ">  205 STUDS"
    direction.TextColor3 = ACCENT
    direction.TextSize = 13
    direction.TextXAlignment = Enum.TextXAlignment.Left
    direction.Parent = panel

    local preview = Instance.new("TextLabel")
    preview.Name = "Preview"
    preview.AnchorPoint = Vector2.new(1, 1)
    preview.Position = UDim2.new(1, -7, 1, -5)
    preview.Size = UDim2.fromOffset(70, 12)
    preview.BackgroundTransparency = 1
    preview.Font = Enum.Font.GothamBold
    preview.Text = "PREVIEW"
    preview.TextColor3 = MUTED
    preview.TextSize = 8
    preview.TextXAlignment = Enum.TextXAlignment.Right
    preview.Parent = panel

    local function updateLayout()
        local phoneLayout = PhoneHudLayout.IsPhone(parent)
        if phoneLayout then
            panel.AnchorPoint = Vector2.new(1, 0)
            panel.Position = UDim2.new(1, -14, 0, 92)
            panel.Size = UDim2.fromOffset(220, 82)
            preview.Visible = false
        else
            panel.AnchorPoint = Vector2.new(1, 1)
            panel.Position = UDim2.new(1, -28, 1, -34)
            panel.Size = UDim2.fromOffset(250, 92)
        end
    end

    local function render()
        local currentItem = player:GetAttribute("CurrentCarryItem")
        local carrying = type(currentItem) == "string" and currentItem ~= ""
        local phone = PhoneHudLayout.IsPhone(parent)
        -- The guided toaster already has a direction arrow and distance.
        -- Hide this duplicate destination card on both desktop and phone.
        panel.Visible = carrying and player:GetAttribute("TutorialStep") ~= 0
            and player:GetAttribute("TutorialReplayActive") ~= true

        local currentDestination = player:GetAttribute("CarryDestination")
        destination.Text = string.upper(if type(currentDestination) == "string" and currentDestination ~= ""
            then currentDestination
            else "Museum Drop-Off")

        local currentDistance = player:GetAttribute("CarryDistance")
        direction.Text = ">  " .. (if type(currentDistance) == "number"
            then tostring(math.max(0, math.floor(currentDistance))) .. " STUDS"
            else "FOLLOW DROP-OFF SIGN")
        preview.Visible = not carrying and not phone
    end

    player:GetAttributeChangedSignal("CurrentCarryItem"):Connect(render)
    player:GetAttributeChangedSignal("CarryDestination"):Connect(render)
    player:GetAttributeChangedSignal("CarryDistance"):Connect(render)
    player:GetAttributeChangedSignal("TutorialStep"):Connect(render)
    player:GetAttributeChangedSignal("TutorialReplayActive"):Connect(render)
    parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        updateLayout()
        render()
    end)
    updateLayout()
    render()
end

return table.freeze(CarryDestinationHud)
