# Downward Slash and attack movement

Integrated 11 October 2026 using `downward_slash_full_pack_for_codex.zip`.
The archive contains eight character PNGs and eight effect PNGs, without a
README. All sixteen are full 1536×1536 RGBA canvases with transparent outer
edges. They are copied unchanged into
`assets/game_assets/red_gothic_replacements/downward_master/`.
`source_manifest.json` records their source and SHA-256 hashes.

## Controls

- Jump, then Down/S + C: standalone Downward Slash.
- During Air Attack 1 or 2, press Down/S + C to queue the dive in the existing
  frames 04–06 chain window. Early presses use the existing 0.25s buffer.
- Air Attack 3 can also chain into Down/S + C. The third hit completes its
  damage frames first; the dive can begin at frames 06–07 or during its 0.24s
  recovery. Plain C still cannot start a fourth air combo hit.
- Up/W + C launches Red; C chains into the air combo while ascending. Down + C
  can replace the next aerial hit with the dive.
- C / left click still uses the ground or air combo. R remains Crescent Slash.

Downward Slash replaces the rest of the current aerial string. It does not
grant a fresh air combo or jump until Red actually lands. A second standalone
dive is likewise unavailable before landing; hurt/death cancel its state.

## Motion and recovery

Character frames 00–02 hold Red briefly in place. Frame 03 commits to downward
motion and stays displayed during travel. Horizontal velocity is zero and
normal steering, air hang and gravity cannot override the dive. The existing
20-damage hitbox activates once and remains active through travel; the old
hit-confirmed upward bounce is removed.

`move_and_slide()` resolves ground and one-way platform contact. On contact,
downward motion and damage stop, queued combo input clears, and source poses
04–07 play as `downward_impact`. Normal walking/jumping remain locked for
landing recovery, then return. Dash can cancel that recovery immediately.
There is no position teleport into the floor.
A bounded travel timeout prevents a stuck attack if no terrain is reached.

All basic ground and aerial attacks also clear incoming horizontal momentum
and block steering throughout startup, active frames and recovery. Regular
attacks retain their 0.16s recovery; finishers retain 0.24s. Normal gravity
resumes after an air swing, while horizontal movement waits for recovery to
finish. Rising Slash preserves its intended upward launch. Hurt can interrupt
an attack and retains knockback.

L/Shift dash can cancel any basic ground/air attack, Rising Slash, the dive,
or attack recovery when its 1.5s cooldown and one-air-dash allowance permit it.
It clears the old hitbox, queued hits and attack effects
before moving, and preserves the existing 0.7s immunity. Hold left/right when
pressing dash to choose direction; otherwise dash uses Red's current facing.
Cancellation does not restore jumps, the spent air combo or dive allowance.
Hurt, death and unrelated skill states retain their existing dash restrictions.
See [ability cooldowns](red_ability_cooldowns.md) for dash/Crescent limits and
the shared HUD indicators.

## Tuning

Select Player in the Godot inspector, or edit the exports in `scripts/red.gd`:

| Setting | Default | Purpose |
| --- | --- | --- |
| `downward_dive_speed` | 700 px/s | Committed downward velocity |
| `downward_landing_recovery` | 0.32s | Four impact poses and movement lock |
| `downward_max_dive_time` | 2.0s | Safety limit without terrain |

`scripts/red_animation_library.gd` controls character scale (0.035), startup
FPS (16), fixed VFX scale (0.04), and the mirrored VFX anchor (6, −5).
`DOWNWARD_IMPACT_FOOT_LINES` contains the reviewed sole anchors for source
frames 04, 05, 06, 07, respectively. These adjust display position only;
character collision and source PNGs remain intact.

`Player/VFXAnchor/DownwardSlashVFX` is separate from the character and old
effects. The character drives effect frame N directly, including the held
travel frame and four impact frames. No independent effect timer, atlas crop
or frame resizing is used. Scale is set before entering the scene tree and
interpolation resets when the configured effect becomes visible.
The broad effect draws behind Red so her pose remains readable.

## Previous verification (before the Air 3 follow-up/dash cancel update)

`tools/tests/test_red_downward_slash.gd` passes 177 checks headless and rendered
using actual Stage 1 terrain. It covers both facings, standalone dive, dives
after air hits 1/2, launcher routes, ground/platform contact, 1100 px/s at
10 physics ticks/s, stationary ground combos, recovery, timeout and hurt/death
cancellation. Captures and logs are in `.godot/red_dive_review/`.

`test_red_combo_startup.gd --downward-attack` passes twenty cold rendered size
checks at both 60 and 10 physics ticks/s. All sixteen active PNGs match their
archive bytes and have fully transparent outer canvas edges. Existing ground,
movement, combat/death, directional, Crescent, crouch and retained skill
regressions pass 221 checks; the air combo suite passes all 232 checks.
The air combo regression fixture waits for actual
recovery completion before testing a repeated launcher.

Tests use `--presentation-test` to isolate gameplay saves/settings. Some
existing fixture cleanup warnings remain at test exit.
