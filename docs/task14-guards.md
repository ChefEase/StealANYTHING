# Task 14: depot guard

The NPC depot has one server-owned guard archetype with a six-point, 34-stud-radius patrol. The orange vest, overhead state label and player warning identify its behavior without requiring sound. The loop is independent of museum ownership or player earnings. It does not change stock weights, rewards, or prices.

Detection requires an active NPC carry, a live character, a 24-stud range, a 100-degree forward field of view, and an unobstructed server ray. The guard warns for 0.75 seconds before chasing at 14 studs/second. Solid cover or leaving detection range for four seconds ends pursuit. Capture requires continuous visible contact within 3.5 studs for 0.4 seconds; moving away cancels that windup. Capture fails the stock run through CarryService, removes only the unsaved carry, and briefly slows the character for 0.6 seconds. It does not damage the character or remove cash or registered exhibits. Delivery locks and carry IDs are checked again at commit.

First-item protection reads the authoritative profile rule and carry source. Tutorial/replay carries can receive a practice warning but cannot enter Chase or Capture. Museum bounds, including cloned museum grounds, are excluded from both target acquisition and guard movement. Delivered/dropped items, dead/disconnected players, changed carry IDs, or inactive match admission invalidate the target. Shuttle/depot rides reject chased players, including a second check after the teleport effect's delay.

Movement runs at 10 Hz with capped simulation steps. Paths are requested no faster than once per 1.25 seconds, with one computation in flight. Each path has a waypoint cap; stale results are discarded. Every movement step is checked against collidable geometry and museum bounds. A small checked retreat resolves navmesh corner clearance; blocked/unreachable pursuit returns to patrol rather than teleporting through walls. Patrol visited all six indices in the live navigation test (about 291 studs traveled over 22 seconds, three path computations).

Failure history is session-only and capped at eight observations per player. Sightings, capture, dropped/dead carries, and unusually long routes use allowlisted reason codes. A long route is not counted as a failed heist, and one run cannot count twice. After two failed runs, rate-limited optional advice offers **Got it** and **No more tips** (for this session). Successful public delivery resets the failure streak. Phone guard warnings reserve the notification slot; ordinary notices wait until it is free. Noisy-item investigation/pings remain part of Task 15's carry behavior.

## Validation performed

- Deterministic tests: warning delay, capture windup/cancel, four-second sight loss, sight reacquisition, target invalidation, tutorial protection, bounded/deduplicated guidance. Run `tests/unit/Task14.spec.luau` in Studio after syncing.
- Live normal public pickup: Suspicious → Chase → Capture → Return. A server-script audit confirmed the carry was cleared, cash was not deducted, registered exhibits were unchanged, and the target was cleared.
- Live tutorial replay: Suspicious → Return, toaster preserved, no Chase or Capture.
- Live solid-cover test: no capture through a temporary wall; pursuit ended after four seconds and the carry remained held at the assertion.
- Live museum-entry test during Chase: target cleared, guard remained outside, carried item preserved.
- Actual optional guidance appeared after two captures and its dismiss button was exercised.
- Guard patrol and no-jump navmesh routes measured in the current six-plot district. Distances below are to starter gate approaches, not guaranteed player completion times or measurements of fully populated six-player traffic.

| Plot | Open route | Covered route via both authored waypoints |
|---|---:|---:|
| 1 | 300 studs | 410 studs |
| 2 | 325 studs | 359 studs |
| 3 | 327 studs | 349 studs |
| 4 | 300 studs | 397 studs |
| 5 | 318 studs | 353 studs |
| 6 | 327 studs | 352 studs |

The patrol checks exits near the depot, so owning a farther plot does not automatically avoid detection. Longer covered routes still need player escape/pacing feedback, especially once Task 15's carry penalties exist.

## Owner playtest

1. Restart Play, take normal public stock, and watch for the yellow warning before the red chase state.
2. Move away during the capture windup; then let the guard catch you once. Check that only the held item is lost and its pedestal restocks.
3. Break sight behind a solid wall for four seconds. Repeat on open/covered approaches to different plots. A roof alone is not cover.
4. Enter a museum: the guard should stop targeting you and never enter the museum grounds.
5. Replay the tutorial: the practice warning must never take the toaster.
6. Fail two normal runs, dismiss the help, and choose **No more tips** to verify it stays dismissed for the session.

Remaining acceptance: six simultaneous players, physical-phone/controller warning readability, full end-to-end escape/capture coverage on both routes to every occupied plot, and final pacing after Task 15. No live publication was performed.
