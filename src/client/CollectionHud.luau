--!strict

local HttpService = game:GetService("HttpService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Catalog = require(ReplicatedStorage.Shared.ItemCatalog)

local CollectionHud = {}
local CYAN = Color3.fromRGB(73, 232, 197)
local GOLD = Color3.fromRGB(244, 197, 97)
local BLUE = Color3.fromRGB(105, 175, 255)
local MUTED = Color3.fromRGB(157, 180, 178)
local WHITE = Color3.fromRGB(239, 248, 246)
local CHECK = utf8.char(10003)

local function round(parent: Instance, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local function label(parent: Instance, name: string, value: string, size: number,
    color: Color3): TextLabel
    local item = Instance.new("TextLabel")
    item.Name = name
    item.BackgroundTransparency = 1
    item.Font = Enum.Font.GothamBold
    item.Text = value
    item.TextColor3 = color
    item.TextSize = size
    item.TextTruncate = Enum.TextTruncate.AtEnd
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.Parent = parent
    return item
end

local function button(parent: Instance, name: string, title: string,
    color: Color3): TextButton
    local item = Instance.new("TextButton")
    item.Name = name
    item.BackgroundColor3 = color
    item.BorderSizePixel = 0
    item.Font = Enum.Font.GothamBold
    item.Text = title
    item.TextColor3 = Color3.fromRGB(8, 22, 23)
    item.TextSize = 11
    item.AutoButtonColor = true
    item.ZIndex = 106
    item.Parent = parent
    round(item, 5)
    return item
end

local function markSelection(control: TextButton, selected: boolean, title: string,
    color: Color3)
    control.Text = if selected then CHECK .. " " .. title else title
    control.BackgroundColor3 = if selected then color else Color3.fromRGB(62, 79, 81)
    control.TextColor3 = if selected then Color3.fromRGB(8, 22, 23) else WHITE
    control.Active = not selected
    if selected then
        local stroke = Instance.new("UIStroke")
        stroke.Name = "SelectedOutline"
        stroke.Color = WHITE
        stroke.Thickness = 2
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = control
    end
end

function CollectionHud.Start(player: Player, pane: ScrollingFrame, openCollection: () -> ())
    local remote = ReplicatedStorage:WaitForChild("Network"):WaitForChild("ArrangeExhibit") :: RemoteEvent
    local finishTutorial = ReplicatedStorage.Network:WaitForChild("FinishCollectionTutorial") :: RemoteEvent
    local function send(action: string, itemId: string?, slotId: string?)
        remote:FireServer(action, itemId, slotId, HttpService:GenerateGUID(false))
    end

    local header = Instance.new("Frame")
    header.Name = "CollectionHeader"
    header.Position = UDim2.fromOffset(10, 10)
    header.Size = UDim2.new(1, -25, 0, 112)
    header.BackgroundColor3 = Color3.fromRGB(14, 41, 44)
    header.BorderSizePixel = 0
    header.ZIndex = 104
    header.Parent = pane
    round(header, 8)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(Color3.fromRGB(15, 58, 59),
        Color3.fromRGB(9, 25, 30))
    gradient.Rotation = 20
    gradient.Parent = header
    local outline = Instance.new("UIStroke")
    outline.Color = CYAN
    outline.Transparency = 0.35
    outline.Thickness = 2
    outline.Parent = header
    local title = label(header, "Title", "MY COLLECTION", 22, WHITE)
    title.Position = UDim2.fromOffset(15, 8)
    title.Size = UDim2.new(1, -30, 0, 29)
    title.ZIndex = 105
    local count = label(header, "Capacity", "LOADING COLLECTION...", 12, CYAN)
    count.Position = UDim2.fromOffset(16, 37)
    count.Size = UDim2.new(1, -30, 0, 19)
    count.ZIndex = 105
    local tip = label(header, "Tip", "SAFE: half income  /  PUBLIC: full income  /  STORAGE: $0", 11, MUTED)
    tip.Position = UDim2.fromOffset(16, 55)
    tip.Size = UDim2.new(1, -30, 0, 18)
    tip.ZIndex = 105
    local auto = button(header, "AutoMode", "AUTO: APPROVED ITEMS", CYAN)
    auto.Position = UDim2.fromOffset(15, 79)
    auto.Size = UDim2.new(0.53, -20, 0, 26)
    local manual = button(header, "ManualMode", "MANUAL STANDS", BLUE)
    manual.Position = UDim2.new(0.53, 0, 0, 79)
    manual.Size = UDim2.new(0.47, -15, 0, 26)
    auto.Activated:Connect(function() send("Auto", nil, nil) end)
    manual.Activated:Connect(function() send("Manual", nil, nil) end)

    local guide = Instance.new("Frame")
    guide.Name = "StandRulesGuide"
    guide.Position = UDim2.fromOffset(10, 134)
    guide.Size = UDim2.new(1, -25, 0, 112)
    guide.BackgroundColor3 = Color3.fromRGB(27, 44, 57)
    guide.BorderSizePixel = 0
    guide.ZIndex = 104
    guide.Visible = false
    guide.Parent = pane
    round(guide, 7)
    local guideTitle = label(guide, "Title", "HOW YOUR STANDS WORK", 13, WHITE)
    guideTitle.Position = UDim2.fromOffset(12, 7)
    guideTitle.Size = UDim2.new(1, -48, 0, 19)
    guideTitle.ZIndex = 105
    for index, rule in {
        { heading = "SAFE", description = "One protected stand. Half income; cannot be stolen.", color = BLUE },
        { heading = "PUBLIC", description = "Two stands. Full income; stealable when raids launch.", color = GOLD },
        { heading = "SWAP", description = "Replacing an item keeps it in your collection.", color = MUTED },
    } do
        local text = label(guide, "Rule" .. tostring(index),
            rule.heading .. "  /  " .. rule.description, 10, rule.color)
        text.Position = UDim2.fromOffset(12, 28 + (index - 1) * 26)
        text.Size = UDim2.new(1, -24, 0, 24)
        text.TextWrapped = true
        text.TextTruncate = Enum.TextTruncate.None
        text.ZIndex = 105
    end
    local guideClose = button(guide, "Dismiss", "X", Color3.fromRGB(70, 94, 105))
    guideClose.Position = UDim2.new(1, -31, 0, 6)
    guideClose.Size = UDim2.fromOffset(24, 22)
    local guideDismissed = false

    local walkthrough = Instance.new("Frame")
    walkthrough.Name = "DisplayWalkthrough"
    walkthrough.Position = UDim2.fromOffset(10, 134)
    walkthrough.Size = UDim2.new(1, -25, 0, 145)
    walkthrough.BackgroundColor3 = Color3.fromRGB(19, 56, 52)
    walkthrough.BorderSizePixel = 0
    walkthrough.ZIndex = 104
    walkthrough.Visible = false
    walkthrough.Parent = pane
    round(walkthrough, 8)
    local walkTitle = label(walkthrough, "Step", "FIRST EXHIBIT  /  STEP 1 OF 3", 13, CYAN)
    walkTitle.Position = UDim2.fromOffset(12, 8)
    walkTitle.Size = UDim2.new(1, -48, 0, 20)
    walkTitle.ZIndex = 105
    local walkText = label(walkthrough, "Instruction", "", 12, WHITE)
    walkText.Position = UDim2.fromOffset(12, 32)
    walkText.Size = UDim2.new(1, -24, 0, 57)
    walkText.TextWrapped = true
    walkText.TextTruncate = Enum.TextTruncate.None
    walkText.TextYAlignment = Enum.TextYAlignment.Top
    walkText.ZIndex = 105
    local walkA = button(walkthrough, "PrimaryAction", "KEEP AUTO", CYAN)
    walkA.Position = UDim2.fromOffset(12, 100)
    walkA.Size = UDim2.new(0.33, -10, 0, 32)
    local walkB = button(walkthrough, "SecondaryAction", "CHOOSE STAND", GOLD)
    walkB.Position = UDim2.new(0.33, 4, 0, 100)
    walkB.Size = UDim2.new(0.34, -10, 0, 32)
    local walkC = button(walkthrough, "StorageAction", "STORE SAFE", BLUE)
    walkC.Position = UDim2.new(0.67, 0, 0, 100)
    walkC.Size = UDim2.new(0.33, -12, 0, 32)
    walkC.Visible = false
    local walkClose = button(walkthrough, "Dismiss", "X", Color3.fromRGB(70, 94, 105))
    walkClose.Position = UDim2.new(1, -31, 0, 6)
    walkClose.Size = UDim2.fromOffset(24, 22)
    local walkStep = 1
    local walkDismissed = false
    local walkItemId: string? = nil
    local walkSlot: string? = nil
    local walkApproved = false
    local walkChoiceSlot: string? = nil
    local walkUsedAuto = false
    local walkPendingAt = 0
    local walkReadyAt = 0
    local currentMode = "Auto"

    local screen = pane:FindFirstAncestorOfClass("ScreenGui")
    if screen == nil then return end
    local nudge = Instance.new("Frame")
    nudge.Name = "CollectionOnboardingNudge"
    nudge.AnchorPoint = Vector2.new(0.5, 1)
    nudge.Position = UDim2.new(0.5, 0, 1, -16)
    nudge.Size = UDim2.new(1, -24, 0, 96)
    nudge.BackgroundColor3 = Color3.fromRGB(15, 42, 43)
    nudge.BorderSizePixel = 0
    nudge.Visible = false
    nudge.ZIndex = 65
    nudge.Parent = screen
    round(nudge, 8)
    local nudgeLimit = Instance.new("UISizeConstraint")
    nudgeLimit.MaxSize = Vector2.new(360, 96)
    nudgeLimit.Parent = nudge
    local nudgeStroke = Instance.new("UIStroke")
    nudgeStroke.Color = CYAN
    nudgeStroke.Thickness = 2
    nudgeStroke.Parent = nudge
    local nudgeTitle = label(nudge, "Title", "NEW ITEM IN YOUR COLLECTION", 13, CYAN)
    nudgeTitle.Position = UDim2.fromOffset(12, 7)
    nudgeTitle.Size = UDim2.new(1, -82, 0, 19)
    nudgeTitle.ZIndex = 66
    local nudgeBody = label(nudge, "Instruction", "See how Auto, Manual and safe storage work.", 11, WHITE)
    nudgeBody.Position = UDim2.fromOffset(12, 28)
    nudgeBody.Size = UDim2.new(1, -24, 0, 19)
    nudgeBody.ZIndex = 66
    local nudgeOpen = button(nudge, "OpenCollection", "OPEN COLLECTION", CYAN)
    nudgeOpen.Position = UDim2.fromOffset(12, 55)
    nudgeOpen.Size = UDim2.new(1, -24, 0, 30)
    nudgeOpen.ZIndex = 67
    local nudgeClose = button(nudge, "Later", "LATER", Color3.fromRGB(70, 94, 105))
    nudgeClose.Position = UDim2.new(1, -66, 0, 6)
    nudgeClose.Size = UDim2.fromOffset(58, 21)
    nudgeClose.ZIndex = 67
    local nudgeDismissed = false
    local overlay = screen:FindFirstChild("OperationsOverlay") :: GuiObject?
    nudgeOpen.Activated:Connect(openCollection)
    nudgeClose.Activated:Connect(function()
        nudgeDismissed = true
        nudge.Visible = false
    end)
    local standInfo = Instance.new("Frame")
    standInfo.Name = "StandRulesInfo"
    standInfo.AnchorPoint = Vector2.new(0.5, 1)
    standInfo.Position = UDim2.new(0.5, 0, 1, -12)
    standInfo.Size = UDim2.new(1, -28, 0, 135)
    standInfo.BackgroundColor3 = Color3.fromRGB(15, 31, 39)
    standInfo.BorderSizePixel = 0
    standInfo.Visible = false
    standInfo.ZIndex = 70
    standInfo.Parent = screen
    round(standInfo, 9)
    local infoLimit = Instance.new("UISizeConstraint")
    infoLimit.MaxSize = Vector2.new(440, 135)
    infoLimit.Parent = standInfo
    local infoStroke = Instance.new("UIStroke")
    infoStroke.Thickness = 2
    infoStroke.Color = BLUE
    infoStroke.Parent = standInfo
    local infoTitle = label(standInfo, "Title", "PROTECTED STAND", 20, WHITE)
    infoTitle.Position = UDim2.fromOffset(18, 8)
    infoTitle.Size = UDim2.new(1, -64, 0, 28)
    infoTitle.ZIndex = 71
    local infoBody = label(standInfo, "Explanation", "", 14, WHITE)
    infoBody.Position = UDim2.fromOffset(18, 40)
    infoBody.Size = UDim2.new(1, -36, 0, 65)
    infoBody.TextWrapped = true
    infoBody.TextTruncate = Enum.TextTruncate.None
    infoBody.TextYAlignment = Enum.TextYAlignment.Top
    infoBody.ZIndex = 71
    local infoFooter = label(standInfo, "Footer", "Change items in MENU > COLLECTION", 12, MUTED)
    infoFooter.Position = UDim2.fromOffset(18, 108)
    infoFooter.Size = UDim2.new(1, -36, 0, 20)
    infoFooter.ZIndex = 71
    local infoClose = button(standInfo, "Close", "X", Color3.fromRGB(69, 90, 99))
    infoClose.Position = UDim2.new(1, -42, 0, 8)
    infoClose.Size = UDim2.fromOffset(27, 27)
    infoClose.TextColor3 = WHITE
    infoClose.ZIndex = 72
    infoClose.Activated:Connect(function() standInfo.Visible = false end)
    ProximityPromptService.PromptTriggered:Connect(function(prompt)
        local slotId = prompt:GetAttribute("StandRuleSlot")
        if slotId ~= "protected" and slotId ~= "exposed_01"
            and slotId ~= "exposed_02" then return end
        local protected = slotId == "protected"
        infoTitle.Text = if protected then "PROTECTED STAND"
            else "PUBLIC STAND " .. (if slotId == "exposed_01" then "1" else "2")
        infoTitle.TextColor3 = if protected then BLUE else GOLD
        infoStroke.Color = if protected then BLUE else GOLD
        infoBody.Text = if protected
            then "Your museum has one protected stand. Its item is safe and earns half its listed income. You can replace it with any owned item after the tutorial."
            else "Public stands earn an item's full listed income. Items here will be stealable when player raids launch. Move an item to the protected stand or storage to keep it safe."
        standInfo.Visible = true
    end)

    local pulse = TweenInfo.new(1.7, Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut, -1, true)
    local function animateGlow(instance: Instance)
        if not instance:IsA("BasePart") or instance.Name ~= "StandGlow"
            or instance:GetAttribute("GlowAnimated") then return end
        instance:SetAttribute("GlowAnimated", true)
        TweenService:Create(instance, pulse, { Transparency = 0.62 }):Play()
        local light = instance:FindFirstChild("ExhibitLight")
        if light and light:IsA("PointLight") then
            TweenService:Create(light, pulse, { Brightness = 1.35 }):Play()
        end
    end
    workspace.DescendantAdded:Connect(animateGlow)
    for _, instance in workspace:GetDescendants() do animateGlow(instance) end

    local cards: {Frame} = {}
    local function selectionConfirmed(): boolean
        if walkUsedAuto then return currentMode == "Auto" end
        if walkChoiceSlot == "storage" then return walkSlot == nil and not walkApproved end
        return walkChoiceSlot ~= nil and walkSlot == walkChoiceSlot
    end
    local function updateNudge()
        nudge.Visible = not nudgeDismissed and walkItemId ~= nil
            and player:GetAttribute("CollectionTutorialDone") ~= true
            and player:GetAttribute("CarryId") == nil
            and not pane.Visible
            and (overlay == nil or not overlay.Visible)
    end
    local function render()
        if pane.Parent == nil then return end
        for _, card in cards do card:Destroy() end
        table.clear(cards)
        local raw = player:GetAttribute("CollectionState")
        if type(raw) ~= "string" then
            pane.CanvasSize = UDim2.fromOffset(0, if guide.Visible then 260 else 135)
            return
        end
        local ok, state = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok or type(state) ~= "table" or type(state.items) ~= "table" then return end
        local mode = state.mode == "Manual" and "Manual" or "Auto"
        currentMode = mode
        walkItemId = nil
        walkSlot = nil
        walkApproved = false
        for _, entry in state.items do
            if entry.id ~= "toaster" and entry.state == "Available" then
                walkItemId = entry.id
                walkSlot = entry.slot
                walkApproved = entry.approved == true
                break
            end
        end
        walkthrough.Visible = pane.Visible and not walkDismissed
            and player:GetAttribute("CollectionTutorialDone") ~= true
            and walkItemId ~= nil
        updateNudge()
        local narrow = pane.AbsoluteSize.X < 340
        local walkHeight = if narrow then 188 else 145
        walkthrough.Size = UDim2.new(1, -25, 0, walkHeight)
        walkText.Size = UDim2.new(1, -24, 0, if narrow then 96 else 57)
        local actionY = if narrow then 142 else 100
        walkA.Position = UDim2.fromOffset(12, actionY)
        walkA.Size = if walkStep == 3 or (walkStep == 2 and walkUsedAuto)
            then UDim2.new(1, -24, 0, 32)
            else UDim2.new(0.33, -10, 0, 32)
        walkB.Position = UDim2.new(0.33, 4, 0, actionY)
        walkC.Position = UDim2.new(0.67, 0, 0, actionY)
        for _, action in { walkA, walkB, walkC } do
            action.TextSize = if narrow then 9 else 11
        end
        if walkthrough.Visible then
            local item = Catalog.ById[walkItemId :: string]
            local itemName = if item then item.name else "your item"
            local choiceName = if walkChoiceSlot == "protected" then "the protected stand"
                elseif walkChoiceSlot == "exposed_01" then "public stand 1"
                elseif walkChoiceSlot == "storage" then "safe storage"
                else "a public stand"
            walkTitle.Text = "FIRST EXHIBIT  /  STEP " .. tostring(walkStep) .. " OF 3"
            local choiceConfirmed = walkStep ~= 3 or selectionConfirmed()
            walkText.Text = if walkStep == 1
                then itemName .. (if walkSlot == "protected" then " is on your protected stand."
                    elseif walkSlot ~= nil then " is on a public stand."
                    else " is in safe storage.")
                    .. " New items fill empty public stands automatically. Keep Auto for approved items, or choose where this one goes yourself."
                elseif walkStep == 2 and walkUsedAuto then "Auto is on. Manual selection is different: tap MANUAL STANDS at the top, then choose SAFE, PUBLIC 1, PUBLIC 2 or STORAGE on each item card. A checkmark shows its current place; replacing an item keeps it owned."
                elseif walkStep == 2 then "Manual lets you choose a stand for each item. Tap Safe, Public or Storage below. The selected location will show a checkmark on the item's card. Replacing an item keeps it in your collection."
                elseif not choiceConfirmed and os.clock() - walkPendingAt >= 5
                    then "The move has not been confirmed yet. Tap RETRY MOVE, then check the item card."
                elseif not choiceConfirmed then "Saving your selection... The item card will update when the move is confirmed."
                elseif walkUsedAuto then "Auto fills public stands with your approved items. To choose later, tap MANUAL STANDS above, then tap a stand on an item card. A checkmark shows where each item is now."
                else itemName .. " is now in " .. choiceName
                    .. ". The matching card button has a checkmark. In Manual mode, tap another stand or STORE SAFE whenever you want to move it."
            walkA.Text = if walkStep == 1 then "KEEP AUTO"
                elseif walkStep == 2 then (if walkUsedAuto then "NEXT" else "SAFE STAND")
                elseif choiceConfirmed then "GOT IT" else "RETRY MOVE"
            walkB.Text = if walkStep == 1 then "CHOOSE STAND" else "PUBLIC STAND"
            walkB.Visible = walkStep ~= 3 and not walkUsedAuto
            walkC.Visible = walkStep == 2 and not walkUsedAuto
            local ready = if walkStep == 1 then true
                elseif walkStep == 2 then walkUsedAuto
                    or (mode == "Manual" and os.clock() >= walkReadyAt)
                else choiceConfirmed or os.clock() - walkPendingAt >= 5
            for _, action in { walkA, walkB, walkC } do
                action.Active = ready
                action.AutoButtonColor = ready
                action.BackgroundTransparency = if ready then 0 else 0.4
            end
        end
        local guideY = if walkthrough.Visible then 134 + walkHeight + 12 else 134
        guide.Position = UDim2.fromOffset(10, guideY)
        count.Text = tostring(state.displayCapacity or 3) .. " STANDS  /  "
            .. tostring(state.storageUsed or 0) .. "/"
            .. tostring(state.storageCapacity or 10) .. " STORAGE"
        auto.BackgroundColor3 = if mode == "Auto" then CYAN else Color3.fromRGB(70, 94, 92)
        manual.BackgroundColor3 = if mode == "Manual" then BLUE else Color3.fromRGB(70, 94, 92)
        tip.Text = if mode == "Auto"
            then "SAFE: half income  /  PUBLIC: full income  /  STORAGE: $0"
            else "Choose a safe or public stand. Replaced items stay owned."
        local y = guideY + (if guide.Visible then 124 else 0)
        local rowHeight = if mode == "Manual" then (if narrow then 150 else 132)
            else (if narrow then 112 else 96)
        for _, entry in state.items do
            local item = Catalog.ById[entry.id]
            if item == nil then continue end
            local card = Instance.new("Frame")
            card.Name = "Item_" .. entry.id
            card.Position = UDim2.fromOffset(10, y)
            card.Size = UDim2.new(1, -25, 0, rowHeight)
            card.BackgroundColor3 = Color3.fromRGB(18, 34, 37)
            card.BorderSizePixel = 0
            card.ZIndex = 104
            card.Parent = pane
            round(card, 7)
            local accent = if entry.slot == "protected" then BLUE
                elseif entry.slot ~= nil then CYAN else BLUE
            local strip = Instance.new("Frame")
            strip.Size = UDim2.fromOffset(4, rowHeight)
            strip.BackgroundColor3 = accent
            strip.BorderSizePixel = 0
            strip.ZIndex = 105
            strip.Parent = card
            local name = label(card, "ItemName", item.name, 15, WHITE)
            name.Position = UDim2.fromOffset(14, 6)
            name.Size = UDim2.new(1, if narrow then -28 else -100, 0, 23)
            if narrow then name.TextSize = 13 end
            name.ZIndex = 105
            local activeRate = if entry.slot == "protected"
                then item.baseIncomePerMinute / 2
                elseif entry.slot ~= nil then item.baseIncomePerMinute else 0
            local rate = label(card, "Income", if activeRate > 0
                then "+$" .. tostring(activeRate) .. "/MIN" else "$0 NOW", 13, accent)
            rate.Position = if narrow then UDim2.fromOffset(14, 29)
                else UDim2.new(1, -86, 0, 7)
            rate.Size = UDim2.fromOffset(if narrow then 125 else 75, 22)
            rate.TextXAlignment = if narrow then Enum.TextXAlignment.Left
                else Enum.TextXAlignment.Right
            rate.ZIndex = 105
            local status = if entry.slot == "protected" then CHECK .. " SELECTED: PROTECTED STAND  /  HALF RATE"
                elseif entry.slot == "exposed_01" then CHECK .. " SELECTED: PUBLIC STAND 1  /  FULL RATE"
                elseif entry.slot == "exposed_02" then CHECK .. " SELECTED: PUBLIC STAND 2  /  FULL RATE"
                elseif entry.state == "Missing" then "MISSING  /  DISCOVERED"
                elseif entry.state == "Discovered" then "COLLECTION INDEX ONLY"
                else CHECK .. " IN SAFE STORAGE  /  $" .. tostring(item.baseIncomePerMinute)
                    .. "/MIN IF DISPLAYED"
            local stateLine = label(card, "Status", status, 10, accent)
            stateLine.Position = UDim2.fromOffset(14, if narrow then 51 else 30)
            stateLine.Size = UDim2.new(1, -25, 0, 17)
            stateLine.ZIndex = 105
            if entry.state == "Available"
                and (player:GetAttribute("TutorialStep") or 0) >= 2 then
                if mode == "Auto" then
                    local action = if entry.slot == "protected" or entry.approved
                        then "Store" else "Allow"
                    local control = button(card, "DisplayApproval",
                        if entry.slot == "protected" then CHECK .. " SAFE STAND  /  TAP TO STORE"
                            elseif entry.slot == "exposed_01" then CHECK .. " PUBLIC 1  /  TAP TO STORE"
                            elseif entry.slot == "exposed_02" then CHECK .. " PUBLIC 2  /  TAP TO STORE"
                            elseif entry.approved then "APPROVED  /  TAP TO STORE"
                            else "ALLOW PUBLIC DISPLAY",
                        if entry.slot == "protected" then BLUE
                            elseif entry.approved then GOLD else CYAN)
                    control.Position = UDim2.fromOffset(14, if narrow then 77 else 57)
                    control.Size = UDim2.new(1, -28, 0, 28)
                    control.Activated:Connect(function() send(action, entry.id, nil) end)
                else
                    local topY = if narrow then 77 else 56
                    local bottomY = topY + 32
                    local protected = button(card, "ProtectedStand", "SAFE  /  HALF RATE", BLUE)
                    protected.Position = UDim2.fromOffset(14, topY)
                    protected.Size = UDim2.new(0.5, -20, 0, 27)
                    protected.Activated:Connect(function()
                        send("Place", entry.id, "protected")
                    end)
                    markSelection(protected, entry.slot == "protected", "SAFE  /  HALF RATE", BLUE)
                    local store = button(card, "Store", "STORE SAFE", GOLD)
                    store.Position = UDim2.new(0.5, 4, 0, topY)
                    store.Size = UDim2.new(0.5, -18, 0, 27)
                    store.Activated:Connect(function() send("Store", entry.id, nil) end)
                    markSelection(store, entry.slot == nil,
                        if entry.slot == nil then "IN SAFE STORAGE" else "STORE SAFE", BLUE)
                    for index, slotId in { "exposed_01", "exposed_02" } do
                        local control = button(card, "Stand" .. tostring(index),
                            "PUBLIC " .. tostring(index) .. "  /  FULL RATE", GOLD)
                        control.Position = if index == 1
                            then UDim2.fromOffset(14, bottomY)
                            else UDim2.new(0.5, 4, 0, bottomY)
                        control.Size = UDim2.new(0.5, if index == 1 then -20 else -18, 0, 27)
                        control.Activated:Connect(function()
                            send("Place", entry.id, slotId)
                        end)
                        markSelection(control, entry.slot == slotId,
                            "PUBLIC " .. tostring(index) .. "  /  FULL RATE", GOLD)
                        if narrow then control.TextSize = 9 end
                    end
                    if narrow then protected.TextSize = 9; store.TextSize = 9 end
                end
            end
            table.insert(cards, card)
            y += rowHeight + 8
        end
        pane.CanvasSize = UDim2.fromOffset(0, y + 10)
    end
    walkA.Activated:Connect(function()
        if walkStep == 1 then
            if currentMode ~= "Auto" then send("Auto", nil, nil) end
            walkUsedAuto = true
            walkStep = 2
        elseif walkStep == 2 and walkItemId ~= nil then
            if walkUsedAuto then
                walkStep = 3
                walkPendingAt = os.clock()
                task.delay(5, render)
            else
                walkChoiceSlot = "protected"
                walkStep = 3
                walkPendingAt = os.clock()
                if walkSlot ~= "protected" then send("Place", walkItemId, "protected") end
                task.delay(5, render)
            end
        elseif walkStep == 3 then
            if selectionConfirmed() then
                finishTutorial:FireServer()
                walkDismissed = true
                nudgeDismissed = true
            else
                walkPendingAt = os.clock()
                if walkUsedAuto then send("Auto", nil, nil)
                elseif walkItemId ~= nil then
                    if walkChoiceSlot == "storage" then send("Store", walkItemId, nil)
                    else send("Place", walkItemId, walkChoiceSlot) end
                end
                task.delay(5, render)
            end
        end
        render()
    end)
    walkB.Activated:Connect(function()
        if walkStep == 1 then
            walkStep = 2
            if currentMode ~= "Manual" then
                walkReadyAt = os.clock() + 0.35
                send("Manual", nil, nil)
            end
            render()
            task.delay(0.35, render)
        elseif walkStep == 2 and walkItemId ~= nil then
            walkChoiceSlot = "exposed_01"
            walkStep = 3
            walkPendingAt = os.clock()
            if walkSlot ~= "exposed_01" then send("Place", walkItemId, "exposed_01") end
            task.delay(5, render)
            render()
        end
    end)
    walkC.Activated:Connect(function()
        if walkStep ~= 2 or walkItemId == nil then return end
        walkChoiceSlot = "storage"
        walkStep = 3
        walkPendingAt = os.clock()
        if walkSlot ~= nil or walkApproved then send("Store", walkItemId, nil) end
        task.delay(5, render)
        render()
    end)
    walkClose.Activated:Connect(function()
        walkDismissed = true
        nudgeDismissed = true
        render()
    end)
    player:GetAttributeChangedSignal("CollectionState"):Connect(render)
    player:GetAttributeChangedSignal("CollectionTutorialDone"):Connect(render)
    player:GetAttributeChangedSignal("CarryId"):Connect(updateNudge)
    player:GetAttributeChangedSignal("TutorialStep"):Connect(render)
    pane:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
    pane:GetPropertyChangedSignal("Visible"):Connect(function()
        if pane.Visible and not guideDismissed then
            guide.Visible = true
        end
        render()
    end)
    if overlay then overlay:GetPropertyChangedSignal("Visible"):Connect(updateNudge) end
    guideClose.Activated:Connect(function()
        guideDismissed = true
        guide.Visible = false
        render()
    end)
    render()
end

return table.freeze(CollectionHud)
