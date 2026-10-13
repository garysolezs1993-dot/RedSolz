# Red's buffered three-hit ground combo

Ground attacks clear incoming horizontal momentum and keep Red stationary
through startup, active frames and their closing-pose recovery. Steering and
jump resume afterward; an available L/Shift dash can cancel immediately,
respecting the [ability cooldown rules](red_ability_cooldowns.md).

## Shorter ground recovery (11 October 2026)

The basic ground combo now uses frames 5–7 as its complete recovery, playing
these existing poses in 0.14 seconds for hits 1/2 and 0.20 seconds for hit 3.
Startup and active frames 0–4 retain their original speed, hitboxes and damage.
There is no additional landing/recover animation after a ground swing. With no
follow-up input, Red returns to idle; held movement resumes walk/run once the
recovery ends. All eight source poses and their synchronized VFX are retained.

The next C press can chain during frames 4–7 on hits 1/2. The existing 0.25s
early input buffer remains, and holding C still does not chain automatically.
Dash cancels remain available throughout. Air combos, the launcher, downward
landing recovery and ability cooldowns retain their previous behavior.

Inspector tuning on Player: `ground_attack_recovery`,
`ground_finisher_recovery`, and `combo_input_buffer`. This timing pass has not
been playtested or had its regression suites rerun. Validation totals in the
historical integration notes below predate this change.

## Current master pack integration (11 October 2026)

### First-attack scale flash fix

The first C attack could briefly render VFX at its hidden sprite's default 1x
scale even though the script already reported 0.105. A cold-start capture
reproduced this renderer interpolation bug (243px wide before settling).
`red.gd` now seeds the anchor and VFX scale before adding the nodes to the tree,
and resets their interpolation after showing the configured effect. Subsequent
body movement stays interpolated normally.

`tools/tests/test_red_combo_startup.gd` captures the first 20 visible renders
without prewarming the combo and checks their actual image extents. Optional
`--physics-ticks=10` stresses interpolation. The corrected stress capture starts
at 25px wide, with a 46px maximum through the sampled strike poses; all 109
existing combo assertions also pass. Art, attack timing and damage are unchanged.

Source: `red_3hit_combo_master_pack_for_codex.zip`. All 48 individual RGBA
512x512 PNGs were imported unchanged after reading `README_FOR_CODEX.txt`.
Active assets: `assets/game_assets/red_gothic_replacements/combo_master/`,
with eight character frames and eight separate VFX frames per attack.
The original README and manifest SHA-256 hashes are retained alongside them.
The temporary basic-attack fallback and rejected older combo pack are no longer
referenced by the active ground clips. Previous notes below are historical.

| Step | Character clip | FPS | Damage frames | Recovery |
| --- | --- | --- | --- | --- |
| 1 | `attack_slash` | 12 | 02-04 | 0.16s |
| 2 | `attack_spin` | 12 | 02-04 | 0.16s |
| 3 | `attack_thrust` | 10 | 02-04 | 0.24s |

Character scale remains 0.105 for every pose. Manually reviewed boot contacts
in `COMBO_FOOT_LINES` correct only vertical ground placement. No source crop,
trim, automatic centering, recoloring or individual frame resizing is applied.
Source canvases retain some faint alpha specks and edge-reaching trails; these
are preserved as required. No opaque backgrounds, white guide borders or
neighboring characters were visible in the inspected source/game previews.

Runtime nodes: `Player/VFXAnchor/AttackVFX`, separate from `Player/Visual` and
the retained `AttackEffect` for directional/Crescent attacks. Red's frame N and
frame progress directly drive effect frame N, including during hitstop.
`COMBO_VFX_PROFILES` assigns one fixed anchor/scale at each swing's start:

| Step | Right-facing anchor | VFX scale |
| --- | --- | --- |
| 1 | (22, -5) | 0.105 |
| 2 | (22, -5) | 0.105 |
| 3 | (20, -8) | 0.12 |

Facing left mirrors anchor X and the effect. Boot corrections do not move VFX;
effects follow Red's body and hide on completion or cancellation. The old
AttackEffect stays hidden during ground combos. Red never moves to fit VFX.

Existing buffered chaining, C/click controls, 20 damage per swing, hitbox shape,
knockback and hitstop remain. Frames 04-06 allow chaining with a 0.25s early
buffer. Finisher cannot queue a fourth swing. Up+C, airborne Down+C and
R Crescent remain separate; wolf summon remains disabled.

Verification covers every paired frame, fixed anchor/scale, grounded soles,
both facings, chaining, cancellation, one hit per swing and idle recovery.
Combat/death, directional, Crescent, retained skills, movement and crouch/drop
regressions pass. Six Stage 1 captures reviewed at 1.25 camera zoom.
Final totals: 219 headless assertions passed, plus all 109 combo assertions
passed again in the rendered game.
Logs: `.godot/combo_master_review/`; captures: `.godot/red_combo_checks/`.
The render/combat test shutdown also reports existing ObjectDB/resource cleanup
warnings; gameplay assertions and runtime checks pass.

Tuning: `scripts/red_animation_library.gd` (source/FPS, boot anchors, VFX
profiles), `scripts/red.gd` (combo/window/hitbox logic). Reimport via
`tools/import_red_combo_master.py`; verify via `tools/tests/test_red_combo.gd`
with `--presentation-test` and optional `--capture`.

