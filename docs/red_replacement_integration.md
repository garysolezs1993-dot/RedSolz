# Reviewed Red replacement bundle

## Current combat controls

The [air combo and Rising Slash launcher](red_air_combo.md) now use the air
master pack. Jump + C chains three air hits; Up + C launches Red and accepts
a buffered C follow-up while ascending. Each normal air string/vertical launch
is limited until landing. This supersedes the old standalone air clip below.
All three air hits now hold Red in place, with horizontal steering disabled.
The three clean-frames VFX ZIPs replace only the effects; the air character
art uses fixed 0.10/0.09/0.09 scales to better match movement poses.

The [buffered ground combo](red_ground_combo.md) now uses the 11 October master
pack's three distinct character/VFX sets at 12/12/10fps, with a fixed VFX anchor
and a heavier final recovery. This supersedes the basic-attack fallback and
earlier ground-combat mappings recorded below.

- C or left mouse: attack.
- Up Arrow / W + C: rising slash.
- Down Arrow / S + C while airborne: downward slash.
- R: Crescent Slash.
- Wolf summon is temporarily disabled: `special` has no input binding and
  `Red.wolf_summon_enabled` defaults to false. Its code/assets remain for future
  development. Enemy wolves and the Game Over guardian foreshadowing remain.

Stage HUD hints reflect these bindings. R no longer appears as a retry hint;
retry is selected from the Game Over menu after the death presentation.

Integrated locally on `editpower1`, 10 October 2026.
Source: `Red_Dash_Approved_8Frames_For_Codex (2).zip`. Despite its name, this
archive contains 15 nested ZIP files covering multiple animations.

## Activated replacements

Imported **78 original PNGs across 11 groups** into
`assets/game_assets/red_gothic_replacements/`. Each PNG matches its archive
bytes; `source_manifest.json` records original paths, canvas sizes and SHA-256.
No source image was cropped, resliced, recolored, stretched or resized.
The later `red_death_frames_codex.zip` adds eight unchanged death PNGs:
The later basic attack and Crescent packs add 32 unchanged PNGs:
**118 PNGs across 16 groups** are now recorded in the source manifest.

| Source group | Existing animation names | Mapping |
| --- | --- | --- |
| Idle, eight frames | `idle` | 00–07, looping at existing 5fps |
| Run, eight frames | `run`, `walk` | Existing 14fps run and 10fps walk fallback |
| Jump, eight frames | `jump`, `double_jump` | 00–07, existing 18fps |
| Fall, four frames | `fall` | Existing looping 8fps |
| Landing/recovery, four frames | `land`, `recover` | 00–01 then 02–03, both 12fps |
| Dash, eight frames | `dash` | Original 0.15-second burst |
| Air attack, eight frames | `attack_air` | Original 16fps and active frames |
| Hurt, eight frames | `hurt`, `knockback` | First four at 16fps; all eight at 18fps |
| Crouch, six frames | `crouch_enter`, `crouch_hold`, `crouch_exit` | Existing state subsets/rates |
| Crouch walk, eight frames | `crouch_move` | Existing 10fps |
| Rising slash character, eight frames | `rising_slash` | Source 01–08, original 16fps |
| New death, eight frames | `death` | `red_death_frames_codex.zip`, 00–07 once at 8fps |
| New basic attack, eight frames | `attack_slash`, `attack_spin`, `attack_thrust` | `red_basic_attack_frames_codex.zip`, 00–07 at the existing 14/16/13fps |
| Fixed Crescent character, eight frames | `crescent_cast` | `crescent_slash_fixed_all_for_codex.zip`, 01–08 at 16fps |
| Fixed Crescent cast VFX, eight frames | Separate `AttackEffect` layer | Frame index follows `crescent_cast`; no independent playback clock |
| Fixed Crescent projectile, eight frames | `flight` | Separate projectile, existing 18fps; existing impact retained |

**The rising folders are mislabeled in the ZIP.** `vfx_frames/` contains Red;
`character_frames/` contains the effect. The mapping uses actual image content,
not the misleading folder labels. The new effect has clipping defects, so the
existing separate rising effect remains active.

The title silhouette uses the new idle PNG. The Game Over pose now uses frame
07 of `red_death_frames_codex.zip`, at 0.21 scale, preserving the existing scene.

## Display transforms and gameplay

The source frames have different canvas sizes and different drawing scales.
`VISUAL_PROFILES` in `scripts/red_animation_library.gd` assigns one fixed
uniform scale to each entire animation, using the complete canvas.
The profile fields are scale, canvas width, canvas height, source ground pivot.
`character_transform()` places that pivot at the player's existing bottom,
y=15. Idle and death have reviewed vertical ground anchors per frame to correct
source placement; other clips retain their fixed pivot. No per-frame alpha
measurement or automatic recentering occurs at runtime.

