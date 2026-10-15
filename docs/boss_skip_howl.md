# Boss entry howl after Skip — 2026-10-15

Skipping the boss story now leads into the existing presentation-only howl before combat. Retry/Continue after an acknowledged intro uses the same short opening. The full watched sequence retains its howl and boss title.

## Behaviour

1. Skip cancels the current illustrated/story transition and clears its dialogue.
2. Red is staged safely on the arena floor to the left of the boss. Camera framing includes both actors.
3. After a brief 0.12-second fade each way, the Wolf plays all eight howl frames at the existing 7 FPS (about 1.14 seconds).
4. The existing boss-only dark howl sound, curse burst and release-frame shake play with it.
5. HUD/camera reveal takes 0.35 seconds for the quick path. Control returns, followed by the existing one-second boss AI grace.

The world remains paused and the boss AI and damage receivers remain disabled throughout the howl. It is a cinematic beat, not a damaging howl attack. Actor health, combat patterns and ability settings are unchanged.

Repeated Skip presses do not restart or bypass an in-progress howl. A first Skip during the watched howl preserves its current frame and clock, then omits the following title hold. A Skip after the howl finishes does not replay it. Automatic rematches wait for the scene-transition black fade to clear so the entire howl remains visible.

The controller uses one shared battle-reveal/howl path for watched intros, manual Skip and automatic rematches. The Skip button hides during the protected howl. Keyboard/controller Skip remains consumed safely.

## Validation

The rendered arena/rematch regression passed **86 checks with zero failures**, including howl on manual Skip and automatic retry, proper actor/HUD restoration, full-health rematches, preserved floor safety and normal melee damage.

The full revised ending still completes its original reveal → new hand-contact images → final wide shot, then returns through Prototype Complete to Title.

The expanded intro regression passed **324 checks with zero failures**. It exercises full watched playback and Skip at 14 phases, keyboard/controller/button input, repeated Skip, every howl animation frame, sound/burst playback, damage gating and post-handoff movement/attack/dash. Mid-howl Skip preserves the current frame; Skip after the howl does not replay it. No runtime or shader errors were reported in the final runs; existing camera interpolation warnings remain.

Logs: `.godot/boss_skip_howl_intro.log`, `.godot/boss_skip_howl_arena.log`, `.godot/boss_skip_howl_ending.log`. Capture saves are isolated from the normal journey.

Preview: [Boss howling after Skip](previews/boss_skip_howl.png).

Backup: `.godot/local_backups/boss-skip-howl-20261015-131625/`.
