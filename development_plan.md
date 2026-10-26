# Steal Anything! — Step-by-Step Development Plan

> **CURRENT REVISION — 21 October 2026: 40 numbered tasks; additions and revisions to Tasks 1–12 are scheduled only after Task 12.** Post-launch work is in a separate file.

**Source of truth:** The owner's museum expansion brief (12 October 2026) overrides conflicting older rules. [Steal_Anything_MVP_Game_Design.md](Steal_Anything_MVP_Game_Design.md) is updated to match it.  
**Status:** This plan has **40 consecutively numbered tasks**: the original 36 plus four new implementation stages. The owner confirms Tasks 1–12 complete, including Task 6 input and Task 12 real-player multiplayer, delivery, and matchmaking checks (21 October 2026). Post-Task-12 follow-up A is complete by owner confirmation of the saved-place/Rojo persistence check; follow-up B has a working implementation but remains open pending its remaining acceptance checks. Exact devices and individual Task 12 edge-case results were not supplied with that confirmation; record those separately without reopening the completed tasks.  
**Platform:** Roblox, with typed Luau and the source layout in design §13.2.

## How to use this plan

Work through numbered Tasks 1–12 in order. Complete Task 12 and its exit check before starting either post-Task-12 follow-up or Task 13. Then complete the post-Task-12 follow-ups below before Task 13, and continue the numbered tasks in order. Keep the game playable after the first vertical slice. A task is complete only when its behavior works in Studio, its relevant checks pass, and its result is recorded. A script stub, UI mockup, or untested happy path does not count. After launch, use [post_launch_updates.md](post_launch_updates.md) rather than returning to this file for update steps.

For each task, record: changed files, how to run it, test results, known limitations, and any IDs/assets the owner still needs to supply. Mark its checkbox only after the exit check passes. If a design rule changes, update the design document and this plan together. Do not begin a later milestone to work around a failing gate.

**Authority rule:** The owner's 12 October museum expansion brief takes precedence wherever it conflicts with the earlier design or completed prototype. The updated game-design document defines behavior and scope; this plan defines order and acceptance. Check current Roblox documentation for exact APIs during implementation.

**13 October progression decision:** Preserve the 40-task sequence and its completion history. Add the launch requirements below to the relevant unfinished tasks. The order within those tasks is: (1) one player-pinned next goal, (2) clear delivery payoff, (3) three small permanent-registration sets, (4) lasting heist milestones, and (5) a guaranteed rare-acquisition path only if limited-test evidence shows frustrating spawn waits. The first four are launch gates; the fifth is conditional and can ship later. A successful delivery can advance several goals at once without introducing another currency.

**19 October first-session pacing addition:** Use the existing heist, delivery, collection, contract, and shop loop to make each confirmed delivery feel valuable and make the next robbery appealing. The proposed observation targets are first steal by 1:30, first lasting delivery reward by 2:30, a normal depot challenge by 5:00, a visible small improvement by 8:00, and a chosen next goal by 10:00. These are playtest hypotheses, not achieved timings or fixed time gates. Measure actual routes on the six-plot map and revise the targets from observed players. Keep the existing ability and capacity milestones; do not add a reward currency or personalized odds, prices, or payouts.

## 14 October owner decisions — scouting, abilities, and pricing

These rules override the earlier ability prices and refine raid scouting. Each item is placed in the task that owns it below.

**Scouting is part of the heist.** From far away there is no automatic owner-location marker; players investigate. Near a property a security light shows whether the owner is home. When the owner leaves, the light changes and a short, visible departure grace period runs before the property can be entered. If a target is unavailable, other museums and NPC depot jobs remain worthwhile. A scanner bought with earned cash briefly reveals approximate player positions and saves scouting effort; it does not replace planning.

**Post-Task-12 PvP design decision (20 October; implement in Tasks 23–30):** A museum can be raided only while its owner and attacker are online in the same game server and all raid eligibility checks pass. An owner who is online but away from the museum may be raided; an offline owner may not. The later raid rules also allow an eligible owner who is home to defend during an open window. A thief whose raid already started keeps an open escape route; home/away transitions must never trap them. The existing owner-home visitor barrier and security light remain Task 12 staging only; change their PvP meaning in Tasks 24–27, after Task 12 passes.

**Abilities are earned conveniences.** Players start with normal movement and one carry slot, enough to complete the whole basic loop. All upgrades are visible from the start, with exact effects, before the player can afford them. No upgrade removes the challenge:

| Ability | At start? | Why earn it | Challenge it keeps |
| --- | --- | --- | --- |
| Normal movement + one carry slot | Yes | Completes the basic loop | — |
| Speed coil | No; early purchase | First noticeable convenience | Carrying penalties are unchanged |
| Depot ride (teleport) | No; early alternative to speed | A choice about how to spend savings | You still escape with the prize |
| Extra carry capacity | No; later purchase | Bigger, more profitable NPC trips | Guards and carry restrictions still apply |
| Scanner | No; after learning PvP | Information once players know why it matters | The player still executes the theft |

**Pricing method.** Prices come from target saving times and the prices of everything else the player is expected to buy. The rule is price ≈ typical earnings by the target time − spending on other expected purchases before then. Use one published price for everyone, set from the **median** (average) player's earnings curve, because individual players progress at different speeds. Because income grows, prices follow the earnings curve rather than a flat dollar rate. Early, cheap purchases take more minutes per dollar; later, expensive ones take fewer minutes per dollar. These are tuning targets, not time locks; progress carries across sessions.

| Milestone | Target cumulative active playtime | Provisional price | Modeled fast / typical / slow |
| --- | --- | ---: | --- |
| First small museum improvement | 5–10 min | Existing $180–$340 shop commons | — |
| First ability: speed coil **or** depot ride | 20–30 min | **$1,000** | 19 / 23 / 27 min |
| Second ability: the other one | 45–75 min | **$2,200** | 47 / 57 / 66 min |
| Second carry slot | 90–150 min | **$6,500** | 104 / 115 / 127 min |
| Scanner | 2–3 h | **$3,200** unlock + **$100** per scan | 133 / 147 / 163 min |
| Third carry slot | 4–6 h | **$17,000** | 259 / 288 / 316 min |

The two movement abilities are priced **by purchase order**: whichever the player buys first costs $1,000 and the remaining one costs $2,200. This keeps a real choice at 20–30 minutes without letting the second follow a few minutes later. The scan fee is about 30 seconds of modeled income at that stage.

*How the provisional numbers were made:* a 400-run simulation of the current catalog, weights, salvage, and protected-slot rule. Assumptions: a typical NPC delivery cycle of 3 minutes (2 fast, 4.5 slow); $35 average contract cash per delivery; the toaster stays protected; the best items fill the two exposed stands until a six-stand museum at about 90 minutes. The other expected spending is a $220 shop common around 8 min, Local Attraction $1,200 around 40 min, a **placeholder** tier-2 building $2,500 around 85 min, Town Landmark $4,000 around 130 min, a **placeholder** tier-3 building $6,000 around 200 min, and Grand Collection $10,000 around 240 min. Each ability takes 85% of the cash remaining at its target time, since players hold some cash.

*Re-tune before release:* (1) once Tasks 13–16 make delivery time real and Task 19 sets building prices, record the median cumulative earned cash per active minute in a limited test; (2) recompute every price with the same formula; (3) check that fast and slow players stay inside or near each window; and (4) always leave a worthwhile smaller goal, such as an exhibit, contract, or museum improvement, while saving for an expensive one. Do not simply multiply every price. Do not use the toaster's $6/minute alone: income grows quickly, and a $300 ability would take 7.5 minutes at $40/minute.

**Built on 14 October (Task 12 source, still needs a Studio Play check):**
- The original museum and every cloned museum have double entrance doors (`MuseumDoors.luau`). Every 30–90 seconds the server picks a new state: both open, one open, or both closed. A leaf never swings shut on someone in the doorway. When both are closed, anyone nearby can open them with Roblox's **default** ProximityPrompt; the game's custom interaction HUD ignores prompts tagged `DefaultPromptStyle`.
- The six-museum depot's shuttle stop back to the original museum was buried under the raised depot platform. Both stops now rest on their real surface with a neon pad, a glow disk, and a `SHUTTLE to …` sign.
- The menu's character preview can play emotes. The owner adds ten animation IDs to `src/client/MenuEmoteConfig.luau`. Every 120 seconds the preview plays one once in a shuffled, no-repeat order, then returns to a still pose facing forward.
- Each owned museum has a roof security light with a status sign: red `OWNER HOME — SECURED`, amber `OWNER LEFT — OPENS IN Ns` during a 10-second departure grace, and teal `OWNER AWAY`. The visitor barrier stays up through the grace period.

## Museum expansion revision — read before the task list

**The game direction is museum building, collecting, upgrading, and raiding.** Each player gets a server-cloned museum reconstructed from their saved tier, configuration, and exhibits. Six fixed plot slots reserve the maximum property area before anyone joins. The building grows through authored modules and predefined tiers, never unrestricted resizing. Functional security and raider counters are earnable. Robux can offer architecture, appearances, landscaping, construction shortcuts, and limited defensive sidegrades only within tested caps and with a nonpaid counterplay route.

| Tier | Museum | Building footprint | Exhibit stands | Used plot footprint |
| --- | --- | ---: | ---: | ---: |
| 1 | Starter | 60 × 60 studs | **3** | 120 × 120 studs |
| 2 | Growing | 80 × 80 studs | 6 | 160 × 160 studs |
| 3 | Expanded | 110 × 110 studs | 10 | 200 × 200 studs |
| 4 | Prestigious | 140 × 140 studs | 15 | 240 × 240 studs |
| 5 | Grand | 170 × 170 studs | 20 | 280 × 280 studs |

