-- Decisions consume elapsed time; movement has its own bounded integration.
local B=require(game.ReplicatedStorage.Shared.BalanceConfig)
local Brain={}
function Brain.New()
    return {state="Patrol",target=nil,warning=0,windup=0,lost=0,age=0,pursuit=0,searching=0}
end
local function enter(b,state) b.state=state; b.age=0 end
function Brain.Return(b)
    enter(b,"Return"); b.target=nil
    b.warning=0; b.windup=0; b.lost=0; b.pursuit=0
end
function Brain.Step(b,o,dt)
    dt=math.max(0,dt); b.age+=dt
    if not b.target then
        if o.candidate then
            b.target=o.candidate; b.warning=0; enter(b,"Suspicious")
        elseif o.noise and b.state~="Investigation" then
            enter(b,"Investigation"); return "Investigate"
        elseif b.state=="Investigation" and b.age>=B.GUARD_INVESTIGATION_SECONDS then
            Brain.Return(b); return "InvestigationEnded"
        elseif b.state=="Return" and (o.home or b.age>=B.GUARD_RETURN_SECONDS) then
            enter(b,"Patrol"); return "Returned"
        end
        return nil
    end
    if not o.valid then Brain.Return(b); return "InvalidTarget" end
    if b.state=="Suspicious" then
        if not o.seen then Brain.Return(b); return "WarningLostSight" end
        -- Never infer continuous visibility across a long server stall.
        b.warning+=math.min(dt,.25)
        if b.warning>=B.GUARD_WARNING_SECONDS then
            if o.protected then Brain.Return(b); return "TutorialWarning" end
            enter(b,"Chase"); return "Chase"
        end
        return nil
    end
    if o.protected then Brain.Return(b); return "Protected" end
    b.pursuit+=dt
    if b.pursuit>=B.GUARD_CHASE_SECONDS then Brain.Return(b); return "PursuitLimit" end
    if o.seen then
        b.lost=0
        if o.contact then
            if b.state~="Capture" then enter(b,"Capture"); b.windup=0 end
            b.windup+=math.min(dt,.25)
            if b.windup>=B.GUARD_CAPTURE_WINDUP_SECONDS then Brain.Return(b); return "Capture" end
        else
            enter(b,"Chase"); b.windup=0
        end
    else
        b.windup=0; b.lost+=dt
        if b.state~="Search" then enter(b,"Search"); b.searching=0 end
        if o.atLastKnown or b.lost>=B.GUARD_LOST_SIGHT_SECONDS*3 then
            b.searching+=dt
            if b.searching>=B.GUARD_SEARCH_SECONDS then Brain.Return(b); return "SearchExpired" end
        end
    end
    return nil
end
return Brain
