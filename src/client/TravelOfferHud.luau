--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(script.Parent.HudTheme)

local TravelOfferHud = {}

local function label(parent: Instance, name: string, value: string,
    y: number, height: number, size: number, color: Color3): TextLabel
    local text = Instance.new("TextLabel")
    text.Name = name
    text.Position = UDim2.fromOffset(18, y)
    text.Size = UDim2.new(1, -36, 0, height)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.Text = value
    text.TextColor3 = color
    text.TextSize = size
    text.TextWrapped = true
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.ZIndex = 104
    text.Parent = parent
    return text
end

function TravelOfferHud.Create(parent: Frame, _player: Player)
    local network = ReplicatedStorage:WaitForChild("Network")
    local rideRemote = network:WaitForChild("RideToDepot") :: RemoteEvent

    label(parent, "Title", "TRAVEL", 16, 32, 22, Theme.Text)
    label(parent, "RideDescription",
        "DEPOT RIDE  /  Free while testing. Use it from your museum to reach the depot.",
        61, 60, 14, Theme.Text)

    local ride = Instance.new("TextButton")
    ride.Name = "RideToDepot"
    ride.Position = UDim2.fromOffset(18, 126)
    ride.Size = UDim2.new(1, -36, 0, 44)
    ride.BackgroundColor3 = Theme.Accent
    ride.TextColor3 = Theme.Ink
    ride.Text = "RIDE TO DEPOT"
    ride.Font = Enum.Font.GothamBlack
    ride.TextSize = 15
    ride.ZIndex = 105
    ride.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = ride
    ride.Activated:Connect(function()
        rideRemote:FireServer()
    end)

    label(parent, "SprintDescription",
        "SPRINT  /  A faster walking option is planned for a future update.",
        188, 64, 13, Theme.Muted)
    label(parent, "ReminderDescription",
        "Travel information stays here in the menu. It will not pop up during play.",
        263, 60, 12, Theme.Muted)
end

return table.freeze(TravelOfferHud)
