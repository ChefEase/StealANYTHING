--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = require(script.Parent.Parent.Domain.ExhibitArrangementRules)
local IncomeService = require(script.Parent.IncomeService)
local PlotService = require(script.Parent.PlotService)
local ProfileService = require(script.Parent.ProfileService)

local Service = {}
local started = false
local raidLocks: {[number]: boolean} = {}
local lastRequest: {[number]: number} = {}
local feedback: RemoteEvent? = nil

local MESSAGES = {
    Allowed = "This item may now appear on a public stand.",
    StoredSafe = "Item moved to safe storage. It earns no income there.",
    Placed = "Exhibit placed on a public stand.",
    PlacedProtected = "Exhibit placed on the protected stand at half income.",
    AutoEnabled = "Automatic display is on for approved items.",
    ManualEnabled = "Manual display selection is on.",
    StorageFull = "Storage is full. Make room before storing another item.",
    FinishTutorial = "Earn the toaster's first displayed dollar before rearranging it.",
    NotOwned = "That item is not available in your collection.",
    InvalidSlot = "That display stand is not available.",
}

local function tell(player: Player, message: string, kind: string)
    if feedback ~= nil and player.Parent == Players then
        feedback:FireClient(player, { text = message, kind = kind })
    end
end

local function arrange(player: Player, action: any, itemId: any,
    slotId: any, requestId: any)
    if type(action) ~= "string" or #action > 16
        or type(requestId) ~= "string" or #requestId < 8 or #requestId > 64
        or string.match(requestId, "^[%w%-]+$") == nil
        or itemId ~= nil and (type(itemId) ~= "string" or #itemId > 48)
        or slotId ~= nil and (type(slotId) ~= "string" or #slotId > 24) then return end
    local now = os.clock()
    if now - (lastRequest[player.UserId] or -math.huge) < 0.25 then return end
    lastRequest[player.UserId] = now
    if raidLocks[player.UserId] or player:GetAttribute("RaidTransferLocked") == true then
        tell(player, "Wait until the active raid ends before moving exhibits.", "Error")
        return
    end
    if player:GetAttribute("ProfileState") ~= "Ready"
        or PlotService.GetMuseum(player) == nil then return end
    local snapshot = ProfileService.GetSnapshot(player)
    if snapshot == nil then return end
    -- Check expected rejection without creating a saved operation.
    local preview = table.clone(snapshot)
    preview.displaySlots = table.clone(snapshot.displaySlots)
    preview.publicDisplayApproved = table.clone(snapshot.publicDisplayApproved)
    local result, resultCode = Rules.Apply(preview, action, itemId, slotId)
    if result ~= "Committed" then
        tell(player, MESSAGES[resultCode] or "That exhibit move is not available.", "Error")
        return
    end
    IncomeService.Settle(player)
    local operationId = ProfileService.NewOperationId(player)
    if operationId == nil then return end
    local operation, status = ProfileService.ApplyOperation(player, operationId,
        "ExhibitArrangement", requestId, function(profile: any): (string, string)
            return Rules.Apply(profile, action, itemId, slotId)
        end)
    if operation ~= nil and operation.result == "Committed" then
        PlotService.RefreshDisplays(player)
        tell(player, MESSAGES[operation.resultCode] or "Collection updated.", "Success")
    elseif status == "SaveError" or status == "RetryableError" then
        tell(player, "Saving delayed. Try again in a moment.", "Error")
    else
        tell(player, "Collection change was not saved.", "Error")
    end
end

function Service.SetRaidLocked(player: Player, locked: boolean)
    raidLocks[player.UserId] = if locked then true else nil
    player:SetAttribute("RaidTransferLocked", locked)
end

function Service.Start()
    if started then return end
    started = true
    local remote = ReplicatedStorage:WaitForChild("Network"):WaitForChild("ArrangeExhibit") :: RemoteEvent
    feedback = ReplicatedStorage.Network:WaitForChild("Feedback") :: RemoteEvent
    remote.OnServerEvent:Connect(arrange)
    local finishTutorial = ReplicatedStorage.Network:WaitForChild("FinishCollectionTutorial") :: RemoteEvent
    finishTutorial.OnServerEvent:Connect(function(player: Player)
        if player:GetAttribute("ProfileState") ~= "Ready" then return end
        local snapshot = ProfileService.GetSnapshot(player)
        if snapshot == nil or snapshot.settings.collectionTutorialDone then return end
        local hasPublicItem = false
        for itemId, exhibit in pairs(snapshot.exhibits) do
            if itemId ~= "toaster" and exhibit.state == "Available" then
                hasPublicItem = true
                break
            end
        end
        if not hasPublicItem then return end
        local operationId = ProfileService.NewOperationId(player)
        if operationId == nil then return end
        ProfileService.ApplyOperation(player, operationId,
            "ExhibitArrangement", "collection-tutorial-complete",
            function(profile: any): (string, string)
                if profile.settings.collectionTutorialDone then
                    return "Rejected", "AlreadyComplete"
                end
                profile.settings.collectionTutorialDone = true
                return "Committed", "TutorialComplete"
            end)
    end)
    Players.PlayerRemoving:Connect(function(player)
        raidLocks[player.UserId] = nil
        lastRequest[player.UserId] = nil
    end)
end

return table.freeze(Service)
