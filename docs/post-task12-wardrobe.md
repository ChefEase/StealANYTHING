# Post-Task-12 follow-up B implementation — updated 23 October 2026

## Built

- Seven available wardrobe entries: one free Starter Robber look with bandana; cash ski mask, classic, street, and tactical outfits, getaway bag, and phantom glow. Three additional **preview-only** Robux candidates appear below them: Neon Phantom, Shadow King, and Legendary Robber. The old separate `starter_mask` ID stays valid for saved loadouts, but no longer occupies a second shop row. All items are cosmetic. Robux prompts and marketplace IDs remain disabled for Tasks 37–38.
- Shared Roblox-avatar overlay renderer for R15 and R6 body names. It attaches named, noncolliding visual parts to the player's current avatar and removes the whole set when unequipped. Original body, face, hair, clothing, and accessories remain intact. Server application replicates to other players and reapplies after respawn.
- Lobby lockers gained a wardrobe mannequin, mirror, sign, and prompt. The same inventory, try-on viewport, equip, remove, and restore controls run in both places. In the museum the wardrobe is a Menu tab between Tutorial and Map, using the menu colors and a clipped scrolling pane. The separate museum corner button is hidden. The lobby points players to the museum for cash purchases; it never spends museum cash or opens a writable museum profile.
- The 23 October visual pass gave each outfit a distinct shape: the starter has a hood and pouch, Classic has a striped pullover and knit cap, Street has an oversized bomber and crossbody pouch, and Tactical has armor plates, pouches, and knee guards. The Robux previews add a neon hood and coat tails, a crown and cape, or a gold long coat with particle accents. The bag is now a hand-carried cylindrical duffel with a handle; its preview focuses on the hand and bag. Phantom Glow has brighter light, a faint halo, neon seams and arm bands, and particles. Hair is temporarily hidden under the ski mask and restored when it is removed.
- After owner feedback that the fits still looked blocky, arm and leg clothing was changed from box overlays to rounded cylindrical layers, and the ski mask was rebuilt with a rounded Roblox head mesh shape, fabric seams, and a covered base head. The Classic cap is hidden while the ski mask is worn so it does not poke through. The free bandana also has a softer rounded shape. These remain code-authored visuals in `src/shared/WardrobeAppearance.luau`.
- A separate experience-wide wardrobe record stores equipped slots and a mirror of paid ownership. The museum's existing serialized profile operation commits each cash deduction and permanent unlock first. The lobby can read the committed museum profile to repair a missed mirror write, without leasing or writing that profile. A local unpublished `.rbxl` preview uses an in-memory wardrobe record that resets after Play.
- Museum doors play the 1.4-second wooden creak asset `rbxassetid://9120839174` when a player uses the Open prompt. Server random door changes do not trigger this sound.

## Checks actually run

- Rojo builds of both `default.project.json` and `lobby.project.json` passed. `tests/unit/PostTask12Wardrobe.spec.luau` passed in Studio Edit: catalog count and slot ownership, invalid/insufficient purchases, one $400 deduction, duplicate rejection, and valid profile schema.
- In the published museum's Studio Play, free outfit and mask equipped and replicated to the server, survived a respawn, and disappeared on Restore Roblox Avatar. The door sound asset loaded and played when the prompt was triggered. An unowned tactical outfit was refused. A $15,000 request with insufficient cash did not spend; a $400 ski mask purchase spent exactly once, and a repeat spent nothing. The mask and selected outfit returned after Stop/Play with the saved cash balance.
- In the published lobby's Studio Play, the locker prompt opened the wardrobe; the owned ski mask and equipped outfit loaded from the shared record. Unequip/equip left the Studio matchmaking status unchanged. The equipped mask then appeared after returning to the museum Studio Play.
- A compact 1182 × 349 Studio screenshot exposed an overlapping preview and action area; the panel layout was corrected. On 23 October the museum menu wardrobe was inspected again in Studio Play at that size, including its clipped outer scroll, cash outfits, carried duffel, glow, and premium previews. The handle and bag were visible beside the avatar's right hand. The first glow halo looked like a solid oval, so it was reduced before the final screenshot. Studio inspection confirmed hair hides under the ski mask, a cloned preview does not change the live avatar's hair, and clearing a cloned mask restores its hair visibility. The shorter viewport requires scrolling to reach lower controls and the bottom of the preview. The lobby wardrobe opened and listed all ten rows after the shared-script update. Both Rojo place builds passed again; the wardrobe purchase test passed in a fresh Studio Play server. The server rejected a premium item as a cash purchase without changing the test balance.
- The owner reports on 23 October that they successfully bought and equipped outfits in their own test. The item(s), device, and exact purchase log were not specified. A later Studio Play screenshot showed the rounded mask on an equipped Classic outfit; a cloned mask-clear check restored head transparency without changing the live avatar.

