--!strict

-- Selected museum benches support sitting. Prompts are decorative descendants,
-- while the decision to sit is checked here on the server.
local Workspace = game:GetService("Workspace")
local CarryService = require(script.Parent.CarryService)

local SeatService = {}
local bound: {[ProximityPrompt]: boolean} = {}

local function bind(descendant: Instance)
    if not descendant:IsA("ProximityPrompt") or descendant:GetAttribute("Task11SitPrompt") ~= true then
        return
    end
    if bound[descendant] then return end
    local seat = descendant.Parent
    if not seat or not seat:IsA("Seat") or seat:GetAttribute("Task11SitOnly") ~= true then return end
    bound[descendant] = true
    local function refreshPrompt()
        descendant.Enabled = seat.Occupant == nil
    end
    seat:GetPropertyChangedSignal("Occupant"):Connect(refreshPrompt)
    refreshPrompt()
    descendant.Triggered:Connect(function(player: Player)
        if game:GetAttribute("MatchmakingEnabled") and player:GetAttribute("MatchActive") ~= true then return end
        if not seat:IsDescendantOf(Workspace) or seat.Occupant ~= nil then return end
        local character = player.Character
        local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
        local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
        if not humanoid or not root or not root:IsA("BasePart") or humanoid.Health <= 0 then return end
        if humanoid.Sit or CarryService.GetActiveCarry(player) ~= nil then return end
        if (root.Position - seat.Position).Magnitude > descendant.MaxActivationDistance + 2 then return end
        seat:Sit(humanoid)
    end)
    descendant.Destroying:Connect(function() bound[descendant] = nil end)
end

function SeatService.Start()
    for _, descendant in Workspace:GetDescendants() do bind(descendant) end
    Workspace.DescendantAdded:Connect(bind)
end

return table.freeze(SeatService)
