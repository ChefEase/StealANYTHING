--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Balance = require(ReplicatedStorage.Shared.BalanceConfig)
local Catalog = require(ReplicatedStorage.Shared.ItemCatalog)
local ItemVisuals = require(ReplicatedStorage.Shared.ItemVisuals)
local DepotStockCard = require(script.Parent.DepotStockCard)
local PublicStockState = require(script.Parent.PublicStockState)

local IDS = { "depot.public_01", "depot.public_02", "depot.public_03" }
local PublicStockService = {}
assert(#IDS == Balance.PUBLIC_DEPOT_PEDESTALS)
local started = false
local stock: any = nil
local prompts: {[string]: ProximityPrompt} = {}
local displays: {[string]: Model} = {}
local cards: {[string]: any} = {}
local runtime: Folder? = nil

local function chooseWeighted(exclude: string?): string
    local total = 0
    for _, id in Catalog.OrderedIds do
        if id ~= exclude then total += Catalog.ById[id].depotWeight end
    end
    local roll = math.random() * total
    for _, id in Catalog.OrderedIds do
        if id ~= exclude then
            roll -= Catalog.ById[id].depotWeight
            if roll <= 0 then return id end
        end
    end
    for _, id in Catalog.OrderedIds do
        if id ~= exclude then return id end
    end
    error("Public depot has no eligible stock")
end

local function render(id: string)
    if stock == nil then return end
    local pedestal = stock:Get(id)
    local prompt = prompts[id]
    local card = cards[id]
    if pedestal == nil or prompt == nil or card == nil or runtime == nil then return end
    local itemId = pedestal.itemId
    local definition = itemId and Catalog.ById[itemId]
    prompt.Enabled = definition ~= nil
    prompt:SetAttribute("StockItemId", itemId or "")
    local display = displays[id]
    if display ~= nil and display:GetAttribute("StockItemId") ~= itemId then
        display:Destroy()
        displays[id] = nil
        display = nil
    end
    if definition ~= nil and display == nil then
        local height = ItemVisuals.Height(itemId)
        local displayScale = if definition.sizeClass == "Small" then 1.5
            elseif definition.sizeClass == "Medium" then 1.2 else 1
        display = ItemVisuals.Create(itemId, "PublicStockDisplay_" .. id,
            (prompt.Parent :: BasePart).CFrame
                * CFrame.new(0, height * displayScale / 2 - 0.25, 3),
            true, displayScale)
        display:SetAttribute("StockItemId", itemId)
        display.Parent = runtime
        displays[id] = display
    end
    if definition then
        local remaining = math.max(0, math.ceil(pedestal.rotateAt - os.clock()))
        prompt.ObjectText = definition.name
        -- Place the information beside the stock. A centered billboard hides
        -- small models even when raised above their pedestal.
        card.gui.StudsOffsetWorldSpace = Vector3.new(9, 7.2, 0)
        DepotStockCard.ShowItem(card, definition, definition.baseIncomePerMinute,
            "ROTATES IN " .. tostring(remaining) .. "S  /  DISPLAY INCOME")
    else
        local remaining = math.max(0, math.ceil(pedestal.restockAt - os.clock()))
        card.gui.StudsOffsetWorldSpace = Vector3.new(9, 7.2, 0)
        DepotStockCard.ShowRestock(card, remaining)
    end
end

function PublicStockService.Start()
    if started then return end
    started = true
    local map = workspace:FindFirstChild("Map")
    local district = map and map:FindFirstChild("ExpansionDistrict")
    local depot = district and district:FindFirstChild("Depot")
    if depot == nil then
        warn("[Steal Anything] Public depot is missing")
        return
    end
    local sockets: {[string]: BasePart} = {}
    for index, id in IDS do
        local socket = depot:FindFirstChild("Public0" .. index .. "PedestalSocket")
        if socket == nil or not socket:IsA("BasePart")
            or socket:GetAttribute("SocketId") ~= id then
            warn("[Steal Anything] Public stock socket missing: " .. id)
            return
        end
        sockets[id] = socket
    end
    stock = PublicStockState.New(os.clock, chooseWeighted, IDS)
    runtime = Instance.new("Folder")
    runtime.Name = "PublicStockRuntime"
    runtime.Parent = depot
    for _, id in IDS do
        local socket = sockets[id]
        local anchor = Instance.new("Part")
        anchor.Name = "PublicPickupTarget"
        anchor.Size = Vector3.new(0.5, 0.5, 0.5)
        anchor.CFrame = socket.CFrame * CFrame.new(0, 0, -3)
        anchor.Transparency = 1
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor:SetAttribute("PickupTargetId", id)
        anchor.Parent = runtime
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "PublicPickupPrompt"
        prompt.ActionText = "Steal stock"
        prompt.HoldDuration = Balance.PICKUP_HOLD_SECONDS
        prompt.MaxActivationDistance = Balance.PICKUP_DISTANCE_STUDS
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
        prompt.RequiresLineOfSight = true
        prompt.Style = Enum.ProximityPromptStyle.Custom
        prompt:SetAttribute("PickupTargetId", id)
        prompt.Parent = anchor
        prompts[id] = prompt
        cards[id] = DepotStockCard.Create(socket, "PUBLIC DEPOT")
        render(id)
    end
    task.spawn(function()
        while started do
            stock:Tick()
            for _, id in IDS do render(id) end
            task.wait(1)
        end
    end)
end

function PublicStockService.GetPrompt(id: string): ProximityPrompt?
    return prompts[id]
end

function PublicStockService.GetAnchor(id: string): BasePart?
    local prompt = prompts[id]
    return prompt and prompt.Parent :: BasePart?
end

function PublicStockService.GetDisplay(id: string): Model?
    return displays[id]
end

function PublicStockService.GetItemId(id: string): string?
    local pedestal = stock and stock:Get(id)
    return pedestal and pedestal.itemId or nil
end

function PublicStockService.Begin(id: string, userId: number, requestId: string): (boolean, string)
    if stock == nil then return false, "Unavailable" end
    return stock:Begin(id, userId, requestId)
end

function PublicStockService.Cancel(id: string, userId: number, requestId: string)
    if stock ~= nil then stock:Cancel(id, userId, requestId) end
end

function PublicStockService.Claim(id: string, userId: number, requestId: string,
    runId: string): (string?, string)
    if stock == nil then return nil, "Unavailable" end
    local itemId, status = stock:Claim(id, userId, requestId, runId)
    render(id)
    return itemId, status
end

function PublicStockService.Finish(runId: string)
    if stock ~= nil then stock:Finish(runId) end
end

function PublicStockService.Fail(runId: string)
    if stock ~= nil then stock:Fail(runId) end
end

return table.freeze(PublicStockService)