These are proposed targets requiring route, avatar, camera, and largest-object tests. The current 36 × 30-stud museum and its four unlocked slots are a **prototype**, not the future tier-1 specification. Migration must preserve any existing `exposed_03` placement as a registered item in storage until a legal stand is available. One permanent entitlement per item type remains; the launch catalog has 12 types, so eight of the 20 top-tier stands cannot hold distinct registered objects until the catalog expands. Six maximum plots need 470,400 square studs before roads and public space; roughly 1,000 × 750 studs is a planning estimate, not a final map measurement.

**Fairness rule:** More stands and security come with a more visible, attractive museum and more tested approaches for raiders. Start with up to two guards, one sensor, and one shared-cooldown defense pad; test whether a third guard can be fair before allowing it. Prestige hints may reveal tier and rough collection value, never the private item list. Sprint with stamina and earnable counter-abilities must keep long routes and raids viable. Re-measure the old 45-second raid limit on the expanded world. A paid defense cannot exceed the same placement/budget caps or remove every earned counter.

**Where the four tasks were added:** new Task 12 follows original Task 11 (dynamic lifecycle); new Task 19 follows original Task 17 (museum and grounds expansion); new Task 26 follows original Task 23 (security and counterplay); new Task 38 follows original Task 34 (purchase fulfillment and fairness). Every original task remains in order, renumbered after those insertions.

**Original tasks revised for the new direction:**

| Original | Now | Required change |
| ---: | ---: | --- |
| 2 | 2 | Tier, maximum plot, stand class, defense, speed, and purchase definitions |
| 3 | 3 | Profile schema/migration for tier, configuration, defenses, cosmetics, and old slots |
| 4 | 4 | Idempotent museum upgrades and durable paid entitlement rules |
| 5 | 5 | Turn the prototype museum into a reusable template with expansion anchors |
| 7 | 7 | Resolve personal tutorial targets after plot cloning |
| 8 | 8 | Accept delivery only at the player's assigned clone; rerun Q10/Q29 in Task 12 |
| 9 | 9 | Keep size-only income at zero and settle before display/tier changes |
| 11 | 11 | Reserve six maximum envelopes and build tier-1 template |
| 16 | 17 | Add large-object footprint classes; retain 12 unique launch types |
| 17 | 18 | Validate floor/room/stand compatibility and saved placements |
| 18 | 20 | Add earned building, grounds, defense, and movement offers |
| 19 | 21 | Keep accreditation separate from building tier and stand capacity |
| 22 | 24 | Apply protection/windows and security budgets to every tier |
| 23 | 25 | Validate tier-specific raid entrances, sensors, and guards |
| 24 | 27 | Add counters, guard interactions, sprint, and measured deadline |
| 28 | 31 | Make tiered modules, expanded exhibits, grounds, and security assets |
| 31 | 34 | Test streaming, replication, and six maximum-tier museums |
| 34 | 37 | Review premium architecture, shortcuts, defenses, and fairness |

**Post-Task-11 checkpoint (12 October 2026; historical):** Task 9's protected-display income, save/rejoin, and tier-only pure income check pass. The repaired prototype entrance was walked in Play mode. The owner verified Task 10 complete; Task 6's input check was still listed as open at that date and was later accepted by the owner on 21 October. The six maximum plot envelopes, starter template, tier/socket manifest, and Task 12 migration contract are recorded in `docs/task11-layout.md`. The tier system does not need early implementation; repeat the integrated income check at Task 19. Current `Workspace/Map` stays the playable Studio-authored prototype. Task 12 switches pickup, delivery, guide arrows, income placement, and raid ownership together, with Q10/Q29 rerun against cloned museums.

**Implementation timing:** The design and plan change now. The current toaster loop stays playable while tasks 10–12 prepare cloning; guards, five tier upgrades, and paid offers are built at their numbered stages, with their own tests. Completed prototype checks are not evidence that the new clone/tier/security behavior already works.

## M0 — Project foundation

**Goal:** A player can join, receive one safe writable profile, and leave without data loss. No gameplay is required yet.

### 1. Create the repository and Studio mapping

- [x] Create `default.project.json`, `src/shared`, `src/server`, `src/client`, `src/serverStorage`, `assets`, `tests`, and `docs` as described in design §13.2. Add a short `README.md` with local setup and Studio sync steps.
- **Exit check:** A blank place syncs successfully; a server bootstrap and client bootstrap each run once; no server-only module appears in replicated storage.

**Task 1 completed — 10 October 2026:** Git repository initialized. Added the four Rojo-owned source folders, both bootstraps, `default.project.json`, `rokit.toml`, `.gitignore`, and setup instructions in `README.md`. Rojo 7.7.1 built the project successfully. The owner confirmed the server and client bootstrap messages in Play mode. Read-only Studio inspection confirmed `Shared` under `ReplicatedStorage`, `Bootstrap` scripts in the intended server/client folders, `Assets` under `ServerStorage`, and no server-only script in `ReplicatedStorage`.

### 2. Add typed definitions and environment configuration

- [x] Add the profile types/defaults from design §14, the item/contract/upgrade definition modules, balance values, a fixed remote allowlist, and separate development/test versus production store names. Use placeholder asset IDs that are visibly marked as placeholders.
- **Exit check:** Every definition loads, IDs are unique, and a schema validation test accepts defaults and rejects invalid enums, nonfinite numbers, and duplicate exhibit placements.

**Task 2 completed — 10 October 2026:** Added the 12-item catalog, six contracts, three upgrades, balance values, fixed remote names, server-only environment/feature/asset configuration, typed profile defaults, and full profile validation. Rojo built the project, live sync placed the modules in Place1, and `tests/unit/Task2.spec.luau` passed in Studio Edit mode. The test covers definition loading, unique IDs, exact depot weight, valid defaults, invalid enums, nonfinite values, invalid contract progress, and duplicate exhibit placement. No datastore read or write occurs in this task.

**Post-Task-12 follow-up:** Record the completed tier/plot/stand definition audit after Task 12. Add the remaining upgrade, security, movement, and approved-purchase allowlists with Tasks 19, 26, and 38 as their rules are implemented. Keep the completed Task 2 result for the original schema; test each new definition as a versioned extension.

### 3. Implement profile load, session ownership, and migration

- [x] Build the `ProfileService` wrapper. Acquire exclusive writable ownership before gameplay, distinguish an absent record from a failed read, migrate old versions deterministically, and release safely on leave. Create fixture profiles for migration tests.
- **Exit check:** New join creates defaults; rejoin restores the same profile; concurrent sessions cannot both write; load failure leaves the player in a safe retry state. Covers Q03, Q04, Q31.

**Task 3 completed — 11 October 2026:** Added a metadata lease repository, profile service, version-0 migration, fixture profiles, and a visible safe loading/error state. Rojo builds; `tests/unit/Task3.spec.luau` passed against an injected store, covering new/rejoin, overlapping sessions, stale leases, read failures, uncertain writes, and migration. In the published Studio test place, a real development DataStore first join reached `Ready`, a competing repository was `Locked`, stopping Play cleared the lease, and rejoin retained cash 100 and the same three contract IDs. See `docs/profile-testing.md` for the test record and prelaunch multi-server checks.

**Expansion dependency:** Task 12 must add a new schema migration for museum tier, style, grounds, security, and verified entitlement fields. Existing profiles and slot placements must survive; plot assignment and clone identity stay out of the saved profile.

### 4. Add serialized writes and save failure handling

- [x] Queue mutations per profile, use idempotent operation IDs, autosave dirty profiles, and implement bounded retry/reconciliation. Provide an observable save-error state. Do not grant rewards inside a retryable datastore transform.
- **Exit check:** Repeated operation IDs return one result, simulated failed/uncertain writes do not create a blank overwrite, and leave/shutdown attempts a bounded save. Covers Q12, Q22, Q32 in foundation form.

**Task 4 completed — 11 October 2026:** Added a per-player write queue, server-issued operation IDs, durable terminal results, routine dirty staging and autosave, uncertain-write reconciliation, bounded leave/shutdown save attempts, and a visible `SaveError` state. Rojo built successfully. `tests/unit/Task4.spec.luau` passed in Studio with duplicate, concurrent, failed, and uncertain writes. The Task 3 suite passed again. Play mode loaded and rejoined the same development-store profile, released its lease on stop, and displayed the `SaveError` message when that state was simulated. See `docs/save-testing.md` for results and the API contract.

**Expansion dependency:** Apply the same serialized, idempotent rules to tier upgrades and layout changes at Task 19. Task 38 must keep paid receipt deduplication durable and separate from ordinary prunable operation history.

**M0 gate:** Two accounts can join and leave repeatedly with separate profiles; one account cannot acquire two writable sessions; a forced data error cannot erase progress. Do not start monetization or PvP.

## M1 — First playable NPC vertical slice

**Goal:** A stranger can get the tutorial toaster, bring it home, display it, earn cash, and rejoin with progress intact. Use simple graybox art.

### 5. Graybox one museum, depot pedestal, and two routes

- [x] Build one museum with spawn, receiving zone, protected display slot, recovery-console placeholder, a public route, and a covered route. Use stable socket IDs/tags and simple authoritative hitboxes.
- **Exit check:** From the reachable depot pickup edge, walk about 200 studs on the 18-stud-wide open route or 320 studs on the 14-stud-wide covered route, without a forced jump. Three turns and solid cover break plaza sightlines; the receiving pad and protected stand are visually distinct. Recheck both paths with the largest heavy object once carry exists.

**Task 5 finalized — 11 October 2026:** Updated the repository model and connected Studio scene to the measured one-museum layout. No-jump pathfinding from the accessible pickup edge measured 200.7 studs open and 320.4 studs covered; live character navigation reached the receiving pad by both routes. Three 14-stud-high cover walls blocked plaza-side rays. Eight tagged sockets retain stable IDs. The heavy-carry camera and collision check remains for Task 15, when the largest object exists. See `docs/map-testing.md` for layout, source ownership, and test results.

