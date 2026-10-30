local R = {}
local V, C, A = Vector3.new, CFrame.new, CFrame.Angles
local rgb = Color3.fromRGB
local gold, cyan, violet = rgb(255, 193, 61), rgb(66, 239, 255), rgb(167, 76, 255)
local function part(r, name, size, color, shape, material)
    return r:Part(name, size, color, shape, material)
end
local function fade(u) return 1 - math.sin(math.pi * u) end
local function star(r, color)
    return {part(r, "Glint", V(.04,.4,.04), color), part(r,"Glint",V(.4,.04,.04),color)}
end
local function poseStar(r, parts, cf, amount)
    r:Pose(parts[1],cf,1-amount,V(.035,.5*amount+.01,.035))
    r:Pose(parts[2],cf,1-amount,V(.5*amount+.01,.035,.035))
end

R.toaster = function(r)
    local bread = {}
    for i=1,2 do
        bread[i] = {part(r,"ToastCrust",V(.5,.65,.15),rgb(145,73,29),nil,Enum.Material.SmoothPlastic),
            part(r,"ToastCenter",V(.37,.48,.17),rgb(255,210,128),nil,Enum.Material.SmoothPlastic)}
    end
    return function(t)
        local u = (t % 5) / 1.4
        for i,p in bread do
            local cf = C((i-1.5)*.55,r.size.Y*.3+math.sin(math.min(u,1)*math.pi)*1.1,0)*A(0,0,(i-1.5)*u*.7)
            for _,b in p do r:Pose(b,cf,if u>1 then 1 else .05) end
        end
    end
end
R.duck = function(r)
    local bubbles={}
    for i=1,6 do bubbles[i]=part(r,"SoapBubble",V(.22,.22,.22),rgb(142,234,255),"Ball",Enum.Material.Glass) end
    return function(t)
        for i,p in bubbles do
            local u=(t*.24+i/6)%1
            local s=.08+.27*u
            r:Pose(p,C(math.sin(i*5+t*.7)*(.4+r.size.X*.35),-r.size.Y*.25+u*(r.size.Y+1),.25),.35+.6*fade(u),V(s,s,s))
        end
    end
end
R.traffic_cone = function(r)
    local crown={}
    for i=1,5 do crown[i]=part(r,"TinyRoyalCrown",V(.16,.32,.14),gold,"Wedge",Enum.Material.Metal) end
    return function(t)
        for i,p in crown do
            local a=i*math.pi*2/5
            r:Pose(p,C(math.cos(a)*.23,r.size.Y/2+.32+math.sin(t)*.07,math.sin(a)*.23)*A(0,-a,0),.05)
        end
    end
end
R.disco_bin = function(r)
    local tiles={}
    for i=1,12 do tiles[i]=part(r,"DancefloorCaustic",V(.32,.025,.32),Color3.fromHSV(i/12,.75,1)) end
    return function(t)
        for i,p in tiles do
            local x=((i-1)%4-1.5)*.55
            local z=(math.floor((i-1)/4)-1)*.65
            r:Pose(p,C(x,-r.size.Y/2+.04,z),.35+.55*(.5+.5*math.sin(t*3+i*1.7)))
        end
    end
end
local function coins(r, count, radius, top)
    local list={}
    for i=1,count do
        local p=part(r,"JackpotCoin",V(.06,.26,.26),gold,nil,Enum.Material.Metal)
        p.Shape=Enum.PartType.Cylinder
        list[i]=p
    end
    return function(t)
        for i,p in list do
            local u=(t*.35+i/count)%1
            local x=math.sin(i*8)*radius
            r:Pose(p,C(x,top+math.sin(u*math.pi)*1.1-u*.7,math.cos(i*8)*.4)*A(t*2+i,0,t*3),fade(u)*.9)
        end
    end
end
R.gold_toilet=function(r) return coins(r,7,r.size.X*.55,r.size.Y*.3) end
R.jelly_lamp=function(r)
    local jellies={}
    for i=1,3 do
        local row={part(r,"JellyBell",V(.34,.2,.34),rgb(255,124,220),"Ball",Enum.Material.Glass)}
        for j=1,3 do row[j+1]=part(r,"JellyTendril",V(.025,.3,.025),rgb(169,124,255)) end
        jellies[i]=row
    end
    return function(t)
        for i,row in jellies do
            local x=math.sin(t*.5+i*2.1)*(r.size.X*.5+.25)
            local y=math.sin(t*.8+i)*.25+r.size.Y*(i/4-.35)
            r:Pose(row[1],C(x,y,.3),.3,V(.34,.18+math.sin(t*2+i)*.035,.34))
            for j=2,4 do
                r:Line(row[j],V(x+(j-3)*.1,y-.04,.3),V(x+(j-3)*.1+math.sin(t*2+j)*.08,y-.38,.3),.022,.28)
            end
        end
    end
