# Task 5 map and visual pass

**Current map ownership:** `Workspace/Map` is edited in Roblox Studio and is no longer synced by Rojo. This page records the earlier generated graybox checks; do not sync `assets/places/MainMap.model.json` over the restored Studio map. The restored version 53 map, with its four original invisible boundary walls raised to 64 studs, is backed up at `assets/places/MapRestoredFromVersion53.rbxm`.

## Source and instance ownership

`scripts/build_graybox_map.py` generated the earlier `assets/places/MainMap.model.json` graybox. It is retained as reference and is not mapped by the current Rojo project. The current map lives in the Steal Anything Studio place (`PlaceId 94309819487664`).

## Top-down layout

The museum is centered at `(65, 60)` and measures 36 × 30 studs. Its south entrance is 12 studs wide and 14 studs high. Spawn is toward the north/back wall, facing the entrance. The teal 10 × 10 receiving pad is centered at `(65, 52)`, inside the door. The raised gold 8 × 8 protected stand is near the back wall at `(75, 70.5)`, with a blue shield badge. Two side display placeholders leave a 12-stud central aisle. The orange recovery console is on the west side, away from the entrance.

The 12 × 12 depot pedestal is centered at `(-92, -72)`. The open route is 18 studs wide and crosses the plaza to the south entrance. The covered route is 14 studs wide, with 18 × 18 corner pads and three turns: `(-99, 52)`, `(-20, 52)`, and `(65, 25)`. Three solid, 14-stud-high walls break sightlines from the plaza; canopies and support posts mark the detour. Exits remain visible, and supports sit outside the clear walking lane.

### Distance and time targets

One-way distances start at the **reachable east side** of the pickup pedestal, `(-83, -72)`, and end on the receiving pad `(65, 52)`. After the exhibit and landscape refinement, no-jump pathfinding measured **205.2 studs open** and **320.5 studs covered** with a 2-stud agent radius. The estimates below use the 200/320-stud design targets; they exclude pickup, hesitation, turns, and pursuit.

| Route | Target distance | Empty at 16 studs/s | Normal carry at 12 studs/s | Heavy carry at 10 studs/s |
| --- | ---: | ---: | ---: | ---: |
| Open | 200 studs | 12.5 s | 17 s | 20 s |
| Covered | 320 studs | 20 s | 27 s | 32 s |

The covered choice costs about 10 seconds with a normal carry or 12 seconds with a heavy carry. Those are starting targets, subject to movement and guard playtests.

## Stable sockets

Every invisible socket is anchored, non-colliding, queryable, touchable, tagged `MapSocket`, and has unique string `SocketId` and `SocketKind` attributes.

| Socket ID | Use |
| --- | --- |
| `museum_01.receiving` | Owner delivery zone |
| `museum_01.protected` | Protected display position |
| `museum_01.recovery_console` | Recovery console placeholder |
| `museum_01.raid_entrance` | Marked raid entrance |
| `museum_01.approach` | Shared route arrival marker |
| `depot.tutorial_pedestal` | Tutorial pickup position |
| `route.open.start` | Open route marker |
| `route.covered.start` | Covered route marker |

## Verification — 11 October 2026

- Rojo built `build/StealAnything.rbxl` from the regenerated map.
- In Studio, no-jump pathfinding with a 2-stud agent radius succeeded for every open and covered route segment, starting from the accessible side of the pickup pedestal. After solid props were added, path lengths summed to 204.3 and 320.5 studs.
- A live character traversed the open route from the depot side to the receiving pad, then the covered route through all three turns to the same pad. Every navigation step returned `Success`; the character ended on the pad.
- A horizontal ray from a plaza-side viewpoint toward three covered-route points hit `CoverWall01`, `CoverWall02`, and `CoverWall03` respectively. The walls provide physical line-of-sight interruption.
- Geometry inspection found a 12-stud entrance gap, 14 studs of clear height, a 10 × 10 receiving pad, an 8 × 8 protected stand, a 12 × 12 depot platform, and eight unique sockets. The cover walls are 14 studs high; the current character's reported `JumpHeight` was 7.2 studs.

## Visual pass — 11 October 2026

- The museum has a raised cornice, framed door, shallow pilasters, wall panels, two planters, and a readable name sign. Inside are calm stone-colored tile divisions, wood dado and trim, framed collection posters, ceiling beams, and warm light fixtures.
- Side and protected displays have layered bases, stems, tops, and nameplates. The protected stand adds gold trim, a shield sign, and a spotlight. The receiving mat has a gold border, floor arrows, and a `DROP-OFF` sign. The recovery kiosk has a screen, angled controls, and a recovery symbol.
- The open path has paving joints, limestone edging, and direction arrows. The covered path has brick lower wall cladding, metal coping and pipes, supports, awnings, and lamps. The depot has a loading awning, stock shelf, warning marks, crates, and a sign facing arriving players.
- Grass, planted beds, stylized trees, and distant building silhouettes replace the plain backdrop. The original 2048-stud template Baseplate was removed from the connected Studio scene. `ScenicGround` extends the view beyond the finite 220 × 180 collision ground but is non-colliding and non-queryable. Lighting is set to 16.2 ClockTime for angled afternoon shadows, with warm interior fixtures.
- Player-height Studio captures were inspected from the museum approach, both interior directions, the first covered passage, and the depot. Trim, signs, lamps, and the scenic apron remain non-colliding. All eight socket IDs remain unique, and plaza-side rays still hit the three cover walls.