**Task 5 visual pass — 11 October 2026:** Added a museum façade and interior, layered exhibits, readable delivery and recovery signs, depot loading details, service-passage materials, open-route paving, landscaping, and fixed afternoon light. The template Baseplate was removed; the scenic apron has no collision. Player-height Studio views were inspected inside and outside. Post-art no-jump pathfinding measured 199.8 studs open and 320.5 studs covered; the eight socket IDs and three solid sightline walls remain intact. See `docs/map-testing.md`.

**Outdoor collision correction — 11 October 2026:** Made tree trunks and lower crowns, shrubs, planters, the depot bench, and crates solid. Moved props clear of the route lanes. Rays hit the expected solid parts, and no-jump pathfinding still succeeds at 2- and 4-stud agent radii. Current measured paths are 204.3 studs open and 320.5 studs covered for the 2-stud agent. See `docs/map-testing.md`.

**Four visual refinements — 11 October 2026:** Replaced exhibit slabs with framed stands, hid the cyan spawn pad, grouped varied trees near boundaries, layered the exterior walls, and calmed the grass and museum floor materials. Play still spawns in the museum; 2- and 4-stud no-jump agents traverse both routes. Latest path lengths are 205.2 studs open and 320.5 studs covered for the 2-stud agent. See `docs/map-testing.md`.

**Expansion dependency:** This single museum remains the prototype for a reusable, versioned starter template. Task 11 moves it into a cloneable asset with expansion anchors; Task 19 builds authored tier modules. The original 200/320-stud routes are prototype measurements only.

### 6. Build the minimal HUD and input shell

- [x] Show load state, current objective, cash, interaction prompt, carry destination, and result/error feedback. Wire keyboard, touch, and controller actions through one input controller.
- **Exit check:** The first objective is understandable on desktop and a phone-sized viewport; input never grants an item locally.

**Task 6 owner acceptance — 21 October 2026:** The owner confirms the input task was completed and tested. Earlier notes asking for the device/control details are a documentation gap, not an unfinished Task 6 implementation. Do not infer a specific physical device or controller model from this report.

### 7. Implement personal tutorial pickup and one active carry

- [x] Create a player-specific tutorial toaster run. Server validates target, hold time, distance, line of sight, and ownership; `CarryService` permits only one active item. Handle cancel, reset, death, and disconnect.
- **Exit check:** Two players can each take their own tutorial toaster; repeated pickup requests or reset cannot create a second carry. Covers Q05, Q07, Q27.

**Task 7 completed — 12 October 2026:** Added a server-owned tutorial run and carry state, a depot prompt, a carried toaster model, and death/reset/leave cleanup. The state test exercised two independent players and duplicate/stale requests; one-player Studio Play verified pickup, cancel, the original abandon action, death, and respawn. G now delivers the item at the museum. A live two-client session remains a prelaunch integration check because the connected Studio MCP play mode exposes one client. See `docs/task7-testing.md`.

**Expansion dependency:** Task 12 must resolve each player's tutorial target and destination through their assigned plot clone; no client-selected museum ID becomes authoritative.

### 8. Implement server-validated delivery and permanent registration

- [x] Detect arrival at the player's protected stand or receiving mat on the server. Validate the run ID and plausible route, settle the delivery once, register the toaster, and place it in the protected slot. A repeated delivery returns the prior result.
- **Exit check:** Exactly one toaster entitlement and one first-delivery reward exist after repeated callbacks and rejoin. Invalid remote or impossible-position attempts grant nothing. Covers Q10, Q29.

**Task 8 completed — 12 October 2026:** G now submits a server-checked delivery at the gold-trimmed exhibit stand or marked entrance mat. The guide arrow points to the stand, which visibly receives the toaster. The operation ledger prevents duplicate registration. A remote fired from the depot granted nothing; a repeated delivered carry ID granted nothing; rejoin retained one toaster and one first-delivery count. Both mat and stand were walked to and delivered to in Studio using separate development and test profiles. See `docs/tutorial-loop-testing.md`.

**Task 8 follow-up — 12 October 2026:** The delivery remote now samples the current server position before checking route history, closing the interval before the next periodic sample. Rojo build and the in-memory delivery/rejoin test passed. The initial forecourt repair left visible stacked entrance surfaces; a second Studio edit replaced them with adjacent height bands and removed coplanar front-wall columns. Play-mode walking and no-jump pathfinding reached the receiving pad. See `docs/tutorial-loop-testing.md` and `docs/map-testing.md` for evidence. Keep a saved Studio place version of the corrected map before extracting the template at Task 11.

**Expansion dependency:** Task 12 must replace the hard-coded `Museum01` zone lookup with a server-owned assigned-clone lookup, then rerun Q10/Q29 across two players, all six plot slots, and rejoin. The existing Step 8 result remains valid for the one-museum prototype.

### 9. Add displayed income and save/rejoin behavior

- [x] Confirm active-server income uses only valid displayed exhibits, with the protected slot at 50%; changing museum footprint or tier alone must not change the rate. Settle under the old state before display changes, retain fractional income, and save without offline earnings. The existing code is the starting implementation.
- **Exit check:** Cash increases at the expected rate only while displayed; a tier-only profile change leaves the rate unchanged; reconnect retains confirmed cash and registration; waiting offline earns nothing. Covers Q14.

**Task 9 prototype implementation — 12 October 2026:** The tutorial toaster earns $6/min on its protected stand, with server-timed whole-dollar payouts and saved fractional remainder. Studio Play showed cash increasing after delivery; rejoin restored the registered item, rate, and cash. The in-memory store test checked a one-hour offline interval earned nothing. See `docs/tutorial-loop-testing.md`.

**Task 9 completed — 12 October 2026:** Extended `TutorialLoop.spec.luau` with tier-1/tier-5 pure income comparisons: identical displayed toaster profiles each earn $1 over ten seconds regardless of tier; stored and Missing toaster variants earn zero. The updated test passed in Studio Edit with the existing delivery, fraction, save/rejoin, and one-hour offline checks. The tier field is a test-only target field until Task 12's profile migration; repeat this as an integrated upgrade check in Task 19.

**Expansion dependency:** Task 19 settles income before any tier, room, slot, or display state change. Building size alone never increases rate. Rejoin reconstructs the correct visual exhibits without accruing offline income.

### 10. Complete the guided first session

- [x] Save tutorial steps, show the second-run objective, and keep tutorial guard capture disabled for the first item. Do not show purchase prompts. Add a short manual playtest script to `docs/playtest.md`.
- **Exit check:** An unfamiliar player can complete the first delivery without developer instructions; reconnect at each tutorial step resumes correctly. Covers Q01, Q05.

**Task 10 implementation — 12 October 2026:** Delivery persists tutorial step 1; the first displayed income dollar commits step 2 as a durable, idempotent operation. The HUD now guides the player through the first payout and shows the next public-depot heist as upcoming, without sending them to stock that does not exist yet. A server-owned `TutorialGuardProtected` flag and domain rule mark the first item as protected for Task 14's guard implementation. Added `docs/playtest.md`. Rojo built, fresh-module delivery/income/rejoin, Task 2 schema, and Task 4 save regression tests passed, and Studio Play restored step 2, the toaster, and the next objective after a normal player disconnect/rejoin. Public stock, guard AI, and raid training are later tasks.

**Task 10 accepted — 12 October 2026:** The owner verified Task 10 and confirmed it complete. Physical phone/controller verification remains tracked under Task 6; the guard and public stock are still scheduled for M2.

**Prelaunch follow-up to the completed Task 10:** In Task 39, observe unfamiliar players from spawn through first pickup, escape, delivery, and next objective. Check whether pickup and escape feedback are understandable and satisfying within the proposed opening-minute targets; record actual six-plot travel time and any stalls. Fix observed presentation or routing issues in Task 40 without reopening the accepted tutorial implementation.

**M1 gate:** One complete toaster run works in a nearly empty server, on a phone viewport, and after reconnect. Duplicate delivery and load-failure tests pass. This is the first playable build to review before expanding scope.

## M2 — Complete the NPC heist loop

**Goal:** Solo play remains useful with six museums, public stock, guard pressure, and three distinct item carry behaviors. These are Heavy, Noisy, and Bouncy rules scheduled for Task 15, not three carry states already completed in Tasks 1–12. Task 7 supplies one active carry at a time.

### 11. Reserve six expandable plots and prepare the starter template

- [x] Lay out six fixed, nonoverlapping 280 × 280-stud maximum envelopes around the depot. Extract the current museum as a reusable source and author a 60 × 60-stud tier-1 template with exactly three stand anchors, including the protected stand. Reserve modular anchors for 80/110/140/170-stud buildings and 160/200/240/280-stud used grounds. Preserve public stock and at least two legal routes per plot. Measure world size, guard paths, mobile streaming, and travel time at maximum tier.
- **Exit check:** Six maximum envelopes fit without overlap; tier-1 and tier-5 outlines leave viable public/covered approaches; the three starter stands and stable socket IDs are valid; no route bypasses a raid gate. Covers Q02/Q37 in layout form.

**Task 11 completed — 12 October 2026:** Added six fixed plot definitions, five tier targets, a reproducible Studio builder, and a generated `ServerStorage/Assets/Task11MapTemplates` pack containing the archived prototype, 60 × 60 starter museum with three stands and expansion anchors, and a 1,000 × 1,080 six-plot world. Maximum envelopes have at least 40 studs of separation. No-jump 4-stud-agent paths passed on public and covered approaches for all six starter and mock tier-5 plots; a side-approach check crossed each starter fence only at its gate. The iPhone 17 Pro simulator showed the starter entrance without visible overlap, and a Play streaming smoke check loaded 413 staged BaseParts nearby versus 39 about 2,000 studs away. The current one-museum loop remains active; Task 12 owns clone activation, profile migration, and delivery retests. See `docs/task11-layout.md` for measurements and limitations.

