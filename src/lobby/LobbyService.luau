--!strict
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = script.Parent.Parent:WaitForChild("MatchShared")
local Config = require(Shared.PlaceConfig)
local State = require(Shared.MatchState)
local Registry = require(Shared.MatchRegistry)
local TeleportRetry = require(Shared.TeleportRetry)

local LobbyService = {}
local started = false
local enabled: {[number]: boolean} = {}
local teleporting: {[number]: string} = {}
local teleportFailures: {[number]: number} = {}
local remote: RemoteEvent

local function tell(player: Player, status: string, count: number)
    if player.Parent == Players then
        player:SetAttribute("MatchStatus", status)
        player:SetAttribute("WaitingCount", count)
        remote:FireClient(player, status, count)
    end
end

local function queuePlayer(player: Player)
    if not enabled[player.UserId] then return false end
    if RunService:IsStudio() then
        tell(player, "STUDIO PREVIEW - LIVE MATCHMAKING REQUIRES PUBLISHING", 1)
        return false
    end
    local join = player:GetJoinData()
    local inviter = join.ReferredByPlayerId
    if type(inviter) ~= "number" or inviter <= 0 or inviter == player.UserId then
        inviter = 0
    end
    local _, errorMessage = Registry.Update(function(old)
        return State.Queue(old, player.UserId, game.JobId, inviter, os.time(),
            Config.QueueLeaseSeconds)
    end)
    if errorMessage then
        tell(player, "MATCHMAKING TEMPORARILY UNAVAILABLE — RETRY", 0)
        return false
    end
    return true
end

local function clearAssignment(player: Player)
    local _, err = Registry.Update(function(old)
        return State.Cancel(old, player.UserId, os.time())
    end)
    if err then warn("[Steal Anything Lobby] Could not clear assignment: " .. err) end
end

local function failedTeleport(player: Player, reason: string)
    warn("[Steal Anything Lobby] Museum teleport failed for "
        .. tostring(player.UserId) .. ": " .. reason)
    clearAssignment(player)
    if player.Parent ~= Players or not enabled[player.UserId] then return end
    local failures = (teleportFailures[player.UserId] or 0) + 1
    teleportFailures[player.UserId] = failures
    if failures >= 3 then
        enabled[player.UserId] = false
        tell(player, "TELEPORT FAILED - PRESS RETRY", 0)
    else
        tell(player, "TELEPORT FAILED - RETRYING MATCHMAKING", 0)
        task.delay(3, queuePlayer, player)
    end
end

local function teleport(player: Player, assignment: any)
    if teleporting[player.UserId] or player.Parent ~= Players then return end
    teleporting[player.UserId] = assignment.ticket
    tell(player, "JOINING YOUR MUSEUM SERVER", 0)
    task.spawn(function()
        local success, _, err = TeleportRetry.Run(3, function()
            local options = Instance.new("TeleportOptions")
            options.ReservedServerAccessCode = assignment.code
            options:SetTeleportData({
                serverKey = assignment.serverKey,
                ticket = assignment.ticket,
            })
            TeleportService:TeleportAsync(Config.GamePlaceId, { player }, options)
        end, task.wait, function()
            return player.Parent == Players and enabled[player.UserId] == true
                and teleporting[player.UserId] == assignment.ticket
        end)
        if teleporting[player.UserId] ~= assignment.ticket then return end
        if success then
            -- TeleportAsync may return before an eventual TeleportInitFailed.
            task.delay(Config.ReservationSeconds - 15, function()
                if teleporting[player.UserId] ~= assignment.ticket then return end
                teleporting[player.UserId] = nil
                if player.Parent == Players and enabled[player.UserId] then
                    failedTeleport(player, "Player did not leave before ticket expiry")
                end
            end)
            return
        end
        teleporting[player.UserId] = nil
        if player.Parent == Players and enabled[player.UserId] then
            failedTeleport(player, err or "TeleportAsync failed")
        end
    end)
end

local function teleportAssignedPlayers(state: any)
    for _, player in Players:GetPlayers() do
        if enabled[player.UserId] and not teleporting[player.UserId] then
            local assignment = state.assignments[tostring(player.UserId)]
            if assignment then teleport(player, assignment) end
        end
    end
end

local function playerAdded(player: Player)
    enabled[player.UserId] = true
    if RunService:IsStudio() then
        tell(player, "STUDIO PREVIEW - LIVE MATCHMAKING REQUIRES PUBLISHING", 1)
        return
    end
    if Config.LobbyPlaceId == 0 or Config.GamePlaceId == 0
        or (not RunService:IsStudio() and game.PlaceId ~= Config.LobbyPlaceId) then
        tell(player, "LOBBY PLACE ID NEEDS CONFIGURATION", 0)
        return
    end
    local join = player:GetJoinData()
    local data = join.TeleportData
    if join.SourcePlaceId == Config.GamePlaceId
        and join.SourceGameId == game.GameId
        and type(data) == "table" and type(data.admissionError) == "string" then
        enabled[player.UserId] = false
        tell(player, "ENTRY FAILED: " .. data.admissionError .. " - RETRY", 0)
        return
    end
    queuePlayer(player)
