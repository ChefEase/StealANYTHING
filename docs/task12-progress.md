# Task 12 progress — 14 October 2026

This file records the 14–16 October implementation and test history. On 21 October 2026 the owner confirmed real-player Task 12 multiplayer, delivery, and matchmaking checks passed and accepted Task 12 as complete. The owner also confirmed the saved-place reopen/Rojo reconnect persistence check was completed. The exact player count and individual adverse-case results were not supplied with that confirmation; earlier pending notes below are historical snapshots.

## Source and runtime changes

- `ProfileDefaults`, `ProfileMigration`, `ProfileSchema`, and `Types` now use schema 3. Schema 2 added the tier-one museum record; schema 3 adds the saved `travelTipsEnabled` preference. Migration removes only legacy `exposed_03` placement or recovery preference, keeping the registered item and other accepted profile fields. Plot and clone IDs remain transient.
- `PlotService` keeps the playable original `Workspace.Map` and adds the six-plot district to its east at runtime. A walkable gate and route connect the two districts; a shuttle offers an optional faster link. It reserves a free slot after a successful profile load, clones the starter museum and selected landscape, gives its sockets clone-local IDs, reconstructs displayed items, and cleans the clone on leave or profile error. A player without a free plot has no owned museum, pickup, delivery zone, or income accrual; the HUD reports that it is waiting for a space. A freed slot is offered to a waiting player.
- Carry validation, delivery display refresh, income settlement, and the guide use the assigned runtime clone. Tutorial pickup uses the shared depot in the six-plot district. The menu map reads both districts and offers zoom, pan, and landmark focus. Delivery still derives the zone and owner from server state; the request does not accept a client plot ID. Starter museum spawning moves the avatar 20 studs toward the center aisle from the authored socket to avoid a rear-wall camera obstruction.
- Non-toaster legacy displays use a labeled temporary artifact placeholder until their final models are added at later visual and catalog tasks.

## Checks actually run

