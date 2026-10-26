--!strict
local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")

local FriendInviteHud = {}

function FriendInviteHud.Start(player: Player)
    if game:GetAttribute("MatchmakingEnabled") == nil then
        task.spawn(function()
            for _ = 1, 100 do
                if game:GetAttribute("MatchmakingEnabled") ~= nil then break end
                task.wait(0.1)
            end
            if game:GetAttribute("MatchmakingEnabled") == true then
                FriendInviteHud.Start(player)
            end
        end)
        return
    end
    if game:GetAttribute("MatchmakingEnabled") ~= true then return end
    local screen = Instance.new("ScreenGui")
    screen.Name = "FriendInviteHud"
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 101
    screen.Parent = player:WaitForChild("PlayerGui")
    local button = Instance.new("TextButton")
    button.Name = "InviteFriends"
    button.AnchorPoint = Vector2.new(1, 1)
    button.Position = UDim2.new(1, -16, 1, -16)
    button.Size = UDim2.fromOffset(140, 42)
    button.BackgroundColor3 = Color3.fromRGB(37, 104, 92)
    button.TextColor3 = Color3.fromRGB(245, 255, 251)
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    button.Text = "INVITE FRIEND"
    button.Parent = screen
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    button.Activated:Connect(function()
        task.spawn(function()
            local ok, allowed = pcall(function()
                return SocialService:CanSendGameInviteAsync(Players.LocalPlayer)
            end)
            if ok and allowed then SocialService:PromptGameInvite(Players.LocalPlayer) end
        end)
    end)
end

return table.freeze(FriendInviteHud)
