# Crimson petal runtime review

Date: 2026-10-14. Tested the actual Stage 1 scene with Godot 4.7.2 and its OpenGL Compatibility renderer on the NVIDIA GPU. These are controlled runtime captures, not a full manual playthrough. The test uses an isolated save path, fixed player positions and frozen enemy movement, plus a moving-camera sample along the Gate approach. Existing scenery, lighting, HUD and petal code render normally. The real opening arrival controller runs without being replaced.

This records the earlier six-petal baseline. The later approved nine-petal baseline with wind clusters is documented in [crimson_petals_natural_review.md](crimson_petals_natural_review.md); the current runtime test writes its newer captures to `previews/petal_natural_review/`.

## Results

The final run passed 26 checks. The renderer log contains no script or shader errors after the foreground shader repair.

| Location / state | Small petals in view during sample | Average |
|---|---:|---:|
| Quiet entrance | 5-6 | 5.7 |
| Broken Chapel | 5-8 | 7.1 |
| Quiet Gate approach, after traversal | 5-9 | 7.2 |
| Creek Wolf nearby / combat suppression | 0-1 | 0.7 |
| Root Cellar | 0 | 0 |

Counts include active background and midground sprites inside the camera view with alpha at least 0.05. They exclude large foreground petals and do not measure whether terrain covers an individual sprite. Samples last three seconds after settling. Random shedding can temporarily exceed the ambient target; the traversal sample reached ten small petals during a local burst.

Confirmed behavior:

- Petals are visible and moving during the paused in-engine opening arrival.
- The arrival restores ordinary gameplay, with petals continuing afterward.
- Small petals fall over time and remain in world space when the camera moves.
- Combat proximity suppresses spawning and reduces opacity.
- Root Cellar does not add ambient petals.
- Ordinary pause hides petals and freezes their motion; unpausing resumes them.
- The bounded pool stays at 26 sprites.

## Runtime rendering defect fixed

The first run discovered that `crimson_petal_soft.gdshader` referenced Godot's `TEXTURE` built-in directly inside a helper function. The real renderer could not compile that function, even though an editor import had passed. The helper now receives the texture sampler as an argument from `fragment()`. No petal source PNG or density setting was changed during this review.

Shader backup: `.godot/local_backups/petal-shader-20261014-162359/`.
Final log: `.godot/petal_runtime_retest.log`.
Detailed measurements: `previews/petal_review/runtime_results.json`.

## Visual review

The current amount reads as quiet drifting atmosphere. Red, the shrine, platform edges and UI remain clear in the inspected captures. Petals are still small and blend into the crimson vegetation, so visible presence is subtler than the numerical count suggests. If a stronger visual presence is desired, review slightly larger midground petals or occasional gust clusters before another global density increase.

- [Opening arrival motion preview](previews/petal_review/opening_arrival.gif)
- [Chapel motion preview](previews/petal_review/chapel_petals.gif)
- [Entrance screenshot](previews/petal_review/entrance_with_petals.png)
- [Chapel screenshot](previews/petal_review/chapel_with_petals.png)
- [Gate approach screenshot](previews/petal_review/gate_approach_with_petals.png)
- [Combat suppression screenshot](previews/petal_review/creek_combat_with_petals.png)
- [Cellar screenshot](previews/petal_review/root_cellar_with_petals.png)

Each still also has a corresponding `_without_petals.png` for comparison. Raw motion frames are stored in `.godot/petal_review_raw_frames/` after encoding. GIF timings are approximately eight seconds for arrival and four seconds for Chapel.

## Reproduce

Run with the real renderer, not `--headless`, to compile shaders and capture images:

```text
Godot.exe --path . --script res://tools/tests/test_crimson_petals.gd --resolution 960x540 --log-file .godot/petal_runtime_retest.log -- --presentation-test
```

This writes only a dedicated test save, runtime captures and results. It does not change the player's normal journey save. Motion frames are regenerated in the preview folder on each run.
