-- Paste this whole file into Studio's command bar in Edit mode after Rojo sync.
-- Use when the Rojo-staged files are current but the existing script bodies are not.
local staged = game.ServerStorage.Assets:FindFirstChild("SourceSync_v1")
local client = game.StarterPlayer.StarterPlayerScripts:FindFirstChild("Client")
assert(staged and client, "Rojo has not staged SourceSync_v1 and Client yet")
local stagedHud = staged:FindFirstChild("TravelOfferHud")
local stagedEmotes = staged:FindFirstChild("MenuEmoteConfig")
assert(stagedHud and stagedHud.Source:find("ReopenTravelOffer", 1, true),
    "Rojo has not staged the new travel HUD yet")
assert(stagedEmotes and stagedEmotes.Source:find("507770239", 1, true),
    "Rojo has not staged the emote IDs yet")

for _, name in { "TravelOfferHud", "MenuEmoteConfig", "OperationsMenu" } do
    local source = staged:FindFirstChild(name)
    local target = client:FindFirstChild(name)
    assert(source and target, "Missing staged or live script: " .. name)
    target.Source = source.Source
    assert(target.Source == source.Source, "Source did not update: " .. name)
    print("[travel/emotes]", name, "UPDATED")
end
