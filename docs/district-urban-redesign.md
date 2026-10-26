# Six-museum urban district, 16 October 2026

The first visual pass keeps all six plot centers, the 280 x 280 maximum
upgrade reservation for each plot, the depot, both route types, and the
starter museum template. It changes the runtime appearance of the outdoor
district. No plot IDs or coordinates are saved to a player profile.

## Runtime layers

`PlotService` clones the Studio-owned `SixPlotWorldTemplate`, pivots it into
place, then calls `DistrictUrbanVisuals.Build` before parenting the district
to Workspace. The urban builder removes the cosmetic ridge/tree backdrop,
changes the ground finish to concrete, and creates `UrbanDistrict`:

| Folder | Purpose | Upgrade behavior |
| --- | --- | --- |
| `CityBoundary` | Building facades inside the existing collision boundary | Outside all plot reservations |
| `InnerBlocks` | Four public civic/security buildings and plazas | Outside all plot reservations |
| `ServiceYards` | Four service bays framing the east and west public lanes | Outside all plot reservations |
| `Checkpoints` | Six numbered kiosks and overhead wayfinding signs | Outside all plot reservations |
| `PlotParcels` | Shallow paving outside the current 120-stud grounds | Marked `ClearOnGroundsUpgrade` |

`DistrictOutdoorDetail` builds six removable `VacantPlotScenery` models. Each
has a closed annex and stone yard. `PlotService` unparents that model before
the player's museum appears and restores it after the museum is destroyed.
The old generated `GrassFill` is no longer built at runtime.

## Blender replacement contract

Each urban building or kiosk is a Model with a ground-level pivot, a `Visual`
child, a separate invisible `CollisionProxy`, and `VisualBounds`/
`VisualSwapSlot` attributes. A future imported Blender model should replace
only `Visual`, retaining the parent pivot and collision proxy. Its entrance
side faces local negative Z. The vacant `UnclaimedAnnex` uses the same
separation. Check an import's actual bounds and pivot in Studio before a
swap; do not scale the collision proxy to match decorative overhangs.
Keep player-height collision simple and test jumping around each model.

## Verification and limits

Run `scripts/validate_district_urban.luau` in Studio Edit after Rojo sync.
It creates and removes a temporary preview, checks that all 46 permanent
collision modules lie outside the six full upgrade reservations, walks all
six open and 18 covered route segments without jumping, stages a complete
starter museum and grounds to check its entrance, and checks vacancy cleanup.
The 16 October Studio run passed. Studio Play then assigned one loaded player
to plot 01 with its annex removed and the other five annexes present.
Studio stopped responding to a later repeat of the validator after Play
stopped, so that repeat has no result.

This is a visual-scale change. Plot coordinates and travel times have not
changed. Published appearance, two-player robbery, six-museum load, and
physical mobile/controller performance remain to be tested. The authored
Studio template remains unchanged; the runtime district appears during Play.
