--!strict

local Players = game:GetService("Players")

local IncomeMath = require(script.Parent.Parent.Domain.IncomeMath)
local TutorialProgress = require(script.Parent.Parent.Domain.TutorialProgress)
local ProfileService = require(script.Parent.ProfileService)
local PlotService = require(script.Parent.PlotService)

local IncomeService = {}
local started = false
local lastSettlement: {[number]: number} = {}
local settling: {[number]: boolean} = {}
local firstIncomeOperations: {[number]: string} = {}
local firstIncomeInFlight: {[number]: boolean} = {}

local function commitFirstIncomeStep(player: Player)
    local userId = player.UserId
    if player.Parent ~= Players or firstIncomeInFlight[userId] then return end
    local operationId = firstIncomeOperations[userId]
    if operationId == nil then
        local snapshot = ProfileService.GetSnapshot(player)
        if snapshot == nil or snapshot.tutorialStep ~= 1
            or snapshot.lifetime.totalCashEarned < 1
            or snapshot.displaySlots.protected ~= "toaster"
            or snapshot.exhibits.toaster == nil
            or snapshot.exhibits.toaster.state ~= "Available" then return end
        operationId = ProfileService.NewOperationId(player)
        if operationId == nil then return end
        firstIncomeOperations[userId] = operationId
    end
    firstIncomeInFlight[userId] = true
    local result, status = ProfileService.ApplyOperation(player, operationId,
        "TutorialProgress", "first-display-income", function(profile: any): (string, string)
            if TutorialProgress.OnIncomeSettled(profile, profile.lifetime.totalCashEarned) then
                return "Committed", "FirstIncomeSeen"
            end
            return "Rejected", "AlreadyAdvanced"
        end)
    firstIncomeInFlight[userId] = nil
    if result ~= nil then
        firstIncomeOperations[userId] = nil
    elseif status == "RetryableError" or status == "SaveError" then
        task.delay(4, commitFirstIncomeStep, player)
    else
        firstIncomeOperations[userId] = nil
        warn("[Steal Anything] Could not save first-income tutorial step: " .. status)
    end
end

function IncomeService.Settle(player: Player): number
    if game:GetAttribute("MatchmakingEnabled") and player:GetAttribute("MatchActive") ~= true then
        -- Paused time never accrues and is not paid retroactively on resume.
        lastSettlement[player.UserId] = os.clock()
        return 0
    end
    if player:GetAttribute("ProfileState") ~= "Ready"
        or PlotService.GetMuseum(player) == nil then return 0 end
    while settling[player.UserId] do task.wait(0.03) end
    settling[player.UserId] = true
    local now = os.clock()
    local previous = lastSettlement[player.UserId]
    if previous == nil then
        lastSettlement[player.UserId] = now
        settling[player.UserId] = nil
        return 0
    end
    local elapsed = math.max(0, now - previous)
    if elapsed < 0.05 then
        settling[player.UserId] = nil
        return 0
    end
    local snapshot = ProfileService.GetSnapshot(player)
    if snapshot == nil then
        settling[player.UserId] = nil
        return 0
    end
    if IncomeMath.RatePerMinute(snapshot) == 0 then
        lastSettlement[player.UserId] = now
        settling[player.UserId] = nil
        return 0
    end

    local earned = 0
    local staged = ProfileService.StageRoutine(player, function(profile: any)
        earned = IncomeMath.Accrue(profile, elapsed)
    end)
    if staged then
        lastSettlement[player.UserId] = now
        settling[player.UserId] = nil
        if earned > 0 then task.spawn(commitFirstIncomeStep, player) end
        return earned
    end
    settling[player.UserId] = nil
    return 0
end

local function playerAdded(player: Player)
    player:GetAttributeChangedSignal("ProfileState"):Connect(function()
        if player:GetAttribute("ProfileState") == "Ready" then
            lastSettlement[player.UserId] = os.clock()
            task.spawn(commitFirstIncomeStep, player)
        else
            lastSettlement[player.UserId] = nil
        end
    end)
    if player:GetAttribute("ProfileState") == "Ready" then
        lastSettlement[player.UserId] = os.clock()
        task.spawn(commitFirstIncomeStep, player)
    end
end

function IncomeService.Start()
    if started then return end
    started = true
    ProfileService.RegisterBeforeRelease(IncomeService.Settle)
    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(function(player)
        firstIncomeOperations[player.UserId] = nil
        firstIncomeInFlight[player.UserId] = nil
        local previous = lastSettlement[player.UserId]
        task.delay(2, function()
            if lastSettlement[player.UserId] == previous then
                lastSettlement[player.UserId] = nil
            end
        end)
    end)
    for _, player in Players:GetPlayers() do playerAdded(player) end
    task.spawn(function()
        while started do
            task.wait(1)
            for _, player in Players:GetPlayers() do
                IncomeService.Settle(player)
            end
        end
    end)
end

return table.freeze(IncomeService)
