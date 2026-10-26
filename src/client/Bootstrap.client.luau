--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

if player:GetAttribute("ClientBootstrapStarted") == true then
    return
end
player:SetAttribute("ClientBootstrapStarted", true)

print("[Steal Anything] Client bootstrap ready")

local connectingScreen = Instance.new("ScreenGui")
connectingScreen.Name = "ConnectingToLobby"
connectingScreen.IgnoreGuiInset = true
connectingScreen.ResetOnSpawn = false
connectingScreen.Parent = player:WaitForChild("PlayerGui")
local connectingText = Instance.new("TextLabel")
connectingText.Size = UDim2.fromScale(1, 1)
connectingText.BackgroundColor3 = Color3.fromRGB(14, 27, 32)
connectingText.TextColor3 = Color3.fromRGB(231, 246, 242)
connectingText.Font = Enum.Font.GothamBold
connectingText.TextScaled = true
connectingText.Text = "CONNECTING TO MATCHMAKING"
connectingText.Parent = connectingScreen

-- The server decides whether this is a redirect server or a reserved museum.
-- Waiting for its replicated decision avoids starting museum HUD on ingress.
while type(ReplicatedStorage:GetAttribute("MuseumIngressOnly")) ~= "boolean" do
    ReplicatedStorage:GetAttributeChangedSignal("MuseumIngressOnly"):Wait()
end
if ReplicatedStorage:GetAttribute("MuseumIngressOnly") == true then
    return
end
connectingScreen:Destroy()

local CameraController = require(script.Parent.CameraController)
local CashHud = require(script.Parent.CashHud)
local CarryDestinationHud = require(script.Parent.CarryDestinationHud)
local CarryHud = require(script.Parent.CarryHud)
local CarryInputController = require(script.Parent.CarryInputController)
local InteractionHud = require(script.Parent.InteractionHud)
local NotificationHud = require(script.Parent.NotificationHud)
local RemoteHudController = require(script.Parent.RemoteHudController)
local TutorialPickupController = require(script.Parent.TutorialPickupController)
local TutorialGuideController = require(script.Parent.TutorialGuideController)
local OperationsMenu = require(script.Parent.OperationsMenu)
local PhoneHudLayout = require(script.Parent.PhoneHudLayout)
local Theme = require(script.Parent.HudTheme)
local TravelOfferHud = require(script.Parent.TravelOfferHud)
local MatchWaitingHud = require(script.Parent.MatchWaitingHud)
local FriendInviteHud = require(script.Parent.FriendInviteHud)
local WardrobeUi = require(ReplicatedStorage.Shared.WardrobeUi)

local playerGui = player:WaitForChild("PlayerGui")
MatchWaitingHud.Start(player)
FriendInviteHud.Start(player)

CameraController.Start(player)

for _, child in playerGui:GetChildren() do
    if child.Name == "GameHud" then
        child:Destroy()
    end
end

local OBJECTIVE_ACCENT = Theme.Accent
local COMPLETE_ACCENT = Color3.fromRGB(112, 116, 119)
local WARNING_ACCENT = Color3.fromRGB(255, 190, 35)
local ERROR_ACCENT = Color3.fromRGB(229, 31, 50)

local messages = {
    Loading = "LOADING YOUR MUSEUM...",
    WaitingForSession = "WAITING FOR YOUR PREVIOUS SESSION",
    RetryableError = "SAVED DATA UNAVAILABLE - REJOIN LATER",
    SaveError = "SAVING DELAYED - COLLECTION CHANGES PAUSED",
    DataError = "SAVED DATA NEEDS REPAIR - GAMEPLAY PAUSED",
    SessionConflict = "THIS ACCOUNT ALREADY HAS AN ACTIVE SESSION",
    ConfigurationError = "GAME DATA IS NOT CONFIGURED FOR THIS SERVER",
}

local errorStates = {
    RetryableError = true,
    SaveError = true,
    DataError = true,
    SessionConflict = true,
    ConfigurationError = true,
}

local screen = Instance.new("ScreenGui")
screen.Name = "GameHud"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.DisplayOrder = 10
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

