# Task 4 save and operation testing

## Implementation contract

- `ProfileRepository.NewOperationId` issues an ID tied to the current writable session. Gameplay services must use this server-issued ID for valuable actions. A client request ID is only a session-scoped retry key; never pass it as the durable operation ID.
- `ApplyOperation` serializes each player's writes. Its mutation callback runs once **before** `UpdateAsync`; it must be pure server logic and return `Committed` or `Rejected` plus a short result code. The profile change and terminal operation record are written together. Gameplay may announce a valuable result only after the method returns a confirmed operation.
- A failed or lost write response keeps the original candidate and ID pending. The service exposes `ProfileState = SaveError`, pauses new valuable mutations, and retries reconciliation with backoff. `GetSnapshot` is unavailable while the result is uncertain. Do not issue a new ID for the same action.
- `StageRoutine` accepts only cash, fractional income, beginner active seconds, or raid-cycle changes. The staged profile is validated and autosaved every 60 seconds after a per-player initial offset. `Release` refuses to discard dirty or pending data; leave and shutdown try up to three saves before releasing the lease.
- The profile ledger retains at most 128 operation results. Entries may be pruned only after 600 seconds. If all 128 are still inside that retry horizon, new valuable actions return `HistoryFull` until an entry ages out. The current session also remembers confirmed IDs; old-session IDs absent from the ledger are rejected. This avoids replaying a pruned purchase or claim.

## Studio check

1. Sync Rojo to the **Steal Anything** test place and run `tests/unit/Task4.spec.luau` in Studio **Edit** command context, or through the Studio MCP. This uses only an in-memory store and should print `Task 4 serialized writes and reconciliation: PASS`.
2. Confirm one duplicate ID returns its first terminal result and does not run the mutation again. Confirm concurrent IDs serialize and both survive. The test also injects failure before read and a lost response after commit, checks reconciliation, confirms routine autosave, and checks that release refuses dirty or uncertain state.
3. In the private published test place with `StealAnything_Dev_v1`, confirm an ordinary join still reaches `Ready` and stop/rejoin retains the starter profile. Do not test changes by editing a real player's saved cash through the Studio command bar.
4. Confirm the client displays `SaveError` when that attribute is set. Task 5 and later gameplay services must call this API with server-generated IDs. No gameplay mutation service exists yet, so the in-memory adapter is the authoritative failure test for Task 4.

## Results

- 11 October 2026: `.\rojo.exe build default.project.json -o build/StealAnything.rbxl` passed.
- 11 October 2026: The synced Steal Anything Studio place contained the Task 4 repository and service code. `tests/unit/Task4.spec.luau` printed `Task 4 serialized writes and reconciliation: PASS`. The Task 3 suite also passed again.
- 11 October 2026: Play mode reached `Ready` against `StealAnything_Dev_v1`, with cash 100, revision 0, and the same three contract IDs as Task 3. Stopping Play cleared the lease metadata; rejoin reached `Ready` with the same data. The second Play session was stopped afterward.
- 11 October 2026: Temporarily setting the Play test player's `ProfileState` to `SaveError` made the client status label visible with the delayed-save message. The attribute was restored to `Ready` before stopping Play. No saved player value was changed for this UI check.

Task 4's exit check is complete. A real value-changing gameplay save/rejoin check belongs to the first gameplay mutation task; no such service exists yet.
