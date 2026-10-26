-- Run in Studio Edit with the six inspection clones present.
-- No scene edits: compare traversable approaches after visual changes.
local PF = game:GetService("PathfindingService")
local HS = game:GetService("HttpService")
local preview = assert(workspace:FindFirstChild("Task11InspectionPreview"))
local origin = preview.World:GetPivot().Position
local start = origin + Vector3.new(0, 3, 0)
local function path(a, b)
    local p = PF:CreatePath({AgentRadius=4, AgentHeight=5, AgentCanJump=false, WaypointSpacing=4})
    p:ComputeAsync(a, b)
    assert(p.Status == Enum.PathStatus.Success, "No route: " .. tostring(a) .. " -> " .. tostring(b))
    local points, distance = p:GetWaypoints(), 0
    for i=2,#points do distance += (points[i].Position-points[i-1].Position).Magnitude end
    return distance, points
end
local results = {}
for i=1,6 do
    local museum=preview.Museums[string.format("Museum%02d",i)]
    local destination=museum.ReceivingZone.Position
    local a=preview.World.Routes["Covered"..i.."Waypoint1"].Position+Vector3.new(0,3,0)
    local b=preview.World.Routes["Covered"..i.."Waypoint2"].Position+Vector3.new(0,3,0)
    local direct=path(start,destination)
    local covered=path(start,a)+path(a,b)+path(b,destination)
    local sideStart=museum:GetPivot():PointToWorldSpace(Vector3.new(67,3,0))
    local _,side=path(sideStart,destination)
    local crossed=false
    for j=2,#side do
        local a0=museum:GetPivot():PointToObjectSpace(side[j-1].Position)
        local b0=museum:GetPivot():PointToObjectSpace(side[j].Position)
        if a0.Z < -59.5 and b0.Z >= -59.5 then
            local t=(-59.5-a0.Z)/(b0.Z-a0.Z)
            local x=a0.X+(b0.X-a0.X)*t
            assert(math.abs(x)<=8.5,"Side route bypasses gate "..i)
            crossed=true
        end
    end
    assert(crossed,"Side approach did not cross front gate "..i)
    results[i]={plot=i,publicStuds=math.floor(direct+0.5),coveredStuds=math.floor(covered+0.5),sideUsesGate=crossed}
    task.wait()
end
return HS:JSONEncode(results)
