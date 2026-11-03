# Local VFX preview room

This is a separate, development-only Roblox place. It is **not** mapped by
`default.project.json` or `lobby.project.json`. Do not publish this place to the
live experience or copy `vfx-preview/` into either live StarterPlayerScripts.

## Open it

1. From the repository root, run `./rojo.exe build vfx-preview.project.json -o build/VfxPreviewGallery.rbxl`.
2. Open `build/VfxPreviewGallery.rbxl` in Roblox Studio as a separate local place.
3. Press **Play**. The camera points at the selected sample station. No DataStore,
   purchase, inventory, carry, delivery, guard, or matchmaking code is present.
4. Use **Play**, **Replay**, and **Reset**. Select a station, cycle **Camera**
   through near (12 studs), medium (30), and gameplay (60), and cycle **Mode**
   through normal, low effects, and reduced motion. Hide the panel for an
   unobstructed view. Select **Exhibit** and cycle the item button to see all
   12 existing `SignatureVfxRecipes` on the neutral sample artifact. Select
   **Gallery** to see all twelve recipe geometries together on neutral proxies.

The built `.rbxl` is local and ignored by Git. Rebuild after changing a preview
file. A live Rojo connection is optional, but use this project file only.

## What the stations show

| Station | Preview source | What is mocked |
| --- | --- | --- |
| Pickup | Shared `PickupRarityVfx` geometry, now used by the live confirmed pickup controller | A hold and confirmed carry are simulated locally; no carry ID or item is granted. |
| Receiving | Shared `ReceivingPlatformVfx.luau`, also used by the live delivery feedback controller | Approach, processing, committed success, cancellation, and failure are mock state buttons; no collection or cash changes. |
| Extraction | Shared `ExtractionMachineVfx.luau`, also used by the live extraction feedback controller | Activation, 3.5-second charging, completion, and cancellation are local mock states; no teleport or guard noise occurs. |
| Restock | Client-only stand-in using current highlight and shimmer timing | A stock-ready event is simulated; no pedestal state changes. |
| Exhibit | The actual shared `SignatureVfx` and `SignatureVfxRecipes` modules | A neutral cube stands in for each authored item model. Low effects hides the recipe geometry; reduced motion freezes its motion. |
| Gallery | All twelve actual `SignatureVfxRecipes` at once | Twelve neutral cubes and simple stands are mock display targets. No real item mesh, actual museum lighting/layout, or exhibit audio is loaded. |

The pickup, receiving, extraction, and restock stations use **mock events**, not
live-controller playback. Pickup geometry is now shared with production, while
the receiving and extraction geometry is now shared with production. No preview control
changes carry, delivery, travel, restock, or lobby gameplay state. The exhibit
recipes are the actual shared geometry module, shown without item models or persistence.
The shared extraction hum uses user-inventory force-field clip `129267525484488`,
which loaded in Studio Edit at 4.68 seconds. Its audible mix and published-place
permission still need human review. Other preview stations remain silent.

## Pickup rarity reference review

Select **Pickup** and choose Common, Uncommon, Rare, or Legendary. **Play** and
**Replay** show a 0.45-second mock hold followed by a short confirmation. Press
**Reset** during the hold to verify that no success effect appears. Compare all
tiers at near, medium, and gameplay camera distances.

The four tiers differ in motion, not only color:

| Tier | Motion after the mock confirmation | Approximate duration |
| --- | --- | --- |
| Common | Small centered teal impact flash | 0.30 s |
| Uncommon | Gold center flash and five short upward flicks | 0.38 s |
| Rare | Purple center flash, brief four-point accent, and six directional streaks toward the camera side | 0.46 s |
| Legendary | Gold center flash and four-point accent, expanding segmented purple/gold ring, seven streaks, and five tiny sparkles | 0.52 s |

Low effects reduces geometry counts and removes extra sparkles. Reduced motion
shows a brief, static colored outline instead of moving geometry. Every visual
is parented to the disposable active preview root; Reset/Replay cancels tweens
and destroys that root. The ring uses short segments rather than a filled neon
disc, and all tiers leave the sample item visible.

This uses the **shape and rarity hierarchy** of the owner's pickup and loot
references conceptually. It does not copy their textures, assets, or exact
effects. After approval, the live `PickupFeedbackController` uses the same
shared geometry only after the server-set `CarryId` and `CarryItemId` confirm a
pickup; the existing single pickup sound remains. No separate higher-tier
chime is configured or claimed here. If a chime
is chosen later, its permission, loading, and mix need a Studio listening test
before use. Preview controls still grant no item or reward.

## Extraction machine reference review

Select **Extraction** and press **Play** for a mock 3.5-second activation:
0.35 seconds of mechanical shutter pulse, then 3.15 seconds of accelerating
ring charge. Only the simulated validated completion converges the inner ring
and flashes the center for about 0.3 seconds. Press **Cancellation** at any
point during charging: it cancels the scheduled completion, changes to an amber
power-down state, and returns to idle without a completion flash. State buttons
also allow direct inspection of Idle, Activation, Charging, and Completion.

