# Roblox AI reference integration — 26 October 2026

## References used

- `roblox-ai/style-refs/input-prompts/sheet-input-prompts-all-2.png` guided the readable, outlined key shape in the interaction prompt. This sheet is from a Kenney CC0 pack, as recorded in `roblox-ai/style-refs/input-prompts/README.md`. The game draws its own Roblox UI elements; it does not embed the sheet.
- `roblox-ai/style-refs/simulator/mockup-hud.png` and `mockup-reward.png` guided the idea of showing money changes near the balance. The existing dark green and mint HUD palette stays in use.

## Implementation

- `src/client/InteractionHud.luau`: The compact prompt starts hidden, appears only when the player collapses an active interaction, and can now be clicked or selected to reopen the full prompt. It clears when the interaction ends. The compact text describes the open-details action so a touch player is not led to expect that tapping it will complete a pickup. The key has a rounded rectangular outline, and gamepad labels show `X` instead of the internal enum name `ButtonX`.
- `src/client/CashHud.luau`: A confirmed increase in the replicated cash attribute temporarily changes the `CASH` caption to `+$N EARNED` for 1.8 seconds. Initial balance loading does not show a gain. A newer gain replaces an older one, and spending restores the normal caption. The server still owns cash and income calculations.

## Verification

- `rojo.exe build default.project.json -o build/StealAnything.rbxl` passed on 26 October 2026.
- `git diff --check` passed. No Studio device playtest was available in this workspace session. In Studio, check pickup hold/collapse/reopen on desktop and phone, controller `X` display, and the first `$1` income tick after displaying the tutorial toaster.
- A later audit of the open museum Studio Edit place found the interaction prompt and cash caption code present. These are the only two Roblox AI reference changes documented here; the requested earlier four-item list has not been recovered from this workspace. Both effects appear only during an interaction or a confirmed cash increase, so the idle museum view looks nearly unchanged. No other two changes are claimed as implemented.

These changes affect the current tutorial and general interaction HUD. A collectible catalog and a large reward overlay were not added because the current playable slice has only the tutorial toaster and already shows delivery feedback; those reference ideas fit later collection content.
