local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Pathfinding=game:GetService("PathfindingService")
local Balance=require(game.ReplicatedStorage.Shared.BalanceConfig)
local Brain=require(script.Parent.Parent.Domain.GuardBrain)
local Carry=require(script.Parent.CarryService)
local Profiles=require(script.Parent.ProfileService)
local FirstItem=require(script.Parent.Parent.Domain.TutorialProgress)
local Feedback=require(script.Parent.NpcRunFeedback)
local Visual=require(script.Parent.DepotGuardVisual)
local Service={}
local started=false
local runtime, visual, origin
local brain=Brain.New()
local patrol, museumZones={},{}
local patrolIndex=1
local lastSeen, targetCarryId
local pathPoints, pathIndex={},1
local computing=false
local generation=0
local nextPath=0
local pathGoal=nil
local lastProgress=0
local tutorialWarnings={}
local runTracking={}

local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function excluded()
    local list={runtime}
    for _,player in Players:GetPlayers() do if player.Character then table.insert(list,player.Character) end end
    return list
end
local function params()
    local p=RaycastParams.new();p.FilterType=Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances=excluded();p.RespectCanCollide=true;p.IgnoreWater=true
    return p
end
local function safe(position)
    for model,zone in museumZones do
        if not model.Parent then museumZones[model]=nil; continue end
        local p=zone.cf:PointToObjectSpace(position)
        if math.abs(p.X)<=zone.size.X/2+3 and math.abs(p.Z)<=zone.size.Z/2+3 then return true end
    end
    return false
end
local function ground(position)
    local hit=workspace:Raycast(position+Vector3.new(0,5,0),Vector3.new(0,-16,0),params())
    return if hit then Vector3.new(position.X,hit.Position.Y+3,position.Z) else nil
end
local function invalidatePath()
    generation+=1;pathPoints={};pathIndex=1;pathGoal=nil
end
local function eligible(player)
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    local carry=Carry.GetActiveCarry(player)
    if not root or not hum or hum.Health<=0 or not carry or player:GetAttribute("ProfileState")~="Ready"
        or (game:GetAttribute("MatchmakingEnabled") and player:GetAttribute("MatchActive")~=true)
        or safe(root.Position) or (flat(root.Position-origin)).Magnitude>340 then return nil end
    local profile=Profiles.GetSnapshot(player)
    local protected=profile==nil or FirstItem.FirstItemGuardProtected(profile) or carry.tutorial or carry.replay
    return {root=root,carry=carry,protected=protected}
end
local function seen(data)
    local delta=data.root.Position-visual.root.Position
    if delta.Magnitude>Balance.GUARD_DETECTION_STUDS then return false end
    local direction=flat(delta)
    if direction.Magnitude>.01 and flat(visual.root.CFrame.LookVector):Dot(direction.Unit)
        <math.cos(math.rad(Balance.GUARD_VIEW_DEGREES/2)) then return false end
    local p=params()
    return workspace:Raycast(visual.root.Position+Vector3.new(0,1.5,0),
        data.root.Position+Vector3.new(0,1,0)-(visual.root.Position+Vector3.new(0,1.5,0)),p)==nil
end
local function requestPath(destination,now)
    if computing or now<nextPath then return end
    computing=true;nextPath=now+1.25
    local stamp=generation
    local start=visual.root.Position
    task.spawn(function()
        local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=5.5,AgentCanJump=false,WaypointSpacing=4})
        local ok=pcall(function() path:ComputeAsync(start,destination) end)
        computing=false
        if generation~=stamp or not runtime.Parent then return end
        runtime:SetAttribute("PathComputations",(runtime:GetAttribute("PathComputations") or 0)+1)
        if not ok or path.Status~=Enum.PathStatus.Success then return end
        local points=path:GetWaypoints()
        if #points>160 then return end
        for _,point in points do if safe(point.Position) then return end end
        pathPoints, pathIndex, pathGoal=points,2,destination
    end)
