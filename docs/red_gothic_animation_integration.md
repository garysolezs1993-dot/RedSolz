# Gothic Red animation integration

> **Stage 1 platform art:** the approved gothic forest kit now covers the whole
> stage, with area-specific dressing and unchanged collisions. See
> [previews, tuning and verification](gothic_forest_platform_kit.md).

> **Moon Lantern interaction:** nearby unlit checkpoints hold Red on frame 01;
> E continues 02–07, with hand-contact activation, active idle and smooth camera
> zoom. Escape cancels the waiting pose. See [sequence and tuning](moon_lantern_interaction.md).

> **Stage 1 chapter:** contextual lessons, explicit E checkpoints, spaced wolf
> encounters, retained optional routes and a quiet Moon Gate approach. See
> [chapter layout and tuning](stage1_chapter_redesign.md).

> **Boss melee fix:** the Cursed Wolf now has a body-sized damage hurtbox,
> separate from its compact terrain collision. Normal swings can hit the
> visible body, with one damage event per swing. See
> [diagnosis and measured reach](cursed_wolf_melee_hurtbox.md).

> **Ability balance update:** dash now has a 1.5s cooldown and one air dash
> until landing, with the existing 0.7s iframe. Crescent Slash has its own
> 3s cooldown from cast startup. Neither timer resets on attack cancellation.
> Both stages show ready/countdown labels below HP. See
> [ability cooldown rules and tuning](red_ability_cooldowns.md).

> **Downward Slash update:** the new full character/VFX pack is active.
> Airborne Down + C starts a committed dive or queues it after air hit 1/2/3.
> Ground/platform contact plays impact recovery; all basic attacks now lock
> normal steering through recovery. L/Shift dash can cancel those attacks or
> recovery immediately. See [controls and tuning](red_downward_slash.md).

> **Air combo update:** Jump + C now starts a buffered three-hit aerial string.
> Up + C launches Red; press C again to follow with Air Attack 1 while ascending.
> During the air combo, Red stays in place: steering and incoming horizontal
> momentum are blocked. The three new VFX-only ZIPs are active, with canvas-size
> compensation; fixed air character scales reduce the larger source poses.
> Attack 3 now uses `air_attack3_vfx_redone_clean_for_codex.zip`: eight clean
> 1536px effect frames at 0.04 scale, replacing the earlier cut fragments.
> See [air combo and launcher integration](red_air_combo.md) for controls,
> tuning, limits, source issues and verification. Old air mappings below are
> historical.

> **Crescent impact cleanup:** the six legacy impact drafts contain numbered
> labels and sheet guides. `projectile_frames()` now excludes those areas with
> AtlasTexture regions and margins, preserving the original 96px canvas, impact
> placement and 18fps timing. Original PNGs remain intact. All six display frames
> were reviewed in Godot; the 12 Crescent gameplay checks passed.

> **11 October 2026 update:** the [three-hit ground combo](red_ground_combo.md)
> now uses the new master pack's separate character and VFX frames, synchronized
> through a fixed anchor. Current attack controls are C / left click, Up + C,
> airborne Down + C, and R for Crescent. Older mappings below are historical.

> **10 October 2026 update:** movement, crouch, hurt, death, air attack and the rising
> character now use reviewed replacement PNGs. See
> [replacement integration](red_replacement_integration.md) for active sources,
> full-canvas transforms, unchanged gameplay timing and rejected export sets.
> The original draft mappings and test totals below describe the first import.

## Source and rendering

Source: `Red_Gothic_48x48_Fully_Exported_For_Codex.zip`.

231 numbered draft PNGs are imported under `assets/game_assets/red_gothic/`.
The import script copies their bytes unchanged and checks RGBA, canvas sizes,
and the character foot line. Original handoff documents accompany the frames;
the high-resolution/reference sheets remain in the original ZIP.

All character clips use the supplied 48×48 drafts at scale **1**. Every character
frame ends at source y=46. With a centered 48px canvas, `Visual.position=(0,-7)`
puts the foot line at the existing collider's bottom (+15). The body stays 18×30
through every animation, including crouch. All character/VFX nodes use nearest
filtering. Title and Game Over use integer 2× Red artwork.

The boss assets, boss controller, movement speeds, double jump, platform drop,
HP/HUD signals, checkpoint persistence and scene transition logic are preserved.
Dash retains its 0.15s burst, existing deceleration, and 0.7s invulnerability.
Damage invulnerability remains 0.5s.

## Implemented states and controls

