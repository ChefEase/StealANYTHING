--!strict

local TutorialProgress = {}

-- Step 1 is the confirmed first delivery. Step 2 is the first displayed
-- income payout, which proves the reward to the player before the next goal.
function TutorialProgress.OnIncomeSettled(profile: any, totalEarned: number): boolean
    if totalEarned <= 0 or profile.tutorialStep ~= 1
        or profile.displaySlots.protected ~= "toaster" then
        return false
    end
    local toaster = profile.exhibits.toaster
    if toaster == nil or toaster.state ~= "Available" then return false end
    profile.tutorialStep = 2
    return true
end

function TutorialProgress.FirstItemGuardProtected(profile: any): boolean
    return profile.tutorialStep == 0
end

return table.freeze(TutorialProgress)
