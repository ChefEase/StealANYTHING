# Task 14F — visual effects design review

This follow-up covers the live museum, depot and lobby presentation code plus connected Studio scenes. It does not claim a six-player performance pass, physical-phone review or unfamiliar-player response. The [cue inventory](task14f-full-cue-inventory.md) contains the interaction-by-interaction SFX list; this document records the visual design decisions and the tests actually run.

## Reference direction

The [holographic fashion-editor concept](https://trinityvideogame.com/index.php/fashion-editor) uses a clear garment focal point, layered display depth and motion within the changing area. The [Beyond Good & Evil planning-table image](https://store.playstation.com/pl-pl/product/EP0001-PPSA08706_00-BGER000000000000) shows a projected miniature scene on a central table. These are visual references only. The effects below use original procedural parts and Roblox's built-in particles; no reference art was copied. Roblox's [effects documentation](https://create.roblox.com/docs/effects) describes the particle/trail approach used here.

## World-by-world audit

| Area or action | Existing presentation | Change and design judgment | Still needed |
| --- | --- | --- | --- |
| Lobby locker **room** | Lockers and a dark wall sign; mannequin preview off to the side | A layered garment projection floats in front of the locker bank. A moving scan and afterimage travel over the locker doors, with a matching floor projection and rising motifs. Approaching Open Wardrobe briefly intensifies the scan. The frame and floor chevrons are now supporting wayfinding, not the claimed VFX. The room effect is client-local and bounded. | Owner visual review from spawn/phone and a six-player performance check. The procedural garment may still look too blocky for final art quality; improve its authored shape before adding more particles. |
| Lobby planning table | Flat blueprint and static route lines | A miniature projected museum and two moving route pings make the heist planning premise visible. The pings are decorative and never show real people or guard locations. | Check whether the table reads at ordinary walking distance and whether it competes with the Play vault. |
| Lobby deployment vault, queue card | Existing animated-looking vault design, lamp, sign and live queue UI | No extra particles added: the vault is already the strongest focal point and a second large effect would compete with the locker room. Neutral UI press has a short tap sound/scale, while queue status remains authoritative. | Real queue-enter/fail/transfer playtest and phone contrast. |
| Museum tutorial pickup and depot stock | World marker, pickup hold highlight, item-specific model visuals | Existing rarity-colored pickup burst remains keyed to a new server carry. A nearby local restock shimmer now emits only when server stock actually becomes enabled. | Real restock cycle and completed/cancelled pickup on phone. |
| Museum return and receiving area | Tutorial arrow/sign, receiving glow and hold bar | A local DELIVER HERE marker appears within 70 studs only while carrying. On a committed delivery packet, the receiving area emits a short teal/amber motif burst; a rejected packet emits none. This is result feedback, not an always-on beacon. | Real public displayed/stored delivery and failed-save test. The hold percentage is still local input progress; a fully server-timed ring needs a begin/cancel contract. |
| Voluntary G/touch carry drop | Carry model disappeared with a text result | A small local dust-release puff now follows the server's validated drop result and carry ID. Delivery and capture use different paths, so they cannot trigger this cue. | Real G/touch drop test with normal/heavy/tutorial/public carries. A distinct drop SFX needs a suitable supplied clip. |
| Museum exhibits and first income | Twelve item-specific `SignatureVfxRecipes` (toast, bubbles, crown, disco tiles, coins, jellies, snacks, rocks, UFO, fossil, storm, diamond); stand glow and first-dollar HUD pulse | Existing identity is stronger than a blanket emitter on every stand. No new ambient particles added to all exhibits. | Inspect each recipe at device quality and with several displays together. First-dollar payoff needs a fresh account test. |
| Museum doors, travel and extraction | Door swing, travel sparks/rings, extraction countdown/origin marker | Existing motion expresses these actions. Door collision was fixed separately. No cosmetic change to extraction logic or guard cues. | Real cancellation, capture, teleport, and both-sided door passage tests. |
| Warden, cover and chase | Guard model, warning and chase HUD | Task 14B owns cinematic guard VFX/audio; this pass did not add it. | Review after gameplay acceptance. |
| District buildings, routes, trees, landscape, seats, static lobby cases | Art geometry and lighting | No automatic sparkle/glow pass. Environmental atmosphere should be composed around routes and focal scenes rather than attached to every prop. | Art review by area and device performance before any additional ambient effects. |

## HUD control audit

Every current `GuiButton` in `PlayerGui` now receives the neutral press cue and a small tap scale. The button input cue is not a success cue. The modules below were inspected so each action has a deliberate second-stage response where one matters.

| HUD module | Clickable actions | Result treatment and gap |
| --- | --- | --- |
| `OperationsMenu` | Open/close, Tutorial, Wardrobe, Map, Collection, Travel, replay, return to lobby | Tabs already change selected content; shared tap makes input immediate. Tutorial replay and lobby travel need actual state/transfer result checks; no speculative success effect. |
| `CollectionHud` | Auto Equip Best, Manual, stand assignment, store, help/close | Server-committed arrangement already triggers a Collection pulse and equip cue. Failed/locked actions retain text feedback. Live save/restore and displaced-item clarity need testing. |
| `CashHud` | Income detail | First earned dollar has its own pulse and chime; ordinary detail open gets only neutral click. Do not animate every passive dollar. |
| `CarryHud` and `CarryInputController` | Collapse/expand, touch carry/drop/deliver | Buttons receive neutral input cue and scale. Drop lacks a distinct server result hook and supplied clip; a delivery hold has input progress plus server saving state, but no false success effect. |
| `InteractionHud` and `TravelOfferHud` | Prompt action, collapse/expand, ride | Buttons receive neutral input cue. Teleport gets the existing warp rings/sparks on actual completion. Test failed/blocked travel before adding more feedback. |
| `TutorialGuideController` | Guided ride, replay prompt | World objective marker and ride button remain; shared tap is input only. Physical-phone route visibility and first-90-second timing remain unverified. |
| `GuardHud` | Hint dismiss/mute | Shared tap; guard warning/escape VFX and audio stay with Task 14B. |
| `FriendInviteHud` | Invite | Shared tap only. Sending an invite is not a successful referral and must not get reward effects. |
| `NotificationHud`, `CarryDestinationHud`, `MatchWaitingHud`, `RemoteHudController` | Mostly display/state, no primary reward buttons | Existing text and layout changes are the feedback. Adding a sound to every HUD refresh would clutter the mix. |
| Lobby `Lobby.client` and shared `WardrobeUi` | Play, cancel, retry, invite, expand; wardrobe preview, buy/equip/remove/restore | Neutral click starts on press. The wardrobe result banner/flash/highlight waits for the server's unique result ID. Queue success, purchase failure and cross-place return still need live checks. |

## UI and sound timing correction

The owner's first listening test found action sounds too quiet and menu clicks late. Action cues are now 0.36–0.48, music 0.11–0.12, local exhibit accents 0.18–0.24, door 0.38, and Phantom Glow aura 0.10 before saved volume settings. The neutral HUD click is the owner's short `226892749` clip at 0.28. Mouse/touch press starts it before the button action; `Activated` is a keyboard/gamepad fallback. Studio Play checked the click's volume was set while the lobby MORE button still had its pre-release label, then the action completed on release. A button scale provides a small tactile visual on normal effects.

Wardrobe purchase/equip/remove/restore feedback is separate: only a server-confirmed result ID triggers its `LOOK UPDATED` or `UNLOCKED` banner, panel flash, and brief avatar highlight for look changes. A click alone never triggers that success effect.

## Verification performed

- Museum and lobby Rojo builds and `git diff --check` passed after the final source edits.
- Lobby Studio Play loaded the music and new shared modules. The locker scan moved across the doors; the garment projection contained eleven local parts; moving route pings and a nine-part miniature museum existed on the planning table. Screenshots were inspected from the spawn side and a closer planning-table view. Approaching the wardrobe prompt increased scan opacity and light brightness. A local low-effects override hid the scan, garment, particles and planning-table projection. Explicit startup wait timeouts removed the lobby's infinite-yield warnings in a fresh Play run. The unrelated `203785492` asset-type warning remains.
- Museum Studio Play used a synthetic committed delivery packet to exercise one result burst, then an Error packet produced no burst. A local carry-attribute override produced the receiving marker near the owner's zone. These test presentation branches only; they do not prove a real delivery. The later voluntary-drop cue was source-built but not live-tested because the museum Studio instance closed.
- Studio Play tested a muted/low-effects menu click: the menu still opened, its click stayed silent and no button scale appeared. A real saved settings change was not tested.

## Files changed in this follow-up

- Audio/UI: `src/shared/HeistAudioConfig.luau`, `ExhibitSoundConfig.luau`, `UiFeedback.luau`, `WardrobeAppearance.luau`, `WardrobeUi.luau`; `src/client/Bootstrap.client.luau`, `HeistAudioController.luau`.
- Lobby world/VFX: `src/lobby/LobbyWorld.luau`; `src/lobbyClient/Lobby.client.luau`, `LobbySeating.client.luau`; new `src/shared/WardrobeRoomVfx.luau`, `LobbyPlanningVfx.luau`.
- Server-confirmed wardrobe/drop results and museum VFX: `src/matchShared/WardrobeSession.luau`, `src/server/Services/WardrobeService.luau`, `CarryService.luau`; `src/client/DeliveryFeedbackController.luau`, `PickupFeedbackController.luau`; new `src/client/CarryDropVfx.luau`.
- Documentation: `development_plan.md`, `docs/task14f-full-cue-inventory.md`, this review and `docs/task14f-polish.md`.

## Honest quality assessment

The initial neon frame was not adequate VFX. The later locker effect has recognizable clothing imagery, layered motion and an interaction response, but the procedural jacket is still simple. I cannot rate it an accepted final look without the owner seeing it in motion on a phone. The planning table is a stronger scene-design addition in its close Studio view, while its impact from ordinary walking distance remains unmeasured. More particles would not solve weak composition or weak model detail. The highest-value next art step is refining the garment projection and locker scene shape, then testing visibility and frame rate with actual players.
