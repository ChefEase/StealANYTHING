-- Local-only VFX review room. This script is mapped only by vfx-preview.project.json.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effects = require(script.Parent.PreviewEffects)
local ReceivingPrototype = require(script.Parent.ReceivingPrototype)
local PickupPrototype = require(script.Parent.PickupPrototype)
local ExtractionPrototype = require(script.Parent.ExtractionPrototype)
local Catalog = require(ReplicatedStorage.Shared.ItemCatalog)
local Balance = require(ReplicatedStorage.Shared.BalanceConfig)
local player = Players.LocalPlayer

local TEAL = Color3.fromRGB(74, 235, 194)
local GOLD = Color3.fromRGB(255, 207, 115)
local INK = Color3.fromRGB(17, 30, 34)
local TEXT = Color3.fromRGB(237, 246, 242)

local kinds = { "Pickup", "Receiving", "Extraction", "Restock", "Exhibit", "Gallery" }
local views = { { "NEAR", 12 }, { "MEDIUM", 30 }, { "GAMEPLAY", 60 } }
local modes = { "Normal", "Low effects", "Reduced motion" }
local selected = 1
local viewIndex = 2
local modeIndex = 1
local itemIndex = 1
local pickupTierIndex = 1
local serial = 0
local activeRoot = nil
local cancelTweens = nil
local receivingController = nil
local extractionController = nil

local arena = Instance.new("Folder")
arena.Name = "LocalVfxPreviewArena"
arena.Parent = workspace

local function makePart(name, size, cf, color, material, parent)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = parent
    return p
end

local targets = {}
for index, kind in kinds do
    local model = Instance.new("Model")
    model.Name = "Sample" .. kind
    model.Parent = arena
    local x = if kind == "Gallery" then 0 else (index - 3) * 20
    local z = if kind == "Gallery" then -42 else 0
    makePart("Station", if kind == "Gallery" then Vector3.new(44, .3, 32)
        else Vector3.new(11, .3, 11), CFrame.new(x, .15, z),
        Color3.fromRGB(39, 54, 57), Enum.Material.Metal, model)
    local stand = makePart("SampleTarget", Vector3.new(3.5, 2.3, 3.5),
        CFrame.new(x, 1.45, z), if kind == "Receiving" or kind == "Extraction"
            then TEAL else GOLD, Enum.Material.SmoothPlastic, model)
    if kind == "Pickup" then
        stand.Color = Color3.fromRGB(85, 101, 107)
    elseif kind == "Receiving" then
        stand.Size = Vector3.new(8, .25, 6)
        stand.CFrame = CFrame.new(x, .46, 0)
        stand.Transparency = 1
    elseif kind == "Extraction" then
        stand.Shape = Enum.PartType.Cylinder
        stand.Size = Vector3.new(.3, 8, 8)
        stand.CFrame = CFrame.new(x, .48, 0) * CFrame.Angles(0, 0, math.rad(90))
        stand.Transparency = 1
    elseif kind == "Exhibit" then
        stand.Size = Vector3.new(5, 1.4, 5)
        stand.CFrame = CFrame.new(x, .85, 0)
    elseif kind == "Gallery" then
        stand.Transparency = 1
        stand.Size = Vector3.new(.2, .2, .2)
    end
    local sign = Instance.new("BillboardGui")
    sign.Name = "StationLabel"
    sign.Adornee = stand
    sign.Size = UDim2.fromOffset(160, 30)
    sign.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
    sign.MaxDistance = 75
    sign.AlwaysOnTop = false
    sign.Parent = model
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = INK
    label.BackgroundTransparency = .18
    label.TextColor3 = TEXT
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Text = string.upper(kind)
    label.Parent = sign
    targets[index] = stand
end

local gui = Instance.new("ScreenGui")
gui.Name = "VfxPreviewControls"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")

local toggle = Instance.new("TextButton")
toggle.Name = "ToggleControls"
toggle.Size = UDim2.fromOffset(106, 32)
toggle.Position = UDim2.fromOffset(10, 10)
toggle.Text = "HIDE PANEL"
toggle.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "PreviewPanel"
panel.Position = UDim2.fromOffset(10, 48)
panel.Size = UDim2.fromOffset(310, 445)
panel.BackgroundColor3 = INK
panel.BackgroundTransparency = .06
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
local function fitPanel()
    panelScale.Scale = math.clamp(math.min(1,
        (gui.AbsoluteSize.X - 20) / 310,
        (gui.AbsoluteSize.Y - 58) / 445), .55, 1)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitPanel)
fitPanel()

local function label(name, value, y, height, size, color)
    local t = Instance.new("TextLabel")
    t.Name = name
    t.Position = UDim2.fromOffset(12, y)
    t.Size = UDim2.new(1, -24, 0, height)
    t.BackgroundTransparency = 1
    t.Text = value
    t.TextColor3 = color or TEXT
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextWrapped = true
    t.Font = Enum.Font.GothamBold
    t.TextSize = size
    t.Parent = panel
    return t
end

label("Title", "VFX PREVIEW  /  LOCAL TEST PLACE", 8, 28, 15, TEAL)
label("Notice", "Mocks show timing and cleanup. Exhibit uses the live recipe module.",
    36, 38, 11, TEXT)

