--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = script.Parent.Parent.Parent.MatchShared
local Config = require(Shared.PlaceConfig)
local State = require(Shared.MatchState)
local Registry = require(Shared.MatchRegistry)
local Rules = require(Shared.MatchRules)

local MatchService = {}
local started = false
local serverKey: string? = nil
local serverCode: string? = nil
local admitted: {[number]: boolean} = {}
local lobbyAttempts: {[number]: number} = {}
local lobbyRedirectBusy: {[number]: boolean} = {}

local function activeCount(): number
    local records = {}
    for _, player in Players:GetPlayers() do
        table.insert(records, { admitted = admitted[player.UserId] == true,
            profile = player:GetAttribute("ProfileState"),
            plot = player:GetAttribute("PlotState") })
    end
    return Rules.ReadyCount(records)
end

local function refreshActive()
    local active = activeCount() >= Config.MinimumPlayers
    game:SetAttribute("MatchmakingState", if active then "Active" else "WaitingForPlayer")
    for _, player in Players:GetPlayers() do
        local ready = admitted[player.UserId] == true
            and player:GetAttribute("ProfileState") == "Ready"
            and player:GetAttribute("PlotState") == "Ready"
        local canPlay = active and ready
        player:SetAttribute("MatchActive", canPlay)
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            root.Anchored = not canPlay
        end
    end
end

local function sendToLobby(player: Player, reason: string?)
    if lobbyRedirectBusy[player.UserId] then return end
    lobbyRedirectBusy[player.UserId] = true
    player:SetAttribute("MatchAdmission", "Denied")
    if Config.LobbyPlaceId <= 0 then
        player:Kick("Matchmaking lobby is not configured yet. Please try again later.")
        return
    end
    local join = player:GetJoinData()
    local inviter = join.ReferredByPlayerId
    if type(inviter) == "number" and inviter > 0 and inviter ~= player.UserId then
        Registry.Update(function(old)
            return State.ReferralHint(old, player.UserId, inviter, os.time(),
                Config.AssignmentSeconds)
        end)
    end
    while (lobbyAttempts[player.UserId] or 0) < 3 do
        if player.Parent ~= Players then return end
        local attempt = (lobbyAttempts[player.UserId] or 0) + 1
        lobbyAttempts[player.UserId] = attempt
        local ok, err = pcall(function()
            local options = Instance.new("TeleportOptions")
            if reason then options:SetTeleportData({ admissionError = reason }) end
            TeleportService:TeleportAsync(Config.LobbyPlaceId, { player }, options)
        end)
        if ok then
            lobbyRedirectBusy[player.UserId] = nil
            return
        end
        warn("[Steal Anything] Lobby redirect attempt " .. attempt
            .. " failed: " .. tostring(err))
        task.wait(math.min(2 ^ attempt, 8))
    end
    lobbyRedirectBusy[player.UserId] = nil
    if player.Parent == Players then
        player:Kick("Could not reach the matchmaking lobby. Please rejoin.")
    end
end

