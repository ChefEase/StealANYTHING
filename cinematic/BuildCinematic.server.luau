-- Run once in Studio Edit command context. Creates only Workspace.StealAnythingCinematic.
local W = workspace
local R = game:GetService("ReplicatedStorage")
local old = W:FindFirstChild("StealAnythingCinematic")
if old then old:Destroy() end
local scene = Instance.new("Model")
scene.Name = "StealAnythingCinematic"
scene.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
scene.Parent = W
local O = Vector3.new(0,40,0)
local C = {
    gold=Color3.fromRGB(228,173,75), dark=Color3.fromRGB(29,27,37),
    stone=Color3.fromRGB(52,58,73), red=Color3.fromRGB(234,48,57),
    teal=Color3.fromRGB(55,227,207), pale=Color3.fromRGB(236,215,179),
}
local function part(parent,n,size,pos,col,mat)
    local p=Instance.new("Part")
    p.Name=n; p.Anchored=true; p.CanCollide=false; p.CanTouch=false
    p.Size=size; p.Color=col; p.Material=mat or Enum.Material.SmoothPlastic
    p.CFrame=CFrame.new(O+pos); p.Parent=parent
    return p
end
local function label(parent,face,text,color,sz)
    local g=Instance.new("SurfaceGui"); g.Name="CinematicText"; g.Face=face
    g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud=55
    g.AlwaysOnTop=false; g.Parent=parent
    local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=UDim2.fromScale(1,1)
    t.Text=text; t.TextColor3=color; t.TextScaled=true; t.Font=Enum.Font.GothamBold
    t.TextStrokeTransparency=.55; t.Parent=g
    if sz then g.CanvasSize=Vector2.new(sz,sz) end
    return t
end
-- A self-contained backlot, deliberately above the normal game world.
local set=Instance.new("Folder"); set.Name="Set"; set.Parent=scene
part(set,"MuseumFloor",Vector3.new(28,.4,30),Vector3.new(1,-.25,0),Color3.fromRGB(55,58,66),Enum.Material.Marble)
part(set,"MuseumBackWall",Vector3.new(25,13,.65),Vector3.new(0,6.3,-14),Color3.fromRGB(31,37,53))
part(set,"MuseumLeftWall",Vector3.new(.6,13,30),Vector3.new(-12,6.3,0),Color3.fromRGB(25,31,47))
part(set,"MuseumFrontWall",Vector3.new(25,13,.65),Vector3.new(0,6.3,14.6),Color3.fromRGB(31,37,53))
part(set,"MuseumFrontBaseboard",Vector3.new(24.5,.32,.12),Vector3.new(0,.18,14.2),C.gold,Enum.Material.Metal)
part(set,"MuseumCeilingTrim",Vector3.new(25,.45,1),Vector3.new(0,11.5,-13.5),C.gold,Enum.Material.Metal)
for i=-2,2 do
    local x=i*4.4
    part(set,"GalleryTile"..i,Vector3.new(.14,.03,27),Vector3.new(x,.0,0),Color3.fromRGB(170,138,99),Enum.Material.Metal)
end
part(set,"DoorwayNorth",Vector3.new(.85,11,10.5),Vector3.new(12,5.5,-8.85),C.stone)
part(set,"DoorwaySouth",Vector3.new(.85,11,10.5),Vector3.new(12,5.5,8.85),C.stone)
part(set,"DoorwayLintel",Vector3.new(.85,3,7.4),Vector3.new(12,9.5,0),C.gold,Enum.Material.Metal)
part(set,"DoorwayThreshold",Vector3.new(1,.18,7.2),Vector3.new(12,.04,0),C.gold,Enum.Material.Metal)
part(set,"NarrowJambNorth",Vector3.new(.95,8.3,.46),Vector3.new(12,4.15,-3.65),Color3.fromRGB(61,67,80),Enum.Material.Marble)
part(set,"NarrowJambSouth",Vector3.new(.95,8.3,.46),Vector3.new(12,4.15,3.65),Color3.fromRGB(61,67,80),Enum.Material.Marble)
part(set,"Street",Vector3.new(80,.35,15),Vector3.new(51,-.3,0),Color3.fromRGB(43,56,72),Enum.Material.Concrete)
part(set,"StreetStripe",Vector3.new(73,.04,.22),Vector3.new(50,-.07,0),Color3.fromRGB(210,213,189),Enum.Material.SmoothPlastic)
for i=1,13 do
    local x=17+i*5
    part(set,"LampPost"..i,Vector3.new(.25,7,.25),Vector3.new(x,3.4,-6.4),Color3.fromRGB(30,37,47),Enum.Material.Metal)
    local lamp=part(set,"StreetLamp"..i,Vector3.new(.9,.3,.9),Vector3.new(x,6.9,-6.4),Color3.fromRGB(134,211,242),Enum.Material.Neon)
    local l=Instance.new("PointLight"); l.Color=lamp.Color; l.Range=15; l.Brightness=1.1; l.Parent=lamp
