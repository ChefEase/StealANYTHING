--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PlotService = require(script.Parent.PlotService)
local ProfileService = require(script.Parent.ProfileService)
local TravelEffects = require(script.Parent.TravelEffects)

local TravelService = {}
local wasInside: {[number]: boolean} = {}
local offered: {[number]: boolean} = {}
local lastSettingUpdate: {[number]: number} = {}
local lastRide: {[number]: number} = {}
local lastTick = 0

local function getPosition(player: Player): Vector3?
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root.Position else nil
end

function TravelService.Start()
    local network = ReplicatedStorage:WaitForChild("Network")
    local settings = network:FindFirstChild("TravelTipSettings")
    if not settings then
        settings = Instance.new("RemoteEvent")
        settings.Name = "TravelTipSettings"
        settings.Parent = network
    end
    local ride = network:FindFirstChild("RideToDepot")
    if not ride then
        ride = Instance.new("RemoteEvent")
        ride.Name = "RideToDepot"
        ride.Parent = network
    end
    local settingsEvent = settings :: RemoteEvent
    local rideEvent = ride :: RemoteEvent
    settingsEvent.OnServerEvent:Connect(function(player: Player, enabled: any)
        if type(enabled) ~= "boolean" or player:GetAttribute("ProfileState") ~= "Ready" then return end
        local now = os.clock()
        if now - (lastSettingUpdate[player.UserId] or -10) < 0.4 then return end
        lastSettingUpdate[player.UserId] = now
        ProfileService.StageRoutine(player, function(profile: any)
            profile.settings.travelTipsEnabled = enabled
        end)
    end)
    rideEvent.OnServerEvent:Connect(function(player: Player)
        if player:GetAttribute("ProfileState") ~= "Ready" then return end
        local now = os.clock()
        if now - (lastRide[player.UserId] or -10) < 2 then return end
        local museum = PlotService.GetMuseum(player)
        local position = getPosition(player)
        if not museum or not position then return end
        local center = museum:GetPivot().Position
        if (Vector3.new(position.X, 0, position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude > 68 then return end
        local map = workspace:FindFirstChild("Map")
        local expansion = map and map:FindFirstChild("ExpansionDistrict")
        local depot = expansion and expansion:FindFirstChild("Depot")
        local platform = depot and depot:FindFirstChild("Platform")
        if platform and platform:IsA("BasePart") and player.Character then
            lastRide[player.UserId] = now
            if TravelEffects.Teleport(player,
                CFrame.new(platform.Position + Vector3.new(0, 4, -16))) then
                player:SetAttribute("RouteScouted", true)
            end
        end
    end)
    RunService.Heartbeat:Connect(function()
        if os.clock() - lastTick < 0.35 then return end
        lastTick = os.clock()
        for _, player in Players:GetPlayers() do
            if player:GetAttribute("ProfileState") ~= "Ready" then continue end
            local museum = PlotService.GetMuseum(player)
            local position = getPosition(player)
            if not museum or not position then continue end
            local localPosition = museum:GetPivot():PointToObjectSpace(position)
            local inside = math.abs(localPosition.X) < 28 and math.abs(localPosition.Z) < 28
            if wasInside[player.UserId] and not inside and not offered[player.UserId]
                and player:GetAttribute("TravelTipsEnabled") == true
                and (player:GetAttribute("TutorialStep") or 0) >= 2
                and (player:GetAttribute("NpcDeliveries") or 0) >= 2 then
                local saved = ProfileService.StageRoutine(player, function(profile: any)
                    profile.settings.travelTipsEnabled = false
                end)
                if saved then
                    offered[player.UserId] = true
                    player:SetAttribute("TravelOfferSerial", (player:GetAttribute("TravelOfferSerial") or 0) + 1)
                end
            end
            wasInside[player.UserId] = inside
        end
    end)
    Players.PlayerRemoving:Connect(function(player)
        wasInside[player.UserId] = nil
        offered[player.UserId] = nil
        lastSettingUpdate[player.UserId] = nil
        lastRide[player.UserId] = nil
    end)
end

return table.freeze(TravelService)
