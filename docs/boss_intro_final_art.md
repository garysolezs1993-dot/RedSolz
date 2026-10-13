# Boss intro: final artwork integration

## Full run

[Watch the full rendered preview](previews/boss_intro_final_full_run.gif)

The preview is a silent 960×540 GIF sampled at 5 FPS. It shows the entire intro from Red's entry to the restored battle HUD, at the actual pacing of about 27.5 seconds including the boss opening grace. In-game audio remains enabled normally; the capture mutes audio only in its own process.

## Artwork mapping

All five supplied 1672×941 PNGs are stored unchanged in `assets/cutscenes/boss_intro/final_art_v1/` and assigned directly in `scenes/BossIntroCutscene.tscn`:

| Shot | Source file | Resource |
| --- | --- | --- |
| 03 White lily / scarf | `moonlit_wolf_with_crimson_lily.png` | Lily Artwork |
| 04 Recognition | `moonlit_recognition_in_the_crimson_forest.png` | Recognition Artwork |
| 05 Warm memory | `golden_lily_in_the_ruined_garden.png` | Memory Artwork |
| 07 Wolf reaction / Run | `moonlit_wolf_and_crimson_hood.png` | Run Artwork |
| 08 Curse awakening | `crimson_moon_wolf_showdown.png` | Curse Awakens Artwork |

Red entering the clearing, the away-facing wolf and the return-to-present `...Brother?` shot keep the existing in-engine presentation. Godot draws both dialogue lines and the boss title separately. No source image contains baked dialogue or storyboard borders.

`docs/boss_intro_final_art_manifest.json` records ZIP/extracted SHA-256 matches for all five images. The ZIP contains only those images; there is no included README or instruction file.

## Presentation and audio

- Still panels use aspect-preserving full-screen rendering, linear texture filtering, 3% zoom and a 4-pixel pan. These controls are exported on the cinematic controller.
- Existing in-engine shots retain their letterboxing. Artwork defaults to full-screen to protect the raised muzzle and other edge details; **Illustration Letterbox Height** can be tuned later.
- Image transitions fade through black over 0.25 seconds each way. Reading holds remain configurable.
- Memory uses its supplied golden lighting plus a mild Godot warm tint. PNG pixels are untouched.
- The existing forest track supplies subdued atmosphere. Lily reveal lowers it to −38 dB; recognition/present use −27 dB; memory uses −33 dB. All levels remain subject to the player's Music volume setting.
- Quiet breathing uses the existing wolf huff. The single live howl after the illustrated scene uses the existing boss-only dark howl. No heartbeat asset was found, so no new heartbeat/audio asset was added.
- Combat music resumes through AudioDirector when the boss HP bar and player control return.

The curse illustration holds for 1.75 seconds after its fade. The camera returns to the arena and frames both actors for one full, presentation-only howl (8 frames at 7 FPS, about 1.14 seconds). Its AOE and dark audio play together; release frame 4 adds a small camera shake. Gameplay remains paused and no attack state or damage is triggered. The boss title then appears, the camera settles back to Red, and the HUD/control return.

Red can act immediately after handoff. The wolf stays idle for one second before its normal AI resumes, including when the intro is skipped. Tune **Opening Breathing Window** on the root of `scenes/BossIntroCutscene.tscn`; zero restores immediate AI processing. This one-time external delay is implemented in `scripts/boss_opening_grace.gd`.

## Verification

Before the later live-howl adjustment, `tools/tests/test_boss_intro_final_art.gd` completed **234 checks, zero failures** (historical results; not rerun for this timing change):

- all five resource mappings and actual displayed textures;
- all three retained in-engine fallbacks;
- hidden HUD, paused player/world and disabled boss AI during the cinematic;
- separate Brother/Run dialogue and title-before-HUD ordering;
- natural completion and Skip at waiting, entry, silent wolf, lily, recognition, memory, Brother, wolf turn, Run, curse, camera return, title and HUD reveal;
- Escape, controller Start, Skip button and repeated Skip requests;
- restored normal camera, full HUD opacity, boss body/hurtbox layers, AI and music context;
- unchanged actor health and safe grounded Red placement;
- movement, basic attack and dash cancellation after Skip.

The full rendered run is in `docs/boss_intro_final_art_capture.log`; the test results are in `docs/boss_intro_final_art_test.log`. Both use isolated journey paths, leaving the player's saved journey untouched.

The wolf combat script matches its pre-import backup byte-for-byte. No attack behavior, damage, cooldown, health or arena geometry was changed for this art integration.

Backup: `.godot/local_backups/boss-intro-final-art-20261013-162253/`.

## Live-howl revision

Backup: `.godot/local_backups/boss-intro-live-howl-20261013-164751/`.

The updated rendered capture reaches player control at about 26.5 seconds, followed by the one-second boss opening grace. [Live howl screenshot](previews/boss_intro_cinematic_howl.png). The full-run GIF above includes the revision. Editor import and the rendered capture completed without script errors; logs are `docs/boss_intro_live_howl_import.log` and `docs/boss_intro_live_howl_capture.log`. The boss combat script remains byte-identical to this backup. The existing handoff test expectation now accommodates the intentional opening grace; automated tests were not rerun for this revision.

To review with sound: F5 → Stage 2 through the gate or F7 shortcut → walk into the clearing. Escape/Enter/Space or controller Start/B skips the intro and initializes the same fight.
