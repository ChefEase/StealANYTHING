--!strict
local MatchWaitingHud = {}

function MatchWaitingHud.Start(player: Player)
    if game:GetAttribute("MatchmakingEnabled") == nil then
        task.spawn(function()
            for _ = 1, 100 do
                if game:GetAttribute("MatchmakingEnabled") ~= nil then break end
                task.wait(0.1)
            end
            if game:GetAttribute("MatchmakingEnabled") == true then
                MatchWaitingHud.Start(player)
            end
        end)
        return
    end
    if game:GetAttribute("MatchmakingEnabled") ~= true then return end
    local screen = Instance.new("ScreenGui")
    screen.Name = "MatchWaitingHud"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.DisplayOrder = 100
    screen.Parent = player:WaitForChild("PlayerGui")
    local veil = Instance.new("Frame")
    veil.Size = UDim2.fromScale(1, 1)
    veil.BackgroundColor3 = Color3.fromRGB(8, 21, 27)
    veil.BackgroundTransparency = 0.18
    veil.Parent = screen
    local message = Instance.new("TextLabel")
    message.AnchorPoint = Vector2.new(0.5, 0.5)
    message.Position = UDim2.fromScale(0.5, 0.48)
    message.Size = UDim2.new(0.85, 0, 0, 90)
    message.BackgroundTransparency = 1
    message.TextColor3 = Color3.fromRGB(225, 248, 241)
    message.Font = Enum.Font.GothamBold
    message.TextScaled = true
    message.TextWrapped = true
    message.Text = "LOADING YOUR MUSEUM"
    message.Parent = veil
    local hint = Instance.new("TextLabel")
    hint.AnchorPoint = Vector2.new(0.5, 0)
    hint.Position = UDim2.fromScale(0.5, 0.56)
    hint.Size = UDim2.new(0.85, 0, 0, 45)
    hint.BackgroundTransparency = 1
    hint.TextColor3 = Color3.fromRGB(151, 193, 184)
    hint.Font = Enum.Font.Gotham
    hint.TextScaled = true
    hint.TextWrapped = true
    hint.Text = "Your museum and progress are safe."
    hint.Parent = veil
    local function refresh()
        screen.Enabled = player:GetAttribute("MatchActive") ~= true
        local profile = player:GetAttribute("ProfileState")
        message.Text = if player:GetAttribute("MatchAdmission") == "Pending"
            then "JOINING YOUR MUSEUM SERVER"
            elseif profile == "Loading" or profile == "WaitingForSession"
            then "LOADING YOUR MUSEUM"
            elseif profile == "DataError" or profile == "ConfigurationError"
                or profile == "RetryableError" or profile == "SessionConflict"
            then "MUSEUM DATA UNAVAILABLE - REJOIN LATER"
            else "LOADING YOUR MUSEUM"
    end
    player:GetAttributeChangedSignal("MatchActive"):Connect(refresh)
    player:GetAttributeChangedSignal("MatchAdmission"):Connect(refresh)
    player:GetAttributeChangedSignal("ProfileState"):Connect(refresh)
    refresh()
end

return table.freeze(MatchWaitingHud)
