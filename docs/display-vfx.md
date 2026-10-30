# Display and wardrobe effects

`SignatureVfx` creates local animated geometry from replicated recipe markers. `ItemVisuals` attaches markers only to anchored displays; carried items do not receive these effects. `WardrobeUi.Start` starts the world renderer in both places and explicitly updates preview geometry after positioning the avatar. This avoids relying on particle emitters, trails, or lights inside ViewportFrames.

Display recipes: popping toast, duck bubbles, a miniature cone crown, disco floor tiles, toilet jackpot coins, jelly creatures, falling snack packets, levitating lunar fragments, a UFO tractor scene, fossil echoes, contained storm lightning, and diamond caustics/refraction. The pedestal has one through four small rarity jewels. Effects do not affect value, income, ownership, collision, or stand protection.

Premium outfits use digital contours and scanning (Neon Phantom), opening shadow blades (Shadow King), and a royal card fan with coins (Legendary Robber). They take priority over the cash Phantom Glow special. Cash Phantom Glow keeps its existing appearance. Robux purchase availability is unchanged.

World effects update at 30 Hz within 85 studs of the camera; distant geometry is removed and rebuilt on approach. Each recipe uses 3–23 noncolliding parts. Reduced motion freezes the animation. Geometry belongs to its marker and is destroyed when its item or outfit is removed. Preview geometry is destroyed with the old preview avatar.

Validated in Studio: all 15 recipes at 81 time samples plus reduced motion, finite transforms, effects noncolliding/nonqueryable, all 12 item display collision hulls, and actual wardrobe selection of all three premium previews. Both Rojo builds pass. Museum Studio sources were synced; the separate lobby place must use the updated shared source when opened/synced. Live publication and physical-device performance testing were not performed.
