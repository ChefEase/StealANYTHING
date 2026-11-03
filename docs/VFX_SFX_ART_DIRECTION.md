# Museum Heist VFX and SFX art direction

This is the standing quality standard for new visual and audio cues in the lobby, public depot, and player museums. The game is fast-paced, stylized, comedic, and slightly futuristic. Effects should make the steal, escape, deliver, earn loop readable and satisfying. A strong silhouette and precise timing matter more than raw brightness.

## Visual language

- Use clean geometric shapes, brief energetic motion, mechanical responses, controlled cyan/teal for museum technology, gold/amber for rewards, and red/orange for danger or rejection. Reserve purple and larger effects for exceptional rarity.
- Avoid generic glowing spheres, excessive neon, uncontrolled particles, randomly rotating Parts, giant shockwaves, and effects that cover an item, player, prompt, route, or guard warning.
- A persistent focal object must read at about 12, 30, and 60 studs before extra particles are added. Keep all twelve displays readable together, not merely attractive one at a time.
- Use ParticleEmitters for bounded bursts, Beams for directional energy, Trails for moving sources, and TweenService for deliberate mechanical motion. Use authored meshes or textures when Parts cannot form the needed silhouette. Do not make procedural primitives the only visual tool.

## Reference-driven production gate

1. Inspect the supplied stills or clips before implementation. Record the silhouette, main shapes, timing, motion, layering, and color hierarchy to borrow conceptually. Never copy proprietary textures, meshes, or exact effects.
2. Describe how those qualities can be built in Roblox and which custom asset is needed, if any.
3. Build a playable prototype in the isolated `vfx-preview.project.json` place. Include idle, success, failure, cancellation, near/medium/gameplay camera views, low effects, and reduced motion as relevant.
4. Ask for visual review. Refine specific feedback in motion. Only then integrate with the live, server-confirmed result. A working script or one screenshot is not visual acceptance.
5. Profile expected multiplayer load, phone readability, sound stacking, repeated actions, and cleanup. Success, failure, and cancellation must resolve separately.

The ten images inspected in `C:\Users\User\Downloads\VFX References` provide conceptual examples of circular platforms (`MiAV5BW1*.jpg`, `images.jpg`), rarity pickup streaks (`R5jBEs.jpg`), directional beams (`images (3).jpg`, `maxresdefault.jpg`), angular technology (`images (2).jpg`), and a bright impact (`images (5).jpg`). The red weapon effect in `images (4).jpg` is too dense for routine heists. None shows a garment silhouette. The images are review references, not imported game assets.

## Current Step 6 review

- **Locker room:** The live floating garment now has a deeper coat chest/waist, sloped shoulders, cylindrical sleeve volume, lapels, collar and hem instead of a single flat body sheet. It retains the existing scan/trail and rising motifs; no new persistent particles were added. Review it at 12/30/60 studs and in the live lobby. An authored garment mesh may still be needed if the sculpted Part silhouette remains blocky; source geometry alone is not visual acceptance.
- **Vault deployment:** Keep the existing planning-table and vault presentation. The live client now uses short, local, nonpersistent teal/amber/orange segment pulses on confirmed queue/deployment/failure status transitions. It does not fire a success pulse from the Play button. Review the actual queue result and cancellation cases in published multiplayer matchmaking; Studio preview cannot accept a live queue.
- **Exhibits:** The isolated preview `Gallery` station runs all twelve `SignatureVfxRecipes` at once on neutral proxies; `Exhibit` shows each separately. This is a composition test, not a recreation of the actual museum, item meshes, stand spacing, occlusion, or audio mix. Review all twelve in the real museum together at gameplay distance before changing intensity. The existing `ExhibitAudio` spatial/one-at-a-time throttle helps avoid twelve simultaneous clips, but must be heard in Studio. Reduce any distracting constant motion or light only after that review.
- **Core effects:** The receiving and extraction geometry modules are now shared by preview and live client controllers at the owner's explicit request. Delivery success follows the committed server feedback cue; extraction completion follows the server outcome. Pickup uses confirmed carry attributes. All three still need real-device visual review and multiplayer profiling before visual acceptance.

## Audio standard and cue backlog

Preserve the current lobby, museum, and carry music contexts and ducking. Use only owned or appropriately licensed sounds; an asset ID must be permission-checked and heard in Studio before shipping. Prioritize audible gameplay results; keep UI clicks subtle. Use spatial audio for local machines and world actions. Keep reward sounds distinct from routine controls. Fade and stop loops when their gameplay state ends. Respect `masterVolume`, `musicVolume`, and `effectsVolume`; let warning cues remain clear over music.

| Cue still needing a suitable asset or live confirmation | Trigger and character |
| --- | --- |
| Item drop | Server-confirmed voluntary carry drop; soft physical clunk, once per carry. |
| Queue accepted | Server-confirmed queue entry; brief electronic acknowledgement. |
| Queue failed | Server-confirmed rejection; gentle two-tone rejection, no reward cue. |
| Deployment | Server-assigned destination; rising mechanical pulse. |
| Extraction charging | Active server-owned extraction timer; user-inventory force-field clip `129267525484488` loaded in Studio Edit at 4.68 s and is wired as a rising positional hum. Human listening and published-place permission check remain open. |
| Extraction cancelled | Server cancellation/interruption; short power-down, stop hum, never completion cue. |
| Restock | Nearby stock-ready transition; brief mechanical chime with local throttling. |
| Stored delivery | Confirmed stored result; current provisional clip needs a suitable secure-storage latch and listening review. |

No new sound IDs are assigned by this document. Do not create a second music controller or alter established gameplay rules for a cue.

## Acceptance

An effect is accepted only after it communicates the intended event, follows the approved direction in motion, preserves important gameplay visibility, looks clear on desktop and phone, performs at expected six-player load, responds correctly to success/failure/cancellation, and reliably stops or cleans all temporary geometry, particles, tweens, beams, and sounds. The corresponding Studio and device observations must be recorded; source inspection and Rojo builds alone do not satisfy visual or audio acceptance.
