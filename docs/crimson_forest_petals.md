# Crimson petal shedding in Stage 1

The four original PNGs from crimson_petal_pack_for_codex.zip remain unchanged. They are 64 x 64 with transparent padding; hashes and visible bounds are in crimson_petal_assets_manifest.json.

## Natural shedding

The earlier uniformly scattered drifting field is replaced by small, irregular shedding events. Fixed canopy pockets sit along the entrance, camp, Broken Chapel, Hollow Oak, creek, upper ruins, and quiet Moon Gate descent. Additional source points come from selected stable mossy ledge edges and the actual crimson bushes, sprigs, vines, and branches on terrain artwork.

Outdoor traversal maintains a baseline target of nine small petals in view, with ten around Broken Chapel and the Moon Gate approach. These enter gradually from the upper part of the camera and remain in world space, so they fall through and between platforms instead of looking attached to the screen. Existing local shedding contributes to the same visible target, preventing the ambient pass from doubling the density during a burst. The Root Cellar disables this baseline. Moving quickly can temporarily reduce the visible count as new petals enter the view.

Moving/crumbling platforms and deep cellar floors are excluded from these source points. Terrain geometry, platforms, collision and gameplay behavior are unchanged.

Only nearby sources can emit. Each event releases 1-3 petals with 0.1-0.28 seconds between them, followed by a randomized 2-4.5 second pause scaled by region/combat activity. The viewport is no longer filled with petals on startup. A private RNG keeps this decorative variation separate from enemy/gameplay randomness.

Petals shed by scenery remain in world space as the camera moves. They fall with varied initial velocities, gradual acceleration, terminal speed, tumbling, flutter and occasional smoothly changing wind gusts. Some pass behind the platform art; others skim in front of its edges while remaining behind Red. They have no collision and cannot be collected.

Occasional wind clusters add two to four small petals at irregular 8-15 second intervals during quiet outdoor scenes. A 1.5-2.7 second wind envelope smoothly picks up and settles, affecting existing petals as the new cluster enters from an upwind edge. Creek and Gate winds favor rightward travel; other outdoor pockets vary direction. Each cluster has a fixed world origin. New clusters stop during combat and in the cellar. Combined visible drift is checked before each cluster emission; the existing pool caps allocation, and foreground sprites receive only a mild fraction of the extra wind. Additional canopy sources cover the Chapel approach and open climb beyond the Creek.

## Depth and readability

The bounded sprite pool contains eighteen background, fourteen midground and at most two foreground petals. Sprites are reused. Midground petals now use 0.65-1.0 scale (previously 0.5-0.85) and 0.48 opacity, making tumbling more visible without enlarging the foreground. Ambient spawns split evenly between the small-petal layers. Foreground petals retain their soft shader, edge-only visibility, parallax, low opacity, and exclusion around Red and the upper HUD band. Foreground timing varies around its configured interval.

Chapel/canopy and gate approach regions have slightly more atmosphere. The cellar suppresses the effect. Nearby combat reduces opacity, lengthens shedding pauses and limits new bursts to one petal; new foreground spawns stop. Ordinary pauses, other paused cinematics, death and transitions hide the effect and stop motion.

The in-engine opening arrival after the illustrated cutscene is an explicit exception: petals drift and shed while Red enters, stops and speaks, even though gameplay is paused. They use the arrival camera and continue seamlessly when the normal gameplay camera returns. Nearby enemies do not suppress the atmosphere during this protected shot. Skipping the arrival restores ordinary pause and combat rules through the existing opening_arrival_active flag.

## Tuning

Select Main / CrimsonPetals. Controls include enabled, pool sizes, ambient_visible_target (default 9), ambient_spawn_interval (default 0.35-0.75 seconds), per-layer opacity, foreground softness, combat opacity, drift speed, foreground spawn interval, shedding_interval (default 2-4.5 seconds), and shedding_burst_max (default 3). The Occasional Wind Clusters group exposes gusts_enabled, gust_interval, gust_duration, gust_speed (default 36 world pixels/second of peak added wind) and gust_burst_max (default 4). Pool capacity changes require restarting the scene. Other values can be tuned during play.

Stage 2, menu screens, collectible Moon Petals and Wisp trails are unchanged.

Original integration backup: .godot/local_backups/crimson-petals-20261014-111120/
Shedding revision backup: .godot/local_backups/petal-shedding-20261014-112916/
Map-wide ambient revision backup: .godot/local_backups/stage1-petals-and-art-brief-20261014-151354/
Denser outdoor revision backup: .godot/local_backups/petal-density-20261014-154322/
Opening arrival revision backup: .godot/local_backups/petals-opening-arrival-20261014-160736/
Fuller natural drift revision backup: .godot/local_backups/petals-natural-gusts-20261014-163445/
Godot editor imports completed for the density and opening-arrival revisions with exit code 0 and no script/parse errors in .godot/petal_density_import.log and .godot/petal_arrival_import.log. The subsequent actual-renderer runtime review passed 26 checks, captured arrival and Chapel motion previews, and repaired the foreground shader's sampler access. Measurements and limitations are recorded in [crimson_petals_runtime_review.md](crimson_petals_runtime_review.md).

The fuller natural drift revision passed 35 actual-renderer checks with no script or shader errors. Its new previews and validation notes are in [crimson_petals_natural_review.md](crimson_petals_natural_review.md).
