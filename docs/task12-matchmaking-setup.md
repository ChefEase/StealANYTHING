# Task 12: one-to-six-player gameplay and matchmaking setup

The earlier heading “26 player” meant **2–6**, not 26. The updated solo rule
lets the first player start alone and lets any remaining player keep playing.
The current private test temporarily caps museum servers at **two** players.
The six museum plots remain in place. After the four-account test, restore the
six-player cap in `src/matchShared/PlaceConfig.luau` and Creator Dashboard.
The lobby place exists at `105126787891032` in the same experience as the
museum. The owner published the lobby place on 15 October. The current museum
redirect fix and lobby room refresh are still unpublished.

## Place layout

- `default.project.json` remains the museum gameplay place. Its place ID is
  `94309819487664`, and its maximum visitor count must be **2 for this test**. It stays the
  experience's start place. Public entrants are immediately sent to the
  lobby before profile loading or runtime museum construction. Reserved
  servers at this same place ID run the museum game.
- `lobby.project.json` is the second, lightweight place in the **same Roblox
  experience**. Its `HeistLobby` model contains a planning table, decorative
  vault gate, armory and collector displays, crew lounge, lockers, and spawn
  pad. It never imports `Workspace.Map`,
  the Task 11 visual kit, or gameplay code. The model can be rebuilt from
  `src/lobby/LobbyWorld.luau` if needed.
- `src/matchShared` is mapped once into each project under
  `ServerScriptService.MatchShared`. This shares configuration and atomic
  matchmaking rules without duplicating the museum systems.
- The lobby never loads a player profile. The gameplay place loads the
  existing account profile only after a server-issued reservation is verified.

## Manual Creator Dashboard and Studio steps

1. In Creator Dashboard, open the **Steal Anything!** experience, then
   **Configure → Places**. Confirm the museum gameplay place is
   `94309819487664` and set its **Access → Maximum Visitor Count** to **2**
   for this test. Restore **6** after the test.
   The connected Studio Edit session still reported `Players.MaxPlayers = 60`
   on 15 October; reopen Studio or check the published place after changing
   Dashboard settings. The source cannot change this property.
2. The lobby Baseplate was added as place `105126787891032` and its ID is set
   in `src/matchShared/PlaceConfig.luau` and `lobby.project.json`. **Leave the
   existing museum place as the start place.** Roblox's current workflow
   cannot directly switch the start place to a new place without overwriting
   the current start place; this project avoids overwriting the museum place.
   A friend join can create a new public instance of this start place. That
   brief ingress server must redirect the player into the lobby; the two-player
   matchmaking limit applies to reserved gameplay servers, not to how Roblox
   allocates public instances of the start place.
3. Open the museum place in Studio and connect Rojo using
   `rojo serve default.project.json --port 34872`. Open the new lobby place
   in a separate Studio window and connect it using
   `rojo serve lobby.project.json --port 34873`. The current open lobby Edit
   session already contains matching scripts and the `HeistLobby` model, but
   connect Rojo for subsequent source edits. Check that each window shows
   the correct source tree. Save each place in Studio. **Publish each place
   only after review and explicit approval.**
4. For a private live check, publish a test version of both places under the
   same experience after approval, then join through the existing museum
   start place in the Roblox client. Its public server redirects entrants to
   the lobby. `TeleportService` does not run in Studio Play.

### Third-player report, 15 October

The owner reported that a third invite led to another server instead of a
visible lobby. This is **not a passed live test**. The tested source rule
still reserves a new server only when a fourth player joins a queued third
player, provided the active two-player server is registered. The museum place
opened in Studio with no misplaced FBX imports and with the redirect source,
but Studio reported `Players.MaxPlayers = 60`; confirm the Dashboard value
is really 2 on the published gameplay place. A friend join to the museum
start place can briefly land in a new public instance before redirect. The
museum client had a startup race that could show a broken-looking public
redirect server; the source now waits for a replicated ingress decision and
retries asynchronous lobby teleport failures. These fixes need a reviewed
museum publish and four real clients before the behavior can be confirmed.

## Runtime behavior

- The lobby displays waiting count, status, Cancel, Retry, and Invite.
  When no game server exists, one player can start a reserved museum server.
  Studio Play shows a preview status without calling live matchmaking.
- The compact `HEIST CONTROL` panel follows the owner's dark/cyan reference.
  `MORE` reveals the queue controls. Its count and status come from the
  server; it does not display a fictitious two-player minimum, progress
  percentage, or wait-time estimate.
- The lobby currently has no purchase prompts, cash transactions, or item
  grants. If added later, a lobby shop will use Robux products only; earned
  cash purchases belong in the museum game. Robux offers may also appear in
  gameplay. A single account profile must own any purchased entitlements
  across both places.
- The registry uses one `MemoryStoreHashMap` entry whose `UpdateAsync`
  transform claims queue entries, server slots, and tickets atomically.
  Each queue entry, reservation, assignment, and server heartbeat expires.
  The temporary registry contains no cash, inventory, or saved museum data.
