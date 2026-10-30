local Visual = {}
function Visual.Create(parent, position)
    local model=Instance.new("Model")
    model.Name="DepotGuard"
    local function part(name,size,offset,color,shape)
        local p=Instance.new("Part")
        p.Name=name;p.Size=size;p.CFrame=CFrame.new(position)*offset;p.Color=color
        p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
        p.Material=Enum.Material.SmoothPlastic
        if shape then p.Shape=shape end
        p.Parent=model
        return p
    end
    local navy=Color3.fromRGB(35,49,66)
    local vest=Color3.fromRGB(245,150,51)
    local root=part("Root",Vector3.new(2.4,2.5,1.4),CFrame.identity,vest)
    part("Head",Vector3.new(1.5,1.5,1.5),CFrame.new(0,2,0),Color3.fromRGB(220,180,137),Enum.PartType.Ball)
    part("Cap",Vector3.new(1.7,.35,1.65),CFrame.new(0,2.65,0),navy)
    part("Brim",Vector3.new(1.6,.12,.7),CFrame.new(0,2.5,-.9),navy)
    local limbs={}
    for _,side in {-1,1} do
        local leg=part("Leg",Vector3.new(.85,1.5,.9),CFrame.new(side*.6,-1.9,0),navy)
        local arm=part("Arm",Vector3.new(.7,2,.8),CFrame.new(side*1.6,-.1,0),navy)
        table.insert(limbs,{part=leg,offset=CFrame.new(side*.6,-1.9,0),side=side})
        table.insert(limbs,{part=arm,offset=CFrame.new(side*1.6,-.1,0),side=-side})
        part("VestStripe",Vector3.new(.28,2.1,.06),CFrame.new(side*.7,.1,-.73),Color3.fromRGB(255,241,166))
        part("Eye",Vector3.new(.12,.12,.08),CFrame.new(side*.3,2.1,-.72),navy)
    end
    part("Badge",Vector3.new(.35,.45,.08),CFrame.new(.22,.5,-.76),Color3.fromRGB(255,228,100))
    model.PrimaryPart=root
    local billboard=Instance.new("BillboardGui")
    billboard.Name="GuardWarning";billboard.Size=UDim2.fromOffset(190,48)
    billboard.StudsOffsetWorldSpace=Vector3.new(0,4,0);billboard.MaxDistance=65
    billboard.AlwaysOnTop=false;billboard.Parent=root
    local label=Instance.new("TextLabel")
    label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=navy;label.BackgroundTransparency=.1
    label.TextColor3=Color3.new(1,1,1);label.Font=Enum.Font.GothamBold;label.TextSize=16
    label.Text="DEPOT GUARD";label.Parent=billboard
    Instance.new("UICorner",label).CornerRadius=UDim.new(0,8)
    model.Parent=parent
    return {model=model,root=root,label=label,limbs=limbs}
end
function Visual.Update(v, state, warning, moving, time)
    v.label.Text=if state=="Suspicious" then "?  NOTICED YOU  "..math.floor(warning*100).."%"
        elseif state=="Chase" then "!  CHASING" elseif state=="Capture" then "!  MOVE AWAY!"
        elseif state=="Investigation" then "?  HEARD A PICKUP"
        elseif state=="Search" then "?  SEARCHING"
        elseif state=="Return" then "RETURNING" else "DEPOT GUARD"
    v.label.TextColor3=if state=="Chase" or state=="Capture" then Color3.fromRGB(255,128,111)
        elseif state=="Suspicious" then Color3.fromRGB(255,220,111) else Color3.fromRGB(213,230,239)
    for _,limb in v.limbs do
        limb.part.CFrame=v.root.CFrame*limb.offset*CFrame.Angles(if moving then math.sin(time*10)*.32*limb.side else 0,0,0)
    end
end
function Visual.SetPivot(v,cf) v.model:PivotTo(cf) end
function Visual.Destroy(v) v.model:Destroy() end
return Visual
