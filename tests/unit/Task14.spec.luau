-- Studio Edit or Server after syncing. Does not mutate profiles or characters.
local Server=game.ServerScriptService.Server
local Brain=require(Server.Domain.GuardBrain)
local function observed(extra)
    local o={valid=true,seen=true,contact=false,protected=false}
    for k,v in extra or {} do o[k]=v end
    return o
end
local function acquire()
    local b=Brain.New()
    Brain.Step(b,{candidate=123},.1)
    assert(b.state=="Suspicious" and b.target==123)
    for i=1,7 do Brain.Step(b,observed(),.1) end
    assert(b.state=="Suspicious","warning cannot finish before 0.75 seconds")
    assert(Brain.Step(b,observed(),.1)=="Chase")
    return b
end
local b=acquire()
for i=1,3 do assert(Brain.Step(b,observed({contact=true}),.1)==nil) end
assert(b.state=="Capture")
Brain.Step(b,observed({contact=false}),.1)
assert(b.state=="Chase" and b.windup==0,"moving away cancels capture windup")
for i=1,3 do Brain.Step(b,observed({contact=true}),.1) end
assert(Brain.Step(b,observed({contact=true}),.1)=="Capture")
assert(b.state=="Return" and b.target==nil,"capture clears target")
Brain.Step(b,{home=true},.1);assert(b.state=="Patrol")
b=acquire()
for i=1,39 do Brain.Step(b,observed({seen=false}),.1) end
assert(b.state=="Chase","give-up needs full four seconds")
assert(Brain.Step(b,observed({seen=false}),.1)=="Escaped")
b=acquire()
for i=1,30 do Brain.Step(b,observed({seen=false}),.1) end
Brain.Step(b,observed(),.1)
assert(b.lost==0,"reacquisition resets lost-sight timer")
Brain.Step(b,observed({valid=false}),.1)
assert(b.target==nil and b.state=="Return","delivery, drop, death, disconnect invalidate target")
b=Brain.New();Brain.Step(b,{candidate=123},.1)
for i=1,8 do Brain.Step(b,observed({protected=true,contact=true}),.1) end
assert(b.state=="Return" and b.target==nil,"first tutorial warning cannot chase/capture")
b=acquire();Brain.Step(b,observed({protected=true,contact=true}),.1)
assert(b.state=="Return","protection gained mid-chase is honored")
b=Brain.New();Brain.Step(b,{candidate=123},.1)
Brain.Step(b,observed({seen=false}),.1)
assert(b.state=="Return","cover during warning prevents chase")

local Feedback=require(Server.Services.NpcRunFeedback)
local fake={attributes={}}
function fake:SetAttribute(k,v) self.attributes[k]=v end
Feedback.Record(fake,"route_confusion","unfinished")
assert(Feedback.Snapshot(fake).failures==0,"a slow route is not a failed heist")
Feedback.Record(fake,"capture","same-run")
Feedback.Record(fake,"dropped_carry","same-run")
assert(Feedback.Snapshot(fake).failures==1,"one run cannot count as two failures")
Feedback.Success(fake)
for i=1,30 do Feedback.Record(fake,"capture","test-"..i) end
assert(Feedback.Snapshot(fake).count==8 and Feedback.Snapshot(fake).failures==8)
assert(fake.attributes.NpcHintVersion==1,"guidance is rate limited")
Feedback.Record(fake,"capture","test-30")
assert(Feedback.Snapshot(fake).count==8)
Feedback.Success(fake)
assert(Feedback.Snapshot(fake).count==0 and Feedback.Snapshot(fake).failures==0)
print("Task14: warning, capture windup/cancel, sight loss/reacquisition, cleanup, tutorial safety, bounded guidance passed")
return true