## Robux candidate status

Neon Phantom, Shadow King, and Legendary Robber are visible try-on previews in both places. Their earlier 99/199/399 Robux figures are **drafts**, not published prices. The purchase button says the Robux look is coming soon; server cash purchase rules reject all three. They cannot be owned or equipped until Tasks 37–38 approve the exact offers, the owner creates/supplies the marketplace IDs, and durable entitlement/receipt tests pass. This avoids showing a working purchase prompt that cannot safely grant the item.

## Cash price basis

The current prices in `src/shared/WardrobeCatalog.luau` are **provisional**, not final measured launch prices. The documented early economy in `src/shared/ItemCatalog.luau` has shop items at $180/$220/$280/$340 and base income of $12/$14/$16/$18 per minute; the protected toaster earns $6 per minute. The development plan's 14 October model also assumes a typical three-minute NPC delivery, $35 average contract cash per delivery, and spending on shop items, museum upgrades, and abilities. The wardrobe prices were selected against those modeled goals, but the normal public depot and final tier prices are still future tasks, so actual median earned cash per active minute has not been measured.

| Wardrobe item | Current cash price | Status |
| --- | ---: | --- |
| Starter Robber with bandana | Free | Permanent free option |
| Black Ski Mask | $400 | Model target: about 10–15 active minutes |
| Getaway Bag | $750 | Model price; no measured time yet |
| Classic Burglar | $1,400 | Model target: about 30–45 active minutes |
| Phantom Glow | $2,200 | Model price; no measured time yet |
| Street Robber | $5,200 | Model target: about 1.5–2.5 hours |
| Tactical Heist | $15,000 | Model target: about 5–8 hours |

Recalculate against observed fast, median, and slow earnings after Tasks 13–16 and final Task 19 upgrade prices. Show the confirmed prices in the wardrobe before launch.

## Remaining exit checks

- The displayed cash prices are **provisional**. Task 12B's median earned-cash curve and fast/typical/slow purchase timing cannot be verified until the first collectible models and normal depot earnings exist. Reprice and confirm before launch.
- Physical phone and controller navigation, wardrobe loadout persistence through a real lobby-to-reserved-museum teleport, six simultaneous cosmetic appearances, and failed DataStore/write reconciliation still need targeted acceptance. The owner confirms underlying lobby teleportation, six-player appearance replication, and queue behavior already work from Task 12; those baseline results remain accepted. Studio previews verify the two places and shared data separately; Studio matchmaking deliberately shows a preview status instead of teleporting.
- The wardrobe source changes are applied to both open Studio Edit places and built as local `.rbxl` artifacts. Save/publish each place deliberately after review; no public version was published by this work.

## Art files

No Blender file is needed for the current playable wardrobe. The mask, clothing layers, bag, glow, and preview attachments are authored in `src/shared/WardrobeAppearance.luau`; the mannequin and mirror are authored in `src/lobby/LobbyWorld.luau`. A higher-fidelity mesh pass would most improve the ski mask, duffel, tactical coat, and mannequin. There is currently no `.blend` or `.fbx` source for those pieces. Studio mesh generation returned “Model generation should only be called from the server,” and a free Creator Store ski-mask mesh could not be inserted because Studio's asset-insert handler was unavailable; neither attempt changed the place. The rounded code-authored mask is the current source. The existing imported lobby locker pack is `assets/lobby/LobbyAssets.rbxm`.
