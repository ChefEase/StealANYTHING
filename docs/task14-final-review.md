# Task 14 focused gameplay review — 31 October 2026

Scope: the final refinement request takes precedence over the earlier proposed rebalance/extraction implementation. Preserve the playtested Warden; review abilities without changing them. This revision fixes deterministic acquisition ties and phone carry clutter. It does not complete multiplayer acceptance or implement adaptation, 14A or 14B.

**1 November extraction follow-up:** The user authorized fixing extraction and clarified **3-4 seconds**, not 34. The later implementation now enforces a configurable 3.5s public-stock activation after the normal prompt hold, permits capture during activation, validates immutable run/carry identity and server spatial/admission/access state, and blocks alternate shuttle bypasses. Empty/tutorial travel remains quick. This supersedes the historical ability-unchanged/extraction-not-implemented findings below. Implementation and remaining live tests are tracked in [the main plan, Task 14.3/14.4](../development_plan.md).

**Subsequent startup fix, 31 October:** After the source reached Studio, the user reported the missing guard. The Play log showed `GuardBrain:1 ... Unicode character U+FEFF`; a leading UTF-8 BOM prevented module loading and guard startup. Removed the BOM from the repository source and verified the actual synced module loads. A new Studio Play check confirmed Patrol, 25.7 studs of movement over two seconds, and 13 visible replicated guard parts on the client. Returned to Edit afterward. Earlier source-injection tests stripped the BOM and missed the failure. This subsequent startup check supersedes the earlier no-Play/no-sync status below; it is not multiplayer acceptance. All remaining work is now tracked directly under Task 14 in [the main development plan](../development_plan.md).

## Exact changed files

- `src/server/Domain/GuardBrain.luau`: total-order candidate comparator.
- `src/server/Services/DepotGuardService.luau`: use that comparator when acquiring a target.
- `tests/unit/Task14.spec.luau`: simultaneous/staggered candidates, search lock and invalidation regression checks.
- `src/client/CarryHud.luau`: phone carry starts collapsed, shows museum distance, opens details on tap, collapses on chase entry; larger phone controls.
- `src/client/CarryDestinationHud.luau`: suppress the duplicate phone destination card. Desktop presentation remains available.
- `docs/task14-guards.md`: correct the movement description and link this review.
- `docs/task14-final-review.md`: this report.

## Confirmed findings and narrow fixes

1. Acquisition depended on player enumeration order when distance and selection history tied. The old pairwise 0.1-stud tolerance was also non-transitive: distances 20, 20.08 and 20.16 could give different winners after reordering. Fixed using distance rounded to tenths, then oldest selection timestamp, then UserId. It only changes acquisition ties; no active target switching or progression-based preference. Tests rotate 26 equal candidates and the three-distance counterexample. This does not certify 26-client performance; the current configuration is **six players**.
2. The phone destination card overlapped the carry card. At 390px width its old rectangle was x=156..376, y=92..174; the carry card occupies x=14..264, y=94..190. Fixed by combining the distance into the carry summary and hiding the second phone card. The summary is 250x48 at this size, compared with the expanded 250x96 carry panel plus 220x82 destination panel. Income detail remains available elsewhere in the existing HUD/menu; phone carry detail prioritizes the route. Warning and delivery controls remain available. A 44x44 detail-collapse control replaces the small phone control.
3. Public-stock extraction before detection is allowed by the existing code. ReturnToMuseum has a 0.5s prompt; TravelEffects waits another 0.22s. Both travel checks reject GuardChased, but Suspicious does not set GuardChased. CarryService permits a carrying, unlocked, route-valid session and credits authorized teleport distance/time toward delivery validation. The destination is inside the assigned museum. Thus an unobserved thief, or a second thief while the guard is occupied, can extract without a chase. This is a confirmed permitted code path, not a live exploit reproduction. Ability behavior is unchanged in this review.

Minimum follow-up for finding 3: one server-owned extraction transaction at the public-stock return shuttle, with configurable initial duration 3.5s (corrected from the mistaken 34s; user intended 3-4 seconds). Capture immutable carry ID, run ID, character and origin; validate active public run, admission, tutorial eligibility, reservation lifecycle, delivery lock, proximity and any actual entitlement at start and completion. Cancel on capture, drop, delivery, departure or invalidation; serialize activations per player and commit once. Emit bounded noise from the activation point and show activation progress. Do not pass a player's destination to perception. Ordinary empty travel and protected tutorial travel retain their current rules. Merely changing HoldDuration is insufficient. Current travel is free during testing; no paid entitlement or price should be invented. Implement and test this separately, as requested by the final review.