## Solid outdoor props — 11 October 2026

The tree trunks and crowns, planted beds and shrubs, façade planters, depot bench and stock shelf, loading crates, awning, and support posts now have `CanCollide = true` and `CanQuery = true`. The bench has a solid seat and legs. The left planter, first tree, bench, and crates were moved away from the direct walking lane before the collision change. Horizontal rays through the tree, shrub, bench, and crate hit their solid parts. No-jump pathfinding succeeded on every segment with both 2-stud and 4-stud agent radii; the wider agent measured 206.1 studs open and 321 studs covered. Small trim and signs remain non-colliding.

## Four visual refinements — 11 October 2026

- Replaced broad side-display slabs with solid pedestals, framed display cases, subtle glass, placeholder exhibit forms, and readable nameplates. The protected slot keeps its socket and 8 × 8 area but uses a narrower raised plinth, wood display surface, and thin gold rails instead of a solid yellow top. The cyan SpawnLocation is invisible and non-colliding; a live Play character still spawned safely on the museum floor.
- Rebuilt the eight trees as three loose groups near the south, northwest, and east boundaries. Trunk heights and yaw vary; canopies use differently sized overlapping rounded forms. The physical trunks and crowns remain collidable.
- Added side-wall rails, lower panels, lamps, signs, and fuller climbing greenery. Added piers, signs, and greenery to the service cover walls on or outside the existing wall faces; the three cover walls and route openings are unchanged.
- Switched grass and floor tiles to calmer SmoothPlastic surfaces with subtle tile color variation. No-jump pathfinding still succeeds for 2- and 4-stud agent radii. The current lengths are 205.2/320.5 studs for radius 2 and 207/321 studs for radius 4. All eight socket IDs remain unique.

The largest heavy object and guard do not exist yet, so their collision, camera behavior, sight model, and actual carry times remain Task 14/guard playtests. Before signing off those later tasks, walk both routes carrying the largest object without dash, check that turns do not snag or hide the camera, and try jumping onto cover to look for a shortcut. This paragraph records the Task 5 map snapshot; the tutorial pickup, delivery, ownership, and UI were added in later tasks.

## Front entrance repair — 12 October 2026

The connected Studio map had several open and covered route slabs with identical 0.60-stud top faces across the forecourt. That caused visible pavement flicker. The approach plaza now has one collidable visible top face at 0.68 studs; the route slabs remain underneath for their socket and route metadata. The entrance steps, mat, and threshold were realigned to rise toward the 1.00-stud museum floor. The two upper front wall panels and frames were moved from outside the building onto the actual front walls. `scripts/fix_museum_entrance.luau` reproduces these Studio-owned changes if an older map backup is restored.

Player-height screenshots from the center and left approach showed a stable floor and aligned front walls. No-jump pathfinding still reached the receiving pad from the depot pickup edge with 2-stud radius (203.4 studs, 55 waypoints) and 4-stud radius (212.0 studs, 55 waypoints), and from the forecourt (23.8 studs, 9 waypoints). Receiving and display sockets remain at their previous positions. Save the connected Studio place after reviewing the change.

**Second entrance correction — 12 October 2026:** A closer Play-mode inspection showed the first stair/mat layout still stacked visible surfaces. The live map now uses four adjacent one-stud-deep bands rising from the forecourt to the interior floor; the entrance mat sits only on its matching band. The broad duplicate upper wall skins are hidden, leaving the solid limestone front wall visible. Six later-added exterior columns and caps were also hidden because their front faces coincided exactly with the core wall face and could flicker while moving. The facade's original pilasters still frame the door. A character walked from the forecourt through the doorway to the receiving pad in Play mode. No-jump paths from the forecourt remain successful for 2- and 4-stud agents (23.9 and 27.9 studs). A focused geometry scan found zero coplanar visible top-face pairs and zero coplanar visible front-face pairs in the entrance area. The updated `scripts/fix_museum_entrance.luau` is the reproducible Edit-mode repair; the connected Studio scene already has these edits.

## Reference use

- [Stylized Museum Map: from level block-out to finished environment](https://www.artstation.com/artwork/xDWzXO): museum graybox-to-art direction.
- [The Level Design Book — Layout](https://book.leveldesignbook.com/process/layout): top-down route and room planning.
- [The Level Design Book — Blockout](https://book.leveldesignbook.com/process/blockout): test circulation and sightlines in the playable blockout.
- [Hall of Science VR Experience](https://anandshukla.artstation.com/projects/49ANBk): later display and visual style reference only.

The cited *Cost of Culture* breakdown could not be uniquely identified from the title alone, so no layout detail was copied from it.
