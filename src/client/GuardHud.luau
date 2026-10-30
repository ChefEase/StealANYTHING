local Hud={}
local PhoneLayout=require(script.Parent.PhoneHudLayout)
function Hud.Start(player,screen)
    local panel=Instance.new("Frame")
    panel.Name="GuardWarning";panel.AnchorPoint=Vector2.new(.5,0)
    panel.Position=UDim2.new(.5,0,0,72);panel.Size=UDim2.fromOffset(290,58)
    panel.BackgroundColor3=Color3.fromRGB(37,28,23);panel.Visible=false;panel.ZIndex=20;panel.Parent=screen
    local constraint=Instance.new("UISizeConstraint");constraint.MaxSize=Vector2.new(330,72);constraint.Parent=panel
    Instance.new("UICorner",panel).CornerRadius=UDim.new(0,8)
    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,-16,0,24);title.Position=UDim2.fromOffset(8,3)
    title.BackgroundTransparency=1;title.TextColor3=Color3.fromRGB(255,214,126)
    title.Font=Enum.Font.GothamBold;title.TextSize=14;title.ZIndex=21;title.Parent=panel
    local detail=title:Clone();detail.Position=UDim2.fromOffset(8,26);detail.TextSize=12
    detail.Font=Enum.Font.Gotham;detail.Parent=panel
    local bar=Instance.new("Frame");bar.Position=UDim2.new(0,0,1,-4);bar.Size=UDim2.new(0,0,0,4)
    bar.BackgroundColor3=Color3.fromRGB(255,180,74);bar.BorderSizePixel=0;bar.ZIndex=21;bar.Parent=panel
    local tutorialUntil=0
    local function render()
        local state=player:GetAttribute("GuardState")
        panel.Visible=state~=nil or os.clock()<tutorialUntil
        local protected=player:GetAttribute("TutorialGuardProtected")==true or player:GetAttribute("TutorialReplayActive")==true
        title.Text=if not state or protected then "PRACTICE WARNING — YOUR ITEM IS SAFE"
            elseif state=="Suspicious" then "GUARD NOTICED YOU" elseif state=="Capture" then "MOVE AWAY — ABOUT TO BE CAUGHT"
            else "GUARD CHASING YOU"
        detail.Text=if not state or protected then "Normal depot items can be confiscated."
            elseif state=="Suspicious" then "Break sight before the warning fills."
            elseif state=="Capture" then "Get out of reach now!"
            else "Break sight behind a solid wall for 4 seconds."
        bar.Size=UDim2.new(if state=="Capture" then player:GetAttribute("GuardCaptureProgress") or 0
            elseif state=="Suspicious" then player:GetAttribute("GuardSuspicion") or 0 else 1,0,0,4)
        local width=screen.AbsoluteSize.X
        if PhoneLayout.IsPhone(screen) then
            local rect=PhoneLayout.Calculate(screen.AbsoluteSize).notice
            panel.AnchorPoint=Vector2.zero
            panel.Position=UDim2.fromOffset(rect.x,rect.y)
            panel.Size=UDim2.fromOffset(rect.w,rect.h)
            title.TextSize=12;detail.TextSize=11
            title.TextWrapped=true;detail.TextWrapped=true
            title.Text=if not state or protected then "PRACTICE — ITEM SAFE"
                elseif state=="Capture" then "MOVE AWAY!" else title.Text
            detail.Text=if not state or protected then "Your first item cannot be taken."
                elseif state=="Suspicious" then "Hide behind a solid wall."
                elseif state=="Capture" then "Get out of reach now!"
                else "Break sight for 4 seconds."
        else
            panel.AnchorPoint=Vector2.new(.5,0)
            panel.Size=UDim2.fromOffset(math.min(330,width-28),58)
            panel.Position=UDim2.new(.5,0,0,72)
        end
        -- Reserve the notification slot while the safety warning is visible.
        screen:SetAttribute("GuardWarningVisible",panel.Visible)
    end
    for _,name in {"GuardState","GuardSuspicion","GuardCaptureProgress"} do player:GetAttributeChangedSignal(name):Connect(render) end
    player:GetAttributeChangedSignal("GuardTutorialNotice"):Connect(function()
        tutorialUntil=os.clock()+4;render();task.delay(4,render)
    end)
    screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
    local hint=Instance.new("Frame")
    hint.Name="OptionalGuardHelp";hint.AnchorPoint=Vector2.new(.5,.5)
    hint.Position=UDim2.fromScale(.5,.54);hint.Size=UDim2.new(1,-28,0,144)
    hint.BackgroundColor3=Color3.fromRGB(19,38,38);hint.Visible=false;hint.ZIndex=30;hint.Parent=screen
    local cap=Instance.new("UISizeConstraint");cap.MaxSize=Vector2.new(340,144);cap.Parent=hint
    Instance.new("UICorner",hint).CornerRadius=UDim.new(0,9)
    local text=Instance.new("TextLabel")
    text.Position=UDim2.fromOffset(12,10);text.Size=UDim2.new(1,-24,0,82)
    text.BackgroundTransparency=1;text.TextColor3=Color3.new(1,1,1);text.TextSize=15
    text.Font=Enum.Font.Gotham;text.TextWrapped=true;text.ZIndex=31;text.Parent=hint
    local muted=false
    for index,caption in {"Got it","No more tips"} do
        local button=Instance.new("TextButton");button.Size=UDim2.new(.5,-18,0,34)
        button.Position=UDim2.new((index-1)*.5,12,1,-44);button.Text=caption
        button.BackgroundColor3=Color3.fromRGB(63,113,105);button.TextColor3=Color3.new(1,1,1)
        button.Font=Enum.Font.GothamBold;button.TextSize=14;button.ZIndex=31;button.Parent=hint
        button.Activated:Connect(function() hint.Visible=false;if index==2 then muted=true end end)
    end
    player:GetAttributeChangedSignal("NpcHintVersion"):Connect(function()
        if muted then return end
        local reason=player:GetAttribute("NpcHintReason")
        text.Text=if reason=="route_confusion" then "Route tip: open MENU → MAP and follow your museum marker. Stand on your green receiving carpet to deliver."
            elseif reason=="dropped_carry" then "Carry tip: dropping ends the depot run. Follow your museum marker to the green delivery carpet; use solid cover if a guard notices you."
            else "Guard tip: the yellow warning gives you time to hide. Put a solid wall between you and the guard for 4 seconds. A roof alone will not hide you."
        hint.Visible=true
    end)
    render()
end
return Hud