end
part(set,"HomeFloor",Vector3.new(13,.4,16),Vector3.new(41,-.25,0),Color3.fromRGB(54,56,70),Enum.Material.WoodPlanks)
part(set,"HomeBackWall",Vector3.new(.5,12,16),Vector3.new(47,6,0),Color3.fromRGB(42,45,63))
part(set,"HomeNorthWall",Vector3.new(13,12,.5),Vector3.new(41,6,-8),Color3.fromRGB(41,45,62))
part(set,"HomeSouthWall",Vector3.new(13,12,.5),Vector3.new(41,6,8),Color3.fromRGB(41,45,62))
part(set,"HomeEntranceNorth",Vector3.new(.5,11,4.8),Vector3.new(35,5.5,-5.6),C.stone)
part(set,"HomeEntranceSouth",Vector3.new(.5,11,4.8),Vector3.new(35,5.5,5.6),C.stone)
part(set,"HomeLintel",Vector3.new(.5,2,6.4),Vector3.new(35,10,0),C.gold,Enum.Material.Metal)
part(set,"HomeDisplayStand",Vector3.new(3.4,3.0,1.0),Vector3.new(42,1.5,-4.8),Color3.fromRGB(74,52,78),Enum.Material.Wood)
part(set,"HomeDisplayTop",Vector3.new(4.2,.25,1.4),Vector3.new(42,3.07,-4.8),C.gold,Enum.Material.Metal)
local homeSign=part(set,"HomeSign",Vector3.new(.22,1.2,3.5),Vector3.new(35.36,8,0),C.dark)
homeSign.CFrame=homeSign.CFrame*CFrame.Angles(0,math.pi/2,0)
label(homeSign,Enum.NormalId.Front,"THIEF'S MUSEUM",C.gold)
local protected=part(set,"HomeProtection",Vector3.new(.13,8,6.32),Vector3.new(34.83,4,0),C.teal,Enum.Material.ForceField)
protected.Transparency=1; protected:SetAttribute("CinematicBarrier",true)
part(set,"BarrierLeftGlow",Vector3.new(.26,8,.24),Vector3.new(34.85,4,-3.2),C.teal,Enum.Material.Neon).Transparency=.45
part(set,"BarrierRightGlow",Vector3.new(.26,8,.24),Vector3.new(34.85,4,3.2),C.teal,Enum.Material.Neon).Transparency=.45
for i,y in ipairs({1.7,4,6.3}) do
    part(set,"BarrierWave"..i,Vector3.new(.17,.10,6.1),Vector3.new(34.83,y,0),C.teal,Enum.Material.Neon).Transparency=1
end
local museumLamp=part(set,"GalleryKeyLight",Vector3.new(1,.18,1),Vector3.new(0,9.3,-9.3),C.gold,Enum.Material.Neon)
local kl=Instance.new("SpotLight");kl.Name="PaintingGold";kl.Face=Enum.NormalId.Bottom;kl.Angle=85;kl.Range=22;kl.Brightness=3.5;kl.Color=C.gold;kl.Parent=museumLamp
local alarm=part(set,"AlarmIndicator",Vector3.new(.5,.5,.3),Vector3.new(2.8,6,-13.4),C.red,Enum.Material.Neon)
local fill=part(set,"GalleryFrontFill",Vector3.new(.2,.2,.2),Vector3.new(1,6,-5),Color3.fromRGB(255,230,192))
fill.Transparency=1
local fl=Instance.new("PointLight");fl.Color=Color3.fromRGB(255,219,173);fl.Range=17;fl.Brightness=1.8;fl.Shadows=false;fl.Parent=fill
local faceFill=part(set,"GallerySideFill",Vector3.new(.2,.2,.2),Vector3.new(6,5,-8.4),Color3.fromRGB(195,207,225))
faceFill.Transparency=1
local sideLight=Instance.new("PointLight");sideLight.Color=Color3.fromRGB(190,206,231)
sideLight.Range=12;sideLight.Brightness=1.35;sideLight.Shadows=false;sideLight.Parent=faceFill
local chaseFill=part(set,"ChaseFaceFill",Vector3.new(.2,.2,.2),Vector3.new(10,5,-5),Color3.fromRGB(181,202,229))
chaseFill.Transparency=1
local chaseLight=Instance.new("PointLight");chaseLight.Color=Color3.fromRGB(181,202,229)
chaseLight.Range=18;chaseLight.Brightness=1.65;chaseLight.Shadows=false;chaseLight.Parent=chaseFill
local jukeFill=part(set,"JukeFaceFill",Vector3.new(.2,.2,.2),Vector3.new(-5,5,-3),Color3.fromRGB(184,199,223))
jukeFill.Transparency=1
local jukeLight=Instance.new("PointLight");jukeLight.Color=Color3.fromRGB(184,199,223)
jukeLight.Range=15;jukeLight.Brightness=1.1;jukeLight.Shadows=false;jukeLight.Parent=jukeFill
local al=Instance.new("PointLight"); al.Color=C.red;al.Range=14;al.Brightness=0;al.Parent=alarm
local empty=part(set,"EmptyDisplay",Vector3.new(6.3,8.0,.22),Vector3.new(0,5,-13.5),Color3.fromRGB(30,28,35))
local rim=part(set,"DisplayRim",Vector3.new(6.8,8.5,.18),Vector3.new(0,5,-13.34),C.gold,Enum.Material.Metal)
local hole=part(set,"DisplayOpening",Vector3.new(6.0,7.7,.07),Vector3.new(0,5,-13.21),Color3.fromRGB(25,22,28))
local plaque=part(set,"ArtPlaque",Vector3.new(3,.45,.1),Vector3.new(0,.65,-13.08),Color3.fromRGB(28,25,31))
label(plaque,Enum.NormalId.Front,"MONA LISA",C.gold)
local original=R:FindFirstChild("MonaLisaArt")
local painting=Instance.new("Model");painting.Name="MonaLisaPainting";painting.Parent=scene
local canvas=part(painting,"Canvas",Vector3.new(5.25,7.0,.25),Vector3.new(0,5,-12.95),Color3.fromRGB(63,50,42),Enum.Material.Wood)
painting.PrimaryPart=canvas
local art=Instance.new("Decal");art.Name="MonaLisaImage";art.Face=Enum.NormalId.Back
art.Texture="rbxassetid://134265287077679"
art.Transparency=0
art.Parent=canvas
local portrait=Instance.new("SurfaceGui")
portrait.Name="StylizedMonaLisa";portrait.Face=Enum.NormalId.Back
portrait.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;portrait.PixelsPerStud=70
portrait.AlwaysOnTop=true;portrait.Parent=canvas
portrait.Enabled=false -- The full-resolution Mona Lisa decal is the visible artwork.
local imageGui=Instance.new("SurfaceGui")
imageGui.Name="MonaLisaFullArt";imageGui.Face=Enum.NormalId.Back
imageGui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
imageGui.PixelsPerStud=90;imageGui.AlwaysOnTop=false;imageGui.Parent=canvas
local artImage=Instance.new("ImageLabel")
artImage.Name="Portrait";artImage.BackgroundTransparency=1
artImage.Size=UDim2.fromScale(1,1)
artImage.Image=art.Texture;artImage.ScaleType=Enum.ScaleType.Stretch
artImage.Parent=imageGui
local function patch(n,x,y,w,h,col,round,rotation)
    local q=Instance.new("Frame");q.Name=n;q.BorderSizePixel=0;q.BackgroundColor3=col
    q.Position=UDim2.fromScale(x,y);q.Size=UDim2.fromScale(w,h);q.Rotation=rotation or 0
    q.Parent=portrait
    if round then local u=Instance.new("UICorner");u.CornerRadius=UDim.new(1,0);u.Parent=q end
    return q
