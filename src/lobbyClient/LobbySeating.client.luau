--!strict
-- Roblox draws both controls. Only the local player's relevant prompt is shown.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local lobby = workspace:WaitForChild("HeistLobby")
local seats = {
    lobby:WaitForChild("LoungeSeat1") :: Seat,
    lobby:WaitForChild("LoungeSeat2") :: Seat,
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