- `rojo.exe build default.project.json -o build/Task12SourceCheck.rbxl`: passed.
- Studio Play on the connected place: an existing profile loaded and migrated, received `plot_01` with a unique clone ID and owner, and reconstructed one protected toaster. A second Play session rejoined with a new clone ID and one toaster display. Console contained only bootstrap messages.
- A Studio screenshot after the spawn adjustment showed a clear interior and entrance view. The old spawn placed the follow camera at the rear wall and showed black behind the HUD.
- Studio server-side tests: Task 2, Task 3, Task 4, TutorialLoop, and new Task12Migration passed. The migration suite covers v1 empty, toaster displayed, available `exposed_03` in storage, Missing `exposed_03` recovery preference, schema-2 reminder migration, corrupt item, and future version. Task 2 and Task 3 assertions were updated for schema 3; Task 2 also reflects the Task 11b replay request.
- In the additive-world Studio pass, the original museum and the expansion were both present. A no-jump path from the original museum to the new plaza succeeded at about 548 studs. The new museum spawn to its depot path succeeded at about 406 studs. The gate prompt was visible and transported the player to the new depot; the pickup target was 5.5 studs from that depot's pedestal. Imported benches, sculptures, planters, trees, rocks, and crates now receive collision where their solid body is reachable. The client and server console showed only bootstrap lines.
- The depot and district shuttle prompts now use custom style, so the game-drawn interaction HUD is the only prompt. The collision audit added rock arches, boulders, bollards, poles, estate walls/piers, utility cabinets, and distant tree trunks. Remaining visible noncolliding large pieces were soft foliage, distant backdrops, or pieces already enclosed by a solid model hull.
- The original and cloned museum entrance markers now have neither physical collision nor ray-query collision. A no-jump path from the connector into the original museum and a no-jump straight path into the new museum both succeeded. The old museum's visible central podium requires a small bend left; its entrance marker does not physically block entry.
- `PlotProtection` creates a 120 × 120-stud visitor boundary for each assigned tier-one garden. It activates while the owner is on the grounds, lets the owner through via collision groups, and ejects any visitor already inside. Studio checked the owner group/barrier pair, visitor default group/barrier pair, active barrier at home, and inactive barrier after the owner left. Two-account live enforcement remains to be tested.
- A travel card appears on leaving the museum, offers free testing access to the depot ride, explains the future speed coil, and lets players turn future reminders off. A new schema-3 profile migrated from schema 2 correctly. A fresh test profile saved `travelTipsEnabled=false` through the actual client remote and rejoined with it still false; leaving home then produced no card. A temporary Studio-only test store and smoke LocalScript were removed afterward, and `EnvironmentConfig` was restored to the normal development store.
- Follow-up correction: the new district's solid `EstateEdge` crossed the original map's east opening even though `InvWall_East` had been opened. `PlotService` now splits only that east edge around the connector. The other edge sections and three original boundaries remain. A collision ray through the opening hit nothing, and no-jump pathfinding from the connector to the original museum succeeded.
- Follow-up grass correction: the expansion's `EastWestGroundExtension` lay flush against the original ground over its entire footprint. It is now split into two strips outside the original 180-stud north/south ground span, removing the overlapping surface that caused flicker.
- Follow-up protection rule: visitor barriers surround the garden only while the owner is physically inside the museum building. They turn off while the owner is in the garden or away. In Studio, the same barrier was active at the museum center and inactive when the owner stood 45 studs from center in the garden.
- Follow-up offer rule: a travel offer requires completed tutorial income (`TutorialStep >= 2`) and at least two confirmed NPC deliveries. On its first eligible display the reminder is saved as off; the player can explicitly turn future reminders on. In Studio, a new test profile at tutorial step 0/zero deliveries showed no offer on exit; changing only its public attributes to step 2/two deliveries and exiting again showed one offer and saved reminders off. A normal two-delivery gameplay run remains for the Task 12 integrated loop.
- Abilities are scheduled at Tasks 20 and 27. On 14 October their provisional prices were re-derived from target playtimes and expected other spending: first movement ability $1,000, second $2,200, second/third NPC slots $6,500/$17,000, scanner $3,200 plus $100 per scan. See the 14 October section of `development plan.md`. Testing rides remain free.

## Remaining exit checks

- The user reports setting the gameplay place's Maximum Visitor Count to six in Creator Dashboard. The connected Studio Edit session still reports `Players.MaxPlayers = 60`; reload and verify the published setting before live tests. The property is read-only in scripts.
- Run six real clients in one server and verify six distinct visible museums, no overlap, routes, owner-specific guides, and cleanup as players leave. Through the new lobby, verify that the seventh waits and the eighth forms a second server when no existing vacancy exists.
- Rerun pickup and delivery against the clones with two accounts: cross-player museum rejection, duplicate callback, impossible position, stale clone ID, and Q10/Q29. Rejoin after a fresh delivery and confirm one toaster and continuing income.
- Force load failure and uncertain write in the integrated Play flow; verify no writable museum appears and rejoin reconciles the same operation.
- Save, close, and reopen a local `.rbxl`, reconnect Rojo, and verify imported template meshes and pivots as required by the Task 11b handoff. Physical phone/controller evidence and full-server performance are still open.

The connected Studio instance used for these checks is the published place `94309819487664`. Studio source for changed scripts was explicitly refreshed from the workspace because this Rojo connection retained earlier bodies for existing scripts. The repository remains the source of truth; the place setting and any Studio-owned template changes still require normal Studio save/publish handling.

## 14 October owner requests

