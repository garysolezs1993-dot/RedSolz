# Root Cellar cleanup sample

## Before and after

| View | Original | Cleaned |
| --- | --- | --- |
| Western entrance | [Before](previews/cellar_cleanup_entry_before.png) | [After](previews/cellar_cleanup_entry_after.png) |
| Combat floor | [Before](previews/cellar_cleanup_combat_before.png) | [After](previews/cellar_cleanup_combat_after.png) |
| Seal and lift | [Before](previews/cellar_cleanup_lift_before.png) | [After](previews/cellar_cleanup_lift_after.png) |

## Changes

- Removed the four overlapping vertical return shelves at x=3510.
- Retained the three shared entry/return shelves: (3380,550), (3540,610),
  (3700,670). Each is 220–240 px wide; height changes between these shelves
  are 60 px. Returning from the combat floor begins with a 70 px rise.
- The cellar's local shelf count drops from eleven to seven.
- Cellar surfaces use the existing thin quiet/crimson pieces, with extra
  hanging braces/roots omitted. Collider dimensions and walkable top alignment
  on retained surfaces stay unchanged.
- Removed the old Hollow Oak, Root Cellar and Rootbound Shortcut world labels.
  The HUD region name and actual lift interaction remain.
- Softened the dark room backing at its edges with a generated radial gradient.

The two combat escape shelves, guards, broad floor, optional hazard alcoves,
moon petal, Seal 2, and lift remain. The surface route and Chapel platforms above
the entrance retain their geometry. No source PNGs were changed.

## Review and recovery

`Stage1Layout.cellar_cleanup_enabled` enables this version and can be disabled
before starting the scene to compare the original. It is independent of the
previous camp cleanup toggle. The existing route fixture now targets the shared
stairs when this option is enabled.

Original scripts are backed up at
`.godot/local_backups/stage1-cellar-cleanup-20261015-224220/`.

The actual scene was rendered in both configurations at 960×540 and zoom 1.35,
without script errors. Petals were hidden only during preview capture.
This pass has not had a full traversal/combat playtest. Changes remain local.