end
R.snack_machine=function(r)
    local packets={}
    for i=1,3 do packets[i]=part(r,"PrizeSnack",V(.18,.26,.12),({rgb(255,89,94),gold,cyan})[i],nil,Enum.Material.SmoothPlastic) end
    return function(t)
        for i,p in packets do
            local u=(t*.23+i/3)%1
            r:Pose(p,C((i-2)*.3,-r.size.Y*.15-u*.7,-r.size.Z*.5-.15-u*.35)*A(u*5,i,u*2),fade(u))
        end
    end
end
R.moon_rock=function(r)
    local rocks={}
    for i=1,7 do rocks[i]=part(r,"LevitationFragment",V(.16+(i%3)*.06,.13,.2),rgb(126,151,180),"Wedge",Enum.Material.Slate) end
    return function(t)
        for i,p in rocks do
            local u=(t*.16+i/7)%1
            local a=i*2.4
            r:Pose(p,C(math.cos(a)*r.size.X*.55,-r.size.Y*.4+math.sin(u*math.pi)*1.25,math.sin(a)*r.size.Z*.55)*A(u*2,i,u),.15+.8*fade(u))
        end
    end
end
R.mini_ufo=function(r)
    local rays={}
    for i=1,9 do rays[i]=part(r,"TractorRay",V(.025,1,.025),rgb(116,255,177)) end
    local cow=part(r,"AbductedCow",V(.34,.18,.15),rgb(240,241,224),nil,Enum.Material.SmoothPlastic)
    local spots=part(r,"CowSpots",V(.16,.19,.16),rgb(30,37,42),nil,Enum.Material.SmoothPlastic)
    local head=part(r,"CowHead",V(.13,.14,.16),rgb(240,241,224),nil,Enum.Material.SmoothPlastic)
    return function(t)
        for i,p in rays do
            local a=i*math.pi*2/9
            r:Line(p,V(math.cos(a)*.13,-.05,math.sin(a)*.13),V(math.cos(a)*.7,-r.size.Y*.5,math.sin(a)*.7),.018,.68+.15*math.sin(t*2+i))
        end
        local cf=C(0,-r.size.Y*.45+((t*.2)%1)*r.size.Y*.35,0)*A(0,t*.5,0)
        r:Pose(cow,cf,.1);r:Pose(spots,cf,.1);r:Pose(head,cf*C(.2,.06,0),.1)
    end
end
R.dinosaur_skull=function(r)
    local ribs={}
    for i=1,10 do ribs[i]=part(r,"FossilEcho",V(.06,.5,.06),rgb(255,204,130)) end
    return function(t)
        local u=(t%5)/2
        for i,p in ribs do
            local side=if i%2==0 then 1 else -1
            local n=math.ceil(i/2)
            r:Pose(p,C(side*(.3+n*.13),-.2+math.sin(n/5*math.pi)*.3,r.size.Z*.3+math.min(u,1)*.9+n*.12)*A(0,0,side*-.55),if u>1 then 1 else .35+.65*fade(u))
        end
    end
end
R.storm_jar=function(r)
    local bolts={}
    for i=1,8 do bolts[i]=part(r,"ContainedLightning",V(.035,.2,.035),rgb(199,230,255)) end
    local clouds={}
    for i=1,3 do clouds[i]=part(r,"StormCloud",V(.4,.18,.3),rgb(72,84,117),"Ball",Enum.Material.SmoothPlastic) end
    return function(t)
        local pulse=(t%3.8)/.65
        local h=r.size.Y*.55
        for i,p in bolts do
            local a=V(math.sin(i*7+math.floor(t/3.8))*.2,h*.5-(i-1)*h/8,0)
            local b=V(math.sin((i+1)*7+math.floor(t/3.8))*.2,h*.5-i*h/8,0)
            r:Line(p,a,b,.035,if pulse>1 then 1 else .15+.85*pulse)
        end
        for i,p in clouds do r:Pose(p,C(math.sin(t*.5+i)*.22,h*.35,.05+math.cos(i)*.12),.35) end
    end