- `MuseumDoors.luau` adds double entrance doors to `Museum01` and each cloned museum, sized from the `RaidEntrance` marker, wall plane, and lintel. The server picks both open, one open, or both closed every 30–90 seconds and never closes a leaf on someone in the doorway. When both are closed, a default-style ProximityPrompt opens them; `InteractionHud` skips prompts with the `DefaultPromptStyle` attribute.
- The museum-district shuttle stop sat at Y 0.86 under the 1.19-stud depot platform top. Both stops now sit on their measured surface with a neon pad, glow disk, light, and `SHUTTLE to …` billboard.
- `PlotProtection` adds a roof security light and status sign to each owned museum, plus a 10-second departure grace during which the visitor barrier stays up.
- The menu's `PlayerPreview` character now plays emotes continuously while the Tutorial tab is visible, pausing two seconds between them. The ten IDs in `src/client/MenuEmoteConfig.luau` are Roblox's default R15 gestures and dances; replace them there to change the set. The server builds broad, overlapping grass beds with irregular multi-lobed shrubs, slate rocks, and trees under `ExpansionDistrict/GrassFill`. Raised props are solid; flat beds are walkable. The grass fill uses a much wider grid and is assembled off-world to reduce both Play startup and Stop teardown cost. Plot-specific planting has a separate folder so future grounds upgrades can remove it. Main routes, depot, and starter museum grounds stay clear. `ProfileService` now coalesces `PlayerRemoving` and `BindToClose` release calls for the same player and reports release duration in Studio Output.
- Checks run: `rojo.exe build default.project.json -o build/DoorsEmotesCheck.rbxl` passed. **Not yet run:** Studio Play for door swing direction and fit at both museums, the default prompt appearing without the custom HUD, the pad and sign at the depot, and security-light states.

**15 October travel and emote follow-up:** The travel offer now leaves a small `DEPOT RIDE` tab when collapsed, so players can reopen it. The HUD ride, district shuttle stops, and museum dispatch prompts use a shared warp effect with Roblox's Magic Sound, sparks, and expanding neon rings at departure and arrival. Rojo synced the changed scripts into the published place's Studio Edit session, and `TravelEffectsFinal.rbxl` built. In Play, clicking `KEEP WALKING` showed the reopen tab and clicking it reopened the card. A successful ride reached the depot. The warp effect created its sound, spark emitter, and two rings; the sound asset loaded in Studio. All ten default R15 animation assets preloaded successfully, and the menu preview played the wave animation. The automatic 120-second emote cycle and visual quality of the warp effect still need a longer Play review.

**15 October return shuttle:** `PlotService` creates a second pad in the free center aisle of the six-museum depot. Its prompt returns each player to their own assigned museum using the shared warp sound and effects. The pad checks assignment and carry state on the server. Rojo build passes; Studio Play verification remains pending because Stop has repeatedly stalled in the Studio engine's Workspace teardown.

## 15 October: matchmaking source

**Implemented in source:** A separate `lobby.project.json` maps a small lobby
server and client UI, while `default.project.json` keeps the museum world.
Both map `src/matchShared`. The lobby registers waiting players in a
MemoryStore registry, prefers free existing servers and an eligible inviter's
server, then pairs two players for a new reserved server when necessary.
Claims and tickets are made in atomic `UpdateAsync` transforms with expiration.
Teleport attempts use bounded retries and handle delayed initialization
failure. The gameplay server verifies tickets before profile loading, counts
ready profiles with ready plots, initially pauses interactive gameplay below
two ready players, and resumes when a second player arrives. The subsequent
solo-play correction below changes that minimum to one. The four-qualified-friend rule is
defined but rewards are not enabled. Existing profile store names, Task 11
assets, and the museum map were not changed.

**Checks run:** Both Rojo projects built. `Task12MatchState.spec.luau` passed
in Studio Edit with mocked matching/teleport operations, covering one waiting
player, pair creation, six slots, seventh/eighth behavior, vacancy reuse,
friend preference, stale tickets, bad arrival tickets, denied admission,
one-player readiness conditions, retry bounds, and duplicate/fifth referral
claims. Studio Edit required the new gameplay `MatchService` and a temporary
copy of `LobbyService` successfully; the temporary copy was removed.

