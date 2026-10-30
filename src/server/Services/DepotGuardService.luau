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
local Perception=require(script.Parent.Parent.Domain.GuardPerception)
local Noise=require(script.Parent.GuardNoise)
local Service={}
local started=false
local lifecycle=0
local runtime, visual, origin
local brain=Brain.New()
local patrol, museumZones={},{}
local patrolIndex=1
local lastSeen, targetCarryId, targetRunId, investigation
local connections={}
local selectedAt={}
local movementOrigin=nil
local moving=false
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
    if runtime and runtime.Parent then runtime:SetAttribute("PathStatus","Idle") end
end
local function segmentSafe(a,b)
    -- Exact slab intersection in each museum's local X/Z rectangle.
    for model,zone in museumZones do
        if not model.Parent then continue end
        local p=zone.cf:PointToObjectSpace(a)
        local q=zone.cf:PointToObjectSpace(b)
        local lo,hi=0,1
        for _,axis in {"X","Z"} do
            local extent=zone.size[axis]/2+3
            local delta=q[axis]-p[axis]
            if math.abs(delta)<.00001 then
                if math.abs(p[axis])>extent then hi=-1;break end
            else
                local t1,t2=(-extent-p[axis])/delta,(extent-p[axis])/delta
                lo=math.max(lo,math.min(t1,t2));hi=math.min(hi,math.max(t1,t2))
            end
        end
        if lo<=hi then return false end
    end
    return true
end
local function eligible(player,acquiring)
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    local carry=Carry.GetActiveCarry(player)
    if not root or not hum or hum.Health<=0 or not carry or player:GetAttribute("ProfileState")~="Ready"
        or (game:GetAttribute("MatchmakingEnabled") and player:GetAttribute("MatchActive")~=true)
        or safe(root.Position)
        or (acquiring and (flat(root.Position-origin)).Magnitude>Balance.GUARD_ACQUISITION_RADIUS) then return nil end
    local profile=Profiles.GetSnapshot(player)
    local protected=profile==nil or FirstItem.FirstItemGuardProtected(profile) or carry.tutorial or carry.replay
    return {root=root,carry=carry,protected=protected}
end
local function seen(data,pursuing)
    local delta=data.root.Position-visual.root.Position
    local reason=Perception.Reason(delta,flat(visual.root.CFrame.LookVector),
        not data.carry.tutorial and not data.carry.replay,pursuing)
    if not reason then return false end
    local p=params()
    local clear=workspace:Raycast(visual.root.Position+Vector3.new(0,1.5,0),
        data.root.Position+Vector3.new(0,1,0)-(visual.root.Position+Vector3.new(0,1.5,0)),p)==nil
    return clear, if clear then reason else "Obstructed"
end
local function requestPath(destination,now)
    if computing or now<nextPath then return end
    computing=true;nextPath=now+Balance.GUARD_PATH_INTERVAL
    runtime:SetAttribute("PathStatus","Computing")
    local stamp=generation
    local start=visual.root.Position
    task.spawn(function()
        local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=5.5,AgentCanJump=false,WaypointSpacing=4})
        local ok=pcall(function() path:ComputeAsync(start,destination) end)
        computing=false
        if generation~=stamp or not runtime.Parent then path:Destroy();return end
        runtime:SetAttribute("PathComputations",(runtime:GetAttribute("PathComputations") or 0)+1)
        if not ok or path.Status~=Enum.PathStatus.Success then
            runtime:SetAttribute("NavigationFailureReason","NoPath");runtime:SetAttribute("PathStatus","Failed");path:Destroy();return
        end
        local points=path:GetWaypoints()
        path:Destroy()
        if #points>160 then runtime:SetAttribute("NavigationFailureReason","PathTooLong");return end
        local previous=start
        for _,point in points do
            if not segmentSafe(previous,point.Position) then
                runtime:SetAttribute("NavigationFailureReason","MuseumIntersection")
                runtime:SetAttribute("PathStatus","Rejected");return
            end
            previous=point.Position
        end
        pathPoints, pathIndex, pathGoal=points,2,destination
        runtime:SetAttribute("PathStatus","Following")
    end)
