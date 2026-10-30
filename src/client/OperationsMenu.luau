--!strict

local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(script.Parent.HudTheme)
local MenuEmotes = require(script.Parent.MenuEmoteConfig)

local OperationsMenu = {}
local INK = Theme.Ink
local PANEL = Theme.Panel
local ACCENT = Theme.Accent
local WHITE = Theme.Text
local MUTED = Theme.Muted
local PARCHMENT = Color3.fromRGB(215, 198, 158)
local CHART_INK = Color3.fromRGB(69, 59, 43)

local function frame(name: string, parent: Instance, color: Color3): Frame
    local item = Instance.new("Frame")
    item.Name = name
    item.BackgroundColor3 = color
    item.BorderSizePixel = 0
    item.Parent = parent
    return item
end

local function label(name: string, parent: Instance, text: string, size: number,
    color: Color3, bold: boolean?): TextLabel
    local item = Instance.new("TextLabel")
    item.Name = name
    item.BackgroundTransparency = 1
    item.Text = text
    item.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
    item.TextSize = size
    item.TextColor3 = color
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.TextYAlignment = Enum.TextYAlignment.Center
    item.TextWrapped = true
    item.Parent = parent
    return item
end

local function button(name: string, parent: Instance, title: string): TextButton
    local item = Instance.new("TextButton")
    item.Name = name
    item.BackgroundColor3 = PANEL
    item.BorderSizePixel = 0
    item.Font = Enum.Font.GothamBold
    item.Text = title
    item.TextSize = 15
    item.TextColor3 = WHITE
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.AutoButtonColor = true
    item.Parent = parent
    return item
end

local function mapParts(): { { part: BasePart, kind: string } }
    local regions = {}
    local seen: { [BasePart]: boolean } = {}
    local function add(part: Instance?, kind: string)
        if part and part:IsA("BasePart") and not seen[part] then
            seen[part] = true
            table.insert(regions, { part = part, kind = kind })
        end
    end
    local map = workspace:FindFirstChild("Map")
    if map then
        add(map:FindFirstChild("Ground"), "ground")
        local open = map:FindFirstChild("OpenRoute")
        local covered = map:FindFirstChild("CoveredRoute")
        for _, route in { covered, open } do
            if route then
                for _, item in route:GetChildren() do
                    if item:IsA("BasePart") and (item.Name:match("Path$") or item.Name:match("^WideCorner")) then
                        add(item, if route == covered then "covered" else "route")
                    end
                end
            end
        end
        local exterior = map:FindFirstChild("ExteriorDressing")
        add(exterior and exterior:FindFirstChild("ApproachPlaza"), "plaza")
        local depot = map:FindFirstChild("Depot")
        add(depot and depot:FindFirstChild("DepotPad"), "depot")
        local museum = map:FindFirstChild("Museum01")
        add(museum and museum:FindFirstChild("Floor"), "museum")
        -- Task 12 replaces the old route models with six plot routes. Keep
        -- the existing chart renderer and read the new walkable parts.
        local routes = map:FindFirstChild("Routes")
        if routes then
            for _, item in routes:GetChildren() do
                if item:IsA("BasePart") and item.Name:match("^Open%d+$") then
                    add(item, "route")
                end
            end
        end
        local plots = map:FindFirstChild("PlotSlots")
        if plots then
            for _, plot in plots:GetChildren() do
                add(plot:FindFirstChild("Origin"), "museum")
            end
        end
        local expansion = map:FindFirstChild("ExpansionDistrict")
        if expansion then
            add(expansion:FindFirstChild("Ground"), "ground")
            local newRoutes = expansion:FindFirstChild("Routes")
            if newRoutes then
                for _, item in newRoutes:GetChildren() do
                    if item:IsA("BasePart") and item.Name:match("^Open%d+$") then
                        add(item, "route")
                    end
                end
            end
            local newPlots = expansion:FindFirstChild("PlotSlots")
            if newPlots then
                for _, plot in newPlots:GetChildren() do
                    add(plot:FindFirstChild("MaximumEnvelope"), "plot")
                    add(plot:FindFirstChild("Origin"), "museum")
                end
            end
            local newDepot = expansion:FindFirstChild("Depot")
            add(newDepot and newDepot:FindFirstChild("Platform"), "depot")
        end
        local connector = map:FindFirstChild("DistrictConnector")
        if connector then
            for _, item in connector:GetChildren() do
                if item:IsA("BasePart") and item.Name:match("^Walkway") then
                    add(item, "route")
                end
            end
        end
        local owned = map:FindFirstChild("OwnedMuseums")
        if owned then
            for _, museum in owned:GetChildren() do
                add(museum:FindFirstChild("Floor", true), "museum")
            end
        end
    end
    -- Builders can tag every new walkable floor or region with this tag. It
    -- enters the map and expands its bounds without changing this UI module.
    for _, item in CollectionService:GetTagged("PlayableMapRegion") do
        if item:IsDescendantOf(workspace) then add(item, "expansion") end
    end
    return regions
end