**15 October solo-play correction (source only):** A lone player can start the
first museum server when none exists and can keep playing if everyone else
leaves. The seventh still waits for the eighth when all existing servers are
full. Passive income continues for a loaded solo player. The lobby and
gameplay HUD no longer tell a solo player they must wait for someone else.
Both Rojo projects built after the correction, and the Studio Edit
`Task12MatchState` test passed with a first-player solo claim, solo admission,
filling its vacant slot, and a rejected seventh-player solo claim. Published
behavior remains untested.

**Pending:** `LobbyPlaceId` is configured for the new lobby place. The
existing museum place stays the start place and routes public entrants to
the lobby; its reserved instances run gameplay. The gameplay place must be
confirmed at maximum six. The connected Studio Edit session
still reported `Players.MaxPlayers = 60` after the user's Dashboard change;
its setting may be stale until Studio reloads. No published teleport, queue,
six-client, cross-server save, mobile/controller, or reward test has run.
See `docs/task12-matchmaking-setup.md` for the exact setup and live checks.

**15 October lobby build:** The user created a Baseplate place
`105126787891032` in the same experience. `LobbyPlaceId` and the lobby Rojo
place filter now use that ID. `LobbyWorld.luau` builds a compact heist staging
room; the open lobby Studio Edit place contains the matching `HeistLobby`
model, shared modules, remotes, lobby server scripts, and client UI. The lobby
UI leaves the room visible and shows crew count, status, Leave Queue, Retry,
and Invite Crew. Studio Play showed the room and the preview status; a clipped
header was corrected and visually rechecked. The Roblox `CorePackages`
FoundationProvider warning also appeared during this Play test. No gameplay
profile, museum, item, or purchase system was added to the lobby. The lobby
Edit session still needs saving and Rojo connection for future edits. Neither
place was published or live-tested.

**15 October lobby UI adjustment:** The matchmaking panel now starts as a
compact 400 × 108-pixel maximum card showing status and queue count. `MORE`
opens the Leave Queue, Retry, and Invite Crew controls; `LESS` collapses them.
The lobby Rojo build passed. Studio Play screenshots confirmed both states
and the expand button responded to a click. The open Studio place contains
the revised LocalScript; saving and published-client checks remain pending.

**15 October lobby containment:** The front wall now reaches the roof, and
the staging room has a solid roof. Each exhibition case has solid front,
back, and side glass, with a top and plinth. The open lobby Edit place was
rebuilt from `LobbyWorld.luau`. Studio Edit raycasts hit collidable front
wall, roof, and glass on the front, rear, and side of a case. The lobby Rojo
build passed and Studio Play loaded the revised room. An actual player jump
path check and a saved/published-place check remain pending.

**15 October hideout reference follow-up:** The owner supplied a `HEIST
CONTROL` UI screenshot and requested a fuller hideout. The open lobby place
now has a decorative deployment vault, armory and collector displays, a crew
lounge, lockers, and signs for future stations. The stations remain visual:
no shop, loadout, collectible grant, or profile load was added. The compact
queue card follows the dark/cyan/green reference and expands to show queue
controls. It shows the real count/status and does not claim a two-person
minimum, queue percentage, or estimated wait. Studio Play displayed both UI
states, and the `MORE` button responded. No-jump paths from spawn to the
table, armory, vault display, lounge, and lockers succeeded in Studio Edit;
raycasts still hit solid perimeter, roof, and exhibition glass. The lobby
Rojo build passed. Published two-place teleport, phone/controller UI, and
actual jump traversal remain pending. Tasks 31–33 and 37–38 now hold the
art, deployment, locker, and purchase work; post-launch updates hold vault
and lounge expansions.

