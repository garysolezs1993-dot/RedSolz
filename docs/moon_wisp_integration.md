# Finished Moon Wisp visuals

For the latest connected shrine activation/release flow, timing and validation,
see [Moon Seal flow](moon_seal_flow.md). The visual/trail component details below
still apply; the older integration captures and test counts record that earlier pass.

Sources: `C:\Users\Owner\Downloads\wisp_all_clean_assets_for_codex.zip`
and `C:\Users\Owner\Downloads\wisp_trail_clean_frames_for_codex.zip`.
All 24 body/arrival PNGs and 8 separate trail PNGs are imported unchanged under
`assets/game_assets/moon_wisp/`. Hash comparison confirms identical bytes.
The supplied preview sheets are not used as gameplay textures.

## Reusable visual scene

Open `scenes/moon_wisp_visual.tscn` and select **MoonWispVisual**:

| Inspector setting | Starting value | Purpose |
| --- | --- | --- |
| Gameplay Scale | 0.045 | One uniform scale for all 24 frames |
| Idle FPS | 9 | Looping hover animation |
| Move FPS | 11 | Looping comet animation |
| Arrive FPS | 11 | Standalone one-shot arrival animation |
| Trail Enabled | true | Spawn separate history VFX during movement |
| Trail Spawn Distance | 20 px | Distance accumulated between emissions |
| Trail Min Interval | 0.08 s | Also limit emission frequency at high speed |
| Trail Lifetime | 0.5 s | All eight trail frames complete in this interval |
| Trail Fade Duration | 0.2 s | Smooth fade over the final part of the lifetime |
| Trail Scale | 0.05 | Uniform runtime scale for the full 444px trail canvas |
| Trail Opacity | 0.35 | Keep afterimages dimmer than the Wisp core |
| Max Trail Instances | 12 | Preallocated pool capacity |

The visible idle swirl is approximately 14–16 world pixels tall; Red is
approximately 35–40 world pixels tall. The moving tail and arrival burst can
extend farther. The 512×512 texture canvas is always preserved in full.
Nearest filtering and an unshaded sprite material retain the supplied glow.
The moving body still uses `wisp_move_00` through `07`, including its baked
tail. Separate supplied trail-only frames now leave a fading history behind
it. No source art is changed and no additional light is added.

The source's bright core changes position inside its canvas, especially
between the idle, move, and arrival sets. Reviewed `CORE_ANCHORS` in
`scripts/moon_wisp_visual.gd` compensate with sprite offsets only. The world
pivot always represents the core; scale never changes between frames.
For the final dissolving arrival frames, the pivot follows the burst center.
These offsets do not edit, crop, or resample any PNG.

Moving art faces right in the source. Reverse travel mirrors it horizontally
and mirrors the pivot with it. Rotation points the comet along vertical and
diagonal travel, keeping the tail behind the head. Arrival starts with a
diagonal comet, so its orientation compensates for that source angle.

The component exposes `play_state("idle"/"move"/"arrive")`,
`play_appearance(duration)`, `face_travel(displacement)`, `deactivate()`,
and `arrival_finished`.
It hides after the arrival clip completes and can be reused afterward.

## World-space afterimages

`scripts/moon_wisp_trail_pool.gd` shares one eight-frame SpriteFrames resource
among twelve reusable AnimatedSprite2D nodes. The pool is parented to the
current world scene, outside the moving guide's transform and visibility
hierarchy. Each emission assigns position, heading, horizontal flip, scale,
and opacity once. Neither the Wisp moving nor its guide hiding changes those
existing world positions or rotations.

Emission requires both 20 px of movement and 0.08 seconds since the previous
spawn; it never runs simply because the move animation is playing. The idle,
appearance, arrival, and hidden states do not emit. Each afterimage plays at
16 FPS for 0.5 seconds, holds its initial opacity for 0.3 seconds, then fades
with smoothstep during the final 0.2 seconds. Lifetime changes adjust playback
speed to fit the entire clip. Completed nodes return to the pool; a full pool
skips new emissions. No per-spawn node allocation or tween is needed.

The trail's fixed front pivot mirrors with horizontal flip. Vertical and
diagonal directions rotate the whole sprite so its rear remains behind its
spawn direction. The entire supplied 444×444 canvas is used, without cropping
or individually resizing frames. Old effects retain their original heading
even when the Wisp turns, preserving its actual travel history.

Stop/disappear allows old effects to finish naturally. Removing the component
or changing stages frees the external pool, avoiding orphan VFX. Trail nodes
continue processing during the first paused camera tour.

