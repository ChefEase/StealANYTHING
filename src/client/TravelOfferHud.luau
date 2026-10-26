--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(script.Parent.HudTheme)

local TravelOfferHud = {}

local function label(parent: Instance, name: string, text: string, y: number, height: number, size: number): TextLabel
    local item = Instance.new("TextLabel")
    item.Name = name
    item.Position = UDim2.fromOffset(18, y)
    item.Size = UDim2.new(1, -36, 0, height)
    item.BackgroundTransparency = 1
    item.Text = text
    item.TextColor3 = Theme.Text
    item.Font = Enum.Font.GothamBold
    item.TextSize = size
    item.TextWrapped = true
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.ZIndex = 26
    item.Parent = parent
    return item
end

local function button(parent: Instance, name: string, text: string, x: number, width: number, color: Color3): TextButton
    local item = Instance.new("TextButton")
    item.Name = name
    item.Position = UDim2.new(x, 0, 0, 118)
    item.Size = UDim2.new(width, -24, 0, 38)
    item.BackgroundColor3 = color
    item.TextColor3 = if color == Theme.Accent then Theme.Ink else Theme.Text
    item.Text = text
    item.Font = Enum.Font.GothamBlack
    item.TextSize = 15
    item.ZIndex = 26
    item.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = item
    return item
end

function TravelOfferHud.Create(screen: ScreenGui, player: Player)
    local network = ReplicatedStorage:WaitForChild("Network")
    local rideRemote = network:WaitForChild("RideToDepot") :: RemoteEvent
    local settingsRemote = network:WaitForChild("TravelTipSettings") :: RemoteEvent
    local card = Instance.new("Frame")
    card.Name = "TravelOffer"
    card.AnchorPoint = Vector2.new(0.5, 0)
    card.Position = UDim2.new(0.5, 0, 0, 70)
    card.Size = UDim2.fromOffset(390, 216)
    card.BackgroundColor3 = Theme.Panel
    card.BorderSizePixel = 0
    card.Visible = false
    card.ZIndex = 25
    card.Parent = screen
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = card
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Accent
    stroke.Thickness = 2
    stroke.Parent = card
    local reopen = Instance.new("TextButton")
    reopen.Name = "ReopenTravelOffer"
    reopen.AnchorPoint = Vector2.new(0.5, 0)
    reopen.Position = UDim2.new(0.5, 0, 0, 70)
    reopen.Size = UDim2.fromOffset(176, 36)
    reopen.BackgroundColor3 = Theme.Panel
    reopen.TextColor3 = Theme.Accent
    reopen.Text = "DEPOT RIDE  ▲"
    reopen.Font = Enum.Font.GothamBold
    reopen.TextSize = 14
    reopen.ZIndex = 25
    reopen.Visible = false
    reopen.Parent = screen
    local reopenCorner = Instance.new("UICorner")
    reopenCorner.CornerRadius = UDim.new(0, 7)
    reopenCorner.Parent = reopen
    local reopenStroke = Instance.new("UIStroke")
    reopenStroke.Color = Theme.Accent
    reopenStroke.Thickness = 2
    reopenStroke.Parent = reopen
    local hasOffer = player:GetAttribute("TravelOfferSerial") ~= nil
    local function setCardVisible(visible: boolean)
        card.Visible = visible
        reopen.Visible = hasOffer and not visible
    end
    reopen.Activated:Connect(function() setCardVisible(true) end)
    local title = label(card, "Title", "GET TO THE DEPOT", 10, 26, 20)
    title.TextColor3 = Theme.Accent
    label(card, "Description", "RIDE: free while testing; later an unlock with a 60s cooldown. SPEED COIL: 20% faster walking, coming later. First pick $1,000, second $2,200.", 39, 70, 14)
    local ride = button(card, "Ride", "RIDE NOW", 0, 0.5, Theme.Accent)
    ride.Position = UDim2.new(0, 18, 0, 118)
    ride.Size = UDim2.new(0.5, -24, 0, 38)
    local walk = button(card, "Walk", "KEEP WALKING", 0.5, 0.5, Theme.Ink)
    walk.Position = UDim2.new(0.5, 6, 0, 118)
    walk.Size = UDim2.new(0.5, -24, 0, 38)
    local preference = Instance.new("TextButton")
    preference.Name = "ReminderPreference"
    preference.Position = UDim2.fromOffset(18, 168)
    preference.Size = UDim2.new(1, -36, 0, 34)
    preference.BackgroundColor3 = Theme.Ink
    preference.TextColor3 = Theme.Text
    preference.Font = Enum.Font.GothamBold
    preference.TextSize = 13
    preference.ZIndex = 26
    preference.Parent = card
    local prefCorner = Instance.new("UICorner")
    prefCorner.CornerRadius = UDim.new(0, 5)
    prefCorner.Parent = preference
    local function refreshPreference()
        preference.Text = if player:GetAttribute("TravelTipsEnabled") == true
            then "SHOW TRAVEL TIPS AGAIN: ON  (tap to disable)"
            else "SHOW TRAVEL TIPS AGAIN: OFF  (tap to enable)"
    end
    preference.Activated:Connect(function()
        local nextValue = player:GetAttribute("TravelTipsEnabled") ~= true
        player:SetAttribute("TravelTipsEnabled", nextValue)
        settingsRemote:FireServer(nextValue)
        refreshPreference()
    end)
    player:GetAttributeChangedSignal("TravelTipsEnabled"):Connect(refreshPreference)
    ride.Activated:Connect(function()
        setCardVisible(false)
        rideRemote:FireServer()
    end)
    walk.Activated:Connect(function() setCardVisible(false) end)
    player:GetAttributeChangedSignal("TravelOfferSerial"):Connect(function()
        hasOffer = true
        setCardVisible(true)
        refreshPreference()
    end)
    if hasOffer then setCardVisible(true) end
    refreshPreference()
end

return table.freeze(TravelOfferHud)
