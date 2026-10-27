# Task 12b lobby wardrobe check

Task 12b's wardrobe unit test is `tests/unit/PostTask12Wardrobe.spec.luau`. Run it in **museum Studio Edit**, after Rojo sync, through the Studio Command Bar or connected Studio execute tool. It needs `ServerScriptService.Server`, so running it in the lobby place will fail. A pass prints `Post-Task-12 wardrobe catalog and purchase rules: PASS`. It uses an in-memory profile and does not buy anything on the owner's account.

## Check the lobby UI in Studio

1. Open the **Steal Anything Lobby** place, ID `105126787891032`, in Studio. Keep the museum place, ID `94309819487664`, distinct.
2. From this project folder, run `.\rojo.exe serve lobby.project.json --port 34873`. Connect the Rojo plugin in the lobby Studio window to port `34873` and review its sync preview. The museum uses `default.project.json` and port `34872` if it is also open.
3. Press **Play** in the lobby Studio window. The character starts in staging with matchmaking paused. Walk to the wardrobe locker/mannequin and press **E** on `Open wardrobe`. When finished, press **PLAY / JOIN HEIST** in the `HEIST CONTROL` card or walk to the deployment vault and press **E** on `Play / Join Heist`. Both start the same queue. In Studio the status confirms the press but does not teleport.
4. Verify the panel lists ten rows, the free Starter Robber can be equipped, the red patterned bandana appears on the avatar, and the look stays after a respawn. If Phantom Glow is owned, equip it and check its quiet aura sound; otherwise its preview is visual only and the lobby should say to buy it at the museum. The lobby must not deduct museum cash.
5. Stop Play. Studio Play shows a matchmaking preview; it does **not** execute a real `TeleportService` trip to the museum.

## Check a real lobby-to-museum transfer

Use a private published test version of **both** places in the same experience. Local Rojo sync or Studio Play alone does not publish those changes. Join through the museum start place in the Roblox client; it redirects to the lobby. The player remains in staging until they press **PLAY / JOIN HEIST** or use the deployment vault prompt. Equip an owned look in the lobby, then use either Play route and allow matchmaking to send the player to a reserved museum server. Verify the same look, including the bandana or Phantom Glow if selected, on the museum character and after respawn. Leave, rejoin, and check that the loadout remains. With another client, confirm the other player sees the same cosmetic. The broader Task 12b exit check also calls for phone/controller navigation, six-player appearance replication, and an uncertain-save purchase case; those are separate from the quick lobby UI check.

The museum **Menu > Wardrobe** tab also lets a player inspect and change owned cosmetics during a match, without returning to the lobby. **LEAVE QUEUE** in the expanded lobby card returns a waiting player to staging; **PLAY / JOIN HEIST** starts the queue again.

`src/matchShared/PlaceConfig.luau` currently sets the museum server cap to **6**. Older two-player rehearsal instructions in `docs/task12-matchmaking-setup.md` are historical and should not be applied to this wardrobe check.
