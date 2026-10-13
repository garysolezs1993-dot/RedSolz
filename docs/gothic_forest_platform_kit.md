# Gothic forest platform kit - Stage 1

The entrance treatment was approved and is now applied across the full
11,200 px Stage 1, including the lower safety floors, return stairs, moving
lifts and crumbling shelves. The layout, collisions, tutorials, encounters,
checkpoints, rewards and Moon Gate route retain their existing behavior.

## Area dressing

| Area | Treatment |
| --- | --- |
| Entrance / first clearing | Approved mossy stone, sparse plants and bare roots |
| Camp | Wood braces/posts, broken stone and small rock groups |
| Chapel | Thin stone shelves, moss and remnants of carved supports |
| Creek | Moss cascades, quiet stone and bare roots |
| Hollow Oak | Root-bound shelves and hanging branches |
| Root Cellar | Darker stone, crimson vines and compact ledges |
| Burial ground | Restrained stone and roots around the existing graves |
| Heartwood | Stronger roots and crimson accents around the existing arena |
| Moon Gate approach | Cleaner moss surfaces with sparse crimson framing |

193 visual helpers compose 22 reusable textures. All 44 supplied assets are
organized and preserved; pieces unsuitable for the existing flat walkable
surfaces are available for later use rather than forced into the level.

## Rendered previews

Normal-time renders use the actual Stage 1 camera and gameplay sprites.

- [Entrance before](previews/platform_entrance_before.png) /
  [entrance after](previews/platform_entrance_after.png)
- [Camp](previews/platform_camp.png)
- [Broken Chapel](previews/platform_chapel.png)
- [Winding Creek](previews/platform_creek.png)
- [Oak trail](previews/platform_oak_trail.png) /
  [Oak canopy](previews/platform_oak_canopy.png)
- [Root Cellar](previews/platform_cellar.png)
- [Burial ground](previews/platform_burial.png)
- [Heartwood](previews/platform_heartwood.png)
- [Quiet approach](previews/platform_quiet_approach.png) /
  [Moon Gate](previews/platform_moon_gate.png)
- [Lower return steps](previews/platform_return_steps.png)

## Imported kit

44 source PNGs are copied byte-for-byte under
`assets/environment/gothic_forest/`. `manifest.json` maps every original
filename to its descriptive name and category.

| Category | Count | Intended use |
| --- | ---: | --- |
| platform_large | 5 | Connected ground and broader platforms |
| platform_medium | 13 | General ledges and ground combinations |
| platform_small | 8 | Stepping stones and short islands |
| platform_slope | 2 | Decorative irregular/sloped forms |
| platform_edge | 2 | Exposed edge/buttress dressing |
| platform_pair | 1 | Asset 28, containing two separate ledges; unused in single-platform compositions |
| root_hanging | 3 | Non-collision roots and vines |
| root_cluster | 1 | Ground stump/root accent |
| rock_cluster | 3 | Background rocks |
| foliage | 2 | Sparse crimson vegetation |
| wood_support | 2 | Broken/carved supports |
| environment_prop | 2 | Fallen trunks/logs |

The preview sheet is not a gameplay texture. All individual files have real
alpha and clear margins on all four edges. Visual inspection found no clipped
outer silhouettes. Asset 28 is intentionally kept separate because its two
disconnected ledges are unsuitable as a single collider's artwork.

## Implementation and tuning

- `scripts/forest_platform_art.gd` is a visual-only composition helper.
  `ART_SCALE = .6` sets the uniform scale of long-ground pieces.
  `KIT` contact rows align the stone/moss tops to the unchanged collision line.
  `POOLS` selects combinations by area; `_add_dressing()` places sparse props.
- Short ledges choose among source widths close to that scale and fit uniformly.
  Deterministic variants and flips keep their appearance stable between retries.
  Closely stacked lower steps use thin pieces; cellar art has a darker tint.
- Whole PNG canvases, alpha and proportions are retained. No atlas cropping,
  source edits or non-uniform scaling are used. Nearest filtering stays enabled.
- The fine moss lip follows the original collider top. Platform art sits behind
  Red; rocks, roots and foliage sit behind the platform art and add no collision.
- `scripts/stage1_layout.gd`: `platform_art_enabled` toggles the kit for Stage 1.
  `_apply_platform_art()` splits only visual composition at area boundaries;
  every original rectangle/body stays intact. Legacy visuals remain available
  when the toggle is off.
- `scripts/forest_platform.gd`: `use_gothic_art` and `art_area_style` opt moving
  and crumbling platforms into the kit. Stage 1 supplies these settings.
  Their travel, sensors, warning shake, collapse and respawn are unchanged.
  The default remains the original terrain helper for other uses.

## Backups

Original current layout, main scene, terrain visual and platform scripts:

`C:\Users\Public\Godot Project\yuki-solz-platform-sample-backup-20261011-162332`

Approved sample helper/layout/platform scripts before the full rollout:

`C:\Users\Public\Godot Project\yuki-solz-platform-rollout-backup-20261011`

These backups include the existing uncommitted work at their respective stages.

## Verification

Tests use `--presentation-test` to isolate the player's normal save/settings.

| Test | Passing checks |
| --- | ---: |
| Platform art / identical authored terrain | 36 |
| Stage 1 chapter and main route to actual boss transition | 54 |
| Optional routes and all six petals | 37 |
| Moon Lantern interactions and retry | 69 |
| Presentation, moving/crumbling platforms and death/retry | 59 |
| Ground combo | 109 |
| Air combo | 232 |
| Downward Slash | 177 |
| **Total** | **773** |

The platform test compares the real scene with the treatment off/on: all
terrain origins, rectangle shapes, layers/masks, one-way flags and margins
are identical. It inspects every visual helper for added collisions, cropped
regions, excessive/non-uniform scale and mismatched top lines. It also exercises
ordinary walking/jumping, dash, Rising Slash into aerial combat, Downward Slash
landing/recovery and the lower safety route.

The chapter test traverses the main route using ordinary movement/jumping,
checks real wolf attacks/stagger/leashes and verifies checkpoint saving, retry
and the Moon Gate transition. Route tests exercise the retained optional climbs,
cellar entry/return and reward ledges.

All 44 local PNGs match the archive byte-for-byte, with real alpha and at least
16 clear pixels on each outer edge. Eleven area captures were reviewed for
surface readability, complete pieces and separation from Red/lanterns.

Tests: `tools/tests/test_platform_art_sample.gd` (now full-stage coverage) and
existing gameplay suites. Captures: `tools/capture_platform_rollout.gd`.
Logs are in `.godot/platform_kit_review/`; persistent previews are in
`docs/previews/`. Existing Camera2D interpolation and test-exit resource
warnings remain; no script or gameplay test failures occurred.
