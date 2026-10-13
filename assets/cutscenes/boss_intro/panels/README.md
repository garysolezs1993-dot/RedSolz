# Final boss-intro panel slots

Place the clean individual PNGs here using these exact filenames:

| Shot | Filename | Inspector resource |
| --- | --- | --- |
| 01 Clearing | `boss_intro_01_clearing.png` | Clearing Artwork |
| 02 Silent Figure | `boss_intro_02_silent_figure.png` | Silent Figure Artwork |
| 03 White Lily | `boss_intro_03_white_lily.png` | Lily Artwork |
| 04 Recognition | `boss_intro_04_recognition.png` | Recognition Artwork |
| 05 Memory | `boss_intro_05_memory.png` | Memory Artwork |
| 06 Brother | `boss_intro_06_brother.png` | Brother Artwork |
| 07 Run | `boss_intro_07_run.png` | Run Artwork |
| 08 Curse Awakens | `boss_intro_08_curse_awakens.png` | Curse Awakens Artwork |

The controller loads only these named files when Stage 2 starts. Alternatively, open `scenes/BossIntroCutscene.tscn` and assign each Texture2D under **Final Panel Slots (01-08)**. Explicit Inspector resources take precedence over files in this folder.

Missing shots keep the current fallback: existing in-engine staging for 01/02/06/07/08, and drawn placeholders for 03/04/05. Files can arrive one at a time. Restart gameplay after Godot imports newly added PNGs.

Use clean landscape panels, preferably matching 16:9 and a consistent resolution. No dialogue, titles, numbers, labels, borders, letterboxing or storyboard contact sheets in the images. Godot draws those presentation elements separately. Leave important features away from the top/bottom edges because the controller supplies letterbox bars and a subtle zoom.

Reference-only storyboard: `docs/reference/boss_intro_storyboard_v2.png`. That folder has `.gdignore` and is not used by the runtime cutscene.