**Task 11 visual implementation — 12 October 2026:** The connected Studio source pack now has visual kit v3: layered museum architecture, a furnished gallery, six removable landscape presets and service yards, shared plaza/depot/path/perimeter details, and restrained lighting. Before/after screenshots and the full implementation report are in [docs/task11-visual-report.md](docs/task11-visual-report.md). Final geometry fingerprints match the pre-art audit; all six public/covered routes still pass; 25 sockets and three stands are preserved. Three runtime visual clone/cleanup cycles produced identical counts. Rojo build and the tutorial/delivery/income regression passed. This completes the visual implementation, with owner visual acceptance and physical mobile performance still open. Six player-owned museums, cross-owner delivery, reconstruction on rejoin and the six-player server setting remain Task 12 checks; visual fixture clones do not prove those behaviors.

**Task 11 environmental follow-up — 12 October 2026:** Visual kit v4 makes the single shared depot the Public Acquisition Pavilion, adds shaped outer ridges, perimeter tree/rock density and edge-only mist, shifts Lighting to readable clouded dusk, and adds controlled starter-plot/backyard detail. Selected benches now have server-checked sit prompts; three benches in the active prototype were updated without changing their geometry. The connected Studio source pack and preview were refreshed. Functional geometry fingerprints, all six public/covered route lengths and the tutorial run remain intact; the live sit prompt succeeded. Six staged visual museums maintained a 16.6 ms median desktop frame time in the tested views. See [docs/task11-environment-followup.md](docs/task11-environment-followup.md) for images, source files and limitations. Real-device mobile performance and player-owned museum integration remain open at their scheduled gates.

**Task 11 player-feedback correction — 12 October 2026:** Visual kit v5 replaces the flat-topped, detached-looking edge ridges with overlapping rounded grass hills joined to the existing field by a grass apron. Four invisible server-side collision walls protect the six-museum world perimeter without moving plots or routes. Benches keep Roblox's native Sit prompt; the game interaction HUD appears only while seated as **G — STAND UP**. Studio Play verified Sit and G Stand transitions. The six-plot visual, geometry and route checks pass. See [docs/task11-environment-followup.md](docs/task11-environment-followup.md) and the [updated hill view](docs/task11-screenshots/v5-ridge.jpg). Save the generated Studio place after rebuilding the v5 source pack.

### 12. Implement dynamic museum lifecycle

- [x] Build a server-owned `PlotService` that reserves a free slot, clones the versioned museum template, positions it, assigns ownership, reconstructs saved tier/layout/exhibits, and cleans up safely on leave or failed load. Migrate existing profiles to tier 1; preserve a saved `exposed_03` entitlement in storage because the new starter has only two exposed stands. Switch pickup, delivery, guide target, protected display, income visuals, and any owner-facing plot lookup to the assigned clone together. Do not accept a client-supplied plot or zone as authority. Set the place's maximum server size to six for this six-plot design, and handle a join safely if no plot is free.
- [x] Finish the separate heist hideout as a safe matchmaking entry: preserve a single-player start when no game server exists, prefer a free museum slot, and show truthful live queue/deployment status. Keep the compact `HEIST CONTROL` card readable on phone/controller with its controls collapsible. The armory, vault, locker, and lounge are visual staging areas in Task 12; they do not load museum profiles, grant items, or prompt purchases.
- **Exit check:** The gameplay place reports a six-player maximum; six players see six distinct owned museums, all visible to one another. No overlap or cross-player delivery is possible; a seventh join waits in the lobby when all museum servers are full and gets no writable plot or cross-player access. Stale clone IDs grant nothing. Rejoin reconstructs the saved museum and toaster once; failed loads do not expose a writable museum. Repeated callback and impossible-position tests pass against clones. Covers Q02, Q10, Q29, Q31, Q37.

**14 October progress record:** Schema-2 migration, runtime plot assignment and starter cloning, owner-specific delivery and guide lookup, and one-player rejoin reconstruction were implemented. Studio Play and source checks passed for these portions. The checks listed as pending in that dated record were later superseded by the owner acceptance below. See `docs/task12-progress.md`.

**Task 12 owner acceptance — 21 October 2026:** The owner confirms testing Task 12 with real players and reports that multiplayer, delivery, and matchmaking check out. Mark Task 12 complete on that report. The report does not identify the player count, exact device mix, or outcomes for each adverse-case test in the exit check; keep those as later regression documentation rather than asserting they were individually observed.

**15 October matchmaking request:** The live experience uses up to six players per museum server and fresh player grouping across sessions while preserving account progress. The latest solo-play correction allows the first player to start alone when no game server exists and allows a remaining player to keep playing; when all existing servers are full, the seventh still waits for the eighth to form a new pair. The confirmed referral rule caps rewards at four distinct qualifying friends per inviter; the third and fourth referral cosmetics are specified in `post_launch_updates.md`. Lobby, queue, admission, and teleport source are implemented. The lobby place ID `105126787891032` is configured and its heist staging room is built in the open Studio Edit session. Saving the lobby place, two-place publishing, and published-client checks remain; the referral reward feature itself remains disabled. See `docs/task12-matchmaking-setup.md` and `docs/task12-progress.md`.

**15 October hideout direction:** The lobby is a heist preparation hideout. The `HEIST CONTROL` UI follows the owner's dark/cyan reference while displaying live queue count and actual server status. Do not show an invented `1 / 2` minimum, 50% progress bar, or queue-time estimate: Task 12 permits solo play. The planning table, armory, collector vault, locker, and lounge establish the future layout. Functional shop, ownership, loadouts, leaderboards, and deployment effects remain in their later tasks. The prototype uses original procedural props and signs marked `COMING LATER`; no reference screenshot asset is copied into the game.

**Customization handoff:** Keep Task 12's lockers as visual staging until its matchmaking exit check passes. The post-Task-12 Robber Wardrobe follow-up below then makes them functional. Tasks 37–38 finish approval and fulfillment for Robux cosmetics before launch; [post_launch_updates.md](post_launch_updates.md) Update 9 contains later cosmetic expansions.

**15 October two-player rehearsal:** Temporarily set the museum admission cap to two, with the six plots and solo-start rule intact. The first two players may share a server; with both present, the third waits and the fourth starts another pair. Rejoin in varied orders to verify account progress follows the player and there is no permanent pairing. Restore the six-player cap in source and Creator Dashboard after the four-account published test. The lounge now offers two server-controlled seats with Roblox's default E Sit and G Stand prompts; touch and controller use the same prompt system. See `docs/task12-matchmaking-setup.md` for the test and revert steps. These live checks remain pending.

**16 October live rehearsal update:** The owner observed two players enter the lobby and reach the museum game in under five seconds, then confirmed they shared one museum server and each received a separate plot. The third/fourth-player sequence and progress after varied-order rejoin remain open. Keep the temporary two-player cap until those checks are complete.

**16 October outdoor district redesign:** The owner prioritized the overwhelming open view over more greenery. The runtime district now replaces distant cosmetic hills and broad grass with a modular urban boundary, public blocks, service yards, numbered checkpoints, paved plot margins, and removable annexes on vacant plots. Six coordinates, future 280-stud reservations, starter museums, and routes stay fixed. The repeatable Studio geometry validator and a one-player runtime spawn passed. Judge player-height sightlines, two-player robbery routes, and physical-device performance before deciding whether additional public transport or plot-coordinate changes are needed. See `docs/district-urban-redesign.md` and `docs/task12-progress.md`. This visual pass does not close Task 12.

### Post-Task-12 follow-up A. Close the late-added foundation checks

**Do this after Task 12 passes.** This records checks and additions made after Tasks 1–12 without inserting a task into their sequence. Check existing work first and mark each item only when the result is recorded. Earlier foundation behavior remains the historical baseline.

**13 October historical progress:** Definitions, profile migration target, write contract and Task 12 handoff are recorded in [docs/task11b-handoff.md](docs/task11b-handoff.md). The prototype floor and entrance fixes are repeatable through `scripts/fix_task11b_prototype_front.luau` and `scripts/fix_playable_floor_flicker.luau`. Input and saved-place checks were listed as open at that date; the owner later confirmed both.

- [x] **Definitions from Task 2:** Audit the existing 12-item catalog, `PlotDefinitions.luau`, `Types.luau`, profile schema, socket manifest, and remote allowlist together. Confirm six fixed plot IDs, five tier targets, the three tier-1 stand IDs, and stable authored footprint/stand classes. Record which fields are needed by Task 12 now and which definitions can wait for Tasks 19, 26, and 38. Add only missing versioned definitions required to clone and restore tier 1; do not invent marketplace IDs or rebalance catalog values. Test unique IDs, valid references, and rejection of invalid definitions.
- [x] **Profile contract from Task 3:** Prepare a written migration map and fixture cases for current profiles → tier-1 museum, default style/grounds/security fields, and saved `exposed_03` placement → registered storage when that stand is absent. Preserve cash, lifetime counts, tutorial, contracts, income remainder, and permanent item rights. Keep plot assignment and clone instance IDs transient. Task 12 implements and tests the actual migration and reconstruction; the recorded handoff makes the expected before/after records unambiguous.
- [x] **Write contract from Task 4:** Document which Task 12 changes are durable versus temporary, and identify the existing serialized/idempotent operation path for profile changes. Record how a failed or uncertain write blocks further valuable changes without producing a blank museum. Actual tier purchases/layout mutation remain Task 19; purchase receipt handling remains Task 38.
- [x] **Task 6 owner acceptance:** Record the owner's 21 October confirmation in [docs/playtest.md](docs/playtest.md). Device and individual-control details remain unspecified; capture them during later device regression without treating Task 6 as incomplete.
- [x] **Template and asset persistence from Tasks 5/11:** Verify the saved Studio place contains one `ServerStorage/Assets/Task11MapTemplates` source pack and the needed `ReplicatedStorage/VisualAssets` templates, with their reproducible builders/source references documented. Rebuild or reopen after Rojo sync and check that imported meshes, pivots, materials, socket tags, three tier-1 stands, six envelopes, and both public/covered routes remain correct. Record any Studio-only asset requiring an explicit saved place copy or reproducible import step. Owner confirms this persistence check was completed on 21 October 2026; no separate inspection log was supplied.
- [x] **Handoff record:** Save the exact baseline source/place version, unresolved assets or IDs, fixture names, build commands, and checks actually run in a short `docs/task11b-handoff.md`. Link any existing evidence instead of repeating tests. Give Task 12 a list of remaining implementation items: assign/clone/clean up museums, migrate profiles, resolve owner-specific pickup/delivery/guide/income lookups, set six-player cap, and run multi-client/rejoin/failure checks.