end
local function walk(destination,dt,now)
    if safe(destination) then return false end
    local position=visual.root.Position
    local delta=flat(destination-position)
    if delta.Magnitude<1.2 then return false end
    local p=params()
    local blocked=workspace:Blockcast(CFrame.new(position),Vector3.new(2.2,4.6,1.8),delta,p)
    local goal=destination
    if blocked then
        if not pathGoal or (pathGoal-destination).Magnitude>6 or pathIndex>#pathPoints then requestPath(destination,now) end
        local point=pathPoints[pathIndex]
        if not point then return false end
        -- Reach corners before advancing; skipping early cuts through pedestal edges.
        if flat(point.Position-position).Magnitude<0.35 then pathIndex+=1;point=pathPoints[pathIndex] end
        if not point then return false end
        goal=point.Position
    end
    delta=flat(goal-position)
    if delta.Magnitude<.05 then return false end
    local step=delta.Unit*math.min(delta.Magnitude,Balance.GUARD_SPEED*dt)
    local nextPosition=ground(position+step)
    if not nextPosition or safe(nextPosition) or math.abs(nextPosition.Y-position.Y)>1.6 then return false end
    local obstruction=workspace:Blockcast(CFrame.new(position),Vector3.new(2.2,4.6,1.8),nextPosition-position,p)
    if obstruction then
        -- A navmesh start can lie inside an obstacle's clearance margin. Back
        -- away from that surface before requesting another path, never through it.
        local normal=flat(obstruction.Normal)
        if normal.Magnitude>.1 then
            local retreat=ground(position+normal.Unit*math.min(.65,Balance.GUARD_SPEED*dt))
            if retreat and not safe(retreat) and math.abs(retreat.Y-position.Y)<=1.6
                and not workspace:Blockcast(CFrame.new(position),Vector3.new(2.2,4.6,1.8),retreat-position,p) then
                visual.model:PivotTo(CFrame.lookAt(retreat,retreat+delta.Unit))
                invalidatePath();lastProgress=now
                return true
            end
        end
        requestPath(destination,now);return false
    end
    visual.model:PivotTo(CFrame.lookAt(nextPosition,nextPosition+delta.Unit))
    lastProgress=now
    return true
end
local function clearTarget(player)
    if player and player.Parent==Players then
        player:SetAttribute("GuardState",nil);player:SetAttribute("GuardSuspicion",nil)
        player:SetAttribute("GuardCaptureProgress",nil);player:SetAttribute("GuardChased",false)
    end
    targetCarryId=nil;lastSeen=nil;invalidatePath()
end

