--!strict
local TeleportRetry = {}

function TeleportRetry.Run(maxAttempts: number, invoke: (number) -> (),
    waitFor: (number) -> (), active: () -> boolean): (boolean, number, string?)
    local lastError: string? = nil
    for attempt = 1, maxAttempts do
        if not active() then return false, attempt - 1 end
        local ok, err = pcall(invoke, attempt)
        if ok then return true, attempt end
        lastError = tostring(err)
        if attempt < maxAttempts then waitFor(math.min(2 ^ attempt, 8)) end
    end
    return false, maxAttempts, lastError
end

return table.freeze(TeleportRetry)
