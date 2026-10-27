--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local player = Players.LocalPlayer
require(ReplicatedStorage.Shared.WardrobeUi).Start(player, nil, false)
local statusRemote = ReplicatedStorage:WaitForChild("MatchStatus") :: RemoteEvent
local controlRemote = ReplicatedStorage:WaitForChild("MatchControl") :: RemoteEvent

local screen = Instance.new("ScreenGui")
screen.Name = "MatchmakingLobby"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "HeistControl"
card.AnchorPoint = Vector2.new(1, 0)
card.Position = UDim2.new(1, -12, 0, 8)
card.Size = UDim2.fromOffset(236, 135)
card.BackgroundColor3 = Color3.fromRGB(21, 30, 35)
card.BackgroundTransparency = 0.04
card.Parent = screen
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(236, 172)
limit.Parent = card
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 9)
corner.Parent = card
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 84, 88)
stroke.Thickness = 1
stroke.Parent = card

local function label(name: string, text: string, x: number, y: number,
    width: UDim, height: number, color: Color3, font: Enum.Font,
    size: number): TextLabel
    local item = Instance.new("TextLabel")
    item.Name = name
    item.Position = UDim2.new(0, x, 0, y)
    item.Size = UDim2.new(width.Scale, width.Offset, 0, height)
    item.BackgroundTransparency = 1
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Center
    item.Text = text
    item.TextColor3 = color
    item.Font = font
    item.TextSize = size
    item.TextWrapped = true
    item.Parent = card
    return item
end

local title = label("Title", "HEIST CONTROL", 12, 6, UDim.new(1, -80), 23,
    Color3.fromRGB(235, 241, 242), Enum.Font.GothamBold, 14)
title.TextScaled = true
local titleSize = Instance.new("UITextSizeConstraint")
titleSize.MaxTextSize = 14
titleSize.MinTextSize = 10
titleSize.Parent = title
local toggle = Instance.new("TextButton")
toggle.Name = "Expand"
toggle.AnchorPoint = Vector2.new(1, 0)
toggle.Position = UDim2.new(1, -9, 0, 6)
toggle.Size = UDim2.fromOffset(50, 24)
toggle.BackgroundColor3 = Color3.fromRGB(48, 67, 72)
toggle.TextColor3 = Color3.fromRGB(232, 243, 241)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 11
toggle.Text = "MORE"
toggle.Parent = card
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggle

local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Position = UDim2.new(0, 12, 0, 32)
divider.Size = UDim2.new(1, -26, 0, 1)
divider.BorderSizePixel = 0
divider.BackgroundColor3 = Color3.fromRGB(57, 79, 84)
divider.Parent = card
local count = label("Count", "1 IN QUEUE", 12, 39, UDim.new(1, -24), 19,
    Color3.fromRGB(70, 225, 208), Enum.Font.GothamBold, 16)
local status = label("Status", "FINDING A MUSEUM SERVER", 12, 61,
    UDim.new(1, -24), 29, Color3.fromRGB(224, 233, 235),
    Enum.Font.GothamMedium, 10)
local footerLine = Instance.new("Frame")
footerLine.Name = "StatusLine"
footerLine.Position = UDim2.new(0, 12, 0, 93)
footerLine.Size = UDim2.new(1, -26, 0, 2)
footerLine.BorderSizePixel = 0
footerLine.BackgroundColor3 = Color3.fromRGB(60, 223, 207)
footerLine.Parent = card
local play = Instance.new("TextButton")
play.Name = "Play"
play.Position = UDim2.fromOffset(12, 100)
play.Size = UDim2.new(1, -24, 0, 29)
play.BackgroundColor3 = Color3.fromRGB(74, 235, 194)
play.TextColor3 = Color3.fromRGB(8, 15, 14)
play.Font = Enum.Font.GothamBold
play.TextSize = 14
play.Text = "PLAY / JOIN HEIST"
play.Parent = card
local playCorner = Instance.new("UICorner")
playCorner.CornerRadius = UDim.new(0, 6)
playCorner.Parent = play
play.Activated:Connect(function()
    if play.Active then controlRemote:FireServer("Start") end
end)
local footer = label("Footer", "MATCHMAKING ACTIVE", 14, 117,
    UDim.new(1, -28), 14, Color3.fromRGB(142, 187, 188),
    Enum.Font.GothamMedium, 10)
