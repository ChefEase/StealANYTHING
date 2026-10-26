# Task 3 profile testing

## What is implemented

`ProfileRepository` owns one player key (`player:<UserId>`) in the configured store. An `UpdateAsync` call both reads the profile and writes a lease token in key metadata. A second server must wait while that lease is valid. The current holder refreshes it every 60 seconds; it expires after 180 seconds if the holder disappears. Every refresh and release checks the token, so a server that lost ownership cannot write. Unknown results retry with the same token. Version-0 profiles migrate to version 1 inside the acquire operation; unknown or invalid records are left untouched.

`ProfileService` sets a player attribute named `ProfileState`. `Ready` is the only state that exposes a profile snapshot to future gameplay services. On load or configuration errors, the client shows a message and gameplay remains unavailable. Task 4 will add the profile mutation queue and saving of earned changes.

## Local deterministic check

After Rojo sync, run `tests/unit/Task3.spec.luau` in Studio's **Edit** command context or through Studio MCP. The test uses an in-memory store and makes no Roblox DataStore requests. It covers first load, rejoin, overlapping sessions, lease expiry and lost ownership, errors before a read, a lost response after a write, metadata preservation, full and partial version-0 migration, and future-version rejection. Fixture samples are in `tests/fixtures/`.

## Live persistence check

Use a **separate private published test experience**. In its Studio security settings, enable **Studio Access to API Services** only for that test experience. The configured store must remain `StealAnything_Dev_v1` or `StealAnything_Test_v1`; never use the production store for this check.

1. Sync the project to the private test place and run a one-player test. Confirm `ProfileState` becomes `Ready` and the server logs no load error.
2. Stop and rejoin with the same Roblox account. Confirm the same profile is loaded, with starter cash 100 and three contract instance IDs unchanged. Task 3 has no gameplay mutations, so this verifies stored defaults and stable rejoin.
3. While one server holds the same account's lease, attempt a second repository acquire against that key. Confirm `Locked` and no second writable snapshot. The in-memory unit test already covers this race; use a controlled multi-server test before launch.
4. Disable Studio API access temporarily **on the test experience only** or inject a failing store adapter. Confirm the player stays in `ConfigurationError`/`RetryableError`, sees the safe message, and no default profile is saved over the previous one. Restore test access afterward.
5. Verify the normal leave path clears the lease. If a server crashes, wait for the 180-second lease expiry and verify a new server can load while the old token can no longer refresh or release.

Keep the fixture migration check in the in-memory test; never insert synthetic legacy profiles into a real player's key.

## Test record — 11 October 2026

The connected published Studio place had `PlaceId = 94309819487664` and `GameId = 10770294953`. Its synced server configuration selected `development` and `StealAnything_Dev_v1`. The user supplied the published test place and Studio API access; these checks touched only the development store.

| Check | Result |
| --- | --- |
| Join with starter profile | **Pass.** The test player reached `ProfileState = Ready`. The stored profile had cash 100, schema version 1, and three contract instances. Output had both bootstrap messages and no load error. The key was not inspected before this Play session, so this run alone does not prove it was previously absent; the absent-key creation path is covered by the in-memory test. |
| Second acquire during Play | **Pass.** A separate `ProfileRepository` instance using the real development DataStore and the same player key returned `Locked` with no writable snapshot. This was a second repository in the same Studio server; a two-server run remains a prelaunch check. |
| Normal release | **Pass.** Stopping Play cleared `sessionToken` and `sessionExpiresAt` from the key metadata. |
| Rejoin | **Pass.** The same account returned to `Ready` before the old 180-second lease would have expired. Cash remained 100 and all three contract instance IDs matched the first join. A new session token was issued. |
| Failure and stale-lease paths | **Pass in the in-memory `Task3.spec.luau` test** run during implementation. Injected read failure did not replace an existing record or create a missing one. Expired-lease takeover made the old owner lose refresh and release rights. The unpublished-place Play test also showed the safe `ConfigurationError` state. A live DataStore outage and real server crash were not induced. |
| Rojo build | **Pass.** `.\rojo.exe build default.project.json -o build/StealAnything.rbxl`. |

Task 3's join/rejoin exit check is complete. The target Studio disconnected after the second rejoin inspection, so release of that second session was not observed. Before launch, repeat the contention check with two actual servers and test recovery after an unclean server shutdown. Task 4 adds the mutation and save path, so this check does not claim gameplay progress persistence yet.
