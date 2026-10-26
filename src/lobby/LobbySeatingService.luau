--!strict
local Players = game:GetService("Players")

local LobbySeatingService = {}
local started = false

local function loungeSeat(value: Instance?): Seat?
    local lobby = workspace:FindFirstChild("HeistLobby")
    if lobby and value and value:IsA("Seat") and value.Parent == lobby
        and (value.Name == "LoungeSeat1" or value.Name == "LoungeSeat2") then
        return value
    end
    return nil
end

function LobbySeatingService.Start()
    if started then return end
    started = true
    local lobby = workspace:WaitForChild("HeistLobby")
    for _, child in lobby:GetChildren() do
        local seat = loungeSeat(child)
        if seat then
            local attachment = seat:FindFirstChild("SitPromptAttachment")
            local sitPrompt = attachment and attachment:FindFirstChild("SitPrompt")
            local standAttachment = seat:FindFirstChild("StandPromptAttachment")
            local standPrompt = standAttachment and standAttachment:FindFirstChild("StandPrompt")
            if sitPrompt and sitPrompt:IsA("ProximityPrompt")
                and standPrompt and standPrompt:IsA("ProximityPrompt") then
                local function refreshPrompt()
                    local occupied = seat.Occupant ~= nil
                    seat:SetAttribute("LoungeOccupied", occupied)
                    sitPrompt.Enabled = not occupied
                end
                seat:GetPropertyChangedSignal("Occupant"):Connect(refreshPrompt)
                refreshPrompt()
                sitPrompt.Triggered:Connect(function(player: Player)
                    if player.Parent ~= Players or seat.Occupant then return end
                    local character = player.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if not humanoid or not root or humanoid.Health <= 0
                        or humanoid.SeatPart ~= nil or (root.Position - seat.Position).Magnitude > 9 then
                        return
                    end
                    seat:Sit(humanoid)
                end)
                standPrompt.Triggered:Connect(function(player: Player)
                    local character = player.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if not humanoid or humanoid.SeatPart ~= seat or not character then return end
                    local weld = seat:FindFirstChild("SeatWeld")
                    if weld then weld:Destroy() end
                    humanoid.Sit = false
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    task.delay(0.1, function()
                        if player.Character == character and humanoid.Health > 0
                            and humanoid.SeatPart == nil then
                            character:PivotTo(CFrame.new(seat.Position.X, 3.5, 17.9))
                        end
                    end)
                end)
            end
        end
    end
end

return table.freeze(LobbySeatingService)
