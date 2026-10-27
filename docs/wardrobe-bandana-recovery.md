# Imported bandana recovery — 26 October 2026

The owner reported that the red patterned imported bandana disappeared from the museum Studio Play character after a Rojo sync. The initial attempt to add a green, then plain red, code-drawn face covering was incorrect and has been removed.

## Original found

The open published museum place (place ID `94309819487664`, Studio place version 233 at inspection) still contains `Workspace.Handle.Bandana`, an imported `Part` with a `SpecialMesh`. Its mesh ID is `20637493` and its patterned texture ID is `75739837`. `Workspace.WardrobeAssetReview.RobberWardrobeVisuals.Bandana` is a fitted review copy with a head weld. The imported object itself was present in the place; the active wardrobe renderer had been constructing green geometry instead of cloning it.

The exact mesh and texture IDs are now stored in `src/shared/WardrobeAssets/Bandana.model.json`. `src/shared/WardrobeAppearance.luau` clones and fits that asset to the player's head for the free starter mask, including an older saved `starter_mask` Face slot. The original imported object in `Workspace` was left in place.

## Checks

- Rojo synced the new `Bandana` part and its `SpecialMesh` into `ReplicatedStorage.Shared.WardrobeAssets` in the open museum Studio Edit place.
- In museum Studio Play, the local character had a visible `RobberWardrobeVisuals.Bandana` with the same mesh and texture IDs. A front view showed a red cloth with white patterns.
- The map still had 17 top-level children, including `BoundaryArt` (102 children), `ExteriorDressing` (193), `DistantSilhouettes` (86), `HillTerrain` (15), and `LandscapeArt` (108). The 11 `ReplicatedStorage.VisualAssets` children and the original `Workspace.Handle` and `WardrobeAssetReview` objects were present. These checks establish presence, not equality with any unsaved earlier Studio session.
- The available local auto-recovery files for this museum place are dated 12–14 October; the newest local wardrobe Rojo build is dated 22 October. Neither is a complete record of later unsaved Studio edits. The original imported bandana was recovered from the currently open published place, not those backups.

The repo changes made in this session are limited to the cash HUD, interaction HUD, imported bandana asset, wardrobe appearance application, and their documentation. Rojo owns mapped code folders, so edits made only inside those Studio scripts can be replaced on sync. `Workspace.Map` and `ReplicatedStorage.VisualAssets` are configured to retain unknown instances. There is no recent full autosave available to prove that every unsaved Studio edit survived the forced close or the sync.
