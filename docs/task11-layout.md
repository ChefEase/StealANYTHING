# Task 11: six plot layout and starter template

**Date:** 12 October 2026. **Status:** layout and template prepared in Studio; activation belongs to Task 12.

## Source and reproduction

`src/shared/PlotDefinitions.luau` defines the five tier targets and six fixed plot slots. After Rojo sync in the connected place, run `scripts/build_task11_templates.luau`, then `scripts/build_task11_visuals.luau` in the Studio Edit command context. The second script adds the reusable architectural kit, six deterministic local-coordinate landscape presets, and shared plaza details under `ServerStorage/Assets/Task11MapTemplates`. Both builders only replace their own generated folders. Save the Studio place to retain the generated models; the scripts are the reproducible repository source.

The original playable `Workspace/Map` remains active for the current toaster loop. The new assets stay in ServerStorage until Task 12 assigns player plots and switches the game services together. Rojo preserves the generated pack because `ServerStorage/Assets` ignores unknown instances. `src/shared/Task11VisualDefinitions.luau` is the single source for palette and preset IDs; Task 12 should clone the selected preset into a player's museum after pivoting it, and destroy it with that museum.

### Inspecting the six plots in Studio

Run `scripts/preview_task11_plots.luau` in Studio Edit. It creates `Workspace/Task11InspectionPreview` about 2,000 studs away from the playable prototype and focuses `Museum01`. In Explorer, expand `Task11InspectionPreview > Museums`, select `Museum01` through `Museum06` one at a time, and press **F** to move the camera to each selection. The six copies receive landscape presets 1–6 in order, so orientation and variation can be inspected together. The upper-right view cube changes the viewing angle. Select `World` to inspect the central depot and overall layout.

The preview folder has `Archivable = false`, so Studio does not save or publish it. It is visual inspection only and contains no live plot ownership. Run `scripts/clear_task11_preview.luau` when finished, or close/reopen the place; the builder and source templates remain available.

## Geometry contract

| Tier | Building | Stands | Used grounds |
| ---: | ---: | ---: | ---: |
| 1 | 60 × 60 | 3 | 120 × 120 |
| 2 | 80 × 80 | 6 | 160 × 160 |
| 3 | 110 × 110 | 10 | 200 × 200 |
| 4 | 140 × 140 | 15 | 240 × 240 |
| 5 | 170 × 170 | 20 | 280 × 280 |

Every slot reserves a fixed 280 × 280 envelope. The world ground is 1,000 × 1,080 studs; the depot is at (0, 0). Slot center coordinates (X, Z) and yaw in degrees are:

| Slot | Center | Yaw |
| --- | --- | ---: |
| plot_01 | (0, 360) | 0 |
| plot_02 | (320, 180) | 90 |
| plot_03 | (320, −180) | 90 |
| plot_04 | (0, −360) | 180 |
| plot_05 | (−320, −180) | −90 |
| plot_06 | (−320, 180) | −90 |

The axis-aligned maximum envelopes do not overlap; the minimum edge separation is 40 studs. The starter gate is 300–317 studs from the depot center, depending on slot. The 60-stud hall and 120-stud grounds have matching physical footprints. The 16-stud grounds gate and 14-stud hall doorway line up with the receiving mat. Walls and fences are collidable; the gate is the legal entrance. Exterior wall and entrance floor bands meet without coplanar overlap in the inspected phone-sized view.

The starter museum contains exactly three stand anchors: one protected and two exposed. It also has spawn, receiving, recovery, raid entrance, approach, and plot-gate sockets, plus four expansion-edge anchors for each of tiers 2–5. There are 25 unique tagged sockets in the museum template. The world template contains the six origin/gate reservations, a tutorial depot pedestal, three future public-stock pedestals, open approaches, covered-route cover walls, and tier-specific covered waypoints. Template `SocketId`s start with `template.`; Task 12 must assign unique per-clone IDs, validate server-owned plot ownership, and query sockets inside the active Workspace clone. Do not save temporary slot assignment or clone identity in profiles.