**Follow-up A complete — 21 October 2026, by owner confirmation.** The definitions and migration target are recorded; the owner confirms the source and Studio templates survived save/reopen and Rojo sync, and Task 6 input acceptance is recorded. Six player-owned museums, clone-based delivery, live profile migration, tier purchases, and maximum-tier performance retain their checks in Tasks 12, 19, and 34.

### Post-Task-12 follow-up B. Build the pre-launch Robber Wardrobe

**Character choice:** Use hybrid customization. Keep each player's Roblox avatar and let them add an optional full robber outfit or mix masks, hats, bags, gloves, and other pieces. Cosmetics belong to this experience; they do not become Roblox-wide avatar items. None changes speed, stealing range, carrying, defense, or another competitive rule.

**23 October 2026 implementation record — in progress, not complete:** The playable wardrobe has seven available entries: one free Starter Robber look with bandana, plus the ski mask, three paid outfits, a hand-carried duffel, and phantom glow. Outfit shapes now differ through hoods, cap, bomber layers, armor, pouches, and knee guards. Neon Phantom, Shadow King, and Legendary Robber are visible try-on previews; their Robux purchase buttons remain locked until Tasks 37–38 approve exact offers and marketplace IDs. The museum wardrobe sits in the existing Menu between Tutorial and Map and uses its palette; the lobby locker still opens the wardrobe. Avatar overlays remain reversible, cash purchases are server validated, and the museum-door opening sound is implemented. Rojo builds and the wardrobe unit test passed. Studio Play verified free equip/remove and respawn, a single-player server appearance, a $400 purchase charged once, rejection of an unaffordable purchase, rejoin restoration, the lobby locker loading the owned/equipped look, and server rejection of a premium cash purchase. See [docs/post-task12-wardrobe.md](docs/post-task12-wardrobe.md) for the files, test details, sound ID, and Studio save/publish status. These results do not establish the full exit check.

**Still needed to close follow-up B:** Measure the earned-cash curve and finalize prices; verify selected cosmetics and performance on a physical phone; test controller navigation, a wardrobe purchase during a failed/uncertain DataStore write, and the equipped cosmetic loadout after a real lobby-to-reserved-museum teleport with six players. The owner confirms the underlying lobby teleport, six-player appearance replication, and solo/seventh/eighth-player queue behavior already work; these Task 12 results remain accepted. Only wardrobe-specific regressions need a new check. The checkboxes below remain open because each includes at least one unverified wardrobe condition. Robux offers remain gated by Tasks 37–38.

**23 October owner wardrobe check:** The owner reports that buying and equipping outfits works. The later visual pass rounded the ski mask and limb clothing after the owner identified blocky shapes. Record this as owner acceptance of the basic cash purchase/equip path, while retaining the remaining device, save-failure, cross-place cosmetic, pricing, and Robux gates above.

- [ ] Preserve the player's original avatar and make all robber clothing and accessories reversible. Provide a free starter robber outfit and mask. Support full outfits, face accessories, body accessories, and special visuals; test combinations, respawn, and return to the original appearance.
- [ ] Convert some existing lobby lockers into the **Robber Wardrobe**, with mirrors, mannequins, outfit preview, try-on, equip, and unequip. Add shop and inventory UI to the museum game so players can buy or change cosmetics without returning to the lobby. Keep both flows usable on phone/controller and preserve queue position during harmless changes.
- [ ] Save purchased/unlocked cosmetics and the equipped loadout across sessions and both places. Validate ownership and appearance on the server, make grants and cash deductions idempotent, and ensure lobby purchases cannot create a second writable museum profile or interrupt matchmaking. Recheck loadouts after teleport and respawn.
- [ ] Use existing earned museum cash for cash cosmetics. Set one published cash price per item from the measured median earnings curve, expected spending on collectibles/upgrades, and the value and income rates of the first collectibles the owner makes. The current catalog in `src/shared/ItemCatalog.luau` and design §6.2 lists placeholder first-item shop costs of $180/$220/$280/$340 and base income of $12/$14/$16/$18 per minute; the protected display halves its income. These are reference inputs, not final cosmetic prices. Recalculate after the first collectible models and live earning pace are settled. Do not add a separate cosmetic currency.

  | Cosmetic candidate | Average active-play target to afford | Cash price | Draft Robux |
  | --- | --- | ---: | ---: |
  | Basic robber outfit | Free starter | Free | — |
  | Black ski mask | 10–15 min | Set from earnings | — |
  | Classic burglar outfit | 30–45 min | Set from earnings | — |
  | Street robber outfit | 1.5–2.5 h | Set from earnings | — |
  | Tactical heist outfit | 5–8 h | Set from earnings | — |
  | Elite gold robber | 20–30 h | Set from earnings | — |
  | Neon phantom robber | Premium candidate | — | 99 |
  | Shadow King bundle | Premium candidate | — | 199 |
  | Legendary animated robber | Premium candidate | — | 399 |

- [ ] Launch with **5–8 cosmetics total**, selected from the candidates above, with free and earned-cash options and any approved Robux choices. The black ski mask target is about 10 minutes for a player with the highest-value early collectibles and 15 minutes with the lowest-value ones; the other windows are average targets, not time locks. Include other expected purchases when calculating prices, then check actual fast/typical/slow players. Verify every selected model, preview, final price, and phone performance before release. Tasks 37–38 approve marketplace IDs and implement permanent paid entitlements before any Robux prompts are enabled.
- [ ] Test free play, cash purchase, preview/equip/unequip, duplicate requests, save failure, lobby-to-museum transfer, rejoin, six-player appearance replication, phone memory, and controller navigation. Check that a high-income player still has meaningful earned goals and that wardrobe interactions do not break solo entry or the seventh/eighth-player pairing rule.

**Exit check:** A player keeps their Roblox avatar, can wear and remove robber cosmetics in both places, and retains ownership and the chosen look across teleport/rejoin without losing cash, profile progress, or queue position. Robux purchases are gated by Tasks 37–38 and their own exit checks. Additional animated skins, seasonal items, accessories, victory poses, and achievement-exclusive outfits belong to post-launch Update 9.

### 13. Add public depot stock and reservation rules

- [ ] Implement weighted restocks, rotation, visible countdowns, first-valid-finish reservation, run IDs, and cleanup on failure. Keep tutorial stock separate.
- **Exit check:** Two players finishing the same pedestal yield exactly one carry; failed runs schedule restock; an old run ID cannot award another delivery. Covers Q06.

### 14. Add the guard state machine

- [ ] Implement depot patrol, suspicion, chase, capture, and return with bounded path recomputation and visual warning. The NPC depot guard must not enter any cloned museum or confiscate the first tutorial item; use the server-side first-item protection rule. Scale patrol coverage from measured six-plot routes without making distant plots safer by default.
- [ ] Record bounded NPC failure reasons (for example, guard sighting, capture, dropped carry, or route confusion). After repeated failed NPC heists, offer optional, specific guidance about the guard warning or an available route; let the player dismiss it. Keep guard behavior, stock odds, and rewards identical for players in the same circumstances.
- **Exit check:** Sight, loss of sight, capture, and return behave as designed on both routes to all six plots; guard cleanup leaves no stale target. Covers Q09.

### 15. Add heavy, noisy, and bouncy carrying

- [ ] Implement server-authoritative speed/ping/timing rules from design §5.2, with camera-safe presentation and no physics-driven fling. Add drop behavior.
- **Exit check:** Each behavior is legible and escapable on both routes at tested latency; death/drop cleans up. Covers Q08, Q27.

### 16. Add earned dash, bounded sprint, and basic shove controls

- [ ] Implement server-checked dash cooldown/collision, sprint stamina and speed, shove range, and stun immunity. Tune sprint after six-plot travel measurements; define its carry restrictions explicitly. Disable dash while carrying. Keep raid-specific shove effects inactive until M4.
- **Exit check:** Repeated inputs cannot bypass walls, outrun server limits, exceed cooldowns, or chain-stun a player; long-route play remains practical without buying movement. Covers Q19 and Q29 in preliminary form.

**M2 gate:** One-player and six-player NPC sessions run with uniquely owned cloned museums, no blocked routes, duplicate stock, or stuck carry states. Clone rejoin, cross-player delivery rejection, and touch/controller routes pass before adding progression.

## M3 — Collection, economy, and lasting progression

**Goal:** Every object has a clear acquisition path, ordinary earned-cash progression, and deterministic rewards.

### 17. Implement the 12-item catalog and duplicate rules

- [ ] Add the exact 12 launch item IDs, tiers, rates, weights, carry behavior, and authored footprint/stand compatibility class. Register one permanent entitlement per type and show salvage before a duplicate run. Keep larger future catalog additions separate from the launch balance table.
- [ ] Define three launch sets against **permanent first registration**, not current display or Missing state. Proposed, subject to playtest tuning: **Questionable Kitchen** = `toaster`, `snack_machine`, `gold_toilet` → kitchen exhibit backdrop; **Space Oddities** = `moon_rock`, `mini_ufo` → star-pattern display lighting; **Everyday Treasures** = all four actual Common IDs, `toaster`, `duck`, `traffic_cone`, `disco_bin` → original museum sign style. Keep these definitions ready for the Task 22 progression pass.
- **Exit check:** A first delivery registers; a duplicate gives only advertised salvage; a missing owned type restores its existing entitlement. Every item fits at least one reachable stand in an eligible tier. Covers Q11, Q25.