function OperationsMenu.Start(player: Player, screen: ScreenGui)
    local toggle = button("OperationsMenuToggle", screen, "  MENU  /  M")
    toggle.AnchorPoint = Vector2.zero
    toggle.Size = UDim2.fromOffset(112, 32)
    toggle.BackgroundColor3 = INK
    toggle.TextColor3 = ACCENT
    toggle.TextSize = 12
    toggle.ZIndex = 20
    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Color = Color3.fromRGB(2, 8, 7)
    toggleStroke.Thickness = 2
    toggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    toggleStroke.Parent = toggle
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 5)
    toggleCorner.Parent = toggle

    local overlay = frame("OperationsOverlay", screen, INK)
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundTransparency = 1
    overlay.Visible = false
    overlay.Active = true
    overlay.ZIndex = 100

    local panelShadow = frame("OperationsPanelShadow", overlay, Color3.fromRGB(2, 8, 7))
    panelShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    panelShadow.Position = UDim2.new(0.5, 5, 0.5, -6)
    panelShadow.ZIndex = 100
    local panel = frame("OperationsPanel", overlay, INK)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.new(0.5, 0, 0.5, -12)
    panel.ZIndex = 101
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(2, 8, 7)
    stroke.Thickness = 3
    stroke.Parent = panel
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 6)
    panelCorner.Parent = panel

    local bar = frame("AccentBar", panel, ACCENT)
    bar.Size = UDim2.new(1, 0, 0, 3)
    bar.ZIndex = 102
    local header = label("Header", panel, "MENU", 27, WHITE, true)
    header.Position = UDim2.fromOffset(24, 14)
    header.Size = UDim2.new(1, -100, 0, 37)
    header.ZIndex = 102
    local subheader = label("Subheader", panel, "STEAL ANYTHING  /  FIELD GUIDE", 12, ACCENT, true)
    subheader.Position = UDim2.fromOffset(25, 49)
    subheader.Size = UDim2.new(1, -100, 0, 18)
    subheader.ZIndex = 102
    local close = button("Close", panel, "X")
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -20, 0, 21)
    close.Size = UDim2.fromOffset(36, 36)
    close.TextXAlignment = Enum.TextXAlignment.Center
    close.ZIndex = 103
    close.BackgroundColor3 = Color3.fromRGB(28, 49, 41)
    close.TextColor3 = WHITE
    local closeStroke = Instance.new("UIStroke")
    closeStroke.Color = Color3.fromRGB(2, 8, 7)
    closeStroke.Thickness = 2
    closeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    closeStroke.Parent = close
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = close

    local returnToLobby = button("ReturnToLobby", panel, "BACK TO LOBBY")
    returnToLobby.TextXAlignment = Enum.TextXAlignment.Center
    returnToLobby.TextSize = 12
    returnToLobby.BackgroundColor3 = Color3.fromRGB(28, 49, 41)
    returnToLobby.ZIndex = 103
    local returnCorner = Instance.new("UICorner")
    returnCorner.CornerRadius = UDim.new(0, 4)
    returnCorner.Parent = returnToLobby

    local sidebar = frame("Tabs", panel, Color3.fromRGB(11, 22, 18))
    sidebar.Position = UDim2.fromOffset(0, 80)
    sidebar.ZIndex = 102
    local tutorialShadow = frame("TutorialShadow", sidebar, Color3.fromRGB(2, 8, 7))
    tutorialShadow.ZIndex = 103
    local tutorialTab = button("TutorialTab", sidebar, "")
    tutorialTab.Position = UDim2.fromOffset(0, 20)
    tutorialTab.Size = UDim2.new(1, 0, 0, 54)
    tutorialTab.ZIndex = 104
    local tutorialStroke = Instance.new("UIStroke")
    tutorialStroke.Color = Color3.fromRGB(2, 8, 7)
    tutorialStroke.Thickness = 3
    tutorialStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    tutorialStroke.Parent = tutorialTab
    local tutorialIcon = frame("IconTile", tutorialTab, ACCENT)
    tutorialIcon.ZIndex = 105
    local tutorialGlyph = label("Icon", tutorialIcon, "?", 23, INK, true)
    tutorialGlyph.TextXAlignment = Enum.TextXAlignment.Center
    tutorialGlyph.Size = UDim2.fromScale(1, 1)
    tutorialGlyph.ZIndex = 106
    local tutorialCaption = label("Caption", tutorialTab, "TUTORIAL", 13, WHITE, true)
    tutorialCaption.ZIndex = 105

    local wardrobeShadow = frame("WardrobeShadow", sidebar, Color3.fromRGB(2, 8, 7))
    wardrobeShadow.ZIndex = 103
    local wardrobeTab = button("WardrobeTab", sidebar, "")
    wardrobeTab.ZIndex = 104
    local wardrobeStroke = Instance.new("UIStroke")
    wardrobeStroke.Color = Color3.fromRGB(2, 8, 7)
    wardrobeStroke.Thickness = 3
    wardrobeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    wardrobeStroke.Parent = wardrobeTab
    local wardrobeIcon = frame("IconTile", wardrobeTab, ACCENT)
    wardrobeIcon.ZIndex = 105
    local wardrobeGlyph = label("Icon", wardrobeIcon, "W", 19, INK, true)
    wardrobeGlyph.TextXAlignment = Enum.TextXAlignment.Center
    wardrobeGlyph.Size = UDim2.fromScale(1, 1)
    wardrobeGlyph.ZIndex = 106
    local wardrobeCaption = label("Caption", wardrobeTab, "WARDROBE", 13, WHITE, true)
    wardrobeCaption.ZIndex = 105
    local mapShadow = frame("MapShadow", sidebar, Color3.fromRGB(2, 8, 7))
    mapShadow.ZIndex = 103
    local mapTab = button("MapTab", sidebar, "")
    mapTab.Position = UDim2.fromOffset(0, 82)
    mapTab.Size = UDim2.new(1, 0, 0, 54)
    mapTab.ZIndex = 104
    local mapStroke = Instance.new("UIStroke")
    mapStroke.Color = Color3.fromRGB(2, 8, 7)
    mapStroke.Thickness = 3
    mapStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mapStroke.Parent = mapTab
    local mapIcon = frame("IconTile", mapTab, ACCENT)
    mapIcon.ZIndex = 105
    local mapGlyph = label("Icon", mapIcon, "M", 19, INK, true)
    mapGlyph.TextXAlignment = Enum.TextXAlignment.Center
    mapGlyph.Size = UDim2.fromScale(1, 1)
    mapGlyph.ZIndex = 106
    local mapCaption = label("Caption", mapTab, "MAP", 13, WHITE, true)
    mapCaption.ZIndex = 105

    local collectionShadow = frame("CollectionShadow", sidebar, Color3.fromRGB(2, 8, 7))
    collectionShadow.ZIndex = 103
    local collectionTab = button("CollectionTab", sidebar, "")
    collectionTab.ZIndex = 104
    local collectionStroke = Instance.new("UIStroke")
    collectionStroke.Color = Color3.fromRGB(2, 8, 7)
    collectionStroke.Thickness = 3
    collectionStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    collectionStroke.Parent = collectionTab
    local collectionIcon = frame("IconTile", collectionTab, ACCENT)
    collectionIcon.ZIndex = 105
    local collectionGlyph = label("Icon", collectionIcon, "C", 19, INK, true)
    collectionGlyph.TextXAlignment = Enum.TextXAlignment.Center
    collectionGlyph.Size = UDim2.fromScale(1, 1)
    collectionGlyph.ZIndex = 106
    local collectionCaption = label("Caption", collectionTab, "COLLECTION", 13, WHITE, true)
    collectionCaption.ZIndex = 105

    local travelShadow = frame("TravelShadow", sidebar, Color3.fromRGB(2, 8, 7))
    travelShadow.ZIndex = 103
    local travelTab = button("TravelTab", sidebar, "")
    travelTab.ZIndex = 104
    local travelStroke = Instance.new("UIStroke")
    travelStroke.Color = Color3.fromRGB(2, 8, 7)
    travelStroke.Thickness = 3
    travelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    travelStroke.Parent = travelTab
    local travelIcon = frame("IconTile", travelTab, ACCENT)
    travelIcon.ZIndex = 105
    local travelGlyph = label("Icon", travelIcon, "R", 19, INK, true)
    travelGlyph.TextXAlignment = Enum.TextXAlignment.Center
    travelGlyph.Size = UDim2.fromScale(1, 1)
    travelGlyph.ZIndex = 106
    local travelCaption = label("Caption", travelTab, "TRAVEL", 13, WHITE, true)
    travelCaption.ZIndex = 105

    local content = frame("Content", panel, PANEL)
    content.Position = UDim2.fromOffset(180, 80)
    content.ZIndex = 102
    local tutorialPane = frame("Tutorial", content, PANEL)
    tutorialPane.Size = UDim2.fromScale(1, 1)
    tutorialPane.ZIndex = 103

    local wardrobePane = Instance.new("ScrollingFrame")
    wardrobePane.Name = "Wardrobe"
    wardrobePane.Size = UDim2.fromScale(1, 1)
    wardrobePane.BackgroundColor3 = PANEL
    wardrobePane.BorderSizePixel = 0
    wardrobePane.ClipsDescendants = true
    wardrobePane.ScrollingDirection = Enum.ScrollingDirection.Y
    wardrobePane.ScrollBarThickness = 5
    wardrobePane.ZIndex = 103
    wardrobePane.Parent = content
    local collectionPane = Instance.new("ScrollingFrame")
    collectionPane.Name = "Collection"
    collectionPane.Size = UDim2.fromScale(1, 1)
    collectionPane.BackgroundColor3 = PANEL
    collectionPane.BorderSizePixel = 0
    collectionPane.ClipsDescendants = true
    collectionPane.ScrollingDirection = Enum.ScrollingDirection.Y
    collectionPane.ScrollBarThickness = 5
    collectionPane.ZIndex = 103
    collectionPane.Parent = content
    local travelPane = frame("Travel", content, PANEL)
    travelPane.Size = UDim2.fromScale(1, 1)
    travelPane.Visible = false
    travelPane.ZIndex = 103
    local tutorialTitle = label("Title", tutorialPane, "FIRST HEIST", 24, WHITE, true)
    tutorialTitle.Position = UDim2.fromOffset(26, 24)
    tutorialTitle.Size = UDim2.new(1, -52, 0, 36)
    tutorialTitle.ZIndex = 104
    local tutorialIntro = label("Intro", tutorialPane,
        "Practice the depot-to-museum route. Your saved collection and rewards stay intact.",
        15, MUTED)
    tutorialIntro.Position = UDim2.fromOffset(26, 71)
    tutorialIntro.Size = UDim2.new(1, -52, 0, 70)
    tutorialIntro.TextYAlignment = Enum.TextYAlignment.Top
    tutorialIntro.ZIndex = 104
    local heroBackdrop = frame("HeroBackdrop", tutorialPane, Color3.fromRGB(24, 74, 58))
    heroBackdrop.ZIndex = 103
    local heroCorner = Instance.new("UICorner")
    heroCorner.CornerRadius = UDim.new(1, 0)
    heroCorner.Parent = heroBackdrop
    local hero = Instance.new("ViewportFrame")
    hero.Name = "PlayerPreview"
    hero.BackgroundTransparency = 1
    hero.Ambient = Color3.fromRGB(180, 214, 196)
    hero.LightColor = Color3.fromRGB(240, 255, 245)
    hero.LightDirection = Vector3.new(-1, -1, -1)
    hero.ZIndex = 104
    hero.Parent = tutorialPane
    local heroWorld = Instance.new("WorldModel")
    heroWorld.Parent = hero
    local heroCamera = Instance.new("Camera")
    heroCamera.FieldOfView = 40
    heroCamera.Parent = hero
    hero.CurrentCamera = heroCamera
    local heroAnimator: Animator? = nil
    local heroModel: Model? = nil
    local heroTrack: AnimationTrack? = nil
    local function resetHeroPose()
        -- Neutral stance, head facing forward, between emotes.
        local model = heroModel
        if model == nil then return end
        for _, joint in model:GetDescendants() do
            if joint:IsA("Motor6D") then joint.Transform = CFrame.identity end
        end
    end
    local function updateHero()
        if heroTrack then heroTrack:Stop(0) end
        heroTrack = nil
        heroAnimator = nil
        heroModel = nil
        heroWorld:ClearAllChildren()
        local character = player.Character
        if character == nil then return end
        local wasArchivable = character.Archivable
        character.Archivable = true
        local clone = character:Clone()
        character.Archivable = wasArchivable
        if clone == nil then return end
        for _, item in clone:GetDescendants() do
            if item:IsA("Script") or item:IsA("LocalScript") then item:Destroy() end
        end
        clone:PivotTo(CFrame.new(0, 0, 0))
        local cloneRoot = clone:FindFirstChild("HumanoidRootPart")
        if cloneRoot and cloneRoot:IsA("BasePart") then cloneRoot.Anchored = true end
        clone.Parent = heroWorld
        local humanoid = clone:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator == nil then
                animator = Instance.new("Animator")
                animator.Parent = humanoid
            end
            heroAnimator = animator
        end
        heroModel = clone
        resetHeroPose()
        local center, bounds = clone:GetBoundingBox()
        heroCamera.CFrame = CFrame.lookAt(center.Position
            + Vector3.new(0, bounds.Y * 0.06, -bounds.Y * 1.55), center.Position)
    end
    player.CharacterAdded:Connect(function()
        task.delay(1, updateHero)
    end)
    task.defer(updateHero)
    task.spawn(function()
        local ids = {}
        for _, id in MenuEmotes.ANIMATION_IDS do
            if type(id) == "number" and id > 0 then table.insert(ids, id) end
        end
        if #ids == 0 then return end
        local bag: { number } = {}
        local lastId = 0
        while screen.Parent do
            if not overlay.Visible or not tutorialPane.Visible then
                task.wait(0.2)
                continue
            end
            local animator = heroAnimator
            if animator == nil or animator.Parent == nil then
                task.wait(0.2)
                continue
            end
            if #bag == 0 then
                -- Play every emote once in random order before repeating any.
                for _, id in ids do table.insert(bag, id) end
                for index = #bag, 2, -1 do
                    local swap = math.random(index)
                    bag[index], bag[swap] = bag[swap], bag[index]
                end
                if #bag > 1 and bag[#bag] == lastId then
                    bag[1], bag[#bag] = bag[#bag], bag[1]
                end
            end
            local id = table.remove(bag) :: number
            lastId = id
            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://" .. id
            local ok, track = pcall(function()
                return animator:LoadAnimation(animation)
            end)
            if not ok or track == nil then
                warn("[Steal Anything] Menu emote failed to load: " .. id)
                task.wait(MenuEmotes.INTERVAL_SECONDS)
                continue
            end
            heroTrack = track
            track.Looped = false
            track:Play(0.2)
            local started = os.clock()
            while track.IsPlaying and heroTrack == track
                and overlay.Visible and tutorialPane.Visible
                and os.clock() - started < MenuEmotes.MAX_PLAY_SECONDS do
                task.wait(0.1)
            end
            if heroTrack == track then
                track:Stop(0.3)
                task.wait(0.35)
                heroTrack = nil
                resetHeroPose()
            end
            track:Destroy()
            task.wait(MenuEmotes.INTERVAL_SECONDS)
        end
    end)
    local playerChip = frame("PlayerChip", panel, PANEL)
    playerChip.ZIndex = 102
    local playerName = label("PlayerName", playerChip, player.DisplayName, 11, WHITE, true)
    playerName.Position = UDim2.fromOffset(8, 0)
    playerName.Size = UDim2.new(1, -16, 0, 17)
    playerName.ZIndex = 103
    local cashLabel = label("Cash", playerChip, "$---", 12, ACCENT, true)
    cashLabel.Position = UDim2.fromOffset(8, 17)
    cashLabel.Size = UDim2.new(1, -16, 0, 17)
    cashLabel.ZIndex = 103
    local function updateCash()
        local cash = player:GetAttribute("Cash")
        cashLabel.Text = if type(cash) == "number" then "$" .. tostring(math.floor(cash)) else "$---"
    end
    player:GetAttributeChangedSignal("Cash"):Connect(updateCash)
    updateCash()
    local routeMode = frame("RouteMode", tutorialPane, INK)
    routeMode.ZIndex = 104
    local routeTitle = label("Title", routeMode, "PRACTICE RUN", 12, WHITE, true)
    routeTitle.Position = UDim2.fromOffset(10, 2)
    routeTitle.Size = UDim2.new(1, -20, 0, 22)
    routeTitle.ZIndex = 105
    local routeDetail = label("Detail", routeMode, "DEPOT  >  MUSEUM", 11, ACCENT, true)
    routeDetail.Position = UDim2.fromOffset(10, 23)
    routeDetail.Size = UDim2.new(1, -20, 0, 20)
    routeDetail.ZIndex = 105
    local steps = frame("RouteSteps", tutorialPane, PANEL)
    steps.BackgroundTransparency = 1
    steps.ZIndex = 104
    local stepCards = {}
    for index, title in { "GO TO THE DEPOT", "PICK UP THE TOASTER", "DELIVER AT YOUR MUSEUM" } do
        local card = frame("Step" .. index, steps, Color3.fromRGB(28, 49, 41))
        card.ZIndex = 105
        local number = label("Number", card, string.format("%02d", index), 15, ACCENT, true)
        number.Position = UDim2.fromOffset(9, 0)
        number.Size = UDim2.fromOffset(28, 28)
        number.ZIndex = 106
        local caption = label("Caption", card, title, 13, WHITE, true)
        caption.Position = UDim2.fromOffset(39, 0)
        caption.Size = UDim2.new(1, -45, 1, 0)
        caption.ZIndex = 106
        table.insert(stepCards, { card = card, number = number, caption = caption })
    end
    local replayShadow = frame("ReplayShadow", tutorialPane, Color3.fromRGB(2, 8, 7))
    replayShadow.ZIndex = 104
    local replay = button("Replay", tutorialPane, "START PRACTICE ROUTE  >")
    replay.Position = UDim2.new(0, 26, 1, -75)
    replay.Size = UDim2.new(1, -52, 0, 46)
    replay.BackgroundColor3 = ACCENT
    replay.TextColor3 = INK
    replay.TextXAlignment = Enum.TextXAlignment.Center
    replay.ZIndex = 105
    local replayStroke = Instance.new("UIStroke")
    replayStroke.Color = Color3.fromRGB(2, 8, 7)
    replayStroke.Thickness = 3
    replayStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    replayStroke.Parent = replay
    local replayCorner = Instance.new("UICorner")
    replayCorner.CornerRadius = UDim.new(0, 4)
    replayCorner.Parent = replay

    local mapPane = frame("Map", content, PANEL)
    mapPane.Size = UDim2.fromScale(1, 1)
    mapPane.Visible = false
    mapPane.ZIndex = 103
    local mapTitle = label("Title", mapPane, "DISTRICT MAP", 24, WHITE, true)
    mapTitle.Position = UDim2.fromOffset(18, 14)
    mapTitle.Size = UDim2.new(1, -36, 0, 31)
    mapTitle.ZIndex = 104
    local mapHint = label("Hint", mapPane, "NORTH  /  LIVE PLAYABLE AREA", 11, ACCENT, true)
    mapHint.Position = UDim2.new(1, -230, 0, 18)
    mapHint.Size = UDim2.fromOffset(210, 26)
    mapHint.TextXAlignment = Enum.TextXAlignment.Right
    mapHint.ZIndex = 104
    local canvas = frame("MapCanvas", mapPane, PARCHMENT)
    canvas.Position = UDim2.fromOffset(18, 54)
    canvas.Size = UDim2.new(1, -36, 1, -99)
    canvas.ClipsDescendants = true
    canvas.Active = true
    canvas.ZIndex = 104
    local chartBorder = Instance.new("UIStroke")
    chartBorder.Color = Color3.fromRGB(128, 99, 60)
    chartBorder.Thickness = 2
    chartBorder.Parent = canvas
    local legend = label("Legend", mapPane, "YOU  ◆    MUSEUM  ■    DEPOT  ■    ROUTES  ━", 11, MUTED, true)
    legend.Position = UDim2.new(0, 18, 1, -37)
    legend.Size = UDim2.new(1, -36, 0, 26)
    legend.ZIndex = 104
    legend.TextColor3 = MUTED

    local mapControls = frame("MapControls", mapPane, PANEL)
    mapControls.BackgroundTransparency = 1
    mapControls.ZIndex = 104
    local mapButtons = {}
    for _, spec in {
        { name = "FocusYou", title = "YOU" },
        { name = "FocusOriginal", title = "OLD" },
        { name = "FocusPlots", title = "PLAZA" },
        { name = "ZoomOut", title = "-" },
        { name = "ZoomIn", title = "+" },
    } do
        local item = button(spec.name, mapControls, spec.title)
        item.TextXAlignment = Enum.TextXAlignment.Center
        item.TextSize = 11
        item.BackgroundColor3 = INK
        item.TextColor3 = WHITE
        item.ZIndex = 105
        local outline = Instance.new("UIStroke")
        outline.Color = Theme.Outline
        outline.Thickness = 1
        outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        outline.Parent = item
        table.insert(mapButtons, item)
    end

    local activeTab = "Tutorial"
    local layout: () -> ()
    local drawMap: () -> ()
    local mapCenter = Vector2.new(60, 0)
    local mapZoom = 1.25
    local mapFocused = false
    local function setTab(tab: string)
        activeTab = tab
        tutorialPane.Visible = tab == "Tutorial"
        wardrobePane.Visible = tab == "Wardrobe"
        mapPane.Visible = tab == "Map"
        collectionPane.Visible = tab == "Collection"
        travelPane.Visible = tab == "Travel"
        tutorialTab.BackgroundColor3 = if tab == "Tutorial" then Theme.Selected else PANEL
        wardrobeTab.BackgroundColor3 = if tab == "Wardrobe" then Theme.Selected else PANEL
        mapTab.BackgroundColor3 = if tab == "Map" then Theme.Selected else PANEL
        collectionTab.BackgroundColor3 = if tab == "Collection" then Theme.Selected else PANEL
        travelTab.BackgroundColor3 = if tab == "Travel" then Theme.Selected else PANEL
        tutorialCaption.TextColor3 = if tab == "Tutorial" then WHITE else MUTED
        wardrobeCaption.TextColor3 = if tab == "Wardrobe" then WHITE else MUTED
        mapCaption.TextColor3 = if tab == "Map" then WHITE else MUTED
        collectionCaption.TextColor3 = if tab == "Collection" then WHITE else MUTED
        travelCaption.TextColor3 = if tab == "Travel" then WHITE else MUTED
        layout()
    end

    local function placeToggle()
        local area = screen.AbsoluteSize
        local w, h = toggle.AbsoluteSize.X, toggle.AbsoluteSize.Y
        local maxY = math.min(175, area.Y - h - 12)
        local obstacles = {}
        for _, item in screen:GetChildren() do
            if item:IsA("GuiObject") and item ~= toggle and item ~= overlay and item.Visible
                and item.AbsoluteSize.X > 0 and item.AbsoluteSize.Y > 0 then
                table.insert(obstacles, item)
            end
        end
        local function clear(x: number, y: number): boolean
            for _, item in obstacles do
                local p, s = item.AbsolutePosition, item.AbsoluteSize
                if x < p.X + s.X + 18 and p.X - 18 < x + w
                    and y < p.Y + s.Y + 18 and p.Y - 18 < y + h then
                    return false
                end
            end
            return true
        end
        for y = 18, maxY, 12 do
            for x = area.X - w - 16, 16, -12 do
                if clear(x, y) then
                    toggle.Position = UDim2.fromOffset(x, y)
                    return
                end
            end
        end
        toggle.Position = UDim2.fromOffset(math.max(12, area.X - w - 12),
            math.max(12, math.min(maxY, 112)))
    end

    layout = function()
        local window = screen.AbsoluteSize
        local touch = player.PlayerGui:FindFirstChild("TouchGui") ~= nil
        local landscapePhone = touch and window.Y < 500
        local narrow = window.X < 620
        local showingMap = activeTab == "Map"
        local width = math.min(940, math.max(300, window.X - 24))
        local height = math.min(650, math.max(240, window.Y - 24))
        local tabWidth = if showingMap then (if width < 600 then 104 else 125)
            elseif width < 530 then 104 else 148
        local compact = height < 330
        local headerHeight = if showingMap then 46 elseif compact then 58 else 72
        panel.Size = UDim2.fromOffset(width, height)
        panelShadow.Size = panel.Size
        toggle.Size = UDim2.fromOffset(112, if touch then 44 else 34)
        toggle.Text = if touch then "  MENU" else "  MENU  /  M"
        sidebar.Position = UDim2.fromOffset(0, headerHeight)
        sidebar.Size = UDim2.fromOffset(tabWidth, height - headerHeight)
        content.Position = UDim2.fromOffset(tabWidth, headerHeight)
        content.Size = UDim2.fromOffset(width - tabWidth, height - headerHeight)
        header.Position = UDim2.fromOffset(18, if compact then 4 else 10)
        header.TextSize = if compact then 21 else 25
        subheader.Position = UDim2.fromOffset(19, if compact then 35 else 44)
        close.Position = UDim2.new(1, -14, 0, if compact then 11 else 17)
        close.Size = UDim2.fromOffset(if touch then 44 else 36,
            if touch then 44 else 36)
        returnToLobby.Position = UDim2.new(1, if width < 530 then -170 else -288,
            0, if compact then 11 else 17)
        returnToLobby.Size = UDim2.fromOffset(if width < 530 then 114 else 130,
            if touch then 44 else 36)
        returnToLobby.TextSize = if width < 530 then 10 else 12
        playerChip.Position = UDim2.new(1, -158, 0, if compact then 10 else 17)
        playerChip.Size = UDim2.fromOffset(96, 37)
        playerChip.Visible = width >= 530
        local tabHeight = math.clamp(math.floor((height - headerHeight - 24) / 5) - 5, 28, 50)
        local tabGap = if compact then 5 else 7
        local tabStart = if compact then 4 else 12
        local offsets = {}
        for index = 1, 5 do
            offsets[index] = tabStart + (index - 1) * (tabHeight + tabGap)
        end
        tutorialTab.Position = UDim2.fromOffset(7, offsets[1])
        tutorialTab.Size = UDim2.new(1, -15, 0, tabHeight)
        wardrobeTab.Position = UDim2.fromOffset(7, offsets[2])
        wardrobeTab.Size = tutorialTab.Size
        mapTab.Position = UDim2.fromOffset(7, offsets[3])
        mapTab.Size = tutorialTab.Size
        collectionTab.Position = UDim2.fromOffset(7, offsets[4])
        collectionTab.Size = tutorialTab.Size
        travelTab.Position = UDim2.fromOffset(7, offsets[5])
        travelTab.Size = tutorialTab.Size
        tutorialShadow.Position = UDim2.fromOffset(10, offsets[1] + 4)
        tutorialShadow.Size = tutorialTab.Size
        wardrobeShadow.Position = UDim2.fromOffset(10, offsets[2] + 4)
        wardrobeShadow.Size = wardrobeTab.Size
        mapShadow.Position = UDim2.fromOffset(10, offsets[3] + 4)
        mapShadow.Size = mapTab.Size
        collectionShadow.Position = UDim2.fromOffset(10, offsets[4] + 4)
        collectionShadow.Size = collectionTab.Size
        travelShadow.Position = UDim2.fromOffset(10, offsets[5] + 4)
        travelShadow.Size = travelTab.Size
        local iconSize = if compact then 22 else math.min(34, tabHeight - 8)
        for _, icon in { tutorialIcon, wardrobeIcon, mapIcon, collectionIcon, travelIcon } do
            icon.Position = UDim2.fromOffset(7, (tabHeight - iconSize) / 2)
            icon.Size = UDim2.fromOffset(iconSize, iconSize)
        end
        for _, caption in { tutorialCaption, wardrobeCaption, mapCaption, collectionCaption, travelCaption } do
            caption.Position = UDim2.fromOffset(iconSize + 12, 0)
            caption.Size = UDim2.new(1, -iconSize - 14, 1, 0)
            caption.TextSize = if width < 530 then 10 else 13
        end
        local bodyHeight = height - headerHeight
        tutorialTitle.Position = UDim2.fromOffset(18, if compact then 5 else 14)
        tutorialTitle.Size = UDim2.new(1, -36, 0, if compact then 27 else 34)
        tutorialTitle.Text = if width < 530 then "FIRST HEIST" else "FIRST HEIST / PRACTICE"
        tutorialTitle.TextSize = if width < 530 then 16 elseif compact then 17 else 21
        tutorialIntro.Position = UDim2.fromOffset(18, if compact then 34 else 55)
        tutorialIntro.Size = UDim2.new(1, -36, 0, if compact then 43 else 58)
        tutorialIntro.TextSize = if compact or width < 530 then 12 else 13
        tutorialIntro.Text = if compact then
            "Practice the route again. Your saved rewards stay intact."
            else "Take the toaster from the depot to your museum again. Your saved collection and rewards stay intact."
        local stepsY = if compact then 84 else 128
        local buttonY = bodyHeight - (if compact then 48 else 62)
        local stepsHeight = math.max(22, buttonY - stepsY - 8)
        steps.Position = UDim2.fromOffset(18, stepsY)
        steps.Size = UDim2.new(1, -36, 0, stepsHeight)
        steps.Visible = bodyHeight >= 160
        local horizontalSteps = compact or stepsHeight < 88
        for index, item in stepCards do
            if horizontalSteps then
                local segment = (width - tabWidth - 36 - 12) / 3
                item.card.Position = UDim2.fromOffset((index - 1) * (segment + 6), 0)
                item.card.Size = UDim2.fromOffset(segment, 34)
                item.number.Position = UDim2.fromOffset(6, 0)
                item.number.Size = UDim2.fromOffset(21, 34)
                item.number.TextSize = 11
                item.caption.Position = UDim2.fromOffset(26, 0)
                item.caption.Size = UDim2.new(1, -29, 1, 0)
                item.caption.Text = ({ "DEPOT", "PICK UP", "DELIVER" })[index]
                item.caption.TextSize = 10
            else
                local rowHeight = math.min(34, (stepsHeight - 10) / 3)
                item.card.Position = UDim2.fromOffset(0, (index - 1) * (rowHeight + 5))
                item.card.Size = UDim2.new(1, 0, 0, rowHeight)
                item.number.Position = UDim2.fromOffset(9, 0)
                item.number.Size = UDim2.fromOffset(28, rowHeight)
                item.number.TextSize = 13
                item.caption.Position = UDim2.fromOffset(39, 0)
                item.caption.Size = UDim2.new(1, -45, 1, 0)
                item.caption.Text = ({ "GO TO THE DEPOT", "PICK UP THE TOASTER", "DELIVER AT YOUR MUSEUM" })[index]
                item.caption.TextSize = if width < 530 then 11 else 13
            end
        end
        replay.Position = UDim2.fromOffset(18, buttonY)
        replay.Size = UDim2.new(1, -36, 0, if touch then 44 elseif compact then 34 else 42)
        replayShadow.Position = UDim2.fromOffset(21, buttonY + 4)
        replayShadow.Size = replay.Size
        replay.TextSize = if width < 530 then 12 else 14
        local bodyWidth = width - tabWidth
        if not showingMap then
            local heroSize = math.min(250, math.max(125, bodyHeight - 62))
            heroBackdrop.Position = UDim2.fromOffset((bodyWidth - heroSize) / 2, 17)
            heroBackdrop.Size = UDim2.fromOffset(heroSize, heroSize)
            hero.Position = UDim2.fromOffset((bodyWidth - heroSize) / 2, 13)
            hero.Size = UDim2.fromOffset(heroSize, heroSize + 8)
            tutorialTitle.Position = UDim2.fromOffset(18, 10)
            tutorialTitle.Size = UDim2.fromOffset(math.max(115, bodyWidth * 0.34), 29)
            tutorialTitle.Text = "FIRST HEIST"
            tutorialTitle.TextSize = 18
            tutorialIntro.Position = UDim2.fromOffset(18, 44)
            tutorialIntro.Size = UDim2.fromOffset(math.max(115, bodyWidth * 0.29), 100)
            tutorialIntro.Text = "Take the toaster from the depot and bring it home."
            tutorialIntro.TextSize = 12
            steps.Visible = false
            if bodyWidth >= 320 then
                local leftWidth = math.floor(bodyWidth * 0.5) - 22
                routeMode.Position = UDim2.fromOffset(18, bodyHeight - 63)
                routeMode.Size = UDim2.fromOffset(leftWidth, 47)
                replay.Position = UDim2.fromOffset(leftWidth + 31, bodyHeight - 63)
                replay.Size = UDim2.fromOffset(bodyWidth - leftWidth - 49, 47)
            else
                routeMode.Position = UDim2.fromOffset(14, bodyHeight - 111)
                routeMode.Size = UDim2.new(1, -28, 0, 42)
                replay.Position = UDim2.fromOffset(14, bodyHeight - 61)
                replay.Size = UDim2.new(1, -28, 0, 46)
            end
            replayShadow.Position = UDim2.fromOffset(replay.Position.X.Offset + 3,
                replay.Position.Y.Offset + 4)
            replayShadow.Size = replay.Size
            replay.Text = "PLAY  /  PRACTICE"
        end
        mapTitle.Position = UDim2.fromOffset(14, if compact then 4 else 12)
        mapTitle.TextSize = if compact then 18 else 21
        mapHint.Position = UDim2.new(1, -185, 0, if compact then 6 else 16)
        mapHint.Size = UDim2.fromOffset(170, 22)
        mapHint.TextSize = if compact then 9 else 10
        mapHint.Visible = not compact and width >= 530
        canvas.Position = UDim2.fromOffset(14, if compact then 32 else 50)
        canvas.Size = UDim2.new(1, -28, 1, if showingMap then (if compact then -94 else -110)
            elseif compact then -58 else -86)
        legend.Position = UDim2.new(0, 14, 1, if showingMap then -31 elseif compact then -24 else -32)
        legend.TextSize = if compact then 9 else 11
        mapControls.Position = UDim2.new(0, 14, 1, -61)
        mapControls.Size = UDim2.new(1, -28, 0, 28)
        local controlWidth = math.min(66, math.max(44, (width - tabWidth - 72) / 5))
        for index, item in mapButtons do
            item.Position = UDim2.fromOffset((index - 1) * (controlWidth + 5), 0)
            item.Size = UDim2.fromOffset(controlWidth, 26)
        end
        legend.Text = "DRAG TO PAN  /  SCROLL OR +/- TO ZOOM"
        if showingMap then
            subheader.Visible = false
            mapTitle.Position = UDim2.fromOffset(14, 1)
            mapTitle.Size = UDim2.new(1, -28, 0, 24)
            canvas.Position = UDim2.fromOffset(14, 28)
            canvas.Size = UDim2.new(1, -28, 1, -65)
            mapControls.Position = UDim2.new(0, 14, 1, -31)
            legend.Visible = false
        else
            subheader.Visible = true
            legend.Visible = true
        end
        placeToggle()
    end

    drawMap = function()
        if not overlay.Visible or activeTab ~= "Map" then return end
        for _, child in canvas:GetChildren() do
            if child ~= chartBorder then child:Destroy() end
        end
        local regions = mapParts()
        if #regions == 0 or canvas.AbsoluteSize.X < 40 then return end
        local area = canvas.AbsoluteSize
        if not mapFocused then
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                mapCenter = Vector2.new(root.Position.X, root.Position.Z)
                mapFocused = true
            end
        end
        local scale = math.min(area.X / 480, area.Y / 260) * mapZoom
        local minX = mapCenter.X - area.X / (2 * scale)
        local maxX = mapCenter.X + area.X / (2 * scale)
        local minZ = mapCenter.Y - area.Y / (2 * scale)
        local maxZ = mapCenter.Y + area.Y / (2 * scale)
        local function point(x: number, z: number): Vector2
            return Vector2.new(area.X / 2 + (x - mapCenter.X) * scale,
                area.Y / 2 - (z - mapCenter.Y) * scale)
        end
        local colors = {
            ground = Color3.fromRGB(207, 190, 150),
            covered = Color3.fromRGB(122, 105, 78),
            route = Color3.fromRGB(154, 128, 89),
            plaza = Color3.fromRGB(179, 151, 109),
            depot = Color3.fromRGB(115, 73, 49),
            museum = Color3.fromRGB(91, 77, 58),
            plot = Color3.fromRGB(191, 174, 137),
            expansion = Color3.fromRGB(185, 164, 123),
        }
        local function drawRegion(region)
            local part = region.part
            local middle = point(part.Position.X, part.Position.Z)
            local shape = frame(part.Name, canvas, colors[region.kind] or colors.expansion)
            shape.AnchorPoint = Vector2.new(0.5, 0.5)
            shape.Position = UDim2.fromOffset(middle.X, middle.Y)
            shape.Size = UDim2.fromOffset(math.max(2, part.Size.X * scale),
                math.max(2, part.Size.Z * scale))
            shape.Rotation = math.deg(math.atan2(-part.CFrame.RightVector.Z,
                part.CFrame.RightVector.X))
            shape.ZIndex = if region.kind == "ground" then 105
                elseif region.kind == "plot" then 106 else 107
            if region.kind == "plot" then
                local rounded = Instance.new("UICorner")
                rounded.CornerRadius = UDim.new(1, 0)
                rounded.Parent = shape
                shape.BackgroundTransparency = 0.18
            end
        end
        for _, region in regions do
            if region.kind == "ground" then drawRegion(region) end
        end
        for _, region in regions do
            if region.kind == "plot" then drawRegion(region) end
        end
        local gridStep = 100
        for x = math.floor(minX / gridStep) * gridStep, maxX, gridStep do
            local px = point(x, minZ).X
            local line = frame("ChartGrid", canvas, CHART_INK)
            line.Position = UDim2.fromOffset(px, 0)
            line.Size = UDim2.fromOffset(1, area.Y)
            line.BackgroundTransparency = 0.74
            line.ZIndex = 106
            local coord = label("GridLetter", canvas,
                string.char(65 + (math.floor(x / gridStep) % 26)), 11, CHART_INK, true)
            coord.Font = Enum.Font.Garamond
            coord.Position = UDim2.fromOffset(px + 3, 2)
            coord.Size = UDim2.fromOffset(22, 18)
            coord.ZIndex = 108
        end
        for z = math.floor(minZ / gridStep) * gridStep, maxZ, gridStep do
            local py = point(minX, z).Y
            local line = frame("ChartGrid", canvas, CHART_INK)
            line.Position = UDim2.fromOffset(0, py)
            line.Size = UDim2.fromOffset(area.X, 1)
            line.BackgroundTransparency = 0.74
            line.ZIndex = 106
            local coord = label("GridNumber", canvas, tostring(math.floor(z / gridStep)),
                11, CHART_INK, true)
            coord.Font = Enum.Font.Garamond
            coord.Position = UDim2.fromOffset(4, py + 2)
            coord.Size = UDim2.fromOffset(32, 18)
            coord.ZIndex = 108
        end
        for _, region in regions do
            if region.kind ~= "ground" and region.kind ~= "plot" then drawRegion(region) end
        end
        local compass = label("Compass", canvas, "N  ◆", 19, CHART_INK, true)
        compass.Font = Enum.Font.Garamond
        compass.TextXAlignment = Enum.TextXAlignment.Right
        compass.Position = UDim2.new(1, -66, 0, 4)
        compass.Size = UDim2.fromOffset(57, 27)
        compass.ZIndex = 109
        local map = workspace:FindFirstChild("Map")
        for _, spec in {
            { name = "DEPOT", model = map and map:FindFirstChild("Depot"), color = CHART_INK },
            { name = "ORIGINAL MUSEUM", model = map and map:FindFirstChild("Museum01"), color = CHART_INK },
            { name = "DISTRICT DEPOT", model = map and map:FindFirstChild("ExpansionDistrict")
                and map.ExpansionDistrict:FindFirstChild("Depot"), color = CHART_INK },
        } do
            local model = spec.model
            if model and model:IsA("Model") then
                local p = model:GetPivot().Position
                local loc = point(p.X, p.Z)
                local tag = label(spec.name, canvas, spec.name, 11, spec.color, true)
                tag.Font = Enum.Font.Garamond
                tag.Position = UDim2.fromOffset(loc.X + 5, loc.Y - 10)
                tag.Size = UDim2.fromOffset(90, 20)
                tag.ZIndex = 108
            end
        end
        local expansion = map and map:FindFirstChild("ExpansionDistrict")
        local plotSlots = expansion and expansion:FindFirstChild("PlotSlots")
        if plotSlots then
            for _, plot in plotSlots:GetChildren() do
                local origin = plot:FindFirstChild("Origin")
                if origin and origin:IsA("BasePart") then
                    local loc = point(origin.Position.X, origin.Position.Z)
                    local number = plot.Name:match("%d+$") or "?"
                    local tag = label("Plot" .. number, canvas, "MUSEUM " .. number,
                        12, CHART_INK, true)
                    tag.Font = Enum.Font.Garamond
                    tag.Position = UDim2.fromOffset(loc.X - 30, loc.Y - 9)
                    tag.Size = UDim2.fromOffset(86, 18)
                    tag.ZIndex = 109
                end
            end
        end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            local loc = point(root.Position.X, root.Position.Z)
            local marker = label("You", canvas, "◆", 23, Color3.fromRGB(142, 55, 45), true)
            marker.Position = UDim2.fromOffset(loc.X - 9, loc.Y - 15)
            marker.Size = UDim2.fromOffset(28, 28)
            marker.ZIndex = 109
        end
    end

    mapButtons[1].Activated:Connect(function()
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            mapCenter = Vector2.new(root.Position.X, root.Position.Z)
            mapZoom = 1.25
            mapFocused = true
            drawMap()
        end
    end)
    mapButtons[2].Activated:Connect(function()
        mapCenter = Vector2.new(0, 0)
        mapZoom = 1.3
        mapFocused = true
        drawMap()
    end)
    mapButtons[3].Activated:Connect(function()
        mapCenter = Vector2.new(610, 0)
        mapZoom = 1.25
        mapFocused = true
        drawMap()
    end)
    mapButtons[4].Activated:Connect(function()
        mapZoom = math.max(0.3, mapZoom / 1.4)
        drawMap()
    end)
    mapButtons[5].Activated:Connect(function()
        mapZoom = math.min(4, mapZoom * 1.4)
        drawMap()
    end)
    local dragging = false
    local dragStart = Vector2.zero
    local dragCenter = Vector2.zero
    canvas.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            dragCenter = mapCenter
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not overlay.Visible or activeTab ~= "Map" then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local p = Vector2.new(input.Position.X, input.Position.Y)
            local corner = canvas.AbsolutePosition
            local size = canvas.AbsoluteSize
            if p.X >= corner.X and p.Y >= corner.Y
                and p.X <= corner.X + size.X and p.Y <= corner.Y + size.Y then
                mapZoom = math.clamp(mapZoom * (if input.Position.Z > 0 then 1.25 else 0.8), 0.3, 4)
                drawMap()
            end
        elseif dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local p = Vector2.new(input.Position.X, input.Position.Y)
            local delta = p - dragStart
            local size = canvas.AbsoluteSize
            local scale = math.min(size.X / 480, size.Y / 260) * mapZoom
            mapCenter = dragCenter + Vector2.new(-delta.X / scale, delta.Y / scale)
            mapFocused = true
            drawMap()
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local function setOpen(open: boolean)
        overlay.Visible = open
        toggle.Visible = not open
        if open then drawMap() end
    end
    tutorialTab.Activated:Connect(function() setTab("Tutorial") end)
    wardrobeTab.Activated:Connect(function() setTab("Wardrobe") end)
    mapTab.Activated:Connect(function() setTab("Map"); drawMap() end)
    collectionTab.Activated:Connect(function() setTab("Collection") end)
    travelTab.Activated:Connect(function() setTab("Travel") end)
    replay.Activated:Connect(function()
        local network = ReplicatedStorage:WaitForChild("Network")
        local request = network:WaitForChild("StartTutorialReplay") :: RemoteEvent
        request:FireServer()
        setOpen(false)
    end)
    close.Activated:Connect(function() setOpen(false) end)
    returnToLobby.Activated:Connect(function()
        if not returnToLobby.Active then return end
        returnToLobby.Active = false
        returnToLobby.Text = "RETURNING..."
        local network = ReplicatedStorage:WaitForChild("Network")
        local request = network:WaitForChild("ReturnToLobby") :: RemoteEvent
        request:FireServer()
    end)
    player:GetAttributeChangedSignal("LobbyReturnState"):Connect(function()
        local state = player:GetAttribute("LobbyReturnState")
        if state == "Teleporting" then return end
        returnToLobby.Active = true
        returnToLobby.Text = if state == "StudioPreview" then "LIVE GAME ONLY"
            elseif state == "Failed" then "RETRY LOBBY"
            else "BACK TO LOBBY"
    end)
    toggle.Activated:Connect(function()
        setOpen(true)
    end)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.M then
            setOpen(not overlay.Visible)
        elseif input.KeyCode == Enum.KeyCode.Escape and overlay.Visible then
            setOpen(false)
        end
    end)
    screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
    player.PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "TouchGui" then layout() end
    end)
    player.PlayerGui.ChildRemoved:Connect(function(child)
        if child.Name == "TouchGui" then layout() end
    end)
    layout()
    setTab("Tutorial")
    task.spawn(function()
        while screen.Parent do
            placeToggle()
            if overlay.Visible and activeTab == "Map" then drawMap() end
            task.wait(0.5)
        end
    end)
    return wardrobePane, collectionPane, travelPane, function()
        setTab("Collection")
        collectionPane.CanvasPosition = Vector2.zero
        setOpen(true)
    end
end

return table.freeze(OperationsMenu)
