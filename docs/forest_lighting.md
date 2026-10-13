# Forest lighting

Implemented 11 October 2026, using existing artwork and Godot 2D lights.

The current [seal encounter redesign](stage1_seal_encounters.md) builds on the 10,000 px forest hub with an upper ruins route. Selective lighting covers all 143 platform helpers, including the canopy and sanctuary, with regional shading following the Oak, Cellar, Heartwood and Moon Gate. Source artwork and brightness settings are unchanged.

## Current Stage 1 pass: selective lighting

The second pass uses separate background and platform shaders. Stage 1 no
longer creates a global darkness CanvasModulate. Red, enemies, player VFX,
projectiles and Moon Lantern sprites retain their normal artwork colors and
local lights. Stage 2 keeps the earlier ambient treatment described below.

### Inspected layer map

| Element | Actual nodes/resources | Treatment |
| --- | --- | --- |
| Far background | `Main/ForestEnvironment/FarParallax/MoonlitRidge`, Z -24 | Independent brightness and cool shadow tint |
| Mid forest | `Main/ForestEnvironment/MidParallax/RedwoodMist`, Z -10 | Independent brightness; existing 0.55 alpha retained |
| Moon/castle | Painted into the far PNG, not separate nodes | Soft UV mask in the far shader; no PNG edits |
| Foreground canopy | `ForegroundParallax/ThornedCanopy`, Z 5 | Independent brightness; existing 0.34 alpha retained |
| Platforms | `Stage1Layout/*/GothicPlatformArt`, including moving/crumbling platforms | Bright top band, darker underside; collision unchanged |
| Red | `Main/Player/Visual` | No darkening material or modulation |
| Enemies | `Stage1Layout/*Wolf*/Visual` and Heartwood actors | No background grading; existing faint actor lights |
| VFX | Player AttackEffect, VFXAnchor children, Dash effects; Crescent ProjectileVisual | Excluded from grading |
| Moon Lanterns | `Stage1Layout/Promise_*/LanternVisual`, CrimsonGlow and WarmCore | Artwork and activation/idle lighting preserved |
| UI | `Main/UI` CanvasLayer and separate lesson/session layers | Above the vignette; unchanged |

### Inspector controls

Open `scenes/main.tscn`, select the **ForestEnvironment** instance and expand
**Stage 1 Selective Lighting**. Save scene overrides to retain adjustments.
The same controls update during play through the Remote Inspector.
Switching `selective_lighting_enabled` itself requires reloading the scene.

| Property | First-pass value | Purpose |
| --- | ---: | --- |
| `far_background_brightness` | 0.85 | Conservative 15% background reduction |
| `mid_background_brightness` | 0.90 | Conservative 10% mid-layer reduction |
| `moon_castle_brightness` | 0.80 | Slight extra softening inside the landmark region |
| `foreground_brightness` | 0.85 | Quiet foreground framing |
| `platform_brightness` | 0.94 | Only mild darkening of top surfaces |
| `platform_underside_brightness` | 0.72 | Greater depth below walkable surfaces |
| `scenery_brightness` | 0.82 | Root/ruin scenery behind the main route |
| `vignette_strength` | 0.045 | At most 4.5% darkness at the outer fringe; zero disables it |

`selective_shadow_tint` retains the existing forest's blue/purple night palette.
`regional_background_shading` preserves the earlier cellar/oak/gate mood,
applied only to parallax layers. Brightness values multiply this tone, rather
than describing total brightness relative to raw PNGs. The central 75% of
the viewport is clear of the vignette; UI is drawn above it.

The far shader's soft mask is anchored to the moon/castle region of the
existing 1672x941 PNG. Replacing that background later may require updating
the mask coordinates in `shaders/forest_background_grade.gdshader`.

### Before / after captures

Fixed frame/pose captures use the actual 960x540 renderer and 1.35 camera.

