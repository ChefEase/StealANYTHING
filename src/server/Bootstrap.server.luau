--!strict

print("[Steal Anything] Server bootstrap ready")

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(script.Parent.Parent.MatchShared.PlaceConfig)
local ingressOnly = not RunService:IsStudio() and Config.LobbyPlaceId > 0
    and (game.PrivateServerId == "" or game.PrivateServerOwnerId ~= 0)
-- Set this before client scripts start so a public redirect server never
-- flashes museum HUD or starts gameplay controllers while teleporting.
game:SetAttribute("MuseumIngressOnly", ingressOnly)
ReplicatedStorage:SetAttribute("MuseumIngressOnly", ingressOnly)

local MatchService = require(script.Parent.Services.MatchService)
MatchService.Start()

-- The existing start place remains the public entry. Public arrivals are
-- routed to the separate lobby; only reserved servers build museum gameplay.
if ingressOnly then
    return
end

local ProfileService = require(script.Parent.Services.ProfileService)
local IncomeService = require(script.Parent.Services.IncomeService)
local CarryService = require(script.Parent.Services.CarryService)
local DeliveryService = require(script.Parent.Services.DeliveryService)
local SeatService = require(script.Parent.Services.SeatService)
local PlotService = require(script.Parent.Services.PlotService)
local TravelService = require(script.Parent.Services.TravelService)
local WardrobeService = require(script.Parent.Services.WardrobeService)
ProfileService.Start()
PlotService.Start()
TravelService.Start()
WardrobeService.Start()
IncomeService.Start()
CarryService.Start()
DeliveryService.Start()
SeatService.Start()