CashHud.Create(screen, player)
CarryHud.Create(screen, player)
CarryDestinationHud.Create(screen, player)
InteractionHud.Create(screen, player)
NotificationHud.Create(screen, player)
RemoteHudController.Start(player)
TutorialPickupController.Start(player)
CarryInputController.Start(player, screen)
TutorialGuideController.Start(player, screen)
local wardrobePane = OperationsMenu.Start(player, screen)
WardrobeUi.Start(player, wardrobePane)
TravelOfferHud.Create(screen, player)

local objective = Instance.new("Frame")
objective.Name = "Objective"
objective.Position = UDim2.fromOffset(32, 28)
objective.Size = UDim2.new(1, -64, 0, 30)
objective.BackgroundTransparency = 1
objective.Parent = screen

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(540, 30)
sizeConstraint.MinSize = Vector2.new(240, 30)
sizeConstraint.Parent = objective

local icon = Instance.new("Frame")
icon.Name = "Icon"
icon.Position = UDim2.fromOffset(0, 3)
icon.Size = UDim2.fromOffset(22, 22)
icon.BackgroundColor3 = OBJECTIVE_ACCENT
icon.BorderSizePixel = 0
icon.Parent = objective

local iconGlyph = Instance.new("TextLabel")
iconGlyph.Name = "Glyph"
iconGlyph.Size = UDim2.fromScale(1, 1)
iconGlyph.BackgroundTransparency = 1
iconGlyph.Font = Enum.Font.GothamBold
iconGlyph.Text = utf8.char(9670)
iconGlyph.TextColor3 = Theme.Ink
iconGlyph.TextSize = 13
iconGlyph.Parent = icon

local textShadow = Instance.new("TextLabel")
textShadow.Name = "Shadow"
textShadow.Position = UDim2.fromOffset(31, 2)
textShadow.Size = UDim2.new(1, -31, 1, 0)
textShadow.BackgroundTransparency = 1
textShadow.Font = Enum.Font.GothamBold
textShadow.Text = ""
textShadow.TextColor3 = Color3.new(0, 0, 0)
textShadow.TextTransparency = 0.35
textShadow.TextSize = 15
textShadow.TextXAlignment = Enum.TextXAlignment.Left
textShadow.TextYAlignment = Enum.TextYAlignment.Center
textShadow.TextTruncate = Enum.TextTruncate.AtEnd
textShadow.Parent = objective

local objectiveText = Instance.new("TextLabel")
objectiveText.Name = "Text"
objectiveText.Position = UDim2.fromOffset(30, 1)
objectiveText.Size = UDim2.new(1, -30, 1, 0)
objectiveText.BackgroundTransparency = 1
objectiveText.Font = Enum.Font.GothamBold
objectiveText.Text = ""
objectiveText.TextColor3 = Theme.Text
objectiveText.TextSize = 15
objectiveText.TextXAlignment = Enum.TextXAlignment.Left
objectiveText.TextYAlignment = Enum.TextYAlignment.Center
objectiveText.TextTruncate = Enum.TextTruncate.AtEnd
objectiveText.Parent = objective

local function updateObjectiveLayout()
    if PhoneHudLayout.IsPhone(screen) then
        PhoneHudLayout.Apply(objective, PhoneHudLayout.Calculate(screen.AbsoluteSize).objective)
        sizeConstraint.MinSize = Vector2.zero
        sizeConstraint.MaxSize = Vector2.new(2000, 50)
        local size = if screen.AbsoluteSize.X < 520 then 12 else 14
        objectiveText.TextSize = size
        textShadow.TextSize = size
    else
        objective.Position = UDim2.fromOffset(32, 28)
        objective.Size = UDim2.new(1, -64, 0, 30)
        sizeConstraint.MinSize = Vector2.new(240, 30)
        sizeConstraint.MaxSize = Vector2.new(540, 30)
        objectiveText.TextSize = 15
        textShadow.TextSize = 15
    end
end