function Service.Start()
    if started then return end
    started=true
    task.spawn(function()
        local map=workspace:WaitForChild("Map",30)
        local district=map and map:WaitForChild("ExpansionDistrict",30)
        local depot=district and district:FindFirstChild("Depot")
        local platform=depot and depot:FindFirstChild("Platform")
        if not platform then warn("[Guard] Depot platform unavailable");return end
        runtime=Instance.new("Folder");runtime.Name="DepotGuardRuntime";runtime.Parent=workspace
        origin=platform.Position
        local function museumAdded(model)
            if model:IsA("Model") then
                local cf,size=model:GetBoundingBox();museumZones[model]={cf=cf,size=size}
            end
        end
        local museums=map:WaitForChild("OwnedMuseums",15)
        if museums then
            museums.ChildAdded:Connect(function(m) task.defer(museumAdded,m) end)
            for _,m in museums:GetChildren() do museumAdded(m) end
        end
        if map:FindFirstChild("Museum01") then museumAdded(map.Museum01) end
        -- Equal-radius sweep covers every outbound direction, independent of plot assignment.
        for i=1,6 do
            local angle=(i-1)*math.pi/3
            patrol[i]=Vector3.new(origin.X+34*math.sin(angle),platform.Position.Y+platform.Size.Y/2+3,origin.Z+34*math.cos(angle))
        end
        visual=Visual.Create(runtime,patrol[1]);patrolIndex=2;lastProgress=os.clock()
        local accumulator=0
        RunService.Heartbeat:Connect(function(dt)
            if not runtime.Parent then return end
            accumulator+=dt;if accumulator<.1 then return end
            local step=math.min(accumulator,.2);accumulator=0
            local now=os.clock()
            local oldTarget=brain.target
            local data=oldTarget and eligible(oldTarget)
            local candidate=nil
            if brain.state=="Patrol" then
                local closest=math.huge
                for _,player in Players:GetPlayers() do
                    local info=eligible(player)
                    if info and now>=(tutorialWarnings[player] or 0) and seen(info) then
                        local distance=(info.root.Position-visual.root.Position).Magnitude
                        if distance<closest then closest=distance;candidate=player end
                    end
                end
            end
            local visible=data and seen(data) or false
            if visible then lastSeen=data.root.Position end
            local event=Brain.Step(brain,{
                candidate=candidate, valid=data~=nil and data.carry.carryId==targetCarryId,
                seen=visible,protected=data and data.protected,
                contact=data and (data.root.Position-visual.root.Position).Magnitude<=3.5,
                home=(flat(visual.root.Position-patrol[patrolIndex])).Magnitude<2,
            },step)
            if brain.target~=oldTarget then
                clearTarget(oldTarget)
                if brain.target then
                    local info=eligible(brain.target)
                    if info then targetCarryId=info.carry.carryId;lastSeen=info.root.Position end
                end
            end
            if event=="Capture" and oldTarget and data then
                Carry.TryGuardCapture(oldTarget,data.carry.carryId)
            elseif event=="TutorialWarning" and oldTarget then
                tutorialWarnings[oldTarget]=now+20
                oldTarget:SetAttribute("GuardTutorialNotice",now)
            elseif event=="Chase" and data and oldTarget then
                Feedback.Record(oldTarget,"guard_sighting",data.carry.runId)
            end
            if brain.target then
                brain.target:SetAttribute("GuardState",brain.state)
                brain.target:SetAttribute("GuardSuspicion",math.clamp(brain.warning/Balance.GUARD_WARNING_SECONDS,0,1))
                brain.target:SetAttribute("GuardCaptureProgress",math.clamp(brain.windup/Balance.GUARD_CAPTURE_WINDUP_SECONDS,0,1))
                brain.target:SetAttribute("GuardChased",brain.state=="Chase" or brain.state=="Capture")
            end
            local moving=false
            if brain.state=="Patrol" or brain.state=="Return" then
                if flat(visual.root.Position-patrol[patrolIndex]).Magnitude<2 then patrolIndex=patrolIndex%6+1;invalidatePath() end
                moving=walk(patrol[patrolIndex],step,now)
                if now-lastProgress>8 then patrolIndex=patrolIndex%6+1;invalidatePath();lastProgress=now end
            elseif brain.state=="Chase" and lastSeen then
                moving=walk(lastSeen,step,now)
                if now-lastProgress>8 then local target=brain.target;Brain.Return(brain);clearTarget(target);lastProgress=now end
            elseif brain.state=="Suspicious" and lastSeen then
                local look=flat(lastSeen-visual.root.Position)
                if look.Magnitude>.01 then visual.model:PivotTo(CFrame.lookAt(visual.root.Position,visual.root.Position+look)) end
                lastProgress=now
            end
            runtime:SetAttribute("State",brain.state)
            runtime:SetAttribute("PatrolIndex",patrolIndex)
            runtime:SetAttribute("TargetUserId",brain.target and brain.target.UserId or nil)
            Visual.Update(visual,brain.state,math.clamp(brain.warning/Balance.GUARD_WARNING_SECONDS,0,1),moving,now)
            for _,player in Players:GetPlayers() do
                local carry=Carry.GetActiveCarry(player)
                if not carry or carry.tutorial or carry.replay then runTracking[player]=nil;continue end
                local track=runTracking[player]
                if not track or track.runId~=carry.runId then runTracking[player]={runId=carry.runId,started=now}
                elseif now-track.started>120 then Feedback.Record(player,"route_confusion",carry.runId) end
            end
        end)
    end)
    Players.PlayerRemoving:Connect(function(player)
        tutorialWarnings[player]=nil;runTracking[player]=nil
        if brain.target==player then Brain.Return(brain);clearTarget(player) end
    end)
end
return Service
