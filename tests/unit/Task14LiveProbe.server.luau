-- Run this file in the Studio SERVER command bar during one-player Play.
-- Creates temporary isolated guard/carry modules and a normal Script, then restores
-- the original guard. No profile writes or real stock claims. Stop Play afterward.
local services=game.ServerScriptService.Server.Services
assert(not services:FindFirstChild("Task14ProbeCarry"),"Restart Play before rerunning")
local carry=Instance.new("ModuleScript")
carry.Name="Task14ProbeCarry"
carry.Source="return table.clone(require(script.Parent.CarryService))"
carry.Parent=services
local guard=services.DepotGuardService:Clone()
guard.Name="Task14ProbeGuard"
guard.Source=string.gsub(guard.Source,"require%(script.Parent.CarryService%)","require(script.Parent.Task14ProbeCarry)")
guard.Parent=services
local runner=Instance.new("Script")
runner.Name="Task14LiveProbe"
runner.Source=[==[
-- MANUAL Studio Play only. Install as a temporary normal server Script.
-- Uses one real character with a synthetic carry; never claims stock or edits profiles.
-- Stop Play after running. This is NOT an end-to-end inventory/capture test.
local Services=game.ServerScriptService.Server.Services
local Carry=require(Services.Task14ProbeCarry)
local originalGuard=require(Services.DepotGuardService)
local testGuard=require(Services.Task14ProbeGuard)
originalGuard.Stop()
testGuard.Start()
task.wait(.5)
local p=game.Players:GetPlayers()[1]
assert(p and p.Character,"Start a one-player Studio session first")
local root=p.Character:FindFirstChild("HumanoidRootPart")
local guard=workspace:WaitForChild("DepotGuardRuntime")
local model=guard.DepotGuard
local originalGet,originalCapture=Carry.GetActiveCarry,Carry.TryGuardCapture
local originalPose,originalAnchored=root.CFrame,root.Anchored
local fake=nil
local captures=0
local wall=nil
Carry.GetActiveCarry=function(player)
    if player==p then return fake end
    return originalGet(player)
end
Carry.TryGuardCapture=function(player,id)
    if player==p then
        assert(fake and fake.carryId==id and not fake.tutorial,"invalid capture request")
        captures+=1;fake=nil;return true
    end
    return originalCapture(player,id)
end
local function position(z)
    root.CFrame=CFrame.new(610,4.2,z)
end
local function reset(z)
    fake=nil;task.wait(.3)
    model:PivotTo(CFrame.lookAt(Vector3.new(610,4.2,z),Vector3.new(610,4.2,z+1)))
end
local function public()
    fake={carryId="probe-carry",runId="probe-run",itemId="jelly_lamp",tutorial=false,replay=false}
end
local ok,err=xpcall(function()
    root.Anchored=true
    reset(70);position(87);public()
    task.wait(1.1)
    assert(guard:GetAttribute("State")=="Chase","forward acquisition failed")
    script:SetAttribute("ForwardChase",true)
    position(140);task.wait(3)
    assert(model.PrimaryPart.Position.Z>95,"chase failed beyond depot")
    script:SetAttribute("BeyondDepot",true)
    wall=Instance.new("Part");wall.Name="Task14TestCover";wall.Anchored=true
    wall.Size=Vector3.new(100,20,2)
    wall.Position=Vector3.new(610,8,model.PrimaryPart.Position.Z+6);wall.Parent=workspace
    task.wait(.5)
    assert(guard:GetAttribute("State")=="Search" and captures==0,"solid cover did not stop sight")
    script:SetAttribute("CoverSearch",true)
    task.wait(20)
    assert(guard:GetAttribute("TargetUserId")==nil,"lost target never released")
    script:SetAttribute("SearchEnded",true)
    fake=nil;wall:Destroy();wall=nil
    reset(70);position(65);public()
    task.wait(.2)
    assert(guard:GetAttribute("State")=="Suspicious","rear close awareness failed")
    script:SetAttribute("RearAwareness",true)
    fake=nil;task.wait(.3)
    assert(guard:GetAttribute("TargetUserId")==nil,"dropped carry kept target")
    script:SetAttribute("DropInvalidates",true)
    reset(70);position(87);public()
    task.wait(1.3)
    local museum=workspace.Map.OwnedMuseums:FindFirstChildWhichIsA("Model")
    assert(museum,"Join an assigned museum before running")
    local museumCF,museumSize=museum:GetBoundingBox()
    root.CFrame=museumCF
    task.wait(.4)
    assert(guard:GetAttribute("TargetUserId")==nil,"museum entry kept target")
    local localGuard=museumCF:PointToObjectSpace(model.PrimaryPart.Position)
    assert(math.abs(localGuard.X)>museumSize.X/2+3 or math.abs(localGuard.Z)>museumSize.Z/2+3,
        "guard entered excluded museum")
    script:SetAttribute("MuseumExclusion",true)
    reset(70);position(72);public()
    local capturesBefore=captures
    task.wait(.4)
    assert(captures==capturesBefore,"capture skipped warning")
    for _=1,30 do
        if captures>capturesBefore then break end
        task.wait(.1)
    end
    assert(captures==capturesBefore+1,"visible contact never requested capture")
    script:SetAttribute("CaptureWindup",true)
    reset(70);position(87);public();fake.tutorial=true
    local previousCaptures=captures
    local warned=false
    for _=1,40 do
        task.wait(.1)
        local state=guard:GetAttribute("State")
        assert(state~="Chase" and state~="Capture","protected carry pursued")
        if guard:GetAttribute("PursuitEndReason")=="TutorialWarning" then warned=true;break end
    end
    assert(warned and captures==previousCaptures,"protected warning never completed")
    script:SetAttribute("ProtectedWarning",true)
end,debug.traceback)
fake=nil
if wall then wall:Destroy() end
Carry.GetActiveCarry=originalGet;Carry.TryGuardCapture=originalCapture
root.CFrame=originalPose;root.Anchored=originalAnchored
script:SetAttribute("Passed",ok);script:SetAttribute("Error",if ok then nil else tostring(err))
testGuard.Stop();originalGuard.Start()
if not ok then warn(err) end

]==]
runner.Parent=game.ServerScriptService
return "Started isolated live probe; inspect ServerScriptService.Task14LiveProbe attributes"