footer.Visible = false

local function button(name: string, text: string, x: number): TextButton
    local item = Instance.new("TextButton")
    item.Name = name
    item.Position = UDim2.new(x, 0, 0, 138)
    item.Size = UDim2.new(0.3, -4, 0, 28)
    item.BackgroundColor3 = Color3.fromRGB(48, 75, 79)
    item.TextColor3 = Color3.fromRGB(240, 247, 246)
    item.Font = Enum.Font.GothamBold
    item.TextScaled = true
    item.Text = text
    item.Visible = false
    item.Parent = card
    local textLimit = Instance.new("UITextSizeConstraint")
    textLimit.MaxTextSize = 11
    textLimit.MinTextSize = 8
    textLimit.Parent = item
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(0, 6)
    round.Parent = item
    return item
end

local cancel = button("Cancel", "LEAVE QUEUE", 0.05)
cancel.Activated:Connect(function()
    controlRemote:FireServer("Cancel")
end)
local retry = button("Retry", "RETRY", 0.35)
retry.Activated:Connect(function()
    controlRemote:FireServer("Retry")
end)
local invite = button("Invite", "INVITE CREW", 0.65)
invite.Activated:Connect(function()
    task.spawn(function()
        local ok, canInvite = pcall(function()
            return SocialService:CanSendGameInviteAsync(player)
        end)
        if ok and canInvite then SocialService:PromptGameInvite(player) end
    end)
end)

local expanded = false
toggle.Activated:Connect(function()
    expanded = not expanded
    card.Size = UDim2.fromOffset(236, if expanded then 172 else 135)
    toggle.Text = if expanded then "LESS" else "MORE"
    cancel.Visible = expanded
    retry.Visible = expanded
    invite.Visible = expanded
end)

local function update(message: any, waiting: any)
    local enabled = player:GetAttribute("MatchmakingEnabled") == true
    local deploying = type(message) == "string" and string.find(message, "JOINING") ~= nil
    play.Active = not enabled and not deploying
    play.AutoButtonColor = play.Active
    play.Text = if deploying then "JOINING MUSEUM..."
        elseif enabled then "MATCHMAKING ACTIVE"
        else "PLAY / JOIN HEIST"
    play.BackgroundColor3 = if play.Active then Color3.fromRGB(74, 235, 194)
        else Color3.fromRGB(48, 75, 79)
    play.TextColor3 = if play.Active then Color3.fromRGB(8, 15, 14)
        else Color3.fromRGB(240, 247, 246)
    if type(message) == "string" then
        status.Text = message
        local paused = string.find(message, "CANCELLED") ~= nil
        local preview = string.find(message, "STUDIO PREVIEW") ~= nil
        local problem = string.find(message, "FAILED") ~= nil
            or string.find(message, "UNAVAILABLE") ~= nil
            or string.find(message, "NEEDS CONFIGURATION") ~= nil
        footer.Text = if not enabled then "READY WHEN YOU ARE"
            elseif deploying then "DEPLOYING TO HEIST"
            elseif preview then "STUDIO PREVIEW"
            elseif problem then "MATCHMAKING NEEDS RETRY"
            else "MATCHMAKING ACTIVE"
        footerLine.BackgroundColor3 = if not enabled or paused or problem
            then Color3.fromRGB(217, 146, 81)
            else Color3.fromRGB(60, 223, 207)
    end
    if type(waiting) == "number" then
        count.Text = tostring(math.max(0, waiting)) .. " IN QUEUE"
    end
end
statusRemote.OnClientEvent:Connect(update)
player:GetAttributeChangedSignal("MatchStatus"):Connect(function()
    update(player:GetAttribute("MatchStatus"), player:GetAttribute("WaitingCount"))
end)
player:GetAttributeChangedSignal("MatchmakingEnabled"):Connect(function()
    update(player:GetAttribute("MatchStatus"), player:GetAttribute("WaitingCount"))
end)
update(player:GetAttribute("MatchStatus"), player:GetAttribute("WaitingCount"))