## Actual movement and abilities

No speed configuration changed:

| Setting | Current value | Actual use |
| --- | ---: | --- |
| NORMAL_WALK_SPEED | 16 | Restore after carry |
| NORMAL_CARRY_SPEED | 12 | All attached carries |
| HEAVY_CARRY_SPEED | 10 | Defined, not applied by current movement code |
| BOUNCY_DIP_SPEED | 9 | Defined, not applied by current movement code |
| GUARD_SPEED | 14 | Patrol, investigation, chase, search and return; no acceleration |
| GUARD_PURSUIT_VISION_STUDS | 70 | Existing target, all directions, obstruction ray still required |

Catalog size/weight does not currently reduce movement speed. There is no implemented sprint/Speed Boost system in `src`; TravelOfferHud explicitly says sprint is planned. No duration, magnitude, cooldown, purchase or stacking behavior can honestly be tested yet. Carry route sampling currently uses a maximum sample speed of 18 (=12x1.5); any future sprint needs a narrow server-authorized route-validation integration as well as a single non-stacking speed resolver.

RideToDepot is a free museum-to-depot convenience remote, gated by profile readiness, museum proximity (68 horizontal studs), a two-second throttle and GuardChased. It is not the return/extraction ability. District shuttle and museum-return prompts have their own three-second throttles and match checks. TravelEffects checks character and item-name continuity after its yield, then CarryService checks the current session and route; this is not immutable run-ID continuity across the yield. Future extraction must add that continuity. No purchases, prices, ability settings, delivery rules or reserved-server systems were changed.

## Chase/capture and multiplayer assessment

- Simultaneous visible eligible thieves: nearest rounded distance wins, then least recently selected, then UserId. Each newly acquired player gets the existing 0.75s warning.
- Staggered theft: the current target remains locked through Suspicious, Chase, Capture and Search. A second thief cannot redirect the guard simply by becoming closer. Search does not inspect hidden target coordinates to choose its destination.
- Drop, delivery, death, departure, protected museum entry or invalid carry/run clears the target. Another visible eligible thief is considered on the next decision, normally about 0.1s later, with a fresh warning. Search timeout, capture and pursuit limit also release the lock.
- Investigation and Return have no forced nonresponsive period: their no-target branch checks visible candidates first. Noise carries a location, not a player identity. Search remains exclusive until reacquisition/termination. Repeated cover changes can resume the same chase, bounded by the 60s pursuit budget.
- Pursuit visibility is already configurable. 70 studs applies to the existing target with clear sight, not omniscience or a 70-stud acquisition radius. Hidden movement leaves lastSeen unchanged. Travel is blocked during Chase/Capture/Search; an allowed warp during warning is followed only if the destination is genuinely visible and eligible. Museum protection ends pursuit.
- Capture requires visible contact within 3.5 studs for 0.4s; gaining distance resets windup. The service validates carry and run before calling CarryService.TryGuardCapture(carryId). That contract rejects wrong/missing carry, tutorial pedestal/replay, protected first item, missing profile and a delivery lock. It clears only that active run through PublicStockService.Fail. It does not kill/reset the avatar or write currency, owned exhibits, storage or progression. Repeating capture with the old carry fails. There is a hard-coded 0.6s stagger at speed 6, **not** a configurable post-capture immunity window.
- Restock is real service wiring: clearPlayer -> PublicStockService.Fail -> PublicStockState.Fail(current run). An empty originating pedestal gets a 20s restock deadline; an already replenished pedestal is not removed. Actual live capture, replicated stock display and concurrent delivery remain untested in this revision.
- Return times out after 20s, and blocked patrol goals rotate after 8s without progress. This bounds states; it cannot prove physical escape from every bad geometry pocket. No teleport fallback was added.

Balance concerns, not newly demonstrated defects: a coordinated distraction can let others steal while the target lock is held; a lone guard cannot police everyone simultaneously. At 14 versus 12, a straight uninterrupted chase closes at 2 studs/s before windup/geometry effects. If heavy speed 10 is activated later this becomes 4 studs/s. The current fixed speed and 70-stud memory sight may be too strong on some open routes, but the existing successful playtests are reason to measure rather than rebalance. Do not add target churn, wall vision, speed scaling or server-wide punishment to address distraction without real paired route trials.

## Tutorial and future hooks

