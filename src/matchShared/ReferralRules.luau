--!strict
-- Reward feature is disabled. This is the durable claim rule for its later implementation.
local ReferralRules = {}
ReferralRules.MaximumQualifiedFriends = 4

function ReferralRules.Qualify(record: any, inviterId: number, friendId: number): (any, boolean)
    record = record or { qualified = {}, count = 0 }
    record.qualified = record.qualified or {}
    local count = 0
    for _, qualified in pairs(record.qualified) do
        if qualified == true then count += 1 end
    end
    record.count = count
    if inviterId <= 0 or friendId <= 0 or inviterId == friendId
        or record.qualified[tostring(friendId)] == true
        or record.count >= ReferralRules.MaximumQualifiedFriends then
        return record, false
    end
    record.qualified[tostring(friendId)] = true
    record.count += 1
    return record, true
end

return table.freeze(ReferralRules)