- Each eligible existing server with free capacity is preferred. A valid
  `ReferredByPlayerId` gives priority to an eligible inviter's server.
  The lobby starts a teleport as soon as the registry confirms an open-slot
  claim; it does not wait for the next registry read. Registry read, claim,
  and museum heartbeat failures are logged in server Output.
  If no server is eligible and an active server is full, two queued players
  receive tickets for one new reserved game server. A full two-player server
  cannot assign a third museum; the third waits and the fourth can start
  a new pair. When the registry has no game servers at all, the first player
  launches alone.
- `TeleportAsync` retries synchronous failures up to three attempts with
  bounded backoff. `TeleportInitFailed` and a 165-second no-departure timeout
  return the player to matchmaking. An unopened reserved server is removed
  when its last failed assignment is cancelled, so a solo player can be
  assigned again immediately. After three failed teleport cycles, matchmaking
  pauses for that player and the lobby shows **Press Retry**; server Output
  records the Roblox failure reason. The museum accepts a repeated arrival
  with the same ticket into the same server, and a solo player's new instance
  can reclaim their old server lease. Museum admission failures show a reason
  on the phone lobby and pause matchmaking until Retry is pressed. A ticket
  is tied to a user ID, server
  key, and expiration, and is checked against the registry on arrival.
- The gameplay server admits only players with a live server-issued ticket.
  It waits for profile readiness and an owned plot before counting someone
  toward play readiness. A lone player with a loaded profile and owned plot
  can play and earn passive income normally. Their server advertises its
  vacancy so another player can join. Profile saving and lease release on
  departure continue through the existing services.
- Plot ID, clone ID, server key, and teleport ticket are transient. The
  existing account profile remains the source of cash, exhibits, displays,
  and progress across different matches.
- Referral rewards remain disabled. `ReferralRules` defines a maximum of
  four distinct qualified friends, but no invite send is counted as a
  qualification and no reward is currently granted.

## Published-game test checklist (pending)

**16 October owner observation:** Two players reached the lobby and then the
museum game in under five seconds. The owner confirmed that they shared one
museum server and each received a separate plot. Saved progress after rejoin
was not checked. The third and fourth player sequence is planned for a later
test; the broader checks below remain open.

- [x] Owner-reported live check: two players reached the museum game through
      the lobby, shared one server, and received separate plots.
- [ ] One client joins an otherwise empty experience and starts playing
      alone after their museum loads, with passive income working. A second
      client joins that server and receives a distinct plot.
- [ ] Keep clients 1 and 2 playing, then join client 3. Verify client 3 waits
      in the lobby. Join client 4 and verify clients 3 and 4 share a second
      reserved server with distinct museums; neither joins clients 1 and 2.
- [ ] Leave and rejoin in a different arrival order. Verify pairings change
      with order and that cash, displays, inventory, and progress follow each
      account. Matching currently takes the oldest waiting pair; it does not
      deliberately shuffle players, so repeat the test with varied order.
- [ ] Remove one player from a full server and verify the next newcomer fills
      that free slot instead of creating another server.
- [ ] Remove one player from a two-player server. Verify the remaining player
      keeps playing and earning income with their museum still owned; a
      replacement should fill the vacant slot.
- [ ] Interrupt a teleport, disconnect one initial-pair member, and retry.
      Verify the surviving server is advertised and can accept a replacement.
- [ ] Join the game place directly without a ticket; verify redirection to
      the lobby and no profile load or owned museum before admission.
- [ ] Invite a friend into a server with a free slot, then into a full server.
      Verify friend priority and truthful waiting behavior. Do not infer
      actual invite sends from the prompt-close event.
- [ ] Rejoin in a different server and confirm saved cash, display slots,
      exhibits, tutorial progress, and lease release/reacquisition.
- [ ] Test two real clients' museum access, cross-owner security, pickup,
      delivery, and departure cleanup. Check mobile and controller lobby UI.
- [ ] In the lobby, use E on each lounge chair and G to stand. Verify a
      seated player cannot be displaced by another E press. Check the on-screen
      Roblox Stand prompt on touch devices and controller B. While seated,
      verify neither couch spot shows a Sit prompt to that player.
- [ ] Test MemoryStore throttling, registry expiration, duplicate joins,
      cross-platform matchmaking, and high queue traffic in a private build.

The registry currently uses one atomic global key. Its memory and request
quota must be load-tested before wider launch; it is intended for the current
small-player test stage. A registry failure keeps players in the lobby rather
than assigning an unverified museum.

## Revert after the two-player test

Change `MaximumPlayers` back to `6` and `RegistryName` back to
`StealAnythingMatchmakingV1` in `src/matchShared/PlaceConfig.luau`. Set the
gameplay place's Maximum Visitor Count back to **6** in Creator Dashboard.
Rebuild both Rojo projects, sync both places in Studio, and publish them only
after review and approval. The test registry name isolates two-player tickets
from older six-player leases; it contains no persistent player progress.
