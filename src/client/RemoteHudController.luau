--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ContractDefinitions = require(Shared:WaitForChild("ContractDefinitions"))
local ItemCatalog = require(Shared:WaitForChild("ItemCatalog"))

local RemoteHudController = {}

local function normalizedKind(value: any): string
    if type(value) ~= "string" or value == "" then return "Info" end
    return string.upper(string.sub(value, 1, 1)) .. string.lower(string.sub(value, 2))
end

function RemoteHudController.Start(player: Player)
    local networkFolder = ReplicatedStorage:WaitForChild("Network", 10)
    if networkFolder == nil then return end
    local profileSync = networkFolder:FindFirstChild("ProfileSync") :: RemoteEvent?
    local feedback = networkFolder:WaitForChild("Feedback", 10) :: RemoteEvent?
    local notificationSerial = 0

    if profileSync ~= nil then profileSync.OnClientEvent:Connect(function(snapshot)
        if type(snapshot) ~= "table" then return end

        if type(snapshot.cash) == "number" then
            player:SetAttribute("Cash", snapshot.cash)
        end

        local carrying = snapshot.carrying
        if type(carrying) == "string" and carrying ~= "" then
            local definition = ItemCatalog.ById[carrying]
            player:SetAttribute("CurrentCarryItem", if definition ~= nil then definition.name else carrying)
            player:SetAttribute("CarryBehavior", if definition ~= nil then definition.carry else "")
            player:SetAttribute("CarryDestination", "Museum Drop-Off")
        else
            player:SetAttribute("CurrentCarryItem", nil)
            player:SetAttribute("CarryBehavior", nil)
            player:SetAttribute("CarryDestination", nil)
            player:SetAttribute("CarryDistance", nil)
        end

        local contracts = snapshot.contracts
        if type(contracts) == "table" and #contracts > 0 then
            local selected = contracts[1]
            if type(snapshot.pinnedContractId) == "string" then
                for _, contract in contracts do
                    if contract.instanceId == snapshot.pinnedContractId then
                        selected = contract
                        break
                    end
                end
            end
            local definition = ContractDefinitions.ById[selected.definitionId]
            player:SetAttribute("CurrentObjective", if definition ~= nil then definition.name else "Complete Contract")
            player:SetAttribute("ObjectiveComplete", selected.completed == true)
        end
    end) end

    if feedback ~= nil then feedback.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" or type(data.text) ~= "string" or data.text == "" then return end
        notificationSerial += 1
        player:SetAttribute("HudNotificationKind", normalizedKind(data.kind))
        player:SetAttribute("HudNotificationDetail", "")
        player:SetAttribute("HudNotificationText", data.text)
        player:SetAttribute("HudNotificationSerial", notificationSerial)
    end) end
end

return table.freeze(RemoteHudController)
