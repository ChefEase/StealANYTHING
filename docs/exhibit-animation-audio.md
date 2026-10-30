# Exhibit motion and subtle audio

All 12 items were checked against their imported mesh groups. Animations affect display models only; carry behavior, income, collision hulls, and storage are unchanged. Golden Toilet keeps its existing coin VFX and has no model movement.

| Item | Display animation | Suggested sound |
|---|---|---|
| Dramatic Toaster | Lever presses down, releases with the existing toast-pop VFX | Soft spring pop and small mechanical click, under 0.65 seconds |
| Springy Rubber Duck | Short spring-bounce bursts with a settling wobble | One soft rubber squeak, under 0.45 seconds |
| Royal Traffic Cone | Stationary; crown VFX remains | None |
| Disco Dustbin | Lid bobs rhythmically; floor-tile VFX remains | None, to avoid competing with music |
| Golden Toilet | Stationary, including its lid; coin VFX remains | None |
| Jelly Lamp | Tentacles gently sway beneath the fixed lamp | None |
| Rattling Snack Machine | Cabinet rocks in short bursts, snacks shake inside, feet/plinth remain fixed | Muted metal/plastic rattle with wrappers, about 1 second |
| Suspicious Moon Rock | Embedded crystals occasionally tremble; rock remains still | None |
| Spring-Mounted Mini UFO | Saucer bobs, tilts and slowly turns above its base | Optional soft airy sci-fi hum swell, under 1.5 seconds |
| Tiny Dinosaur’s Giant Skull | Stationary; fossil-echo VFX remains. Imported moving group contains the upper jaw, not a separate hinged lower jaw | None |
| Storm in a Jar | Internal clouds/lightning assembly slowly swirls; jar remains still | Soft distant thunder/static crackle, under 1.2 seconds |
| Absurdly Large Diamond | Slow gem rotation without lifting out of its setting | Optional delicate glass shimmer, under 1.5 seconds |
| Museum doors | Existing door swing | Short wooden hinge creak with a light latch click, about 0.7 seconds; no slam |

## Where to add the sounds

1. Stop Play in Studio. In Explorer, open **ReplicatedStorage → Shared → ExhibitSoundConfig** (ModuleScript). The source file is `src/shared/ExhibitSoundConfig.luau`.
2. In the matching `Items` entry, replace `SoundId = ""` with `SoundId = "rbxassetid://YOUR_AUDIO_ID"`. Use audio your experience has permission to play. For the doors, fill the separate `Door.SoundId` entry at the bottom. Leave unwanted sounds empty.
3. Restart Play. Stand near that exhibit for a full cycle and then walk away. The code creates the spatial Sound instances automatically; do not add sounds to temporary models in Workspace. If using Rojo, make the same edits in the source file so syncing retains them.

The volumes are intentionally low (0.04–0.10 for exhibits, 0.12 for doors). Exhibit accents and doors stop at 28 studs, with full volume within 8 studs to allow for the third-person camera. There are no exhibit audio loops. A client-wide gap of at least 1.5 seconds (longer for longer accents) limits overlapping exhibit accents. Nearby loaded exhibits can trigger an initial accent after 0.35 seconds; subsequent accents follow their normal cycles. Clip lengths are capped by `MaxDuration`; short clips with their own gentle fade-outs work best. Optional UFO and diamond sounds can remain blank.

Toaster pop plays every 5 seconds, duck squeak every other bounce cycle (11.6 seconds), snack rattle every 7 seconds, UFO swell every 12 seconds, storm every third lightning cycle (11.4 seconds), diamond shimmer every 18 seconds. Nearby competing events may be skipped. Reduced motion freezes models but does not mute audio.

Phantom Glow retains its existing sound, reduced from volume 0.16 to 0.025 and range 32 to 12 studs, with a tapered distance falloff. Its settings are in `src/shared/WardrobeAppearance.luau`, under `PhantomAuraSound`. Preview avatars do not start an additional aura sound.

## Validation

Studio playback sampled all twelve live rigs over more than eight seconds: cabinet movement and lever travel confirmed, snack feet fixed, toilet/cone/skull transforms unchanged. All motion curves were checked at 221 time samples. Shadow King’s brighter, wider preview blades were checked through the actual wardrobe UI. User-supplied audio IDs are now preserved in ExhibitSoundConfig. All six exhibit clips and the door clip loaded in Studio. A live nearby UFO test began playback in 0.39 seconds and produced nonzero PlaybackLoudness. Final listening/balancing against background music is still needed. Both place builds and whitespace checks pass.