## Studio checks

Temporary preview clones were staged in Workspace and removed after checking; the source pack remains in ServerStorage. `PathfindingService` checks used a 4-stud-radius agent with jumping disabled. Both starter paths and mock tier-5 paths reached the entrance for all six plots.

| Slot | Tier-1 open | Tier-1 covered | Tier-5 open | Tier-5 covered |
| --- | ---: | ---: | ---: | ---: |
| 01 | 347 | 429 | 289 | 367 |
| 02 | 365 | 390 | 323 | 353 |
| 03 | 362 | 388 | 317 | 347 |
| 04 | 343 | 440 | 288 | 367 |
| 05 | 368 | 392 | 317 | 347 |
| 06 | 365 | 389 | 323 | 348 |

Distances are approximate studs from depot center to the museum entrance, including the prescribed covered waypoints. The tier-5 check used 280-stud mock fences with one legal gate, not finished tier-5 architecture. In the tier-1 preview, six side-approach paths crossed the front fence only through the 16-stud gate; a ray into the right fence hit the solid fence. This confirms the current geometry gives no traversable fence shortcut at the tested radius, although later movement abilities require their own bypass tests.

Studio's iPhone 17 Pro simulator showed the starter entrance at 874 × 402 landscape resolution without visible wall/floor overlap or a blocked doorway. In a one-client Play streaming check with six starter preview museums, the client had 413 preview BaseParts near the staged map and 39 after returning roughly 2,000 studs to the old prototype. `Workspace.StreamingEnabled` was true. This is a streaming smoke check, not a frame-time or six-player maximum-tier performance result; Task 34 measures the finished world on named devices.

The longest starter covered path is about 440 studs. At an unmodified heavy-carry speed of 10 studs/second that is about 44 seconds before interaction and turns. Task 15 must test carry feel and Task 27 must remeasure the 45-second raid deadline after sprint and counter-abilities exist. The future depot guard at Task 14 needs route/path recomputation tests across all six entrances; no guard AI exists yet.

## Visual pass handoff

**Visual kit v5 is implemented and tested in the connected Studio DataModel.** See the [museum visual report](task11-visual-report.md) for the v3 baseline and the [environment follow-up](task11-environment-followup.md) for rounded edge hills, the district boundary, the central acquisition pavilion, dusk, local mist, sitting and regression results.

The reusable implementation is `src/serverStorage/Task11VisualKit.luau`. Generic architecture and interiors clone with the museum; each deterministic landscape is applied as `BackyardVisuals` beneath that clone. The shared plaza, depot, paths and perimeter clone once with the world. All decorative parts are anchored, noncolliding, nontouching and nonqueryable.

Run `scripts/build_task11_visuals.luau` and `scripts/apply_task11_lighting.luau` after Rojo sync, then recreate the inspection preview. `scripts/apply_task11_live_visuals.luau` refreshes compatible existing 60 × 60 starter clones without accumulating legacy layers; it skips the older 36 × 30 prototype. Save the Studio place to retain the generated source assets. The repository builders reproduce them.

Final validation passed: 25 sockets, three stands, six correctly oriented presets, unchanged functional geometry, no blocked public/covered routes, and identical descendant counts across three runtime visual clone/cleanup cycles. The original Task 11 layout result remains valid. Full player-owned lifecycle tests belong to Task 12. Physical mobile performance is not verified: simulator timing was inconsistent with the approximately 60 FPS desktop sample. Do not treat the visual implementation as a completed multiplayer or physical-device acceptance gate.

## Task 12 handoff

Clone the world once; reserve a free plot on the server; clone and pivot the starter museum to its slot center/yaw; assign unique ownership and socket IDs; reconstruct saved tier, layout, and exhibits; then point pickup, delivery, guide, income visual, and raid lookups to that assigned clone. Migrate existing `exposed_03` placement to storage while preserving its registration. On failed load or leave, release the slot and destroy only that player's clone. Re-run Q02, Q10, Q29, Q31, and Q37 in a two-client and six-client session.