end
patch("PaintedSky",0,0,1,1,Color3.fromRGB(83,111,110))
patch("DistantLandscape",0,.28,1,.33,Color3.fromRGB(120,128,91))
patch("LeftHill",-.08,.34,.63,.27,Color3.fromRGB(66,93,76),true)
patch("RightHill",.55,.31,.6,.28,Color3.fromRGB(73,98,81),true)
patch("Dress",.14,.59,.72,.45,Color3.fromRGB(44,38,34),true)
patch("HairSilhouette",.28,.09,.45,.64,Color3.fromRGB(40,31,27),true)
patch("Face",.39,.22,.25,.3,Color3.fromRGB(207,169,119),true)
patch("Neck",.45,.48,.12,.13,Color3.fromRGB(194,151,105))
patch("LeftEye",.43,.35,.038,.016,Color3.fromRGB(39,33,29),true)
patch("RightEye",.55,.35,.038,.016,Color3.fromRGB(39,33,29),true)
patch("HalfSmile",.485,.442,.065,.013,Color3.fromRGB(111,69,57),true)
patch("LeftSleeve",.21,.63,.33,.19,Color3.fromRGB(48,41,35),true,-15)
patch("RightSleeve",.52,.62,.27,.19,Color3.fromRGB(48,41,35),true,16)
patch("CrossedHandBack",.36,.77,.31,.067,Color3.fromRGB(193,152,111),true,-9)
patch("CrossedHandFront",.46,.81,.25,.06,Color3.fromRGB(214,171,121),true,8)
-- Physical painted layers make the portrait readable even if SurfaceGui/marketplace
-- images fail to load in another creator's place.
local function painted(n,w,h,x,y,z,col)
    return nil -- legacy block-colour portrait replaced by the decal above
end
painted("PortraitLandscape",5.18,6.92,0,5,-12.78,Color3.fromRGB(94,112,89))
painted("PortraitHillLeft",2.7,1.6,-1.25,5.15,-12.74,Color3.fromRGB(71,94,71))
painted("PortraitHillRight",2.7,1.4,1.25,5.27,-12.735,Color3.fromRGB(86,102,78))
painted("PortraitHair",2.5,4.4,0,5.5,-12.70,Color3.fromRGB(46,33,26))
painted("PortraitDress",3.6,2.8,0,2.93,-12.67,Color3.fromRGB(40,36,32))
painted("PortraitFace",1.55,2.05,0,5.68,-12.63,Color3.fromRGB(214,171,119))
painted("PortraitNeck",.5,.55,0,4.46,-12.60,Color3.fromRGB(205,158,109))
painted("PortraitEyeLeft",.18,.09,-.38,5.98,-12.59,Color3.fromRGB(36,31,29))
painted("PortraitEyeRight",.18,.09,.38,5.98,-12.59,Color3.fromRGB(36,31,29))
painted("PortraitSmile",.5,.07,0,5.11,-12.58,Color3.fromRGB(119,68,54))
painted("PortraitHandLeft",1.45,.38,-.46,2.43,-12.57,Color3.fromRGB(196,148,101))
painted("PortraitHandRight",1.42,.37,.42,2.21,-12.55,Color3.fromRGB(215,167,112))
local function border(n,sz,pos)
    local q=part(painting,n,sz,pos,C.gold,Enum.Material.Metal);return q
