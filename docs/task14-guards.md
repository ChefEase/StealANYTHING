# Task 14 guard repair (2–6 players)

Status: implementation and focused automated checks; multiplayer/route acceptance is still required. Task 14A and 14B have not started. Earlier implementation playtests do not count as acceptance of this revision.

## Gameplay and transitions

- Patrol, Return, or Investigation acquire the nearest eligible visible carrier. Distance ties within 0.1 studs prefer the least recently selected player; never use plot number or earnings. An active target is retained until invalid, captured, protected, timed out, or unreachable. Other thieves cannot steal its target lock.
- Forward acquisition: 24 studs, 130-degree total cone. Public carriers within 9 studs can be noticed from any direction. BOTH routes require a server obstruction ray. All acquisitions use the same visible 0.75-second warning; nearby ordinary visitors are not chased.
- A successful public pickup emits a server-only location event after carry attachment. The guard hears events within 35 studs, including behind cover, but gains NO player identity. Patrol/Return -> Investigation. The overhead label says HEARD A PICKUP. Investigation moves toward the location, acquires only through sight, and expires after 8 seconds. Repeated noises cannot reset that deadline indefinitely. The queue is capped at 12 and stale events expire after 2 seconds. Task 15 may add other explicit noise sources later.
- Investigation/Patrol/Return -> Suspicious on visual confirmation. Losing sight during warning cancels it. Protected first-item/tutorial/replay warnings return without chasing. Otherwise Suspicious -> Chase after the warning.
- Chase retains sight in all directions within 70 studs (still requires obstruction checks), moves at 14 studs/s versus normal carry 12 and heavy carry 10. The 340-stud radius limits NEW acquisition, not a valid ongoing chase. A 60-second pursuit budget prevents endless map-wide chase.
- Lost sight -> Search, following the last observed location without tracking hidden player movement. On reaching it, search for 6 seconds; after 12 seconds of travel without sight, the search deadline starts anyway. Reacquisition resumes Chase; prolonged search -> Return. Travel during Search remains blocked by GuardChased.
- Visible contact within 3.5 studs -> Capture; 0.4 seconds of observed contact is required. Losing contact resets windup. Capture invokes the unchanged CarryService.TryGuardCapture contract. Carry ID AND run ID are revalidated. Delivery locks, tutorial protection, stock failure and feedback remain in the existing service; cash and registered exhibits are untouched.
- Invalid carry, death/reset/disconnect, museum entry, or match ineligibility -> Return. Return -> Patrol on arrival or after 20 seconds. Patrol then tries alternative points if blocked; there is no teleport fallback.

## Navigation, timing, diagnostics

Local movement sweeps only the intended step, not the full destination distance. Ground height and obstacle clearance are checked each step. Longer routes use the existing no-jump pathfinder, at most once per 1.25 seconds with one computation in flight. Stale results are discarded and Path instances destroyed. Museum intersection is checked along whole path segments and movement segments using local-space rectangle intersection, including the existing 3-stud margin.

Movement uses at most three <=0.1-second swept steps per decision. State deadlines consume all elapsed time without an unbounded catch-up loop. Warning/capture credit is limited to 0.25 seconds per observation so a long server stall cannot instantly convict a player. A stall deliberately slows physical movement instead of teleporting to catch up. Visual poses update at most 15 Hz using wall-clock time independently of AI decisions.

Eight seconds without meaningful positional progress ends an unreachable pursuit or skips a blocked patrol destination. A small collision-checked retreat is retained; retreat alone does not reset progress. Dynamic museum expansion still needs bounds refresh when that future feature is implemented; current bounds are captured when each complete museum model is added.

Inspect workspace.DepotGuardRuntime attributes: State, TargetUserId, LastKnownPosition, DetectionReason, InvestigationSource, PursuitEndReason, NavigationFailureReason, PathStatus, PathComputations, CaptureAccepted. Failure/source attributes retain the last event, rather than implying an active failure. There is no per-tick logging. Service.Stop disconnects listeners, clears target attributes and destroys presentation.

## Configuration

