--!strict
-- Display-only motion: stationary collision hulls and carried items are unaffected.
local Motion = {}

local function burst(time: number, period: number, duration: number): number
    local phase = time % period
    if phase >= duration then return 0 end
    return math.sin(phase / duration * math.pi)^2
end

function Motion.Sample(id: string, channel: string, time: number): CFrame
    if id == "toaster" then
        local phase = time % 5
        -- The lever loads just before the existing toast-pop effect starts.
        local pull = if phase > 4.2 then math.min(1, (phase - 4.2) / 0.35)
            elseif phase < 0.16 then 1 - phase / 0.16 else 0
        return CFrame.new(0, -0.2 * pull, 0)
    elseif id == "duck" then
        local envelope = burst(time, 5.8, 1.8)
        return CFrame.new(0, math.abs(math.sin(time * 8)) * 0.22 * envelope, 0)
            * CFrame.Angles(0, 0, math.rad(8) * math.sin(time * 8) * envelope)
    elseif id == "disco_bin" then
        local beat = math.max(0, math.sin(time * math.pi * 2 / 0.8))^4
        return CFrame.new(0, beat * 0.075, 0)
            * CFrame.Angles(math.rad(5) * beat, 0, math.rad(2) * math.sin(time * 3.9))
    elseif id == "jelly_lamp" then
        return CFrame.Angles(math.rad(5) * math.sin(time * 1.4), 0,
            math.rad(11) * math.sin(time * 1.05))
    elseif id == "snack_machine" then
        local envelope = burst(time, 7, 1.35)
        if channel == "chassis" then
            return CFrame.new(0.045 * math.sin(time * 53) * envelope, 0, 0)
                * CFrame.Angles(0, 0, math.rad(1.3) * math.sin(time * 47) * envelope)
        end
        return CFrame.new(0.07 * math.sin(time * 67) * envelope,
            0.055 * math.sin(time * 59) * envelope, 0)
            * CFrame.Angles(0, 0, math.rad(3) * math.sin(time * 61) * envelope)
    elseif id == "moon_rock" then
        local envelope = burst(time, 11, 1.6)
        return CFrame.new(0, 0.045 * math.sin(time * 28) * envelope, 0)
    elseif id == "mini_ufo" then
        return CFrame.new(0, 0.12 * math.sin(time * 2), 0)
            * CFrame.Angles(0, time * 0.32, math.rad(4) * math.sin(time * 1.6))
    elseif id == "storm_jar" then
        -- Only the internal cloud/lightning assembly moves; the glass stays still.
        return CFrame.new(0, 0.035 * math.sin(time * 1.5), 0)
            * CFrame.Angles(0, time * 0.23, 0)
    elseif id == "giant_diamond" then
        return CFrame.Angles(0, time * 0.18, 0)
    end
    -- Golden toilet, royal cone and fossil skull remain stationary.
    return CFrame.identity
end

return table.freeze(Motion)