local function button(name, value, x, y, width, height)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Position = UDim2.fromOffset(x, y)
    b.Size = UDim2.fromOffset(width, height)
    b.BackgroundColor3 = Color3.fromRGB(37, 61, 62)
    b.TextColor3 = TEXT
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Text = value
    b.Parent = panel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    return b
end

local kindButtons = {}
for index, kind in kinds do
    local column = (index - 1) % 2
    local row = math.floor((index - 1) / 2)
    kindButtons[index] = button("Select" .. kind, kind, 12 + column * 145,
        80 + row * 35, 136, 30)
end

local play = button("Play", "PLAY", 12, 190, 87, 34)
local replay = button("Replay", "REPLAY", 108, 190, 87, 34)
local reset = button("Reset", "RESET", 204, 190, 94, 34)
local viewButton = button("CameraDistance", "CAMERA: MEDIUM", 12, 235, 286, 32)
local modeButton = button("EffectMode", "MODE: NORMAL", 12, 275, 286, 32)
local itemButton = button("ExhibitItem", "ITEM: DRAMATIC TOASTER", 12, 315, 286, 32)
itemButton.TextWrapped = true
local stageNames = { "Idle", "Approach", "Processing", "Success", "Cancel", "Failure" }
local stageButtons = {}
for index, stage in stageNames do
    local column = (index - 1) % 3
    local row = math.floor((index - 1) / 3)
    stageButtons[index] = button("Mock" .. stage, string.upper(stage),
        12 + column * 98, 315 + row * 35, 90, 30)
end
local tierNames = { "Common", "Uncommon", "Rare", "Legendary" }
local tierButtons = {}
for index, tier in tierNames do
    local column = (index - 1) % 2
    local row = math.floor((index - 1) / 2)
    tierButtons[index] = button("Pickup" .. tier, string.upper(tier),
        12 + column * 145, 315 + row * 35, 136, 30)
end
local extractionStates = { "Idle", "Activation", "Charging", "Completion", "Cancellation" }
local extractionButtons = {}
for index, state in extractionStates do
    local column = (index - 1) % 2
    local row = math.floor((index - 1) / 2)
    extractionButtons[index] = button("Extraction" .. state, string.upper(state),
        12 + column * 145, 315 + row * 25, 136, 22)
end
local status = label("Status", "Ready. Select a station, then Play.", 391, 44, 11, GOLD)

local function focusCamera()
    local camera = workspace.CurrentCamera
    local target = targets[selected]
    if not camera or not target then return end
    local distance = views[viewIndex][2]
    local center = target.Position + Vector3.new(0, 1, 0)
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = 70
    camera.CFrame = CFrame.lookAt(center + Vector3.new(0, distance * .34, distance), center)
end

local function clear()
    serial += 1
    if cancelTweens then cancelTweens(); cancelTweens = nil end
    if receivingController then receivingController:Destroy(); receivingController = nil end
    if extractionController then extractionController:Destroy(); extractionController = nil end
    if activeRoot then activeRoot:Destroy(); activeRoot = nil end
    status.Text = "Reset. No preview effects active."
end

local function startReceiving()
    local root = Instance.new("Folder")
    root.Name = "ActiveReceivingPrototype"
    root.Parent = arena
    activeRoot = root
    receivingController = ReceivingPrototype.Create(root,
        targets[selected], modes[modeIndex])
    status.Text = "Receiving platform idle. Play a flow or select a mock state."
end

local function startExtraction()
    local root = Instance.new("Folder")
    root.Name = "ActiveExtractionPrototype"
    root.Parent = arena
    activeRoot = root
    extractionController = ExtractionPrototype.Create(root,
        targets[selected], modes[modeIndex])
    status.Text = "Machine idle. Play a flow or select a mock state."
end

local function refresh()
    for index, b in kindButtons do
        b.BackgroundColor3 = if index == selected then TEAL
            else Color3.fromRGB(37, 61, 62)
        b.TextColor3 = if index == selected then INK else TEXT
    end
    viewButton.Text = "CAMERA: " .. views[viewIndex][1]
    modeButton.Text = "MODE: " .. string.upper(modes[modeIndex])
    local item = Catalog.ById[Catalog.OrderedIds[itemIndex]]
    itemButton.Text = "ITEM: " .. string.upper(item.name)
    itemButton.Visible = kinds[selected] == "Exhibit"
    for _, b in stageButtons do b.Visible = kinds[selected] == "Receiving" end
    for _, b in extractionButtons do b.Visible = kinds[selected] == "Extraction" end
    for index, b in tierButtons do
        b.Visible = kinds[selected] == "Pickup"
        b.BackgroundColor3 = if index == pickupTierIndex then TEAL
            else Color3.fromRGB(37, 61, 62)
        b.TextColor3 = if index == pickupTierIndex then INK else TEXT
    end
    focusCamera()
end

