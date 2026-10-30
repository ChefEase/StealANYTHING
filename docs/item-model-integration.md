# Imported collectible models

The eleven new Blender imports were prepared in Studio Edit on 29 October 2026. Their untouched Models were moved from `Workspace` to `ServerStorage.Assets.ItemSourceImports`. Reusable gameplay copies are in `ReplicatedStorage.VisualAssets.ItemModels`, keyed by the exact catalog item IDs. The Dramatic Toaster uses its existing imported `VisualAssets.DramaticToaster` template and its existing appearance module.

| Size class | Items | Maximum prepared height / width |
|---|---|---|
| Small | Toaster, Rubber Duck, Jelly Lamp, Storm Jar | 2.3 / 2.8 studs for new imports |
| Medium | Traffic Cone, Disco Dustbin, Golden Toilet, Moon Rock, Mini UFO | 3.2 / 4.0 studs |
| Heavy | Snack Machine, Dinosaur Skull, Giant Diamond | 4.3 / 5.2 studs |

`sizeClass` is separate from carry behavior. Museum stands use the prepared size; the depot enlarges small items by 1.5x and medium items by 1.2x for readability. The carried visual is scaled down to a camera-safe height of at most 1.8 studs. The prepared models have an invisible root, a weld for every visible MeshPart, and one animated Motor6D group. Templates remain noncolliding; live museum and depot displays add one invisible collidable hull sized to the model. Carried items stay noncolliding. The client animates the moving group while the model is on a museum stand or public stock pedestal. Animation does not control ownership, delivery, or income.

Every model has an authored color palette and Roblox materials. Six generated tileable PBR MaterialVariants add actual texture maps to gold, painted metal, rubber, lunar stone, porcelain, and fossil bone surfaces. Glass and neon elements use Roblox's built-in materials. These are reusable material textures, not mesh-specific UV art. The material names are `StealAnythingAntiqueGold`, `StealAnythingPaintedMetal`, `StealAnythingToyRubber`, `StealAnythingLunarStone`, `StealAnythingRoyalCeramic`, and `StealAnythingFossilBone`; they live under `MaterialService.AssistantMaterials`. All eleven templates use at least one of them.

The generated material asset IDs, in creation order, are:

| Material | Asset IDs |
|---|---|
| AntiqueGold | 83805126554963, 121179415073662, 82567181949556, 106813718345111 |
| PaintedMetal | 81150862096826, 105471848534344, 104904491447226, 107355611653946 |
| ToyRubber | 134302175351079, 112338185886118, 108299745269878, 119757896976648 |
| LunarStone | 121159819396212, 98896440257379, 132987021038653, 97488153329153 |
| RoyalCeramic | 93893375667009, 83739582424466, 81252088461709, 77332036608609 |
| FossilBone | 83377758633559, 120463532213246, 128002639533151, 101721563001499 |

To rebuild the gameplay copies from the untouched imports, run [prepare_item_models.luau](../scripts/prepare_item_models.luau) in Studio Edit, then [validate_item_models.luau](../scripts/validate_item_models.luau). The preparation script replaces only its own marked `ItemModels` folder. The Rojo mappings preserve the Studio-owned mesh geometry and MaterialService variants, but source code alone cannot recreate the imported MeshIds or generated material assets. Save the Studio place after preparing the models, then reopen and confirm they persist. Publishing the live place is a separate step.
