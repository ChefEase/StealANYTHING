# Tutorial pickup, delivery, and income — 12 October 2026

## Player flow

On a new profile, a screen arrow and world marker lead from the museum to the personal depot toaster. Holding E for 1.25 seconds starts a server-owned carry. The carry HUD names the item, shows its Noisy behavior and the $12/min base and $6/min protected-display rates, and points the player back to the museum. The toaster is welded to the right hand, not the head. The gold-trimmed protected stand is the guided drop-off; the marked entrance mat remains a valid alternate delivery point. Hold G for 0.5 seconds at either point. A successful delivery saves one toaster registration in the protected slot, clears the carry, and starts $6/min active-server income. The cash HUD states that the rate applies while the player is here.

On a phone, the smaller tutorial card sits near the lower center. It hides while the toaster pickup prompt is open, then returns once the player picks up the toaster. The pickup prompt says TAP. At a valid drop-off, the guide makes room for a visible HOLD TO DELIVER button; a 0.5-second hold completes delivery. The button is hidden away from the museum drop-off. Phone cash, carry, interaction, notification, and tutorial panels use the safe screen area and avoid the movement controls.

The tutorial is one complete first NPC delivery and income loop. The next objective points to the three public depot pedestals after the first displayed dollar. Guard pressure and raid training remain later development tasks.

## Validation and persistence

The server owns the run and carry IDs. Pickup requires the known pedestal, an eligible profile, the full hold, a living character, seven-stud reach, and line of sight. Delivery requires the matching active carry, a living character inside the protected stand socket or receiving zone, and plausible server-observed travel. The client sends only the carry ID. The profile operation ledger makes repeated delivery callbacks return one result. A failed or uncertain write does not show success; the service retries the same operation ID. The receiving mat and protected display are distinct: the mat can accept an item, while the stand shows and earns from the registered exhibit.

Income is calculated from server time while the player is present. Only available items placed in a display slot earn income; the protected slot applies the configured 50% multiplier. Whole dollars go to cash and `lifetime.totalCashEarned`, while a fractional remainder stays in the profile. Income is settled before the first display registration. No offline interval is accrued on rejoin.

## Checks run

| Check | Result |
| --- | --- |
| In-memory delivery and income test | `tests/unit/TutorialLoop.spec.luau` passed in Studio Edit using a fresh clone of the synced modules. It covered one registration, repeated operation ID, a second duplicate attempt, $6/min with fractional income, save/release/rejoin, and no offline earnings. |
| New player guidance | Fresh Studio test profile began at $100, tutorial step 0, and a visible depot arrow about 206 studs away. |
| Pickup and carry | Walking the no-jump route and holding the depot prompt produced one `RightHand` weld, 12-stud/sec carry speed, the expanded item HUD, and an arrow back to the museum. The model body was about 0.8 studs from the hand and 2.6 studs from the head. |
| Invalid remote and route | Firing `DeliverCarry` from the depot did not remove the carry or advance the tutorial. On another fresh test profile, teleporting directly from the depot to the stand cleared the carry without registering the toaster; walking the no-jump route afterward still delivered it. |
| Entrance mat | Walking the open route back and holding G on the marked mat registered the toaster once and cleared the carry. Repeating the old carry ID did not create another item. |
| Protected exhibit stand | On a separate fresh Studio test profile, the guide pointed to the protected stand; a no-jump route reached the stand, `AtDropOff` became true, and holding G completed the delivery. The toaster appeared on the stand with its base resting at the plinth top. |
| Income and rejoin | After the first delivery, cash rose from $100 to $101 with $6/min displayed. Rejoining the development profile restored the registered toaster, $6/min rate, and accumulated cash. |
| Phone HUD positions | `tests/unit/PhoneHudLayout.spec.luau` passed nine safe-area sizes, including the 733 × 333 iPhone 16 simulator area and compact portrait screens. It checked bounds, panel pairs that can appear at the same time, and text width for the guide, delivery button, and income label. |
| Phone pickup and delivery | A fresh iPhone 16 Studio simulator profile began at $100 with the lower-center guide. At the depot, the TAP pickup prompt hid the guide. Picking up showed the compact carry HUD and restored the guide. Walking the no-jump route showed HOLD TO DELIVER at the protected stand; a 0.2-second press did nothing, while a 0.75-second press delivered the toaster, cleared carry, and activated $6/min income. The guide and delivery button did not overlap. |
| Rojo build and map | `.\rojo.exe build default.project.json -o build/StealAnything.rbxl` passed. After Play, the preserved Studio map still had 15 hills, 193 exterior pieces, 86 distant silhouettes, 9 front decorations, and 102 boundary pieces; the temporary `TutorialRuntime` folder disappeared. |

