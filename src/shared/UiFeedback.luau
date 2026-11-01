--!strict

-- Local, neutral input feedback. It never represents a server-confirmed result.
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Config = require(script.Parent.HeistAudioConfig)

local UiFeedback = {}
local started: {[Player]: boolean} = {}

local function effectsGain(player: Player): number
    local master = player:GetAttribute("MasterVolume")
    local effects = player:GetAttribute("EffectsVolume")
    return math.clamp(if type(master) == "number" then master else 1, 0, 1)
        * math.clamp(if type(effects) == "number" then effects else 1, 0, 1)
end

function UiFeedback.Start(player: Player)
    if started[player] then return end
    started[player] = true
    local spec = Config.Effects.UiClick
    local sound = Instance.new("Sound")
    sound.Name = "HeistUiClick"
    sound.SoundId = spec.SoundId
    sound.Volume = 0
    sound.Parent = SoundService
    task.spawn(function()
        pcall(function() ContentProvider:PreloadAsync({ sound }) end)
    end)
    local lastClick = -math.huge
    local bound: {[GuiButton]: boolean} = {}
    local function bind(instance: Instance)
        if not instance:IsA("GuiButton") or bound[instance] then return end
        bound[instance] = true
        local pressedAt = -math.huge
        local function respond()
            if not instance.Visible then return end
            local now = os.clock()
            if now - lastClick >= spec.MinInterval then
                lastClick = now
                local volume = spec.Volume * effectsGain(player)
                if volume > 0 and sound.IsLoaded then
                    sound:Stop()
                    sound.TimePosition = 0
                    sound.Volume = volume
                    sound:Play()
                end
            end
            if player:GetAttribute("ReduceMotion") == true
                or player:GetAttribute("LowEffects") == true then return end
            local scale = instance:FindFirstChild("InputFeedbackScale")
            if scale == nil then
                scale = Instance.new("UIScale")
                scale.Name = "InputFeedbackScale"
                scale.Parent = instance
            end
            local uiScale = scale :: UIScale
            uiScale.Scale = 0.96
            TweenService:Create(uiScale, TweenInfo.new(0.13, Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out), { Scale = 1 }):Play()
        end
        instance.InputBegan:Connect(function(input)
            local kind = input.UserInputType
            if kind ~= Enum.UserInputType.MouseButton1
                and kind ~= Enum.UserInputType.Touch then return end
            pressedAt = os.clock()
            respond()
        end)
        instance.Activated:Connect(function()
            -- Keyboard/gamepad activation has no mouse/touch press event on the
            -- button. Mouse/touch already received its immediate cue above.
            if os.clock() - pressedAt >= 0.6 then respond() end
        end)
        instance.Destroying:Connect(function() bound[instance] = nil end)
    end
    local gui = player:WaitForChild("PlayerGui")
    gui.DescendantAdded:Connect(bind)
    for _, descendant in gui:GetDescendants() do bind(descendant) end
end

return table.freeze(UiFeedback)