**15 October two-player rehearsal (source):** `PlaceConfig.MaximumPlayers` is
temporarily 2 and `MatchState` now reads that shared value instead of its own
hardcoded 6. A separate temporary MemoryStore registry avoids mixing old
six-slot leases into this test. All six plots remain untouched, and the
first-player solo rule stays enabled. When two players occupy a server, the
third should wait and the fourth should create the next pair. Pairing follows
queue arrival order and available slots; there is no permanent pair binding
or random shuffle. The lobby sofa has two `Seat` objects with server-validated
E prompts. G, controller B, and a touch button request standing, with the
server checking the player is in a lounge seat. Both Rojo projects built.
The published four-account sequence and actual seating interaction have not
yet been tested. The gameplay place's Creator Dashboard maximum must be set
to 2 for the live rehearsal and restored to 6 afterward.

**Lobby seating and compact UI correction:** The open lobby Studio Edit place
still had the old UI and no lounge seats or stand remote, explaining the
reported failure. The new scripts, remote, and two visible seat cushions were
applied to that place. The E prompt is above each cushion; the server checks
range and occupancy. Seat touch is off so walking into the couch does not sit
the player automatically. Standing clears the seat weld and moves the player
in front of the couch. The matchmaking card is 236 × 96 pixels when collapsed,
236 × 142 when expanded, and sits at the upper right inside the GUI inset;
the stand button sits above the bottom movement controls. Studio Play confirmed
E seated the test avatar and G stood it in front of the couch. The smaller
panel appeared in the upper right. The lobby Rojo build passed. Mobile touch,
controller B, a second seated player, save/reopen, and published behavior remain
untested; the open Edit place must be saved to retain the manual sync.

**Lobby prompt correction:** The custom Stand screen and `LobbyStand` remote
were removed. Each cushion now has Roblox default Sit (E) and Stand (G)
ProximityPrompts. The client shows Sit only while unseated and shows Stand only
for its own occupied seat; the server still verifies the seat occupant before
standing. In Studio Play, each cushion accepted E, both Sit prompts were hidden
while seated, only the occupied cushion's Stand prompt was enabled, and G stood
the character in front of the couch. `ProximityPromptService.PromptShown`
reported the Stand prompt. The lobby Rojo build passed. A two-player and touch
device check remain open, as does saving/publishing the Studio Edit place.

**Lobby Blender asset integration:** The six FBX imports are now in the open
lobby place's `ServerStorage/LobbyAssets`, with one visible table, vault, two
cases, three lockers, and couch under `Workspace.HeistLobby`. The same six
templates are saved in `assets/lobby/LobbyAssets.rbxm` and mapped by
`lobby.project.json`, so the lobby Rojo build includes them. `LobbyAssetPlacement`
fits each model using its imported bounds and pivot, gives the mesh parts a
hideout material palette, disables their collision, and hides the corresponding
procedural visuals while retaining the original solid parts. Both `LoungeSeat`
instances and their E/G prompts remain; seats were aligned to the imported
cushions. Studio Edit checks found six templates, eight visible placements,
zero loose imported models, zero collidable imported mesh parts, and no
missing imports. No-jump pathfinding succeeded from spawn to the table,
vault approach, both display cases, lockers, and the lounge approach.
The new appearance was inspected in Studio Edit. The lobby Rojo build passed.
Studio Play loaded all eight imports and both seats on the server and client;
the client logged a temporary `WaitForChild("LoungeSeat1")` warning while the
room replicated, then the seat appeared. Existing unrelated CorePackages UI
and asset-type warnings also appeared. **Pending:** save/reopen the lobby
place, exercise E/G seating and jump paths with a player, and verify the
imported mesh IDs render in the published place. The museum place was not
changed.

