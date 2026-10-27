-- Steal Anything: self-contained local filming player. Does not write profiles or gameplay state.
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")
local Config=require(script.Parent:WaitForChild("CinematicConfig"))
local player=Players.LocalPlayer
local scene=workspace:WaitForChild("StealAnythingCinematic")
local thief=scene:WaitForChild("Thief")
local owner=scene:WaitForChild("Owner")
local painting=scene:WaitForChild("MonaLisaPainting")
local backAlarm=painting:WaitForChild("BackAlarm")
local backAlarmLight=backAlarm:FindFirstChildOfClass("PointLight")
local barrier=scene.Set:WaitForChild("HomeProtection")
local barrierWaves={scene.Set:WaitForChild("BarrierWave1"),scene.Set:WaitForChild("BarrierWave2"),scene.Set:WaitForChild("BarrierWave3")}
local alarm=scene.Set.AlarmIndicator:FindFirstChildOfClass("PointLight")
local camera=workspace.CurrentCamera
local O=Config.StageOrigin
local smooth=function(x) x=math.clamp(x,0,1);return x*x*(3-2*x) end
local function lerp(a,b,u) return a+(b-a)*smooth(u) end
local function seg(t,a,b) return smooth((t-a)/(b-a)) end
local function v(x,y,z) return O+Vector3.new(x,y,z) end
local base={}
for _,m in ipairs({thief,owner,painting}) do
    for _,p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then base[p]=p.CFrame end end
end
local saved={}
local sounds={}
local overlapSounds={}
local cueFired={}
local playing=false
local frozenSecond=nil
local elapsed=0
local startClock=0
local conn
local cameraBefore
local hidden={}
local lightBefore
local cleanVisibility
local ui=Instance.new("ScreenGui")
ui.Name="StealAnythingCinematicControls";ui.ResetOnSpawn=false;ui.IgnoreGuiInset=true
ui.DisplayOrder=1000;ui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")
panel.Size=UDim2.fromOffset(400,38);panel.Position=UDim2.new(.5,-200,0,8)
panel.BackgroundColor3=Color3.fromRGB(25,27,37);panel.BackgroundTransparency=.15
panel.Parent=ui
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,8);corner.Parent=panel
local function button(n,text,x,w,callback)
    local b=Instance.new("TextButton");b.Name=n;b.Text=text;b.Font=Enum.Font.GothamBold;b.TextSize=13
    b.TextColor3=Color3.fromRGB(245,235,207);b.BackgroundColor3=Color3.fromRGB(71,74,91)
    b.Size=UDim2.fromOffset(w,30);b.Position=UDim2.fromOffset(x,4);b.Parent=panel
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    b.MouseButton1Click:Connect(callback)
    return b
end
local guide=Instance.new("Frame")
guide.Name="VerticalCropGuide";guide.BackgroundTransparency=1
guide.SizeConstraint=Enum.SizeConstraint.RelativeYY
guide.Size=UDim2.fromScale(9/16,1)
guide.AnchorPoint=Vector2.new(.5,.5);guide.Position=UDim2.fromScale(.5,.5)
guide.Visible=Config.ShowCropGuide;guide.Parent=ui
local guideStroke=Instance.new("UIStroke");guideStroke.Color=Color3.fromRGB(255,214,124)
guideStroke.Thickness=1;guideStroke.Transparency=.38;guideStroke.Parent=guide
local title=Instance.new("Frame")
title.Name="EndCard";title.Size=UDim2.fromScale(1,1);title.BackgroundColor3=Color3.fromRGB(18,22,39)
title.BackgroundTransparency=1;title.Visible=false;title.Parent=ui
local grad=Instance.new("UIGradient")
grad.Color=ColorSequence.new(Color3.fromRGB(25,28,50),Color3.fromRGB(9,19,31));grad.Rotation=90;grad.Parent=title
local function titleText(n,s,y,h,size,color)
    local q=Instance.new("TextLabel");q.Name=n;q.BackgroundTransparency=1
    q.AnchorPoint=Vector2.new(.5,.5);q.Position=UDim2.fromScale(.5,y)
    q.Size=UDim2.new(.52,0,h,0);q.SizeConstraint=Enum.SizeConstraint.RelativeYY
    q.Text=s;q.TextScaled=true
    q.TextColor3=color;q.Font=Enum.Font.GothamBlack;q.TextStrokeTransparency=.64
    q.Parent=title;return q
end
local titleBig=titleText("GameTitle","STEAL\nANYTHING",.41,.25,64,Color3.fromRGB(249,202,96))
local titleSoon=titleText("ComingSoon","COMING SOON",.59,.08,35,Color3.fromRGB(243,242,231))
local titleTag=titleText("Tagline","Getting it is the easy part.",.69,.047,20,Color3.fromRGB(166,222,222))
local titleLine=Instance.new("Frame");titleLine.AnchorPoint=Vector2.new(.5,.5)
titleLine.Position=UDim2.fromScale(.5,.535);titleLine.Size=UDim2.new(.27,0,0,2)
titleLine.SizeConstraint=Enum.SizeConstraint.RelativeYY
titleLine.BackgroundColor3=Color3.fromRGB(225,68,74);titleLine.BorderSizePixel=0;titleLine.Parent=title
local titleOut=Instance.new("Frame")
titleOut.Name="TitleFadeOut";titleOut.Size=UDim2.fromScale(1,1)
titleOut.BackgroundColor3=Color3.new(0,0,0);titleOut.BackgroundTransparency=1
titleOut.BorderSizePixel=0;titleOut.ZIndex=5;titleOut.Parent=title
-- Sound slots are named in Config. Music IDs can be assigned there without touching the timeline.
local audioFolder=Instance.new("Folder");audioFolder.Name="CinematicAudio";audioFolder.Parent=SoundService
for n,spec in pairs(Config.Sounds) do
    local s=Instance.new("Sound");s.Name=n;s.Volume=spec.volume or .5;s.SoundId=spec.id or ""
    s.Looped=n=="OpeningMusic" or n=="Alarm" or n=="ChaseMusic"
        or n=="OfficerFootsteps" or n=="Footsteps" or n=="FastFootsteps" or n=="Huffs"
    s.Parent=audioFolder;sounds[n]=s
    if spec.overlap then
        local fill=s:Clone()
        fill.Name=n.."Overlap";fill.Volume=s.Volume*.7;fill.Parent=audioFolder
        overlapSounds[n]=fill
    end
end
local function hideAvatar()
    local char=player.Character
    if not char then return end
    for _,q in ipairs(char:GetDescendants()) do
        if q:IsA("BasePart") then hidden[q]=q.LocalTransparencyModifier;q.LocalTransparencyModifier=1 end
    end
