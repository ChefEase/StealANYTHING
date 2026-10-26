# Task 11 environment follow-up: ridges, pavilion, dusk and seats

**12 October 2026. Visual kit v5 implemented in the connected Studio place.** This follows the [museum visual report](task11-visual-report.md). The original playable `Workspace/Map` remains active until Task 12 connects player-owned plots. The six-museum district is inspectable at `Workspace/Task11InspectionPreview`.

## Design decision and implementation

**Central structure:** The district has **one Public Acquisition Pavilion**. It is the shared depot for the existing tutorial pedestal and three later public-stock pedestals. It also serves as a curator information hub in the visual design. A stronger arrival arch, two roof wings, warm light ribbons, banners, a curator counter and wayfinding signs establish it as the center of the district. The four pickup sockets, their positions and stock behavior were not changed. The counter creates no new interaction.

**Edge landforms:** The northern and southern edges now have overlapping rounded grass mounds with varied heights, rock clusters and planted toes. Lower mounds frame selected east/west corners. A continuous grass apron joins the existing field at its outer edge so the hills cannot float over empty space. The landforms begin outside the 1,000 × 1,080-stud playable ground and the six 280 × 280 plot reservations. Wide gaps remain at the four cardinal approach corridors for future map connections. These are anchored, noncolliding visual scenery, not Roblox voxel Terrain or traversable new play space. Four invisible collidable walls at the original world perimeter prevent players falling from the six-museum district; the walls have their own `PerimeterCollision` root and do not move any original path or plot.

**Perimeter density and local mist:** Trees follow the ridge slopes in varied sizes, with boulders and low planting at the feet. Eight low-rate mist emitters are confined to those far ridges and shoulders. The core depot, museum gates, public paths and covered paths have no local mist emitters. The existing global Atmosphere was reduced slightly, keeping routes readable. There is no weather or day/night loop.

**Early-evening lighting:** `ClockTime` is 17.85, with cloud cover, softer blue-gray ambient fill, modest contrast and readable warm gallery/entrance lights. The [Roblox Clouds API](https://create.roblox.com/docs/reference/engine/classes/Clouds) requires its object under `Terrain`; the lighting script creates only its named `Task11Clouds` instance. The [ParticleEmitter API](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter) supplies local edge mist. `default.project.json` agrees with the authored global ClockTime, Brightness and ambient colors so Rojo sync does not revert those base values.

**Plots:** Every starter plot receives a restrained second layer of side-garden gravel, low shrubs, arrival stone bands and small marker lights inside the existing ±59-stud grounds limits. These details remain descendants of the removable landscape preset. Building footprint, gate and receiving lane are unchanged. The 280-stud upgrade reservation outside the starter grounds remains free of permanent props.

**Sitting:** Selected gallery, garden and plaza benches in the reusable kit have invisible anchored Seats and native Roblox Sit prompts. All four front benches and the depot bench in the playable prototype have the same capability through `scripts/apply_task11_prototype_seats.luau`. The Seats sit above the visible bench surfaces. `SeatService` checks the player, humanoid, distance, seat occupancy and active carry on the server before calling `Seat:Sit()`. While seated, the native Sit prompt is disabled and a local native **G / Stand** prompt appears for that player. The custom interaction HUD remains hidden. Seats are sit-only, anchored, and have no carry integration. The [Roblox Seat API](https://create.roblox.com/docs/reference/engine/classes/Seat) supports this pattern.

## Studio views

| View | Screenshot |
| --- | --- |
| Shared acquisition pavilion at dusk | [v4-pavilion.jpg](task11-screenshots/v4-pavilion.jpg) |
| Designed ridge and tree line | [v4-ridge.jpg](task11-screenshots/v4-ridge.jpg) |
| Rounded and grounded edge hills after player feedback | [v5-ridge.jpg](task11-screenshots/v5-ridge.jpg) |
| Museum approach at dusk | [v4-museum-dusk.jpg](task11-screenshots/v4-museum-dusk.jpg) |
| Whole district and outer framing | [v4-district-dusk.jpg](task11-screenshots/v4-district-dusk.jpg) |

## Verification

- Rojo build passed after the code and Lighting updates.
- Original functional geometry fingerprints remain unchanged: museum 50 parts / 447533886 and playable prototype 927 / 2371593528. The world audit reports 113 original functional parts / 3056087353 after excluding the new, separately checked perimeter walls and visual folders.
- The visual validator passed with 1,753 checked source art parts, 25 existing museum sockets, three display stands and six correctly assigned preview plots. All art remains anchored, noncolliding, nontouching and nonqueryable.
- Four-stud-agent no-jump public/covered route checks still measured 347/429, 365/390, 362/388, 343/440, 368/392 and 365/389 studs for plots 1–6. All tested side approaches used the legal gate.
- Three visual spawn/cleanup cycles produced exactly 4,192 descendants each; the temporary runtime scene was removed after testing.
- In Play, activating a prototype bench prompt seated the player on its corresponding Seat. The server reported `Humanoid.Sit = true` and that Seat as `SeatPart`.
- A Studio client with six staged visual museums resident measured 16.6 ms median frame time at entrance, gallery and plaza views. Their 95th-percentile times were 17.9, 18.0 and 18.1 ms respectively. The desktop viewport was 1,182 × 326. Studio reported about 1,470 MB total client memory during this run; this includes editor/test overhead and is not a physical mobile result.

### v5 correction checks

- In Studio Play, a player 2.55 studs from a prototype bench saw `ProximityPromptStyle.Default` with the game HUD hidden. The native E Sit prompt seated the player; its `Enabled` state became false while the game HUD showed `G` and `STAND UP`. Pressing G returned `Humanoid.Sit = false`, cleared `SeatPart`, hid the game HUD and re-enabled the native Sit prompt.
- The six-district source pack has four invisible, anchored collision walls. A ray from inside the east edge hit `EastWestWall` at world x = 2,498 in the staged scene (local x = 498), before the original ground ends at local x = 500. All four walls are checked for size, position, collision and transparency by `scripts/validate_task11_visuals.luau`.
- In Studio Play, moving a character from world x = 2,488 toward x = 2,520 stopped its root at x = 2,497.45, inside the east edge of the existing ground (x = 2,500).
- The v5 visual validator passed with six preview museums and 1,745 source art parts. The geometry audit retained the same museum and prototype fingerprints; it separately excludes the intentionally added `PerimeterCollision` root. All six no-jump public and covered route lengths remained the values above. Three staged clone/cleanup cycles contained 4,189 descendants each.

## Reproduce and remaining work

After Rojo sync, run `scripts/build_task11_visuals.luau`, `scripts/apply_task11_lighting.luau`, `scripts/fix_task11_prototype_landscape.luau`, `scripts/apply_task11_prototype_seats.luau`, then `scripts/preview_task11_plots.luau` in Studio Edit. The builders refresh their owned visual roots, the landscape fix is idempotent, and the prototype seat script safely replaces only its own folder. Save the Studio place to retain the generated templates, prototype landscape changes, seat proxies and named cloud instance. The preview has `Archivable = false`, so it will not publish as live gameplay. Select `Workspace > Task11InspectionPreview > Museums > Museum01–Museum06` and press **F** to inspect each plot.

The v5 pass does not claim real-device mobile performance or six player-owned museums. Task 12 must connect owner assignment, saved exhibits, delivery, cleanup and server player cap to the source templates. Physical phone/controller and full-server performance remain acceptance checks. New landforms and the boundary occupy the current world edge and should be reviewed if a later plan extends the map into those reserved approach gaps.
