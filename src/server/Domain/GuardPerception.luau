local B=require(game.ReplicatedStorage.Shared.BalanceConfig)
local P={}
-- This broad phase NEVER substitutes for the service's obstruction ray.
function P.Reason(delta,forward,publicCarry,pursuing)
    local distance=delta.Magnitude
    if publicCarry and distance<=B.GUARD_CLOSE_AWARENESS_STUDS then return "CloseAwareness" end
    if pursuing and distance<=B.GUARD_PURSUIT_VISION_STUDS then return "PursuitSight" end
    if distance>B.GUARD_DETECTION_STUDS then return nil end
    local horizontal=Vector3.new(delta.X,0,delta.Z)
    if horizontal.Magnitude<.01 or forward:Dot(horizontal.Unit)>=math.cos(math.rad(B.GUARD_VIEW_DEGREES/2)) then
        return "ForwardVision"
    end
    return nil
end
return P