end
local function restoreAvatar()
    for q,a in pairs(hidden) do if q.Parent then q.LocalTransparencyModifier=a end end
    table.clear(hidden)
end
local function pos(keys,t)
    if t<=keys[1][1] then return keys[1][2],keys[1][3],keys[1][4] end
    for i=1,#keys-1 do
        local a,b=keys[i],keys[i+1]
        if t<=b[1] then
            local u=seg(t,a[1],b[1])
            return lerp(a[2],b[2],u),lerp(a[3],b[3],u),lerp(a[4],b[4],u)
        end
    end
    local k=keys[#keys];return k[2],k[3],k[4]
end
local function pathMotion(keys,t)
    local traveled=0
    for i=1,#keys-1 do
        local a,b=keys[i],keys[i+1]
        local length=Vector2.new(b[2]-a[2],b[3]-a[3]).Magnitude
        if t>=b[1] then
            traveled+=length
        elseif t>a[1] then
            local u=math.clamp((t-a[1])/(b[1]-a[1]),0,1)
            return traveled+length*smooth(u),length*6*u*(1-u)/(b[1]-a[1])
        else
            return traveled,0
        end
    end
    return traveled,0
end
local thiefKeys={
    {0,0,-8,math.pi},{2,0,-8,math.pi},{3.8,0,-8,math.pi},{4.45,1,-6,4.15},
    {6.85,9,-.4,3*math.pi/2},{7.48,10.0,0,3*math.pi/2},
    {8.25,10.0,0,3*math.pi/2},{9.2,10.8,0,3*math.pi/2},
    {10.8,14.2,0,3*math.pi/2},{11.1,14.7,0,3*math.pi/2},
    {14.8,31.8,0,3*math.pi/2},{16.15,36.8,0,3*math.pi/2},
    {17.9,39.0,-1.2,3*math.pi/2},{18.8,40.5,-3.5,5.3},
    {20.95,40.5,-3.5,5.3},{24,40.5,-3.5,5.3},
}
local ownerKeys={
    {0,5,6,0},{2.0,5,6,0},{2.65,4,3,0},{3.8,3.1,1,0},
    {4.25,3.1,1,-math.pi/2},{6.8,7.8,-.4,-math.pi/2},
    {7.7,9,0,-math.pi/2},{9.7,10.7,0,-math.pi/2},
    {11,13,0,-math.pi/2},{14.85,29.3,0,-math.pi/2},
    {16.25,33.7,0,-math.pi/2},{24,33.7,0,-math.pi/2},
}
local bodyParts={}
for _,actor in ipairs({thief,owner}) do
    local d={}
    for _,p in ipairs(actor:GetChildren()) do if p:IsA("BasePart") then d[p.Name]=p end end
    bodyParts[actor]=d
end
local function face(actor,mode)
    local f=bodyParts[actor].Head.Face
    local mouth=f.Mouth
    if mode=="shock" then
        mouth.Position=UDim2.fromScale(.44,.65);mouth.Size=UDim2.fromScale(.12,.18)
    elseif mode=="smile" then
        mouth.Position=UDim2.fromScale(.37,.72);mouth.Size=UDim2.fromScale(.26,.06)
    elseif mode=="angry" then
        mouth.Position=UDim2.fromScale(.37,.72);mouth.Size=UDim2.fromScale(.26,.07)
    else
        mouth.Position=UDim2.fromScale(.4,.7);mouth.Size=UDim2.fromScale(.2,.055)
    end
    f.LeftBrow.Rotation=mode=="angry" and 20 or (mode=="shock" and -12 or -5)
    f.RightBrow.Rotation=mode=="angry" and -20 or (mode=="shock" and 12 or 5)
end
local function pose(actor,t,x,z,yaw,run,lean,armMode,react,distance,speed)
    local d=bodyParts[actor]
    local floor=O+Vector3.new(x,0,z)
    local phase=(run and distance*2.65 or t*2.2)+(actor==owner and 1.5 or 0)
    local effort=math.clamp(speed/6,0,1)
    local stride=run and math.sin(phase)*effort or 0
    local bounce=run and .10*math.abs(math.sin(phase))*effort or .025*math.sin(t*3)
    local root=CFrame.new(floor+Vector3.new(0,bounce,0))*CFrame.Angles(0,yaw,0)
    local function set(n,off,rot)
        local p=d[n];if p then p.CFrame=root*CFrame.new(off)*CFrame.Angles(rot.X,rot.Y,rot.Z) end
    end
    local torsoLean=lean or 0
    set("Torso",Vector3.new(0,2.7,0),Vector3.new(torsoLean,0,.03*stride))
    set("Hips",Vector3.new(0,1.72,0),Vector3.new(torsoLean*.35,0,0))
    local headTilt=react=="lookback" and .22 or (react=="bonk" and -.26 or (react=="admire" and -.13 or 0))
    local headYaw=react=="lookback" and 1.45 or (react=="admire" and .32 or 0)
    set("Head",Vector3.new(0,4.12,0),Vector3.new(headTilt,headYaw,.05*stride))
    for _,n in ipairs({"CapBrim","CapCrown","HatBrim","HatCrown"}) do
        local p=d[n]
        if p then local localCf=p:GetAttribute("CinematicLocal");p.CFrame=root*CFrame.new(0,4.12,0)*CFrame.Angles(headTilt,headYaw,0)*CFrame.new(0,-4.12,0)*localCf end
    end
    for _,n in ipairs({"Scarf","Satchel","Badge"}) do
        local p=d[n];if p then p.CFrame=root*p:GetAttribute("CinematicLocal")*CFrame.Angles(torsoLean*.4,0,0) end
    end
    local carry=armMode=="carry" or armMode=="rotate" or armMode=="place" or armMode=="wave"
    for _,side in ipairs({-1,1}) do
        local prefix=side<0 and "Left" or "Right"
        local cycle=run and stride*side or 0
        local armPitch=carry and -.65 or (run and cycle*.85 or 0)
        if armMode=="wave" and side==1 then armPitch=-2.45 end
        if armMode=="fold" then armPitch=-1.15 end
        if armMode=="knock" then armPitch=-1.3 end
        local z=carry and -.39 or (armMode=="fold" and -.42 or 0)
        local handZ=carry and -1.72 or (armMode=="fold" and -.72 or (run and cycle*.42 or 0))
        local turnGrip=seg(t,8.42,9.22)-seg(t,10.35,11.05)
        local elbowX=carry and side*lerp(1.82,.65,turnGrip) or side*1.15
        local handX=carry and side*lerp(2.55,.76,turnGrip) or side*1.15
        local elbowY=carry and 2.45 or 1.86
        local handY=carry and 2.22 or 1.34
        if armMode=="wave" and side==1 then elbowY=3.18;handY=4.0;handZ=-.35;elbowX=side*1.15;handX=side*1.15 end
        if armMode=="knock" and side==1 then elbowY=2.95;handY=3.0;handZ=-.8 end
        set(prefix.."UpperArm",Vector3.new(side*1.15,2.78,z),Vector3.new(armPitch,0,side*(carry and -.14 or .06)))
        set(prefix.."LowerArm",Vector3.new(elbowX,elbowY,handZ*.62),Vector3.new(armPitch*.4,0,0))
        set(prefix.."Hand",Vector3.new(handX,handY,handZ),Vector3.new(0,0,0))
        local leg=run and stride*side or 0
        local ly=run and math.max(0,leg)*.17 or 0
        set(prefix.."UpperLeg",Vector3.new(side*.45,1.18,-leg*.29),Vector3.new(leg*.5,0,0))
        set(prefix.."LowerLeg",Vector3.new(side*.45,.43+ly,-leg*.43),Vector3.new(-math.max(0,leg)*.55,0,0))
        set(prefix.."Shoe",Vector3.new(side*.45,.13+ly,-.16-leg*.48),Vector3.new(0,0,0))
    end
    local expression=(react=="bonk" or react=="flinch") and "shock"
        or (actor==owner and t>=3 and "angry" or (actor==thief and t>18 and "smile" or "neutral"))
    face(actor,expression)
    return root
end
local paintOffsets={}
for _,p in ipairs(painting:GetDescendants()) do if p:IsA("BasePart") then paintOffsets[p]=p:GetAttribute("LocalOffset") end end
local function paint(cf)
    for p,offset in pairs(paintOffsets) do p.CFrame=cf*offset end
end
local function paintingPose(t,root)
    local target
    if t<1.2 then
        target=CFrame.new(v(0,lerp(5,4.6,seg(t,0,1.2)),-12.95+6.35*seg(t,0,1.2)))
    elseif t<18.1 then
        -- Canvas front is the +Z face. Broad side projects across the narrow Z opening.
        local twist=math.pi/2*(seg(t,8.42,9.22)-seg(t,10.35,11.05))
        local bonk=t>=7.4 and t<=8.4 and math.sin(math.pi*seg(t,7.4,8.4))*.28 or 0
        local side=-3.0*seg(t,2.45,3.0)*(1-seg(t,3.67,4.3))
        local hold=root*CFrame.new(side,2.8,-1.35+bonk)*CFrame.Angles(0,math.pi+twist,0)
        if t<2 then hold=CFrame.new(v(0,4.6,-6.6)) end
        target=hold
    elseif t<18.55 then
        target=CFrame.new(v(58,lerp(4.4,6.8,seg(t,18.1,18.55)),-4.65))*CFrame.Angles(0,0,math.pi*seg(t,18.1,18.55))
    elseif t<20.15 then
        target=CFrame.new(v(58,6.8,-4.65))*CFrame.Angles(0,0,math.pi)
    else
        target=CFrame.new(v(70,6.8,-4.65))*CFrame.Angles(0,0,math.pi*(1-seg(t,20.15,20.48)))
    end
    paint(target)
end
-- Revised performance: standard R6 joint animation, continuous movement, and
-- a painting that stays mounted until the thief actually lifts it.
thiefKeys={
    {0,3.4,-12.0,math.pi/2},{1.05,3.4,-12.0,math.pi/2},{1.6,5.6,-12.0,math.pi},
    {2.9,5.6,-12.0,math.pi},{3.35,4.0,-12.0,math.pi},{3.8,3.4,-12.0,math.pi},
    {4.18,2.6,-9.8,2.6},{4.85,-2.3,-6.6,2.45},
    {5.22,-2.2,-5.9,4.1},{5.85,2.7,-1.2,4.15},
    {6.95,8.55,-.45,3*math.pi/2},
    {7.42,10.45,0,3*math.pi/2},{7.76,12.1,0,3*math.pi/2},
    {8.2,14.3,0,3*math.pi/2},{8.55,16.15,0,3*math.pi/2},
    {8.9,18.0,0,3*math.pi/2},{9.4,20.6,0,3*math.pi/2},
    {10.4,26.2,0,3*math.pi/2},{11.2,31.3,0,3*math.pi/2},
    {13.3,46.0,0,3*math.pi/2},
    {14.85,57,0,3*math.pi/2},{16.0,64,0,3*math.pi/2},
    {17.75,67.3,0,3*math.pi/2},{18.38,67.4,0,math.pi/2},
    {19.1,67.4,0,math.pi/2},{21,67.4,0,math.pi/2},
}
ownerKeys={
    {0,14,2,math.pi/2},{2.0,14,2,math.pi/2},
    {2.65,10.5,1.2,1.25},{3.65,7.8,-1,.72},
    {4.12,7.2,-3.4,.75},{4.45,5.8,-7.2,.7},{4.9,1.7,-8.1,.7},
    {5.4,0,-9.0,1.8},{6.15,2.0,-8.3,4.0},
    {6.55,5.8,-8.1,4.45},{6.95,7.0,-5.3,4.65},{7.42,6.4,-3.4,4.7},
    {7.75,7.7,-2.5,4.71},{8.2,9.3,-1.7,4.71},
    {8.55,10.9,-1.2,4.71},{8.9,12.6,-.4,4.71},
    {9.4,14.8,0,4.71},{10.4,19.9,0,4.71},
    {11.2,24.9,0,3*math.pi/2},{13.3,39.5,0,3*math.pi/2},
    {14.8,49.5,0,3*math.pi/2},{16.18,58,0,3*math.pi/2},
    {16.75,60.7,0,3*math.pi/2},{17.02,62.1,0,3*math.pi/2},
    {18.1,62.1,-1.3,3*math.pi/2},{19.1,61.2,-3.1,3*math.pi/2},
    {20.3,61.2,-3.1,3*math.pi/2},{20.78,62.1,-1.3,3*math.pi/2},
    {21,62.1,-1.3,3*math.pi/2},
}
local function spline(keys,t,col)
    if t<=keys[1][1] then return keys[1][col] end
    for i=1,#keys-1 do
        local a,b=keys[i],keys[i+1]
        if t<=b[1] then
            local prev=keys[math.max(1,i-1)]
            local next=keys[math.min(#keys,i+2)]
            local dt=b[1]-a[1]
            local m0=(b[col]-prev[col])/(b[1]-prev[1])
            local m1=(next[col]-a[col])/(next[1]-a[1])
            if i==1 then m0=0 end
            if i==#keys-1 then m1=0 end
            local u=(t-a[1])/dt
            return (2*u^3-3*u^2+1)*a[col]+(u^3-2*u^2+u)*dt*m0
                +(-2*u^3+3*u^2)*b[col]+(u^3-u^2)*dt*m1
        end
    end
    return keys[#keys][col]
end
local function chaseOffset(t)
    return 24*math.clamp((t-8.55)/(16.0-8.55),0,1)
end
pos=function(keys,t) return spline(keys,t,2)+chaseOffset(t),spline(keys,t,3),spline(keys,t,4) end
pathMotion=function(keys,t)
    local d=0
    local lastX,lastZ=pos(keys,0)
    local step=.08
    for s=step,t,step do
        local x,z=pos(keys,s)
        d+=(Vector2.new(x-lastX,z-lastZ)).Magnitude
        lastX,lastZ=x,z
    end
    local x,z=pos(keys,t)
    d+=(Vector2.new(x-lastX,z-lastZ)).Magnitude
    local x0,z0=pos(keys,math.max(0,t-.025))
    local x1,z1=pos(keys,math.min(24,t+.025))
    return d,(Vector2.new(x1-x0,z1-z0)).Magnitude/.05
end
local RunClip=require(script.Parent.CinematicRunClip)
local WalkClip=require(script.Parent.CinematicWalkClip)
local function prepareFrames(clip)
    local frames={}
    for _,row in ipairs(clip.frames) do
        local frame={time=row[1],poses={}}
        for i,name in ipairs(clip.names) do
            frame.poses[name]=CFrame.new(table.unpack(row[i+1]))
        end
        table.insert(frames,frame)
    end
    return frames
end
local runFrames=prepareFrames(RunClip)
local walkFrames=prepareFrames(WalkClip)
local function sampleFrames(frames,names,cycle)
    for i=1,#frames-1 do
        local a,b=frames[i],frames[i+1]
        if cycle<=b.time then
            local alpha=math.clamp((cycle-a.time)/(b.time-a.time),0,1)
            local out={}
            for _,name in ipairs(names) do
                out[name]=a.poses[name]:Lerp(b.poses[name],alpha)
            end
            return out
        end
    end
    return frames[#frames].poses
end
local function sampleRun(t,actor)
    -- The authored R6 loop plays at a brisk 2.3 cycles per second. Travel
    -- speed rises separately as the chase enters the longer street.
    local cycle=(((t-4.18)*2.3+(actor==owner and .36 or 0))%1)*RunClip.duration
    return sampleFrames(runFrames,RunClip.names,cycle)
end
local function sampleWalk(t)
    local cycle=(((t-2.02)*1.45)%1)*WalkClip.duration
    return sampleFrames(walkFrames,WalkClip.names,cycle)
end
local joints={}
for _,actor in ipairs({thief,owner}) do
    local j={}
    for _,v in ipairs(actor:GetDescendants()) do
        if v:IsA("Motor6D") then j[v.Name]=v end
    end
    joints[actor]=j
end
face=function(actor,mode)
    local decal=actor.Head:FindFirstChild("CinematicExpression")
    if not decal then return end
    local ids={neutral="rbxassetid://135806968456855",shock="rbxassetid://112080603129404",
        angry="rbxassetid://78179118958530",smile="rbxassetid://118915171997573",
        nervous="rbxassetid://82964912479810",determined="rbxassetid://125405440883631"}
    local target=ids[mode] or ids.neutral
    if decal.Texture~=target then decal.Texture=target end
end
pose=function(actor,t,x,z,yaw,run,lean,armMode,react,distance,speed)
    local j=joints[actor]
    local walking=actor==owner and not run and t>=2.02 and t<4.10
    local walkWeight=walking and seg(t,2.02,2.20)*(1-seg(t,3.90,4.10))
        *math.clamp(speed/3,0,1) or 0
    local clip=run and sampleRun(t,actor) or (walking and sampleWalk(t) or nil)
    local effort=run and math.clamp(speed/6,.85,1) or 0
    local phase=distance*1.85+(actor==owner and 1.3 or 0)
    local stride=run and math.sin(phase)*effort or 0
    local bounce=run and .025*math.abs(math.sin(phase))*effort or 0
    local impact=0
    local barrierHit=actor==owner and (seg(t,16.96,17.06)-seg(t,17.18,17.30)) or 0
    local doorLunge=0
    local dodge=actor==thief and seg(t,4.35,4.55)*(1-seg(t,5.03,5.32)) or 0
    local overreach=actor==owner and seg(t,4.35,4.6)*(1-seg(t,5.2,5.7)) or 0
    local function hit(at)
        local d=(t-at)/.075
        return math.exp(-d*d)
    end
    local knock=hit(17.30)+hit(17.52)+hit(17.74)+hit(20.76)
    local crouch=.45*impact+.34*barrierHit+.38*dodge+.08*doorLunge
    local root=CFrame.new(v(x,4.25+bounce-crouch,z))*CFrame.Angles(0,yaw,0)
    actor:PivotTo(root)
    local function joint(n,rx,ry,rz)
        local motor=j[n]
        if motor then
            local motion=CFrame.new()
            if clip then
                local poseName=({RootJoint="Torso",Neck="Head",["Right Shoulder"]="Right Arm",
                    ["Left Shoulder"]="Left Arm",["Right Hip"]="Right Leg",["Left Hip"]="Left Leg"})[n]
                if poseName and poseName~="Torso"
                    and (actor==owner or poseName~="Right Arm" and poseName~="Left Arm") then
                    local sampled=clip[poseName]
                    if walking and (poseName=="Right Arm" or poseName=="Left Arm")
                        and t>=3.90 then sampled=nil end
                    if sampled then motion=walking and motion:Lerp(sampled,walkWeight) or sampled end
                end
            end
            motor.C0=motor:GetAttribute("CinematicC0")*motion*CFrame.Angles(rx or 0,ry or 0,rz or 0)
        end
    end
    local hold=actor==thief and t<19.12
    local reach=actor==thief and seg(t,.08,.58) or 0
    local rightX,rightY,rightZ=0,0,.08
    local leftX,leftY,leftZ=0,0,-.08
    if hold then
        rightX=-.25*reach;leftX=-.25*reach
        rightY=1.42*reach;leftY=-1.42*reach
        rightZ=.13;leftZ=-.13
        -- Keep both hands on the frame while the legs and torso drive the sprint.
    elseif run then
        -- The imported R6 sprint supplies the officer's arm pump.
        rightX=0;leftX=0;rightY=0;leftY=0;rightZ=0;leftZ=0
    end
    if actor==thief and t>=3.17 and t<3.72 then
        rightX=-2.25+math.sin(t*14)*.13;rightY=0;rightZ=.14
    end
    if actor==thief and t<1.9 then
        local grab=seg(t,.08,.45)*(1-seg(t,1.43,1.9))
        rightX=rightX+(2.2-rightX)*grab
        rightY=rightY+(.2-rightY)*grab
        rightZ=rightZ+(.6-rightZ)*grab
        leftX=leftX+(1.2-leftX)*grab
        leftY=leftY*(1-grab)
        leftZ=leftZ+(-1.0-leftZ)*grab
    end
    if actor==thief and t>=19.15 then
        local shrug=seg(t,19.82,20.05)*(1-seg(t,20.55,20.8))
        rightX=-1.28;leftX=-1.28;rightY=.2;leftY=-.2
        rightZ=-.42-.24*shrug;leftZ=.42+.24*shrug
    end
    if actor==owner and t>=4.05 and t<4.82 then
        rightX=-.28;leftX=-.28
        rightY=1.5;leftY=-1.5
    end
    if actor==owner and t>=7.5 and t<8.32 then
        rightX-=1.25*doorLunge;rightY+=.42*doorLunge
        leftX-=.38*doorLunge;leftY-=.22*doorLunge
    end
    if actor==owner and t>=17.15 and t<17.88 then
        rightX=-.35-.2*knock;rightY=1.25+.22*knock
    end
    if actor==owner and t>=19.35 and t<20.45 then
        rightX=-2.1;rightY=1.1;rightZ=-.1
    end
    if actor==owner and t>=20.68 and t<21 then
        rightX=-.42;rightY=1.45+.3*knock;rightZ=-.08
    end
    joint("Right Shoulder",rightX,rightY,rightZ)
    joint("Left Shoulder",leftX,leftY,leftZ)
    -- R6 hips are mounted with a 90-degree yaw. Their local Z axis drives
    -- forward/back leg swing; local Y only twists the feet sideways.
    local legSwing=0
    joint("Right Hip",0,0,legSwing)
    joint("Left Hip",0,0,legSwing)
    local lookback=react=="lookback" and seg(t,12.45,12.7)*(1-seg(t,13.15,13.47)) or 0
    local headTilt=react=="bonk" and -.35 or (react=="admire" and .2 or (react=="notice" and -.26 or 0))
    if actor==owner and t>=19.35 and t<20.45 then headTilt=.23 end
    joint("Neck",headTilt-.22*(actor==thief and knock or 0),lookback*1.0,(react=="flinch" and .12 or 0)+.2*(actor==thief and knock or 0))
    joint("RootJoint",(lean or 0)+.28*impact+.34*barrierHit+.3*doorLunge+.17*(actor==thief and knock or 0)+.2*overreach,
        run and 0 or .02*stride,(run and 0 or .035*stride)-.32*dodge)
    face(actor,actor==owner and (t>=2.58 and t<3.25 and "shock" or (t>=3.25 and "angry" or "neutral"))
        or (react=="bonk" or (actor==thief and knock>.25)) and "shock"
        or (t>=19.15 and t<19.85 and "smile" or ((react=="notice" or (t>=3 and t<4.12)) and "nervous" or
        ((run or dodge>.2) and "determined" or "neutral"))))
    return actor.HumanoidRootPart.CFrame
end
paintingPose=function(t,root)
    local wall=CFrame.new(v(0,5,-12.95))
    local side=3.15*seg(t,2.82,3.25)*(1-seg(t,3.72,4.25))
        +2.25*seg(t,5.25,5.65)*(1-seg(t,7.0,7.36))
    local showArt=seg(t,2.82,3.25)*(1-seg(t,3.72,4.25))
    local carryDepth=1.0+1.08*seg(t,3.8,4.5)
    local chaseArt=math.rad(30)*seg(t,9.45,10.05)*(1-seg(t,14.25,15.0))
    local held=root*CFrame.new(side,1.42,-carryDepth)*CFrame.Angles(0,math.pi*showArt+chaseArt,0)
    if t<.55 then
        paint(wall)
    elseif t<.96 then
        -- The top edge rocks free while its centre stays at the display.
        local u=seg(t,.55,.96)
        paint(wall*CFrame.new(0,0,.24*u)*CFrame.Angles(-.22*u,0,0))
    elseif t<1.15 then
        -- Pull the frame straight away from the wall before moving it across
        -- the thief. The surface never crosses his torso.
        local u=seg(t,.96,1.15)
        paint(CFrame.new(v(0,5,-12.71+2.46*u))*CFrame.Angles(-.22*(1-u),0,0))
    elseif t<1.45 then
        paint(CFrame.new(v(3.4*seg(t,1.15,1.45),5,-10.25)))
    elseif t<3.25 then
        paint(CFrame.new(v(3.4,5,-10.25)))
    elseif t<3.72 then
        paint(CFrame.new(v(3.4,5,-10.25)):Lerp(held,seg(t,3.25,3.72)))
    elseif t<18.3 then
        -- The widened opening clears the 4.74-stud frame at sprint speed.
        paint(held)
    else
        -- He tries to conceal an enormous frame behind his back, circling it
        -- around his right side so it never passes through his torso.
        local sideMove=3.6*seg(t,18.3,18.65)*(1-seg(t,18.92,19.25))
        local back=-2.08+3.13*seg(t,18.65,18.92)
        local crooked=math.rad(11)*seg(t,19.03,19.27)
        paint(root*CFrame.new(sideMove,1.42,back)*CFrame.Angles(0,0,crooked))
    end
end
local shots={
    {0,.55,Vector3.new(0,5.0,-4.0),Vector3.new(.2,4.9,-4.5),Vector3.new(.8,4.4,-12.7)},
    {.55,.97,Vector3.new(-6,5.0,2),Vector3.new(-5.5,4.8,1.5),Vector3.new(1.6,4.5,-12.7)},
    {.97,1.55,Vector3.new(9.0,5.7,-2.2),Vector3.new(8.4,5.4,-3.0),Vector3.new(2.75,4.8,-12.4)},
    {1.55,2,Vector3.new(7.0,5.5,0),Vector3.new(7.2,5.5,-.4),Vector3.new(5.2,4.5,-10.6)},
    {2,3.16,Vector3.new(4.5,5.2,6.0),Vector3.new(5.5,4.9,5.0),Vector3.new(10,3.4,1)},
    {3.16,4,Vector3.new(7,4.9,-8),Vector3.new(7.5,4.6,-7.5),Vector3.new(3.3,3.5,-11.5)},
    {4,4.55,Vector3.new(-7,4.9,-10),Vector3.new(-6,4.5,-9),Vector3.new(2,3.2,-8)},
    {4.55,5.35,Vector3.new(-10,4.5,-6),Vector3.new(-9,4.2,-6.5),Vector3.new(-1,3,-6.5)},
    {5.35,7,Vector3.new(-10,5.1,-6),Vector3.new(-9,4.7,-6),Vector3.new(5,3,-4)},
    {7,8.7,Vector3.new(4.7,4.6,10.4),Vector3.new(5.5,4.1,9.2),Vector3.new(9.5,3.5,0)},
    {8.7,9.55,Vector3.new(17,4.8,10),Vector3.new(20,4.7,11),Vector3.new(13,3.2,0)},
    {9.55,11,Vector3.new(21,4.4,10.8),Vector3.new(24,4.2,10.8),Vector3.new(17.5,3.1,0)},
    {11,12.25,Vector3.new(28,2.6,11.5),Vector3.new(37,2.6,11.5),Vector3.new(32,2.8,0)},
    {12.25,13.3,Vector3.new(39,4.1,10),Vector3.new(47,4.1,10),Vector3.new(43,3.2,0)},
    {13.3,15,Vector3.new(46,5.7,14),Vector3.new(58,5.4,14),Vector3.new(53,2.7,0)},
    {15,16.3,Vector3.new(55.5,4.7,6.2),Vector3.new(57.3,4.5,6.2),Vector3.new(62,3.0,0)},
    {16.3,16.9,Vector3.new(72.2,4.7,6.3),Vector3.new(71.8,4.5,5.8),Vector3.new(66.2,3.0,0)},
    {16.9,18,Vector3.new(55.5,4.3,9.5),Vector3.new(56.5,4.1,9.0),Vector3.new(64.5,3.0,0)},
    {18,19.13,Vector3.new(72,5.0,2.7),Vector3.new(71.8,4.7,2.4),Vector3.new(67.8,3.5,0)},
    {19.13,20.35,Vector3.new(59.5,4.8,4.0),Vector3.new(60.5,4.7,3.6),Vector3.new(67.4,3.5,0)},
    {20.35,21,Vector3.new(60.5,4.8,1.5),Vector3.new(61.0,4.7,1.2),Vector3.new(67.4,3.5,0)},
}
local function cameraAt(t)
    local shot=shots[#shots]
    for _,q in ipairs(shots) do if t>=q[1] and t<q[2] then shot=q;break end end
    local u=seg(t,shot[1],shot[2])
    local shift=Vector3.new(chaseOffset(t),0,0)
    local p=shot[3]:Lerp(shot[4],u)+shift
    local focus=shot[5]+shift
    if shot[1]==5.35 then
        local tx,tz=pos(thiefKeys,t)
        local ox,oz=pos(ownerKeys,t)
        focus=Vector3.new((tx+ox)/2,3,(tz+oz)/2)
    elseif shot[1]==4 then
        local x,z=pos(thiefKeys,t)
        focus=Vector3.new(x+1,3,z)
    elseif shot[1]==4.55 then
        local tx,tz=pos(thiefKeys,t)
        local ox,oz=pos(ownerKeys,t)
        focus=Vector3.new((tx+ox)/2,3,(tz+oz)/2)
    elseif shot[1]==2 then
        local x,z=pos(ownerKeys,t)
        focus=Vector3.new(x,3.4,z)
    elseif shot[1]==11 then
        local tx,tz=pos(thiefKeys,t)
        local ox,oz=pos(ownerKeys,t)
        local mid=(tx+ox)/2
        p=Vector3.new(mid+3,3.2,14)
        focus=Vector3.new(mid+2.5,2.8,(tz+oz)/2)
    elseif shot[1]==12.25 then
        local tx,tz=pos(thiefKeys,t)
        p=Vector3.new(tx+3,4.1,10)
        focus=Vector3.new(tx+1,3.2,tz)
    elseif shot[1]==8.7 then
        local tx=pos(thiefKeys,t)
        local ox=pos(ownerKeys,t)
        focus=Vector3.new((tx+ox)/2,3.2,0)
    elseif shot[1]==9.55 then
        local tx=pos(thiefKeys,t)
        local ox=pos(ownerKeys,t)
        local mid=(tx+ox)/2
        p=Vector3.new(mid+4,4.3,10.8)
        focus=Vector3.new(mid,3.1,0)
    elseif shot[1]==13.3 then
        local tx=pos(thiefKeys,t)
        local ox=pos(ownerKeys,t)
        local mid=(tx+ox)/2
        p=Vector3.new(mid+4,5.5,14)
        focus=Vector3.new(mid+2.5,2.9,0)
    elseif shot[1]==15 then
        local x=pos(thiefKeys,t)
        focus=Vector3.new(x+2.5,2.9,0)
    end
    local function bump(at,power)
        local d=t-at
        if d<0 or d>.32 then return 0 end
        return power*math.exp(-d*13)*math.sin(d*85)
    end
    local shake=bump(4.76,.07)+bump(5.20,.06)
        +bump(16.96,.14)+bump(20.76,.10)
    local chase=math.clamp(seg(t,4.1,4.6)*(1-seg(t,7.0,7.4))
        +seg(t,9.2,9.7)*(1-seg(t,15.1,15.6)),0,1)
    p+=Vector3.new(shake+.035*chase*math.sin(t*16),.55*shake+.025*chase*math.sin(t*21),0)
    camera.CFrame=CFrame.lookAt(O+p,O+focus)*CFrame.Angles(0,0,.007*chase*math.sin(t*13))
    local fov= t<.97 and 42 or (t<1.55 and 45 or (t<2 and 42 or (t<4 and 44 or
        (t<7 and 46 or (t<11 and 44 or (t<15 and 43 or (t<19.13 and 40 or (t<20.35 and 54 or 45))))))))
    if t>=.55 and t<.97 then fov=60 end
    if t>=4 and t<5.35 then fov=49+3*math.sin(math.pi*seg(t,4,5.35)) end
    if t>=5.35 and t<7 then fov=59+11*seg(t,5.35,7) end
    if t>=7 and t<8.7 then fov=61 end
    if t>=8.7 and t<9.55 then fov=58 end
    if t>=9.55 and t<11 then fov=58 end
    if t>=11 and t<12.25 then fov=75 end
    if t>=12.25 and t<13.3 then fov=56 end
    if t>=13.3 and t<15 then fov=70 end
    if t>=15 and t<16.3 then fov=53 end
    if t>=16.9 and t<18 then fov=52 end
    if t>=18 and t<19.13 then fov=48 end
    if t>=7.4 and t<8.2 then fov-=4*(1-seg(t,7.4,8.2)) end
    if t>=4.55 and t<5.35 then fov-=3*math.sin(math.pi*seg(t,4.55,5.35)) end
    camera.FieldOfView=fov
end
local function setLighting(t)
    Lighting.ClockTime=t<11 and 22.4 or 22.8
    Lighting.Brightness=t<11 and 1.45 or 1.55
    Lighting.ExposureCompensation=t<11 and -.28 or -.22
    Lighting.Ambient=t<11 and Color3.fromRGB(74,82,103) or Color3.fromRGB(57,74,99)
    Lighting.OutdoorAmbient=t<11 and Color3.fromRGB(66,77,99) or Color3.fromRGB(54,73,101)
    local alarmOn=t>=1.16 and t<7.4 and math.sin(t*22)>0
    alarm.Brightness=alarmOn and 2.4 or 0
    local stolenAlarm=t>=19.12 and t<21 and math.sin(t*24)>0
    backAlarm.Transparency=stolenAlarm and 0 or (t>=19.12 and t<21 and .25 or 1)
    backAlarmLight.Brightness=stolenAlarm and 6.0 or 0
    local shieldOn=t>=16.25 and t<18
    local shieldHit=seg(t,16.91,16.99)*(1-seg(t,17.09,17.32))
    barrier.Transparency=shieldOn and (.43-.27*shieldHit+.05*math.sin(t*25))
        or (t>=18 and t<21 and .76 or 1)
    for i,wave in ipairs(barrierWaves) do
        wave.Transparency=shieldOn and math.clamp(.29-.13*math.sin(t*15+i)-.17*shieldHit,.06,.55) or 1
    end
    local bloom=Lighting:FindFirstChild("CinematicBloom")
    if bloom then bloom.Intensity=t>=21 and .38 or .12 end
    local grade=Lighting:FindFirstChild("CinematicGrade")
    if grade then
        grade.TintColor=t<11 and Color3.fromRGB(168,190,224)
            or (t<18 and Color3.fromRGB(160,188,222) or Color3.fromRGB(183,202,227))
        grade.Contrast=t<21 and .18 or .12
        grade.Saturation=t<21 and -.27 or -.08
    end
end
local function setTitle(t)
    title.Visible=t>=21
    if t>=21 then
        local u=seg(t,21,21.55)
        title.BackgroundTransparency=1-u
        titleBig.TextTransparency=1-u;titleSoon.TextTransparency=1-seg(t,21.38,21.9)
        titleTag.TextTransparency=1-seg(t,21.9,22.45)
        titleBig.Position=UDim2.fromScale(.5,.41+.04*(1-u))
        titleLine.BackgroundTransparency=1-seg(t,21.3,21.8)
        titleOut.BackgroundTransparency=1-seg(t,23.2,23.75)
    end
end
local function frame(t)
    elapsed=t
    local tx,tz,tyaw=pos(thiefKeys,t)
    local ox,oz,oyaw=pos(ownerKeys,t)
    local td,ts=pathMotion(thiefKeys,t)
    local od,os=pathMotion(ownerKeys,t)
    local trun=t>=4.18 and t<16.5
    local orun=t>=4.1 and t<17.02
    local treact=t>=3.0 and t<3.8 and "nervous" or (
        (t>=12.6 and t<13.5 and "lookback" or
        (t>=17.3 and t<17.9 and "flinch" or
        (t>=19.15 and t<19.8 and "admire" or
        (t>=19.8 and t<20.7 and "notice" or
        (t>=20.72 and t<21.1 and "flinch" or ""))))))
    local arm=t>=2.9 and t<3.5 and "wave" or (t>=19.15 and "innocent" or "carry")
    local tlean=trun and (.27+.10*math.clamp(ts/8,0,1))
        or (treact=="bonk" and .32 or (t>=15 and t<16.3 and -.42 or 0))
    local root=pose(thief,t,tx,tz,tyaw,trun,tlean,arm,treact,td,ts)
    pose(owner,t,ox,oz,oyaw,orun,orun and (.30+.10*math.clamp(os/8,0,1))
        or (t>=16.96 and t<18 and .18 or 0),t>=17.15 and t<17.88 and "knock" or "swing",
        t>=2.5 and t<3.1 and "shock" or "",od,os)
    paintingPose(t,root)
    cameraAt(t)
    setLighting(t)
    setTitle(t)
    for n,spec in pairs(Config.Sounds) do
        if n=="OpeningMusic" and spec.brakeStart then
            local s=sounds[n]
            local blend=math.clamp((t-spec.brakeStart)/math.max((spec.stopTime or spec.brakeStart)-spec.brakeStart,.001),0,1)
            s.PlaybackSpeed=1-(1-(spec.brakeMinSpeed or .32))*blend*blend
            local duck=seg(t,.50,.58)*(1-seg(t,1.0,1.12))
            s.Volume=(spec.volume or .4)*(1-(spec.woodDuck or 0)*duck)
        elseif n=="ChaseMusic" and spec.fadeStart then
            sounds[n].Volume=(spec.volume or .5)*(1-seg(t,spec.fadeStart,spec.stopTime or Config.Duration))
        end
        if t>=spec.time and not cueFired[n] then
            cueFired[n]=true
            local s=sounds[n]
            if s and s.SoundId~="" then
                s.TimePosition=spec.startOffset or 0
                s:Play()
            end
        end
        local s=sounds[n]
        if spec.stopTime and t>=spec.stopTime and s and s.IsPlaying then s:Stop() end
        local fill=overlapSounds[n]
        if fill then
            if t>=spec.time+spec.overlap and t<(spec.stopTime or Config.Duration)
                and not fill.IsPlaying and fill.SoundId~="" then
                fill.TimePosition=0
                fill:Play()
            end
            if spec.stopTime and t>=spec.stopTime and fill.IsPlaying then fill:Stop() end
        end
    end
end
local function stop()
    playing=false
    frozenSecond=nil
    if cleanVisibility then
        panel.Visible=cleanVisibility.panel
        guide.Visible=cleanVisibility.guide
        cleanVisibility=nil
    end
    if conn then conn:Disconnect();conn=nil end
    for n,s in pairs(sounds) do
        s:Stop();s.PlaybackSpeed=1;s.Volume=Config.Sounds[n].volume or .5
    end
    for _,s in pairs(overlapSounds) do s:Stop() end
    for p,cf in pairs(base) do if p.Parent then p.CFrame=cf end end
    for _,actor in ipairs({thief,owner}) do
        for _,motor in ipairs(actor:GetDescendants()) do
            if motor:IsA("Motor6D") then
                local original=motor:GetAttribute("CinematicC0")
                if original then motor.C0=original end
            end
        end
    end
    barrier.Transparency=1;alarm.Brightness=0;title.Visible=false
    for _,wave in ipairs(barrierWaves) do wave.Transparency=1 end
    backAlarm.Transparency=1;backAlarmLight.Brightness=0
    if lightBefore then
        Lighting.ClockTime=lightBefore.clock;Lighting.Brightness=lightBefore.brightness
        Lighting.Ambient=lightBefore.ambient;Lighting.OutdoorAmbient=lightBefore.outdoor
        Lighting.ExposureCompensation=lightBefore.exposure
        if lightBefore.bloom then lightBefore.bloom:Destroy() end
        if lightBefore.dof then lightBefore.dof:Destroy() end
        if lightBefore.grade then lightBefore.grade:Destroy() end
        lightBefore=nil
    end
    if cameraBefore then
        camera.CameraType=cameraBefore.type;camera.CFrame=cameraBefore.cf
        camera.FieldOfView=cameraBefore.fov;camera.CameraSubject=cameraBefore.subject
        cameraBefore=nil
    end
    restoreAvatar()
end
local function start(from)
    stop()
    frozenSecond=nil
    cleanVisibility={panel=panel.Visible,guide=guide.Visible}
    panel.Visible=false
    guide.Visible=false
    camera=workspace.CurrentCamera
    cameraBefore={type=camera.CameraType,cf=camera.CFrame,fov=camera.FieldOfView,subject=camera.CameraSubject}
    lightBefore={clock=Lighting.ClockTime,brightness=Lighting.Brightness,ambient=Lighting.Ambient,outdoor=Lighting.OutdoorAmbient,exposure=Lighting.ExposureCompensation}
    local bloom=Instance.new("BloomEffect");bloom.Name="CinematicBloom";bloom.Intensity=.12
    bloom.Size=20;bloom.Threshold=1.8;bloom.Parent=Lighting;lightBefore.bloom=bloom
    local dof=Instance.new("DepthOfFieldEffect");dof.Name="CinematicDOF"
    dof.FarIntensity=.11;dof.NearIntensity=.02;dof.FocusDistance=14;dof.InFocusRadius=12
    dof.Parent=Lighting;lightBefore.dof=dof
    local grade=Instance.new("ColorCorrectionEffect");grade.Name="CinematicGrade"
    grade.Brightness=-.035;grade.Contrast=.19;grade.Saturation=-.24
    grade.TintColor=Color3.fromRGB(205,211,225);grade.Parent=Lighting
    lightBefore.grade=grade
    camera.CameraType=Enum.CameraType.Scriptable
    hideAvatar()
    table.clear(cueFired)
    elapsed=math.clamp(from or 0,0,Config.Duration)
    for n,spec in pairs(Config.Sounds) do
        if spec.time<elapsed then
            cueFired[n]=true
            -- Shot previews need any active loop, even if its original cue has passed.
            local s=sounds[n]
            if s.Looped and elapsed<(spec.stopTime or Config.Duration) then
                if s and s.SoundId~="" then
                    local position=(spec.startOffset or 0)+(elapsed-spec.time)
                    s.TimePosition=s.IsLoaded and s.TimeLength>0 and position%s.TimeLength or position
                    s:Play()
                end
            end
            local fill=overlapSounds[n]
            if fill and elapsed>=spec.time+spec.overlap
                and elapsed<(spec.stopTime or Config.Duration) and fill.SoundId~="" then
                local position=elapsed-spec.time-spec.overlap
                fill.TimePosition=fill.IsLoaded and fill.TimeLength>0 and position%fill.TimeLength or position
                fill:Play()
            end
        end
    end
    startClock=os.clock()-elapsed
    playing=true
    frame(elapsed)
    conn=RunService.RenderStepped:Connect(function()
        if not playing then return end
        if frozenSecond then frame(frozenSecond);return end
        local t=os.clock()-startClock
        frame(math.min(t,Config.Duration))
        if t>=Config.Duration then
            -- Hold the final card until the recorder is stopped and X is pressed.
            playing=false
            conn:Disconnect()
            conn=nil
        end
    end)
end
button("Play","PLAY",5,58,function() start(0) end)
button("Stop","STOP",66,58,stop)
button("Restart","RESTART",127,75,function() start(0) end)
button("Crop","9:16 GUIDE",205,94,function() guide.Visible=not guide.Visible end)
button("Shots","NEXT SHOT",302,93,function()
    local nextTime=0
    for _,s in ipairs(shots) do if s[1]>elapsed+.15 then nextTime=s[1];break end end
    start(nextTime)
end)
-- Exact static preview for Studio command bar: LocalPlayer.PlayerGui
--   .StealAnythingCinematicControls.PreviewAtSecond:Fire(7.45)
local previewEvent=Instance.new("BindableEvent")
previewEvent.Name="PreviewAtSecond";previewEvent.Parent=ui
previewEvent.Event:Connect(function(second)
    start(tonumber(second) or 0)
    frozenSecond=elapsed
end)
UIS.InputBegan:Connect(function(input,processed)
    -- The control strip may have captured focus just before a recording starts.
    if input.KeyCode==Enum.KeyCode.P then start(0)
    elseif input.KeyCode==Enum.KeyCode.X then stop()
    elseif input.KeyCode==Enum.KeyCode.R then start(0)
    elseif input.KeyCode==Enum.KeyCode.H then panel.Visible=not panel.Visible
    elseif input.KeyCode==Enum.KeyCode.N then
        local nextTime=0
        for _,s in ipairs(shots) do if s[1]>elapsed+.15 then nextTime=s[1];break end end
        start(nextTime)
    elseif input.KeyCode.Value>=Enum.KeyCode.One.Value and input.KeyCode.Value<=Enum.KeyCode.Nine.Value then
        local index=input.KeyCode.Value-Enum.KeyCode.One.Value+1
        if shots[index] then start(shots[index][1]) end
    end
end)
player.CharacterAdded:Connect(function() if playing then task.defer(hideAvatar) end end)
if Config.Autoplay then task.defer(function()start(Config.StartTime)end) end
