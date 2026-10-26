# B6–B9 Task 11 visual integration — 13 October 2026

## Inspected imports and template hierarchy

Eight Models were found in `Workspace`; no B7 wall sconce import was found there or in the existing template folders. Each found import had MeshParts with valid mesh geometry, grey Plastic coloring, empty TextureIDs and no SurfaceAppearance. They were unanchored and collidable on import. Original model pivots and internal transforms are unchanged. The complete originals now live in `ServerStorage.Assets.B6789SourceImports`; the styled runtime clones live in `ReplicatedStorage.VisualAssets`:

| Runtime template | Original MeshParts | Purpose |
| --- | ---: | --- |
| `RockKit.B6RockLow` | 16 | Low ridge rock |
| `RockKit.B6RockTall` | 16 | Vertical ridge rock |
| `RockKit.B6RockArch` | 22 | Arch ridge rock |
| `LightingKit.B7SpotlightHousing` | 17 | Three exhibit spot housings per museum |
| `DisplayKit.B8PedestalDetailedRing` | 18 | Trim around each existing stand |
| `ServiceKit.B9Pallet` | 42 | Service yard pallet |
| `ServiceKit.B9ServiceCrate` | 64 | Crate on pallet |
| `ServiceKit.B9Generator` | 42 | Service yard generator |

`scripts/prepare_b6789_visual_assets.luau` reproducibly moves any still-in-Workspace originals to the server-only backup folder and rebuilds only templates marked `B6789Template`. Running it twice left eight originals and eight templates. `default.project.json` already preserves unknown instances in both `ServerStorage.Assets` and `ReplicatedStorage.VisualAssets` during Rojo sync. **The imported geometry still needs a successful Studio place save and reopen to prove persistence across sessions.** Rojo source cannot rebuild MeshIds from the code alone.

The source-owned palette in `src/serverStorage/Task11VisualKit.luau` colors individually named meshes: slate/stone rocks with gold and teal accents, dark metal spotlight housings, warm lenses, limestone and gold stand trim, wood pallets/crates, and dark metal generator parts. It skips parts with textures or SurfaceAppearance and adds no generated maps. All runtime MeshParts are anchored, massless, and noncollidable, nontouchable, and nonqueryable.

## Integration choices

- **B6:** Twelve imported rock modules alternate deterministically at existing north/south hill positions. The source toe-rock anchors at ±551 studs were behind the 80-stud perimeter wall; the imported copies use the same hill x anchors on the visible inner toe at ±503, outside plot reservations and traveled routes. Uniform scale is capped to 7.5 × 5.5 × 6.5 studs. The second primitive toe rock and existing hills/ground extensions remain. Existing rounded hills are visual Roblox Parts, **not Roblox Terrain**; this integration did not convert them because that would change the established landform and collision design.
- **B7:** Three imported spotlight housings per museum surround the existing SpotLight-bearing parts. Those light-bearing parts remain in place, at their original brightness/range, but their primitive bodies are transparent. No new light count or shadows were added. Existing exterior A2 backplates and functional lantern lights remain because the new wall sconce import is missing.
- **B8:** Each of the protected, exposed 01 and exposed 02 stands gets one ring module below its original top surface. The ring stays under the collectible support height. Only the redundant cosmetic `StandEdge` Parts are omitted when the ring template exists. Stand and stand-top collision geometry, display sockets, IDs, labels, and SpotLights remain unchanged. The current source has no separate temporary trophy display builder to decorate.
- **B9:** One generator, one pallet, and one crate replace primitive counterparts within each existing removable tier-1 landscape `ServiceArea`. The crate sits on the pallet. Service paving, screen, notice, drain, and gameplay routes remain. The modules use the prior service anchors and fit inside the original service footprint.

## Checks actually run

- All eight templates were prepared twice in Studio Edit with no duplicate templates.
- Two complete `build_task11_visuals.luau` passes had identical counts: starter 663 descendants, six landscape presets 3,467, world 1,806.
- `validate_task11_visuals.luau` passed for six preview museums, 25 sockets, three stands, and 5,122 art parts. `check_task11_routes.luau` passed public and covered pathfinding for all six plots.
- One Studio Play client received the staged six-museum scene with 18 B8 rings, 18 B7 housings, 18 B9 prop modules, 12 imported rocks, and 5,358 MeshParts after streaming. Three clone/cleanup cycles held steady at 9,258 descendants. Server and client Output showed bootstrap messages and no game errors in the captured run.
- Studio viewport inspection confirmed the stand rings sit below the tops, the crate sits on the pallet, and the moved arch rock is visible inside the perimeter wall. A first B6 scale produced an oversized tall rock; it was corrected before final checks.
- `rojo build default.project.json -o build/B6789SourceCheck.rbxl` succeeded.

No physical mobile performance test, simultaneous multiplayer test, Rojo reconnect and Studio reopen test, or interactive place/protect/steal/recover exhibit playthrough was run. General exhibit theft and recovery services are not present in the current Task 11 source; the visual change leaves their future sockets and references intact. A B7 wall sconce import is still required to complete that part of B7.