### 18. Add exhibit arrangement and all display slots

- [ ] Support storage, protected/exposed placement, accreditation unlocks, tier-specific physical anchors, size compatibility, and income transitions. Reject absent/incompatible slot IDs, double placement, and arrangement during a locked phase. Store a registered item safely if a template anchor is unavailable after migration.
- **Exit check:** One item occupies at most one slot; stored or missing exhibits earn zero; protected income is halved. All legal placements reconstruct after rejoin. Covers Q14, Q18, Q38.

### 19. Implement museum and grounds expansion

- [ ] Implement the exact proposed five-tier footprint/stand/grounds table above using authored modules, additional wings, taller large-object halls, second-floor or outdoor spaces where appropriate, and landscaping upgrades. Use the fixed 280 × 280-stud envelope; never uniformly scale the model. Apply earned-cash tier purchases through serialized, idempotent profile writes; settle income before changes and rebuild from saved state. Review prices after route/economy tests rather than inventing them now.
- [ ] Expose the next eligible museum upgrade as an achievable goal with earned-cash and delivery counters (for example, `$940 / $1,200` and `5 / 6 deliveries`); respect the separate accreditation and physical-stand limits. Count each confirmed eligible delivery toward all relevant requirements. Never present a locked, impossible, or already completed upgrade as the only next action.
- **Exit check:** A player reaches 3, 6, 10, 15, and 20 physical stands at the corresponding 120/160/200/240/280-stud grounds sizes without overlap, lost entitlements, invalid stands, or size-only income gain. Every tier and legal layout survives rejoin; large items, camera, and both routes remain usable. Covers Q14, Q31, Q38.

### 20. Add the fixed-price ordinary shop

- [ ] Sell the four ordinary items for earned cash at design §6.2 prices. Show separate earnable museum tier, landscaping, security, and movement unlocks only when their effects are implemented and reviewed. Confirm price, balance afterward, duplicate handling, and server-side spend; premium offers remain a separate later flow.
- [ ] Add an **Abilities** shop with earned-cash travel options. Keep `Ride to depot` free in Task 12 testing. On release, allow one free demonstration ride, then offer a permanent ride unlock with a 60-second cooldown; disable rides while carrying, in an active raid, or while chased. Add a permanent speed coil with about +20% empty-handed walking speed; do not boost carrying speed. Task 16 baseline sprint remains free. Price the two by purchase order using the **14 October pricing method**: the first movement ability bought costs a provisional **$1,000** (20–30 minutes), the second **$2,200** (45–75 minutes). Re-derive both from measured median earnings before release.
- [ ] Show every ability, including the Task 27 ones, with its exact effect and price from the start, even while unaffordable or not yet unlocked. Mark it clearly as a goal rather than hiding it. The starting character (normal movement, one carry slot) must already feel good to control; verify this in the limited test before tuning prices.
- [ ] Make the first affordable small improvement from the existing shop or museum options immediately visible and useful: show the item on a stand or the purchased museum change, its actual income effect where eligible, and updated balance/goal progress. Test whether a new player can reach and recognize that improvement in the proposed 5–8 minute window; tune published prices or route pacing from observed earnings if needed. Do not accelerate the speed coil, depot ride, extra slots, or scanner to create this moment.
- **Exit check:** Repeated clicks spend once; insufficient balance and malformed requests change nothing; earned purchases survive rejoin. No disabled security or movement item can be bought early. Covers Q12, Q13.

### 21. Add three accreditation upgrades

- [ ] Enforce the three original sequential costs and flexible requirements, with accreditation limits of 6, 10, and 20 usable stands above the new three-stand starter. Physical building capacity remains a separate lower bound. Preserve cosmetic rewards, collection, and earned movement.
- **Exit check:** An ineligible upgrade cannot be bought; a valid one spends once and preserves all entitlements after rejoin. Neither a building tier nor accreditation alone bypasses the other slot limit.

### 22. Add six repeatable contract templates

- [ ] Assign three eligible contracts, track each requirement path, permit one claim per instance, replace on claim, and support one pinned objective. Keep PvP alternatives optional.
- [ ] Extend the existing `pinnedContractId` concept into one **player-selected pinned next goal** across an eligible upgrade, active contract, or unfinished collection set. Show its exact server-confirmed counters in the HUD and a clear fallback when a goal is completed, invalid, or temporarily unavailable. Do not silently force every player down the same goal path.
- [ ] On confirmed NPC delivery, show the item reveal, registration/duplicate result, actual displayed income change, every affected set counter, and relevant contract/upgrade counter. Do not claim income if the exhibit is stored or Missing. Reuse the same committed operation result after retries instead of animating a second reward.
- [ ] Make the first new registration a brief, skippable celebration with pickup/escape feedback leading into an item reveal, a visible museum display change, actual cash-per-minute change, overlapping set progress, and one attainable next action. Show the protected toaster's +$6/min only when it is displayed and producing that rate. Repeat or duplicate deliveries get faster, truthful feedback, including salvage when applicable; no forced five-second interruption.
- [ ] Add a small **Heist Momentum Controller** for NPC runs using recent failed/successful heists and time since last confirmed delivery. With repeated failures, suggest a route or guard tip; after a delivery, highlight the player's chosen pin or another eligible short objective; otherwise leave normal progression alone. Guidance is optional and dismissible, uses bounded session state, and never changes PvP odds, collectible rarity, prices, or rewards per player. Test fresh, returning, repeated-failure, and no-pinned-goal states.
- [ ] After the goal and delivery feedback work, implement the three Task 17 sets: let one first registration count for every applicable set; persist progress and award each cosmetic once through durable operations. Keep rewards available after theft.
- **Exit check:** Replayed events or claims do not duplicate cash; every active contract is possible for that player; progress survives rejoin.
- **Goal/feedback exit check:** A player can change the pin, see cash plus delivery requirements, and rejoin with the same valid choice. One delivered toaster visibly advances both matching sets and any eligible delivery goal; a repeated callback advances none.
- **Momentum exit check:** A first registration and a repeat delivery both give accurate, timely feedback and a clear optional next objective. Repeated NPC failures surface relevant help without changing the heist rules or overriding a valid player-selected pin.
- **Set exit check:** Progress survives rejoin and Missing/recovery transitions; overlapping toaster registration advances both applicable sets once; replayed delivery never grants a second reward.

**M3 gate:** Catalog, three cosmetic sets, one pinned next goal, delivery payoff, modular tier/grounds upgrades, shop, slots, accreditation, and contracts work together across multiple sessions. No tier alone produces income. Economy, migration, and idempotency tests pass before valuable PvP mutations are introduced.

## Post-Task-12 decision — stealing, defense and retention (implement ONLY in later numbered tasks)

**Scheduling boundary:** Finish Task 12 and its acceptance checks before implementing new theft, lockdown, traps, recovery changes, or PvP UI. The two post-Task-12 follow-ups and Tasks 13–22 retain their scope. The design below is a **future implementation specification** for Tasks 23–30, 32–35 and 39–40; do not insert a new Task 12 subtask or reopen completed tasks. Post-launch enhancements belong in `post_launch_updates.md`.

**Core promise:** Steal from the public NPC depot to build wealth; raid another player's exposed displays only while **both players are online in the same game server**. An owner away from their museum is still online and can be raided during an eligible open window; an owner who left the server cannot be raided. A theft must create an exciting chase, never wipe a player's permanent collection rights. Ordinary museum acquisition starts with the tutorial and is available immediately; player-base raids unlock only after beginner protection ends. The later PvP revision also lets an eligible owner who is home defend during an open window. One player-base item per raid; no theft of cash, protected stand, stored items, permanent paid entitlements, abilities, or full inventory.

**Suggested moment-to-moment loop:** Scout a museum and its visible window/security → enter through a legal route → hold the pickup prompt (Task 25 retains its 1.25-second provisional hold) → carry a single exposed exhibit with its weight/noise/bounce tradeoffs → owner receives an alert and can intercept with the existing shove or capped defense pad → escape to the thief's assigned receiving zone before the server deadline, or lose the carried item back to its owner's display. No item changes owner permanently: server commits the victim's exhibit as **Missing** and awards the thief only the existing temporary trophy + scrapbook achievement; victim restores their permanent entitlement via the three-parcel recovery path (Task 23). This is intentionally **not** permanent transfer of the victim's unique item; any later persistent trophy idea remains conditional post-launch work.

**Protection principles:** Offline and tutorial-protected players cannot be raided; one active raid per target; short protected/open windows and post-theft/retry shields prevent repeated losses. The protected slot remains immune but earns its already specified reduced income. Security must have visible tells, earned counters and fair escape routes at every museum tier. If an owner is home, they may chase, shove or activate an existing defense pad, but they cannot block exits with a late barrier. Proposed new traps, vault slots or manual temporary lockdowns are **not launch commitments**: evaluate later only with measured need and counterplay. The existing 90-second post-success shield and 15-second retry shield take precedence over the earlier informal 60-second suggestion. Beginner eligibility remains the plan's three NPC deliveries **and** five active minutes (not the earlier informal 10-minute timer).

**Retention hypothesis to test, not a guarantee:** Quick initial NPC success and a visible first museum improvement; first fair PvP exposure after beginner eligibility; close escapes and successful defenses generate opt-in rematches. Measure attempted/successful raids, owner response time, rage quits after Missing, recovery completion, repeat raids, voluntary next NPC heists, D1/D7 returns and balance across free/paid loadouts. Do not change drop odds, payouts or defenses per individual player's engagement.

## M4 — Online museum raids and recovery

**Goal:** Raids have visible stakes and a safe, durable owner outcome. Implement recovery before enabling raids for ordinary players.

### 23. Implement missing-state recovery first

