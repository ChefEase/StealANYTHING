--!strict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Server = script.Parent.Parent
local Environment = require(Server.Config.EnvironmentConfig)
local RepositoryModule = require(Server.Data.ProfileRepository)
local ContractDefinitions = require(game:GetService("ReplicatedStorage").Shared.ContractDefinitions)
local ItemCatalog = require(game:GetService("ReplicatedStorage").Shared.ItemCatalog)
local Balance = require(game:GetService("ReplicatedStorage").Shared.BalanceConfig)
local PlotDefinitions = require(game:GetService("ReplicatedStorage").Shared.PlotDefinitions)
local IncomeMath = require(Server.Domain.IncomeMath)
local TutorialProgress = require(Server.Domain.TutorialProgress)
local MatchRules = require(Server.Parent.MatchShared.MatchRules)

local RETRY_DELAYS = { 5, 10, 20 }
local LEASE_REFRESH_SECONDS = 60
local AUTOSAVE_SECONDS = 60

local repository: any = nil
local started = false
local loadingPlayers: {[number]: boolean} = {}
local releasingPlayers: {[number]: string} = {}
local beforeReleaseHandlers: {(Player) -> ()} = {}
local collectionChanged: RemoteEvent? = nil
local collectionCache: {[number]: string} = {}

local ProfileService = {}

local function collectionPayload(profile: any): any
    local registered = {}
    local collection = {}
    local storageUsed = 0
    for _, itemId in ItemCatalog.OrderedIds do
        local exhibit = profile.exhibits[itemId]
        local slotId: string? = nil
        if exhibit ~= nil then
            table.insert(registered, itemId)
            for placedSlot, placedId in pairs(profile.displaySlots) do
                if placedId == itemId then slotId = placedSlot break end
            end
            if exhibit.state == "Available" and slotId == nil then
                storageUsed += 1
            end
        end
        if profile.collectionIndex[itemId] == true then
            table.insert(collection, {
                id = itemId,
                state = if exhibit then exhibit.state else "Discovered",
                slot = slotId,
                approved = profile.publicDisplayApproved[itemId] == true,
            })
        end
    end
    return {
        revision = profile.revision,
        registered = table.concat(registered, ","),
        state = HttpService:JSONEncode({
            items = collection,
            mode = profile.publicDisplayMode,
            storageUsed = storageUsed,
            storageCapacity = Balance.STORAGE_SLOTS_BY_MUSEUM_TIER[profile.museum.tier]
                or Balance.STARTING_STORAGE_SLOTS,
            displayCapacity = PlotDefinitions.Tiers[profile.museum.tier].standCount,
        }),
    }
end

local function syncPublicProfile(player: Player)
    if repository == nil then return end
    local profile = repository:GetSnapshot(player.UserId)
    if profile ~= nil then
        player:SetAttribute("Cash", profile.cash)
        player:SetAttribute("TravelTipsEnabled", profile.settings.travelTipsEnabled)
        player:SetAttribute("CollectionTutorialDone", profile.settings.collectionTutorialDone)
        player:SetAttribute("NpcDeliveries", profile.lifetime.npcDeliveries)
        player:SetAttribute("TutorialStep", profile.tutorialStep)
        player:SetAttribute("TutorialGuardProtected",
            TutorialProgress.FirstItemGuardProtected(profile))
        player:SetAttribute("HasTutorialToaster", profile.exhibits.toaster ~= nil)
        if collectionChanged ~= nil then
            local payload = collectionPayload(profile)
            local key = payload.registered .. "|" .. payload.state
            if collectionCache[player.UserId] ~= key then
                collectionCache[player.UserId] = key
                collectionChanged:FireClient(player, payload)
            end
        end
        player:SetAttribute("IncomePerMinute", IncomeMath.RatePerMinute(profile))
        local selected = profile.contracts[1]
        if profile.pinnedContractId ~= nil then
            for _, contract in profile.contracts do
                if contract.instanceId == profile.pinnedContractId then
                    selected = contract
                    break
                end
            end
        end
        local definition = selected and ContractDefinitions.ById[selected.definitionId]
        local objective = definition and definition.name or nil
        if selected ~= nil and selected.definitionId == "local_courier" then
            objective = "Local Courier (" .. tostring(selected.progress.npcDeliveries)
                .. "/2 deliveries)"
        end
        player:SetAttribute("CurrentObjective", objective)
        player:SetAttribute("ObjectiveComplete", selected and selected.completed or false)
    end
end

local function setState(player: Player, state: string)
    if player.Parent == Players then
        player:SetAttribute("ProfileState", state)
    end
end

