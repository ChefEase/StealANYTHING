-- Deterministic state machine; observations and capture authority belong to the server.
local Balance = require(game:GetService("ReplicatedStorage").Shared.BalanceConfig)
local Brain = {}
function Brain.New()
    return { state = "Patrol", target = nil, warning = 0, lost = 0, windup = 0 }
end
function Brain.Return(brain)
    brain.state, brain.target = "Return", nil
    brain.warning, brain.lost, brain.windup = 0, 0, 0
end
function Brain.Step(b, o, dt)
    dt = math.clamp(dt, 0, 0.2)
    if b.state == "Return" then
        if o.home then b.state = "Patrol" end
        return nil
    end
    if b.state == "Patrol" then
        if o.candidate then
            b.target, b.state, b.warning = o.candidate, "Suspicious", 0
        end
        return nil
    end
    if not o.valid then Brain.Return(b); return nil end
    if b.state == "Suspicious" then
        if not o.seen then Brain.Return(b); return nil end
        b.warning += dt
        if b.warning >= Balance.GUARD_WARNING_SECONDS then
            if o.protected then Brain.Return(b); return "TutorialWarning" end
            b.state, b.lost = "Chase", 0
            return "Chase"
        end
    elseif b.state == "Chase" or b.state == "Capture" then
        if o.protected then Brain.Return(b); return nil end
        b.lost = if o.seen then 0 else b.lost + dt
        if b.lost >= Balance.GUARD_LOST_SIGHT_SECONDS then Brain.Return(b); return "Escaped" end
        if o.seen and o.contact then
            b.state = "Capture"
            b.windup += dt
            if b.windup >= Balance.GUARD_CAPTURE_WINDUP_SECONDS then
                Brain.Return(b)
                return "Capture"
            end
        else
            b.state, b.windup = "Chase", 0
        end
    end
    return nil
end
return Brain
