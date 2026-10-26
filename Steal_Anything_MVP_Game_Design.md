# Steal Anything! — MVP Game Design and Implementation Context

**Version:** 1.2 · **Updated:** 12 October 2026 · **Platform:** Roblox

**Revision authority:** The owner's 12 October museum expansion brief overrides conflicting prototype values and earlier MVP assumptions. The 36 × 30-stud museum and four starter slots are existing implementation, not the target tier-1 design.

**Audience:** solo developer, AI coding agent, asset contractors, and playtesters.

**Status:** prototype specification. Economy values, timings, and performance targets are starting points for playtests. The title is a working title; check availability before publication.

**Implementation rule:** Sections 1–12 define player-facing behavior. Sections 13–14 define the source layout, ownership boundaries, and complete MVP persistence schema. When implementation details conflict with a gameplay rule, resolve the conflict explicitly before coding; do not silently change the player promise.

### Build brief

| Decision | MVP commitment |
|---|---|
| Core loop | Acquire one absurd object, escape, deliver it home, display it, earn cash, and improve the museum |
| Solo play | A guarded NPC depot supports the full loop in an empty server |
| Multiplayer | Online museum raids create temporary loss, a temporary trophy, and a clear owner recovery path |
| Permanent progress | Legitimately registered item types, accreditation, and earned cash survive rejoining |
| Competitive fairness | Protected slot, beginner protection, visible raid windows, one active raid per museum, earnable counters to capped paid sidegrades |
| Technical foundation | Server-authoritative actions, one versioned profile per player, idempotent durable mutations |
| First deliverable | M0–M1: playable toaster acquisition, delivery, display income, and safe save/rejoin |

## Contents

