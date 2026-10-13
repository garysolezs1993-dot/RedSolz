# White Lily trail: first-route preview

[Watch the Stage 1 preview](previews/lily_trail_first_seal.gif) | [Gameplay screenshot](previews/lily_trail_first_seal.png)

The supplied brief requests one Wisp route for review before a wider rollout. The new lily trail is enabled on the full guidance flight after **Moon Seal 1**. Other guidance flights and the earlier chapel glimpse retain their existing trail. Local shrine hover/activation behaviour stays restrained and the boss intro has no new lily effects yet.

## Assets and placement

All eight `lily_trail_00.png` through `lily_trail_07.png` were extracted unchanged to `assets/game_assets/moon_wisp/lily_trail/`. They are 512x512 PNGs with real alpha transparency and transparent margins on every edge. `lily_trail_asset_manifest.json` records SHA-256 matches against the ZIP. No source images were cropped, resized, recoloured or overwritten.

The clip's flower/front is toward the lower left and its petal sweep extends toward the upper right. Godot uses one fixed whole-clip front anchor `(150,350)` and a diagonal authored direction `(-270,150)`. Mirroring and rotation align that direction with travel, including left, right and vertical movement. There is no per-frame crop or independent scale adjustment.

## Behaviour

- Distance-based emission, with the existing 0.08-second minimum interval as a rate limit.
- Each effect is a separate pooled sprite in world space, outside the moving Wisp hierarchy. Its position and orientation never update after spawning.
- Eight-frame one-shot at 16 FPS for the default 0.5-second lifetime; fades smoothly during the final 0.2 seconds.
- A maximum of 12 lily instances; extra emissions are skipped when the pool is full. Sprites are reused, without allocating a node per emission.
- Full Wisp movement frames remain in use. Lily afterimages replace the older secondary afterimages for this route rather than stacking both sets.
- Idle, stationary move poses, appearance, landmark hover and disappearance do not spawn lilies. Existing lilies complete when the Wisp stops or hides.
- The main Wisp stays brightest; lily opacity defaults to 0.28. The captured flight had four simultaneous lily afterimages, with zero old-trail emissions.
- Stage changes remove the external pools. Empty pools stop processing.

## Inspector controls

Open `scenes/main.tscn`, select **Stage1Layout**, then expand **White Lily Trail - First Seal Preview**. These values are forwarded to the guide and its visual when the stage loads. Restart the stage after changing them.

| Property | Default | Purpose |
| --- | --- | --- |
| `lily_trail_enabled` | true | Use lilies on the first-seal flight; false restores the previous trail |
| `lily_trail_spawn_distance` | 32 px | Minimum distance between instances |
| `lily_trail_lifetime` | 0.5 sec | Total one-shot lifetime |
| `lily_trail_fade_duration` | 0.2 sec | Fade during the end of that lifetime |
| `lily_trail_scale` | 0.085 | Uniform Godot scale for every supplied frame |
| `lily_trail_opacity` | 0.28 | Softness relative to the Wisp core |

The reusable `moon_wisp_visual.gd` also exposes these settings but defaults lily support off. The guide deliberately selects it only for the first-seal cinematic.

## Verification

**1,086 checks passed, zero failures**:

- `tools/tests/test_lily_trail.gd`: 51 checks for source dimensions/alpha/margins, one-shot frames, world-space placement, orientation in four directions, lifetime, fading, stopping, cap and cleanup.
- Existing Moon Wisp trails regression: 163 checks, preserving the older trail setup and verifying the paused guidance route.
- Existing Moon Wisp visual regression: 537 checks for state/asset selection, guidance progression and camera handoff.
- Existing Moon Seal flow regression: 335 checks, including first-route-only lily selection and quiet saved shrine restoration.

Logs: `lily_trail_test.log`, `lily_regression_moon_wisp_trails.log`, `lily_regression_moon_wisp_visual.log`, `lily_regression_moon_seal_flow.log`.

The actual Stage 1 route was rendered with an isolated journey path and muted capture audio, preserving the player's saved journey. `tools/capture_lily_trail.gd` recorded 74 frames at 10 FPS; `lily_trail_capture.log` confirms the camera returned, gameplay unpaused and no lilies remained. The GIF is silent; the game retains normal audio. Editor import completed without script errors. Godot's existing camera interpolation warning remains.

Backup before integration: `.godot/local_backups/lily-trail-20261013-171038/`.

To review in-game, activate the first Moon Seal in a fresh Stage 1 journey. After reviewing this flight, the motif can be extended to other routes or subtle shrine/story use separately.