The protected-stand run used `StealAnything_Test_v1` temporarily so a fresh test profile could be exercised without changing the development profile. A separate `StealAnything_TestRoute_v1` profile checked the tighter route validation. `EnvironmentConfig.luau` was restored to `StealAnything_Dev_v1` afterward. The published production store was not used.

The phone checks used isolated `StealAnything_TestMobile_v1` and `StealAnything_TestMobileTouch_v1` Studio profiles. These temporary stores were used only for simulator testing and were restored to the development configuration afterward. No public game version was published during this test.

## Step 8 route validation follow-up — 12 October 2026

`CarryService.CheckDelivery` now samples the carrier's current server position before checking route validity. This closes the gap where a delivery remote could arrive between periodic 0.1-second samples immediately after a teleport. Rojo built successfully, the updated source was visible in the connected Studio place, and `TutorialLoop.spec.luau` passed again in Edit mode. The previous live remote, impossible-position, duplicate, and rejoin checks above remain the step 8 acceptance evidence.

After the second museum entrance geometry correction, the same in-memory delivery/income/rejoin test passed again in Studio Edit mode. A Play-mode character walked through the repaired doorway to the receiving pad without jumping. This checks navigation after the art change; the new six-plot ownership checks are scheduled for Task 11A.

## Remaining prelaunch checks

- Two real Studio clients picking up personal targets at once.
- Physical phone and controller pass for the guide, carry HUD, and hold actions. The iPhone 16 Studio simulator pass is complete.
- An unfamiliar person's end-to-end tutorial playtest using `docs/playtest.md`. The second-run objective and public stock are available; guard training remains in M2.

## Tasks 9–10 follow-up — 12 October 2026

The updated `TutorialLoop.spec.luau` passed in Studio Edit using a fresh clone of the synced server modules. A tier-1 and tier-5 copy of the same displayed toaster each earned $1 in ten active seconds; a stored or Missing toaster earned zero. The earlier fractional payout, one-hour offline, duplicate delivery, and rejoin checks still passed. This closes the Task 9 pure income invariant. The tier field remains a target-only test field until the Task 12 migration, so Task 19 must repeat it against real tier upgrades.

Task 10 adds a saved tutorial step when the first displayed dollar arrives. Step 1 teaches the active-server income; Step 2 points to the public depot heist. The step transition uses a durable idempotent profile operation after the routine income settlement; arbitrary routine tutorial mutations remain rejected. The in-memory test passed the transition and repeated operation, rejected an illegal step 3 routine mutation, and rejoined with step 2 and one toaster. `docs/playtest.md` contains the unfamiliar-player and device script. Public stock is active; guard behavior remains scheduled for Task 14.

In Studio Play, an existing development profile loaded at step 1 and committed `TutorialProgress / FirstIncomeSeen` after its first displayed payout. A data-store read showed revision 9 and step 2, with the protected toaster still registered. The client objective read `NEXT: DEPOT HEIST COMING SOON`. A normal test-player disconnect released the metadata lease and saved cash; rejoining restored `Ready`, step 2, one toaster, the $6/min rate, and the same objective. The guide at step 1 read `WATCH YOUR REWARD` and told the player to watch cash rise. A rapid Studio Stop/Play before disconnect left the prior metadata lease active and the new session waited for it; use a normal leave or wait for the lease to expire when testing rejoin. No runtime errors appeared in the Studio console.
