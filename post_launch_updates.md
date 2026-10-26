# Steal Anything! — Post-Launch Updates

**Start here only after the first public launch and the Task 40 decision.** The launch requirements, numbered Tasks 1–40, and added Tasks 11b and 12a remain in [development plan.md](development%20plan.md). This file is the working checklist for updates after launch. Complete one update at a time, record its results, and change the order only when player evidence justifies it. The core Robber Wardrobe and launch catalog belong to Task 12a; the additions below follow launch.

**Post-Task-12 scope reminder:** The 20 October robbery/defense decisions are specified for development Tasks 23–30, not immediate Task 12 work. Existing launch theft uses server-authorized open windows, allows an eligible owner to be home and defend, protects offline and beginner players, and preserves permanent collectible registration. Expanded lockdown/trap/rematch ideas are conditional Update 12, not launch commitments.

**First post-launch priority:** Validate that the existing heist loop gives a satisfying first delivery and a worthwhile next robbery. Keep daily jobs, deeper referrals, museum challenges, and cosmetic milestones at their listed update stages. If first-session evidence is weak, improve pickup/escape feedback, delivery presentation, visible early purchases, route guidance, or the next-goal prompt before adding a new reward system. The Heist Momentum Controller remains optional guidance for NPC runs; it must not personalize rarity, prices, payouts, or PvP outcomes.

## Before the first update

- [ ] Record a baseline: time to first pickup, escape, committed delivery, and visible improvement; first-heist completion among successfully loaded new players; second-heist starts and voluntary replays; consecutive NPC failures and guidance use; D1/D7 returns; ordinary friend raids; rare-stock waiting; save failures; and phone/server performance. Keep event definitions, cohort dates, acquisition sources, and device mix with the results. Use actual cohorts rather than a guessed success threshold.
- [ ] Review the first-session funnel before planning the next update. Compare the limited-test baseline with public cohorts where the event definitions match. Check whether the first reward visibly changes the museum, shows true income and set/contract progress, and leads players to an achievable next run. Prioritize observed blockers and retest the same measures; small cohorts guide usability fixes but cannot prove a retention lift.
- [ ] Review short first-play exits, return days, playtime per user, and Home recommendation play-through when platform reporting provides them. Relate changes to the first-delivery and next-heist funnel without assuming a guaranteed recommendation boost.
- [ ] Keep the latest stable published place and migration/rollback procedure. Test new profile fields with old saved profiles and uncertain-write retries before enabling a feature for everyone.
- [ ] Keep the six-player museum, protected collection rights, raid counterplay, and earned-cash economy working when a new feature flag is off.
- [ ] Decide each update's exact objects, costs, reward limits, eligibility, and asset rights before implementation. Do not treat the examples below as shipped balances or licensed assets.

## Update 1 — Friend arrival and first referral reward

**Reason to build:** Ordinary friend theft and defense are enjoyable in observed play. The launch invite entry point already works.

