# Task 7 — personal toaster pickup

The tutorial toaster is a server-session run. Every eligible player gets an independent run ID and carry ID. The shared depot display is only a presentation object; taking it does not deplete another player's tutorial target. The server accepts only the known `depot.tutorial_pedestal` target while the player's profile is ready, the toaster is unregistered, and no item is already being carried.

The prompt uses a 1.25-second hold and a seven-stud reach. `BeginPickup` sends a target ID and a client retry ID at hold start. Completion requires the server to observe the prompt trigger after its own timer, then recheck distance, line of sight, life state, and tutorial eligibility. Pending pickups are checked during the hold and expire if the player moves away or the trigger never arrives. `CancelPickup` is scoped to the matching pending request; `DropCarry` is scoped to the matching carried item. Neither client event can grant or permanently register an object. G now sends `DeliverCarry` when held at the museum; `DropCarry` remains a server-validated abandon request without a G binding.

The visible depot toaster and prompt are local to each eligible player. The carried model has no collision or touch behavior and is welded to the character's right hand, so it does not push the player or block the camera. Carrying sets WalkSpeed to 12; abandoning, death, reset, delivery, and character removal restore 16. Leaving removes the session record. The player can try again after a failed run. Task 8 consumes the server-issued run ID for validated delivery and permanent registration.

## Verification — 12 October 2026

| Check | Result |
| --- | --- |
| Rojo build | Pass: `.\rojo.exe build default.project.json -o build/StealAnything.rbxl`. |
| Two personal runs and one-carry limit | Pass in `tests/unit/Task7.spec.luau`: two user IDs got distinct server run and carry IDs; duplicate begin/complete calls could not create another carry. |
| Stale and cross-player IDs | Pass in the state test: another player's carry ID, old cancel ID, and repeated drop did not alter the current session. |
| Live pickup | Pass in the connected Studio Play client at the documented reachable east edge `(-83, -72)`: the prompt appeared 3.5 studs away with clear line of sight; a full hold attached the toaster, set speed to 12, showed carry UI and feedback, and hid that client's depot display. |
| Early release | Pass using `ProximityPrompt:InputHoldBegin()` followed by `InputHoldEnd()` after 0.3 seconds: no carry after 1.6 seconds; speed remained 16. |
| Original drop behavior | Passed on 12 October before G was reassigned. G now delivers at the museum. |
| Death and respawn | Pass: killing the carrier cleared the carry and visual; respawn restored speed 16 and pickup eligibility. |
| Live two-client session | Still needed before launch. The connected MCP Play command opens one test client; the two-player state race is covered by the deterministic test. |
| Map preservation | Pass after Play stopped: hill 15, exterior dressing 193, distant silhouettes 86, front decor 9, boundary art 102. The runtime toaster folder disappeared on Stop; the Studio-authored map did not change. |

Run `tests/unit/Task7.spec.luau` in Studio Edit mode after Rojo sync. It uses no DataStore. For a two-client manual check, use Studio's **Test > Server & Clients** with two clients: move both to the depot, hold the prompt for each, and confirm both carry their own toaster. Try repeated E holds while carrying and reset one player. Each player's carry should change independently. Delivery and income checks are in `docs/tutorial-loop-testing.md`.
