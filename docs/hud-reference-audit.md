# HUD reference audit — 14 October 2026

This audit distinguishes a working HUD from a visual design that was checked against an owner-specified game screenshot. The source and test records document **no actual-game visual references** for the HUD modules listed below. Their existing colors and layouts were authored in code. Functional or simulator checks do not establish approval of their visual design.

| HUD | Source | Implemented and checked | Recorded game-image reference |
| --- | --- | --- | --- |
| Cash and active income | `src/client/CashHud.luau` | Yes; income, rejoin, and phone layout checks in `docs/tutorial-loop-testing.md` | None found |
| Objective and load/error state | `src/client/Bootstrap.client.luau` | Yes; tutorial progress, save-error state, and phone layout checks in `docs/tutorial-loop-testing.md` and `docs/save-testing.md` | None found |
| Carry details | `src/client/CarryHud.luau` | Yes; pickup and phone simulator checks in `docs/task7-testing.md` and `docs/tutorial-loop-testing.md` | None found |
| Carry destination | `src/client/CarryDestinationHud.luau` | Implemented; hidden during the first guided toaster run to avoid duplicating the guide | None found |
| Interaction prompt and touch delivery | `src/client/InteractionHud.luau`, `src/client/CarryInputController.luau` | Yes; simulator pickup and hold-delivery checks in `docs/tutorial-loop-testing.md` | None found |
| Tutorial arrow and marker | `src/client/TutorialGuideController.luau` | Yes; tutorial and phone simulator checks in `docs/tutorial-loop-testing.md` | None found |
| Result/error notification | `src/client/NotificationHud.luau` | Implemented; save-error and delivery feedback have been observed, but no visual-reference review is recorded | None found |

The **menu interface** uses the owner's Brawl Stars screenshot as its current visual reference; the **map tab** uses the owner's Sea of Thieves map screenshot. See `docs/menu-ui-references.md`. Other HUD visuals remain unapproved against game-image references until the owner-specified examples are located or reattached. Do not infer a reference from a similar color palette.

The gameplay HUDs and menu now read their shared dark green, mint, off-white, muted text, and outline values from `src/client/HudTheme.luau`. Cash, carry, destination, interaction, guide, objective, notifications, and the menu use that same base palette. Warning and error colors retain their state meaning; the cartographic parchment remains map-specific.