1. [ ] Confirm the experience is eligible for [Roblox's friend referral system](https://create.roblox.com/docs/production/promotion/referral-system); the documented feature requires the experience to have been live for at least one day. Configure the reward banner and use the existing invite prompt. Do not award anything for pressing Invite.
2. [ ] On the server, read `Player:GetJoinData().ReferredByPlayerId` and persist one inviter/invitee relationship for each distinct eligible referred player. Reject self-referrals and repeat credit. Qualify the referral when that player finishes their first valid heist; specify whether an NPC heist qualifies before coding. Count at most **four distinct qualifying friends per inviter** toward referral rewards. A fifth qualification gives no additional referral reward.
3. [ ] Grant matching **Partners in Crime** museum plaques to inviter and invitee at one qualified friend. Make offline grants and retries durable and idempotent. No income, theft-power, or defense advantage.
4. [ ] Test new join, first-heist qualification, invited player leaving mid-run, inviter offline, simultaneous servers, duplicate join data, self-referral, and rejoin. Measure referred players who finish a heist and later return, not invite clicks.

**Done when:** Both eligible players receive exactly one cosmetic grant and unqualified invitations receive none.

## Update 2 — Museum Challenge

**Reason to build:** Friends want a direct shared activity after ordinary raids work well.

1. [ ] Let a museum owner select one eligible displayed object and invite a friend to a short practice challenge. The friend accepts; the server creates a clearly marked **replica** with its own challenge state and timer.
2. [ ] Reuse carrying, defense, delivery, and museum routes where valid. Show escape time or successful defense, then offer a role swap. Never change permanent registration, display ownership, Missing state, or ordinary raid rewards.
3. [ ] Save personal-best escape/defense records and small capped cosmetic milestones. Give no repeatable cash; limit repeat-friend milestone farming.
4. [ ] Test both roles, cancel, death, disconnect, timeout, simultaneous ordinary raids, replica cleanup, rejoin, and six-player visibility/performance.

**Done when:** Both friends can complete and swap a challenge without collection loss or repeatable-cash farming.

## Update 3 — Return goals and referral depth

**Reason to build:** Players are returning because they enjoy another run; cosmetic goals add structure rather than pressure.

**Entry check:** First-delivery and second-heist evidence shows that the base loop works well enough to support daily goals. If it does not, improve the existing loop and repeat the before/after check before enabling daily jobs or visit tracks.

1. [ ] Add one daily job for an ordinary heist with a small published fixed bonus. Define the reset time and qualifying server event. A repeated event cannot claim twice.
2. [ ] Add a seven-qualifying-visit cosmetic track that advances at most once per day and **pauses** after missed days instead of resetting. Display current progress and the next reward.
3. [ ] After Update 1's abuse checks hold, grant **delivery confetti** at three distinct qualified referrals and a decorative **crew statue** at four. Four distinct qualifying friends is the lifetime reward cap per inviter. Count distinct eligible players, not messages, button clicks, or friends online at once. Persist each grant once.
4. [ ] Consider a later weekly themed objective, such as successfully delivering each carry behavior, only if observed return play supports it. Test day-boundary, missed-day, duplicate-event, offline-grant, and rejoin cases.

**Done when:** Exact qualification rules are visible and missing a day does not erase earned visits or cosmetics.

## Update 4 — Guaranteed rare acquisition, if testing calls for it

**Trigger:** Limited/public tests show that waiting for selected rare depot stock causes unproductive sessions. Skip or delay this update if that problem is not observed.

1. [ ] Choose one rare target, for example `mini_ufo`, and publish the exact saved contract goal and reward: either that collectible or a deterministic earned-cash purchase unlock.
2. [ ] Advance the contract on each eligible confirmed NPC delivery, using the existing durable operation ID. Keep progress across leave/rejoin; duplicate deliveries and claims add nothing.
3. [ ] Keep ordinary uncertain depot appearances as a possible faster path. If the player finds the item first, resolve the contract without a second permanent entitlement and show the new outcome clearly.
4. [ ] Tune required effort from observed delivery time, stock waits, and player feedback. Do not add paid spins, fake near misses, expiring progress, or another currency.

**Done when:** A player can predict and complete the guaranteed path, and ordinary depot discovery still feels useful.

## Update 5 — Categories and expensive direct purchases

**Reason to build:** A larger catalog needs clearer browsing and a costly alternative to search.

1. [ ] Define stable category IDs and migrate existing 12 items without changing their IDs, prices, ownership, or carry behavior. Show categories in the catalog and sets.
2. [ ] For selected harder-to-find objects, price a direct purchase in **earned cash**. Make it deliberately much higher than ordinary shop items, but base the amount on measured time and difficulty to acquire through depot play or contracts. Publish the exact price and earning estimate before purchase.
3. [ ] Validate eligibility, funds, duplicate rights, and one-time grant on the server. Keep search and any guaranteed contract viable; avoid making a required set depend on an impractical price or an unreasonably rare spawn.
4. [ ] Test repeated purchase requests, failure/rejoin, affordability, new-player comprehension, and the effect on depot participation. Do not alter the current `ItemCatalog` balance until this update is approved.

**Done when:** Players can choose search or a known high earned-cash price without a duplicate entitlement or hidden cost.

## Update 6 — Museum-named collection releases

**Reason to build:** Players have exhausted the original catalog and want a new set of objects to pursue.

1. [ ] Select an actual museum as the update name and verify each modeled collectible against that museum's primary collection record. Candidate sequence: **The British Museum** — [Rosetta Stone](https://www.britishmuseum.org/collection/object/Y_EA24); **The Metropolitan Museum of Art** — [Temple of Dendur](https://www.metmuseum.org/art/collection/search/547802); **Musée du Louvre** — [Winged Victory of Samothrace](https://collections.louvre.fr/ark:/53355/cl010252531). These are candidate themes, not promised dates, approved models, or museum partnerships.
2. [ ] Choose a practical collectible representation and legal stand footprint for each real piece; a full-sized monument may need an explicitly labeled scale model. Document rights for references, images, textures, and 3D work before publishing. Keep the game's original absurd objects clearly distinct from historical pieces.
3. [ ] Give each item a sourced information card: museum/accession link; object name; creation date or estimated period; discovery date **when known and applicable**; original place of origin; named painter, artisan, sculptor, or maker **when known**; and a short factual description. Label uncertain dates, attribution, and provenance as such. Do not invent facts to fill blanks.
4. [ ] Reuse existing carry behaviors, then add category/set links and earned cosmetic rewards where they create clear goals. Check acquisition difficulty before assigning any direct-purchase price.
5. [ ] Test registration, permanent rights, Missing/recovery, display bounds, mobile readability, multi-client replication, content sourcing, and asset load failures. Release one museum theme at a time and compare return behavior with the baseline.

**Done when:** Every shipped object has a verified source and usable in-game model, and the museum name does not imply endorsement.

## Update 7 — Reusable session variety

**Reason to build:** Observed runs have become predictable and friends request more shared goals.

1. [ ] Rotate guard patrols, pickup positions, or available cover only where each variant changes a meaningful player decision. Preserve two viable routes and earned counterplay for all six plots; test every variant with carrying and raids.
2. [ ] Add cooperative depot jobs with server-validated participation and **individual rewards** so a friend cannot take another player's payout. Test disconnects and duplicate claims.
3. [ ] Add themed deliveries with a distinctive object pool, clear recurring objectives, and saved progress where promised. Avoid a content cadence that cannot be maintained.
4. [ ] Award earned façade, display-style, and museum-sign milestones. Rebuild/rejoin every museum tier and check that visuals do not block stands, entrances, or routes.
5. [ ] Profile phone memory, six-plot replication, server timing, abuse limits, voluntary next runs, and return behavior after each release. Keep a rollback path for each variant.

**Done when:** The additions create fresh decisions or shared play without breaking existing navigation, collection rights, or performance.

## Update 8 — Persistent trophy history, only if needed

**Trigger:** Real sessions show that the temporary stolen trophy expiring or a disconnect before trophy creation harms the experience enough to justify a more complex cross-profile transaction. The launch heist scrapbook already preserves the achievement; this update concerns trophy ownership or raid escrow, which is a different feature.

1. [ ] Review the measured problem and design a durable transaction/outbox protocol before promising a persistent trophy. Keep the victim's permanent registration and recovery rights intact.
2. [ ] Specify exactly when owner loss, thief reward, timeout, crash, and reconnect become final. Do not claim cross-profile atomicity that Roblox DataStores do not provide.
3. [ ] Test uncertain writes, two servers, owner/thief disconnects at every commit boundary, repeated receipts/events, and rollback. Keep the feature disabled if any path can duplicate or erase an entitlement.

**Done when:** The documented failure matrix has one safe result per boundary and existing raid/recovery behavior still works with the feature disabled.

## Update 9 — Expand robber cosmetics and achievement looks

**Trigger:** Players use the pre-launch Robber Wardrobe and request more appearance choices. The hybrid avatar system, free starter look, cash catalog, and any approved premium launch offers are already built in Task 12a and Tasks 37–38.

1. [ ] Add more masks, bags, outfits, animated skins, visual effects, robbery victory poses, and exclusive animations in measured batches. Preserve avatar compatibility, readable previews, phone performance, and clear ownership in both places.
2. [ ] Add limited seasonal cosmetics only with exact eligibility, start/end dates, and a clear policy for returning items. Keep permanent purchases permanent and describe any time limit before a player buys.
3. [ ] Add achievement-exclusive looks, such as an outfit for 100 valid robberies with no purchase option. Grant once from server-verified heist milestones, apply repeat-player farming limits, and keep the reward after rejoin.
4. [ ] Recheck earned-cash prices against actual late-game income. Use the existing currency and meaningful earned goals before considering a separate cosmetic currency. Test purchase/equip/rejoin, six-player visibility, and wardrobe use during matchmaking.

**Done when:** New looks add visible progression without losing existing avatar choices, owned items, cash, or queue position.

## Update 10 — Hideout Black Market and collector vault expansion

**Trigger:** Players use the pre-launch hideout stations and request more
customization after Task 12a's launch catalog has reliable fulfillment.
Skip paid expansion if purchase reliability or free-player progression is weak.

1. [ ] Expand direct, clearly priced Robux offers from observed demand: masks,
   carrying-bag skins, display frames, museum signs, heist entrance effects,
   soundtrack/emote packs, and seasonal visual themes. Keep the lobby's Black
   Market Robux-only; earned-cash wardrobe purchases use Task 12a's separate
   wardrobe flow in either place. A permanent offer
   should use an appropriate one-time pass; any repeatable offer needs durable
   [developer-product receipt handling](https://create.roblox.com/docs/production/monetization/developer-products).
2. [ ] Expand `MY LOCKER` from Task 12a's character cosmetics to approved
   equipment and additional owned cosmetics. Persist
   only account entitlements and equipped choices, validate each loadout on the
   destination gameplay server, and allow harmless cosmetic changes without
   losing queue position. Keep gameplay-affecting equipment under the Task 37
   earned-alternative and counterplay rules.
3. [ ] Add an original-art collector vault with a collection index, clear
   rarity descriptions, and directly purchased premium display cosmetics or
   collectibles only after ownership rules are tested. Purchased ownership
   is permanent; a raid can yield only a separately defined gameplay replica
   or ordinary reward. The purchase itself is never erased by theft. Trading
   stays off initially. Do not claim a fixed supply or limited edition until
   issuance limits, reconciliation, and duplicate prevention are proven.
4. [ ] Keep paid randomized artifact crates out of this update. Any later
   proposal must first meet Roblox's [paid random items rules](https://create.roblox.com/docs/production/monetization/paid-random-items),
   including numerical odds and per-user restrictions. Direct purchases are
   the default for the collector vault.
5. [ ] Test lobby purchase to museum equip, session-lock handoff, receipt
   retry, cross-server rejoin, offline ownership, six-player fairness, mobile
   and controller navigation, and monetization-off play. Set exact products
   and prices only after owner approval and real purchase/retention evidence.

**Done when:** Approved entitlements appear exactly once in both places, a
stolen replica cannot erase a paid original, and free players retain viable
earnable progress.

## Update 11 — Crew lounge and hideout live events, if players use the space

**Trigger:** Waiting sessions are long enough for optional social activity to
matter, without delaying the first solo or paired match.

1. [ ] Add small optional lounge interactions such as a jukebox, emote spot,
   noticeboard, or arcade display. Preserve responsive matchmaking and allow
   immediate deployment; no interaction may trap a player in the lobby.
2. [ ] Consider a leaderboard only after selecting a fair, server-verified
   measure such as completed heists or collection milestones. Specify season
   reset, duplicate/farming limits, display privacy, and tie handling before
   building it. Do not rank Robux spending as a gameplay achievement.
3. [ ] Rotate original seasonal vault displays and heist briefings with
   guaranteed item descriptions and tested asset rights. Record whether the
   additions improve voluntary play and return visits before extending them.
4. [ ] Recheck lobby loading, mobile memory, controller focus, teleport
   failure cleanup, and six-player museum performance after every addition.

**Done when:** The hideout is more social for players who choose to explore,
while matchmaking, solo entry, and museum progress still work as before.

## Update 12 — Deeper robberies and defensive counterplay (conditional)

**Trigger:** After launch, raid and recovery data show players enjoy the risk but repeatedly ask for more defensive choices, meaningful rematches, or a fairer way to respond to attackers. Do not add this because a single theft clip looked exciting. The launch baseline already permits raids while an eligible owner is home; home status alone is not a lock.

1. [ ] Evaluate **one** clearly signalled, earned-cash defense at a time: e.g., a temporary manual lockdown with an explicit duration/cooldown **or** a visible slow/stun trap. A lockdown can only begin when no raid is active, or must preserve a server-validated exit for an active thief. Never let it invalidate an already accepted theft by trapping or teleporting the carrier. Compare actual defense success against the existing shove/pad, guards and sensors before enabling another tool.
2. [ ] If regular recovery proves frustrating, improve the existing three-parcel job's clarity, route and progress feedback before adding a new recovery currency, paid shortcut or revenge system. Players retain permanent registration; recovery restores the Missing exhibit once. A successful robber keeps only the explicitly scoped temporary trophy and scrapbook milestone, not the victim's permanent object.
3. [ ] Consider an optional revenge/rematch prompt only when both players can decline and anti-farming rules prevent repeat-pair rewards. No forced PvP or repeated notifications. Keep shields, offline protection, beginner eligibility and one active raid per base.
4. [ ] Evaluate additional protected display capacity only if the measured economy and raid participation support it; retain a meaningful set of exposed targets at every tier. Premium defense still needs a nonpaid counter and the same shared defense budget.
5. [ ] Run six-player and physical-device tests for owner-present thefts, offline/rejoin, lockdown boundaries, anti-camping, staggered defense cooldowns, heavy carried items, recovery after disconnect, free-player routes and server stability. Compare raid frequency, victim quit rate, recovery completion, voluntary replay and D1/D7 returns against the launch baseline. Keep a feature flag and rollback route.

**Done when:** New defenses create choices for **both** thief and owner without permanent collectible loss, trapping, runaway paid advantages or a measurable increase in frustrated exits. Skip entirely if the launch raid loop is already healthy.

## Update record template

```text
Update number / release date:
Player evidence that justified it:
First-delivery time / first-heist completion / second-heist start / D1 baseline and comparison:
Changed source and asset files:
Exact rewards, prices, and eligibility:
Data migration and rollback:
Studio / physical-device / multiplayer checks actually run:
Known limits and owner-supplied rights or IDs:
Next update decision:
```
