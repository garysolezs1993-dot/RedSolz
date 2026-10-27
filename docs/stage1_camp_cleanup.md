# Stage 1 camp cleanup sample

First section only: Abandoned Camp, approximately x=2200–2800.

## Comparison

- [Camp before](previews/camp_cleanup_camp_before.png)
- [Camp after](previews/camp_cleanup_camp_after.png)
- [Recovery route before](previews/camp_cleanup_recovery_before.png)
- [Recovery route after](previews/camp_cleanup_recovery_after.png)

The two overhead platforms at (2380,452) and (2560,405) obscured the tent and
had no objective or collectible. They are removed in the cleaned version.
The western shelves leading to the petal at (1800,344) remain.

The six stacked recovery ledges at x=2650 become three 180 px wide ledges at
y=758,654,550. The existing lower floors remain available. These vertical
spacings use the existing double jump; the main route remains a continuous
walkable floor at y=500. No collision/controller rules, enemies, hazards,
checkpoint positions, seals, rewards or source artwork are changed.

The local ledge count falls from eight to three. The rest of Stage 1 and
Stage 2 retain their current layouts.

## Review control and backup

Stage1Layout exposes `camp_cleanup_enabled`, default true. Disable it before
starting a scene to build the original camp layout for comparison.

Original layout scripts are backed up in:
`.godot/local_backups/stage1-camp-cleanup-20261015-223525/`.

Both variants were rendered at 960×540 with the gameplay camera at 1.35.
Ambient petals were hidden only in the capture process to make geometry
comparison clearer. The actual stage retains its petals.
Captures completed without script errors; this is not a full traversal playtest.

Changes are local and have not been pushed to GitHub.
