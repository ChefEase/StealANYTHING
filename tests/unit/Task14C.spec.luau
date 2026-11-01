-- Run in Studio Edit after Rojo sync. No persistent profile writes.
local Server=game.ServerScriptService.Server
local Defaults=require(Server.Data.ProfileDefaults)
local Schema=require(Server.Data.ProfileSchema)
local Rules=require(Server.Domain.ExhibitArrangementRules)
local Income=require(Server.Domain.IncomeMath)
local Public=require(Server.Domain.PublicDeliveryRules)
local Tutorial=require(Server.Domain.TutorialDeliveryRules)

local serial=0
local profile=Defaults.Create(1000,function() serial+=1;return "contract-"..serial end)
assert(Tutorial.Apply(profile,1000)=="Committed")
assert(profile.displaySlots.protected=="toaster" and Income.RatePerMinute(profile)==6)
assert(Rules.Apply(profile,"AutoBest")=="Rejected","first-income lock stays intact")
profile.tutorialStep=2
for i,id in {"duck","traffic_cone","disco_bin","gold_toilet"} do
    assert(Public.Apply(profile,id,1000+i)=="Committed")
end
assert(profile.exhibits.gold_toilet and profile.displaySlots.exposed_01~= "gold_toilet"
    and profile.displaySlots.exposed_02~= "gold_toilet","full stands store later items")
assert(Rules.Apply(profile,"AutoBest")=="Committed")
assert(profile.displaySlots.exposed_01=="gold_toilet"
    and profile.displaySlots.exposed_02=="disco_bin"
    and profile.displaySlots.protected=="traffic_cone")
assert(Income.RatePerMinute(profile)==52,"public 26+18 and protected 16/2")
assert(Rules.StorageCount(profile)==2 and Schema.Validate(profile),"displaced items remain safe")
assert(Rules.Apply(profile,"AutoBest")=="Rejected","repeat is idempotent")
assert(Rules.Apply(profile,"Place","duck","exposed_01")=="Committed")
assert(profile.publicDisplayMode=="Manual" and profile.displaySlots.exposed_01=="duck")
assert(Rules.Apply(profile,"AutoBest")=="Committed")
assert(profile.publicDisplayMode=="Auto" and profile.displaySlots.exposed_01=="gold_toilet")
assert(Rules.Apply(profile,"Place","unknown","exposed_01")=="Rejected")
assert(Rules.Apply(profile,"Place","duck","bad_slot")=="Rejected")
assert(Schema.Validate(profile))
return "Task14C auto equip, tutorial protection, storage, income, manual override PASS"
