--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlotService = require(script.Parent.PlotService)
local ProfileService = require(script.Parent.ProfileService)
local TravelEffects = require(script.Parent.TravelEffects)

local TravelService = {}
local lastRide: {[number]: number} = {}

local function getPosition(player: Player): Vector3?
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then root.Position else nil
end

function TravelService.Start()
    local network = ReplicatedStorage:WaitForChild("Network")
    local ride = network:FindFirstChild("RideToDepot")
    if not ride then
        ride = Instance.new("RemoteEvent")
        ride.Name = "RideToDepot"
        ride.Parent = network
    end
    local rideEvent = ride :: RemoteEvent
    rideEvent.OnServerEvent:Connect(function(player: Player)
        if player:GetAttribute("ProfileState") ~= "Ready" then return end
        if player:GetAttribute("GuardChased") == true then return end
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
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        lastRide[player.UserId] = nil
    end)
end

return table.freeze(TravelService)
