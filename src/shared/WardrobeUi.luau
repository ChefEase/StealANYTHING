--!strict

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Catalog = require(script.Parent.WardrobeCatalog)
local Appearance = require(script.Parent.WardrobeAppearance)

local WardrobeUi = {}
local INK = Color3.fromRGB(8, 15, 14)
local PANEL = Color3.fromRGB(15, 28, 25)
local TEAL = Color3.fromRGB(74, 235, 194)
local GOLD = Color3.fromRGB(230, 183, 102)
local WHITE = Color3.fromRGB(238, 244, 237)
local GLOW = Color3.fromRGB(43, 185, 255)
local ICE = Color3.fromRGB(170, 240, 255)
local PREVIEW_BG = Color3.fromRGB(10, 18, 30)
local GLOW_BG = Color3.fromRGB(4, 10, 32)

local function rounded(parent: Instance, pixels: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, pixels)
    corner.Parent = parent
end

local function button(parent: Instance, name: string, caption: string,
    color: Color3): TextButton
    local item = Instance.new("TextButton")
    item.Name = name
    item.BackgroundColor3 = color
    item.TextColor3 = INK
    item.Font = Enum.Font.GothamBold
    item.TextSize = 14
    item.TextWrapped = true
    item.Text = caption
    item.Selectable = true
    item.Parent = parent
    rounded(item, 8)
    return item
end

local function label(parent: Instance, name: string, caption: string,
    size: UDim2, position: UDim2, textSize: number): TextLabel
    local item = Instance.new("TextLabel")
    item.Name = name
    item.Size = size
    item.Position = position
    item.BackgroundTransparency = 1
    item.TextColor3 = WHITE
    item.Font = Enum.Font.GothamMedium
    item.TextSize = textSize
    item.TextWrapped = true
    item.TextXAlignment = Enum.TextXAlignment.Left
    item.Text = caption
    item.Parent = parent
    return item
end

