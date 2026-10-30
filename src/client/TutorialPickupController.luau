--!strict

local TutorialPickupController = {}

function TutorialPickupController.Start(player: Player)
    task.spawn(function()
        local runtime = workspace:WaitForChild("TutorialRuntime", 20)
        if runtime == nil then return end
        local anchor = runtime:WaitForChild("TutorialPickupTarget", 10)
        local display = runtime:WaitForChild("TutorialToasterDisplay", 10)
        if anchor == nil or display == nil then return end
        local prompt = anchor:FindFirstChild("TutorialPickupPrompt")
        if prompt == nil or not prompt:IsA("ProximityPrompt") then return end
        local card = anchor:WaitForChild("TutorialStockCard", 10)
        if card == nil or not card:IsA("BillboardGui") then return end

        local function refresh()
            local visible = player:GetAttribute("TutorialPickupEligible") == true
            prompt.Enabled = visible
            card.Enabled = visible
            for _, descendant in display:GetDescendants() do
                if descendant:IsA("BasePart") then
                    descendant.LocalTransparencyModifier = if visible then 0 else 1
                end
            end
        end

        player:GetAttributeChangedSignal("TutorialPickupEligible"):Connect(refresh)
        refresh()

    end)
end

return table.freeze(TutorialPickupController)
