--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.Shared.WardrobeCatalog)
local Appearance = require(ReplicatedStorage.Shared.WardrobeAppearance)
local Store = require(script.Parent.WardrobeStore)

local WardrobeSession = {}
local sessions: {[number]: any} = {}
local busy: {[number]: boolean} = {}
local lastAction: {[number]: number} = {}
local refreshing: {[number]: boolean} = {}
local started = false
local actionRemote: RemoteEvent
local stateRemote: RemoteEvent
local purchase: ((Player, string) -> (boolean, string))? = nil
local profileOwned: ((Player) -> {[string]: boolean}?)? = nil

local function remote(name: string): RemoteEvent
    local existing = ReplicatedStorage:FindFirstChild(name)
    if existing and existing:IsA("RemoteEvent") then return existing end
    local created = Instance.new("RemoteEvent")
    created.Name = name
    created.Parent = ReplicatedStorage
    return created
end

local function show(player: Player, message: string?, open: boolean?)
    local record = sessions[player.UserId]
    if player.Parent == Players then
        stateRemote:FireClient(player, {
            ready = record ~= nil,
            canBuy = purchase ~= nil,
            owned = if record then record.owned else {},
            loadout = if record then record.loadout else {},
            message = message,
            open = open == true,
        })
    end
end

local function apply(player: Player)
    local character = player.Character
    if character == nil or character.Parent == nil then return end
    local record = sessions[player.UserId]
    if record then Appearance.Apply(character, record.loadout) end
end

local function refresh(player: Player): boolean
    if refreshing[player.UserId] then
        while refreshing[player.UserId] and player.Parent == Players do task.wait(0.05) end
        show(player)
        return sessions[player.UserId] ~= nil
    end
    refreshing[player.UserId] = true
    local owned = profileOwned and profileOwned(player)
    local record, err
    if owned ~= nil then
        record, err = Store.SyncOwned(player.UserId, owned)
    else
        record, err = Store.Read(player.UserId)
    end
    if record == nil then
        refreshing[player.UserId] = nil
        show(player, "Wardrobe data unavailable: " .. tostring(err))
        return false
    end
    sessions[player.UserId] = record
    refreshing[player.UserId] = nil
    apply(player)
    show(player)
    return true
end

function WardrobeSession.Open(player: Player)
    if player.Parent ~= Players then return end
    if sessions[player.UserId] == nil then refresh(player) end
    show(player, nil, true)
end

local function handle(player: Player, action: any, itemId: any)
    if type(action) ~= "string" or player.Parent ~= Players then return end
    local now = os.clock()
    if busy[player.UserId] then
        show(player, "Wardrobe is updating. Try again in a moment.")
        return
    end
    if now - (lastAction[player.UserId] or -10) < 0.2 then return end
    lastAction[player.UserId] = now
    busy[player.UserId] = true
    if action == "State" then
        if sessions[player.UserId] then show(player) else refresh(player) end
    elseif action == "Buy" and type(itemId) == "string" then
        local item = Catalog.ById[itemId]
        if item == nil or item.currency ~= "Cash" or item.price <= 0 or purchase == nil then
            show(player, "This item is unavailable here.")
        else
            local success, message = purchase(player, itemId)
            if success then
                refresh(player)
            end
            show(player, message)
        end
    elseif action == "Restore" and sessions[player.UserId] then
        local record, err = Store.Restore(player.UserId)
        if record then
            sessions[player.UserId] = record
            apply(player)
            show(player, "Original Roblox avatar restored.")
        else
            show(player, "Could not restore: " .. tostring(err))
        end
    elseif action == "Equip" or action == "Remove" then
        local item = if action == "Equip" and type(itemId) == "string"
            then Catalog.ById[itemId] else nil
        local slot = if action == "Equip" and item then item.slot
            elseif action == "Remove" and type(itemId) == "string" then itemId else nil
        if slot and Catalog.Slots[slot] and sessions[player.UserId] then
            local record, err = Store.Equip(player.UserId, slot,
                if action == "Equip" then itemId else nil)
            if record then
                sessions[player.UserId] = record
                apply(player)
                show(player, "Look updated.")
            else
                show(player, "Could not equip: " .. tostring(err))
            end
        end
    end
    busy[player.UserId] = nil
end

function WardrobeSession.Start(options: any?)
    if started then return end
    started = true
    purchase = options and options.purchase or nil
    profileOwned = options and options.profileOwned or nil
    actionRemote = remote("WardrobeAction")
    stateRemote = remote("WardrobeState")
    actionRemote.OnServerEvent:Connect(handle)
    local function playerAdded(player: Player)
        player.CharacterAppearanceLoaded:Connect(function()
            task.defer(apply, player)
        end)
        player.CharacterAdded:Connect(function()
            task.delay(1, apply, player)
        end)
        if profileOwned ~= nil then
            player:GetAttributeChangedSignal("ProfileState"):Connect(function()
                if player:GetAttribute("ProfileState") == "Ready" then
                    task.spawn(refresh, player)
                end
            end)
        end
        task.spawn(refresh, player)
    end
    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(function(player)
        sessions[player.UserId] = nil
        busy[player.UserId] = nil
        lastAction[player.UserId] = nil
        refreshing[player.UserId] = nil
    end)
    for _, player in Players:GetPlayers() do playerAdded(player) end
end

return table.freeze(WardrobeSession)
