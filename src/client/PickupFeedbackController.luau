--!strict

local Debris = game:GetService("Debris")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
local Theme = require(script.Parent.HudTheme)

local PickupFeedbackController = {}

local TIER_COLORS = {
    Common = Theme.Accent,
    Uncommon = Color3.fromRGB(255, 207, 115),
    Rare = Color3.fromRGB(183, 153, 255),
    Legendary = Color3.fromRGB(255, 132, 198),
}

local function stockDisplay(prompt: ProximityPrompt): Model?
    local targetId = prompt:GetAttribute("PickupTargetId")
    if type(targetId) ~= "string" then return nil end
    if targetId == "depot.tutorial_pedestal" then
        local runtime = workspace:FindFirstChild("TutorialRuntime")
        local display = runtime and runtime:FindFirstChild("TutorialToasterDisplay")
        return if display and display:IsA("Model") then display else nil
    end
    local map = workspace:FindFirstChild("Map")
    local expansion = map and map:FindFirstChild("ExpansionDistrict")
    local depot = expansion and expansion:FindFirstChild("Depot")
    local runtime = depot and depot:FindFirstChild("PublicStockRuntime")
    if runtime == nil then return nil end
    for _, child in runtime:GetChildren() do
        if child:IsA("Model") and child.Name == "PublicStockDisplay_" .. targetId then
            return child
        end
    end
    return nil
end

function PickupFeedbackController.Start(player: Player)
    local activePrompt: ProximityPrompt? = nil
    local holdHighlight: Highlight? = nil
    local lastCueCarryId = player:GetAttribute("CarryId")
    local lastCueAt = -math.huge

    local function clearHold()
        activePrompt = nil
        if holdHighlight then holdHighlight:Destroy() end
        holdHighlight = nil
    end

    ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
        local display = stockDisplay(prompt)
        if display == nil then return end
        clearHold()
        activePrompt = prompt
        local highlight = Instance.new("Highlight")
        highlight.Name = "LocalPickupHoldGlow"
        highlight.Adornee = display
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.FillColor = Theme.Accent
        highlight.OutlineColor = Theme.Accent
        highlight.FillTransparency = if player:GetAttribute("LowEffects") == true then 1 else 0.88
        highlight.OutlineTransparency = 0.22
        highlight.Parent = display
        holdHighlight = highlight
    end)
    ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
        if prompt == activePrompt then clearHold() end
    end)
    ProximityPromptService.PromptHidden:Connect(function(prompt)
        if prompt == activePrompt then clearHold() end
    end)
    ProximityPromptService.PromptTriggered:Connect(function(prompt)
        if prompt == activePrompt then clearHold() end
    end)

    local function confirmPickup()
        local carryId = player:GetAttribute("CarryId")
        local itemId = player:GetAttribute("CarryItemId")
        if type(carryId) ~= "string" or carryId == ""
            or type(itemId) ~= "string" or carryId == lastCueCarryId then return end
        local item = ItemCatalog.ById[itemId]
        if item == nil then return end
        lastCueCarryId = carryId
        local now = os.clock()
        if now - lastCueAt < 0.5 then return end
        lastCueAt = now
        if player:GetAttribute("ReduceMotion") == true then return end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root == nil or not root:IsA("BasePart") then return end
        local attachment = Instance.new("Attachment")
        attachment.Name = "LocalPickupBurst"
        attachment.Position = Vector3.new(0, 1.4, 0)
        attachment.Parent = root
        local particles = Instance.new("ParticleEmitter")
        particles.Name = "PickupConfirmation"
        particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        particles.Color = ColorSequence.new(TIER_COLORS[item.tier] or Theme.Accent)
        particles.LightEmission = 0.6
        particles.Lifetime = NumberRange.new(0.25, 0.5)
        particles.Speed = NumberRange.new(2, 5)
        particles.SpreadAngle = Vector2.new(180, 180)
        particles.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.28),
            NumberSequenceKeypoint.new(1, 0),
        })
        particles.Rate = 0
        particles.Parent = attachment
        particles:Emit(if player:GetAttribute("LowEffects") == true then 2 else 7)
        Debris:AddItem(attachment, 1)
    end

    player:GetAttributeChangedSignal("CarryId"):Connect(confirmPickup)
    player:GetAttributeChangedSignal("CarryItemId"):Connect(confirmPickup)

    task.spawn(function()
        local map = workspace:WaitForChild("Map", 20)
        local expansion = map and map:WaitForChild("ExpansionDistrict", 10)
        local depot = expansion and expansion:WaitForChild("Depot", 10)
        local runtime = depot and depot:WaitForChild("PublicStockRuntime", 10)
        if runtime == nil then return end
        for _, anchor in runtime:GetChildren() do
            if anchor.Name ~= "PublicPickupTarget" then continue end
            local prompt = anchor:FindFirstChild("PublicPickupPrompt")
            if prompt == nil or not prompt:IsA("ProximityPrompt") then continue end
            local wasEnabled = prompt.Enabled
            prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
                local restocked = not wasEnabled and prompt.Enabled
                wasEnabled = prompt.Enabled
                if not restocked then return end
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root == nil or not root:IsA("BasePart")
                    or (root.Position - anchor.Position).Magnitude > 55 then return end
                task.delay(0.15, function()
                    local display = stockDisplay(prompt)
                    if display == nil or not prompt.Enabled then return end
                    local glow = Instance.new("Highlight")
                    glow.Name = "LocalRestockGlow"
                    glow.Adornee = display
                    glow.DepthMode = Enum.HighlightDepthMode.Occluded
                    glow.FillColor = Color3.fromRGB(255, 207, 115)
                    glow.OutlineColor = glow.FillColor
                    glow.FillTransparency = if player:GetAttribute("LowEffects") == true then 1 else 0.9
                    glow.OutlineTransparency = 0.35
                    glow.Parent = display
                    Debris:AddItem(glow, 0.85)
                    if player:GetAttribute("ReduceMotion") == true then return end
                    local mount = Instance.new("Attachment")
                    mount.Name = "LocalStockArrival"
                    mount.Parent = anchor
                    local shimmer = Instance.new("ParticleEmitter")
                    shimmer.Name = "RestockArrivalMotifs"
                    shimmer.Texture = "rbxasset://textures/particles/sparkles_main.dds"
                    shimmer.Color = ColorSequence.new(Color3.fromRGB(255, 207, 115))
                    shimmer.LightEmission = 0.45
                    shimmer.Lifetime = NumberRange.new(0.35, 0.6)
                    shimmer.Speed = NumberRange.new(0.8, 2)
                    shimmer.SpreadAngle = Vector2.new(100, 100)
                    shimmer.Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.22),
                        NumberSequenceKeypoint.new(1, 0),
                    })
                    shimmer.Rate = 0
                    shimmer.Parent = mount
                    shimmer:Emit(if player:GetAttribute("LowEffects") == true then 2 else 7)
                    Debris:AddItem(mount, 0.8)
                end)
            end)
        end
    end)
end

return table.freeze(PickupFeedbackController)
