# Steal Anything!

Roblox MVP source project. Start with [the development plan](development%20plan.md); [the game design](Steal_Anything_MVP_Game_Design.md) defines gameplay, ownership, and persistence rules.

## Responsibility split

- Local files and Rojo own `ReplicatedStorage/Shared`, `ServerScriptService/Server`, `ServerStorage/Assets`, and `StarterPlayer/StarterPlayerScripts/Client`.
- The in-Studio assistant owns the scene, `Workspace/Map`, geometry, and other Studio-authored assets until those assets are exported and deliberately added to the Rojo project.
- Do not edit a Rojo-owned script in Studio and expect it to remain there; the next sync can replace it. Do not sync a whole service over Studio-authored content. The project file preserves unknown instances in the mapped services.
- Never place profile data, server config, purchase IDs, or security logic in `ReplicatedStorage`.

## Local setup

1. Install Rojo **7.7.1** CLI and its matching Studio plugin. `rokit.toml` pins the CLI version for a reproducible setup; Rokit is optional if you install the same version another way. The CLI and plugin are separate installations. Follow the [official Rojo installation guide](https://rojo.space/docs/v7/getting-started/installation/).
2. Open this folder in PowerShell and run `New-Item -ItemType Directory -Force build` followed by `.\rojo.exe build default.project.json -o build/StealAnything.rbxl` to validate the mapping. If Rojo is on PATH, `rojo` also works in place of `.\rojo.exe`.
3. Open the existing **Place1** in Roblox Studio. Run `.\rojo.exe serve default.project.json` from this folder, then connect the Rojo plugin to the local server. Review the sync preview before accepting it; the project should add only the four code-owned folders above.

If cloud saving is unavailable and you open a local `.rbxl` backup, Studio reports `PlaceId = 0`. `default.project.json` permits Rojo sync to that local place and to the published Place1 ID; it does not set a fake place or game ID. Keep the local file saved separately, reconnect Rojo after restarting `rojo serve`, and review the sync preview. A local place has no published game identity, so use the original published place for DataStore tests. Once Roblox uploads work again, use **File > Publish As** and select the existing Steal Anything place deliberately; a Rojo connection does not publish the place.
4. Press **Play** in Studio. The Output window should show one `[Steal Anything] Server bootstrap ready` line and one `[Steal Anything] Client bootstrap ready` line for a single-player test.
5. Stop Play and confirm `ServerScriptService/Server/Bootstrap`, `StarterPlayer/StarterPlayerScripts/Client/Bootstrap`, `ReplicatedStorage/Shared`, and `ServerStorage/Assets` exist. `Bootstrap` scripts are the only scripts expected at Task 1.

Rojo currently does **not** map `Workspace/Map`, because the scene is being built in Studio and no exported `MainMap.rbxm` exists yet. Once the map is exported and checked into `assets/places`, deliberately add that mapping and verify it cannot erase the in-Studio scene. Do not substitute an empty map file merely to satisfy the layout diagram.

## Task 1 acceptance

- Rojo build and live sync complete without errors.
- The two bootstrap messages appear once each in a single-player test.
- No server-only script is in `ReplicatedStorage`.
- The baseplate and any Studio-authored instances remain intact after sync.

Record the result under Task 1 in `development plan.md` before starting Task 2.

## Task 2 definition check

After Rojo sync, run `tests/unit/Task2.spec.luau` in Studio's **Edit** command context (or through the connected Studio MCP). It requires the synced modules, checks catalog/config consistency and profile validation, and prints `Task 2 definitions and profile schema: PASS`. It creates no saved player data. Keep this test outside the normal game tree; `tests/` is not mapped by `default.project.json`.

## Task 3 profile loading

See [the profile test guide](docs/profile-testing.md). `tests/unit/Task3.spec.luau` runs against an in-memory store in Studio Edit mode. A real rejoin check needs a separate private published test experience because the current Place1 is unpublished.