local function safeEnvironment(): boolean
    if RunService:IsStudio() then
        return Environment.Environment == "development" or Environment.Environment == "test"
    end
    -- A published server cannot accidentally use the Studio development store.
    return Environment.Environment == "production"
end

local function setWriteFailure(player: Player?, reason: string)
    if player == nil then return end
    if reason == "Lost" or reason == "Conflict" then
        setState(player, "SessionConflict")
    elseif reason == "CorruptProfile" then
        setState(player, "DataError")
    else
        setState(player, "SaveError")
    end
end

local function saveWithRetries(userId: number, player: Player?): boolean
    if repository == nil then return false end
    for attempt = 1, 3 do
        local saved, reason = repository:SaveDirty(userId)
        if saved or reason == "NotLoaded" then
            if player ~= nil then setState(player, "Ready") end
            return true
        end
        setWriteFailure(player, reason)
        if reason == "Lost" or reason == "Conflict" or reason == "CorruptProfile" then
            return false
        end
        if attempt < 3 then task.wait(attempt + math.random() * 0.5) end
    end
    warn("[Steal Anything] Profile save still uncertain for user " .. userId)
    return false
end

local function releaseWithRetries(userId: number, player: Player?)
    if repository == nil then
        return
    end
    if not saveWithRetries(userId, player) then
        -- Let the lease expire instead of admitting a new writer over an uncertain save.
        return
    end
    for attempt = 1, 3 do
        local released, reason = repository:Release(userId)
        if released or reason == "Lost" or reason == "NotLoaded" then
            return
        end
        if attempt < 3 then
            task.wait(attempt)
        end
    end
    warn("[Steal Anything] Profile lease release uncertain for user " .. userId)
end

local function runBeforeRelease(player: Player)
    for _, handler in beforeReleaseHandlers do
        local ok, errorMessage = pcall(handler, player)
        if not ok then warn("[Steal Anything] Pre-release settlement failed: " .. tostring(errorMessage)) end
    end
end

local function releasePlayerOnce(player: Player)
    local userId = player.UserId
    if releasingPlayers[userId] == "Done" then return end
    if releasingPlayers[userId] == "Running" then
        while releasingPlayers[userId] == "Running" do task.wait(0.05) end
        return
    end
    releasingPlayers[userId] = "Running"
    local startedAt = os.clock()
    runBeforeRelease(player)
    releaseWithRetries(userId, player)
    releasingPlayers[userId] = "Done"
    if RunService:IsStudio() then
        print("[Steal Anything] Profile release took "
            .. string.format("%.1f", os.clock() - startedAt) .. "s")
    end
end

local function loadPlayer(player: Player)
    if game:GetAttribute("MatchmakingEnabled") then
        while player.Parent == Players and player:GetAttribute("MatchAdmission") ~= "Accepted"
            and player:GetAttribute("MatchAdmission") ~= "Denied" do
            task.wait(0.1)
        end
        if not MatchRules.CanLoadProfile(true, player:GetAttribute("MatchAdmission")) then return end
    end
    if releasingPlayers[player.UserId] == "Done" then
        releasingPlayers[player.UserId] = nil
    end
    if loadingPlayers[player.UserId] then
        return
    end
    loadingPlayers[player.UserId] = true
    setState(player, "Loading")
    if repository == nil then
        setState(player, "ConfigurationError")
        loadingPlayers[player.UserId] = nil
        return
    end

    for attempt = 1, #RETRY_DELAYS + 1 do
        if player.Parent ~= Players then
            break
        end
        local _, status = repository:Load(player.UserId)
        if status == "Ready" then
            if player.Parent == Players then
                syncPublicProfile(player)
                setState(player, "Ready")
                task.spawn(function()
                    task.wait(AUTOSAVE_SECONDS + player.UserId % 13)
                    while player.Parent == Players and started do
                        if repository ~= nil then
                            local writeState = repository:GetWriteState(player.UserId)
                            if writeState == "Dirty" or writeState == "SaveError" then
                                saveWithRetries(player.UserId, player)
                            end
                        end
                        task.wait(AUTOSAVE_SECONDS)
                    end
                end)
            else
                releaseWithRetries(player.UserId, player)
            end
            loadingPlayers[player.UserId] = nil
            return
        end
        if status == "CorruptProfile" or status == "CorruptLease" then
            setState(player, "DataError")
            break
        end
        if status == "AlreadyLoaded" then
            setState(player, "SessionConflict")
            break
        end
        setState(player, if status == "Locked" then "WaitingForSession" else "RetryableError")
        if attempt <= #RETRY_DELAYS then
            task.wait(RETRY_DELAYS[attempt])
        end
    end
    loadingPlayers[player.UserId] = nil