local function setObjective(text: string, accent: Color3, glyph: string, muted: boolean)
    local uppercaseText = string.upper(text)
    objectiveText.Text = uppercaseText
    textShadow.Text = uppercaseText
    objectiveText.TextColor3 = if muted
        then Theme.Muted
        else Theme.Text
    icon.BackgroundColor3 = accent
    iconGlyph.Text = glyph
    iconGlyph.TextColor3 = if muted
        then Theme.Text
        else Theme.Ink
end

local function render()
    local state = player:GetAttribute("ProfileState")
    local phone = PhoneHudLayout.IsPhone(screen)
    objective.Visible = true
    if state ~= "Ready" then
        local stateName = if type(state) == "string" then state else "Loading"
        local message = messages[stateName] or messages.Loading
        local accent = if errorStates[stateName] then ERROR_ACCENT else WARNING_ACCENT
        setObjective(message, accent, if errorStates[stateName] then "!" else utf8.char(8226), false)
        return
    end
    local plotState = player:GetAttribute("PlotState")
    if plotState ~= "Ready" then
        local message = if plotState == "Full" then "SERVER PLOTS FULL - WAITING FOR A SPACE"
            elseif plotState == "Unavailable" then "MUSEUM TEMPLATE UNAVAILABLE"
            else "PREPARING YOUR MUSEUM..."
        setObjective(message, if plotState == "Unavailable" then ERROR_ACCENT else WARNING_ACCENT,
            if plotState == "Unavailable" then "!" else utf8.char(8226), false)
        return
    end

    if player:GetAttribute("TutorialStep") == 0
        or player:GetAttribute("TutorialReplayActive") == true then
        -- The guide now occupies this desktop corner and already carries the
        -- same instruction. Leave the phone objective behavior unchanged.
        objective.Visible = false
        local carrying = player:GetAttribute("CarryId") ~= nil
        local tutorialText = if carrying
            then (if player:GetAttribute("AtDropOff") == true
                then "Tutorial: Hold G to deliver the toaster"
                else "Tutorial: Carry the toaster to your exhibit stand")
            else "Tutorial: Follow the arrow to the depot"
        setObjective(tutorialText, OBJECTIVE_ACCENT, utf8.char(9670), false)
        return
    end

    if player:GetAttribute("TutorialStep") == 1 then
        local guide = screen:FindFirstChild("TutorialGuide")
        objective.Visible = phone or not (guide ~= nil and guide:IsA("GuiObject") and guide.Visible)
        setObjective("Watch your toaster earn its first dollar",
            OBJECTIVE_ACCENT, utf8.char(9670), false)
        return
    end

    if player:GetAttribute("TutorialStep") == 2 then
        local guide = screen:FindFirstChild("TutorialGuide")
        objective.Visible = phone or not (guide ~= nil and guide:IsA("GuiObject") and guide.Visible)
        setObjective("Next: depot heist coming soon",
            COMPLETE_ACCENT, utf8.char(10003), false)
        return
    end

    local customText = player:GetAttribute("CurrentObjective")
    local text = if type(customText) == "string" and customText ~= ""
        then customText
        else "Reach the depot"
    local complete = player:GetAttribute("ObjectiveComplete") == true
    local glyph = if complete then utf8.char(10003) else utf8.char(9670)
    setObjective(text, if complete then COMPLETE_ACCENT else OBJECTIVE_ACCENT, glyph, complete)
end

player:GetAttributeChangedSignal("ProfileState"):Connect(render)
player:GetAttributeChangedSignal("PlotState"):Connect(render)
player:GetAttributeChangedSignal("CurrentObjective"):Connect(render)
player:GetAttributeChangedSignal("ObjectiveComplete"):Connect(render)
player:GetAttributeChangedSignal("TutorialStep"):Connect(render)
player:GetAttributeChangedSignal("TutorialReplayActive"):Connect(render)
player:GetAttributeChangedSignal("CarryId"):Connect(render)
player:GetAttributeChangedSignal("AtDropOff"):Connect(render)
local guidePanel = screen:FindFirstChild("TutorialGuide")
if guidePanel ~= nil and guidePanel:IsA("GuiObject") then
    guidePanel:GetPropertyChangedSignal("Visible"):Connect(render)
end
screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    updateObjectiveLayout()
    render()
end)
updateObjectiveLayout()
render()
