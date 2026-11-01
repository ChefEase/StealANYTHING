-- Studio Edit only. Exercises the actual travel transaction with synthetic carries;
-- does not claim real stock, change profiles, or replace live server handlers.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit, not a live server")
local Services=game.ServerScriptService.Server.Services
local Travel=require(Services.TravelEffects)
local Noise=require(Services.GuardNoise)
local B=require(game.ReplicatedStorage.Shared.BalanceConfig)
local Players=game:GetService("Players")
local fixtures={}
local originalMatchmaking=game:GetAttribute("MatchmakingEnabled")
local anchor=Instance.new("Part")
anchor.Anchored=true;anchor.Position=Vector3.new(0,2000,0);anchor.Parent=workspace
local destination=CFrame.new(100,2003,0)
local function player(carry)
    local character=Instance.new("Model")
    local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Anchored=true
    root.Position=anchor.Position+Vector3.new(0,3,0);root.Parent=character
    local hum=Instance.new("Humanoid");hum.Parent=character
    character.PrimaryPart=root;character.Parent=workspace
    local p={Character=character,Parent=Players,carry=carry,credits=0,
        attributes={ProfileState="Ready",MatchActive=true}}
    function p:GetAttribute(k) return self.attributes[k] end
    function p:SetAttribute(k,v) self.attributes[k]=v end
    table.insert(fixtures,p)
    return p,root
end
local serial=0
local function public()
    serial+=1
    return {carryId="carry"..serial,runId="run"..serial,tutorial=false,replay=false}
end
Travel.SetCarryTeleportHandlers(function(p,_,expected)
    if p.locked or p.invalid then return false end
    if not expected then return p.carry==nil end
    return p.carry~=nil and p.carry.carryId==expected.carryId and p.carry.runId==expected.runId
end,function(p) p.credits+=1 end,function(p) return p.carry and table.clone(p.carry) end)
local function travel(p) return Travel.Teleport(p,destination,anchor,12) end
local function cancelled(change)
    local p,root=player(public())
    local origin=root.Position
    task.delay(.15,function() change(p,root) end)
    assert(not travel(p),"invalid activation completed")
    assert(p.credits==0 and root.Position~=destination.Position,"cancel must not move/credit")
    assert(p:GetAttribute("ExtractionActive")==nil and not root:FindFirstChild("ExtractionMarker"))
    return p,origin
end
local ok,err=xpcall(function()
    local p,root=player(public())
    local started=os.clock()
    Noise.Take()
    assert(travel(p))
    assert(os.clock()-started>=B.PUBLIC_EXTRACTION_SECONDS,"server must enforce full duration")
    assert(p.credits==1 and root.Position==destination.Position)
    assert(p:GetAttribute("ExtractionOutcome")=="Completed")
    local heard=Noise.Take()
    assert(#heard>0 and heard[1].source=="TeleportExtraction")
    assert((heard[1].position-anchor.Position).Magnitude<12,"noise must be at origin")
    assert(not travel(p) and p.credits==1,"remote repetition outside pad must fail")
    local noAnchor=player(public())
    assert(not Travel.Teleport(noAnchor,destination),"alternate entry cannot bypass extraction")
    cancelled(function(p) p.carry=nil end) -- capture/drop/delivery clears current carry
    cancelled(function(p) p.carry=public() end) -- a new run, even the same item
    cancelled(function(p) p.carry.runId="replacement" end)
    cancelled(function(p) p.locked=true end)
    cancelled(function(p) p.Parent=nil end)
    cancelled(function(p) p.Character.Humanoid.Health=0 end)
    cancelled(function(_,root) root.Position+=Vector3.new(4,0,0) end)
    cancelled(function(p) p:SetAttribute("ProfileState","Loading") end)
    cancelled(function(p) p.invalid=true end)
    game:SetAttribute("MatchmakingEnabled",true)
    local unadmitted=player(public())
    unadmitted:SetAttribute("MatchActive",false)
    assert(not travel(unadmitted),"reserved-server admission is required")
    cancelled(function(p) p:SetAttribute("MatchActive",false) end)
    game:SetAttribute("MatchmakingEnabled",originalMatchmaking)
    local acquiredMidWarp=player(nil)
    task.delay(.1,function() acquiredMidWarp.carry=public() end)
    assert(not travel(acquiredMidWarp),"empty travel must not smuggle a new carry")
    local denied=player(public())
    assert(not Travel.Teleport(denied,destination,anchor,12,function() return false end))
    local access=true
    local revoked=player(public())
    task.delay(.15,function() access=false end)
    assert(not Travel.Teleport(revoked,destination,anchor,12,function() return access end))
    -- Two players may activate simultaneously; one player's duplicate is rejected.
    local a=player(public());local b=player(public())
    a:SetAttribute("GuardChased",true) -- guard may chase/capture during activation
    local done,first,duplicate=false,false,true
    task.spawn(function() first=travel(a);done=true end)
    task.delay(.1,function() duplicate=travel(a) end)
    assert(travel(b))
    while not done do task.wait() end
    assert(first and not duplicate and a.credits==1 and b.credits==1)
    for _,carry in {false,{carryId="tutorial",runId="tutorial",tutorial=true,replay=false},
        {carryId="replay",runId="replay",tutorial=true,replay=true}} do
        local ordinary=player(if carry then carry else nil)
        local t=os.clock()
        Noise.Take()
        assert(travel(ordinary))
        assert(os.clock()-t<B.PUBLIC_EXTRACTION_SECONDS,"ordinary/tutorial travel stays quick")
        assert(#Noise.Take()==0 and ordinary:GetAttribute("ExtractionActive")==nil)
    end
end,debug.traceback)
for _,p in fixtures do p.Character:Destroy() end
game:SetAttribute("MatchmakingEnabled",originalMatchmaking)
anchor:Destroy()
assert(ok,err)
return "Task14 extraction: duration, noise, invalidation, identity, duplicate/concurrent travel and tutorial travel PASS"
