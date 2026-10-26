--!strict

local ProfileService = require(script.Parent.ProfileService)
local Session = require(script.Parent.Parent.Parent.MatchShared.WardrobeSession)
local Catalog = require(game:GetService("ReplicatedStorage").Shared.WardrobeCatalog)
local PurchaseRules = require(script.Parent.Parent.Domain.WardrobePurchaseRules)

local WardrobeService = {}
local pending: {[number]: { id: string, operationId: string }} = {}

local function purchase(player: Player, id: string): (boolean, string)
    local item = Catalog.ById[id]
    if item == nil or item.currency ~= "Cash" or item.price <= 0 then
        return false, "That item is unavailable."
    end
    local existing = pending[player.UserId]
    if existing and existing.id ~= id then return false, "Finish the previous purchase first." end
    if player:GetAttribute("ProfileState") ~= "Ready" and existing == nil then
        return false, "Museum data is not ready."
    end
    local operationId = existing and existing.operationId or ProfileService.NewOperationId(player)
    if operationId == nil then return false, "Museum data is not ready." end
    pending[player.UserId] = { id = id, operationId = operationId }
    for attempt = 1, 3 do
        local operation, status = ProfileService.ApplyOperation(player, operationId,
            "WardrobePurchase", id, function(profile: any): (string, string)
                return PurchaseRules.Apply(profile, id)
            end)
        if operation then
            pending[player.UserId] = nil
            if operation.resultCode == "Purchased" then
                return true, item.name .. " unlocked for $" .. item.price .. "."
            elseif operation.resultCode == "AlreadyOwned" then
                return true, "Already owned. No cash spent."
            end
            return false, "Not enough cash."
        end
        if status ~= "RetryableError" and status ~= "SaveError" then
            pending[player.UserId] = nil
            return false, "Purchase stopped: " .. status
        end
        if attempt < 3 then task.wait(2) end
    end
    return false, "Purchase save is uncertain. Retry this item; no second charge will be made."
end

function WardrobeService.Start()
    Session.Start({
        purchase = purchase,
        profileOwned = function(player: Player): {[string]: boolean}?
            local profile = ProfileService.GetSnapshot(player)
            return profile and profile.cosmetics or nil
        end,
    })
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        pending[player.UserId] = nil
    end)
end

return table.freeze(WardrobeService)