`scripts/red.gd::_set_visual_offset()` applies these profiles while keeping
the existing body collider, movement and state machine.

- Body collider remains 18x30.
- Dash remains 0.15 seconds at 430px/s, with the existing 0.7-second iframe.
- Damage remains 20, with the same hitbox shapes, active frames and cooldowns.
- Landing plus recovery remains 1/3 second total despite the new frame count.
- Normal damage iframe remains 0.5 seconds.
- Jump, double jump, platform drop, checkpoint/gate and projectile code remain.
- New dash and air-attack frames already include trails. Their legacy overlays
  are hidden to avoid doubling the effects; the nodes/resources are retained.

Some trails/glows remain baked into the supplied character frames. They cannot
be separated without changing the artwork, which this request prohibited.

## Sets that need another export

These were inspected but not activated. Original files remain in the supplied
archive; no unrelated animation assets were deleted.

| Set | Reason / next export requirement |
| --- | --- |
| Dedicated walk | Frames 05–08 jump vertically relative to 01–04. Align real feet across the full eight-frame cycle before export. The clean run cycle at the slower existing walk rate is used meanwhile. |
| Basic attack review V2 | README identifies this as a review version. Frame 02 has a flat cut through the sword glow; source overlap also needs review. Export the complete sword/trail without neighboring-pose overlap. |
| Downward character | Frames 05–08 contain pieces of neighboring boots/poses at the top. Remove contamination in the source export. |
| Rising/downward VFX | Flat cuts through arcs and fragments from adjacent frames remain. Export complete effect silhouettes on consistent canvases. |
| Cast startup / Crescent character and VFX | Row-to-row pivot changes and edge fragments remain. A complete eight-frame pack needs stable character/charging-effect anchors. |
| Crescent projectile | Frames 06–07 have a foreign bright fragment at the left edge and the main wave shifts between rows. Export a standalone projectile with a stable travel origin. |
| Victory | Row-to-row feet shift and occasional fragments remain. Export one stationary cycle with the actual soles on a consistent floor line. |
| Earlier death export | `Red_Death_Cleaned_For_Codex.zip` was skipped: the six-frame sequence collapses, rises, then collapses again. It has now been superseded by `red_death_frames_codex.zip`. |

These findings explain why the earlier bundle's cast-startup → release → new
projectile chain was not activated. The new separate Crescent pack described
below now supplies the active character, cast effect and projectile artwork.
Existing interactions also remain; this bundle provides no replacement
interaction frames.

The accepted sets are better isolated, but still high-resolution concept
sprites displayed at game size, not native 48x48 pixel drawings. Small source
particles, baked trails and some source pose/ground variation remain. This is
not a claim that every supplied frame is now production-clean.

## Verification

- Godot 4.7.2 imported the assets and scripts successfully.
- All **113 Red animation/gameplay checks** passed across seven groups.
- All **58 broader presentation/gameplay regression checks** passed: **171
  assertions total**, including checkpoints, platforms, gate and Game Over.
- Captured and reviewed the actual stage at native 960x540 resolution, including
  replacement movement, crouch, attacks, hurt and the title/Game Over screens.
- Compared all imported PNGs against the nested archive bytes.

The import reported existing duplicate UIDs in old spin-attack backup folders.
Some automated test processes reported resource-in-use messages at shutdown;
their assertions passed. The rendered visual check reported the existing
Camera2D physics-interpolation warning and no script errors.

Press F8 to stop the current game, then F5 to use the updated resources.
No commit or push was performed for this request.

## Fix for oversized flashes during J and skills

The reported giant Red was an integration bug, not a bad crop in the supplied
PNG. Physics interpolation blended the local scale between a legacy 48px
attack and the replacement 512px idle, while the texture changed immediately.
That briefly drew the large idle canvas at an intermediate attack scale.
The same transition could make an attack briefly too small.

`scripts/red.gd::_set_visual_offset()` now resets the Visual node's physics
interpolation whenever its animation profile changes scale or pivot. Normal
movement continues to use interpolation. Source images and gameplay values
are unchanged.

Live render captures from `tools/tests/capture_red_attack_transitions.gd`
reproduced the bug: Red reached 233x267px immediately after J ended. After
the fix, the largest rendered pose in the same sequence was 41x39px, with no
oversized or shrunken transition frame. This check deliberately used 20 physics
ticks per second and up to 120 render frames per second to expose interpolation
between ticks. The earlier paused-pose screenshots did not catch this bug.
The normal 60Hz physics check also passed across 60 live rendered frames.
All 113 Red gameplay/animation assertions passed again after this fix.

## Idle feet alignment

The idle source canvases are all 512x512, but the sole positions differ:
frames 00–02 end at y=469, frame 03 at 468, frames 04–05 at 441,
frame 06 at 455, and frame 07 at 465. With one pivot, frames 04–05 floated
about 3 game pixels above the ground.