**15 October third-player and lobby feedback:** The owner reported that a
third invite entered another server instead of visibly waiting in the lobby;
this published flow is **not verified or fixed live**. The museum place opened
in Studio with no stray FBX imports, but `Players.MaxPlayers` still read 60,
while the temporary source limit is 2. A friend join may briefly enter a new
public instance of the museum start place before its redirect to the lobby.
The client now waits for a server-set ingress flag in `ReplicatedStorage` before
starting museum HUD, and the server handles asynchronous lobby teleport
failures with bounded retries. An initial Studio Play exposed that a flag on
`game` did not reach the client, so that test failed; the source was changed
to `ReplicatedStorage`, but the museum Studio session became unresponsive
before a repeat Play check. Both Rojo builds pass; the revised published
four-player invite route remains untested. The owner clarified that the
complaint about size, open grass, and color was about the six-museum **outdoor
district**, not the lobby. The attempted lobby room resizing, bay dividers,
colored floor zones, and lighting change were reverted in source and in the
open lobby Studio Edit place. The prior layout and interactions remain; this
revert has not been published.

**16 October six-museum outdoor pass:** The six plot centers, museum buildings,
routes, and future 280-stud tier envelopes remain unchanged. `DistrictGrassFill`
now makes more and broader walkable grass patches, more tree groups, and low
solid stone planters with restrained amber and teal accents. A separate
`DistrictOutdoorDetail` service marks each vacant plot with a walkable stone
yard, low solid corner planters, and two small signal lamps. `PlotService`
hides this temporary scenery before an owned museum appears and restores it
when the museum is removed. No plot state is saved. The source Rojo build
passed; a Studio Edit preview contained all six vacant yards, and hide/show
restored the count from six to five to six without duplication. A no-jump path
from the depot to the first plot succeeded. Published appearance, client
performance, and actual two-player plot assignment/removal remain untested.

**16 October urban district revision (supersedes the grass-fill appearance):**
The owner clarified that visual exposure was the primary problem, so the
runtime six-plot world now uses `DistrictUrbanVisuals` instead of generating
`DistrictGrassFill`. The clone keeps its six plot centers, 280 x 280 future
reservations, museum templates, depot, routes, and perimeter collision. The
runtime layer removes the cosmetic hills and distant tree line, changes the
large grass base to muted concrete, and adds city-boundary facades, four inner
blocks, four service bays, six numbered route checkpoints, and removable
plot-edge paving. Vacant plots have a closed annex silhouette, removed before
their museum spawns and restored on release. Visuals have separate collision
proxies and stable module pivots for future Blender replacements. The old
district/lobby places were not changed by this visual revision.

`rojo.exe build default.project.json` passed. The repeatable Studio Edit
`scripts/validate_district_urban.luau` passed: 46 urban collision modules
outside all six upgrade reservations, six open routes and 18 covered-route
segments walkable with a four-stud no-jump agent, a staged museum entrance
reachable, and the vacant annex returning exactly once after removal. The
temporary validation preview was removed. Studio Play loaded one real profile
into `plot_01`, spawned its museum, removed only its vacant annex, retained
the other five, and created the urban layer with no grass fill or ridge model.
Play stopped successfully. Output showed the pre-existing asset-type and
CorePackages FoundationProvider warnings; no new district script error was
observed. Travel distances and plot coordinates were deliberately unchanged.
After Play stopped, the connected Studio instance stopped responding to a
final repeat of the validator; that repeat did not return a result. The
earlier successful validator and Play checks remain the recorded evidence.
Two-player robbery paths, published appearance, physical phone/controller
performance, and six-museum load remain untested. No place was published.

**16 October owner-reported two-player live check:** Two players entered the
lobby and were transported into the museum game after less than five seconds.
The owner subsequently confirmed that both players shared one museum server
and each received a separate plot. This confirms the published two-player
admission and plot assignment in that session. Progress after rejoining was
not checked. The third-player wait, fourth-player pair, alternate arrival orders, and
full-server behavior remain untested. Keep the temporary two-player cap until
the four-account rehearsal is complete; this report does not close Task 12.
