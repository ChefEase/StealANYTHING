# Local VFX preview room

This is a separate, development-only Roblox place. It is **not** mapped by
`default.project.json` or `lobby.project.json`. Do not publish this place to the
live experience or copy `vfx-preview/` into either live StarterPlayerScripts.

## Open it

1. From the repository root, run `./rojo.exe build vfx-preview.project.json -o build/VfxPreview.rbxl`.
2. Open `build/VfxPreview.rbxl` in Roblox Studio as a separate local place.
3. Press **Play**. The camera points at the selected sample station. No DataStore,
   purchase, inventory, carry, delivery, guard, or matchmaking code is present.
4. Use **Play**, **Replay**, and **Reset**. Select a station, cycle **Camera**
   through near (12 studs), medium (30), and gameplay (60), and cycle **Mode**
   through normal, low effects, and reduced motion. Hide the panel for an
   unobstructed view. Select **Exhibit** and cycle the item button to see all
   12 existing `SignatureVfxRecipes` on the neutral sample artifact.

The built `.rbxl` is local and ignored by Git. Rebuild after changing a preview
file. A live Rojo connection is optional, but use this project file only.

## What the stations show

| Station | Preview source | What is mocked |
| --- | --- | --- |
| Pickup | Client-only stand-in using current hold and burst timing | A carry confirmation is simulated locally; no carry ID or item is granted. |
| Receiving | New client-only platform prototype in `ReceivingPrototype.luau` | Approach, processing, committed success, cancellation, and failure are mock state buttons; no collection or cash changes. |
| Extraction | Client-only stand-in using current marker and warp-ring language | A 3.5-second activation and completion are simulated; no teleport or guard noise occurs. Reset cancels it. |
| Restock | Client-only stand-in using current highlight and shimmer timing | A stock-ready event is simulated; no pedestal state changes. |
| Exhibit | The actual shared `SignatureVfx` and `SignatureVfxRecipes` modules | A neutral cube stands in for each authored item model. Low effects hides the recipe geometry; reduced motion freezes its motion. |

The first four stations are **preview mocks**, not exact live-controller playback
or approved redesigns. This keeps the existing pickup, delivery, extraction,
restock, and lobby gameplay contracts untouched. The exhibit recipes are the
actual reusable shared geometry module, shown without item models or persistence.
The room makes no sounds and creates no Sound objects; sound comparison remains
a separate listening task.

## Receiving platform prototype: review before production

Select **Receiving**. The platform starts at **Idle**. **Play** or **Replay**
runs this mock sequence: idle for 1 second, approach for 1.3 seconds, processing
for 1.4 seconds, then a mock committed success. Its gold response lasts about
0.7 seconds before settling back to idle. The six state buttons let you pause on
Idle, Approach, or Processing, or test Success, Cancel, and Failure separately.
Press **Cancel** or **Failure** during processing to confirm that the packets
stop and no gold success burst appears. **Reset** destroys the active preview
and reconstructs the quiet idle platform.

The reference's circular, layered platform informed the shallow dark steel
plinth, raised deck, two segmented cyan rings, and recessed center. Its vertical
light informed only a thin processing beam. We did not reproduce the ceiling
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

This is **not wired to production**. The existing client has `CarryId`,
`AtDropOff`, and `DeliveryInProgress` for approach and processing, while a
unique `DeliveredDisplayed`/`DeliveredStored`/`DeliveredSalvage` success cue
from `DeliveryService` is the only valid source for a future success burst.
Rejected, cancelled, duplicate, and retrying deliveries must never be shown
as success. The prototype uses local mock controls only.

State changes cancel packet tweens and delete their parts. Leaving Success
deletes its particle holder, including on rapid Cancel/Failure. Reset and
selection changes disconnect the animation loop and destroy the whole local
model. Normal mode uses 44 ring/tick segments and at most eight moving packets,
updated at 20 Hz; low effects uses 24 static segments and four packets. Before
production, profile the design with six museums visible and cull distant
animation. Do not copy this preview directly into the live place.

Every replay destroys the previous local effect root and cancels its tweens.
Timed previews clean themselves up; the continuous exhibit preview remains until
Reset, Replay, another selection, or leaving Play. No RemoteEvents or server
services are used.

## Manual Studio checks

- Check all five stations at the three camera distances and in each effects mode.
- Press Reset during extraction, then Replay; verify no marker, ring, particle,
  tween, or visual remains from the cancelled run.
- Cycle all 12 exhibit recipes and ensure the previous geometry disappears.
- Check the controls on a narrow Studio device viewport. This local preview
  layout has not been accepted on a physical phone.
- When a proposed effect is ready, add it as a **preview-only adapter** here for
  visual approval before integrating it with a live server-confirmed result.
