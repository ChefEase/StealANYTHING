--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarryService = require(script.Parent.CarryService)
local IncomeService = require(script.Parent.IncomeService)
local ProfileService = require(script.Parent.ProfileService)
local PlotService = require(script.Parent.PlotService)
local TutorialDeliveryRules = require(script.Parent.Parent.Domain.TutorialDeliveryRules)

type Pending = {
    carryId: string,
    runId: string,
    operationId: string,
    inFlight: boolean,
}

local DeliveryService = {}
local started = false
local pending: {[number]: Pending} = {}
local lastResult: {[number]: string} = {}
local lastFeedback: {[number]: number} = {}
local feedback: RemoteEvent? = nil

local function tell(player: Player, message: string, kind: string?)
    local now = os.clock()
    if now - (lastFeedback[player.UserId] or -math.huge) < 0.65 then return end
    lastFeedback[player.UserId] = now
    if feedback ~= nil and player.Parent == Players then
        feedback:FireClient(player, { text = message, kind = kind or "Info" })
    end
end

local function process(player: Player, record: Pending)
    if pending[player.UserId] ~= record or record.inFlight or player.Parent ~= Players then return end
    record.inFlight = true
    -- Settle any old displayed income before the protected slot becomes active.
    IncomeService.Settle(player)
    local nowUnix = os.time()
    local operation, status = ProfileService.ApplyOperation(player, record.operationId,
        "DepotDelivery", record.runId, function(profile: any): (string, string)
            return TutorialDeliveryRules.Apply(profile, nowUnix)
        end)
    record.inFlight = false
    if pending[player.UserId] ~= record then return end

    if operation ~= nil then
        PlotService.RefreshDisplays(player)
        pending[player.UserId] = nil
        CarryService.FinishDelivery(player, record.carryId)
        lastResult[player.UserId] = record.carryId
        if operation.result == "Committed" then
            tell(player, "Tutorial complete! Your toaster earns $6/min while you play.", "Success")
        else
            tell(player, "That toaster is already registered.", "Info")
        end
        return
    end

    if status == "RetryableError" or status == "SaveError" then
        tell(player, "Saving your toaster. Please wait; your delivery is being checked.", "Info")
        task.delay(4, process, player, record)
        return
    end

    pending[player.UserId] = nil
    CarryService.SetDeliveryLocked(player, record.carryId, false)
    warn("[Steal Anything] Tutorial delivery was not confirmed: " .. status)
    tell(player, "Delivery could not be saved. Try again at the exhibit stand.", "Error")
end

local function requestDelivery(player: Player, carryId: any)
    if type(carryId) ~= "string" or #carryId > 64 then return end
    if lastResult[player.UserId] == carryId then
        tell(player, "Your toaster was already delivered.", "Info")
        return
    end
    local existing = pending[player.UserId]
    if existing ~= nil then
        if existing.carryId == carryId and not existing.inFlight then
            task.spawn(process, player, existing)
        end
        return
    end

    local valid, reason, carry = CarryService.CheckDelivery(player, carryId)
    if not valid then
        if reason == "NotAtDropOff" then
            tell(player, "Go to your gold-trimmed exhibit stand or the DROP-OFF mat.", "Error")
        elseif reason == "TooFast" then
            tell(player, "Keep carrying the toaster along the route to your museum.", "Error")
        elseif reason == "InvalidRoute" then
            CarryService.AbortCarry(player, carryId)
            tell(player, "That run was reset. Pick up your toaster at the depot again.", "Error")
        end
        return
    end
    if carry == nil then return end
    if carry.replay == true then
        CarryService.FinishDelivery(player, carryId)
        CarryService.EndReplay(player)
        player:SetAttribute("TutorialReplayCompleted",
            (player:GetAttribute("TutorialReplayCompleted") or 0) + 1)
        tell(player, "Practice delivery complete. Your saved collection and rewards are unchanged.", "Success")
        return
    end
    local operationId = ProfileService.NewOperationId(player)
    if operationId == nil then
        tell(player, "Your museum data is not ready. Try again in a moment.", "Error")
        return
    end

    local record: Pending = {
        carryId = carryId,
        runId = carry.runId,
        operationId = operationId,
        inFlight = false,
    }
    pending[player.UserId] = record
    CarryService.SetDeliveryLocked(player, carryId, true)
    task.spawn(process, player, record)
end

function DeliveryService.Start()
    if started then return end
    started = true
    local network = ReplicatedStorage:WaitForChild("Network")
    feedback = network:WaitForChild("Feedback") :: RemoteEvent
    local deliverRemote = network:WaitForChild("DeliverCarry") :: RemoteEvent
    deliverRemote.OnServerEvent:Connect(requestDelivery)
    Players.PlayerRemoving:Connect(function(player)
        pending[player.UserId] = nil
        lastResult[player.UserId] = nil
        lastFeedback[player.UserId] = nil
    end)
end

return table.freeze(DeliveryService)