- [1. Product decision](#1-product-decision)
- [2. Scope contract](#2-scope-contract)
- [3. Full player experience](#3-full-player-experience)
- [4. Map and world specification](#4-map-and-world-specification)
- [5. Controls and movement](#5-controls-and-movement)
- [6. Collection, acquisition, and income](#6-collection-acquisition-and-income)
- [7. NPC depot heists](#7-npc-depot-heists)
- [8. Museum raids and fair consequences](#8-museum-raids-and-fair-consequences)
- [9. Contracts and progression](#9-contracts-and-progression)
- [10. Visual asset specification](#10-visual-asset-specification)
- [11. Animation, sound, and effects](#11-animation-sound-and-effects)
- [12. UI and accessibility](#12-ui-and-accessibility)
- [13. Technical architecture and project folder structure](#13-technical-architecture-and-project-folder-structure)
- [14. Complete database schema and transaction safety](#14-complete-database-schema-and-transaction-safety)
- [15. Monetization](#15-monetization)
- [16. Performance, compatibility, and resilience](#16-performance-compatibility-and-resilience)
- [17. Analytics and product validation](#17-analytics-and-product-validation)
- [18. QA and launch acceptance](#18-qa-and-launch-acceptance)
- [19. Build order and deliverables](#19-build-order-and-deliverables)
- [20. Launch and marketing plan](#20-launch-and-marketing-plan)
- [21. Expansion roadmap](#21-expansion-roadmap)
- [22. Traceability: the 30 agreed changes](#22-traceability-the-30-agreed-changes)
- [23. Evidence, assumptions, and references](#23-evidence-assumptions-and-references)
- [24. Definition of done](#24-definition-of-done)

## 1. Product decision

**Pitch:** Build a museum of ridiculous valuables. Sneak into a guarded depot or raid a rival museum, carry something awkward home, escape a chase, and display your prize to earn money.

The central joke is physical: a giant toilet makes you slow, a rattling machine gives away your position, and a springy duck makes your escape unpredictable. The central decision is whether a better prize is worth a riskier trip.

The player owns a lasting collection and grows a museum through predefined building tiers. Theft interrupts an exhibit’s income and starts a recovery task; it does not erase the permanent collection record. Successful thieves receive temporary trophy displays and heist credit. This keeps meaningful consequences while giving the owner a clear way back.

**The title does not mean every world prop is stealable.** Only clearly marked collectible objects are interactive. Scope is a curated catalog, not a physics sandbox.

### 1.1 What must be true at launch

- The first successful heist is understandable without reading a guide.
- Playing alone in an empty server is worthwhile.
- Carrying, chasing, defending, and returning home feel good on a phone.
- Players understand which objects are safe, which can be raided, and what happens after a theft.
- Saving, purchases, and raid resolution cannot duplicate permanent collectibles or delete collection rights.
- A spectator can understand a funny escape clip in a few seconds.
- There is enough progression for several sessions without needing daily new content.

No feature list guarantees a successful Roblox game, an 80% approval rating, revenue, or 100,000 concurrent players. The launch goal is a stable, enjoyable game with evidence that new players understand it and return voluntarily. Population projections require actual acquisition and retention data.

### 1.2 Design principles

1. **Readable risk:** explain the stake before an action, not after a loss.
2. **Lasting progress:** collection registration and accreditation never reset.
3. **Fair competition:** functional movement, building, security, and raid counters are obtainable with play. Robux may shortcut building effort or offer a capped defensive sidegrade, but never an exclusive counter or unbeatable defense.
4. **Activity over waiting:** NPC targets and recovery jobs are always available.
5. **Comedy through play:** absurd objects affect movement and sound.
6. **Small reusable systems:** new objects reuse three carry behaviors.
7. **Server authority:** clients request actions; the server decides outcomes.

## 2. Scope contract

**MUST** means required for public launch. **LATER** means excluded until the MVP has been tested. Cosmetic polish is required at a basic consistent level; expensive cinematics are not.

| Area | MUST: launch MVP | LATER: expansion |
|---|---|---|
| World | Six fixed maximum envelopes, server-cloned tiered museums, one depot, two viable routes to each plot | Additional districts and moving deliveries |
| Population | Six players per server; NPC play works with one | Larger servers only after profiling |
| Collection | 12 original objects, three carry behaviors, four rarity tiers, three registration-based cosmetic sets | Museum-themed historical collections and category expansion |
| Heists | NPC acquisition, online museum raids, delivery, recovery, permanent non-ownership heist scrapbook | Cooperative missions, practice-replica Museum Challenge |
| Defense | Shove, shared-cooldown defense pad, bounded earnable sensors and guards with counterplay | Additional sidegrade devices |
| Escape | Earned dash and tested stamina sprint; carrying restrictions and earnable counters | Alternate sidegrade loadouts |
| Progression | Five museum building tiers, separate accreditation, modular grounds, repeatable contracts, one player-pinned next goal with cash/delivery progress | Conditional guaranteed rare-acquisition contracts, return goals |
| Economy | Earned cash, exhibit income, fixed-price ordinary shop | Carefully tested new sinks |
| Safety | Tutorial protection, one protected display, raid limits | More social preferences if demand supports them |
| Persistence | Versioned profile, session ownership, recovery-safe writes, permanent set and heist-achievement records | Persistent cross-server trophy ownership/history only after transaction review |
| Presentation | Original simple art, UI, feedback, music and effects | Cinematic intro, elaborate visitors |
| Monetization | Reviewed optional architecture, guard appearances, effects, landscaping, building shortcuts, and capped defensive sidegrades with verified fulfillment | More offers only after fairness and purchase tests |
| Operations | Analytics, error reporting, feature flags, rollback procedure | Live event tooling and creator challenge mode |

**Explicitly exclude:** trading, gifting, auctions, pets, crafting, vehicles, player-authored text, paid random rewards, battle passes, clans, voice-dependent gameplay, open-world destruction, PvP leaderboards with valuable prizes, offline raids, and a full inventory of combat weapons.

## 3. Full player experience

### 3.1 Opening session: approximately 5–8 minutes

Times are pacing intentions. Do not forcibly advance a player who needs longer.

| Step | Player action | Game response / developer requirement |
|---|---|---|
| 1. Arrival | Spawn inside assigned museum | Show empty exhibits, starter cash of 100, a friendly curator marker, and one objective |
| 2. Move | Follow a short path toward the depot | Teach movement and camera through play; show the relevant device input |
| 3. First pickup | Hold interact on the starter toaster | Create a player-specific tutorial target, play pickup feedback, attach carry model |
| 4. First escape | Choose the short open path or longer covered path | Tutorial guard warns but cannot confiscate this first item; route markers remain visible |
| 5. Delivery | Follow the arrow to the gold-trimmed protected stand and hold G; the marked entrance mat also accepts delivery | Server validates the active run and route, registers the toaster once, and places it on the protected stand |
| 6. Reward | See exhibit produce income | Show cash feedback and one sentence: “Your museum earns while you play.” |
| 7. Second heist | Take a public depot item | Normal guard rules begin; teach defend/escape only when relevant |
| 8. Stakes | Inspect another museum or the raid demonstration | Explain temporary loss and recovery using a safe demonstration, not forced PvP |
| 9. First goal | Pin a contract and see accreditation | Show one achievable next upgrade and locked catalog silhouettes |

Do not show a purchase prompt during the tutorial. Tutorial targets are personal server records, not a globally consumable starter object. The current first slice saves step 1 at confirmed delivery and step 2 after the first displayed income dollar; it resumes from that saved step after reconnecting. The next-heist objective identifies public depot stock as upcoming until Task 13 implements it. First-time public raiding is unavailable until protection ends.

### 3.2 Repeating session

1. Collect automatically accrued cash and check a simple contract.
2. Inspect the depot stock or a rival’s visible raid window.
3. Pick a target by income, collection need, and carry behavior.
4. Start the visible pickup interaction.
5. Escape with one object; use route knowledge and limited tools.
6. Deliver to your receiving stand.
7. Register a new depot acquisition or display a temporary stolen trophy.
8. Arrange exhibits during a protected window, purchase an upgrade, or recover a missing exhibit.

There is no forced rebirth and no collection wipe. A failed run should normally cost a short trip, not the player’s entire session.

### 3.3 A representative memorable moment

A player spots a golden toilet in an open museum, begins the clearly visible pickup, and triggers the owner’s alert. The toilet slows the carrier. The owner takes the short route while the thief ducks through the longer covered route. A well-timed shove stops the theft, or the thief reaches home and the trophy appears with a brief celebration. The owner immediately sees a recovery job and its exact remaining work.

## 4. Map and world specification

### 4.1 Layout

- Six fixed, nonoverlapping plot envelopes face a shared depot. Each envelope reserves the maximum 280 × 280-stud property footprint from the start; a small museum uses only its center. The server assigns one envelope to each player and clones a museum template into it. Plot ownership is session-only; the building tier, configuration, and exhibits are rebuilt from the saved profile.
- Depot sits opposite the museum row/ring and is visible from spawn.
- The current 220 × 180-stud world and 36 × 30-stud museum are a first-run prototype. Task 11 replaces the one-plot layout; preserve stable socket meanings and the tested tutorial loop while rebuilding. A roughly 1,000 × 750-stud world is a planning estimate, not a final map size.
- The prototype's one-way depot-to-receiving distances are about 200 studs open and 320 through cover. Re-measure all six expanded plots at every tier, including raid return routes. Do not copy the prototype's timing assumptions into the larger world.
- At 16 studs/second empty-handed, these distances suggest 12.5 and 20 seconds. At 12 studs/second with a normal carry, they suggest 17 and 27 seconds. At 10 studs/second with a heavy carry, they suggest 20 and 32 seconds. Pickup, stops, turns, and chases add time; playtest before tuning.
- The prototype museum is 36 × 30 studs. Preserve a 12-stud-wide, 14-stud-high entrance, a 12-stud clear central aisle, a 10 × 10 receiving pad, and a protected display concept in the starter template. The tiered building is modular; large-object halls, wings, taller rooms, outdoor displays, and possible second floors use authored anchors, not uniform scaling.
- The depot pickup platform is 12 × 12 studs. The open path is 18 studs wide. The covered path has 14 studs of clear width, 18-stud corner pads, and three turns with visible exits. Solid 14-stud cover walls break guard sightlines; a roof alone does not count as cover.
- Check both routes on foot without dash or jumping, then with the largest heavy object when carry behavior exists. Verify camera space at corners, no forced jump or cover-climb shortcut, and a receiving pad that reads differently from an exhibit stand.
- The prototype has one marked raid entrance. Expanded tiers may add authored approaches; every entrance and target must pass the same server raid checks. Walls and roofs block player movement; jump shortcuts must not bypass raid checks.
- Spawn, receiving zone, protected display, raid entrance, and recover console have distinct shapes as well as colors.
- No moving traffic, destructive props, climb-dependent progression, or ambient NPC visitors in MVP.

### 4.2 Museum templates and expansion

| Tier | Name | Building footprint target | Registered stand capacity | Used property footprint target |
|---|---|---:|---:|---:|
| 1 | Starter | 60 × 60 | 3 | 120 × 120 |
| 2 | Growing | 80 × 80 | 6 | 160 × 160 |
| 3 | Expanded | 110 × 110 | 10 | 200 × 200 |
| 4 | Prestigious | 140 × 140 | 15 | 240 × 240 |
| 5 | Grand | 170 × 170 | 20 | 280 × 280 |

These are the owner's proposed starting targets for Task 19, not dimensions of the current model. Tier 1 has one protected and two exposed stands. The existing prototype has one extra exposed stand; migration keeps a registered item from that stand in storage until another legal stand is available. Building tier controls physical stand capacity; accreditation controls how many positions are usable. The lower limit wins. The 12-item launch catalog and one-entitlement-per-type rule mean at most 12 registered stands can be filled in the MVP; higher-tier empty stands are capacity for later catalog growth. No duplicate copies are introduced to fill them.

Every template variant has an immutable anchor manifest for spawn, receiving zone, protected slot, exposed slots, recovery console, raid entrances, and expansion seams. The server validates IDs and transforms after cloning. A tier change settles income first, records the new tier/configuration durably, rebuilds or extends modules safely, and restores each legal placement. If a saved slot is incompatible with the new template, move the registered item to storage rather than deleting it. Reserved envelopes prevent overlap with neighbors at all tiers.

Museum size by itself adds no income. Displayed registered items, their state, and the protected multiplier still determine the rate. Larger museums may have more approaches and more visible prestige cues; security has capped costs and earnable counters. Test route time, camera, streaming, and the largest object at each tier before finalizing footprints or deadlines.

### 4.3 World readability

Museum doorway shows owner name using Roblox-provided identity, a shield/open icon, and a countdown. Each display shows item name, income per minute, registration state, and a stealable/secure icon when approached. Do not fill the world with permanent floating text at a distance.

Depot has three public pedestals plus a personal tutorial pedestal. A visible sign identifies the next ordinary restock. Rare content never requires attending a particular real-world time.

### 4.4 Background and atmosphere

Use a bright stylized museum district at fixed afternoon lighting. Neutral cream walls, teal navigation accents, warm gold reward accents, and red/orange danger cues. Danger also uses iconography and animation. Use a simple sky, restrained shadows, and distant non-interactive buildings. Avoid expensive realistic reflections, dense foliage, and heavy fog that hides threats.

Keep the lawn and primary floor surfaces visually quiet. Vary tree height, trunk angle, and canopy silhouette, with loose groups near the district edge instead of evenly spaced copies. Frame exhibit surfaces as stands or cases; avoid large cyan or gold placeholder slabs. Add side-wall trim and signage only where they preserve route width and the existing cover geometry.

For the first museum, give the rectangular shell a raised roof edge, framed entrance, shallow columns, inset wall panels, readable sign, and paired planters. Inside, use divided tile, a contrasting wood lower wall, framed exhibit signs, beams, and visible warm fixtures. Build each display from a base, stem, top, and nameplate; reserve gold trim, a shield emblem, and a spotlight for the protected slot. Mark delivery with a bordered mat, arrows, and a drop-off sign; give recovery its own screened kiosk. Treat the covered route as a museum service passage with concrete cover, brick lower wall, metal awnings, lamps, and pipes. Give the open route paving and edges, and the depot a loading awning and stock area. Keep trim, signs, and light fixtures non-colliding. Trees, shrubs, planters, crates, and benches are solid and sit outside the required route clearance. The prototype collision ground is 220 × 180 studs; Task 11 expands the playable collision world to fit six maximum envelopes. Any scenery apron stays visual only.

When extracting the starter template, keep one visible surface per wall/floor plane. The prototype entrance needed a second correction because duplicated column faces were coplanar with the structural wall and overlapping step/mat parts remained visible in motion. Reuse the repaired Studio entrance and test moving camera views at each modular seam; do not rebuild the old stacked surfaces from the generated JSON.

## 5. Controls and movement

Use standard Roblox avatar movement. Normalize gameplay dimensions and movement settings server-side; avatar cosmetics must not change reach, speed, collision advantage, or visibility of essential cues.

| Action | Keyboard/mouse default | Touch | Controller intent |
|---|---|---|---|
| Move / camera | Standard Roblox | Standard Roblox | Standard Roblox |
| Interact / pick up | Hold E | Large contextual hold button | Context action mapped to X / equivalent |
| Shove | F | Contextual defense button | Dedicated action, avoid jump conflict |
| Dash | Q | Separate ability button | Shoulder action |
| Deliver carried item | Hold G for 0.5 sec at the museum stand or entrance mat | Hold labeled Deliver | Hold B at the drop-off |
| Catalog / museum | Screen buttons | Screen buttons | Focusable menu buttons |
| Cancel / close | Escape or UI close as appropriate | Close button | Back action |

Controller mappings are implementation defaults to verify on actual hardware; adapt labels to device. Do not override Roblox system menus or reserved inputs.

### 5.1 Initial movement values

| Parameter | Initial value |
|---|---:|
| Normal WalkSpeed | 16 studs/sec |
| Normal carry speed | 12 studs/sec |
| Heavy carry speed | 10 studs/sec |
| Pickup hold duration | 1.25 seconds |
| Pickup interaction distance | 7 studs, with line of sight |
| Shove range | 6 studs, forward cone, server checked |
| Shove cooldown | 4 seconds |
| Hit stun | 0.6 seconds |
| Post-stun immunity | 2 seconds |
| Dash | Short forward burst, 12-second cooldown |
| Carrying dash | Disabled; escape relies on route choice |
| Sprint | Task 16 adds server-bounded stamina and speed after six-plot route measurements; no launch value is fixed yet |

No ragdoll is required. Use a brief stagger animation and bounded movement interruption. Dash collision must not pass through walls or protected entrances. Server movement checks should tolerate latency and focus on impossible transitions, not punish a single delayed packet.

The expanded map may need sprint, but carry and raid deadlines must be measured against actual tier-five routes at normal and impaired speeds. Sprint cannot bypass walls, purchase gates, or server movement checks; premium offers cannot increase its competitive speed or stamina.

The travel ability choice uses earned cash. During Task 12 testing, Ride to depot is free. At release, the first ride demonstrates the ability for free, then a permanent unlock gives unlimited rides with a 60-second cooldown; riding is disabled while carrying, in an active raid, or while chased. The speed coil is a permanent unlock for about +20% empty-handed walking speed and does not increase carry speed. The two are priced by purchase order: the first one bought costs a provisional $1,000 (about 20–30 minutes of play) and the other $2,200 (about 45–75 minutes). The pricing method is in the 14 October section of the development plan. Free sprint remains useful. The tutorial plays without a purchase message. After the second confirmed NPC delivery, leaving the museum shows travel options once; future reminders are off by default unless the player enables them, and that preference is saved.

### 5.2 Three carry behaviors

| Behavior | Gameplay rule | Presentation | Implementation boundary |
|---|---|---|---|
| Heavy | Carry speed becomes 10 | Leaning pose, weighty footstep accents | No unbounded physical mass simulation |
| Noisy | Every 3 seconds, ping reveals carrier’s approximate location to nearby guard/affected owner | Rattle, sound-wave ring, short icon | Server schedules ping; clients render within relevance range |
| Bouncy | Every 4 seconds, a 0.35-second speed dip to 9, then normal carry speed | Object springs upward on its attachment | Cosmetic bounce only; never fling character or randomize controls |

These values must be playtested. Each behavior needs a trade-off players can understand. Do not add arbitrary camera shake, uncontrollable ragdolls, or physics-driven falling as the primary difficulty.

## 6. Collection, acquisition, and income

### 6.1 Permanent collection rules

- A legitimate depot delivery or fixed-price shop purchase registers an item type permanently.
- MVP permits one registered exhibit per item type. Reacquiring a duplicate gives a clearly advertised cash salvage reward, not another permanent copy.
- Catalog silhouettes reveal acquisition method and rarity before ownership.
- Registered items can be displayed, stored, or temporarily missing after theft.
- Stored and missing items produce no income. Only active displays earn.
- Registration is never consumed by upgrades, contracts, or recovery.
- Shop purchases are deterministic, use earned cash, and never require Robux.

### 6.2 Starting catalog

All names and models are original placeholders; avoid copying recognizably protected characters or meme audio. Income is **cash per minute**, not per second.

| ID | Object | Tier | Carry | Base income/min | Shop cost | Depot weight |
|---|---|---|---|---:|---:|---:|
| toaster | Dramatic Toaster | Common | Noisy | 12 | 180 | 20 |
| duck | Springy Rubber Duck | Common | Bouncy | 14 | 220 | 18 |
| traffic_cone | Royal Traffic Cone | Common | Heavy | 16 | 280 | 16 |
| disco_bin | Disco Dustbin | Common | Noisy | 18 | 340 | 14 |
| gold_toilet | Golden Toilet | Uncommon | Heavy | 26 | — | 8 |
| jelly_lamp | Jelly Lamp | Uncommon | Bouncy | 28 | — | 7 |
| snack_machine | Rattling Snack Machine | Uncommon | Noisy | 30 | — | 6 |
| moon_rock | Suspicious Moon Rock | Uncommon | Heavy | 32 | — | 5 |
| mini_ufo | Spring-Mounted Mini UFO | Rare | Bouncy | 44 | — | 2 |
| dinosaur_skull | Tiny Dinosaur’s Giant Skull | Rare | Heavy | 48 | — | 2 |
| storm_jar | Storm in a Jar | Rare | Noisy | 52 | — | 1.5 |
| giant_diamond | Absurdly Large Diamond | Legendary | Heavy | 70 | — | 0.5 |

Weights sum to 100. They apply to free ordinary depot restocks, never paid random purchases. The tutorial toaster is guaranteed outside the table. The rarest item is not required for core upgrades or tutorial completion.

Duplicate depot salvage = three minutes of that object’s base income, awarded only after delivery. Rate-limit public acquisitions through pedestal availability and travel, not a hidden arbitrary daily cap. Duplicate collection is visible before pickup.

### 6.3 Exhibit slots and upgrades

The target starter tier has three registered-display stands: one protected and two exposed. The current prototype's fourth stand is a migration case, not part of the new starter tier. A separate temporary trophy stand never counts as a registered-display stand.

| Accreditation | Cost | Flexible requirement | Total display slots | Other reward |
|---|---:|---|---:|---|
| Starter | None | Tutorial | 3 | Museum and recovery console |
| Local Attraction | 1,200 | Six successful deliveries of any kind | 6 | Wall color palette |
| Town Landmark | 4,000 | Twelve NPC deliveries OR six distinct registered objects | 8 | Museum sign style |
| Grand Collection | 10,000 | Twenty-five NPC deliveries OR ten distinct registered objects | 20 | Exhibit frame style |

Counts are lifetime counters unless explicitly stated. Upgrades do not reset cash beyond their purchase price or delete items. Slots are a progression benefit, but movement, shove power, and stun duration never scale with wealth.

Accreditation and building tier are separate gates. Accreditation grants a maximum usable registered-slot count of 3, 6, 10, or 20. Building tiers provide physical anchors with capacities of 3, 6, 10, 15, or 20. A player may use only the lower count. The launch catalog still limits occupied slots to 12 unique registered item types. Tier purchases use earned cash and server-checked prerequisites. Robux building shortcuts may reduce construction time or earned-cash cost without skipping tier order or exceeding the shared security budget; test their effect on raid fairness before enabling them.

### 6.4 Income calculation

- Simulate cash on the server, using elapsed time rather than trusting client ticks.
- Normal registered display: 100% base rate. Protected slot: 50% base rate.
- Temporary PvP trophy: 50% of its item’s base rate for ten minutes of active server time.
- One trophy at a time; a new trophy replaces the previous one after explicit pre-raid UI disclosure.
- Missing, stored, reserved-in-raid, and recovery-pending displays earn zero.
- No offline income in MVP. State this in UI. It avoids extra inflation and ambiguous offline calculations.
- Retain fractional income server-side; present whole cash. Use bounded finite numeric values and an explicit maximum safe currency limit.
- On each state change, settle elapsed income under the old state before changing it. Prevent double settlement.

Shop and upgrade confirmation show price, balance afterward, and outcome. Disable duplicate clicks while pending; server still handles repeated requests idempotently.

## 7. NPC depot heists

### 7.1 Stock

Three public pedestals. A pedestal reserves to the first valid player to finish pickup. Simultaneous attempts receive clear failure feedback. Empty pedestals restock after 20 seconds. Untouched stock rotates after 120 seconds with a visible final countdown. Reserved stock never despawns mid-pickup or run.

Each depot run gets a unique server-generated run ID. A failed carry returns/despawns the run item and schedules pedestal restock. A fresh run cannot award a prior run’s delivery again.

### 7.2 Guard

One guard archetype follows fixed patrol waypoints. States: Patrol → Suspicious → Chase → Return. Use simple, bounded navigation on the grayboxed map; path recomputation is throttled, not every frame.

- Starting detection: 24-stud range, 100-degree forward view, unobstructed line of sight.
- Noisy carry pings can trigger investigation within 35 studs.
- A visible warning fills for 0.75 seconds before chase starts.
- Guard speed starts at 14; tune route cover so all carry types have viable escapes.
- Guard gives up after 4 seconds without detection and never enters a museum.
- Contact capture requires server distance validation and a brief 0.4-second readable windup.
- Capture ends the NPC run, returns player control after a short stagger, and leaves cash/collection intact.
- Guard cannot confiscate the guaranteed first tutorial item.

Guard and players must use consistent collision rules. Avoid required jump puzzles. Other players cannot steal an NPC-carried item out of your hands in MVP; they can compete for the next pedestal.

## 8. Museum raids and fair consequences

### 8.1 Eligibility

A museum is raid eligible only if owner and attacker are in the same server, both completed onboarding protection, owner has at least two available exposed displays, and its raid window is open. The attacker must also maintain two available exposed displays at home. No raiding from a completely risk-free museum.

Building tier does not waive these requirements. Raid entry, target reachability, and recovery access use the specific owner's cloned museum and its server-validated anchor manifest. Security may warn or delay a raider, but no permitted arrangement can seal every legal approach. Bigger tier layouts must expose at least one tested route to every raid-eligible display.

When an owner is physically **inside the museum building**, a server-controlled invisible visitor boundary keeps every other player outside the current grounds footprint, including the garden. The owner can cross it. When the owner leaves the building, visitors can enter the grounds and museum subject to the normal raid-window rules. If an owner returns while a visitor is inside, move that visitor outside and cancel any incompatible pickup or raid before further rewards. This owner-presence rule takes priority over an open raid window.

The protected slot, stored items, missing items, active recovery target, and existing temporary trophies cannot be stolen. Taking a trophy never creates permanent catalog rights.

### 8.2 Raid windows

- Initial beginner protection: until three NPC deliveries AND at least five minutes of active play. Both conditions must be met.
- After beginner protection, automatic cycle: 90 seconds protected, then 60 seconds open.
- A clear doorway icon/countdown communicates the cycle.
- At most one active raid per museum, whether pickup or carry stage.
- Successful theft starts a 90-second protection interval. Failed/expired attempts give a 15-second retry shield, then resume the cycle using an explicit stored remaining phase duration.
- A raid validly started during the open window can finish after it closes. The prototype deadline is 45 seconds; before tiered plots launch, measure and publish a fair bounded deadline or tier/route rule for the longest legal escape. Never silently keep 45 seconds when a maximum-size plot makes it impossible.
- Pause arrangement/storage changes for all exposed displays during an open window and for the duration of an active raid. Allow viewing menus, but explain why changes are locked.
- No paid shield, paid forced opening, or paid bypass.

Server-side eligibility remains authoritative even if a door animation looks open. Use a server-controlled entrance/interaction gate and validate every pickup. Do not rely exclusively on physical doors as security.

### 8.3 Raid state machine

| State | Entry | Allowed transition | Resolution |
|---|---|---|---|
| Available | Eligible display and museum | Valid pickup request | Reserve item and museum; warn owner |
| PickingUp | 1.25-sec held interaction | Complete / cancel / move / hit / disconnect | Complete begins carry; all failures release reservation |
| Carrying | Server creates carry record | Delivery / owner defense / drop / death / timeout | Only one terminal outcome allowed |
| Committing | Valid delivery begins owner profile write | Durable success / definite failure / uncertain result | Freeze further resolution and reconcile operation ID |
| Stolen | Durable owner update succeeded | Owner recovery, independent of thief | Owner item missing; temporary trophy awarded if thief remains eligible |
| Returned | Carry failed before successful commit | None | Exhibit restored; no thief reward |

The owner sees target object, raider direction, and remaining deadline. Do not expose the thief through walls continuously except brief noisy-object pings; avoid clutter for unrelated players.

### 8.4 Carry, defense, and delivery

The carrier cannot pick up another item by default, use dash, arrange exhibits, start recovery, or begin another raid. Earned-cash NPC capacity upgrades later add a second slot for a provisional $6,500 and a third for $17,000, purchased permanently in order. Player theft remains limited to one item per raid. Multiple NPC items share run cleanup on death, disconnect, and delivery. The owner can shove the active thief inside a bounded raid area comprising their museum and public routes. Unrelated players cannot stun either participant during this raid in MVP. A successful owner shove cancels the raid and returns the exhibit. This eliminates repeated third-party harassment and pile-ons.

Each museum has one fixed defense pad near its entrance. It gives the owner an alternate way to trigger the same defend action, with the same shared cooldown and immunity rules; it does not stack stun or create a second damage system. If playtests show no useful distinction, remove the pad and retain shove before adding more devices.

The expansion adds a capped security loadout, starting with at most one motion sensor and two museum guards; a third guard is a balance candidate only after counterplay tests. These are predictable systems with patrol gaps, line-of-sight limits, warning time, and server-checked placement. Guards cannot camp the only legal entry or the receiving zone. Sensor information is scoped to the raid participants; nearby prestige hints expose tier and a coarse collection-value band, never a private inventory list. Raider counter-abilities for every allowed setup are earned through ordinary play. Paid defensive sidegrades use the same guard/device budget and placement limits as earned defenses and must have a tested earnable equivalent or counter. Payment never increases the absolute cap, stun immunity, or protection timer.

Delivery requires the carrier to reach their own assigned clone's receiving zone, be alive, hold the valid raid ID, and remain within the tested deadline. Server checks current position and plausible route history. Delivery starts commit; visible success occurs only after durable owner-state confirmation.

### 8.5 Owner recovery

- A stolen registered item becomes Missing. Registration and its catalog entry remain.
- Recovery starts at the owner’s console, one selected item at a time.
- Complete three recovery courier jobs. Each job collects a marked parcel at the depot and returns it home.
- A job has no theft exposure; guard capture can require retrying the current parcel but never resets already saved job progress.
- Target total active recovery effort: approximately 3–5 minutes. If measured route times make it much shorter, add meaningful route variation, not a forced idle timer.
- After the third delivered parcel is durably saved, restore the exhibit to storage, or its previous slot if that slot remains free and placement is currently allowed.
- Recovery costs no Robux and no rare item. A stored restored exhibit remains available when raid-window arrangement unlocks.
- Multiple missing types keep independent progress records; switching the active target preserves progress.

Never allow recovery to create a second permanent entitlement. A missing item cannot be bought or reacquired as a second copy: legitimate reacquisition instead restores that existing registration once, with an explicit message and no salvage reward.

### 8.6 Disconnects, deaths, and races

| Event | Required result |
|---|---|
| Owner leaves before raid begins | Remove museum eligibility immediately |
| Owner leaves during pickup/carry | Cancel and return exhibit; no reward. MVP favors simple safe resolution over punishing disconnects |
| Thief leaves before commit | Cancel and return exhibit |
| Either resets/dies before commit | Cancel raid and return exhibit |
| Voluntary drop or carry timeout | Return exhibit immediately; no ground loot |
| Owner or thief leaves after commit starts | Finish/reconcile owner write; do not re-run an earlier cancellation path |
| Owner write definitely fails | Return exhibit, no trophy, show retryable error |
| Owner write outcome uncertain | Keep operation unresolved and retry/read using same operation ID; never assume failure and issue a second result |
| Server crashes before durable owner commit | Last saved owner state stays available; no durable theft occurred |
| Server crashes after durable owner commit | Owner remains Missing with recovery available; session-only trophy may be lost |
| Thief disconnects after successful theft | Trophy ends; owner can still recover normally |
| Owner reconnects while old session owns data | Wait safely for session release; do not load a writable duplicate profile |
| Two deliveries or callbacks race | One operation ID commits once; repeats return the recorded result |

**Known MVP trade-off:** owners can disconnect to cancel an in-flight theft. Do not hide this. Analyze how often it happens. A later persistent raid escrow may address it, but is explicitly outside launch scope. Rejoining restarts at the saved raid phase, not a fresh free protection interval; ordinary raid phase tracking must not be used to lock out a player whose data is still loading.

### 8.7 Farming controls

No cash lump-sum from PvP theft at launch. Reward is the temporary trophy income, contract credit under limits, and visual celebration. A pair of user IDs can grant rewarded PvP completion only once per ten minutes per server, regardless of direction. Repeated attempts display “Practice only: no trophy or contract reward” before pickup and require confirmation, or simply reject them in MVP. Prefer rejection for smaller scope.

PvP contracts are optional alternatives to NPC contracts, never the fastest mandatory upgrade path. Track pair repetition and unusually fast deliveries before considering harsher restrictions. Do not automatically ban based on one heuristic.

## 9. Contracts and progression

Three active contracts at a time, selected from six templates. Replacement is immediate on claim; no calendar streak, real-time appointment, or paid refresh. Each contract instance has a unique ID and can be claimed once.

| Template | Requirement | Initial cash reward |
|---|---|---:|
| Local Courier | Deliver two NPC objects | 100 |
| Awkward Cargo | Deliver one heavy NPC object | 80 |
| Quiet Route | Deliver any NPC object without entering guard Chase | 100 |
| New Exhibit | Register one unowned type; only assign when plausible | 150 |
| Museum Worker | Complete one recovery parcel OR two NPC deliveries | 80 |
| Daring Run | Complete one eligible PvP heist OR three NPC deliveries | 160 |

Contract pools must not require inaccessible types. No consuming owned exhibits. Pin one objective to HUD. Public launch has no global wealth leaderboard; it invites inflation and exploit pressure before the economy is understood. Personal bests and lifetime delivery totals are enough.

## 10. Visual asset specification

### 10.1 Character design

Players use their own Roblox avatars with a standardized gameplay controller. Do not require buying an avatar to participate. Use a carry attachment rig that works across tested R15 proportions; if unsupported avatar proportions cannot be normalized reliably, use a consistent game rig and disclose this design decision during prototype review.

One original curator NPC: friendly rounded silhouette, teal jacket, simple museum badge. One original guard: broad readable silhouette, orange vest, flashlight or detector prop, expressive suspicion icon. Avoid realistic weapons and frightening capture imagery.

### 10.2 Asset checklist

| Asset group | Launch quantity / requirements |
|---|---|
| Collectible models | 12; consistent attachment point, bounds, icon framing and metadata |
| Carry variants | Reuse models with smaller camera-safe scale; no separate high-detail models needed |
| Museum shell | One modular kit, six color accents, ten possible display sockets |
| Depot | One kit, three pedestals, tutorial pedestal, guard path markers invisible at runtime |
| Route props | Approximately 8–12 reusable cover/wall/sign pieces |
| NPCs | Two rigs; curator can remain stationary |
| Display stands | Ordinary, protected, temporary trophy, receiving zone |
| UI icons | Cash, shield, open, catalog, contract, recover, carry, warning, audio, settings |
| Item icons | 12 consistent renders; can generate from final in-engine models |
| Marketing | One readable square icon, at least two honest gameplay thumbnails |

Model budget is a profiling constraint, not a universal polygon rule. Start with simple geometry, shared materials and restrained transparent surfaces. Keep authoritative hitboxes invisible and simple. Cosmetic carried models are non-collidable and cannot affect network physics ownership.

Every asset needs a recorded source/license, owner, usage permission, and published Roblox asset ID. Placeholder IDs must be visibly marked; the coding agent must never invent valid-looking IDs or copy unlicensed audio.

## 11. Animation, sound, and effects

### 11.1 Animation inventory

| Animation | Trigger | Requirements |
|---|---|---|
| Normal locomotion | Standard movement | Use compatible Roblox baseline where permitted |
| Pickup | Valid pickup hold | Cancel cleanly; progress ring remains authoritative |
| Carry ordinary | Carrying noisy/bouncy item | Upper-body pose blended with walking |
| Carry heavy | Carrying heavy item | Leaning silhouette; never cover camera |
| Shove | Valid defense action | Short readable windup; hit frame tied to server action timing |
| Stagger | Valid stun | 0.6 sec; no repeated chain during immunity |
| Delivery celebration | Successful confirmed delivery | Under 1.5 sec; no input lock |
| Guard patrol/chase | Guard state | Reuse locomotion with speed/pose change |
| Guard alert | Suspicion completes | Clear icon and gesture |
| Recovery restore | Recovery completes | Exhibit appears with restrained reveal |

Animation priorities and cancel conditions must be explicit in the implementation. Death, respawn, cancellation, and delivery clear all carry tracks and attachments. State logic must work if an animation fails to load.

### 11.2 Audio inventory

| Sound | Purpose / mix rule |
|---|---|
| Plaza music | One original/licensed seamless low-intensity loop; quieter during alert |
| Depot ambience | Very light spatial hum; no loud repetitive crowd |
| UI focus/confirm/error | Short distinct effects; avoid firing each frame |
| Pickup start/complete | Audible action progress and outcome |
| Heavy step accent | Limited rate; spatial, low mix priority |
| Noisy object rattle | Gameplay-timed 3-second cue, bounded range |
| Bouncy object boing | Subtle, synchronized to visual bounce |
| Guard suspicion/alert | Different escalating cues plus visual alternative |
| Owner raid alert | Owner-only clear cue, not server-wide siren |
| Shove/stagger | Light slapstick impact, no graphic effect |
| Delivery/recovery | Short success sting |
| Purchase/upgrade | Brief confirmation, no long fanfare |
| Theft loss | Neutral informative cue, not humiliating laughter |

Provide Master, Music, and Effects volume sliders, persisted per player. Gameplay-critical cues also have visual equivalents. Use SoundGroups, distance falloff, voice limits, and cooldowns to stop overlapping spam. Muted audio must not make the game unplayable. Establish a consistent mix in a busy six-player test; do not rely on one universal volume number across different source files.

### 11.3 VFX inventory

- Pickup: progress ring and gentle outline on the targeted object.
- Carry: behavior-specific motion and a small readable carry indicator.
- Guard: suspicion meter, alert icon, optional short cone preview in tutorial.
- Raid: owner alert, doorway state change, target outline visible only as intended.
- Shove: one impact burst; no full-screen flash.
- Stun immunity: subtle outline plus icon; avoid relying on color alone.
- Delivery: short confetti burst and cash/collection confirmation.
- Protected display: calm shield emblem; no permanent expensive particle shower.
- Recovery: brief restoration sparkle and checklist completion.

Reduce Motion removes screen shake, bounce exaggeration, and excess confetti while preserving gameplay timing and warning icons. Never change actual movement timing through an accessibility setting.

## 12. UI and accessibility

### 12.1 Required screens

1. Loading: actual load state, retry/help message, no fake percentage.
2. HUD: cash, pinned contract, relevant interaction, museum shield state, carry state when active.
3. Carry HUD: object, destination, deadline for PvP, Drop action, behavior icon.
4. Owner raid alert: stolen target, current phase, explanation of defense/recovery.
5. Catalog: owned/unowned/missing filters, source, income, carry behavior.
6. Museum management: building tier, physical versus unlocked stands, slot arrangement, protected slot penalty, grounds, capped security loadout, trophy timer.
7. Recovery console: missing list, selected target, saved parcel progress.
8. Shop: four ordinary items with fixed prices, earned tier/grounds/security/movement offers when implemented, and clear duplicate handling.
9. Accreditation: three upgrades, requirements, cost, permanent benefits.
10. Contracts: progress, reward, claim state, pinned objective.
11. Settings: volume, Reduce Motion, optional low-effects mode, controls.
12. Purchase confirmation/result: only if monetization enabled.
13. Data/service error: clear safe action and retry; never offer “reset data” as a normal fix.

### 12.2 UX requirements

- Touch targets start at approximately 48 logical pixels; validate across device layouts and safe areas.
- Primary actions stay reachable without covering movement controls.
- Gamepad focus order is deterministic and no modal traps focus.
- Show text labels with unfamiliar icons; avoid microscopic currency abbreviations in early progression.
- Support text scaling/localization-friendly layouts, even if English is the only launch language.
- No custom chat or free-text museum names in MVP. Use platform identity/chat systems with their applicable filtering and settings.
- One primary tutorial message at a time. Allow replaying controls.
- Distinguish “Registered forever,” “Currently displayed,” “Missing—recoverable,” and “Temporary trophy” consistently.
- Confirmation copy before first PvP attempt: “This earns a temporary trophy. The owner keeps collection rights and can recover their exhibit.”
- Color contrast, danger icons, captions for meaningful sound, and motion reduction are launch requirements, not future cosmetics.

## 13. Technical architecture and project folder structure

### 13.1 Rules before coding

- Implement in typed Luau where practical. Keep data definitions separate from behavior.
- Build a playable vertical slice before producing all assets or polishing every menu.
- Use current Roblox documentation for exact APIs. Do not invent API names, marketplace IDs, packages, or credentials.
- Explain nontrivial external dependencies and review their maintenance/security status before adopting them.
- Never publish, spend Robux, contact creators, or change production data without project-owner authorization.
- Use separate development/test and production data stores and environment configuration.
- Never run destructive migration experiments against live profiles.

### 13.2 Repository and Roblox instance structure

Use a Rojo-style source layout so code can be reviewed and versioned outside Studio. The present `Workspace/Map` is Studio-owned and preserved by Rojo. Task 11 converts the authored museum into a versioned server-cloned template; public routes and reserved plot anchors remain shared world assets. The layout below is a target structure, not a claim that every folder already exists.

```text
steal-anything/
├── Steal_Anything_MVP_Game_Design.md
├── README.md                    # setup, Studio sync, test and release steps
├── default.project.json         # source/assets → Roblox instance mapping
├── src/
│   ├── shared/                  # ReplicatedStorage/Shared; no secrets or authority
│   │   ├── Types.luau           # payload, profile-view and domain types
│   │   ├── BalanceConfig.luau   # all tunable numbers from this document
│   │   ├── ItemCatalog.luau     # 12 item definitions and validation
│   │   ├── ContractDefinitions.luau
│   │   ├── UpgradeDefinitions.luau
│   │   └── RemoteDefinitions.luau
│   ├── server/                  # ServerScriptService/Server
│   │   ├── Bootstrap.server.luau
│   │   ├── Config/              # environment, store names, feature flags, IDs
│   │   ├── Data/                # ProfileSchema, defaults, migration, validation
│   │   ├── Services/            # one module per owner in §13.3
│   │   ├── Domain/              # pure income, eligibility, state transitions
│   │   └── Networking/          # remote creation, validation and rate limits
│   ├── client/                  # StarterPlayerScripts/Client
│   │   ├── Bootstrap.client.luau
│   │   ├── Controllers/         # input, UI, audio, effects, carry presentation
│   │   └── UI/                  # screens, components, theme, accessibility
│   └── serverStorage/           # ServerStorage/Assets; server-cloned templates
│       ├── Collectibles/
│       ├── NPCs/
│       └── MuseumPieces/          # future versioned tier modules and socket manifest
├── assets/
│   ├── places/MainMap.model.json # old graybox reference, not live-synced
│   ├── audio/                   # source files; published IDs in server config
│   ├── images/                  # source icons and marketing artwork
│   └── asset-manifest.md        # provenance, license, owner, published IDs
├── tests/
│   ├── unit/                    # income, state, validation, migration, idempotency
│   ├── integration/             # multi-client and datastore failure scenarios
│   └── fixtures/                # old and malformed profile samples
└── docs/
    ├── operations.md            # flags, incidents, saves, rollback
    └── playtest.md              # target devices and observed test script
```

`default.project.json` maps `src/shared` to `ReplicatedStorage/Shared`, `src/server` to `ServerScriptService/Server`, `src/client` to `StarterPlayer/StarterPlayerScripts/Client`, and `src/serverStorage` to `ServerStorage/Assets`. It does **not** map the old generated graybox to `Workspace/Map`. The current fixed network allowlist is mapped under `ReplicatedStorage/Network`; keep it fixed as new actions are added. Do not put profiles, lease state, moderation tools, or product secrets in replicated containers. Use tags/attributes or stable IDs for authored sockets; never depend on child order.

Keep one authoritative service per concern. UI components read a sanitized profile view, never the saved profile object. Keep pure domain rules free of Roblox instances so they can be tested without a running place. Add folders only when their first real file is needed; avoid empty scaffolding.

### 13.3 Service ownership

| Service | Authoritative responsibility |
|---|---|
| Profile | Load, session ownership, migrations, serialized durable mutations, save/release |
| Economy | Income settlement, bounded balances, atomic spend within profile |
| Collection | Registration, item state, duplicates, exhibit placement |
| Plot / Museum | Six session-owned slot reservations; clone lifecycle, ownership, profile reconstruction, protection cycle, layout restrictions |
| Depot / Guard | Stock/run IDs, guard state, detection/capture |
| Carry | One carry per player, attach state, terminal cleanup |
| Raid | Eligibility, reservation, deadline, exactly-once logical resolution |
| Recovery | Missing record, parcel runs, restoration |
| Contract / Progression | Server event counters and idempotent claims |
| Purchase | Verified pass ownership, durable receipt processing for any approved developer products, and premium fairness limits |
| Analytics | Valid event schema, sampling/rate limits, no gameplay authority |

Avoid circular service dependencies. A server event coordinator can distribute confirmed domain events such as DeliveryCommitted, ExhibitMissing, and RecoveryCommitted. Clients receive presentation events only after appropriate authoritative state updates.

### 13.4 Remote contracts

Client requests contain IDs and intent, not authoritative price, reward, elapsed time, position, ownership, or outcome. Use a fixed allowlist of action names and validate types, finite numbers, string lengths, ownership, current state, proximity, line of sight, cooldowns, and request frequency.

| Request | Minimal client payload | Server checks |
|---|---|---|
| BeginPickup | targetId, requestId | Known target, distance, eligibility, reservation |
| CancelPickup | pickupId | Own active pickup |
| DeliverCarry | carryId | Own active run, own assigned clone's receiving zone/stand, plausible travel, idempotent registration |
| DropCarry | carryId | Own active carry |
| Shove | action sequence | Cooldown, raid relationship, facing/distance, immunity |
| Dash | action sequence, bounded direction | Not carrying, cooldown, collision, valid movement |
| ArrangeExhibit | itemType, slotId, requestId | Registered available item, unlocked slot, protected phase |
| BuyShopItem | itemType, requestId | Shop allowlist, balance, duplicate rule |
| BuyAccreditation | upgradeId, requestId | Next upgrade, requirements, balance |
| SelectRecovery | itemType | Missing registration, no active carry |
| ClaimContract | contractInstanceId | Complete, unclaimed, same profile |
| UpdateSettings | allowlisted settings | Bounds and rate limits |

Delivery is detected/validated by the server, not awarded by a client “success” message. Clients cannot submit another player’s UserId as authorization. Rate limits should allow normal touch retries and prevent abuse. A remote timeout does not prove the action failed; the UI requests/reconciles current state.

## 14. Complete database schema and transaction safety

### 14.1 Storage model and keys

Roblox MVP persistence is a **versioned player document in DataStoreService**, not a SQL database. The source of truth is one record per user in a store named by environment, such as `StealAnything_Dev_v1` or `StealAnything_Prod_v1`, under key `player:<UserId>`. Do not share test and production stores. `UserId` is taken from the authenticated Player object, never from a client request. An absent key after a successful read creates defaults; a failed read does not.

The record is intentionally denormalized: every durable economy or exhibit mutation can be written to one profile. Item, contract, and upgrade definitions are versioned source code, not rows in the player record. Analytics is emitted to Roblox telemetry and is not a second gameplay authority. A reviewed session-lock library may add lease metadata to the same stored value; its exact envelope is implementation-specific and must be tested before launch.

### 14.2 Full MVP profile schema

The types below define every durable gameplay field. `ItemId`, `ContractId`, `UpgradeId`, and `SlotId` are allowlisted strings from code. Numeric currency and counters are finite, nonnegative integers unless noted. Schema validation rejects unknown states and impossible cross-field combinations; migration fills newly added fields without replacing valid progress.

```luau
export type Exhibit = {
    state: "Available" | "Missing",
    registeredAtUnix: number,
    acquisition: "Tutorial" | "Depot" | "Shop",
    missingOperationId: string?, -- present exactly when Missing
    previousSlotId: string?,     -- restore preference, never a second placement
    recoveryJobsDone: number,    -- integer 0..3; reset on a new theft
}

export type Contract = {
    instanceId: string,          -- server-generated, unique within profile
    definitionId: string,        -- one of six versioned templates
    progress: {[string]: number},-- requirement path -> integer event count
    assignedAtUnix: number,
    completed: boolean,
    claimed: boolean,
}

export type Operation = {
    kind: "DepotDelivery" | "ShopPurchase" | "UpgradePurchase"
        | "RaidLoss" | "RecoveryParcel" | "RecoveryRestore"
        | "ContractClaim" | "ExhibitArrangement" | "MuseumTierPurchase"
        | "GroundsPurchase" | "SecurityPurchase" | "PremiumGrant",
    result: "Committed" | "Rejected",
    committedAtUnix: number,
    requestScope: string,        -- server session/action scope for stale-ID rejection
    resultCode: string,          -- stable response for legitimate retries
}

export type Settings = {
    masterVolume: number,        -- 0..1
    musicVolume: number,         -- 0..1
    effectsVolume: number,       -- 0..1
    reduceMotion: boolean,
    lowEffects: boolean,
}

export type Lifetime = {
    npcDeliveries: number,
    pvpDeliveries: number,
    recoveryParcels: number,
    distinctRegistered: number,  -- derived/validated against exhibits
    totalCashEarned: number,
}

export type RaidCycle = {
    phase: "Protected" | "Open" | "RetryShield",
    remainingSeconds: number,   -- active-server time; bounded by phase config
}

export type PlayerProfile = {
    schemaVersion: number,       -- current version constant; migrate on load
    revision: number,            -- increases on every committed durable mutation
    createdAtUnix: number,
    lastSavedAtUnix: number,     -- diagnostic only; never grants offline income
    cash: number,                -- integer, 0..BalanceConfig.MAX_CASH
    incomeRemainder: number,     -- fractional cash, 0 <= value < 1
    exhibits: {[string]: Exhibit}, -- ItemId -> exactly one entitlement per type
    displaySlots: {[string]: string}, -- unlocked SlotId -> ItemId; occupied only
    accreditation: number,      -- 0..3, sequential tiers
    museumTier: number,          -- 1..5; migrated default 1
    museumStyleId: string,       -- allowlisted cosmetic architecture theme
    groundsUnlocks: {[string]: boolean}, -- earned landscaping IDs
    securityLoadout: {[string]: string},  -- allowlisted bounded device/guard anchors
    lifetime: Lifetime,
    tutorialStep: number,       -- bounded, monotonic onboarding step
    beginnerActiveSeconds: number, -- active play only; bounded/monotonic
    contracts: {Contract},      -- exactly three distinct active instances
    pinnedContractId: string?,  -- must reference an active instance
    activeRecoveryType: string?,-- must reference a Missing exhibit
    settings: Settings,
    cosmetics: {[string]: boolean}, -- earned/unlocked cosmetic IDs only
    premiumEntitlements: {[string]: boolean}, -- verified durable grants only
    processedReceiptIds: {[string]: boolean}, -- if repeatable products are enabled
    recentOperations: {[string]: Operation}, -- operationId -> terminal result
    operationOrder: {string},   -- oldest first, for bounded pruning
    raidCycle: RaidCycle,
}
```

**Initial record:** `schemaVersion` is the current constant, `revision = 0`, `cash = 100`, `incomeRemainder = 0`, empty `exhibits` and `displaySlots`, `accreditation = 0`, `museumTier = 1`, default style, empty grounds/security/premium maps, all lifetime counters zero, tutorial at its first step, `beginnerActiveSeconds = 0`, three server-assigned eligible contracts, no pinned contract or recovery target, volume settings at `1`, motion/effects flags `false`, empty cosmetics and operation ledger, and a `Protected` raid cycle with its configured duration. `createdAtUnix` and `lastSavedAtUnix` use the server clock. A tutorial toaster is registered only after its confirmed first delivery. These new museum and premium fields are a **target migration**, not fields in the current Task 8 profile code.

**Slot IDs:** `protected` is always unlocked and earns 50%. Target tier 1 unlocks `exposed_01` and `exposed_02`; accreditation can unlock through `exposed_19` for a 20-stand upper bound, while the physical museum tier may have fewer anchors. Existing profiles may have an item in `exposed_03`; migration moves that placement to storage without deleting its entitlement, then it can be displayed when a legal stand unlocks. Store occupied slots only. A missing item cannot appear in `displaySlots`; `previousSlotId` preserves its preferred place. No item ID may occupy two slots. `activeRecoveryType` is optional because multiple exhibits can be Missing with independent `recoveryJobsDone` values.

**Contract progress:** `definitionId` selects the requirement and reward from source definitions. `progress` stores only the allowed paths for that template, such as `npcDeliveries` and `pvpDeliveries` for Daring Run. Each path counts events since assignment and is capped at its requirement. Either completed path satisfies an OR contract. `claimed` instances are replaced immediately with new IDs, so the active array normally contains three unclaimed instances. Claim and replacement occur in one profile mutation. For exact replay safety, its operation result remains in `recentOperations` until its retention rule permits pruning.

**Operation IDs:** use server-generated IDs for run, raid, and recovery actions; client `requestId` values are only retry keys scoped to the current player session and action. Persist terminal results for all valuable mutations. Keep `recentOperations` and `operationOrder` synchronized; prune oldest terminal entries only after a documented retry horizon and a durable state check that prevents reapplying stale actions. Never prune an unresolved commit. An uncertain write is reconciled using the same ID before any new result is issued.

**Migration and purchases:** introduce the museum fields in a new schema version with deterministic defaults for every existing profile, then validate old fixtures and profiles with occupied slots before changing the live store. Server-owned plot instance IDs are never saved. Any repeatable paid product needs a durable receipt key coupled atomically to its grant; do not apply ordinary operation-ledger pruning to receipt IDs unless replay safety is proven. If this cannot be bounded safely, keep developer products disabled and use verified one-time passes only.

**Not persisted:** current carry/pickup, pedestal stock, guard AI, player plot assignment and clone instance, active raid reservation, target/position history, income settlement clock, shove/dash/sprint cooldowns, and trophy display/timer. These are server-session records. The temporary trophy is explicitly lost on server exit or crash. At profile load, start the income clock at the current server time; do not pay for elapsed wall time since `lastSavedAtUnix`.

### 14.3 Reference data and server-session records

| Record | Key and required fields | Storage and rule |
|---|---|---|
| Item definition | `itemId`, name, tier, carry behavior, base income/min, optional shop price, depot weight, asset reference | `src/shared/ItemCatalog.luau`; exact 12 IDs from §6.2; immutable during a live run |
| Contract definition | `definitionId`, requirement paths/counts, cash reward, eligibility rule | `src/shared/ContractDefinitions.luau`; exact six templates from §9 |
| Upgrade definition | `upgradeId`, sequence, cost, requirement alternatives, unlocked slot IDs, cosmetic reward | `src/shared/UpgradeDefinitions.luau`; exact three tiers from §6.3 |
| Museum tier/template | tier ID, footprint, module/anchor manifest, stand capacity, allowed styles | versioned authored asset plus server-validated definitions; no client authority |
| Plot assignment | plot ID, owner UserId, clone instance, reservation state | server memory; six maximum envelopes, released on leave/load failure |
| Security definition | device/guard ID, allowed anchors, budget cost, counter paths | server allowlist; functional options earnable |
| Balance/flags | named tuning values, currency cap, timings, feature defaults | versioned server config for authority; replicate only UI-safe values |
| Depot stock | pedestal ID, item ID, restock/rotation deadlines, optional pickup reservation | server memory; fresh after server restart |
| Run/carry | run ID, source, item ID, carrier UserId, target/owner if PvP, start/deadline, state | server memory; at most one per player |
| Raid | raid ID, owner/thief IDs, museum ID, target item/slot, stage, deadline, commit state | server memory; one active reservation per museum |
| Trophy | thief ID, item ID, earned income, active-time expiration | server memory; one per thief, no permanent entitlement |
| Pair reward limit | unordered pair of UserIds, last rewarded server time | server memory; ten-minute limit, resets with server |

There is no global SQL-style index in the MVP. Lookups use the player key and in-memory IDs within one server. Do not create OrderedDataStores or cross-server locks for leaderboards or stock that the design does not need. A paid game pass is checked through Roblox ownership APIs; the `cosmetics` map does not manufacture that entitlement. Server-owned clone and plot records are recreated each session from the saved tier and configuration.

### 14.4 Save policy

- Load successfully and acquire exclusive session ownership before granting gameplay access.
- If loading fails, keep the player in a safe loading state with retry/leave guidance. Never create a fresh profile merely because a read failed.
- New-user defaults require a confirmed absent record, not an exception.
- Use an established, reviewed session-locking approach or implement a lease with stale-lock handling and tested release semantics.
- Serialize writes per profile. Use UpdateAsync appropriately; its transform can retry, so it must not grant rewards, emit one-time events, or yield as a side effect.
- Autosave dirty profiles at a staggered starting interval of 60 seconds, adapting to platform budgets. Save meaningful committed purchases, registration, theft loss, and recovery progress durably before confirming them.
- Coalesce routine income; do not write every second. A crash may lose up to the unsaved income interval, which must be measured and minimized under budget.
- On leave/shutdown, attempt bounded save/release. Shutdown callbacks are a best effort, never the only persistence strategy.
- Track save failures, retry with backoff and jitter, and temporarily disable valuable mutations when profile durability is uncertain.
- Migrate schema versions deterministically. Back up and test migration against fixture copies, including older and partially populated records.

### 14.5 Why PvP does not need a two-player permanent transfer

The owner’s permanent item is never transferred to the thief. Only the owner’s Available → Missing transition is durable. The thief receives a **session-only** trophy, preventing a two-profile atomic ownership transfer requirement in MVP.

Resolution order:

1. Atomically within server logic, move raid to Committing and prevent competing terminal actions.
2. Settle owner income and build an operation with unique raid ID.
3. Through the profile’s serialized mutation queue, persist the Missing state, slot removal, recovery record, and operation result together.
4. On a confirmed repeat operation ID, reuse its result instead of mutating again.
5. After durable success, update visible owner state and award temporary trophy if the thief is still present. Otherwise no trophy is created.
6. Release reservation, begin post-theft shield, and emit confirmed analytics.

**Explicit limitation:** a crash between steps 3 and 5 can leave the owner Missing without a surviving trophy. The owner’s collection rights and recovery remain intact. Do not claim cross-profile atomicity or guaranteed trophy delivery. If persistent trophies are added later, design and test a durable transaction/outbox system first.

Operation records must remain long enough to cover all valid retries; bound storage by a documented retention horizon and never prune an unresolved operation. Reject stale request IDs after their valid session/action lifecycle. Tests must demonstrate that pruning cannot replay an old purchase or recovery claim.

### 14.6 Recovery and abuse safeguards

No client grants currency. No client chooses income values. No datastore write trusts client-owned model attributes. Validate finite numeric values to reject NaN/infinity. Clamp legitimate quantities to business bounds, but reject malformed transaction inputs rather than silently turning them into a different purchase.

Keep an operational record of critical failure categories with operation IDs, not private personal data. Administrative repair commands are server-only, permission checked, auditable, and disabled outside authorized operators. Never expose a public “give cash” remote.

## 15. Monetization

Launch gameplay must work completely without payment. If purchase implementation would delay a stable release, launch the first test with monetization disabled.

Ride to depot, the speed coil, extra NPC carry slots, and the player scanner use **earned in-game cash**, not Robux. They affect travel or competitive information and must remain available to all players through ordinary play. Default carry capacity is one and default map view hides other players. Players start with normal movement and one carry slot; every ability is visible with its exact effect before it is affordable. Task 20 adds the speed coil and permanent ride unlock, priced by purchase order at a provisional $1,000 then $2,200. Task 27 adds second/third NPC slots at a provisional $6,500/$17,000 and a player scanner with a $3,200 unlock plus $100 per five-second scan and a 45-second cooldown. Prices are set so the median player reaches them at about 20–30 min, 45–75 min, 90–150 min, 2–3 h, and 4–6 h of cumulative active play, after other expected purchases. The development plan's 14 October section records the formula and model assumptions; re-derive the prices from measured earnings before release. Scouting stays part of the heist: no long-range owner marker, a security light near each property, and a short visible departure grace before an empty museum opens.

Candidate offers are premium architecture skins, guard appearances, visual effects, landscaping styles, building upgrade shortcuts, and limited defensive sidegrades. Ordinary play must be able to reach every functional museum tier, security budget, and raider counter. A paid shortcut may reduce construction time or earned-cash cost but cannot skip tier order or exceed a tier's cap. A paid defense may differ in presentation or tradeoffs, but uses the same slot/budget limits and has an earnable equivalent or reliable earnable counter. No offer may make a museum practically impossible to rob; test the strongest paid configuration against free loadouts at realistic latency. Task 37 reviews each offer and may choose a cosmetic-only first test. Choose prices only after testing; this document does not forecast conversion or revenue.

Use Roblox-supported purchase flows and verify ownership server-side. A client purchase prompt completion is not sufficient proof for a grant. One-time passes use server-side ownership checks; any repeatable developer product requires confirmed receipt processing, an allowlisted product ID, and a durable receipt/grant record before acknowledgement. Duplicate callbacks and rejoin must produce one entitlement. Keep offers disabled until Task 38 passes failure, duplicate, and fairness tests. Never add paid randomized rewards as an incidental shortcut. See the current [Roblox pass](https://create.roblox.com/docs/production/monetization/passes) and [developer product](https://create.roblox.com/docs/production/monetization/developer-products) documentation when implementing.

Keep the shop accessible but nonintrusive. No fake countdowns, misleading scarcity, or prompts immediately after a loss. Describe cosmetic contents precisely and preview them. Record marketplace IDs in environment config after the owner creates the products.

## 16. Performance, compatibility, and resilience

Initial targets are engineering goals to validate on named test devices, not guarantees:

- Smooth play around 30 FPS on the selected lower-end mobile test device with six players and all displays occupied; aim for 60 FPS on midrange desktop.
- No sustained hitch during pickup, delivery, save, or a burst of effects.
- Essential UI works in supported portrait/landscape behavior chosen for the experience, tablet, desktop, and controller layouts. Prefer landscape for gameplay; verify platform orientation configuration.
- Minimize startup downloads. Preload critical UI and carry feedback; do not block entry on every decorative asset.
- Limit effects by distance and quality setting. Pool frequently reused effects if profiling demonstrates churn.
- Use event-driven logic and bounded update loops. Do not run per-frame datastore, pathfinding, or all-player/all-object scans.
- Test at 100–250 ms latency and packet delay. Present pending states without granting unconfirmed success.
- Missing audio/animation/thumbnail assets never block gameplay.
- Clean all connections, reservations, carry objects, and UI references on respawn, leave, and plot reuse.

Record device model, graphics setting, player count, memory, frame timing, and server timing during tests. Optimize measured bottlenecks rather than a guessed polygon count.

## 17. Analytics and product validation

### 17.1 Events

Use platform analytics with a small stable schema. Confirm current limits and supported API signatures in official documentation. Do not collect external contact details or unnecessary personal data.

| Event / funnel step | Useful properties |
|---|---|
| ProfileReady / TutorialStep | step, platform class, experience version |
| PickupStarted / RunEnded | source NPC/PvP/recovery, item type, result reason, duration bucket |
| DeliveryCommitted | source, carry behavior, first-delivery flag, museum tier bucket |
| RaidStarted / RaidResolved | outcome, disconnect category, duration bucket |
| RecoveryStarted / RecoveryCompleted | item tier, active-work duration, jobs completed |
| ExhibitPlaced | protected/exposed, registered count bucket |
| ContractClaimed / UpgradeBought | definition ID, progression stage |
| MuseumTierBought / PlotRebuilt | tier, rebuild result, occupied-slot bucket |
| SecurityTriggered / CounterUsed | setup ID, warning/counter outcome, tier bucket |
| SaveFailure / TransactionUncertain | category, retry count bucket, server version |
| CosmeticViewed / PurchaseConfirmed | product ID, placement/source |

Use logs for detailed debugging and analytics for aggregated behavior; do not send unrestricted unique IDs as high-cardinality dashboard dimensions.

### 17.2 Questions before scaling marketing

- Can an unfamiliar player describe the goal after one minute?
- How many loaded new players reach first delivery and first active exhibit?
- Where do tutorial exits occur, and is it confusion or a technical fault?
- Do mobile players complete heists at a reasonable rate compared with desktop?
- Do players voluntarily start a second run?
- After losing an exhibit, do they understand recovery and choose to continue?
- Are victims disproportionately new players? Are a few pairs farming heists?
- Does the third session still have a clear goal?
- Are users returning because the gameplay is fun, or only because they fear losing progress?

### 17.3 Initial decision gates

Internal hypotheses, not industry benchmarks: aim for at least 80% first-delivery completion among successfully loaded fresh playtesters, median first delivery under three minutes, and at least 60% voluntarily starting another run during an unprompted short test. Begin with 10–20 observed testers to find usability problems; that sample cannot forecast mass-market success.

Track D1/D7 retention and session length by acquisition source after a real soft launch. Do not invent a universal “good” threshold or infer 100k concurrent players from a tiny cohort. Set a scale-up target after establishing a baseline. Approval rating must be reported with vote count and date; it is not a substitute for active player or retention data.

## 18. QA and launch acceptance

### 18.1 Critical tests: block launch on failure

| ID | Scenario | Pass condition |
|---|---|---|
| Q01 | New player joins empty server | Assigned plot, tutorial, valid NPC loop without another human |
| Q02 | Six players join simultaneously | Unique plots, no duplicate starter rewards |
| Q03 | Data load errors | No blank overwrite; clear safe retry state |
| Q04 | Same account/session overlap | One writable profile owner |
| Q05 | Rejoin at every tutorial step | Correct resume; no duplicate cash/item |
| Q06 | Two players finish same pedestal pickup | Exactly one valid carry |
| Q07 | Pickup canceled by range/line of sight | Reservation released, no hidden carry |
| Q08 | Each carry behavior on all routes | Winnable and readable; no camera/collision obstruction |
| Q09 | Guard loses sight/captures | Correct state transition and cleanup |
| Q10 | Repeated delivery callback | One registration/salvage reward |
| Q11 | Duplicate catalog acquisition | Advertised salvage only; no second entitlement |
| Q12 | Same purchase submitted repeatedly | One spend and one result |
| Q13 | Insufficient balance/malformed values | Rejected without mutation |
| Q14 | Income during slot/state transitions | No overlap or double accrual |
| Q15 | Protected slot raid attempt | Always rejected server-side |
| Q16 | Open window closes mid-carry | Existing raid can finish before deadline |
| Q17 | Two raiders target same museum | One active reservation |
| Q18 | Arrangement/storage during raid | No disappearing target or safe-storage bypass |
| Q19 | Owner shove / immunity | Valid cancel; no chain stun or unrelated interference |
| Q20 | Owner/thief leave before commit | Returned state, no reward, no leaked reservation |
| Q21 | Leave during commit | Operation reconciles once; no opposite terminal result |
| Q22 | Owner write fails or response lost | Definite failure vs unknown handled distinctly |
| Q23 | Crash before/after durable theft write | Collection rights preserved; documented trophy limitation only |
| Q24 | Recovery reconnect after each parcel | Saved progress preserved; restore exactly once |
| Q25 | Reacquire missing object | Restore same entitlement; no salvage/duplicate |
| Q26 | Repeated pair farming | Cooldown applies and UI explains rejection |
| Q27 | Respawn/reset/drop/timeout | All carry and raid states cleaned |
| Q28 | Remote spam/spoofed IDs/NaN | Rate-limited or rejected; server remains stable |
| Q29 | Dash/teleport-style invalid delivery | No wall bypass or impossible reward grant |
| Q30 | Premium entitlement verification | No grant from untrusted client event |
| Q31 | Old profile migration | Collection/cash preserved and schema valid |
| Q32 | Save budgets and shutdown | Bounded retries; no reliance only on shutdown |
| Q33 | Mobile/controller menus | All core actions usable; no blocked focus/buttons |
| Q34 | Audio muted / reduced motion | Warnings and mechanics remain understandable |
| Q35 | Asset load failure | Gameplay still functions |
| Q36 | Full-server prolonged play | Stable memory/connections; no growing stale state |
| Q37 | Six clone lifecycles and rejoin | Unique reserved envelopes, owner-only delivery, rebuilt exhibits, cleanup without stale ownership |
| Q38 | Tier expansion and migration | All five tiers fit, old profiles preserve collection/placement, size alone adds no income |
| Q39 | Security fairness and scaled routes | Every legal defense has an earnable counter; tier-five raid and carry routes remain winnable |
| Q40 | Paid grant replay and monetization-off | When enabled, one durable grant per receipt/pass survives rejoin and respects earned competitive caps; with offers off, no premium grant occurs |

Automate pure-state, economy, migration, and idempotency tests. Use multi-client integration tests for raids, input, networking, and persistence failure injection. Manual playtests remain necessary for feel, readability, art, sound, and mobile ergonomics.

### 18.2 Release checklist

- All critical tests pass; known noncritical issues documented.
- Original/license-cleared assets and valid published IDs.
- Current Creator Dashboard publishing/access requirements checked; maturity/content questionnaire answered accurately.
- Experience title, description, icon, screenshots, controls, and device support match actual build.
- Production/test environments separated; feature flags verified.
- Privacy-respecting analytics and error telemetry visible to owner.
- No developer commands exposed to ordinary users.
- PvP can be disabled independently while NPC gameplay remains live.
- Monetization can be disabled without breaking earned progression.
- Previous stable place version and migration rollback/forward-fix procedure documented.
- At least one owner/operator can inspect save failures and respond to serious issues.

## 19. Build order and deliverables

Do not commit to a calendar estimate until the developer has built the first graybox and measured asset/tooling constraints.

| Milestone | Deliverable | Exit condition |
|---|---|---|
| M0: Project setup | Typed structure, environment config, profile loader, input shell | Safe join/leave, test data isolation |
| M1: Vertical slice | One museum, toaster, depot, carry, delivery, display income | Stranger can complete a run; save/rejoin correct |
| M2: Complete NPC loop | Six reserved plots, clone lifecycle, guard, two routes, three behaviors | Works with one and six players, no cross-player delivery |
| M3: Lasting progression | Catalog, five museum tiers, grounds, shop, slots, accreditation, contracts | Economy, migration, and duplicate rules verified |
| M4: Recovery-first PvP | Raid state machine, windows, bounded security/counters, recovery, disconnect rules | Critical raid/persistence/fairness tests pass |
| M5: Presentation | All 12 objects, UI, animation, audio, VFX, accessibility | Readable complete loop on target devices |
| M6: Soft-launch preparation | Analytics, flags, marketing assets, reviewed optional offers and fulfillment | Release checklist passes |
| M7: Limited public test | Real sessions, usability observations, fixes | Evidence supports broader promotion |

For each milestone, the AI developer must provide: changed files, setup instructions, completed acceptance checks, known limitations, required human-created asset/product IDs, and a short playable test script. A stub or placeholder must not be reported as a completed feature.

### 19.1 First implementation task for the AI developer

Read this entire specification and the current 40-task plan. The M0–M1 toaster prototype code exists; Task 9's pure tier-only income check passes, and Task 10's guided handoff is implemented. Complete the remaining physical device and unfamiliar-player checks before the vertical slice gate. Keep tuning values in BalanceConfig. Demonstrate that duplicate delivery requests cannot duplicate registration or rewards. Begin six-plot template work at Task 11, after the vertical slice gate; defer PvP, paid products, free-form construction, trading, and finished catalog art until their stages.

## 20. Launch and marketing plan

The intended channels are developer journey posts, short gameplay clips, update posts, and invited YouTubers testing the game. Product footage should carry the pitch: “I tried stealing a giant golden toilet and barely made it home.”

- Record clips during real tests: first carry surprise, close escape, successful defense, recovery, and museum before/after.
- Use a thumbnail with one readable object, a visible chase, and the museum destination. Avoid impossible rewards or fake UI.
- Prepare a one-paragraph creator brief: premise, controls, what makes a run funny, test access, known limitations, and optional challenge prompts.
- Suggested challenges: “Deliver one of each carry type,” “Build a museum without buying exhibits,” and “Can you defend your golden toilet?”
- Contact creators only with the project owner’s authorization. No outreach is performed by this specification.
- Use supported share-link attribution to compare traffic sources. Inspect retention and tutorial completion for each source before paying for larger acquisition.
- Do not add a complicated creator mode for launch. Ordinary test servers and a simple challenge checklist are sufficient.
- Publish updates with visible gameplay improvements; do not promise daily content a solo developer cannot maintain.

## 21. Expansion roadmap

The 13 October owner direction moves three small cosmetic collection sets, a player-selected pinned next goal, delivery payoff, and a permanent non-ownership heist scrapbook into launch scope. Set completion depends on first permanent registration and survives theft; the temporary stolen trophy still expires. Every confirmed delivery may advance several eligible requirements. [development plan.md](development%20plan.md) defines the launch task gates, including Task 11b before Task 12; [post-launch-updates.md](post-launch-updates.md) is the working checklist for later updates.

Expand only after fixing observed weaknesses in the core loop. Museum-named releases must use verified real objects, sourced artifact facts, documented model/reference rights, and earned-cash direct prices reviewed against acquisition difficulty. Museum names are update themes, not claims of endorsement.

| Priority | Expansion | Reason to build / trigger |
|---|---|---|
| 1 | One qualified referral reward after platform eligibility; reuse the launch invite entry point | Ordinary friend raids are enjoyable; first-heist and return data can be measured |
| 2 | Practice-replica Museum Challenge with role swap and capped cosmetics | Friends want a direct shared activity without permanent collection loss |
| 3 | Daily ordinary-heist job, pausing seven-visit track, then 3/4 qualified referral cosmetics | Return behavior and referral abuse checks support the additions |
| 4 | Saved guaranteed acquisition path for selected rare items | Testing shows rare stock waiting causes frustration |
| 5 | Catalog categories and deliberately expensive earned direct purchases | Search remains viable and time-to-earn is measured |
| 6 | Updates named after real museums with verified collection pieces and sourced object facts | Current catalog is exhausted; rights and model scope are reviewed |
| 7 | Rotating heist conditions, cooperative depot jobs, themed deliveries, earned museum customization | Each addition improves a player decision or shared goal and passes route/performance tests |
| 8 | Persistent trophy ownership/history or raid escrow | Only if disconnect cancellation materially harms play and transaction design is reviewed |

Do not introduce trading or permanent stolen ownership casually. They change the risk, economy, moderation, and persistence model and require a new design review.

## 22. Traceability: the 30 agreed changes

This list preserves the earlier concept while showing what launches and what waits.

| # | Change from the reference concept | Delivery in this specification |
|---:|---|---|
| 1 | Original absurd valuables | MVP: 12 original object types |
| 2 | Museums instead of generic bases | MVP: exhibits, curator, museum identity |
| 3 | Fixed acquisition locations | MVP: one depot; more locations later |
| 4 | NPC targets for low population | MVP: guard and three public pedestals |
| 5 | Catalog explains acquisition | MVP: source/rarity/behavior entries |
| 6 | Ordinary earned-cash shop | MVP: four deterministic items |
| 7 | Heavy, noisy, bouncy carrying | MVP: three reusable behaviors |
| 8 | Funny readable carry presentation | MVP: attachment poses and camera-safe bounds |
| 9 | Short exposed vs long covered route | MVP: two routes |
| 10 | Visible pickup warning | MVP: 1.25-sec hold and owner alert |
| 11 | One carried prize | MVP: authoritative CarryService rule |
| 12 | Receiving stand completes theft | MVP: server-validated home delivery |
| 13 | Permanent legitimate registration | MVP: catalog entitlement survives theft |
| 14 | Recoverable stolen exhibits | MVP: three saved courier jobs |
| 15 | Temporary stolen trophies | MVP: one session-only ten-minute trophy |
| 16 | Protected display with lower income | MVP: one 50% income slot |
| 17 | Visible automatic raid windows | MVP: 90-sec shield / 60-sec open defaults |
| 18 | Prevent theft pile-ons | MVP: one raid per museum, post-result shield |
| 19 | Beginner safety | MVP: tutorial plus delivery/time protection |
| 20 | Explicit disconnect/offline rules | MVP: no offline raids; cancel pre-commit; reconcile commit |
| 21 | Accreditation instead of wipe rebirth | MVP: three permanent upgrades |
| 22 | Flexible progression requirements | MVP: ordinary deliveries or collection alternatives |
| 23 | Repeatable contracts | MVP: six templates, three active |
| 24 | Commons remain useful | MVP: income/salvage/contracts plus the cosmetic Everyday Treasures registration set |
| 25 | Earnable competitive tools | MVP: every functional tier/security budget and raid counter is earnable; paid sidegrades stay inside tested caps |
| 26 | Stun immunity | MVP: bounded stun plus immunity |
| 27 | Repeatable activity between events | MVP: recurring depot restocks and recovery jobs |
| 28 | Cooperative NPC heists | Later: separate individual rewards |
| 29 | Creator challenges | Later: private configuration, isolated rewards |
| 30 | Community-selected themes | Later: vote among feasible options |

## 23. Evidence, assumptions, and references

The source game provides a reference for acquisition, passive income, visible wealth, raiding, and progression. This specification is an original proposed implementation, not a claim about its latest exact mechanics. Player discussions are anecdotal evidence of possible frustrations, not a representative survey. Claims that all users hated a particular rebirth version should not be treated as established fact.

The main design hypotheses are that recoverable losses, readable defense, repeatable NPC activities, and funny carry behavior can support enjoyment and retention. Test these directly; preserving a popular game’s broad loop does not guarantee its audience.

### Gameplay and feedback context

- [Steal a Brainrot — official Roblox experience](https://www.roblox.com/games/109983668079237/Steal-a-Brainrot)
- [Community description of stealing mechanics](https://stealabrainrot.wiki/wiki/stealing/) — unofficial; verify any competitor-specific detail before quoting it publicly.
- [Community description of rebirth](https://stealabrainrot.wiki/wiki/rebirth/) — unofficial and potentially version-dependent.
- [Player discussion: frustration with gameplay](https://www.reddit.com/r/roblox/comments/1rc4vgt/steal_a_brainrot_is_not_fun/) — anecdotal feedback, not population estimates.
- [Player discussion: activity and progression complaints](https://www.reddit.com/r/stealabrainrot/comments/1tibt7p/60k_players_on_sab_earlier_the_game_is_dying/) — use comments as hypotheses to investigate, not verified engagement statistics.

### Official implementation references

Reference list reviewed during the 12 October 2026 revision. Recheck exact API signatures, limits, and publishing requirements when implementing.

- [Client-server boundary and validation](https://create.roblox.com/docs/scripting/security/client-server-boundary)
- [Server-side detection](https://create.roblox.com/docs/scripting/security/server-side-detection)
- [Data stores](https://create.roblox.com/docs/cloud-services/data-stores)
- [Player data and purchasing](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing)
- [GlobalDataStore API](https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore)
- [Data store limits and errors](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
- [Data store versioning and caching](https://create.roblox.com/docs/cloud-services/data-stores/versioning-listing-and-caching)
- [Analytics event types](https://create.roblox.com/docs/production/analytics/event-types)
- [Funnel events](https://create.roblox.com/docs/production/analytics/funnel-events)
- [Retention analytics](https://create.roblox.com/docs/production/analytics/retention)
- [Acquisition analytics](https://create.roblox.com/docs/production/analytics/acquisition)
- [Publishing experiences](https://create.roblox.com/docs/production/publishing/publish-games-and-places)

## 24. Definition of done

The MVP is done when a new player on a supported phone can join a safe loaded profile, understand the objective and a chosen pinned next goal, steal an NPC object, escape, see its confirmed delivery payoff, display it, earn money, pursue three registration-based cosmetic sets, grow an owned museum through valid tiers, participate in a clearly explained optional museum raid with earned security/counterplay, retain a non-ownership heist achievement, recover an exhibit after loss, and rejoin with the museum and collection intact—and all critical persistence, fairness, and abuse tests pass.

It is not done because all scripts exist, because a single developer can play it in Studio, or because its feature count resembles a popular game. The release must work for unfamiliar players under real multiplayer conditions.
