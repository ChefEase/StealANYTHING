--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarryService = require(script.Parent.CarryService)
local IncomeService = require(script.Parent.IncomeService)
local ProfileService = require(script.Parent.ProfileService)
local PlotService = require(script.Parent.PlotService)
local TutorialDeliveryRules = require(script.Parent.Parent.Domain.TutorialDeliveryRules)
local PublicDeliveryRules = require(script.Parent.Parent.Domain.PublicDeliveryRules)
local BestPublicDisplays = require(script.Parent.Parent.Domain.BestPublicDisplays)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)

type Pending = {
    carryId: string,
    runId: string,
    operationId: string,
    itemId: string,
    tutorial: boolean,
    inFlight: boolean,
}

local DeliveryService = {}
local started = false
local pending: {[number]: Pending} = {}
local lastResult: {[number]: string} = {}
local lastFeedback: {[number]: number} = {}
local reconciling: {[number]: boolean} = {}
local feedback: RemoteEvent? = nil

local function tell(player: Player, message: string, kind: string?)
    local now = os.clock()
    if now - (lastFeedback[player.UserId] or -math.huge) < 0.65 then return end
    lastFeedback[player.UserId] = now
    if feedback ~= nil and player.Parent == Players then
        feedback:FireClient(player, { text = message, kind = kind or "Info" })
    end
end

local function reconcileDisplays(player: Player)
    local userId = player.UserId
    if reconciling[userId] or player.Parent ~= Players
        or PlotService.GetMuseum(player) == nil then return end
    local snapshot = ProfileService.GetSnapshot(player)
    if snapshot == nil or snapshot.tutorialStep < 2 then return end
    local preview = {
        exhibits = snapshot.exhibits,
        displaySlots = table.clone(snapshot.displaySlots),
    }
    if not BestPublicDisplays.Apply(preview) then return end
    reconciling[userId] = true
    IncomeService.Settle(player)
    local operationId = ProfileService.NewOperationId(player)
    if operationId ~= nil then
        local operation = ProfileService.ApplyOperation(player, operationId,
            "ExhibitArrangement", "auto-best-public-displays",
            function(profile: any): (string, string)
                if BestPublicDisplays.Apply(profile) then
                    return "Committed", "BestPublicDisplays"
                end
                return "Rejected", "AlreadyBest"
            end)
        if operation ~= nil and operation.result == "Committed" then
            PlotService.RefreshDisplays(player)
        end
    end
    reconciling[userId] = nil
end

local function process(player: Player, record: Pending)
    if pending[player.UserId] ~= record or record.inFlight or player.Parent ~= Players then return end
    record.inFlight = true
    -- Settle any old displayed income before the protected slot becomes active.
    IncomeService.Settle(player)
    local nowUnix = os.time()
    local operation, status = ProfileService.ApplyOperation(player, record.operationId,
        "DepotDelivery", record.runId, function(profile: any): (string, string)
            if record.tutorial then
                return TutorialDeliveryRules.Apply(profile, nowUnix)
            end
            return PublicDeliveryRules.Apply(profile, record.itemId, nowUnix)
        end)
    record.inFlight = false
    if pending[player.UserId] ~= record then return end

    if operation ~= nil then
        if operation.result == "Rejected" and operation.resultCode == "StorageFull" then
            pending[player.UserId] = nil
            CarryService.SetDeliveryLocked(player, record.carryId, false)
            tell(player, "Storage is full. Make room before delivering this item.", "Error")
            return
        end
        PlotService.RefreshDisplays(player)
        pending[player.UserId] = nil
        CarryService.FinishDelivery(player, record.carryId)
        lastResult[player.UserId] = record.carryId
        if operation.result == "Committed" and record.tutorial then
            tell(player, "Tutorial complete! Your toaster earns $6/min while you play.", "Success")
        elseif operation.result == "Committed" and operation.resultCode == "DuplicateSalvaged" then
            local item = ItemCatalog.ById[record.itemId]
            tell(player, "Duplicate delivered! +$"
                .. tostring(item.baseIncomePerMinute * 3) .. " salvage.", "Success")
        elseif operation.result == "Committed" then
            local snapshot = ProfileService.GetSnapshot(player)
            local slots = snapshot and snapshot.displaySlots
            local displayed = slots ~= nil and (slots.exposed_01 == record.itemId
                or slots.exposed_02 == record.itemId)
            tell(player, ItemCatalog.ById[record.itemId].name
                .. (if displayed then " displayed! Open Menu > Collection to choose Auto, Manual or safe storage."
                    else " stored safely. Open Menu > Collection to place it on a stand."),
                "Success")
        else
            tell(player, "That delivery was already processed.", "Info")
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
        tell(player, "That run was already delivered.", "Info")
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
            tell(player, "Stand on the green museum DROP-OFF carpet to deliver.", "Error")
        elseif reason == "TooFast" then
            tell(player, "Keep carrying the toaster along the route to your museum.", "Error")
        elseif reason == "InvalidRoute" then
            CarryService.AbortCarry(player, carryId)
            tell(player, "That run was reset. Pick up fresh stock at the depot.", "Error")
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
        itemId = carry.itemId,
        tutorial = carry.tutorial,
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
    local function watchPlayer(player: Player)
        player:GetAttributeChangedSignal("PlotState"):Connect(function()
            if player:GetAttribute("PlotState") == "Ready" then
                task.spawn(reconcileDisplays, player)
            end
        end)
        if player:GetAttribute("PlotState") == "Ready" then
            task.spawn(reconcileDisplays, player)
        end
    end
    Players.PlayerAdded:Connect(watchPlayer)
    for _, player in Players:GetPlayers() do watchPlayer(player) end
    Players.PlayerRemoving:Connect(function(player)
        pending[player.UserId] = nil
        lastResult[player.UserId] = nil
        lastFeedback[player.UserId] = nil
        reconciling[player.UserId] = nil
    end)
end

return table.freeze(DeliveryService)