end
local function walk(destination,dt,now)
    if safe(destination) then return false end
    local position=visual.root.Position
    local delta=flat(destination-position)
    if delta.Magnitude<1.2 then return false end
    local p=params()
    local goal=destination
    if pathGoal then
        if not pathGoal or (pathGoal-destination).Magnitude>6 or pathIndex>#pathPoints then requestPath(destination,now) end
        local point=pathPoints[pathIndex]
        if not point then invalidatePath();return false end
        -- Reach corners before advancing; skipping early cuts through pedestal edges.
        if flat(point.Position-position).Magnitude<0.35 then pathIndex+=1;point=pathPoints[pathIndex] end
        if not point then invalidatePath();return false end
        goal=point.Position
    end
    delta=flat(goal-position)
    if delta.Magnitude<.05 then return false end
    local step=delta.Unit*math.min(delta.Magnitude,Balance.GUARD_SPEED*dt)
    local nextPosition=ground(position+step)
    if not nextPosition or not segmentSafe(position,nextPosition) or math.abs(nextPosition.Y-position.Y)>1.6 then
        runtime:SetAttribute("NavigationFailureReason","GroundOrMuseumBoundary");requestPath(destination,now);return false
    end
    local obstruction=workspace:Blockcast(CFrame.new(position),Vector3.new(2.2,4.6,1.8),nextPosition-position,p)
    if obstruction then
        -- A navmesh start can lie inside an obstacle's clearance margin. Back
        -- away from that surface before requesting another path, never through it.
        local normal=flat(obstruction.Normal)
        if normal.Magnitude>.1 then
            local retreat=ground(position+normal.Unit*math.min(.65,Balance.GUARD_SPEED*dt))
            if retreat and segmentSafe(position,retreat) and math.abs(retreat.Y-position.Y)<=1.6
                and not workspace:Blockcast(CFrame.new(position),Vector3.new(2.2,4.6,1.8),retreat-position,p) then
                Visual.SetPivot(visual,CFrame.lookAt(retreat,retreat+delta.Unit))
                requestPath(destination,now)
                return true
            end
        end
        requestPath(destination,now);return false
    end
    Visual.SetPivot(visual,CFrame.lookAt(nextPosition,nextPosition+delta.Unit))
    if not movementOrigin or flat(nextPosition-movementOrigin).Magnitude>=2 then
        lastProgress=now;movementOrigin=nextPosition
    end
    return true
end
local function clearTarget(player)
    if player and player.Parent==Players then
        player:SetAttribute("GuardState",nil);player:SetAttribute("GuardSuspicion",nil)
        player:SetAttribute("GuardCaptureProgress",nil);player:SetAttribute("GuardChased",false)
        player:SetAttribute("GuardDetectionReason",nil)
    end
    targetCarryId=nil;targetRunId=nil;lastSeen=nil;invalidatePath()
end

