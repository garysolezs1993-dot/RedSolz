# Bridge and path presentation cleanup

26 October 2026.

The user clarified that Red was not falling through the route: the bridge looked strange. This pass therefore changes presentation only.

## Cause

Two overlapping decorative bridge images showed curved decks at different heights behind a flat walkable crossing. One source image also has visibly coarse, resampled details. Nearest filtering at fractional art/camera scales emphasized jagged edges. The existing collision belongs to the flat terrain, not those painted curves.

## Changes

- Removed the two overlapping curved-deck sprites from the bridge presentation.
- Kept the existing flat crossing (`RootedLedge_280/281`, x=5380–5860, top y=424) and its artwork.
- Added two small support pillars with their tops at the standing line, plus a restrained back rope and ties. These are decorative only.
- Changed the shared terrain kit and Stage 1 environment sprites to linear filtering. Characters, HUD and VFX retain their existing filtering.
- Kept the finished terrain artwork on upper ledges 610/611 instead of replacing it with the coarse v2 ruin surfaces.
- Preserved all source PNGs, collision, routes, player physics and combat.

Backup: `.godot/local_backups/bridge-presentation-20261026/`.

## Review

Captured and visually inspected the actual Stage 1 scene at 960 × 540, gameplay zoom 1.35:

- [Before](previews/bridge_cleanup_before.png)
- [After](previews/bridge_cleanup_after.png)

The capture uses isolated presentation saves and freezes actors for a consistent view. Godot logged no script errors; it logged the existing Camera2D physics-interpolation process warning. No gameplay tests or full traversal run were performed for this presentation pass.

Smoother sampling reduces jagged scaling, but cannot create detail absent from a source image. A future bespoke bridge replacement should have a flat, clearly marked standing edge matching the crossing, consistent detail with the terrain kit and transparent padding.