| State/group | Input or transition | Implementation |
|---|---|---|
| Idle | Stop | All eight supplied idle poses loop, including the authored blink/breath/cape movement. |
| Walk / run | A/D or Left/Right; Shift sprint | One supplied run cycle at two playback rates. |
| Jump / double jump | Space twice | New jump clip, existing jump physics. |
| Fall | Descending | Four-frame loop. |
| Landing → recovery | Land on terrain | First three landing/recover frames, then last three, then locomotion. Jump can interrupt recovery. |
| Dash | L (existing Shift binding retained) | Eight poses across the original 0.15s; separate dust, petals and streak sprites. |
| Ground combo | J / left click | Three steps reuse the supplied basic attack cycle with different cadence. Original 20 damage and hitstop retained. |
| Air attack | J / click airborne | New air clip and separate slash effect; returns to fall/landing. |
| Rising Slash | W/Up + J/click | Upward hitbox; launches non-boss CharacterBody enemies on confirmed hit. |
| Downward Slash | S/Down + J/click airborne | Downward hitbox; small bounce on confirmed hit. |
| Crescent Slash | **C** | Cast → release on zero-based frame 3 → separate projectile → impact. |
| Hurt / knockback | Receive damage | Cancels attack/cast/dash, disables hitbox, locks controls during reaction. Heavy damage plays the full hurt/knockdown clip. |
| Death | HP reaches 0 | All ten death frames once, then the existing Game Over flow. |
| Crouch / crouch walk | S/Down; A/D while held | Enter, hold/walk, exit clips, stable foot line and body collider. |
| Platform drop | S/Down + Space | Existing one-way platform exception logic. |
| Interaction | E or gate interaction | Look-around poses. Movement/action input can interrupt optional presentation. |
| Pickup | Collect a moon petal | Pickup poses plus existing heal/save/toast behavior. Queued until grounded/available if busy. |
| Victory | Cursed Wolf HP reaches 0 | Bittersweet pose queued through HUD integration; resumes control afterward. |
| Later victory variants | `play_victory("normal_stage_clear")` / `"cheerful"` | Both imported and tested, available for future stages. |
| Other interactions | `play_interaction(kind)` | `open_chest`, `push_pull`, `sit_rest`, `cheer`, `point`, `look_up`, `talk`, `rest_sleep` are available for future objects. No new objects/mechanics added. |
| Existing skills | K, U, I | Guardian, Blood Blossom and Execution retain their gameplay; use the new cast poses because the pack has no dedicated character clips for those spells. |

Up Arrow still enters the Moon Gate; E and Enter remain supported by the gate.
F7 / the existing test button still skips to Stage 2. R retains retry behavior.

### Damage timing

Frame indices are **zero-based**. Ground/air hits are active on frames 2–5;
rising frames 2–4; downward frames 2–5. Anticipation/recovery do no melee damage.
Each attack damages any particular target once. The hitbox scans overlaps while
active, retaining target IDs for the active window. Facing is held during actions
so the attack and hitbox cannot point in opposite directions.

Crescent releases once at cast frame 3. Its independent swept collider moves at
420px/s, stops at terrain or enemies, hits once for 20 damage, plays the six-frame
impact, and expires after 560px if it misses. Hurt before release cancels the cast.

## Files changed for this integration

- `scripts/red.gd`: animation/action coordination and compatibility with current movement/combat.
- `scripts/red_animation_library.gd`: new frame mappings, playback rates and effect texture regions.
- `scripts/crescent_projectile.gd`: independent projectile collision, movement, range and impact.
- `scripts/hitbox.gd`: active overlap scanning with existing one-hit-per-target tracking.
- `scripts/forest_reward.gd`: pickup presentation hook.
- `scripts/stage_gate.gd`: interaction presentation hook.
- `scripts/ui.gd`: one-time bittersweet victory hook on boss defeat.
- `scripts/title_screen.gd`, `scenes/game_over.tscn`: new Red artwork.
- `scenes/main.tscn`, `scenes/stage2_boss.tscn`: native Red scale and updated control hints.
- `project.godot`: Crescent Slash C binding.
- `tools/import_gothic_red.py`: reproducible, byte-preserving import/audit.
- `tools/tests/test_red_animations.gd`, `red_damage_dummy.gd`, `capture_red_animations.gd`: checks and visual QA.

Existing unrelated working changes, including Stage 1 expansion and boss asset
replacement, were retained. No commit or push was performed for this request.

## Tests

Each group was implemented and checked before proceeding to the next.
The final integration passed **93 Red checks** across movement (19), ground
combat/hurt/death (15), directional combat (10), Crescent (12), crouch/drop (10)
and interaction/victory/VFX (13), plus original combo and K/U/I compatibility (14).

The existing presentation/gameplay suite passed **58 checks**, including hazards,
moving/crumbling platforms, dash immunity, checkpoint healing, death/Game Over,
Try Again, Continue, saved health through the Moon Gate, Stage 2 music and menus.

Run groups with Godot 4.7.2:

```powershell
& 'C:\Godot\Godot.exe' --headless --path . --script res://tools/tests/test_red_animations.gd -- --presentation-test --red-group=movement
```

Replace `movement` with `combat`, `directional`, `crescent`, `crouch`, or
`presentation`, or `legacy`. `--presentation-test` isolates saves/settings from the player's
normal files. Broader regression script: `tools/tests/test_presentation.gd`.
Visual capture script: `tools/tests/capture_red_animations.gd` (requires rendering,
so omit `--headless`). Logs and 28 native-resolution screenshots are under
`.godot/red_*` and `.godot/red_visual_checks/`, ignored by Git.

## Art issues and remaining polish

The pack's README identifies these as automatic downscales from AI concept
sheets, rather than hand-clean native pixel sprites. Feet/canvas alignment is
consistent, but pose detail and apparent body size vary, notably run/jump/hurt.
No per-frame resizing or alternate Red design was introduced to conceal this.

The supplied rising/downward and dash effect drafts still contain guide lines,
number circles and text remnants. Display-only AtlasTexture regions hide those
margins while retaining the untouched originals. Region-center compensation
keeps effects anchored as regions change. Some stray pixels/minor trimmed sparks
may remain; **clean, effect-only replacements are recommended for a release**.
The Crescent flight/impact drafts are cleaner and use their full 96px canvases.

The death clip ends with Red dissolving into particles. Game Over therefore uses
frame 05, which still shows Red fallen, while gameplay plays all ten frames.
Ground combo steps share one supplied basic attack animation; separate combo-step
art would add variety later. Chest/dialogue/rest poses are wired as callable clips,
but will need objects/story events when those mechanics are added.

Godot import also reports pre-existing duplicate UIDs in archived old spin frames
and a Camera2D physics-interpolation notice. The executed checks reported no
script/runtime errors. New Red clips do not reference those archived frames.