end

function ProfileService.GetSnapshot(player: Player): any?
    if repository == nil or player:GetAttribute("ProfileState") ~= "Ready" then
        return nil
    end
    return repository:GetSnapshot(player.UserId)
end

function ProfileService.NewOperationId(player: Player): string?
    if repository == nil or player:GetAttribute("ProfileState") ~= "Ready" then return nil end
    return repository:NewOperationId(player.UserId)
end

function ProfileService.ApplyOperation(player: Player, operationId: string, kind: string,
    requestScope: string, mutate: (any) -> (string, string)): (any?, string)
    if repository == nil or player.Parent ~= Players then return nil, "NotLoaded" end
    local state = player:GetAttribute("ProfileState")
    if state ~= "Ready" and state ~= "SaveError" then return nil, "NotReady" end
    local result, status = repository:ApplyOperation(player.UserId, operationId, kind, requestScope, mutate)
    if result ~= nil and (repository:GetWriteState(player.UserId) == "Saved"
        or repository:GetWriteState(player.UserId) == "Dirty") then
        syncPublicProfile(player)
        setState(player, "Ready")
    elseif status == "RetryableError" or status == "SaveError" or status == "Lost"
        or status == "Conflict" or status == "CorruptProfile" then
        setWriteFailure(player, status)
    end
    return result, status
end

function ProfileService.StageRoutine(player: Player, mutate: (any) -> ()): (boolean, string)
    if repository == nil or player.Parent ~= Players
        or player:GetAttribute("ProfileState") ~= "Ready" then
        return false, "NotReady"
    end
    local staged, status = repository:StageRoutine(player.UserId, mutate)
    if staged then
        syncPublicProfile(player)
    end
    return staged, status
end

function ProfileService.RegisterBeforeRelease(handler: (Player) -> ())
    table.insert(beforeReleaseHandlers, handler)
end

function ProfileService.Start()
    if started then
        return
    end
    started = true
    local network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
    collectionChanged = network:WaitForChild("CollectionChanged") :: RemoteEvent
    local getCollection = network:WaitForChild("GetCollectionState") :: RemoteFunction
    getCollection.OnServerInvoke = function(player: Player): any?
        if repository == nil or player:GetAttribute("ProfileState") ~= "Ready" then
            return nil
        end
        local profile = repository:GetSnapshot(player.UserId)
        return if profile ~= nil then collectionPayload(profile) else nil
    end
    if safeEnvironment() then
        local ok, store = pcall(function()
            return DataStoreService:GetDataStore(Environment.StoreName)
        end)
        if ok then
            repository = RepositoryModule.New(store, os.time, function(): string
                return HttpService:GenerateGUID(false)
            end)
        else
            warn("[Steal Anything] Could not open the configured data store")
        end
    else
        warn("[Steal Anything] Profile environment does not match this runtime")
    end

    Players.PlayerAdded:Connect(function(player)
        task.spawn(loadPlayer, player)
    end)
    Players.PlayerRemoving:Connect(function(player)
        collectionCache[player.UserId] = nil
        releasePlayerOnce(player)
    end)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(loadPlayer, player)
    end

    task.spawn(function()
        while started do
            task.wait(LEASE_REFRESH_SECONDS)
            if repository ~= nil then
                for _, player in ipairs(Players:GetPlayers()) do
                    local state = player:GetAttribute("ProfileState")
                    if state == "Ready" or state == "RetryableError" or state == "SaveError" then
                        task.spawn(function()
                            local ok, reason = repository:Refresh(player.UserId)
                            if ok then
                                if repository:GetWriteState(player.UserId) ~= "SaveError" then
                                    setState(player, "Ready")
                                end
                            elseif reason == "Lost" then
                                setState(player, "SessionConflict")
                            elseif reason ~= "PendingWrite" and reason ~= "NotLoaded" then
                                setWriteFailure(player, reason)
                            end
                        end)
                    end
                end
            end
        end
    end)

    game:BindToClose(function()
        started = false
        local remaining = 0
        for _, player in ipairs(Players:GetPlayers()) do
            remaining += 1
            task.spawn(function()
                releasePlayerOnce(player)
                remaining -= 1
            end)
        end
        local deadline = os.clock() + 20
        while os.clock() < deadline do
            local releasing = false
            for _, state in releasingPlayers do
                if state == "Running" then releasing = true; break end
            end
            if remaining == 0 and not releasing then break end
            task.wait(0.1)
        end
    end)
end

return table.freeze(ProfileService)
