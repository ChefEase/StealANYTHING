-- Bounded session-only observations. These never tune guards, rewards or stock.
local Players = game:GetService("Players")
local Feedback = {}
local history = {}
local allowed = { guard_sighting=true, capture=true, dropped_carry=true, route_confusion=true }
function Feedback.Record(player, reason, runId)
    if not allowed[reason] or type(runId) ~= "string" then return end
    local state = history[player] or { events={}, failures=0, lastHint=-math.huge, version=0 }
    history[player] = state
    local alreadyFailed=false
    for _, event in state.events do
        if event.runId == runId and event.reason == reason then return end
        if event.runId==runId and (event.reason=="capture" or event.reason=="dropped_carry") then alreadyFailed=true end
    end
    table.insert(state.events,{reason=reason,runId=runId,time=os.clock()})
    if #state.events > 8 then table.remove(state.events,1) end
    if reason == "guard_sighting" then return end
    if reason~="route_confusion" and not alreadyFailed then
        state.failures = math.min(8,state.failures+1)
    end
    player:SetAttribute("NpcFailureCount",state.failures)
    if state.failures >= 2 and os.clock()-state.lastHint >= 60 then
        state.lastHint=os.clock(); state.version+=1
        player:SetAttribute("NpcHintReason",reason)
        player:SetAttribute("NpcHintVersion",state.version)
    end
end
function Feedback.Success(player)
    local state=history[player]
    if state then state.failures=0; table.clear(state.events) end
    player:SetAttribute("NpcFailureCount",0)
end
function Feedback.Snapshot(player)
    local state=history[player]
    return if state then {count=#state.events,failures=state.failures} else {count=0,failures=0}
end
Players.PlayerRemoving:Connect(function(player) history[player]=nil end)
return Feedback