end
R.giant_diamond=function(r)
    local rays,glints,refractions={},{},{}
    for i=1,7 do rays[i]=part(r,"PrismaticCaustic",V(.08,.02,1),Color3.fromHSV(i/8,.65,1)) end
    for i=1,5 do refractions[i]=part(r,"RefractedLight",V(.035,1,.035),Color3.fromHSV(i/6,.5,1)) end
    for i=1,4 do glints[i]=star(r,rgb(236,255,255)) end
    return function(t)
        for i,p in rays do
            local a=(i-4)*.23+math.sin(t*.35)*.1
            r:Pose(p,C(math.sin(a)*1.3,-r.size.Y/2+.03,math.cos(a)*1.3)*A(0,a,0),.22+.25*math.sin(t+i)^2,V(.12,.025,1.7+.3*math.sin(t+i)))
        end
        for i,p in glints do
            local a=i*2.4+t*.15
            poseStar(r,p,C(math.cos(a)*r.size.X*.45,math.sin(a)*r.size.Y*.42,-r.size.Z*.3),math.max(0,math.sin(t*1.6+i*2))^4)
        end
        for i,p in refractions do
            local angle=(i-3)*.42+math.sin(t*.4)*.08
            r:Line(p,V(0,-r.size.Y*.2,r.size.Z*.4),
                V(math.sin(angle)*2.1,r.size.Y*.45+math.cos(angle)*.4,r.size.Z*.5),.035,.5+.2*math.sin(t+i)^2)
        end
    end
end

R.neon_phantom_outfit=function(r)
    local lines={}
    for i=1,12 do lines[i]=part(r,"DigitalAfterimage",V(.04,.3,.04),if i%4==0 then rgb(255,80,196) else cyan) end
    local outlines={}
    for i=1,8 do outlines[i]=part(r,"HolographicContour",V(.065,1,.065),cyan) end
    local scan=part(r,"ScanPlane",V(4,.035,1.8),cyan)
    return function(t)
        for i,p in lines do
            local side=if i%2==0 then 1 else -1
            local row=math.ceil(i/2)
            local glitch=math.max(0,math.sin(t*1.7+row))^12
            r:Pose(p,C(side*(1.5+glitch*.65),row*.62-2.5,.55)*A(0,0,math.pi/2),.15+glitch*.6,V(.035,.3+row*.06,.035))
        end
        for i,p in outlines do
            local side=if i<=4 then -1 else 1
            local n=(i-1)%4
            local shift=.15+.35*(.5+.5*math.sin(t*1.4))
            local x=side*(1.65+shift)
            local y=1.9-n*1.1
            r:Line(p,V(x,y,.35),V(x+side*(if n==0 then -.5 else .12),y-.8,.35),.065,.25)
        end
        r:Pose(scan,C(0,-2.6+((t*.2)%1)*5.6,0),.84)
    end
end
R.shadow_king_outfit=function(r)
    local blades,cracks={},{}
    for i=1,8 do
        blades[i]=part(r,"LivingShadowBlade",V(.8,2.7,.3),rgb(113,62,159),"Wedge",Enum.Material.SmoothPlastic)
        cracks[i]=part(r,"ShadowEdge",V(.12,2.35,.12),rgb(219,147,255))
    end
    return function(t)
        for i,p in blades do
            local side=if i<=4 then -1 else 1
            local n=(i-1)%4
            local a=side*(.25+n*.19+.07*math.sin(t*.8+n))
            local cf=C(side*(1.65+n*.42),.95-n*.25,.6)*A(0,0,-a)
            r:Pose(p,cf,.08);r:Pose(cracks[i],cf*C(side*.18,.1,-.1),.25+.2*math.sin(t+i)^2)
        end
    end
end
R.legendary_animated_outfit=function(r)
    local cards={}
    for i=1,5 do
        cards[i]={part(r,"RoyalCardGold",V(.84,1.27,.07),gold,nil,Enum.Material.Metal),
            part(r,"RoyalCardFace",V(.72,1.15,.08),rgb(26,24,32),nil,Enum.Material.SmoothPlastic),
            part(r,"RoyalDiamond",V(.25,.25,.09),gold)}
    end
    local animateCoins=coins(r,8,2.6,.6)
    return function(t)
        for i,row in cards do
            local a=(i-3)*.38
            local cf=C(math.sin(a)*2.8,1.15+math.cos(a)*1.1+math.sin(t+i)*.06,1)*A(0,0,-a)
            r:Pose(row[1],cf,.02);r:Pose(row[2],cf,.02);r:Pose(row[3],cf*A(0,0,math.pi/4),.02)
        end
        animateCoins(t)
    end
end
return R