First-item and replay protections are unchanged. Existing GuardState, GuardSuspicion, GuardCaptureProgress, GuardDetectionReason and GuardTutorialNotice support later tutorial presentation. GuardTutorialNotice is currently throttled to once per 20s, not once per tutorial: Task 14B must gate its presentation to the tutorial/replay and remember which guidance was shown during that tutorial. Explain warning -> solid cover -> leave the last seen position -> current public item confiscation; never require sprint or actually confiscate the protected first item to demonstrate it. Existing optional failure guidance is rate limited; its four-second hiding advice is not the actual search deadline (six seconds at last position, with a travel allowance). This review does not add tutorial steps or presentation.

Adaptation remains deferred until baseline playtests are fun. A future isolated, session-only observer could consume visual-loss positions/directions, explicit noise and pursuit-end events. Any occasional alternate search waypoint must stay on legal routes and depend on repeated visible observations for that target, with bounded frequency, deterministic selection, debug reasons and time decay. Reset on departure/session end; never change speed/detection/protection or other players' difficulty. No hidden current positions or learning were added.

Current runtime debug attributes are described in task14-guards.md. They are replicated attributes, not development-only diagnostics, and do not include all requested movement/separation/teleport measurements. This is a remaining earlier-task gap, not claimed complete here.

## Tests actually executed this revision

- Studio Edit: updated Task14.spec passed, using the new GuardBrain source in an isolated function and existing synced dependencies. Balance source equality checked after normalizing line endings/trailing whitespace. Covers selection ordering, staggered lock, invalidation/reacquisition, warning/capture cancellation, search/Return deadlines, tutorial protection, bounded noise and feedback. These are synthetic observations, not actual multiplayer perception.
- Studio Edit: Task13.spec passed (console confirmed), including competing reservations, one successful stock claim, stale carry rejection, failure/restock timing and public delivery rules. TutorialLoop.spec passed (delivery, income, rejoin rules). These do not call the real live capture pipeline.
- Studio Edit: PhoneHudLayout.spec passed for nine safe-area sizes, including 568x320 landscape and 320x568 portrait.
- Studio Edit: new HUD source instantiated in off-tree GUI objects with injected phone layout and a fake attribute holder. Compact default, hidden duplicate card, 250x48 control, changing route distance, chase collapse and carry-clear visibility passed. An initial check sampled deferred attribute signals too early; rerun with 0.1s settling passed. This is not a rendered device/touch acceptance test.
- `rojo build default.project.json -o build/Task14Review.rbxl` passed. `git diff --check` passed (line-ending warnings only).
- No source changes were applied to the connected Studio place, no Play session launched, no profiles modified and no publication performed. Sync repository changes through Rojo before gameplay testing.

## Required manual acceptance

1. Two clients, then six: simultaneous theft from different pedestals and competing theft from one pedestal; repeat with reversed joins and 0.2/1/3s stagger. Record chosen target, warning and target release. Use a separate scale test for 26 clients only if the game capacity is deliberately expanded.
2. A distracts through visible running and cover while B steals, then swap roles/routes. Measure delivery rate and time before B can be targeted. Separate ordinary teamwork from repeatable risk-free shuttle extraction.
3. Real public pickup -> warning -> contact -> completed capture: avatar survives, only current carry disappears, cash/storage/exhibits unchanged, originating stock correctly restocks. Repeat drop/delivery/disconnect at windup completion and near a restock deadline. Test delivery lock versus capture and old run IDs after a new pickup.
4. Beginner without abilities: normal and catalog-heavy items (currently both speed 12), all open/covered routes, 69/71-stud visibility boundary, fast cover peeks, loss/reacquisition and protected museum entry. Verify first theft/replay warnings cannot confiscate the item. Measure physical patrol recovery around actual obstacles.
5. Teleport-only/free travel: empty travel, protected tutorial carry, public carry before warning, during Suspicious and during Chase/Search, then a second player's activation during the first player's chase. Confirm denied travel does not award route credit and allowed travel cannot duplicate delivery. Sprint-only and combined-upgrade tests are **not executable as real ability tests yet** because sprint is absent. After a separate extraction implementation, test capture interruption at start/middle/completion, departure, drop, delivery, stale run, simultaneous activations and retry; activation was not implemented at the time of this historical review.
6. Phone simulator and real touch: portrait/landscape, rotate mid-carry, tap expand/collapse, long item names, guard warning, delivery hold, notifications, cash details and menu open. Confirm controls avoid Roblox thumbstick/jump/safe areas and the compact route remains readable. Desktop carry layout also needs visual regression checking.

Known limitations: source/domain review and focused automated checks do not certify the Warden's fun, 26-player performance, actual confiscation/restock integration or phone rendering. The earlier requests for separate speeds/acceleration, extraction transaction, post-capture immunity and full development-only diagnostics are intentionally not implemented by this narrower final review. Baseline multiplayer acceptance remains open before 14A.