end
border("FrameTop",Vector3.new(5.75,.34,.46),Vector3.new(0,8.67,-12.95))
border("FrameBottom",Vector3.new(5.75,.34,.46),Vector3.new(0,1.33,-12.95))
border("FrameLeft",Vector3.new(.34,7.25,.46),Vector3.new(-2.72,5,-12.95))
border("FrameRight",Vector3.new(.34,7.25,.46),Vector3.new(2.72,5,-12.95))
local backBraceA=part(painting,"BackBraceA",Vector3.new(6.7,.17,.12),Vector3.new(0,5,-13.24),Color3.fromRGB(127,89,58),Enum.Material.Wood)
backBraceA.CFrame=backBraceA.CFrame*CFrame.Angles(0,0,.82)
local backBraceB=part(painting,"BackBraceB",Vector3.new(6.7,.17,.12),Vector3.new(0,5,-13.25),Color3.fromRGB(127,89,58),Enum.Material.Wood)
backBraceB.CFrame=backBraceB.CFrame*CFrame.Angles(0,0,-.82)
local tag=part(painting,"BackAlarm",Vector3.new(1.35,.8,.15),Vector3.new(1.75,7.6,-13.23),C.red,Enum.Material.Neon)
tag.Transparency=1
local tagLight=Instance.new("PointLight");tagLight.Color=C.red;tagLight.Range=5;tagLight.Brightness=0;tagLight.Parent=tag
painting:ScaleTo(.82)
for _,p in ipairs(painting:GetDescendants()) do if p:IsA("BasePart") then p:SetAttribute("LocalOffset",canvas.CFrame:ToObjectSpace(p.CFrame)) end end
-- Articulated Roblox-like block actors. Every body part is posed by the playback script.
local function actor(name,skin,jacket,pants,accent,home)
    local m=Instance.new("Model");m.Name=name;m.Parent=scene
    local function body(n,size,cf,color,material)
        local p=part(m,n,size,cf,color,material);p:SetAttribute("CinematicLocal",CFrame.new(cf));return p
    end
    body("Torso",Vector3.new(1.7,1.85,.82),Vector3.new(0,2.7,0),jacket)
    body("Hips",Vector3.new(1.55,.65,.8),Vector3.new(0,1.72,0),pants)
    local head=body("Head",Vector3.new(1.34,1.32,1.1),Vector3.new(0,4.12,0),skin)
    body("LeftUpperArm",Vector3.new(.57,1.1,.63),Vector3.new(-1.15,2.78,0),jacket)
    body("RightUpperArm",Vector3.new(.57,1.1,.63),Vector3.new(1.15,2.78,0),jacket)
    body("LeftLowerArm",Vector3.new(.5,.86,.56),Vector3.new(-1.15,1.86,0),skin)
    body("RightLowerArm",Vector3.new(.5,.86,.56),Vector3.new(1.15,1.86,0),skin)
    body("LeftHand",Vector3.new(.52,.46,.52),Vector3.new(-1.15,1.34,0),skin)
    body("RightHand",Vector3.new(.52,.46,.52),Vector3.new(1.15,1.34,0),skin)
    body("LeftUpperLeg",Vector3.new(.65,.95,.72),Vector3.new(-.45,1.18,0),pants)
    body("RightUpperLeg",Vector3.new(.65,.95,.72),Vector3.new(.45,1.18,0),pants)
    body("LeftLowerLeg",Vector3.new(.61,.75,.67),Vector3.new(-.45,.43,0),pants)
    body("RightLowerLeg",Vector3.new(.61,.75,.67),Vector3.new(.45,.43,0),pants)
    body("LeftShoe",Vector3.new(.74,.32,1.08),Vector3.new(-.45,.13,-.16),Color3.fromRGB(22,24,32))
    body("RightShoe",Vector3.new(.74,.32,1.08),Vector3.new(.45,.13,-.16),Color3.fromRGB(22,24,32))
    if home then
        body("CapBrim",Vector3.new(1.48,.16,.64),Vector3.new(0,4.74,-.38),Color3.fromRGB(25,31,38))
        body("CapCrown",Vector3.new(1.52,.44,1.18),Vector3.new(0,4.88,.02),Color3.fromRGB(29,36,43))
        body("Scarf",Vector3.new(1.75,.29,.94),Vector3.new(0,3.55,0),accent)
        body("Satchel",Vector3.new(.62,.95,.41),Vector3.new(1.15,2.04,.48),Color3.fromRGB(75,46,37))
    else
        body("HatBrim",Vector3.new(1.62,.14,1.2),Vector3.new(0,4.84,0),Color3.fromRGB(26,47,70))
        body("HatCrown",Vector3.new(1.25,.55,1.0),Vector3.new(0,5.12,0),Color3.fromRGB(27,51,77))
        body("Badge",Vector3.new(.29,.35,.12),Vector3.new(-.48,3.03,-.47),accent,Enum.Material.Metal)
    end
    local face=Instance.new("SurfaceGui");face.Name="Face";face.Face=Enum.NormalId.Front
    face.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;face.PixelsPerStud=100;face.Parent=head
    local function feature(n,pos,size,color)
        local q=Instance.new("Frame");q.Name=n;q.BorderSizePixel=0;q.BackgroundColor3=color
        q.Position=pos;q.Size=size;q.Parent=face;return q
    end
    feature("LeftEye",UDim2.fromScale(.24,.37),UDim2.fromScale(.11,.13),C.dark)
    feature("RightEye",UDim2.fromScale(.65,.37),UDim2.fromScale(.11,.13),C.dark)
    feature("LeftBrow",UDim2.fromScale(.2,.27),UDim2.fromScale(.19,.035),C.dark)
    feature("RightBrow",UDim2.fromScale(.62,.27),UDim2.fromScale(.19,.035),C.dark)
    feature("Mouth",UDim2.fromScale(.4,.7),UDim2.fromScale(.2,.055),Color3.fromRGB(113,42,56))
    if not home then feature("Mustache",UDim2.fromScale(.33,.61),UDim2.fromScale(.34,.06),Color3.fromRGB(57,47,43)) end
    m:SetAttribute("HomeActor",home)
    return m
