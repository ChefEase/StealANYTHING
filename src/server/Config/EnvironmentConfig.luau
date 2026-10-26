--!strict

-- Keep Studio test profiles separate from players joining the published game.
local RunService = game:GetService("RunService")
local environment = if RunService:IsStudio() then "development" else "production"

local storeNames = table.freeze({
    development = "StealAnything_Dev_v1",
    test = "StealAnything_Test_v1",
    production = "StealAnything_Prod_v1",
})

return table.freeze({
    Environment = environment,
    StoreName = storeNames[environment],
    StoreNames = storeNames,
})
