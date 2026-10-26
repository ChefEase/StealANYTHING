# B4/B5 landscape integration — 13 October 2026

## Studio assets and ownership

The four inspected Blender imports were `B4TreeTall` (37 MeshParts), `B4TreeRound` (54), `B5PlanterShrub` (27), and `B5RoundPlanter` (10). All four had valid MeshIds, empty TextureIDs, no SurfaceAppearance, grey Plastic, very large Blender-unit bounds, and enabled physics flags on import. Their original pivots and relative mesh transforms were preserved. The imported originals now live under `ServerStorage.Assets.LandscapeSourceImports` as server-only backups.

The runtime templates are under `ReplicatedStorage.VisualAssets.LandscapeKit`:

| Template | Source | Use |
| --- | --- | --- |
| `TreeTall` | `B4TreeTall` | Close ornamental tree variation |
| `TreeRound` | `B4TreeRound` | Alternate close ornamental tree |
| `RectPlanterShrub` | `B5PlanterShrub` | Two modules in each arrival bed; separate `Planter` and `Shrub` child Models |
| `ShrubOnly` | `B5PlanterShrub` | Existing side/rear planting sockets |
| `RoundPlanterShrub` | `B5RoundPlanter` | Existing urn and pot sockets; separate `Planter` and `Shrub` child Models |

The preparation source is `scripts/prepare_b45_landscape_assets.luau`. Run it in Studio Edit after Rojo sync if the templates need rebuilding from the originals. It only replaces templates carrying the `LandscapeTemplate` marker and leaves the originals intact. Rojo's `VisualAssets` and `ServerStorage.Assets` mappings use `$ignoreUnknownInstances: true`, so a sync preserves these Studio instances. **Save the place to a local `.rbxl` and reopen it to confirm the imported MeshParts survive a Studio session; Rojo source alone cannot recreate their MeshIds and geometry.** Publish/upload separately when Roblox cloud saving works.

## Visual builder changes

`src/serverStorage/Task11VisualKit.luau` v8 clones the templates, uniformly scales each whole Model, aligns its bounding-box bottom with the original landscape anchor, and applies a named-part palette only when no texture is present. The two close side trees on each landscape use alternating B4 forms. Distant ridge, shoulder and background trees remain cheap Part silhouettes because replacing hundreds of them with 37- or 54-mesh imports would be excessive. The plaza's close trees also use B4. Existing round pots use the B5 round module. Arrival beds use two B5 rectangular modules within the prior bed footprint; other beds retain their soil and edging and use B5 shrubs at the prior shrub positions. If a template is missing, the old primitive visual is used.

The palette assigns foliage green, wood trunks, cream limestone planters, teal and gold trim, and dark soil by individual MeshPart names. It does not add SurfaceAppearance or overwrite texture maps. All runtime cosmetic MeshParts are anchored, massless, and have `CanCollide`, `CanTouch`, and `CanQuery` disabled. Existing functional collision and gameplay cover in `Workspace.Map` were not edited. Tier-1 landscape models keep `ClearOnExpansion=true`; all replacements use the existing removable landscape sockets inside the 120-stud used grounds. The unused 280-stud expansion reservation remains clear.

## Checks actually run

- Ran the preparation script twice in Studio Edit: four source Models remained and five runtime templates remained, with 137 MeshParts total across those templates.
- Built the exterior, interior, all six landscape presets and shared world in Studio. `scripts/validate_task11_visuals.luau` passed: six preview museums, 25 sockets, three stands, and art physics/clearance assertions. `scripts/check_task11_routes.luau` passed public and covered pathfinding routes for all six plots.
- Ran `scripts/build_task11_visuals.luau` twice. Counts matched both times: starter 558 descendants/194 meshes, six presets 2,615/2,049, shared world 1,590/411. No duplicate visual roots appeared.
- Inspected a six-plot Studio preview: both tree variations, rectangular arrival planters, round planters and shrubs rendered at their intended anchors. Example heights: side trees about 11.7 studs, arrival modules about 2.9, round planters about 2.7. The imported parts were visible together with no apparent floating or large overlap in the inspected views.
- Started one Studio Play client and staged six visual museums. Three clone/cleanup cycles produced the same 7,560-descendant staged scene. After client streaming completed near the scene, the client saw six museums, 16 imported trees, 54 planters, 57 shrubs and 3,624 MeshParts. This verifies replication to one client, not an actual two-client session.
- Ran a desktop Studio render sample at 1182×366: entrance p95 18.2 ms/139 draws/21,024 triangles; gallery p95 18.2 ms/78 draws/12,322 triangles; plaza p95 18.0 ms/387 draws/112,328 triangles. This is not physical mobile performance evidence. Captured Output had no game error for these checks.
- `rojo build default.project.json -o build/B45LandscapeSourceCheck.rbxl` succeeded.

Physical mobile performance, a simultaneous multiplayer test, and a place save/reopen have not been run. The builder and asset layout are prepared, but persistence across Studio sessions depends on saving the place file containing the imported templates.