function Service.Start()
    if started then return end
    started=true
    lifecycle+=1
    local startEpoch=lifecycle
    task.spawn(function()
        local map=workspace:WaitForChild("Map",30)
        local district=map and map:WaitForChild("ExpansionDistrict",30)
        local depot=district and district:FindFirstChild("Depot")
        local platform=depot and depot:FindFirstChild("Platform")
        if lifecycle~=startEpoch or not started then return end
        if not platform then warn("[Guard] Depot platform unavailable");Service.Stop();return end
        runtime=Instance.new("Folder");runtime.Name="DepotGuardRuntime";runtime.Parent=workspace
        origin=platform.Position
        local function museumAdded(model)
            if model:IsA("Model") then
                local cf,size=model:GetBoundingBox();museumZones[model]={cf=cf,size=size}
            end
        end
        local museums=map:WaitForChild("OwnedMuseums",15)
        if lifecycle~=startEpoch or not started then return end
        if museums then
            table.insert(connections,museums.ChildAdded:Connect(function(m) task.defer(museumAdded,m) end))
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
        local visualAccumulator=0
        table.insert(connections,RunService.Heartbeat:Connect(function(dt)
            if not runtime.Parent then return end
            local now=os.clock()
            visualAccumulator+=dt
            if visualAccumulator>=1/15 then
                visualAccumulator=0
                Visual.Update(visual,brain.state,math.clamp(brain.warning/Balance.GUARD_WARNING_SECONDS,0,1),moving,now)
            end
            accumulator+=dt;if accumulator<.1 then return end
            local elapsed=accumulator;accumulator=0
            -- State deadlines consume ALL elapsed time. Physics never jumps after a stall.
            local step=math.min(elapsed,.3)
            local oldTarget=brain.target
            local data=oldTarget and eligible(oldTarget)
            local candidate=nil
            if not brain.target then
                local closest=math.huge
                for _,player in Players:GetPlayers() do
                    local info=eligible(player,true)
                    if info and now>=(tutorialWarnings[player] or 0) and seen(info) then
                        local distance=(info.root.Position-visual.root.Position).Magnitude
                        if distance<closest-.1 or (math.abs(distance-closest)<=.1 and
                            (not candidate or (selectedAt[player] or 0)<(selectedAt[candidate] or 0))) then
                            closest=distance;candidate=player
                        end
                    end
                end
            end
            local heard=nil
            for _,noise in Noise.Take() do
                if now-noise.time<2 and not safe(noise.position)
                    and (noise.position-visual.root.Position).Magnitude<=Balance.GUARD_NOISE_INVESTIGATION_STUDS then
                    heard=noise
                end
            end
            local visible,reason=false,nil
            if data then visible,reason=seen(data,brain.state~="Suspicious") end
            runtime:SetAttribute("DetectionReason",reason)
            if visible then lastSeen=data.root.Position end
            local event=Brain.Step(brain,{
                candidate=candidate, noise=heard~=nil,
                valid=data~=nil and data.carry.carryId==targetCarryId and data.carry.runId==targetRunId,
                seen=visible,protected=data and data.protected,
                contact=data and (data.root.Position-visual.root.Position).Magnitude<=3.5,
                atLastKnown=lastSeen and flat(visual.root.Position-lastSeen).Magnitude<2,
                home=(flat(visual.root.Position-patrol[patrolIndex])).Magnitude<2,
            },elapsed)
            if event=="Investigate" then
                investigation=heard.position;invalidatePath();lastProgress=now;movementOrigin=visual.root.Position
                runtime:SetAttribute("InvestigationSource",heard.source)
            elseif event and event~="Chase" then runtime:SetAttribute("PursuitEndReason",event) end
            if brain.target~=oldTarget then
                clearTarget(oldTarget)
                lastProgress=now;movementOrigin=visual.root.Position
                if brain.target then
                    local info=eligible(brain.target)
                    selectedAt[brain.target]=now
                    if info then targetCarryId=info.carry.carryId;targetRunId=info.carry.runId;lastSeen=info.root.Position end
                end
            end
            if event=="Capture" and oldTarget and data then
                runtime:SetAttribute("CaptureAccepted",Carry.TryGuardCapture(oldTarget,data.carry.carryId))
            elseif event=="TutorialWarning" and oldTarget then
                tutorialWarnings[oldTarget]=now+20
                oldTarget:SetAttribute("GuardTutorialNotice",now)
            elseif event=="Chase" and data and oldTarget then
                Feedback.Record(oldTarget,"guard_sighting",data.carry.runId)
            end
            if brain.target then
                brain.target:SetAttribute("GuardState",brain.state)
                brain.target:SetAttribute("GuardDetectionReason",reason)
                brain.target:SetAttribute("GuardSuspicion",math.clamp(brain.warning/Balance.GUARD_WARNING_SECONDS,0,1))
                brain.target:SetAttribute("GuardCaptureProgress",math.clamp(brain.windup/Balance.GUARD_CAPTURE_WINDUP_SECONDS,0,1))
                brain.target:SetAttribute("GuardChased",brain.state=="Chase" or brain.state=="Capture" or brain.state=="Search")
            end
            moving=false
            local function moveTo(destination)
                -- At most three short swept steps; no unbounded catch-up loop.
                local count=math.max(1,math.ceil(step/.1))
                for _=1,count do moving=walk(destination,step/count,now) or moving end
            end
            if brain.state=="Patrol" or brain.state=="Return" then
                if flat(visual.root.Position-patrol[patrolIndex]).Magnitude<2 then patrolIndex=patrolIndex%6+1;invalidatePath() end
                moveTo(patrol[patrolIndex])
                if now-lastProgress>Balance.GUARD_STUCK_SECONDS then
                    patrolIndex=patrolIndex%6+1;invalidatePath();lastProgress=now
                    runtime:SetAttribute("NavigationFailureReason","PatrolPointUnreachable")
                end
            elseif (brain.state=="Chase" or brain.state=="Search") and lastSeen then
                moveTo(lastSeen)
                if now-lastProgress>Balance.GUARD_STUCK_SECONDS and flat(lastSeen-visual.root.Position).Magnitude>=2 then
                    local target=brain.target;Brain.Return(brain);clearTarget(target);lastProgress=now
                    runtime:SetAttribute("PursuitEndReason","NavigationStuck")
                end
            elseif brain.state=="Investigation" and investigation then
                moveTo(investigation)
            elseif brain.state=="Suspicious" and lastSeen then
                local look=flat(lastSeen-visual.root.Position)
                if look.Magnitude>.01 then Visual.SetPivot(visual,CFrame.lookAt(visual.root.Position,visual.root.Position+look)) end
                lastProgress=now
            end
            runtime:SetAttribute("State",brain.state)
            runtime:SetAttribute("PatrolIndex",patrolIndex)
            runtime:SetAttribute("TargetUserId",brain.target and brain.target.UserId or nil)
            runtime:SetAttribute("LastKnownPosition",lastSeen)
            for _,player in Players:GetPlayers() do
                local carry=Carry.GetActiveCarry(player)
                if not carry or carry.tutorial or carry.replay then runTracking[player]=nil;continue end
                local track=runTracking[player]
                if not track or track.runId~=carry.runId then runTracking[player]={runId=carry.runId,started=now}
                elseif now-track.started>120 then Feedback.Record(player,"route_confusion",carry.runId) end
            end
        end))
        table.insert(connections,runtime.Destroying:Connect(function() Service.Stop() end))
    end)
    table.insert(connections,Players.PlayerRemoving:Connect(function(player)
        tutorialWarnings[player]=nil;runTracking[player]=nil;selectedAt[player]=nil
        if brain.target==player then Brain.Return(brain);clearTarget(player) end
    end))
end
function Service.Stop()
    started=false
    lifecycle+=1
    for _,connection in connections do connection:Disconnect() end
    table.clear(connections)
    clearTarget(brain.target);Brain.Return(brain)
    if visual then Visual.Destroy(visual);visual=nil end
    if runtime and runtime.Parent then runtime:Destroy() end
    runtime=nil;patrol={};museumZones={};tutorialWarnings={};runTracking={};selectedAt={}
    brain=Brain.New()
end
return Service
