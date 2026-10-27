# Opening cutscene: final artwork

[Watch the complete silent preview](previews/opening_final_full_run.gif)

## Artwork

All eight supplied 1672x941 PNGs are stored unchanged in `assets/cutscenes/opening/final_art_v1/`. The pack's README was read before implementation. `opening_final_art_manifest.json` records byte-identical SHA-256 matches against the ZIP.

Each is assigned to its corresponding `OpeningStoryPanel` resource in `scenes/OpeningCutscene.tscn`:

| Panel | Source | Presentation |
| --- | --- | --- |
| 01 | `opening_01_silent_keep.png` | Gentle zoom toward the Keep; new two-line narration, 3 seconds |
| 02 | `opening_02_brother_prepares.png` | Slight rightward image drift; existing brother narration |
| 03 | `opening_03_red_tries_to_follow.png` | Slight leftward/downward drift toward the faces and hands |
| 04 | `opening_04_sibling_promise_lily.png` | Longest exchange, 7.2 seconds; warmer tint and two faint petal fragments at the lily line |
| 05 | `opening_05_brother_leaves.png` | Bittersweet farewell, leftward drift and one faint fragment |
| 06 | `opening_06_red_waits_by_lantern.png` | 3-second waiting beat with quieter music |
| 07 | `opening_07_red_decides_to_follow.png` | Red: "...You promised." then "So I'm coming to find you." |
| 08 | `opening_08_enter_silent_keep.png` | Silent establishing beat, gentle zoom and fade to title |

The white lily remains attached to her brother's scarf from the beginning. It is an old childhood keepsake, not a newly given flower. All narration, speaker names, dialogue and the title remain separate Godot UI.

## Framing and transitions

Textures use aspect-preserving **Keep Aspect Centered** rendering. Gentle motion starts slightly inside the screen and grows by about 3% toward a full-image fit. Pan is limited to available screen margins. The complete authored image stays visible throughout, including on other screen ratios. No image is stretched, cropped, resized or edited on disk.

Panel resources expose **Still Zoom**, **Still Pan**, **Music Level Db**, **Artwork**, ordered **Lines** and reading duration. The root exposes fade times, title duration, ambience volume and symbolic petal controls. The text box is placed below the important faces/lily; the final artworks hide temporary storyboard labels and counters.

Transitions crossfade the two artwork layers over 0.4 seconds. The final artwork fades to black over 0.65 seconds, followed by the THE SILENT KEEP / MOONLIT OATH title card. Stage 1 uses the existing arrival camera shot, control lock, HUD fade and return to the 1.35 gameplay camera. A transient **Find your brother.** message appears when control returns, including after Skip. Seal objectives and progression rules remain unchanged.

The scene defaults to **Auto Advance = true** for the requested short cinematic. Set it false on the OpeningCutscene root to return to reader-paced dialogue. Enter/Space/E/controller A or Continue still advance early. Escape/Start/B or Skip bypass the opening and arrival shot safely.

## Audio and flower motif

The existing opening music is ducked per shot: -27 dB at the Keep, -28 at the lily exchange, -29 at departure, -36 while Red waits, then builds to -24/-20 for her decision/journey. All remain subject to the player's Music setting. Stage 1 resumes its existing AudioDirector context.

No dedicated wind/forest recording exists in the project. `scripts/opening_ambience.gd` creates a quiet filtered wind/rustle loop at runtime, on the SFX bus. It fades in/out with the opening and respects the SFX volume setting. No source audio files or global audio settings were changed.

Opening petals reuse the complete existing `lily_trail_07.png` as faint, drifting fragments. There are only two one-off fragments in Panel 04 and one in Panel 05, with 0.11 opacity and 0.035 scale. They fade and free themselves. There is no Wisp, full movement trail, continuous spawning or gameplay particle emitter in the opening.

## Review and backup

Backup: `.godot/local_backups/opening-final-art-20261013-174444/`.

The full playback reached gameplay at frame 2601 (about 43.35 seconds at 60 FPS); the silent GIF contains 216 frames at 5 FPS. Both the full playback and an Escape Skip during the lily exchange were rendered using separate isolated journey paths and muted capture audio. The player's saved journey remains untouched. Capture logs record the normal Stage 1 camera, visible HUD, resumed world and Stage 1 music context. No automated tests were added or run for this art pass.

Logs: `opening_final_art_import.log`, `opening_final_art_capture.log`, `opening_final_art_skip_capture.log`. Editor import has no script errors; existing duplicate-UID warnings concern older spin-attack assets. The existing camera interpolation warning remains during arrival.

Run F5 -> Start Game to review with sound. The GIF is a silent preview; reading times, music levels and image resources can all be adjusted in the scene Inspector. No other story scenes or combat behaviour were changed.

- [Lily recognition](previews/opening_panel_4_line_3.png)
- [Waiting](previews/opening_panel_6.png)
- [Decision](previews/opening_panel_7.png)
- [Journey begins](previews/opening_panel_8.png)
- [Gameplay after Skip](previews/opening_skipped_gameplay.png)