local function run()
    clear()
    local mySerial = serial
    local kind = kinds[selected]
    if kind == "Receiving" then
        startReceiving()
        local controller = receivingController
        task.spawn(function()
            task.wait(1)
            if serial ~= mySerial then return end
            controller:SetState("Approach")
            status.Text = "Mock valid carry approaching."
            task.wait(1.3)
            if serial ~= mySerial then return end
            controller:SetState("Processing")
            status.Text = "Mock DeliveryInProgress: processing inward."
            task.wait(1.4)
            if serial ~= mySerial then return end
            controller:SetState("Success")
            status.Text = "Mock server-confirmed Success cue: short gold payoff."
        end)
        return
    end
    if kind == "Extraction" then
        startExtraction()
        local controller = extractionController
        controller:SetState("Activation")
        status.Text = "Mock activation: mechanical pulse."
        task.spawn(function()
            task.wait(.35)
            if serial ~= mySerial then return end
            controller:SetState("Charging")
            status.Text = "Mock extraction charging. Cancel before completion."
            task.wait(math.max(.1, Balance.PUBLIC_EXTRACTION_SECONDS - .35))
            if serial ~= mySerial then return end
            controller:SetState("Completion")
            status.Text = "Mock validated completion only. No teleport."
        end)
        return
    end
    local root = Instance.new("Folder")
    root.Name = "ActivePreviewEffect"
    root.Parent = arena
    activeRoot = root
    local itemId = Catalog.OrderedIds[itemIndex]
    local live = function() return serial == mySerial and root.Parent ~= nil end
    if kind == "Pickup" then
        cancelTweens = PickupPrototype.Play(root, targets[selected],
            tierNames[pickupTierIndex], modes[modeIndex], live)
    else
        cancelTweens = Effects.Play(kind, targets[selected], root,
            modes[modeIndex], itemId, live)
    end
    status.Text = if kind == "Exhibit" then "Live exhibit recipe: " .. itemId
        elseif kind == "Gallery" then "All 12 recipe geometries together; proxy items, no audio."
        elseif kind == "Pickup" then "Mock confirmed " .. tierNames[pickupTierIndex]
            .. " pickup. Reset during hold to cancel."
        else "Local mock event: " .. kind .. ". No rewards or travel."
    if kind ~= "Exhibit" and kind ~= "Gallery" then
        task.delay(if kind == "Pickup" then 1.7 else 6, function()
            if serial == mySerial then clear(); status.Text = "Preview finished. Replay or choose another." end
        end)
    end
end

for index, b in kindButtons do
    b.Activated:Connect(function()
        clear()
        selected = index
        refresh()
        if kinds[selected] == "Receiving" then startReceiving() end
        if kinds[selected] == "Extraction" then startExtraction() end
    end)
end
play.Activated:Connect(run)
replay.Activated:Connect(run)
reset.Activated:Connect(function()
    clear()
    if kinds[selected] == "Receiving" then startReceiving() end
    if kinds[selected] == "Extraction" then startExtraction() end
end)
viewButton.Activated:Connect(function()
    viewIndex = viewIndex % #views + 1
    refresh()
end)
modeButton.Activated:Connect(function()
    clear()
    modeIndex = modeIndex % #modes + 1
    refresh()
    if kinds[selected] == "Receiving" then startReceiving() end
    if kinds[selected] == "Extraction" then startExtraction() end
end)
itemButton.Activated:Connect(function()
    clear()
    itemIndex = itemIndex % #Catalog.OrderedIds + 1
    refresh()
end)
for index, b in stageButtons do
    b.Activated:Connect(function()
        if kinds[selected] ~= "Receiving" then return end
        serial += 1 -- cancel any scheduled mock flow before changing the stage
        if not receivingController then startReceiving() end
        local stage = stageNames[index]
        receivingController:SetState(stage)
        status.Text = if stage == "Success" then "Mock committed Success cue only."
            elseif stage == "Cancel" or stage == "Failure" then
                "No reward burst. Returning to idle."
            else "Mock state: " .. stage
    end)
end
for index, b in tierButtons do
    b.Activated:Connect(function()
        if kinds[selected] ~= "Pickup" then return end
        clear()
        pickupTierIndex = index
        refresh()
        status.Text = "Selected " .. tierNames[index] .. ". Play to compare motion."
    end)
end
for index, b in extractionButtons do
    b.Activated:Connect(function()
        if kinds[selected] ~= "Extraction" then return end
        serial += 1 -- cancel the scheduled mock completion
        if not extractionController then startExtraction() end
        local state = extractionStates[index]
        extractionController:SetState(state)
        status.Text = if state == "Completion" then "Mock validated completion only."
            elseif state == "Cancellation" then "Power-down; no completion visual."
            else "Mock extraction state: " .. state
    end)
end
toggle.Activated:Connect(function()
    panel.Visible = not panel.Visible
    toggle.Text = if panel.Visible then "HIDE PANEL" else "SHOW PANEL"
end)

player.CharacterAdded:Connect(function()
    task.defer(focusCamera)
end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(focusCamera)
RunService.RenderStepped:Connect(function()
    if workspace.CurrentCamera and workspace.CurrentCamera.CameraType ~= Enum.CameraType.Scriptable then
        focusCamera()
    end
end)

refresh()
