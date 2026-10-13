# Cursed Wolf hybrid intro framework

## Review

The intro uses existing Stage 2 terrain, Red and Cursed Wolf sprites, the current howl/AOE frames, the existing breathing sound and the boss-only dark howl audio. All eight story shots have independent optional Texture2D resources. Five final illustrations from `boss_intro_cutscene_art_pack.zip` are now assigned to shots 03/04/05/07/08; shots 01/02/06 keep their in-engine staging. The supplied storyboard image remains reference only. Imported PNGs are byte-identical to the ZIP; no images were generated or edited.

With the final-art fades and one live howl, the full rendered sequence restores player control at about 26.5 seconds. Boss AI resumes one second later. See [final artwork integration and full-run preview](boss_intro_final_art.md).

## Trigger and sequence

`scenes/stage2_boss.tscn` now instances `scenes/BossIntroCutscene.tscn`. Red can traverse the entrance normally. The intro starts when she is grounded at or beyond X = 1000, before the existing wolf detection range. While waiting, the wolf faces away, AI is held and its damage receivers are disabled. The boss HP bar stays hidden.

The sequence is:

1. Pause gameplay; Red enters along the continuous arena floor; pan and gently zoom toward the wolf.
2. Hold the silent, away-facing wolf with quiet breathing and subdued existing forest music.
3. Reveal the scarf/white-lily illustration for about 1.75 seconds, plus fades.
4. Show Red's recognition illustration with a subtle 3% zoom.
5. Show the warmer memory illustration for 2.5 seconds, plus fades.
6. Return to the arena: `...Brother?`
7. Turn the existing wolf side pose toward Red, briefly soften its tint: `Run.`
8. Hold the curse awakening illustration, then return to the arena and frame both actors. Play one presentation-only howl/AOE burst and the existing dark howl, with a small camera shake synchronized to release frame 4. This beat causes no damage.
9. Show `CURSED WOLF` / `The Lost Brother`; settle the camera back to Red; fade in the HUD/boss HP bar and restore player control. Hold the boss idle for one second, then resume its normal AI.

Region labels are hidden during cinematic framing and restored afterward. The curse sprite draws behind the wolf, retaining the existing foot/ground anchor. The battle staging gap is 360 pixels so both actors fit in the existing gameplay camera when control returns.

The existing sprite set contains side views, not a true rear or turning animation. The silent beat therefore uses the existing idle frame facing away, and the turn switches its horizontal orientation after a short pause. The brief softened tint affects the whole sprite; it does not repaint eyes or require a new sprite. These are deliberate prototype limitations pending later artwork/poses.

## Replaceable artwork and tuning

Open `scenes/BossIntroCutscene.tscn`, select its root, and use the Inspector:

| Setting | Purpose |
| --- | --- |
| Clearing Artwork | `boss_intro_01_clearing.png` |
| Silent Figure Artwork | `boss_intro_02_silent_figure.png` |
| Lily Artwork | Clean standalone scarf + white-lily illustration |
| Recognition Artwork | Clean standalone Red reaction illustration |
| Memory Artwork | Clean standalone memory illustration |
| Brother Artwork | `boss_intro_06_brother.png`, with Godot-rendered `...Brother?` |
| Run Artwork | `boss_intro_07_run.png`, with Godot-rendered `Run.` |
| Curse Awakens Artwork | `boss_intro_08_curse_awakens.png` |
| Panel Art Directory | Auto-load folder for the eight exact filenames |
| Trigger X | Arena approach trigger, default 1000 |
| Battle Spacing | Distance left of the wolf when the fight begins, default 360 |
| Entry Duration / Silent Hold | In-engine establishing shots |
| Lily / Recognition / Memory Hold | Illustrated shot durations |
| Brother / Run Hold | Dialogue reading time |
| Title Hold | Boss title reading time |
| Opening Breathing Window | One-time boss AI delay after control returns, default 1 second; applies after Skip too |
| Cutscene Enabled | Disable before loading the stage for development captures |

