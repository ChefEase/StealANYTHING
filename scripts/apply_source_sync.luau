-- Run in Studio's Edit command bar after Rojo has staged SourceSync_v1.
-- This refreshes existing scripts that Rojo left with older source.
local stagedFolder = game.ServerStorage.Assets:WaitForChild("SourceSync_v1", 5)
local services = game.ServerScriptService.Server.Services
local client = game.StarterPlayer.StarterPlayerScripts.Client
assert(stagedFolder, "Rojo has not staged SourceSync_v1 yet")
local stagedMenu = stagedFolder:FindFirstChild("OperationsMenu")
local stagedGrass = stagedFolder:FindFirstChild("DistrictGrassFill")
local stagedPlot = stagedFolder:FindFirstChild("PlotService")
local stagedProfile = stagedFolder:FindFirstChild("ProfileService")
assert(stagedMenu and stagedMenu.Source:find("overlay.Visible and tutorialPane.Visible", 1, true),
	"Rojo has not staged the visible menu emotes yet")
assert(stagedGrass and stagedGrass.Source:find("local STEP = 88", 1, true),
	"Rojo has not staged the new grass scenery yet")
assert(stagedPlot and stagedPlot.Source:find("MuseumReturnPad", 1, true)
    and stagedPlot.Source:find("MatchActive", 1, true),
	"Rojo has not staged the updated PlotService yet")
assert(stagedProfile and stagedProfile.Source:find("releasePlayerOnce", 1, true)
    and stagedProfile.Source:find("MatchAdmission", 1, true),
	"Rojo has not staged the stop-play profile fix yet")

local targets = {
	{ name = "PlotService", parent = services },
	{ name = "DistrictGrassFill", parent = services },
	{ name = "ProfileService", parent = services },
	{ name = "PlotProtection", parent = services },
	{ name = "MuseumDoors", parent = services },
	{ name = "TravelEffects", parent = services },
	{ name = "TravelService", parent = services },
	{ name = "InteractionHud", parent = client },
	{ name = "OperationsMenu", parent = client },
	{ name = "TravelOfferHud", parent = client },
	{ name = "MenuEmoteConfig", parent = client },
}

for _, entry in ipairs(targets) do
	local name = entry.name
	local target = entry.parent:FindFirstChild(name)
	local staged = stagedFolder and stagedFolder:FindFirstChild(name)
	if not staged then
		warn("[sync] staged copy missing: " .. name)
	elseif not target then
		local copy = staged:Clone()
		copy.Parent = entry.parent
		print("[sync]", name, "CREATED")
	else
		local wanted = staged.Source
		local changed = target.Source ~= wanted
		local ok, err = pcall(function()
			if changed then
				target.Source = wanted
			end
		end)
		if ok and target.Source == wanted then
			print("[sync]", name, if changed then "UPDATED" else "CURRENT")
		else
			warn("[sync]", name, "FAILED", if ok then "source did not match" else tostring(err))
		end
	end
end
