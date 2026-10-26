# Menu UI reference record — 14 October 2026

The Task 11b handoff says the owner supplied a Sea of Thieves map screenshot. It does not record an online image search before the current menu UI was implemented. The existing parchment palette, grid, compass, and landmark treatment were derived from that supplied screenshot, with original Luau UI drawing.

An online image search on 14 October 2026 found these visual comparison references:

- [Sea of Thieves map table screenshot at Eurogamer](https://www.eurogamer.es/sea-of-thieves-mapa-islas-posicion-forma-nombres)
- [Sea of Thieves map interface screenshot at Everyeye](https://www.everyeye.it/articoli/guida-sea-of-thieves-come-muovere-primi-passi-nel-nuovo-gioco-rare-37837.html)
- [Brawl Stars home screen screenshot at SkyCoach](https://skycoach.gg/brawl-stars-boost/accounts?preset_id=123)

That search happened after the original map implementation. It verifies the map reference direction; it is not evidence that the original menu was built from online UI images.

## Outer menu interface

The owner supplied `Screenshot 2026-10-14 023030.png`, showing the Brawl Stars main menu, as the specified visual reference for the **menu interface**. It shows strong dark outlines, compact side navigation, bold labels, top status, and a large primary action. The screenshot's yellow action color is not used as this game's menu accent. The game's established dark green, mint, and off-white HUD colors are the source for color.

`OperationsMenu.luau` now places a live player preview in the middle, a compact icon-button column to the left, player and cash status at the top, and a mode card beside a large PLAY action along the bottom. Those placements follow the supplied Brawl Stars screenshot. The yellow PLAY color is translated into this game's shared mint HUD accent. The map tab uses a larger parchment canvas with pan, zoom, sparse coordinate lines, and separate focus controls for the player, original district, and new plaza. The map depicts the actual connected world; no Brawl Stars or Sea of Thieves image asset is embedded.

An earlier exploratory pass looked at Sea of Thieves menus, Two Point Museum, and Pet Simulator 99 and introduced a gold menu accent. That was the wrong reference choice and the owner rejected the resulting color. Those screenshots are not the approved reference for the current menu. No third-party UI image or texture was embedded in the game.
