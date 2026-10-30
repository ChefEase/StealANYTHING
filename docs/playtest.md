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