function WardrobeUi.Start(player: Player, menuHost: ScrollingFrame?)
    local action = ReplicatedStorage:WaitForChild("WardrobeAction") :: RemoteEvent
    local state = ReplicatedStorage:WaitForChild("WardrobeState") :: RemoteEvent
    local playerGui = player:WaitForChild("PlayerGui")
    local previous = playerGui:FindFirstChild("RobberWardrobeGui")
    if previous then previous:Destroy() end
    local screen = Instance.new("ScreenGui")
    screen.Name = "RobberWardrobeGui"
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 30
    screen.IgnoreGuiInset = false
    screen.Parent = playerGui

    local opener = button(screen, "WardrobeButton", "WARDROBE", TEAL)
    opener.AnchorPoint = Vector2.new(1, 1)
    opener.Position = UDim2.new(1, -12, 1, -100)
    opener.Size = UDim2.fromOffset(112, 38)
    opener.Visible = menuHost == nil

    local shade = Instance.new("Frame")
    shade.Name = "Dimmer"
    shade.Size = UDim2.fromScale(1, 1)
    shade.BackgroundColor3 = Color3.new(0, 0, 0)
    shade.BackgroundTransparency = 0.36
    shade.Visible = false
    shade.Parent = screen

    local panel = Instance.new("Frame")
    panel.Name = "WardrobePanel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.new(0.94, 0, 0.9, 0)
    panel.BackgroundColor3 = INK
    panel.Parent = if menuHost then menuHost else shade
    rounded(panel, 12)
    local limit = Instance.new("UISizeConstraint")
    limit.MaxSize = Vector2.new(760, 580)
    limit.MinSize = Vector2.new(315, 310)
    limit.Parent = panel
    if menuHost then
        limit:Destroy()
        panel.AnchorPoint = Vector2.zero
        panel.Position = UDim2.fromOffset(0, 0)
        panel.Size = UDim2.new(1, 0, 0, math.max(480, menuHost.AbsoluteSize.Y))
        panel.ClipsDescendants = true
        menuHost.ClipsDescendants = true
        menuHost.ScrollingDirection = Enum.ScrollingDirection.Y
        menuHost.ScrollBarThickness = 5
        local function resizeEmbedded()
            local height = math.max(480, menuHost.AbsoluteSize.Y)
            panel.Size = UDim2.new(1, 0, 0, height)
            menuHost.CanvasSize = UDim2.fromOffset(0, height)
        end
        menuHost:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeEmbedded)
        resizeEmbedded()
    end
    label(panel, "Heading", "ROBBER WARDROBE", UDim2.new(1, -115, 0, 30),
        UDim2.fromOffset(16, 9), 20).Font = Enum.Font.GothamBlack
    local close = button(panel, "Close", "CLOSE", PANEL)
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -12, 0, 10)
    close.Size = UDim2.fromOffset(88, 30)
    close.TextColor3 = WHITE
    close.Visible = menuHost == nil

    local list = Instance.new("ScrollingFrame")
    list.Name = "Items"
    list.Position = UDim2.new(0, 12, 0, 49)
    list.Size = UDim2.new(0.47, -12, 1, -102)
    list.BackgroundColor3 = PANEL
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 5
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.fromOffset(0, 0)
    list.ScrollingDirection = Enum.ScrollingDirection.Y
    list.ClipsDescendants = true
    list.Parent = panel
    rounded(list, 8)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.Parent = list
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12)
    end)

    local preview = Instance.new("ViewportFrame")
    preview.Name = "TryOnPreview"
    preview.Position = UDim2.new(0.48, 2, 0, 49)
    preview.Size = UDim2.new(0.52, -14, 0, 120)
    preview.BackgroundColor3 = PREVIEW_BG
    preview.Ambient = Color3.fromRGB(112, 139, 157)
    preview.LightColor = Color3.fromRGB(220, 237, 255)
    preview.Parent = panel
    rounded(preview, 8)
    local world = Instance.new("WorldModel")
    world.Parent = preview
    local camera = Instance.new("Camera")
    camera.FieldOfView = 32
    camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, 13), Vector3.new(0, 0, 0))
    camera.Parent = preview
    preview.CurrentCamera = camera

    -- Viewports skip particles, lights and trails, so the glow showcase is drawn in UI.
    local showcase = Instance.new("Frame")
    showcase.Name = "GlowShowcase"
    showcase.Size = UDim2.fromScale(1, 1)
    showcase.BackgroundTransparency = 1
    showcase.ClipsDescendants = true
    showcase.ZIndex = 2
    showcase.Visible = false
    showcase.Parent = preview
    local badge = label(showcase, "Badge", "\u{2726} ANIMATED AURA \u{2726}",
        UDim2.new(1, -16, 0, 18), UDim2.fromOffset(8, 6), 13)
    badge.Font = Enum.Font.GothamBlack
    badge.TextColor3 = ICE
    badge.TextXAlignment = Enum.TextXAlignment.Center
    badge.TextStrokeColor3 = GLOW
    badge.TextStrokeTransparency = 0.3
    badge.ZIndex = 4
    local frameStroke = Instance.new("UIStroke")
    frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    frameStroke.Thickness = 3
    frameStroke.Color = WHITE
    frameStroke.Enabled = false
    frameStroke.Parent = preview
    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, GLOW),
        ColorSequenceKeypoint.new(0.35, ICE),
        ColorSequenceKeypoint.new(0.65, Color3.fromRGB(60, 90, 255)),
        ColorSequenceKeypoint.new(1, GLOW),
    })
    strokeGradient.Parent = frameStroke
    local function spark()
        local dot = Instance.new("Frame")
        local size = math.random(3, 8)
        local x = 0.12 + math.random() * 0.76
        dot.Size = UDim2.fromOffset(size, size)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.fromScale(x, 1.03)
        dot.BackgroundColor3 = if math.random() < 0.35 then WHITE elseif math.random() < 0.5 then ICE else GLOW
        dot.BorderSizePixel = 0
        dot.ZIndex = 3
        dot.Parent = showcase
        rounded(dot, size)
        local life = 1.1 + math.random() * 1.2
        TweenService:Create(dot, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.14, 0.12 + math.random() * 0.5),
            BackgroundTransparency = 1,
        }):Play()
        task.delay(life, dot.Destroy, dot)
    end

    local selectedName = label(panel, "SelectedName", "SELECT AN ITEM",
        UDim2.new(0.5, -16, 0, 25), UDim2.new(0.48, 2, 0.56, 3), 15)
    selectedName.Font = Enum.Font.GothamBold
    local detail = label(panel, "Detail", "Preview your own avatar before equipping.",
        UDim2.new(0.5, -16, 0, 48), UDim2.new(0.48, 2, 0.62, 0), 12)
    detail.TextColor3 = Color3.fromRGB(178, 203, 208)
    local primary = button(panel, "Primary", "EQUIP", GOLD)
    primary.Position = UDim2.new(0.48, 2, 0.77, 0)
    primary.Size = UDim2.new(0.52, -14, 0, 37)
    local buyStroke = Instance.new("UIStroke")
    buyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    buyStroke.Color = GLOW
    buyStroke.Enabled = false
    buyStroke.Parent = primary
    local remove = button(panel, "Remove", "REMOVE SELECTED SLOT", PANEL)
    remove.Position = UDim2.new(0.48, 2, 0.86, 0)
    remove.Size = UDim2.new(0.52, -14, 0, 33)
    remove.TextColor3 = WHITE
    local restore = button(panel, "RestoreAvatar", "RESTORE ROBLOX AVATAR", PANEL)
    restore.Position = UDim2.new(0, 12, 1, -43)
    restore.Size = UDim2.new(0.47, -12, 0, 31)
    restore.TextColor3 = WHITE
    local feedback = label(panel, "Feedback", "",
        UDim2.new(0.52, -14, 0, 28), UDim2.new(0.48, 2, 1, -38), 11)
    feedback.TextColor3 = TEAL
    local function arrange()
        local height = panel.AbsoluteSize.Y
        local previewHeight = math.clamp(height - 270, 96, 300)
        preview.Size = UDim2.new(0.52, -14, 0, previewHeight)
        local belowPreview = 54 + previewHeight
        selectedName.Position = UDim2.new(0.48, 2, 0, belowPreview)
        detail.Position = UDim2.new(0.48, 2, 0, belowPreview + 24)
        detail.Size = UDim2.new(0.5, -16, 0, 38)
        primary.Position = UDim2.new(0.48, 2, 0, belowPreview + 65)
        primary.Size = UDim2.new(0.52, -14, 0, 31)
        remove.Position = UDim2.new(0.48, 2, 0, belowPreview + 100)
        remove.Size = UDim2.new(0.52, -14, 0, 28)
        feedback.Position = UDim2.new(0.48, 2, 0, belowPreview + 132)
        feedback.Size = UDim2.new(0.52, -14, 0, 18)
    end
    panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(arrange)
    arrange()

    local record: any = { ready = false, owned = {}, loadout = {} }
    local selected = Catalog.DisplayItems[1]
    local rows: {[string]: TextButton} = {}
    local previewModel: Model? = nil
    local glowing = false
    local spinning = false
    local yaw = math.pi
    local sparkClock = 0
    local function owns(item: any): boolean
        return item.currency == "Free" or record.owned[item.id] == true
    end
    local function showPreview()
        if previewModel then previewModel:Destroy(); previewModel = nil end
        local character = player.Character
        if character == nil then return end
        local wasArchivable = character.Archivable
        character.Archivable = true
        local clone = character:Clone()
        character.Archivable = wasArchivable
        if clone == nil then return end
        clone.Name = "PreviewAvatar"
        for _, descendant in clone:GetDescendants() do
            if descendant:IsA("LuaSourceContainer") then descendant:Destroy()
            elseif descendant:IsA("BasePart") then
                descendant.Anchored = true
                descendant.CanCollide = false
            end
        end
        local sample = table.clone(record.loadout)
        sample[selected.slot] = selected.id
        glowing = selected.id == "phantom_glow" or selected.id == "neon_phantom_outfit"
        spinning = glowing or selected.slot == "Outfit"
        showcase.Visible = glowing
        frameStroke.Enabled = glowing
        buyStroke.Enabled = glowing and not owns(selected)
        preview.BackgroundColor3 = if glowing then GLOW_BG else PREVIEW_BG
        yaw = if selected.id == "getaway_bag" then math.pi * 0.83 else math.pi
        clone.Parent = world
        clone:PivotTo(CFrame.Angles(0, yaw, 0))
        Appearance.Apply(clone, sample)
        if glowing then
            -- Wide enough for the rune circle at the feet and the halo overhead.
            camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.4, 14.5), Vector3.new(0, -0.7, 0))
        elseif selected.slot == "Face" then
            camera.CFrame = CFrame.lookAt(Vector3.new(0, 1.55, 5.5), Vector3.new(0, 1.35, 0))
        elseif selected.slot == "Body" then
            camera.CFrame = CFrame.lookAt(Vector3.new(-0.45, -0.45, 6.5), Vector3.new(-0.5, -0.7, 0))
        elseif selected.slot == "Outfit" then
            camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.45, 12), Vector3.new(0, 0.25, 0))
        else
            camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.95, 7.5), Vector3.new(0, 0.65, 0))
        end
        previewModel = clone
    end
    local function refresh()
        for _, item in Catalog.DisplayItems do
            local row = rows[item.id]
            row.Text = item.name .. "  -  "
                .. (if record.loadout[item.slot] == item.id then "EQUIPPED"
                    elseif owns(item) then "OWNED"
                    elseif item.currency == "Robux" then "ROBUX PREVIEW"
                    else "$" .. tostring(item.price))
            row.BackgroundColor3 = if selected == item then TEAL else PANEL
            row.TextColor3 = if selected == item then INK else WHITE
        end
        selectedName.Text = selected.name
        detail.Text = selected.note .. "\n" .. selected.slot .. " cosmetic - no gameplay effect"
        if not record.ready then
            primary.Text = "LOADING..."
        elseif record.loadout[selected.slot] == selected.id then
            primary.Text = "EQUIPPED"
        elseif owns(selected) then
            primary.Text = "EQUIP"
        elseif selected.currency == "Robux" then
            primary.Text = "ROBUX LOOK - COMING SOON"
        elseif record.canBuy ~= true then
            primary.Text = "BUY AT YOUR MUSEUM"
        else
            primary.Text = "BUY  $" .. tostring(selected.price)
        end
        showPreview()
    end
    for index, item in Catalog.DisplayItems do
        local row = button(list, item.id, item.name, PANEL)
        row.LayoutOrder = index
        row.Size = UDim2.new(1, 0, 0, 42)
        row.TextXAlignment = Enum.TextXAlignment.Left
        rows[item.id] = row
        row.Activated:Connect(function()
            selected = item
            refresh()
        end)
    end
    local function open()
        if menuHost == nil then
            shade.Visible = true
            opener.Visible = false
        end
        if not record.ready then action:FireServer("State") end
        GuiService.SelectedObject = rows[selected.id]
        refresh()
    end
    local function closePanel()
        if menuHost then return end
        shade.Visible = false
        opener.Visible = true
        GuiService.SelectedObject = nil
    end
    RunService.RenderStepped:Connect(function(dt: number)
        local onScreen = if menuHost then menuHost.Visible else shade.Visible
        if not onScreen then return end
        if spinning and previewModel then
            yaw += dt * 0.7
            previewModel:PivotTo(CFrame.Angles(0, yaw, 0))
        end
        if not glowing then return end
        local t = os.clock()
        strokeGradient.Rotation = (t * 120) % 360
        frameStroke.Transparency = 0.15 + 0.25 * (0.5 + 0.5 * math.sin(t * 3))
        buyStroke.Thickness = 1.5 + 2 * (0.5 + 0.5 * math.sin(t * 4))
        badge.TextTransparency = 0.25 * (0.5 + 0.5 * math.sin(t * 3))
        sparkClock = math.min(sparkClock + dt, 0.4)
        while sparkClock > 0.08 do
            sparkClock -= 0.08
            spark()
        end
    end)
    opener.Activated:Connect(open)
    close.Activated:Connect(closePanel)
    primary.Activated:Connect(function()
        if not record.ready then return end
        if not owns(selected) then
            if selected.currency == "Robux" then
                feedback.Text = "Preview only. Robux offers open after purchase testing."
            elseif record.canBuy == true then action:FireServer("Buy", selected.id)
            else feedback.Text = "Buy this item in your museum wardrobe." end
        elseif record.loadout[selected.slot] ~= selected.id then
            action:FireServer("Equip", selected.id)
        end
    end)
    remove.Activated:Connect(function()
        if record.ready then action:FireServer("Remove", selected.slot) end
    end)
    restore.Activated:Connect(function()
        if not record.ready then return end
        action:FireServer("Restore")
    end)
    state.OnClientEvent:Connect(function(nextState: any)
        if type(nextState) ~= "table" then return end
        record = nextState
        if nextState.message then feedback.Text = tostring(nextState.message) end
        if nextState.open then open() else refresh() end
    end)
    player.CharacterAdded:Connect(function()
        task.delay(1.2, showPreview)
    end)
    action:FireServer("State")
    refresh()
end

return table.freeze(WardrobeUi)
