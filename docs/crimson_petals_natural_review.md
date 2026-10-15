# Fuller natural petal drift

Implemented 2026-10-14 after approval of fuller outdoor coverage, larger midground petals, wind-carried clusters and additional coverage in open stretches.

## Changes

- Ambient target increased from six to nine small petals, with a target of ten at Broken Chapel and the Moon Gate approach. Spawns remain gradual and irregular.
- Midground scale increased from 0.5-0.85 to 0.65-1.0, with opacity increased from 0.44 to 0.48.
- Quiet outdoor scenes receive occasional clusters of two to four petals from an upwind edge. Wind builds and settles over 1.5-2.7 seconds, with irregular 8-15 second gaps between events.
- New canopy pockets cover the approach to Chapel and the open climb beyond Creek; ambient drift continues to cover spaces between local scenery sources.
- Creek and Gate winds favor gentle rightward motion. Other outdoor areas vary direction. Cluster origins stay in world space.
- Existing combat, indoor and pause suppression remains. Foreground stays limited to two rare edge petals; it receives only a small share of extra wind.
- All source PNGs remain untouched. The sprite pool expands from 26 to 34 reusable nodes to support fuller coverage and off-screen lifetimes.

Inspector tuning is on Main / CrimsonPetals, including Ambient Outdoor Drift and Occasional Wind Clusters. These controls make the density, frequency and wind strength easy to adjust independently.

Backup: `.godot/local_backups/petals-natural-gusts-20261014-163445/`.

## Validation

The actual Stage 1 scene was rendered with Godot 4.7.2 OpenGL Compatibility. The updated runtime test passed 35 checks with zero failures and no script or shader errors. The normal journey save was preserved; the test used its own save path.

Coverage included real opening arrival, quiet entrance, Chapel, an open outdoor stretch, moving camera along Gate approach, nearby Creek Wolf suppression, Root Cellar, ordinary pause/resume, world-space motion, gust start/finish and the fixed reusable pool. A scheduled Chapel gust was deliberately triggered to capture its motion.

The measurements and captures are in `previews/petal_natural_review/`, and the log is `.godot/petal_natural_runtime.log`. This is a controlled runtime review, not a full manual playthrough. Player positions and enemy movement are controlled; nearby enemy detection remains active.

The ambient target is a baseline. Local shedding and temporary wind clusters may briefly raise the visible amount above it. Small-petal counts include active background/midground sprites in the camera view with alpha at least 0.05; scenery may cover individual petals.

## Previews

- [Opening arrival](previews/petal_natural_review/opening_arrival.gif)
- [Chapel with wind cluster](previews/petal_natural_review/chapel_petals.gif)
- [Entrance](previews/petal_natural_review/entrance_with_petals.png)
- [Open outdoor stretch](previews/petal_natural_review/open_stretch_with_petals.png)
- [Gate approach](previews/petal_natural_review/gate_approach_with_petals.png)

Earlier previews remain in `previews/petal_review/` for comparison. Raw frames from this pass are stored under `.godot/petal_natural_frames/` after encoding.