end
actor("Thief",Color3.fromRGB(242,185,132),Color3.fromRGB(114,39,64),Color3.fromRGB(35,48,75),C.gold,true)
actor("Owner",Color3.fromRGB(191,128,90),Color3.fromRGB(37,81,121),Color3.fromRGB(28,44,66),C.gold,false)
scene.Thief:Destroy();scene.Owner:Destroy()
local Players=game:GetService("Players")
local function classicActor(name,isThief)
    local rig=Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R6)
    rig.Name=name
    local skin=isThief and Color3.fromRGB(207,154,105) or Color3.fromRGB(174,117,81)
    local shirt=isThief and Color3.fromRGB(129,37,59) or Color3.fromRGB(36,84,129)
    local pants=isThief and Color3.fromRGB(34,44,65) or Color3.fromRGB(26,42,66)
    for _,p in ipairs(rig:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide=false;p.CanTouch=false;p.CastShadow=true
            if p.Name=="Head" then p.Color=skin
            elseif p.Name=="Torso" then p.Color=shirt
            elseif p.Name=="Left Arm" or p.Name=="Right Arm" then p.Color=shirt
            elseif p.Name=="Left Leg" or p.Name=="Right Leg" then p.Color=pants end
        end
    end
    local colors=rig:FindFirstChild("Body Colors")
    if colors then
        colors.HeadColor3=skin
        colors.LeftArmColor3=shirt;colors.RightArmColor3=shirt
        colors.TorsoColor3=shirt
        colors.LeftLegColor3=pants;colors.RightLegColor3=pants
    end
    rig.HumanoidRootPart.Anchored=true
    rig.HumanoidRootPart.Transparency=1
    rig.Animate:Destroy()
    local hum=rig:FindFirstChildOfClass("Humanoid")
    hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
    hum.AutoRotate=false
    for _,joint in ipairs(rig:GetDescendants()) do
        if joint:IsA("Motor6D") then joint:SetAttribute("CinematicC0",joint.C0) end
    end
    for _,d in ipairs(rig.Head:GetDescendants()) do if d:IsA("Decal") then d:Destroy() end end
    local facePlate=Instance.new("Part")
    facePlate.Name="CinematicFacePlate"
    facePlate.Size=Vector3.new(1.35,1.15,.04)
    facePlate.Transparency=0;facePlate.Color=skin
    facePlate.CanCollide=false;facePlate.CanTouch=false
    facePlate.Anchored=false;facePlate.CFrame=rig.Head.CFrame*CFrame.new(0,0,-.58)
    facePlate.Parent=rig
    local faceWeld=Instance.new("WeldConstraint")
    faceWeld.Part0=rig.Head;faceWeld.Part1=facePlate;faceWeld.Parent=facePlate
    local face=Instance.new("SurfaceGui")
    face.Name="CinematicFace";face.Face=Enum.NormalId.Front
    face.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;face.PixelsPerStud=100
    face.AlwaysOnTop=true;face.Adornee=facePlate;face.Parent=facePlate
    local function feature(n,x,y,w,h,col)
        local f=Instance.new("Frame");f.Name=n;f.BorderSizePixel=0
        f.Position=UDim2.fromScale(x,y);f.Size=UDim2.fromScale(w,h)
        f.BackgroundColor3=col;f.Parent=face
        local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=f
        return f
    end
    local ink=Color3.fromRGB(35,30,35)
    feature("LeftEye",.22,.38,.11,.13,ink)
    feature("RightEye",.67,.38,.11,.13,ink)
    feature("LeftBrow",.19,.29,.20,.035,ink)
    feature("RightBrow",.61,.29,.20,.035,ink)
    feature("Mouth",.40,.69,.20,.055,Color3.fromRGB(120,48,55))
    facePlate:Destroy()
    local expression=Instance.new("Decal")
    expression.Name="CinematicExpression"
    expression.Face=Enum.NormalId.Front
    expression.Texture="rbxassetid://135806968456855"
    expression.Parent=rig.Head
    local function adorn(n,size,offset,col,mat)
        local p=Instance.new("Part");p.Name=n;p.Size=size;p.Color=col
        p.Material=mat or Enum.Material.SmoothPlastic
        p.Anchored=false;p.CanCollide=false;p.CanTouch=false
        p.CFrame=rig.Head.CFrame*offset;p.Parent=rig
        local w=Instance.new("WeldConstraint");w.Part0=rig.Head;w.Part1=p;w.Parent=p
        return p
    end
    local hat=isThief and Color3.fromRGB(32,38,48) or Color3.fromRGB(21,47,82)
    adorn("CinematicHatCrown",Vector3.new(1.68,.43,1.36),CFrame.new(0,.64,0),hat)
    adorn("CinematicHatBrim",Vector3.new(1.78,.12,.78),CFrame.new(0,.46,-.48),hat)
    if not isThief then
        local badge=Instance.new("Part");badge.Name="OwnerGoldBadge"
        badge.Shape=Enum.PartType.Ball;badge.Size=Vector3.new(.35,.36,.1)
        badge.Color=C.gold;badge.Material=Enum.Material.Metal
        badge.CanCollide=false;badge.CFrame=rig.Torso.CFrame*CFrame.new(-.45,.35,-.52)
        badge.Parent=rig
        local w=Instance.new("WeldConstraint");w.Part0=rig.Torso;w.Part1=badge;w.Parent=badge
    else
        local satchel=Instance.new("Part");satchel.Name="ThiefSatchel"
        satchel.Size=Vector3.new(.78,1.15,.48)
        satchel.Color=Color3.fromRGB(82,48,32);satchel.Material=Enum.Material.Fabric
        satchel.CanCollide=false;satchel.CFrame=rig.Torso.CFrame*CFrame.new(.95,-.25,.25)
        satchel.Parent=rig
        local w=Instance.new("WeldConstraint");w.Part0=rig.Torso;w.Part1=satchel;w.Parent=satchel
    end
    local function costume(name,body,size,offset,color,material)
        local q=Instance.new("Part");q.Name=name;q.Size=size
        q.Color=color;q.Material=material or Enum.Material.Fabric
        q.CanCollide=false;q.CanTouch=false;q.Massless=true
        q.CFrame=body.CFrame*offset;q.Parent=rig
        local w=Instance.new("WeldConstraint");w.Part0=body;w.Part1=q;w.Parent=q
        return q
    end
    local ink=Color3.fromRGB(26,31,39)
    if isThief then
        costume("HoodCollar",rig.Torso,Vector3.new(1.85,.34,1.18),CFrame.new(0,.82,.04),Color3.fromRGB(69,26,48))
        costume("JacketFront",rig.Torso,Vector3.new(1.66,1.35,.08),CFrame.new(0,-.18,-.55),Color3.fromRGB(115,37,60))
        costume("Zipper",rig.Torso,Vector3.new(.07,1.39,.09),CFrame.new(0,-.2,-.61),Color3.fromRGB(177,144,124),Enum.Material.Metal)
        costume("SatchelStrap",rig.Torso,Vector3.new(.18,2.33,.08),CFrame.new(.13,0,-.64)*CFrame.Angles(0,0,.43),Color3.fromRGB(76,49,34))
        costume("GloveLeft",rig["Left Arm"],Vector3.new(1.04,.45,1.04),CFrame.new(0,-.77,0),ink)
        costume("GloveRight",rig["Right Arm"],Vector3.new(1.04,.45,1.04),CFrame.new(0,-.77,0),ink)
        costume("BootLeft",rig["Left Leg"],Vector3.new(1.08,.52,1.16),CFrame.new(0,-.78,-.08),ink,Enum.Material.SmoothPlastic)
        costume("BootRight",rig["Right Leg"],Vector3.new(1.08,.52,1.16),CFrame.new(0,-.78,-.08),ink,Enum.Material.SmoothPlastic)
        costume("CapStitch",rig.Head,Vector3.new(1.08,.065,.08),CFrame.new(0,.69,-.56),Color3.fromRGB(173,64,69))
    else
        costume("UniformShirt",rig.Torso,Vector3.new(1.64,1.52,.08),CFrame.new(0,.02,-.56),Color3.fromRGB(47,100,143))
        costume("UniformPlacket",rig.Torso,Vector3.new(.12,1.49,.09),CFrame.new(0,.02,-.63),Color3.fromRGB(24,50,78))
        costume("UtilityBelt",rig.Torso,Vector3.new(2.06,.25,1.14),CFrame.new(0,-.87,0),ink)
        costume("BeltBuckle",rig.Torso,Vector3.new(.4,.28,.13),CFrame.new(0,-.87,-.62),Color3.fromRGB(206,170,101),Enum.Material.Metal)
        costume("LeftEpaulette",rig.Torso,Vector3.new(.62,.17,1.04),CFrame.new(-.75,1.02,0),Color3.fromRGB(24,49,80))
        costume("RightEpaulette",rig.Torso,Vector3.new(.62,.17,1.04),CFrame.new(.75,1.02,0),Color3.fromRGB(24,49,80))
        costume("LeftSleeveCuff",rig["Left Arm"],Vector3.new(1.04,.16,1.04),CFrame.new(0,-.84,0),Color3.fromRGB(20,49,79))
        costume("RightSleeveCuff",rig["Right Arm"],Vector3.new(1.04,.16,1.04),CFrame.new(0,-.84,0),Color3.fromRGB(20,49,79))
        costume("LeftBoot",rig["Left Leg"],Vector3.new(1.08,.55,1.17),CFrame.new(0,-.76,-.08),ink)
        costume("RightBoot",rig["Right Leg"],Vector3.new(1.08,.55,1.17),CFrame.new(0,-.76,-.08),ink)
        costume("CapEmblem",rig.Head,Vector3.new(.34,.25,.08),CFrame.new(0,.77,-.64),C.gold,Enum.Material.Metal)
        costume("Radio",rig.Torso,Vector3.new(.31,.55,.3),CFrame.new(1.09,.23,.18),ink)
    end
    rig.Parent=scene
    rig:PivotTo(CFrame.new(O+Vector3.new(isThief and 0 or 6,3,isThief and -9 or 6)))
    return rig
end
classicActor("Thief",true)
classicActor("Owner",false)
-- Gallery architecture and collection. These pieces live entirely in the
-- filming set and have no gameplay tags, prompts, or persistence hooks.
local bronze=Color3.fromRGB(111,84,49)
local warmWhite=Color3.fromRGB(211,200,177)
local panel=Color3.fromRGB(47,48,61)
for _,x in ipairs({-10.8,-5.2,5.2,10.8}) do
    part(set,"GalleryPilaster"..tostring(x),Vector3.new(.38,10,.45),Vector3.new(x,5,-13.2),warmWhite,Enum.Material.Marble)
    part(set,"PilasterCap"..tostring(x),Vector3.new(.75,.28,.72),Vector3.new(x,10.1,-13.05),bronze,Enum.Material.Metal)
end
part(set,"GalleryCornice",Vector3.new(24,.34,.54),Vector3.new(0,10.7,-13.2),bronze,Enum.Material.Metal)
part(set,"GalleryBaseboard",Vector3.new(24,.34,.5),Vector3.new(0,.35,-13.15),bronze,Enum.Material.Metal)
part(set,"LeftWallBaseboard",Vector3.new(.5,.3,28),Vector3.new(-11.65,.3,0),bronze,Enum.Material.Metal)
for _,z in ipairs({-9,-2,5,12}) do
    part(set,"LeftWallPier"..tostring(z),Vector3.new(.42,10,.44),Vector3.new(-11.65,5,z),warmWhite,Enum.Material.Marble)
end
local function artwork(n,w,h,pos,texture,caption,turn)
    local base=CFrame.new(O+pos)*(turn or CFrame.new())
    local group=Instance.new("Model");group.Name=n;group.Parent=set
    local function piece(name,size,off,color,mat)
        local q=Instance.new("Part")
        q.Name=name;q.Size=size;q.CFrame=base*CFrame.new(off)
        q.Anchored=true;q.CanCollide=false;q.Color=color
        q.Material=mat or Enum.Material.SmoothPlastic;q.Parent=group
        return q
    end
    local back=piece("ArtPanel",Vector3.new(w,h,.14),Vector3.new(0,0,0),Color3.fromRGB(37,37,42))
    local gui=Instance.new("SurfaceGui");gui.Name="ArtworkImage";gui.Face=Enum.NormalId.Back
    gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=90
    gui.AlwaysOnTop=false;gui.Parent=back
    local img=Instance.new("ImageLabel");img.BackgroundTransparency=1
    img.Size=UDim2.fromScale(1,1);img.Image=texture
    img.ScaleType=Enum.ScaleType.Stretch;img.Parent=gui
    piece("TopMoulding",Vector3.new(w+.36,.22,.32),Vector3.new(0,h/2+.11,.04),bronze,Enum.Material.Metal)
    piece("BottomMoulding",Vector3.new(w+.36,.22,.32),Vector3.new(0,-h/2-.11,.04),bronze,Enum.Material.Metal)
    piece("LeftMoulding",Vector3.new(.22,h+.18,.32),Vector3.new(-w/2-.11,0,.04),bronze,Enum.Material.Metal)
    piece("RightMoulding",Vector3.new(.22,h+.18,.32),Vector3.new(w/2+.11,0,.04),bronze,Enum.Material.Metal)
    local plate=piece("BrassPlaque",Vector3.new(math.max(2.4,w*.68),.32,.12),Vector3.new(0,-h/2-.47,.14),Color3.fromRGB(47,41,39),Enum.Material.Metal)
    label(plate,Enum.NormalId.Back,caption,Color3.fromRGB(221,187,119))
    local lamp=piece("PictureLamp",Vector3.new(w*.55,.12,.25),Vector3.new(0,h/2+.52,.35),Color3.fromRGB(195,150,87),Enum.Material.Metal)
    local light=Instance.new("PointLight");light.Color=Color3.fromRGB(255,202,144)
    light.Range=10;light.Brightness=.9;light.Parent=lamp
end
artwork("PearlPortrait",3.4,4.15,Vector3.new(-7.6,5.5,-13.01),"rbxassetid://101512166533414","PEARL STUDY")
artwork("WaveLandscape",4.3,3.2,Vector3.new(7.6,5.4,-13.01),"rbxassetid://78251104595180","THE GREAT WAVE")
artwork("SideGalleryWave",3.8,2.8,Vector3.new(-11.35,5.7,4.4),"rbxassetid://78251104595180","COASTAL COLLECTION",CFrame.Angles(0,math.pi/2,0))
local function sculpture(n,x,z,scale)
    local m=Instance.new("Model");m.Name=n;m.Parent=set
    local function sculpt(name,sz,off,shape,col,mat)
        local q=part(m,name,sz,Vector3.new(x,0,z)+off,col or Color3.fromRGB(208,208,199),mat or Enum.Material.Marble)
        if shape then q.Shape=shape end
        return q
    end
    sculpt("PlinthBase",Vector3.new(2.4*scale,.28*scale,2.4*scale),Vector3.new(0,.14*scale,0),nil,bronze,Enum.Material.Metal)
    sculpt("Plinth",Vector3.new(1.9*scale,1.8*scale,1.9*scale),Vector3.new(0,1.18*scale,0),nil,Color3.fromRGB(66,65,73),Enum.Material.Marble)
    sculpt("PlinthLip",Vector3.new(2.15*scale,.22*scale,2.15*scale),Vector3.new(0,2.18*scale,0),nil,bronze,Enum.Material.Metal)
    local chest=sculpt("SculptedChest",Vector3.new(1.5*scale,1.55*scale,.92*scale),Vector3.new(0,3.08*scale,0),nil)
    chest.CFrame=chest.CFrame*CFrame.Angles(0,.22,0)
    sculpt("SculptedNeck",Vector3.new(.53*scale,.5*scale,.5*scale),Vector3.new(0,4.0*scale,0),Enum.PartType.Cylinder)
    sculpt("SculptedHead",Vector3.new(.98*scale,1.17*scale,.9*scale),Vector3.new(0,4.75*scale,0),Enum.PartType.Ball)
    local hair=sculpt("StoneHair",Vector3.new(1.06*scale,.34*scale,.96*scale),Vector3.new(0,5.29*scale,0),Enum.PartType.Ball,Color3.fromRGB(174,175,172))
    hair.CFrame=hair.CFrame*CFrame.Angles(0,0,.12)
    local spot=sculpt("StatueUplight",Vector3.new(.22,.08,.22),Vector3.new(0,.08*scale,1.55*scale),nil,Color3.fromRGB(204,172,116),Enum.Material.Neon)
    local l=Instance.new("SpotLight");l.Face=Enum.NormalId.Top;l.Color=Color3.fromRGB(242,220,183)
    l.Brightness=1.3;l.Range=10;l.Angle=70;l.Parent=spot
end
sculpture("CentralMarbleBust",3.0,-4.0,1)
sculpture("LeftWingBust",-7.0,3.0,.78)
for _,x in ipairs({-10,-5}) do
    local post=part(set,"VelvetPost"..tostring(x),Vector3.new(.18,2.1,.18),Vector3.new(x,1.05,-8.3),bronze,Enum.Material.Metal)
    local finial=part(set,"VelvetFinial"..tostring(x),Vector3.new(.35,.35,.35),Vector3.new(x,2.22,-8.3),bronze,Enum.Material.Metal)
    finial.Shape=Enum.PartType.Ball
end
part(set,"VelvetRope",Vector3.new(4.8,.12,.12),Vector3.new(-7.5,1.56,-8.3),Color3.fromRGB(91,30,43),Enum.Material.Fabric)
-- Street depth and a lived-in getaway room, framed behind the action lanes.
for i,x in ipairs({17,24,30,37,44,51,58,65,72,79}) do
    local wall=part(set,"StreetFacade"..i,Vector3.new(5.4,10,.35),Vector3.new(x,5,-7.35),Color3.fromRGB(32+i*4,40+i*3,56+i*3),Enum.Material.Brick)
    part(set,"FacadeCornice"..i,Vector3.new(5.7,.3,.65),Vector3.new(x,9.8,-7.12),Color3.fromRGB(80,87,96),Enum.Material.Concrete)
    part(set,"FacadeDoor"..i,Vector3.new(1.7,3.6,.13),Vector3.new(x-1.25,1.8,-7.12),Color3.fromRGB(30,37,48),Enum.Material.Wood)
    for floor=1,2 do
        local warm=i%2==0 and floor==1
        local win=part(set,"StreetWindow"..i.."_"..floor,Vector3.new(2.2,2.0,.12),Vector3.new(x,2.3+floor*2.4,-7.09),warm and Color3.fromRGB(168,112,73) or Color3.fromRGB(78,123,151),Enum.Material.Glass)
        local glow=Instance.new("PointLight");glow.Color=warm and Color3.fromRGB(238,165,95) or Color3.fromRGB(111,180,205);glow.Brightness=.35;glow.Range=7;glow.Parent=win
        part(set,"WindowMullion"..i.."_"..floor,Vector3.new(.1,2.08,.16),Vector3.new(x,2.3+floor*2.4,-7.0),Color3.fromRGB(27,36,46),Enum.Material.Metal)
        part(set,"WindowSill"..i.."_"..floor,Vector3.new(2.65,.16,.45),Vector3.new(x,1.17+floor*2.4,-6.96),Color3.fromRGB(100,100,106),Enum.Material.Concrete)
    end
end
part(set,"StreetCurb",Vector3.new(77,.22,.45),Vector3.new(50,-.02,-7.0),Color3.fromRGB(113,115,118),Enum.Material.Concrete)
for i,x in ipairs({19,28,36,43,51,59,67,75,82}) do
    part(set,"WetPavement"..i,Vector3.new(2.7,.025,1.1),Vector3.new(x,-.095,3.8),Color3.fromRGB(39,64,82),Enum.Material.Glass).Transparency=.28
end
part(set,"GetawayRug",Vector3.new(6,.06,5.5),Vector3.new(40.7,.02,1.3),Color3.fromRGB(57,41,62),Enum.Material.Fabric)
part(set,"GetawayRugInset",Vector3.new(5.25,.065,4.75),Vector3.new(40.7,.04,1.3),Color3.fromRGB(92,72,83),Enum.Material.Fabric)
for i,z in ipairs({-6.5,4.8}) do
    part(set,"HomeShelf"..i,Vector3.new(3.2,.15,.76),Vector3.new(45,4.6,z),bronze,Enum.Material.Wood)
    part(set,"ShelfBox"..i,Vector3.new(.8,1,.6),Vector3.new(44.3,5.18,z),Color3.fromRGB(94,69,55),Enum.Material.Wood)
    local gem=part(set,"ShelfTrinket"..i,Vector3.new(.6,.6,.6),Vector3.new(45.6,5.05,z),Color3.fromRGB(67,174,172),Enum.Material.Glass)
    gem.Shape=Enum.PartType.Ball
end
local homeLamp=part(set,"HomeWarmLamp",Vector3.new(.45,.25,.45),Vector3.new(44.5,8.3,-3.5),Color3.fromRGB(245,190,124),Enum.Material.Neon)
local homeLight=Instance.new("PointLight");homeLight.Color=Color3.fromRGB(255,199,143);homeLight.Range=12;homeLight.Brightness=1.3;homeLight.Parent=homeLamp
-- The extended runway supports a faster sprint for the same 24-second cut.
for _,p in ipairs(set:GetChildren()) do
    if p:IsA("BasePart") and (p.Name:match("^Home") or p.Name:match("^Barrier") or p.Name:match("^Getaway") or p.Name:match("^Shelf")) then
        p.CFrame=p.CFrame+Vector3.new(52,0,0)
    end
end
scene:SetAttribute("BuildVersion",10)
return "Built detailed museum, sculpture chase cover, street, getaway room, and Roblox R6 actors."