- [ ] Add missing-item records, recovery selection, three server-validated parcel jobs, durable progress, and restore-to-storage/previous-slot behavior. Test it by injecting a Missing exhibit in a development profile. Make the recovery action understandable after a theft: show the specific Missing collectible, its preserved permanent ownership, exact 0/3–3/3 parcel progress, and where it will be restored. No payment and no reliance on stealing it back.
- **Exit check:** Reconnect after each parcel preserves progress; the third parcel restores the same entitlement once; no Robux or rare item is required. Covers Q24, Q25.

### 24. Add beginner protection and raid windows

- [ ] Enforce three NPC deliveries **and** five active minutes for beginner eligibility; persist phase and remaining active-server time. Add the 90-second protected/60-second open cycle, doorway state, and arrangement lock to every clone tier. Replace the Task 12 owner-home = secured visitor rule with the revised PvP rule: **eligible owners can be robbed while home or away** during a server-approved open window. Retain a nearby light for truthful HOME/AWAY scouting, plus independent PROTECTED/OPENS IN/RAID OPEN status; never imply HOME alone makes an otherwise open museum immune. The earlier 10-second owner-departure grace is only applicable where a transition actually closes entry; do not create an additional automatic home immunity. Show no long-range owner-location marker. Integrate the random entrance doors (`MuseumDoors.luau`) so that a closed door never prevents a raid during an open window. Set tier/collection visibility and security budget so the larger footprint creates readable attraction without weakening the protected slot or making lower-tier owners automatically eligible.
- **Exit check:** Protected, offline, ineligible, or closed-window museums reject pickup even if client visuals are stale. Tier changes cannot reset a window or bypass protection. Covers Q15, Q16, Q18, Q39.

### 25. Add raid reservation and visible pickup

- [ ] Enforce both players' presence in the same game server, both players' eligibility, two available exposed displays on each side, one active raid per assigned museum, and a 1.25-second visible hold (touch/controller equivalent). Validate tier-specific raid entrances and target anchors on the server. Alert the owner immediately on valid exposed-item pickup even when they are home; surface sensor warnings with bounded visibility, and release reservations on cancel. Reject cash, permanent entitlements, Robux purchases, protected/stored items and non-exhibit targets.
- **Exit check:** Concurrent raiders cannot reserve the same clone; protected/stored/missing/trophy targets and invalid entrances are rejected. Covers Q15, Q17, Q37.

### 26. Add security, detection, and earned counterplay

- [ ] Implement allowlisted sensor and guard anchors, at most one sensor and two museum guards initially, readable patrol gaps/warnings, coarse nearby hints for tier and collection value, and earnable raider counter-abilities. A third guard is a candidate only if tests show viable counterplay. Server checks placement, line of sight, information scope, device budgets, and alert cooldowns. Test each allowed loadout, including the strongest premium sidegrade, against free counters. Security features should aid an attentive owner rather than create an unbeatable automatic fortress; defer additional traps or manually triggered temporary lockdowns to conditional post-launch work.
- **Exit check:** Every permitted security setup has a nonpaid counterplay route in all five tiers. No guard camps the only legal entry; no sensor reveals private inventory or bypasses raid timing/beginner protection. A paid setup cannot exceed the shared guard/device budget. Covers Q28, Q39.

### 27. Add carry, defense, and raid deadline

- [ ] Extend **Abilities** with permanent NPC-depot capacity upgrades: the first item is free, the **second slot costs a provisional $6,500** (90–150 minutes), and the **third slot costs a provisional $17,000** (4–6 hours), per the 14 October pricing method. Purchase each slot separately, in order, using server-checked earned cash; three total items is the launch maximum. Carry multiple NPC items safely through death, disconnect, delivery, and rejoin. Keep player theft limited to **one item per raid** and preserve heavy/noisy/bouncy penalties. Re-derive both prices from measured median earnings and the final Task 19 building prices before release.
- [ ] Add a **player scanner** to Abilities: a provisional **$3,200 permanent unlock plus $100 per scan** (2–3 hours; the fee is about 30 seconds of income at that stage). A scan shows approximate player locations on the map for five seconds, with a 45-second cooldown; default map state has **no player locations**. The server controls unlock, per-use spend, cooldown, and disclosed pings. There is no automatic owner-location marker; the map hides everyone outside a scan. Near a property, the Task 24 security light shows whether the owner is home. Explain range and limits before purchase; test the map UI on phone and desktop.
- [ ] Give the thief one carry and a server deadline measured for every tier and legal route; 45 seconds is the prototype value, not a fixed expanded-world promise. Permit only the owner to defend this raid with shove or the shared-cooldown pad. Integrate capped guards, sensors, sprint/counters, and carrying restrictions without chained control loss. Cancel and return on valid defense, drop, death, or timeout. **Owner present throughout OR returns mid-theft:** the owner may enter and defend. A thief whose raid already started keeps an open escape route. The visitor barrier and security light must not activate against an active raider, and nobody is teleported out or trapped by an invisible wall.
- **Exit check:** No third party can stun the pair; defense returns the exhibit once; every legal tier-five raid can be completed under tested latency with an earned loadout. Covers Q19, Q27, Q39.

### 28. Commit a successful theft safely

- [ ] On valid receiving-zone delivery, freeze raid resolution, settle owner income, durably set the owner's exhibit Missing, remove its slot, and record the raid operation before visible success. Award one session-only trophy after confirmed commit.
- [ ] After the same confirmed commit, add a permanent **heist scrapbook** entry for the stolen object type and first successful theft, plus one-time cosmetic milestones. The scrapbook records an achievement, never ownership of the victim's item. Persist an operation ID so retry/rejoin cannot grant duplicate credit; apply pair-farming limits from Task 29 before granting repeat-dependent milestones.
- **Exit check:** Repeated delivery commits once; uncertain owner writes reconcile by the same operation ID; a crash cannot remove permanent catalog rights. Covers Q21–Q23.
- **Scrapbook exit check:** A valid heist survives rejoin as an achievement while its trophy still expires on the existing timer/leave rule; invalid, canceled, and repeated same-pair farm attempts do not mint milestones.

### 29. Handle disconnects, shields, and farming limits

- [ ] Apply the exact pre-commit/post-commit leave rules, 90-second post-success shield, 15-second retry shield, pair reward limit, offline protection, and PvP-off feature flag. Keep the existing protected stand as the safe slot, rather than promising additional free safe stands without tier/economy testing. Keep NPC gameplay running when PvP is off.
- **Exit check:** Both players leaving at each raid stage produce one documented result; reservations clear; repeat-pair rewards are blocked and explained. Covers Q20, Q21, Q26.

### 30. Run a multi-client raid failure matrix

- [ ] Automate pure state transitions and use Studio multi-client tests for races, owner write failures, simultaneous requests, reconnect, and malicious remote payloads. Specifically test owner home before pickup, owner entering during a chase, owner going offline mid-raid, protected versus exposed targets, post-success shield, duplicate theft, legal exits that remain open, victim recovery and no permanent entitlement loss. Fix all failed critical checks before proceeding.
- **Exit check:** Q15–Q29 pass under the stated failure modes, including an uncertain write and a simulated server crash boundary.

**M4 gate:** A player can steal an eligible online exposed exhibit **even if the owner is home**, an attentive owner can defend, the victim can recover their still-owned item, and every disconnect/commit race has one stable outcome. Disabling PvP leaves the complete NPC game usable.

## M5 — Complete presentation and accessibility

**Goal:** Replace graybox placeholders with coherent original assets and make the whole loop readable on supported devices.

### 31. Finish the collectible and environment assets

- [ ] Produce all 12 original models/icons, five modular museum tiers with stand/expansion anchors, grounds styles, depot kit, route props, curator/depot guard/museum guard rigs, security equipment, and an asset manifest with ownership, license, and published ID.
- [ ] Finish the hideout art pass using the Task 12 layout: identifiable planning table, armory, collector vault, crew lounge, locker, and decorative deployment gate. Replace placeholder geometry with original authored assets, keep cases and perimeter physically sealed, preserve a clear spawn-to-table path, and profile the lobby separately from the six-museum place. Do not turn preview props into purchases by implication.
- **Exit check:** Every collectible has a usable attachment point, bounds, footprint class, and icon; tier pieces align without seams or blocked routes; missing optional assets cannot block gameplay. Covers Q35, Q38.

### 32. Finish the required screens and guidance

- [ ] Polish `HEIST CONTROL` on phone, controller, and desktop: live queue count and status, solo-start behavior, friend-full message, cancellation/retry, and deployment/error states. Retain compact and expanded views; show estimates only after measuring real queue data. Add short optional heist tips at the planning table without delaying admission or granting museum ownership from the lobby.
- [ ] Put the four earnable Abilities in the same menu/HUD visual theme. Finish the tutorial before showing any travel offer; after the second confirmed NPC delivery, show travel options once when leaving the museum. Persist an opt-in reminder preference so the offer does not recur by default. Do not advertise the speed coil as usable until Task 20 implements it. Show player markers only during an active Task 27 scan; default map hides every other player.
- [ ] Implement all screens in design §12.1, including catalog, tier/grounds management, security budget and counters, recovery, contracts, settings, purchase previews, and data-error state. Use consistent terms for Registered, Displayed, Missing, and Trophy. Show when a stand is physically absent, locked by accreditation, or waiting for a new collectible type.
- [ ] Present the pinned next goal, three set progress/rewards, delivery result, and heist scrapbook consistently on phone, controller, and desktop. Show the museum invite option only when it leads to a useful shared session; never represent an invite click as a qualified referral.
- **Exit check:** A new player understands the loop and a victim understands recovery without verbal help; no screen claims success before the server confirms it.

### 33. Add animations, sound, and effects

