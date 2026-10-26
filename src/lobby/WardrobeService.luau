--!strict

local Session = require(script.Parent.Parent.MatchShared.WardrobeSession)
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local okMuseumStore, museumStore = pcall(function()
    return DataStoreService:GetDataStore(if RunService:IsStudio()
        then "StealAnything_Dev_v1" else "StealAnything_Prod_v1")
end)

local WardrobeService = {}

function WardrobeService.Start()
    Session.Start({
        -- Read only: the lobby never leases or mutates the museum profile.
        -- A confirmed cash grant can repair a missed wardrobe mirror write.
        profileOwned = function(player: Player): {[string]: boolean}?
            if not okMuseumStore then return nil end
            local ok, profile = pcall(function()
                return museumStore:GetAsync("player:" .. player.UserId)
            end)
            if not ok or type(profile) ~= "table" or type(profile.cosmetics) ~= "table" then
                return nil
            end
            return profile.cosmetics
        end,
    })
    local lobby = workspace:WaitForChild("HeistLobby")
    local display = lobby:FindFirstChild("RobberWardrobeDisplay")
    local anchor = display and display:FindFirstChild("WardrobePromptAnchor")
    if anchor == nil or not anchor:IsA("BasePart") then
        warn("[Steal Anything Lobby] Wardrobe locker prompt anchor is missing")
        return
    end
    local prompt = anchor:FindFirstChild("OpenWardrobe")
    if prompt == nil then
        local created = Instance.new("ProximityPrompt")
        created.Name = "OpenWardrobe"
        created.ActionText = "Open wardrobe"
        created.ObjectText = "Robber Wardrobe"
        created.MaxActivationDistance = 12
        created.HoldDuration = 0
        created.RequiresLineOfSight = false
        created.Parent = anchor
        prompt = created
    end
    (prompt :: ProximityPrompt).Triggered:Connect(Session.Open)
end

return table.freeze(WardrobeService)
