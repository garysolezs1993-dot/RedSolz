# Stage 1 hazard artwork

Integrated `stage1_hazard_assets_for_codex.zip` on 2026-10-14.

## Safety and scope

Backup: `.godot/local_backups/stage1-hazards-20261014-210508/` (previous hazard controller and scenes).

All six original PNGs are copied unchanged into `assets/environment/stage1_hazards/`. Independent inspection confirms RGBA transparency, transparent borders, and no occupied canvas-edge pixels. Source/imported PNG hashes match. No map, enemy, damage, collision, or hazard timing changes were made.

`scripts/forest_hazard.gd` creates a visual-only `forest_hazard_art.gd` child. Disable **Use Hazard Art** in the hazard Inspector to recover its original procedural visuals. Existing width, height, damage, warning/rest/active times, fall distance, and trigger range remain the tuning controls.

## Mapping

| Hazard | Artwork |
| --- | --- |
| Ground/retractable spikes, width <= 40 | Repeated `ground_spike_single.png`, one per original collision triangle |
| Larger spike groups | `ground_spikes_cluster.png` |
| Thorn vines | `thorn_vines.png` |
| Falling branches | `falling_branch.png` |
| Cursed roots, safe/rest or warning | `cursed_roots_rest.png` |
| Cursed roots, emerging/active/retracting | `cursed_roots_active.png` |

Art retains complete PNG canvases with nearest filtering. Godot offsets use the main visible silhouette, excluding very faint fringe pixels from the contact baseline. Ground hazard sprites fit the existing width/height; this can use different horizontal and vertical scales. Their illustrations approximate the existing damage zones rather than creating pixel-perfect collision. Branches keep uniform scale; fine twigs are decorative beyond the solid trunk collision band.

Both root states use one shared scale and pivot. Active art follows the same emergence/retraction strength as the collision polygons, while safe art fades inversely. The wider resting base is decoration and does not deal damage. Branch art follows the existing shake/fall offset, fades during recovery, and resets with the existing state machine.

Original warning lines and exclamation marks remain drawn by the controller above the art. Hazards remain behind Red.

## Verification

- Rendered hazard test: **109 checks, 0 failures**. All eight Stage 1 hazards retain the original polygons, collision masks, state damage permissions, and collision transforms. Checks include actual Red damage calls, root emergence/shared pivots, and branch fall/recovery/reset.
- Rendered Stage 1 route regression: **93 checks, 0 failures**. Ordinary movement/jumps, optional routes/rewards, seal progression, lift and Moon Gate approach remain accessible.
- Both final logs contain no script/shader errors. Tests use isolated presentation save paths.
- Independent alpha/bounds/hash audit: [JSON](previews/stage1_hazards/independent_validation.json).

Gameplay captures at camera zoom 1.35:

- [Cellar resting roots](previews/stage1_hazards/cellar_rest.png)
- [Cellar active roots](previews/stage1_hazards/cellar_active.png)
- [Creek thorns and branch](previews/stage1_hazards/creek_warning.png)
- [Upper ruins spikes and roots](previews/stage1_hazards/upper_ruins.png)