- [ ] Add a brief hideout deployment cue only after the server assigns a valid destination: vault light/alarm and `CREW ASSEMBLED` feedback, with a visual equivalent to sound. Cancel effects cleanly on failed teleport or retry; never imply a match is ready from a client timer.
- [ ] Add the inventories in design §11 with bounded effects, visual equivalents for important audio, clean cancellation, and safe behavior if an asset fails to load.
- [ ] Give the first pickup, close escape, and first confirmed delivery short, distinct animation/sound/visual cues. Let first-time registration feel bigger than repeat delivery without obscuring controls or delaying the next heist; keep equivalent information readable with sound off and reduced effects.
- [ ] Fill the ten menu-preview emote IDs in `src/client/MenuEmoteConfig.luau` (owner-sourced, R15, owned by the experience owner or Roblox). Check that each loads in the published place and that the preview returns to a still, forward-facing pose afterward.
- **Exit check:** Carry, chase, defense, delivery, and loss read clearly in a six-player test; muted audio preserves all essential cues. Covers Q34, Q35.

### 34. Verify mobile, controller, and performance

- [ ] Check touch targets, safe areas, focus order, text scale, Reduce Motion, low-effects mode, memory, streaming, replication, clone spawn/cleanup, and frame/server timing with six maximum-tier museums on named devices and at 100–250 ms latency.
- **Exit check:** Core actions and menus work without keyboard/mouse; six expanded museums do not create a sustained hitch, loading hole, or growing stale state. Covers Q33, Q34, Q36–Q39.

**M5 gate:** The complete game loop is understandable and usable on the chosen phone, desktop, and controller test setups. All assets are original or cleared for use.

## M6 — Soft-launch preparation

**Goal:** Make the experience observable, reversible, and ready for a limited public test.

### 35. Add analytics and operational visibility

- [ ] Emit the events in design §17 with bounded properties, including tier purchase/rebuild, stand use, security/counter outcomes, and paid-versus-earned fairness observations. Track load/save/clone failures and uncertain transactions with actionable operation IDs. Keep feature flags for PvP and monetization separate.
- [ ] Measure pinned-goal selection/completion, delivery-to-next-run choice, set completion, successful friend theft/defense, referral-source first-heist completion, and return visits. Judge progress by voluntary next runs and later returns, not only long logged-in sessions or invite clicks.
- [ ] Measure elapsed time from a successfully loaded fresh profile to first pickup, first escape, first committed delivery, first visible improvement, and second NPC heist start. Record first-heist completion with a stated loaded-player denominator, consecutive NPC failures and reasons, whether guidance was shown/dismissed, and voluntary replay after a reward. Segment by device, acquisition source, and six-plot route where sample size permits; count committed events once. Compare D1 return only across actual dated cohorts, not an observed single session.
- [ ] For public cohorts, review short first-play exits, return days, playtime per user, and Home recommendation play-through where platform reporting makes them available. Use them as diagnostic context alongside the heist funnel, not as an assumed recommendation formula or substitute for direct player observation.
- **Exit check:** Test sessions show the tutorial funnel, building progression, raid/security outcomes, recovery, purchase fulfillment, and save failures without collecting unnecessary personal data.

### 36. Prepare release assets and operating procedure

- [ ] Create honest icon/screenshots showing actual tier progression, title/description, controls guide, operator incident/rollback steps, migration and clone-failure recovery, environment checks, and a stable previous place version. Review the full release checklist in design §18.2.
- **Exit check:** Another authorized operator can reproduce a test build, inspect a failed museum rebuild or save, switch off PvP and monetization independently, and restore a previous stable place version without discarding entitlements.

### 37. Review monetization offers and competitive fairness

- [ ] Keep ride, speed coil, extra carry items, and player tracking as earned-cash abilities. Do not convert these four gameplay advantages into Robux-only products during the monetization review.
- [ ] Approve any Robux cosmetics from the post-Task-12 wardrobe catalog with exact contents, prices, and marketplace IDs; its 99/199/399 Robux examples are drafts. Decide separately whether to enable a small Black Market launch catalog of **3–5 exact, approved offers**, prioritizing cosmetic masks, bag skins, frames, hideout or entrance effects. The Black Market uses Robux prompts; the wardrobe supports earned-cash cosmetics in both places. Robux offers may appear in either place. Do not sell an overlapping grapple/scanner power or paid rare artifact before its earned alternative, counterplay, and collection/theft rules are approved. The game remains playable without a purchase.
- [ ] Review a separate monetization plan for premium architecture, exclusive guard appearances, visual effects, landscaping, building upgrade shortcuts, and limited defensive sidegrades. Passes cover one-time permanent offers; developer products cover approved repeatable offers. A shortcut may reduce build time/cash cost but not skip tier order or exceed stand/security caps. A paid defense uses the same budget as earned options and has an earnable equivalent or counter. The owner supplies actual marketplace IDs and decides which offers to enable; cosmetic-only launch remains allowed.
- **Exit check:** Each approved offer has exact contents, price source, earnable alternative/counter, and a fairness test against a free raider. Monetization-off leaves the full earned loop usable. No unverified or invented product ID enters the build. Covers Q30/Q40 in design form.

### 38. Implement purchase fulfillment and fairness checks

- [ ] For approved offers only, verify one-time pass ownership server-side and use confirmed, durable receipt handling for any repeatable developer product. Deduplicate receipt/grant results across retries, servers, and rejoin; keep client prompts non-authoritative. Compare paid and earned raid/security loadouts in the same test matrix. Leave purchase flows disabled until tests pass.
- [ ] Finish the post-Task-12 wardrobe's premium entitlements and any enabled Black Market offers. Keep only the minimum experience-wide entitlement and equipped-cosmetic fields needed in the lobby; the gameplay server still owns full museum profile loading and plot allocation. Keep queue position during harmless cosmetic changes, validate loadouts on the destination server, reconcile purchases across teleports/rejoin, and test receipt retry/duplicate and concurrent server access. A paid collectible, if approved, keeps permanent purchase ownership when a separate gameplay replica is stolen; do not enable paid random crates or trading in the initial shop.
- [ ] Add a **Return to Hideout** action in the museum game. After server-validated carry/raid cleanup and a confirmed profile save, teleport the player to the lobby so they can browse approved Robux offers. Release their temporary plot and matchmaking reservation safely; keep all purchased entitlements and museum progress. The lobby must leave them out of matchmaking while they shop, then offer an explicit **Find a Game** action that joins the existing queue and sends them to any eligible museum server with a free plot. Handle failed teleports or saves without duplicating items, losing progress, or leaving a ghost reservation.
- **Exit check:** A valid purchase grants exactly once and survives rejoin; a failed prompt, unknown ID, or repeated receipt grants nothing extra. No paid setup defeats every earned counter or breaks monetization-off play. Covers Q30, Q40.
- **Return-flow exit check:** From an active museum session, return to the hideout, complete or cancel a purchase, then choose Find a Game. Progress and entitlements load once in the next eligible server, the old plot becomes available, and failed transitions remain recoverable. Test with two players, a full server, and a mid-raid return attempt.

**M6 gate:** All applicable critical tests Q01–Q40 and the design §18.2 release checklist pass; Q30/Q40 verify monetization-off and any enabled purchases. Document noncritical exceptions. Publishing remains an owner decision.

## M7 — Limited public test and fixes

**Goal:** Test whether real players understand and enjoy the loop before wider promotion.

### 39. Run a limited test with observation

- [ ] Invite a small authorized test group, observe first delivery, second run, building upgrade comprehension, home-owner versus away-owner robbery balance, victim understanding of Missing/recovery, and security/counter fairness. Record device/latency context and inspect tutorial, tier, raid, recovery, purchase, and save analytics. Use design §17.3 as hypotheses, not guarantees.
- [ ] Ask whether players know their chosen next goal, notice all rewards after a delivery, pursue the three sets, enjoy ordinary friend theft/defense, and willingly start another run. Measure time spent waiting for selected rare stock. Record whether a guaranteed acquisition path is needed before wider promotion.
- [ ] Time the proposed first-10-minute sequence on real six-plot routes: first steal, first lasting reward, normal depot challenge, first visible improvement, and next chosen target. Watch for frustrating travel, weak delivery payoff, repeated NPC failures, and guidance that obscures the player's pin. Treat proposed timings as hypotheses and record actual distributions and player comments.
- **Exit check:** The team has a dated issue list with evidence, completion rates, and direct observations; serious data-loss or abuse issues are triaged immediately.

### 40. Fix observed blockers and make the scale decision

- [ ] Address the highest-impact comprehension, tier progression, raid fairness, mobile, streaming, and reliability problems. Re-run the relevant tests plus release-critical regression checks; update design values when playtests justify a change.
- [ ] Compare dated before/after cohorts for first-heist completion, first-delivery time, second-heist start, voluntary replay, and D1 returns when a later-day cohort is available. Check that any improvement is visible across devices and routes and did not come from easier hidden rewards or more aggressive prompts. Keep testing if the sample is too small or the result is mixed; use the evidence to choose the next fix before wider promotion.
- **Exit check:** Design §24's definition of done is met, critical checks pass, and the owner has enough evidence to decide whether to promote, keep testing, or revise the core loop.

## First public launch and later updates

**Launch gate:** Complete Tasks 1–40 and their checks, plus both post-Task-12 follow-ups. The launch scope includes the existing 12 original collectibles, five earned museum tiers, reliable NPC delivery, fair optional raids/recovery, six-player museum reconstruction, the Robber Wardrobe and approved cosmetic catalog, one chosen pinned goal, truthful delivery payoff, three registration-based cosmetic sets, permanent heist achievements, and a simple invite entry point. Verify on real devices and in multi-client tests before wider promotion. Rewarded referrals, Museum Challenge, daily jobs, guaranteed rare acquisition, and historical collections are later work.

**After launch:** Open [post_launch_updates.md](post_launch_updates.md). It contains the setup, ordered steps, and exit checks for each update. Do not work from an old copy of the roadmap here.

## Progress log template

Copy this under the current task when work begins:

```text
Task number / date:
Changed files:
Playable result:
Checks run and results:
Known limitations:
Owner-supplied assets or IDs needed:
Next task:
```