## Existing guidance integration

`scripts/moon_wisp_guide.gd` still owns targets, movement, cooldowns, camera
control, and Stage 1 progression. It instantiates the reusable visual and
maps its existing phases:

| Guidance phase | Visual |
| --- | --- |
| Initial swirl | reversed arrival gathering effect (0.28 s), then idle |
| Pause, landmark | idle |
| Travel | move |
| Fade (existing phase name) | arrive, once |
| Hidden, camera return | inactive |

Arrival replaces the previous alpha-only fade. The guide waits for the
animation's completion before hiding and returning the camera.
Its default arrival intervals remain 0.7 seconds for normal/intro guidance
and 0.85 seconds for the brief Seal 2 cue. The visual fits its eight frames
into that interval, giving effective arrival rates of about 11.4 / 9.4 FPS.
To change **guided arrival timing**, tune `brief_fade_duration` and the normal
arrival interval in the guide; `Arrive FPS` controls untimed standalone use.

Seal 2 now lasts approximately 7.3 seconds total: a 3-second flight and
3-second landmark hover, plus the initial hover/pause and 0.85-second arrival.
The same route now takes 2.5 times as long to travel.
Seal 1 keeps the full paused
camera tour, revealing the Cellar entrance rather than its exact seal.
Later guidance does not take over the camera. The final seal awakens
the Moon Gate and now releases a short Wisp cue along its quiet approach.
Enemy avoidance, inactivity cues,
Escape cancellation, scene-change cleanup, and saved progression remain.

## Actual gameplay previews

Captured at the current 960×540 viewport and 1.35 gameplay zoom:

- [Animated gameplay preview: idle, right, left, up, disappear](previews/moon_wisp_afterimages.gif)
- [Idle beside Red](previews/moon_wisp_01_idle_beside_red.png)
- [Moving right](previews/moon_wisp_02_move_right.png)
- [Moving left](previews/moon_wisp_03_move_left.png)
- [Moving upward](previews/moon_wisp_04_move_up.png)
- [Arrival burst](previews/moon_wisp_05_arrival.png)
- [First camera tour](previews/moon_wisp_06_cinematic.png)
- [Lingering path history](previews/moon_wisp_07_trail_history.png)
- [After disappearing](previews/moon_wisp_08_after_disappear.png)

The GIF uses 81 complete gameplay screenshots. Only the preview is palette
encoded; source textures and lossless PNG screenshots are unchanged.

The beside-Red preview was presented before retaining the initial scale.
The source art naturally changes swirl/tail/burst shape; the anchors correct
placement, not the authored shape differences.

## Validation

Godot 4.7.2 Compatibility; isolated test saves, not the player's journey:

| Suite | Checks | Failures |
| --- | ---: | ---: |
| Moon Wisp visual | 567 | 0 |
| World-space trail lifecycle | 163 | 0 |
| Moon Seal progression | 59 | 0 |
| Seal encounters | 33 | 0 |
| Total | 822 | 0 |

Tests cover all frames, real transparent corners, whole-canvas textures,
constant scale, mirrored/vertical core alignment, actual idle/move looping,
arrival's final-frame interval and single completion, reuse, the paused
camera tour, brief upward/reverse guidance, save progression, and gate logic.
Trail tests additionally cover stationary emission suppression, fixed world
positions and headings, all eight frames playing before expiry, fading after
stop/hide, pool bounds/reuse, appearance settling into idle, processing while
the cinematic pauses gameplay, and scene-change cleanup.
Eight rendered previews and selected GIF frames were inspected.
No script/runtime errors occurred.
Godot emits the existing Camera2D physics-interpolation warning.

These tests include the slower 7.3-second Seal 2 cue. The earlier ground-combo
suite also passed 109 checks during the first visual integration; it was not
rerun for this trail-only change.

Logs: `docs/afterimage_test_moon_wisp_visual.log`,
`afterimage_test_moon_wisp_trails.log`, `afterimage_test_moon_seal_progression.log`,
`afterimage_test_seal_encounters.log`, and `wisp_afterimage_capture.log`.
Before integration, the guide was copied to
`.godot/local_backups/wisp-assets-20261011-223140/moon_wisp_guide.gd`.
Before adding afterimages, the visual/guide scripts and scene were copied to
`.godot/local_backups/wisp-afterimages-20261011-232033/`.
This visual pass does not change player combat, level geometry, or source art.