`IDLE_FOOT_LINES` in `scripts/red_animation_library.gd` stores the reviewed
sole boundaries for all eight poses. `character_transform("idle", frame)`
corrects vertical display placement when the frame changes. Every frame keeps
the same 0.105 scale and horizontal placement; original PNGs are untouched.
Her feet meet the existing collider bottom at y=15 in the full idle loop.

`tools/tests/check_red_idle_grounding.gd` checks all eight sole anchors and
transitions to/from attack, and captures each pose in the actual Stage 1.

## New death integration

Source: `red_death_frames_codex.zip`, root files `death_00.png`–`death_07.png`.
Import with `tools/import_red_death.py`; every 512x512 RGBA PNG is copied byte
for byte into `assets/game_assets/red_gothic_replacements/death/` and hashed.
The original six-frame rejected set and legacy drafts remain available.

The animation progresses from stagger to kneeling and collapse. Frames 05–07
are identical in the supplied archive and intentionally hold the final pose.
The full eight-frame clip plays once at 8fps (one second total). The zero-HP
handler now uses the [death presentation](death_presentation.md): frozen world,
camera focus, collapse, held pose and fog transition into Game Over.

Display scale remains 0.095 throughout. `DEATH_FOOT_LINES` stores reviewed
boot/cape/body ground contacts per frame, keeping the collapse grounded at
the existing collider bottom. No crop, horizontal recentering or per-frame
resizing is performed. The interpolation reset still prevents size flashes.

Game Over reuses `death_07.png` for its defeated Red, with the existing forest,
guardian silhouette, sword and UI. Its larger presentation scale is 0.21.

Verification: all eight imported PNGs match archive bytes; 25 combat/death
checks and 58 presentation checks passed (83 total). The checks exercise
zero HP, action locking, the non-looping eight-frame clip, Game Over, Retry,
Return to Title and Continue. All eight collapse poses and the updated Game
Over screen were also captured and reviewed at the native viewport size.

## Basic attack and Crescent update — 11 October 2026

Sources: `red_basic_attack_frames_codex.zip` and
`crescent_slash_fixed_all_for_codex.zip`. Import with
`tools/import_red_combat.py BASIC_ATTACK_ZIP CRESCENT_ZIP`.
All 32 PNGs are copied unchanged with their original filenames; the manifest
records their archive paths, canvas sizes and hashes.

J's three existing combo steps now share the new eight-frame basic swing.
Their cadence, damage, active frames, hitboxes and recovery are retained.
The supplied sword is part of the character art; no second swing overlay is
added. The display uses a fixed 0.105 scale and reviewed sole anchors for each
pose, preserving the existing collision body's ground line.

C now uses the eight new character poses. Its cast VFX is a separate layer,
driven directly by the character frame, including cancellation on damage or
death. The existing release at index 3 creates the travelling projectile.
Speed 420, maximum range 560, damage 20 and terrain/enemy collision are retained.
The old impact sequence remains because the supplied ZIP has no impact set.
Other skills keep their existing character clips.

Crescent canvases vary between 443/445px wide and 443/444px high. Authored ground
anchors correct the later character row's upward shift. Atlas regions hide
disconnected scraps in the top 24 source pixels of character frames 05–08 and
VFX frame 08; transparent margins preserve the original canvas dimensions.
The projectile uses a fixed 0.16 display scale and reviewed vertical travel
anchors, without changing its collider. Transform changes reset interpolation
to avoid oversized flashes when switching to/from idle or legacy impact art.

Remaining source limitations: some Crescent frames meet the canvas edges,
including the bright wave in frame 05 and character soles in early frames.
This integration cannot reconstruct any artwork missing beyond those edges.
Original PNGs are preserved for a future corrected export.

Godot 4.7.2 completed the editor import without script errors. It reported the
existing duplicate UIDs in old spin backup folders. Gameplay tests were not
run for this update. Stop with F8 and run with F5 to try J and C.

### Crescent hitbox alignment

The original 16x18 terrain collider remains, now checking terrain only.
A separate `EnemyHitbox` Area2D checks enemy layer 2 and follows authored arc
bounds for each flight frame. It uses the same 0.16 visual scale, vertical
anchor and facing direction as the sprite, plus 2px of padding per side.
At peak expansion the damage area is approximately 59x49 game pixels.
Sparse particles outside the main arc do not expand the damage area.
The final dissipating frame retains the preceding arc's reach.

Both terrain impact and enemy impact use the same guarded `_impact()` path,
so each projectile still deals damage once and then plays its impact animation.
Speed, travel range and damage remain unchanged. To tune this, edit
`ARC_BOUNDS` or `hitbox_padding` in `scripts/crescent_projectile.gd`.
