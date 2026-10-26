-- Paste into Studio's Edit command bar after Rojo stages SourceSync_v1.
local staged = game.ServerStorage.Assets.SourceSync_v1:FindFirstChild("PlotService")
local live = game.ServerScriptService.Server.Services:FindFirstChild("PlotService")
assert(staged and staged.Source:find("MuseumReturnPad", 1, true)
    and staged.Source:find("MatchActive", 1, true),
    "Rojo has not staged the museum return pad yet")
assert(live, "Live PlotService is missing")
live.Source = staged.Source
assert(live.Source == staged.Source, "PlotService source did not update")
print("[sync] Museum return pad applied to PlotService")
