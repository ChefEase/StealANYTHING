--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ReceivingPlatformVfx = require(ReplicatedStorage.Shared.ReceivingPlatformVfx)

local Theme = require(script.Parent.HudTheme)

local DeliveryFeedbackController = {}
local SAVING = Color3.fromRGB(255, 207, 115)

function DeliveryFeedbackController.Start(player: Player)
    local zone: BasePart? = nil
    local highlight: Highlight? = nil
    local platformRoot: Folder? = nil
    local platformController: any = nil
    local platformState = "Idle"
    local wasSaving = false
    local savingSign: BillboardGui? = nil
    local arrivalSign: BillboardGui? = nil
    local confirmedUntil = 0
    local confirmedColor = Theme.Accent
    local lastConfirmedCueId: string? = nil
    local lastCheck = 0

    local function findZone(): BasePart?
        if zone ~= nil and zone.Parent ~= nil then return zone end
        zone = nil
        local plotId = player:GetAttribute("AssignedPlotId")
        local cloneId = player:GetAttribute("MuseumCloneId")
        if type(plotId) ~= "string" or type(cloneId) ~= "string" then return nil end
        local map = workspace:FindFirstChild("Map")
        local owned = map and map:FindFirstChild("OwnedMuseums")
        local museum = owned and owned:FindFirstChild("Museum_" .. plotId)
        if museum == nil or museum:GetAttribute("CloneId") ~= cloneId
            or museum:GetAttribute("OwnerUserId") ~= player.UserId then return nil end
        local found = museum:FindFirstChild("ReceivingZone", true)
        if found and found:IsA("BasePart") then zone = found end
        return zone
    end

    local function clearNear()
        if highlight then highlight:Destroy() end
        if savingSign then savingSign:Destroy() end
        highlight = nil
        savingSign = nil
    end

    local function clear()
        clearNear()
        if arrivalSign then arrivalSign:Destroy(); arrivalSign = nil end
        if platformController then platformController:Destroy(); platformController = nil end
        platformRoot = nil
        platformState = "Idle"
        wasSaving = false
    end

    local function setPlatform(target: BasePart, state: string)
        if not platformController or not platformRoot or not platformRoot.Parent then
            platformRoot = Instance.new("Folder")
            platformRoot.Name = "LocalReceivingPlatform"
            platformRoot.Parent = workspace
            local mode = if player:GetAttribute("ReduceMotion") == true then "Reduced motion"
                elseif player:GetAttribute("LowEffects") == true then "Low effects" else "Normal"
            platformController = ReceivingPlatformVfx.Create(platformRoot, target, mode)
            platformState = "Idle"
        end
        if platformState ~= state then
            platformState = state
            platformController:SetState(state)
        end
    end

    local feedback = ReplicatedStorage.Network:WaitForChild("Feedback") :: RemoteEvent
    feedback.OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" or payload.kind ~= "Success"
            or type(payload.cueId) ~= "string"
            or payload.cueId == lastConfirmedCueId then return end
        local cue = payload.cue
        if cue ~= "DeliveredDisplayed" and cue ~= "DeliveredStored"
            and cue ~= "DeliveredSalvage" then return end
        lastConfirmedCueId = payload.cueId
        confirmedUntil = os.clock() + 1.2
        confirmedColor = if cue == "DeliveredStored" then SAVING else Theme.Accent
        local target = findZone()
        if target == nil then return end
        setPlatform(target, "Success")
    end)

    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - lastCheck < 0.15 then return end
        lastCheck = now
        local target = findZone()
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if target == nil or root == nil or not root:IsA("BasePart") then
            clear()
            return
        end
        local distance = (Vector3.new(root.Position.X, 0, root.Position.Z)
            - Vector3.new(target.Position.X, 0, target.Position.Z)).Magnitude
        local near = distance <= 27
        local carrying = type(player:GetAttribute("CarryId")) == "string"
        local saving = player:GetAttribute("DeliveryInProgress") == true
        if near and (carrying or now < confirmedUntil) then
            if now < confirmedUntil then
                setPlatform(target, "Success")
            elseif saving then
                setPlatform(target, "Processing")
            elseif wasSaving then
                setPlatform(target, "Cancel")
            else
                setPlatform(target, "Approach")
            end
        elseif platformController then
            platformController:Destroy()
            platformController = nil
            platformRoot = nil
            platformState = "Idle"
        end
        wasSaving = saving
        if carrying and distance <= 70 and arrivalSign == nil then
            local sign = Instance.new("BillboardGui")
            sign.Name = "LocalReceivingDestination"
            sign.Adornee = target
            sign.Size = UDim2.fromOffset(164, 36)
            sign.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
            sign.MaxDistance = 75
            sign.AlwaysOnTop = false
            local text = Instance.new("TextLabel")
            text.Size = UDim2.fromScale(1, 1)
            text.BackgroundColor3 = Theme.Ink
            text.BackgroundTransparency = 0.12
            text.TextColor3 = Theme.Accent
            text.Font = Enum.Font.GothamBlack
            text.TextSize = 15
            text.Text = "▼  DELIVER HERE"
            text.Parent = sign
            sign.Parent = player:WaitForChild("PlayerGui")
            arrivalSign = sign
        elseif (not carrying or distance > 70) and arrivalSign ~= nil then
            arrivalSign:Destroy()
            arrivalSign = nil
        end
        if not near or (not carrying and now >= confirmedUntil) then
            clearNear()
            return
        end
        if highlight == nil then
            local newHighlight = Instance.new("Highlight")
            newHighlight.Name = "LocalReceivingGlow"
            newHighlight.Adornee = target
            newHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
            newHighlight.Parent = target
            highlight = newHighlight
        end
        local color = if now < confirmedUntil then confirmedColor
            elseif saving then SAVING else Theme.Accent
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = if player:GetAttribute("LowEffects") == true then 1 else 0.82
        highlight.OutlineTransparency = 0.2
        if saving and savingSign == nil then
            local sign = Instance.new("BillboardGui")
            sign.Name = "LocalDeliverySaveState"
            sign.Adornee = target
            sign.Size = UDim2.fromOffset(160, 30)
            sign.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
            sign.MaxDistance = 35
            sign.AlwaysOnTop = false
            local text = Instance.new("TextLabel")
            text.Size = UDim2.fromScale(1, 1)
            text.BackgroundColor3 = Theme.Ink
            text.BackgroundTransparency = 0.15
            text.TextColor3 = SAVING
            text.Font = Enum.Font.GothamBold
            text.TextSize = 13
            text.Text = "SAVING DELIVERY..."
            text.Parent = sign
            sign.Parent = player:WaitForChild("PlayerGui")
            savingSign = sign
        elseif not saving and savingSign ~= nil then
            savingSign:Destroy()
            savingSign = nil
        end
    end)
end

return table.freeze(DeliveryFeedbackController)
