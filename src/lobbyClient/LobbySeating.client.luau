--!strict
-- Roblox draws both controls. Only the local player's relevant prompt is shown.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local lobby = workspace:WaitForChild("HeistLobby", 60)
if not lobby then return end
local seat1 = lobby:WaitForChild("LoungeSeat1", 60)
local seat2 = lobby:WaitForChild("LoungeSeat2", 60)
if not seat1 or not seat2 or not seat1:IsA("Seat") or not seat2:IsA("Seat") then return end
local seats = {
    seat1,
    seat2,
}

local humanoid: Humanoid? = nil
local seatConnection: RBXScriptConnection? = nil
local seatedConnection: RBXScriptConnection? = nil

local function refresh()
    local current = humanoid and humanoid.SeatPart
    for _, seat in seats do
        local attachment = seat:WaitForChild("SitPromptAttachment")
        local sit = attachment:WaitForChild("SitPrompt") :: ProximityPrompt
        local standAttachment = seat:WaitForChild("StandPromptAttachment")
        local stand = standAttachment:WaitForChild("StandPrompt") :: ProximityPrompt
        sit.Enabled = current == nil and seat:GetAttribute("LoungeOccupied") ~= true
        stand.Enabled = current == seat
    end
end

for _, seat in seats do
    seat:GetAttributeChangedSignal("LoungeOccupied"):Connect(refresh)
end

local function watchCharacter(character: Model)
    if seatConnection then seatConnection:Disconnect() end
    if seatedConnection then seatedConnection:Disconnect() end
    humanoid = character:WaitForChild("Humanoid") :: Humanoid
    seatConnection = humanoid:GetPropertyChangedSignal("SeatPart"):Connect(refresh)
    seatedConnection = humanoid.Seated:Connect(refresh)
    refresh()
end

player.CharacterAdded:Connect(watchCharacter)
if player.Character then watchCharacter(player.Character) end
