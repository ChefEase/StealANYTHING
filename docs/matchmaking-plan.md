# One-to-six-player gameplay and matchmaking architecture

Status: implemented in Rojo source and staged in the new lobby place, with
published two-place tests still pending. See `docs/task12-matchmaking-setup.md` for exact
Creator Dashboard setup and the live test checklist.

## Intended player flow

1. Keep the existing museum place as the experience's start place. Its public
   servers redirect entrants to a lightweight waiting lobby before loading a
   profile or constructing runtime museums. Reserved servers of that same
   museum place run gameplay. Players see the matchmaking status and a
   count in the separate lobby.
2. A cross-server matchmaker groups waiting players. Fill a game server with a
   free museum plot first. If no game server exists, the first player may
   launch alone. When all existing servers are full, wait until two players
   are available, then reserve a new game server and move the pair together.
   Continue filling that server up to six.
3. If a game server drops to one player, allow solo play after their museum
   loads. Advertise the vacancy
   so another player can join.
   Do not discard or reset the remaining player's saved profile or museum.
4. A friend invite enters through the lobby, with the inviter's user ID in
   trusted Roblox join data. Prefer the inviter's server when it has capacity;
   otherwise queue the friend and explain that the friend's server is full.
5. Each arrival loads their own saved account profile and is assigned any free
   plot in the selected server. Plot ID, clone ID, and server ID are never
   persisted as museum ownership.

The exact seventh/eighth example is: a full six-player game stays at six; the
seventh waits in the lobby; the eighth pairs with the seventh in a new reserved
server. A seventh may instead take a vacancy in another eligible game server.

## Implementation boundaries

- Set the **game place** maximum visitor count to 6 in Creator Dashboard.
  `Players.MaxPlayers` is read-only to scripts. The lobby has its own capacity.
- Use `MemoryStoreService` for temporary queue membership, server availability,
  reservations, and short leases. Use `TeleportService:TeleportAsync` and a
  reserved-server access code for exact placement. Handle expiration, duplicate
  joins, teleport failure, and abandoned reservations without losing players.
- `TeleportService` cannot be tested in Studio Play. Test in a published,
  private experience with real Roblox clients. Load/save must release profile
  leases correctly across teleports.
- The current `PlotService` already treats full plot occupancy as `PlotState =
  "Full"`, but that is only a fallback; it is not a queue or an entrance gate.
- A normal Roblox public server may start with one player. The public museum
  instance redirects them to the lobby, which can launch a reserved solo
  server when no gameplay server exists.
- `SocialService.GameInvitePromptClosed` no longer provides recipient IDs, so
  the standard multi-friend prompt cannot enforce four actual invite sends.
  The chosen limit is four distinct qualifying friends per inviter, tracked
  on the server using `Player:GetJoinData().ReferredByPlayerId` and the
  qualification event. The same friend counts once. The fifth and later
  friends give no additional referral reward. Do not pay for opening an
  invite prompt.

## Acceptance checks

- One player begins alone when no gameplay server exists. Two may play
  together; six occupy unique plots; seventh waits; eighth forms a new pair
  when no vacancy exists.
- If a player leaves a two-player game, the remaining player keeps playing
  with their profile and museum while a replacement is sought.
- Rejoining can put a player with different people, but keeps cash, items,
  display placements, and other saved progress.
- An invited friend reaches the inviter's available server or sees an honest
  waiting message. A full server never gets a seventh writable plot.
- Cross-server queue races, disconnects, teleport failures, duplicate join
  data, and repeated reward claims cannot make extra plots or rewards.
- Referral rewards count four distinct qualified friends at most, including
  when qualification occurs in another server or the inviter is offline.
