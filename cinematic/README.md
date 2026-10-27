# STEAL ANYTHING — 24-second cinematic

The open Studio place (place ID `136319055936622`) has an isolated
`Workspace.StealAnythingCinematic` backlot and playback scripts in
`StarterPlayer.StarterPlayerScripts`. The source is in this folder. A standalone
filming place is built at `cinematic/StealAnythingCinematic.rbxl` with
`rojo build cinematic.project.json -o cinematic/StealAnythingCinematic.rbxl`.
The live gameplay place and its profile/progression code were not changed.

The revised run and first doorway pass are in the open Studio place and local
source. The first opening has 6.84 studs of clear width for the roughly
4.74-stud frame; the thief runs continuously through it. The chase uses the
authored **Run - V2** R6 motion from the free Creator Store pack
[(R6) Movement Animations: Run, Walk, Etc.](https://create.roblox.com/store/asset/12177921457).
Its sampled poses are stored in `CinematicRunClip.luau`, so playback does not
depend on an animation upload or the source model's scripts. The officer uses
the leg and arm motion; the thief uses the leg motion while keeping both hands
on the painting. The officer stays farther back in the hallway.
The officer's 2–4 second entrance uses the same pack's **Walk - V2** poses,
sampled in `CinematicWalkClip.luau`, with a short blend into his reaction and
run.
The street and home are 24 studs farther down the chase route. Between the
museum exit and home, both actors run at roughly 9-10 studs per second and the
R6 sprint loops at 2.3 cycles per second. The cut still lasts 24 seconds.
The live Studio changes are in the current Edit session. Studio's scripting
interface cannot invoke Save Place from Edit mode; press **Ctrl+S** in Studio
before closing it. The standalone `.rbxl` above is already built on disk.

## Controls

In Studio, press **Play**. The on-screen `PLAY`, `STOP`, `RESTART`, `9:16 GUIDE`,
and `NEXT SHOT` controls appear. Starting playback with `PLAY`, `RESTART`, or
`NEXT SHOT` automatically hides the controls and crop guide. The final title
fades to black with the last alarm chirp. The black end frame stays on screen
until `X` stops playback and restores the controls.

- `P` or `RESTART`: play from 0 seconds.
- `X` or `STOP`: stop and restore camera, lighting, avatar visibility, prop and
  character poses, barrier, sounds, and title.
- `N` or `NEXT SHOT`: play from the next camera cut.
- `1` through `9`: play from that shot's start.
- Starting within an active loop also starts that cue at the matching position,
  so shot previews have their intended sound.
- `H`: manually hide or show the control bar.
- `9:16 GUIDE`: toggle the centered crop outline. Turn it off for recording.
- Exact frozen preview through the Client Command Bar:
  `game.Players.LocalPlayer.PlayerGui.StealAnythingCinematicControls.PreviewAtSecond:Fire(7.45)`.
  Press `PLAY` or `STOP` afterward.

All editable audio IDs, volumes, duration, stage origin, and crop-guide default
are in `StarterPlayer.StarterPlayerScripts.CinematicConfig` (source:
`cinematic/CinematicConfig.luau`). Paste uploaded Roblox IDs as
`rbxassetid://123456789` into each `Sounds.<name>.id`. Empty IDs stay silent.
The runtime creates named `SoundService.CinematicAudio` instances for those slots.
Music, alarm, footsteps, and huffs loop during their assigned story intervals.
The huff cue uses a quieter overlapping copy of the same selected clip to fill
the pauses at its loop boundary.
Each cue's `time` and `stopTime` are positions in the 24-second film. An optional
`startOffset` selects a position inside a longer uploaded audio file. The wood
clip plays briefly as the frame lifts free of the wall, then stops at 1.15.
It starts 0.62 seconds into the uploaded file, while the music briefly ducks
to let it through. The doorway scrape and impact slots are silent now that
the frame clears the widened opening. The opening track
slows from 1.06 to 1.18 seconds, then stops, and resumes as chase music at 4.16.
The chase music continues at its original volume through the title and fades
over the last 0.25 seconds.
The title fades to black from 23.20 to 23.75 as the final chirp plays.
The script editor
may hold a newer text buffer than the `Source` property; update the open script
in Studio before testing changes.

## Audio cues

The Studio-assigned sound IDs are mirrored in `CinematicConfig.luau`.
`SideScrape` remains silent because the widened doorway clears the frame.
`MusicStop` is optional because the opening track already has a brief pitch
drop before its cut.

| Time (s) | Config slot | Suggested audio |
| ---: | --- | --- |
| 0.00 | OpeningMusic | Heist intro; pitch drops from 1.06, cuts at 1.18 |
| 0.55 | FrameScrape | Wood lift from wall mount; starts 0.62 into clip, stops at 1.15 |
| 1.15 | SwitchClick | Hidden alarm switch click |
| 1.18 | MusicStop | Assigned accent after the pitch drop |
| 2.03 | Alarm | Alarm loop, stops at 7.00 |
| 2.08 | OfficerFootsteps | Owner's approach before entering the gallery; reuses the existing footsteps clip, stops at 3.80 |
| 3.10 | NervousBreath | Thief gasp/breath |
| 4.05 | OwnerGrunt | Angry grunt |
| 4.16 | ChaseMusic | Same track as intro, continues through title; fades from 23.75 to 24.00 |
| 4.30 | ShoeSqueak | Frantic first step |
| 4.72 | MissedGrab | Owner's failed grab |
| 5.00 | Footsteps | Running footsteps loop, stops at 13.10 |
| 5.18 | DodgeWhoosh | Thief's evasive cut around the sculpture |
| 5.42 | OfficerBrake | Owner brakes and pivots |
| 7.46 | Bonk | Reserved for a visible wooden impact; currently silent |
| 7.56 | Oof | Thief impact reaction |
| 8.35 | SideScrape | Silent while the widened doorway clears the frame |
| 8.35 | Huffs | Original huff clip, repeated continuously from the first doorway through the end of the home doorway at 16.90 |
| 13.10 | FastFootsteps | Faster steps loop, stops at 16.50 |
| 16.25 | BarrierSlam | Original protection barrier effect, raised in volume; ends at 17.05 before the owner hits it |
| 17.10 | BarrierRattle | Owner hits the protection barrier |
| 17.30 | Knock1 | Knock 1 |
| 17.52 | Knock2 | Knock 2 |
| 17.74 | Knock3 | Knock 3 |
| 18.68 | FrameShuffle | Thief shifts the painting behind himself |
| 19.22 | ComicAccent | Small accent as the thief thinks it is hidden |
| 20.76 | FinalKnock | One last knock |
| 21.02 | MusicFinish | Title finish |
| 23.20 | AlarmChirp | Short final alarm chirp; title fades to black |

## Recording

Record at 1080 × 1920 if possible. Otherwise record the Studio viewport and crop
to the centered 9:16 outline. Keep the subject inside the guide. Start the
external screen recorder, click `PLAY`, then trim the opening click from the
video. The controls and guide hide automatically. Stop the external recording
after the final title appears, then press `X` to restore the controls. Press
`N` during playback to switch shots while the controls are hidden.
The title has no subtitle or narration; its text is the requested game title,
COMING SOON and tagline. The opening keeps the Mona Lisa on its wall mount until
the thief pulls it outward; the ending joke is his failed attempt to hide the
oversized, alarm-lit frame behind his body.

The narrow museum opening is 2.88 studs wide: the frame strikes it broadside,
then turns edge-on before crossing. The collision recoil ends quickly, and the
officer lunges toward the thief as both continue through the doorway. The street
runway is 16 studs longer than the previous cut. Both actors keep running through
the middle stretch; the painting turns slightly toward the side camera so its
art stays readable. The thief's home entrance is 6.4 studs wide, so the full
frame clears it without an extra collision. The officer remains
outside the visible protection barrier. The museum front wall closes the filming
set behind the chase, and the night grade keeps cool blue shadows with warm light
on the stolen painting.

## Verification

The updated Studio build was inspected at the theft, discovery, juke, sculpture
route, sprint, museum-door impact, edge-on turn, exit, street run, home entrance,
protection-barrier impact, and final hiding joke. The public-domain art and
custom expression decals rendered. The revised 5.35–7.00, 8.70–9.55,
9.55–11.00, 11.00–12.25, 12.25–13.30, and 13.30–15.00 camera shots were
checked against the centered 9:16 guide. The R6 hips now swing forward and back on
their correct local axis, rather than twisting the legs sideways.
Sampling the actor paths every 0.1 seconds from 4.0 to 17.0 seconds found a
minimum 3.31-stud root separation at 8.0 seconds. Studio overlap checks at
0.1-second intervals found zero officer body or accessory overlaps with either
museum bust from 3.8 to 8.5 seconds and zero overlaps between the actors from
7.3 to 11.2 seconds. On the longer runway, sampled forward speed stayed above
6.4 studs per second from 11.0 to 15.5 seconds; the thief crossed the home
threshold at x=63 around 15.8 seconds and kept the running gait until after it.
At the impact, the frame spans 4.74 studs across the narrow
opening; after turning, its span across the opening is 0.50 studs. At the home
entrance, the 4.75-stud frame fits inside the 6.4-stud opening. A Studio overlap
check from 15.0 to 16.5 seconds found no frame contact with either home jamb.
Camera motion and shake are confined to the chase and impacts. The revised
24-second cut completed in Studio and returned the camera to `Custom`, removed
the temporary grade, bloom and depth of field, and hid the end card. Studio's
command tool can itself change the preview camera type while it inspects the
running client; this does not occur during ordinary playback.
The Studio console showed no cinematic script error; an unrelated
default-avatar asset logged an asset-type warning. Audio playback remains
untested until IDs are assigned; the finished vertical recording has not been
evaluated.

Artwork: `mona_lisa.jpg`, `girl_pearl.jpg`, and `great_wave.jpg` are source
copies of the [Mona Lisa](https://commons.wikimedia.org/wiki/File:Mona_Lisa.jpg),
[Girl with a Pearl Earring](https://commons.wikimedia.org/wiki/File:Girl_with_a_Pearl_Earring.jpg),
and [The Great Wave](https://commons.wikimedia.org/wiki/File:The_Great_Wave_off_Kanagawa.jpg)
reproductions on Wikimedia Commons. Their uploaded image IDs are respectively
`134265287077679`, `101512166533414`, and `78251104595180`. Six expression
decals generated by `make_faces.py` are uploaded and referenced by the builder
and player scripts. The local JPEG and PNG files are the reproducible sources.
