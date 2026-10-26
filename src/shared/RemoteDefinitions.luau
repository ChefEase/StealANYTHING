--!strict

-- Only these client-to-server actions may be created. Payload validation belongs
-- to server Networking modules added with each gameplay feature.
local requestNames = {
    BeginPickup = "BeginPickup",
    CancelPickup = "CancelPickup",
    DeliverCarry = "DeliverCarry",
    DropCarry = "DropCarry",
    StartTutorialReplay = "StartTutorialReplay",
    Shove = "Shove",
    Dash = "Dash",
    ArrangeExhibit = "ArrangeExhibit",
    BuyShopItem = "BuyShopItem",
    BuyAccreditation = "BuyAccreditation",
    SelectRecovery = "SelectRecovery",
    ClaimContract = "ClaimContract",
    UpdateSettings = "UpdateSettings",
    TravelTipSettings = "TravelTipSettings",
    RideToDepot = "RideToDepot",
}

return table.freeze({ Requests = table.freeze(requestNames) })
