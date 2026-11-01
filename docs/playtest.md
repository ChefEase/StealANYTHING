# First-session playtest

Use a fresh development or test profile in Studio. Do not use the production data store. Ask a player who has not been told the route or controls to play while an observer records where they pause or need help. The observer should give no hints until the run ends.

## Run

1. Join in the museum. Record whether the player finds the depot using the objective and arrow. Check that the starter cash is $100 and no purchase prompt appears.
2. At the personal toaster, hold the displayed pickup control for the full hold. Verify the toaster attaches once and the destination changes to the museum exhibit stand.
3. Take either route back. The Task 14 depot guard may give a practice warning but must never chase or confiscate the tutorial item. For normal public stock, verify the warning, cover escape, capture, and museum safety using [task14-guards.md](task14-guards.md).
4. At the protected stand or entrance mat, hold the delivery control. Verify the toaster appears on the protected stand, the cash HUD shows $6/min while playing, and the guide says to watch the first dollar.
5. Wait for cash to rise by $1. Verify the next objective points to the public depot. Check that three shared pedestals show their item and rotation countdown.
6. Pick up one public item, carry it to the museum drop-off, and verify it registers or pays duplicate salvage. Check that the taken pedestal shows its restock countdown.
7. Leave and rejoin. Verify the toaster, cash, public item registration, and next objective return. No cash should accrue for the time offline.

## Resume points

Repeat with separate fresh test profiles. Leave and rejoin before pickup, while carrying, immediately after delivery but before the first income dollar, and after the first income dollar. Carrying is session-only: on rejoin the player should pick up the personal toaster again. A delivered toaster and the tutorial step must never duplicate or move backward.

## Devices and results

Run once with keyboard/mouse, once in a phone-sized Studio simulator, and once with a controller. On a physical phone and controller, confirm the hold actions, guide, objective, and safe areas as part of device regression. Task 6 was accepted by the owner on 21 October 2026. Record device, input, latency, route, delivery outcome, reconnect outcome, and any moment the player needed help when those details are available.

| Date / build | Tester and device | First delivery without help? | Resume and income result | Issues |
| --- | --- | --- | --- | --- |
| Pending | Unfamiliar tester | Pending | Pending | Pending |
| 13 Oct 2026 / Task 11b owner report | Input test; device and control type not yet specified | Owner reports success | Reconnect and income outcome not specified in this report | Record whether this covered physical phone, controller, or both, and which hold actions were tested. |
| 21 Oct 2026 / owner acceptance | Owner confirms Task 6 completed and tested; device details not specified in this message | Owner accepts Task 6 | Individual reconnect and income results not supplied in this message | Keep the device-level detail as a later regression record; Task 6 is complete. |

## Task 14 two-player chase observations (player report, 1 November 2026)

Initial real two-player Studio playtest, reported by the players. These are observations, not a six-player or route acceptance pass:

1. A stole in the Warden's line of sight while B stole behind him. The Warden pursued A.
2. Both players stole in his field of view. The Warden targeted the nearer eligible thief.
3. After the pursued player dodged or broke pursuit, the Warden acquired and chased a second eligible visible thief.
4. A player without public stolen stock could enter the depot without being attacked.
5. The fixed 14-stud/s Warden felt threatening; continuous running sometimes produced a narrow escape.

**Provisional pass:** two-player detection and basic target switching. Route and timing data were not recorded, so this does not show whether corners or cover create useful decisions during an active chase. Six-player behavior, all six open/covered route trials, actual capture/restock races and public-stock teleport extraction remain unverified in live multiplayer.

**Next chase comparison:** Repeat identical normal-carry routes with the current fixed-speed Warden. Record pickup position, initial guard separation, whether each turn had solid cover, when sight was lost/reacquired, chase duration, and escape/capture result. Test straight running, a sharp corner with cover, a sharp corner without cover, and an alternate long route. Repeat with two thieves. Only after that baseline, try the proposed reversible 11-to-14-stud/s acceleration (about 1.5s) and optional bounded turn penalty. Improvement means a good route or cover decision changes outcomes without making straight running reliably safe; players should still fear capture. The experiment is pending and its results must be compared in Studio before acceptance.
