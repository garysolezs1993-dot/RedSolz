# Cellar lift approach cleanup

## Layout

- Replaced the six vertically stacked recovery shelves at x=5510 with two
  staggered 240 px wide landings: (5480,770) and (5630,680).
- Retained the catch floor at y=860, lower bridge floor at y=590 and broad
  existing lift exit/main floor at y=500.
- Each recovery rise is 90 px and uses Red's existing normal double jump.
  No dash or attack is required.
- The cellar lift remains the direct route from y=740 to y=500 when unlocked.
  The locked-lift recovery option and western cellar return remain available.

[Before](previews/lift_approach_before.png) · [After](previews/lift_approach_after.png)

Stage1Layout exposes `lift_approach_cleanup_enabled` for original/cleaned review
before the scene starts. Camp and cellar cleanup options remain independent.

## Tests

- `tools/tests/test_lift_approach_cleanup.gd`: **38 checks, 0 failures**, using
  the actual OpenGL renderer and player physics. Includes before/after captures,
  exact collider landings, the locked lift, both double-jump recovery routes,
  a deliberate surface drop, the western cellar exit, unlock and lift ride,
  and stepping from the lift onto the main floor.
- `tools/tests/test_stage1_routes.gd`: **92 checks, 0 failures**, headless route
  regression. Includes all three seals, six petals, lift, optional routes and
  quiet Moon Gate descent. Decorative petal shaders are disabled in this
  existing headless fixture; the focused rendered test retains the actual art.
- These route fixtures remove enemies and protect Red from damage to isolate
  traversal. This is not a combat balance test.
- The shared jump helper now supplies a second jump for rises beyond 58 px
  below the surface. Its initial 45 px threshold overshot two unrelated low
  burial steps; correcting the helper required no map change there.
- No script errors in the final runs. Existing Camera2D interpolation warnings
  remain. `git diff --check` passes.

Logs:
`.godot/lift_approach_test.log` and `.godot/lift_cleanup_stage1_routes.log`.

## Backup

Pre-change scripts and route fixture:
`.godot/local_backups/lift-approach-cleanup-20261016-231722/`.

This pass changes the lift approach only. Other pending camp/cellar and teaching
guide edits remain intact. Nothing has been pushed to GitHub by this pass.