In BalanceConfig: GUARD_VIEW_DEGREES=130; GUARD_CLOSE_AWARENESS_STUDS=9; GUARD_PURSUIT_VISION_STUDS=70; GUARD_ACQUISITION_RADIUS=340; GUARD_CHASE_SECONDS=60; GUARD_SEARCH_SECONDS=6; GUARD_INVESTIGATION_SECONDS=8; GUARD_RETURN_SECONDS=20; GUARD_PATH_INTERVAL=1.25; GUARD_STUCK_SECONDS=8.

Existing settings retained: detection=24, noise radius=35, warning=.75, speed=14, lost-sight=4 (now the base for the 12-second last-position travel allowance), capture windup=.4. These are initial gameplay test values.

## Task 14A visual contract (design only)

Current adapter exposes Create(parent, position), SetPivot(controller, CFrame), Update(controller, state, warning, moving, wallClock), Destroy(controller). Gameplay only reads a stable root and sends transforms/state; presentation never chooses targets or captures.

The replacement adapter should support Create or Attach(model), GetRoot(), SetPivot(CFrame), SetFacing(direction), SetState(state), PlayAnimation(name, options), SetProgress(warning, capture), Update(dt), Destroy(). Named animations: Idle, Patrol, Investigate, Warn, Chase, Search, Capture, Return. Map missing clips to Idle/Walk gracefully. SetPivot must preserve one stable gameplay root independent of animated bones; animation root motion cannot move the authoritative collider. Cleanup must disconnect tracks and release instances. This is an interface specification, not a claim that the current placeholder has those animation clips or an imported rig.

## Verification and remaining acceptance

Automated checks run on 30 October: museum and lobby Rojo builds passed; Task14 unit suite passed in a fresh Studio Server context; existing Task13 stock/delivery and TutorialLoop delivery/income/rejoin suites passed. A live server-only noise probe entered Investigation, assigned no target, and exited on its deadline. The final isolated live probe passed forward chase, pursuit beyond depot, solid-cover Search, search exit, rear awareness, drop invalidation, museum exclusion, capture windup and protected warning. This uses synthetic carry/capture dependencies, not real inventory confiscation. git diff --check passed. These are narrower than the outstanding acceptance matrix below. The initial Edit test encountered stale require caching; an initial live-probe version attempted to mutate the frozen CarryService and was corrected to isolated modules; the fixed-delay protected-warning assertion was replaced with transition polling and passed on rerun.

Run tests/unit/Task14.spec.luau in a fresh Studio session after syncing; Edit command-bar require caches may retain old modules. Tests cover perception broad phase, warning/windup, target locking/invalidation, investigation/search/Return deadlines, frame-rate variation, protected carries, bounded noise and feedback. The broad-phase test alone is not proof of wall occlusion.

Run Task14LiveProbe.server.luau in the Server command bar during one-player Studio Play. It creates isolated temporary guard/carry modules and a normal Script, substitutes a synthetic carry and capture callback, then restores the original guard. It never claims stock or changes profiles. It exercises actual guard sight, physical cover, navigation, search, rear awareness, museum entry, capture request timing and protected warning. Stop Play after running. It does NOT replace end-to-end delivery/stock tests or simultaneous multiplayer tests.

Known limits: one no-jump guard, current static museum bounds, conservative movement after long server stalls, no final Warden rig or audiovisual polish. Existing unrelated Studio asset warnings for asset 203785492 remain. Historical route lengths (not remeasured in this repair): open routes 300-327 studs; covered routes 349-410 studs.

Still required before accepting Task 14:
1. Two and six real clients: simultaneous cone entry, multiple carriers, stable pursuit when another thief arrives, no plot priority.
2. Normal public pickup -> noise/warning -> chase -> capture, check actual stock restock, unchanged cash/collection, and delivery-lock race.
3. All six open/covered routes: chase beyond depot, cover loss/reacquisition, unreachable destinations, museum entry and no boundary crossing.
4. Drop/deliver/reset/disconnect while warned, chasing and capturing; tutorial first item and replay end-to-end.
5. Profile pathfinding/physics query rates at six clients and varied server frame rates; phone warning readability and close-awareness fairness.

No manual assets, animation IDs, sound IDs or new remotes are needed. Sync the changed modules through Rojo and restart Play. No publication was performed.