## Previous fallback integration (superseded)

Implemented locally on 11 October 2026. Controls: C / left mouse attack,
Up + C rising, Down + C while airborne downward, R Crescent. Wolf summon stays
disabled.

## Agreed artwork fallback

The supplied `red_combo_and_vfx_all_for_codex.zip` was inspected in full.
It contains 24 character PNGs and 24 VFX PNGs, with RGBA transparency, but the
exports are not clean enough to activate:

- Attack 1 character frame 04 cuts off much of Red's right side. Frame 06
  includes a neighboring sword/boot on the left and scraps at the top.
- Attack 2 frame 04 cuts off the right side; frame 06 includes a substantial
  neighboring Red pose at the left edge.
- Attack 3 frame 02 includes a neighboring cape on the right; frame 04 cuts
  through Red. Other frames also contain clipped swords or edge scraps.
- Attack 1 VFX has opaque white guide/border lines around the canvases.
- Some Attack 2/3 VFX arcs and particles are cut at canvas boundaries.
- Canvases vary between 443/445px wide and 443/444px high, and placement shifts
  between source rows.

The user chose: **build the combo with the current clean attack artwork and
wait for corrected replacements**. None of the supplied combo frames is active
or cropped, resized, recolored or otherwise changed. The source ZIP remains
in Downloads; its contact-sheet inspection is in
`.godot/red_combo_review/source.png`.

All three gameplay steps use the current unchanged
`red_basic_attack_frames_codex.zip` artwork in
`assets/game_assets/red_gothic_replacements/basic_attack/`. They share its fixed
0.105 scale and authored sole anchors. Existing names `attack_slash`,
`attack_spin`, `attack_thrust` remain to preserve references.

The three steps currently share the same clean swing poses. A distinctive
reverse slash and finisher pose, plus the new ground VFX, await corrected art.

## Behavior

| Step | Clip | FPS | Damage frames | Recovery if not chained |
| --- | --- | --- | --- | --- |
| 1 | `attack_slash` | 12 | 02–04 | 0.16s |
| 2 | `attack_spin` | 12 | 02–04 | 0.16s |
| 3 | `attack_thrust` | 10 | 03–05 | 0.24s |

- A fresh ground press always starts step 1.
- Press again during zero-based frames 04–06 of steps 1 or 2 to chain.
- Early presses are buffered for 0.25 seconds; an expired buffer is discarded.
- Each queued press advances one step. Holding the button does not auto-chain.
- Without another press, the current swing finishes and Red returns to idle.
- Step 3 cannot queue a fourth attack; its extra recovery gives commitment.
- Leaving the floor prevents ground chaining. Rising and air/downward attacks
  stay separate. Hurt/death cancel both the current swing and queued input.
- Each swing deals the existing 20 damage once per target. Existing hitbox
  reach, body collision, hitstop and attack sounds remain.

## Separate VFX layer

The existing `AttackEffect` AnimatedSprite2D remains independent of Red's
character sprite. Ground combo VFX stays hidden while waiting for corrected
exports. No border-contaminated source frames are displayed.

`_update_ground_combo_effect()` is ready for `attack_1_vfx`, `attack_2_vfx`,
`attack_3_vfx` clips. It synchronizes all eight effect frames to the remaining
swing time, starting at character frame 02 for steps 1/2 and 03 for step 3.
The character's frame/progress drives this layer, so it cannot drift on hitstop
or continue after cancellation. The corrected canvases/pivots must be reviewed
before those clips are added to `red_animation_library.gd::attack_effects()`.

## Verification

Godot 4.7.2 imported the implementation without script errors.
**222 gameplay assertions passed**: combo 54, combat/death 25, directional 10,
Crescent 12, retained skills 14, movement 39, crouch/platform drop 10, and
broader presentation/checkpoint/menu flow 58.

The combo suite also passed all 54 assertions in the rendered game. Six
native 960x540 Stage 1 screenshots show all three steps facing both directions,
with the current 1.25 camera zoom, grounded soles and consistent character
scale. Screenshot I/O can consume part of a combo window, so the checks accept
an input already consumed at that window and observe recovery at the actual
attack end rather than after a fixed wall-clock screenshot delay.

The inspected fallback frames have no opaque rectangular background or
neighboring-pose fragments in these captures. These results do not certify
the rejected ZIP's artwork or demonstrate alignment of its inactive VFX.

## Tuning and checking

- `scripts/red.gd`: `COMBO_WINDOW`, `combo_input_buffer`,
  `FINISHER_RECOVERY`, `_configure_attack()`.
- `scripts/red_animation_library.gd::add_ground_combat()`: clip artwork/FPS.
- `tools/tests/test_red_combo.gd`: real-player combo/input/damage checks.
  Run with `--presentation-test`; add `--capture` for native Stage 1 screenshots
  in `.godot/red_combo_checks/`.

For the next export, supply individual complete poses with the same canvas,
scale and ground line across all eight frames. Remove neighboring sprites,
white guide lines and any cuts through the body, sword or effect before export.
Do not slice through artwork from a tightly packed contact sheet.