local function verify(player: Player)
    player:SetAttribute("MatchAdmission", "Pending")
    player:SetAttribute("MatchActive", false)
    local join = player:GetJoinData()
    local teleportData = join.TeleportData
    local fromLobby = join.SourcePlaceId == Config.LobbyPlaceId
        and join.SourceGameId == game.GameId
    local key = type(teleportData) == "table" and teleportData.serverKey or nil
    local ticket = type(teleportData) == "table" and teleportData.ticket or nil
    if type(key) ~= "string" or type(ticket) ~= "string"
        or game.PlaceId ~= Config.GamePlaceId
        or game.PrivateServerId == "" or game.PrivateServerOwnerId ~= 0 then
        warn("[Steal Anything] Rejecting museum arrival for " .. tostring(player.UserId)
            .. ": missing teleport ticket or not in a reserved game server")
        sendToLobby(player, if fromLobby then "MISSING MUSEUM TICKET" else nil)
        return
    end
    if serverKey ~= nil and serverKey ~= key then
        warn("[Steal Anything] Rejecting museum arrival for " .. tostring(player.UserId)
            .. ": server key mismatch")
        sendToLobby(player, "SERVER MISMATCH")
        return
    end
    local updated = nil
    local lastError: string? = nil
    for attempt = 1, 6 do
        updated, lastError = Registry.Update(function(old)
            return State.Arrive(old, player.UserId, key, ticket, game.JobId,
                os.time(), Config.ServerLeaseSeconds)
        end)
        if updated then break end
        task.wait(math.min(2 ^ attempt, 8))
    end
    local server = updated and updated.servers[key]
    if server == nil or server.members[tostring(player.UserId)] ~= true
        or server.jobId ~= game.JobId then
        local reason = if lastError then "REGISTRY UNAVAILABLE"
            elseif updated then State.ArrivalFailure(updated, player.UserId,
                key, ticket, game.JobId)
            else "ENTRY NOT CONFIRMED"
        warn("[Steal Anything] Rejecting museum arrival for " .. tostring(player.UserId)
            .. ": " .. reason .. (if lastError then " (" .. lastError .. ")" else ""))
        sendToLobby(player, reason)
        return
    end
    serverKey = key
    serverCode = server.code
    admitted[player.UserId] = true
    player:SetAttribute("MatchAdmission", "Accepted")
    refreshActive()
end

local function playerAdded(player: Player)
    if not game:GetAttribute("MatchmakingEnabled") then
        admitted[player.UserId] = true
        player:SetAttribute("MatchAdmission", "Accepted")
        player:SetAttribute("MatchActive", true)
        return
    end
    player:GetAttributeChangedSignal("ProfileState"):Connect(refreshActive)
    player:GetAttributeChangedSignal("PlotState"):Connect(refreshActive)
    player.CharacterAdded:Connect(function(character)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if root then refreshActive() end
    end)
    task.spawn(verify, player)
end

function MatchService.Start()
    if started then return end
    started = true
    local enabled = not RunService:IsStudio() and Config.LobbyPlaceId > 0
    game:SetAttribute("MatchmakingEnabled", enabled)
    game:SetAttribute("MatchmakingState", if enabled then "WaitingForPlayer" else "LocalTesting")
    if not RunService:IsStudio() and not enabled then
        warn("[Steal Anything] Matchmaking disabled: configure LobbyPlaceId and game place")
    elseif enabled and Players.MaxPlayers ~= Config.MaximumPlayers then
        warn("[Steal Anything] Game place maximum must be "
            .. tostring(Config.MaximumPlayers) .. " in Creator Dashboard")
    end
    Players.PlayerAdded:Connect(playerAdded)
    TeleportService.TeleportInitFailed:Connect(function(player, _, message, placeId)
        if placeId ~= Config.LobbyPlaceId or player.Parent ~= Players then return end
        warn("[Steal Anything] Lobby teleport initialization failed: "
            .. tostring(message))
        if (lobbyAttempts[player.UserId] or 0) >= 3 then
            player:Kick("Could not reach the matchmaking lobby. Please rejoin.")
        else
            task.delay(2, sendToLobby, player)
        end
    end)
    Players.PlayerRemoving:Connect(function(player)
        admitted[player.UserId] = nil
        lobbyAttempts[player.UserId] = nil
        lobbyRedirectBusy[player.UserId] = nil
        if enabled and serverKey then
            Registry.Update(function(old)
                return State.Leave(old, serverKey :: string, player.UserId,
                    os.time(), game.JobId)
            end)
        end
        task.defer(refreshActive)
    end)
    for _, player in Players:GetPlayers() do playerAdded(player) end
    if enabled then
        task.spawn(function()
            while started do
                if serverKey then
                    local members = {}
                    for userId in pairs(admitted) do table.insert(members, userId) end
                    if #members > 0 then
                        local _, heartbeatError = Registry.Update(function(old)
                            return State.Heartbeat(old, serverKey :: string, game.JobId,
                                members, os.time(), Config.ServerLeaseSeconds, serverCode)
                        end)
                        if heartbeatError then
                            warn("[Steal Anything] Could not advertise open museum slots: "
                                .. heartbeatError)
                        end
                    end
                end
                refreshActive()
                task.wait(8)
            end
        end)
    end
end

return table.freeze(MatchService)