This adapts Reference A into a horizontal pad: a shallow metal base, separated
teal deck rings, an elevated segmented crown with three thin charge filaments,
a recessed center, six short mechanical shutters, and a brief converging flash.
There is no large sphere, constant particle spray, or copied reference texture.
Normal mode uses 44 ring segments and six shutters; low effects uses 28 ring
segments and four shutters with slower updates. Reduced
motion keeps the state colors but stops ring rotation and the converging flash.
The controller owns one 20 Hz animation connection, cancels tweens, and destroys
all local geometry on Reset, Replay, or station change.

The live `TravelEffects.Teleport` sets `ExtractionActive`,
`ExtractionEndsAt`, and `ExtractionDuration`; after the final route/identity
check it sets `ExtractionOutcome` to `Completed` or `Cancelled`. The live client
uses those server-owned states and the validated pad position. This preview
uses mock states and does not alter teleport validation, guard noise, travel
effects, or purchases.

A user-inventory force-field clip `129267525484488` now fills the shared
`src/shared/ExtractionAudioConfig.luau` hum slot. The positional Sound fades
from base to peak volume with charge progress, then fades/stops on completion
or cancellation. Its 4.68-second length exceeds the normal 3.5-second
extraction, so a normal run should not wrap; still listen for startup quality,
permissions, unusual delayed-run loops, and volume against guard warnings.
The existing completion warp sound remains unchanged.

## Receiving platform reference review

Select **Receiving**. The platform starts at **Idle**. **Play** or **Replay**
runs this mock sequence: idle for 1 second, approach for 1.3 seconds, processing
for 1.4 seconds, then a mock committed success. Its gold response lasts about
0.7 seconds before settling back to idle. The six state buttons let you pause on
Idle, Approach, or Processing, or test Success, Cancel, and Failure separately.
Press **Cancel** or **Failure** during processing to confirm that the packets
stop and no gold success burst appears. **Reset** destroys the active preview
and reconstructs the quiet idle platform.

The reference's circular, layered platform informed the shallow dark steel
plinth, raised deck, two segmented cyan deck rings, a suspended receiver rim,
and recessed center. Its vertical light informed a controlled processing beam.
We did not reproduce the ceiling
structure, smoke, room lighting, or exact textures. The normal-distance view
is intended to judge the platform silhouette, not just its glow.

The preview model hierarchy is `ActiveReceivingPrototype` >
`ReceivingPlatformPrototype` > three deck disks, `OuterGuideSegment*`,
`InnerReceiverSegment*`, `InwardDirectionTick*`, `ProcessingBeam` with two
anchors, `ProcessingPackets`, and `ConfirmedSuccessOnly`. Idle has a gentle
ring pulse and no particles. Approach brightens the rings. Processing moves
eight short packets inward in bounded waves and enables a thin beam. Success
changes the rings to gold and emits one short burst of ten built-in sparkles.
Cancel briefly uses amber; Failure briefly uses red/orange. Both return to idle
without a success burst. Low effects uses fewer ring segments, four packets,
no beam, and three success particles. Reduced motion keeps state colors but
removes packets, beam, and particles.

This geometry is now wired to the live delivery feedback controller. The client has `CarryId`,
`AtDropOff`, and `DeliveryInProgress` for approach and processing, while a
unique `DeliveredDisplayed`/`DeliveredStored`/`DeliveredSalvage` success cue
from `DeliveryService` is the only valid source for a future success burst.
Rejected, cancelled, duplicate, and retrying deliveries must never be shown
as success. The prototype uses local mock controls only.

State changes cancel packet tweens and delete their parts. Leaving Success
deletes its particle holder, including on rapid Cancel/Failure. Reset and
selection changes disconnect the animation loop and destroy the whole local
model. Normal mode uses 56 ring/tick segments and at most eight moving packets,
updated at 20 Hz; low effects uses 30 static segments and four packets. Before
production, profile the design with six museums visible and cull distant
animation. Do not copy this preview directly into the live place.

Every replay destroys the previous local effect root and cancels its tweens.
Timed previews clean themselves up; the continuous exhibit preview remains until
Reset, Replay, another selection, or leaving Play. No RemoteEvents or server
services are used.

## Manual Studio checks

- Check all six stations at the three camera distances and in each effects mode.
- Compare Gallery at gameplay distance with one-at-a-time Exhibit. Then view the actual twelve displays together in the live museum; the proxy gallery cannot judge final composition or audio.
- Press Reset during extraction, then Replay; verify no marker, ring, particle,
  tween, or visual remains from the cancelled run.
- Cycle all 12 exhibit recipes and ensure the previous geometry disappears.
- Check the controls on a narrow Studio device viewport. This local preview
  layout has not been accepted on a physical phone.
- When a proposed effect is ready, add it as a **preview-only adapter** here for
  visual approval before integrating it with a live server-confirmed result.