The eight independent shot resources use one reusable `TextureRect` renderer with aspect-preserving covered rendering. Assigning a texture replaces only that shot's fallback. Put clean PNGs in `assets/cutscenes/boss_intro/panels/` using the exact names in its README, or assign the Inspector resources directly under **Final Panel Slots (01-08)**. Explicit resources win over automatic filename loading. Missing files are optional and do not produce missing-resource errors. The live howl follows the final illustrated shot; the release-frame shake belongs to that live beat.

The shot order is fixed: Clearing → Silent Figure → White Lily → Recognition → Memory → Brother → Run → Curse Awakens → boss title → HUD → control. Dialogue stays in a separate Label above the panel renderer. Fades, letterbox bars, zooms, the curse shake, audio and the camera/battle staging remain controller-owned. The release-frame shake occurs during the live arena howl after the illustrated curse shot.

The latest storyboard is copied byte-for-byte to `docs/reference/boss_intro_storyboard_v2.png`. Its folder has `.gdignore`, excluding reference images from Godot asset import. It is never assigned to a runtime texture slot.

`scripts/story_transitions.gd` supplies the same reusable fade/hold helpers as the opening. Its skip-action installer now accepts an action name while preserving the opening's default behavior.

## Skip and fight handoff

`skip_boss_intro` defaults to Escape, Enter, Space, controller Start and controller B. The visible Skip button calls the same function. The InputMap action can be defined in Project Settings to customize those defaults.

Skip cancels the active cinematic tween and performs the same fight handoff as natural completion:

- Red is placed safely on the arena floor, left of the wolf.
- Normal camera/current-camera state and smoothing are restored.
- Red returns to idle; her movement pause, interpolation mode and visual processing mode are restored.
- Wolf body/hurtbox layers are restored immediately. AI processing resumes after the configurable opening breathing window, while Red can already move, attack or dash.
- The boss HP bar receives current/max health and restores its original opacity.
- Temporary panels, shake, audio players and curse sprite are freed with the controller.
- Normal boss music resumes through AudioDirector.

Boss health, attack damage, attack patterns, cooldowns, movement constants and combat-state code are not modified. `scripts/cursed_wolf_boss.gd` matches its pre-change backup byte-for-byte. The intro gates the actor externally, then `scripts/boss_opening_grace.gd` releases its processing after the opening delay. The intro currently plays once per Stage 2 scene load, so retries can use Skip; there is no new persistent story/save flag.

## Backup and capture evidence

Backup folder:

`.godot/local_backups/boss-intro-framework-20261013-142034/`

It contains the prior Stage 2 scene/layout, UI script, AudioDirector, story transition helper and boss combat script.

Editor import completed without script errors. `tools/capture_boss_intro.gd` now records the final-art playback at 960×540 using an isolated journey path and muted audio in memory. Its log records every story phase, then resumed battle with `paused=false` and `HUD=true`. The final integration also has a dedicated test covering watched completion, Skip in every major phase, keyboard/controller/button Skip, repeated Skip, actor/HUD/camera restoration and post-Skip movement/attack/dash. See `docs/boss_intro_final_art_test.log` and `docs/boss_intro_final_art_capture.log`.

- [Silent wolf](previews/boss_intro_silent_wolf.png)
- [Lily reveal](previews/boss_intro_lily.png)
- [Red recognition](previews/boss_intro_recognition.png)
- [Warm memory](previews/boss_intro_memory.png)
- [Brother dialogue](previews/boss_intro_brother.png)
- [Run dialogue](previews/boss_intro_run.png)
- [Curse takeover](previews/boss_intro_curse_takeover.png)
- [Live cinematic howl](previews/boss_intro_cinematic_howl.png)
- [Boss title](previews/boss_intro_boss_title.png)
- [Battle after handoff](previews/boss_intro_battle.png)

To review live with audio, enter Stage 2 through the Moon Gate or the existing F7 shortcut, then move right into the clearing. The five supplied final illustrations are already assigned in the boss-intro scene's Inspector resources.

## Eight-slot preparation backup

Before adding the extra slots, the working controller, this document and the unchanged wolf combat script were backed up to `.godot/local_backups/boss-intro-eight-slots-20261013-151010/`. The sequence's timing values, Skip/fight handoff and wolf combat script remain unchanged. This preparation adds no final image files. Editor import is recorded in `docs/boss_intro_eight_slots_import.log`; no gameplay tests were run for this preparation.
