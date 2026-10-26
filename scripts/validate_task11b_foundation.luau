-- Studio Edit, after Rojo sync and building Task 11 templates.
local Shared = game.ReplicatedStorage.Shared
local Plots = require(Shared.PlotDefinitions)
local Items = require(Shared.ItemCatalog)
local TierOne = require(Shared.Task11TierOneContract)
local pack = assert(game.ServerStorage.Assets:FindFirstChild("Task11MapTemplates"))
local museum = assert(pack:FindFirstChild("StarterMuseumTemplate"))

local seenItems = {}
for _, id in Items.OrderedIds do
    assert(not seenItems[id] and Items.ById[id] and Items.ById[id].id == id)
    seenItems[id] = true
end
assert(#Items.OrderedIds == 12)
local seenPlots = {}
for _, slot in Plots.Slots do
    assert(not seenPlots[slot.id] and slot.center and slot.yawDegrees)
    seenPlots[slot.id] = true
    assert(pack.SixPlotWorldTemplate.PlotSlots:FindFirstChild(slot.id))
end
assert(#Plots.Slots == 6 and #Plots.Tiers == 5)
for i, tier in Plots.Tiers do
    assert(tier.tier == i and tier.standCount > (if i == 1 then 0 else Plots.Tiers[i - 1].standCount))
    assert(tier.groundsStuds <= Plots.MaximumEnvelopeStuds)
end

local contract = TierOne.Contract
assert(TierOne.Validate(contract))
assert(museum:GetAttribute("TemplateVersion") == contract.defaults.version)
assert(museum:GetAttribute("Tier") == contract.defaults.tier)
assert(museum:GetAttribute("StandCount") == #contract.socketIds)
for _, id in contract.socketIds do
    local socket = assert(museum:FindFirstChild(contract.socketNamesById[id]))
    assert(socket:GetAttribute("AnchorId") == id)
    assert(socket:GetAttribute("SocketId") == "template." .. id)
    assert(game:GetService("CollectionService"):HasTag(socket, "MapSocket"))
end
local invalid = {
    defaults = contract.defaults,
    socketIds = { "protected", "exposed_01", "exposed_01" },
    socketNamesById = contract.socketNamesById,
}
assert(not TierOne.Validate(invalid), "duplicate socket ID was accepted")
invalid.socketIds = { "protected", "exposed_01", "invented" }
assert(not TierOne.Validate(invalid), "unknown socket ID was accepted")
invalid.socketIds = contract.socketIds
invalid.defaults = { version = 1, tier = 2, styleId = "starter",
    groundsPresetId = contract.defaults.groundsPresetId, securityLevel = 0 }
assert(not TierOne.Validate(invalid), "invalid tier-one default was accepted")

return { items = #Items.OrderedIds, plots = #Plots.Slots, tiers = #Plots.Tiers,
    tierOneSockets = #contract.socketIds, invalidDefinitionsRejected = true }