| Area | Before | After |
| --- | --- | --- |
| Entrance | [Before](previews/selective_entrance_before.png) | [After](previews/selective_entrance_after.png) |
| Dormant lantern | [Before](previews/selective_lantern_dormant_before.png) | [After](previews/selective_lantern_dormant_after.png) |
| Active lantern | [Before](previews/selective_lantern_active_before.png) | [After](previews/selective_lantern_active_after.png) |
| Root Cellar | [Before](previews/selective_cellar_before.png) | [After](previews/selective_cellar_after.png) |
| Heartwood | [Before](previews/selective_heartwood_before.png) | [After](previews/selective_heartwood_after.png) |
| Moon Gate | [Before](previews/selective_moon_gate_before.png) | [After](previews/selective_moon_gate_after.png) |

Backup made before any edits:
`C:/Users/Public/Godot Project/yuki-solz-before-selective-lighting-20261011-180206`.
It includes source artwork, uncommitted files and Git history, excluding only
the regenerable `.godot` cache. All 1,304 source PNGs match this backup by SHA256.

### Validation of selective pass

Nine suites completed successfully: 2,361 checks, zero failures.

| Suite | Checks |
| --- | ---: |
| Selective lighting, exclusions and Inspector updates | 1,588 |
| Platform art and unchanged terrain collision | 36 |
| Moon Lantern interactions and save/retry | 69 |
| Menus, audio, death, checkpoints and stage transition | 59 |
| Ground combo | 109 |
| Air combo | 232 |
| Downward Slash | 177 |
| Full Stage 1 chapter / ordinary main-route traversal | 54 |
| Optional exploration routes and rewards | 37 |

All runs used `--presentation-test` to isolate gameplay saves. Six matching
before/after render pairs were reviewed; rendering emitted no new script or
shader errors. Existing Camera2D interpolation and legacy asset UID warnings
remain. The tests check behavior and rendering configuration; visual review
of the fixed-pose captures establishes the appearance of this first pass.

## Earlier ambient pass (retained in Stage 2)

## Visual treatment

- Cooler, darker ambient light, plus a restrained tint on the three parallax
  layers to reduce bright foliage and moon glare.
- Three decorative lamps across Stage 1: entrance, camp and chapel. The three
  Moon Lantern checkpoints now provide the main local pools of light.
- Ambient light gradually darkens through the oak and optional Root Cellar.
  Heartwood retains more combat visibility, and the gate approach receives
  softer crimson moonlight. Region changes blend rather than snap.
- Tiny ambient motes are dimmer.
- Red and enemy visuals receive faint actor-only lights. These do not flood
  nearby terrain with light.
- Platform contact lines use a restrained unshaded material so the darkest
  areas still show their walkable edges.
- The shared forest background treatment applies to Stage 2, which uses a
  consistent ambient value instead of Stage 1's regional changes.

## Moon Lanterns

Each checkpoint creates a crimson PointLight2D and a smaller warm center,
positioned at the lantern chamber. A dormant lantern has only a faint ember.
Once Red's interaction reaches the existing ignition frame, the illumination
builds and pulses with the lantern activation animation. The pulse settles
into a gentle flicker. Previously activated checkpoints restore their lit
state immediately when the scene loads.

Light Z ranges exclude the distant parallax and foreground canopy. World
terrain and characters receive the illumination; the HUD remains on its
existing canvas layer. Shadow occluders were not introduced.

Checkpoint input, animation timing, healing, saving, collisions, controls,
enemy attacks and camera zoom are unchanged by this lighting treatment.

## Tuning

- `scripts/forest_environment.gd`: exported `ambient_color`, `background_tint`,
  `LANTERN_X`, and `_ambient_at()` for regional darkness.
- `scripts/forest_checkpoint.gd`: exported `active_glow_energy` (0.38),
  `active_core_energy` (0.25), and `glow_size` (1.0).
- `scripts/forest_platform_art.gd`: `WalkableMossLip` color/material.

## Rendered previews

- [Dormant lantern](previews/lighting_lantern_dormant.png)
- [Active lantern](previews/lighting_lantern_active.png)
- [Root Cellar](previews/lighting_cellar.png)
- [Heartwood](previews/lighting_heartwood.png)
- [Moon Gate](previews/lighting_moon_gate.png)

These earlier preview captures used isolated presentation saves and the actual
Godot renderer. Gameplay suites were not run for the initial ambient pass;
the selective pass above adds dedicated checks and gameplay regression runs.
The existing Camera2D physics-interpolation warning is still emitted.