end

function LobbyService.Start()
    if started then return end
    started = true
    remote = ReplicatedStorage:WaitForChild("MatchStatus") :: RemoteEvent
    local control = ReplicatedStorage:WaitForChild("MatchControl") :: RemoteEvent
    control.OnServerEvent:Connect(function(player: Player, action: any)
        if action == "Cancel" then
            enabled[player.UserId] = false
            teleporting[player.UserId] = nil
            clearAssignment(player)
            tell(player, "MATCHMAKING CANCELLED", 0)
        elseif action == "Retry" and not teleporting[player.UserId] then
            enabled[player.UserId] = true
            teleportFailures[player.UserId] = 0
            queuePlayer(player)
        end
    end)
    TeleportService.TeleportInitFailed:Connect(function(player, result, message, placeId, options)
        if placeId ~= Config.GamePlaceId or player.Parent ~= Players then return end
        local data = options and options:GetTeleportData()
        if type(data) ~= "table" or teleporting[player.UserId] ~= data.ticket then return end
        teleporting[player.UserId] = nil
        failedTeleport(player, tostring(result) .. ": " .. tostring(message))
    end)
    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(function(player)
        enabled[player.UserId] = nil
        teleporting[player.UserId] = nil
        teleportFailures[player.UserId] = nil
        -- Keep a claimed reservation intact during a successful teleport.
        Registry.Update(function(old)
            return State.Withdraw(old, player.UserId, os.time())
        end)
    end)
    for _, player in Players:GetPlayers() do playerAdded(player) end
    task.spawn(function()
        while started do
            if not RunService:IsStudio() and Config.LobbyPlaceId ~= 0
                and Config.GamePlaceId ~= 0 then
                local snapshot, readError = Registry.Read()
                if snapshot then
                    teleportAssignedPlayers(snapshot)
                    local waiting = State.WaitingCount(snapshot)
                    for _, player in Players:GetPlayers() do
                        if enabled[player.UserId] and not teleporting[player.UserId] then
                            if queuePlayer(player) then
                                local entry = snapshot.queue[tostring(player.UserId)]
                                local friendFull = false
                                if entry and entry.inviter and entry.inviter > 0 then
                                    for _, server in pairs(snapshot.servers) do
                                        if server.members[tostring(entry.inviter)]
                                            and State.FreeSlots(server) == 0 then
                                            friendFull = true
                                            break
                                        end
                                    end
                                end
                                local status = if friendFull then "FRIEND'S SERVER FULL - FINDING A MATCH"
                                    elseif waiting < 2 and next(snapshot.servers) ~= nil
                                        then "WAITING FOR ANOTHER PLAYER"
                                    else "FINDING A MUSEUM SERVER"
                                tell(player, status, math.max(waiting, 1))
                                local claimed, claimError = Registry.Update(function(old)
                                    return State.ClaimExisting(old, player.UserId, os.time(),
                                        HttpService:GenerateGUID(false), Config.ReservationSeconds)
                                end)
                                if claimed then
                                    teleportAssignedPlayers(claimed)
                                elseif claimError then
                                    warn("[Steal Anything Lobby] Could not claim open museum slot: "
                                        .. claimError)
                                end
                            end
                        end
                    end
                    if waiting >= 2 or (waiting >= 1 and next(snapshot.servers) == nil) then
                        local ok, code = pcall(function()
                            return TeleportService:ReserveServerAsync(Config.GamePlaceId)
                        end)
                        if ok then
                            local claimed, claimError = Registry.Update(function(old)
                                local key = HttpService:GenerateGUID(false)
                                local ticketA = HttpService:GenerateGUID(false)
                                if waiting >= 2 then
                                    return State.ClaimPair(old, os.time(), key, code,
                                        ticketA, HttpService:GenerateGUID(false),
                                        Config.ReservationSeconds)
                                end
                                return State.ClaimFirstSolo(old, os.time(), key, code,
                                    ticketA, Config.ReservationSeconds)
                            end)
                            if claimed then
                                teleportAssignedPlayers(claimed)
                            elseif claimError then
                                warn("[Steal Anything Lobby] Could not claim new museum server: "
                                    .. claimError)
                            end
                        else
                            warn("[Steal Anything Lobby] Could not reserve museum server: "
                                .. tostring(code))
                            for _, player in Players:GetPlayers() do
                                if enabled[player.UserId] and not teleporting[player.UserId] then
                                    tell(player, "SERVER RESERVATION FAILED - RETRYING", waiting)
                                end
                            end
                        end
                    end
                else
                    if readError then
                        warn("[Steal Anything Lobby] Could not read matchmaking registry: "
                            .. readError)
                    end
                    for _, player in Players:GetPlayers() do
                        tell(player, "MATCHMAKING TEMPORARILY UNAVAILABLE — RETRY", 0)
                    end
                end
            end
            task.wait(5)
        end
    end)
end

return table.freeze(LobbyService)
