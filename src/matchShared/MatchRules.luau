--!strict
local MatchRules = {}

function MatchRules.CanLoadProfile(enabled: boolean, admission: string?): boolean
    return not enabled or admission == "Accepted"
end

function MatchRules.CanPlay(enabled: boolean, active: boolean?): boolean
    return not enabled or active == true
end

function MatchRules.ReadyCount(records: {any}): number
    local count = 0
    for _, record in records do
        if record.admitted and record.profile == "Ready" and record.plot == "Ready" then
            count += 1
        end
    end
    return count
end

return table.freeze(MatchRules)
