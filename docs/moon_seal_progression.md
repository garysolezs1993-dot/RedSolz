# Stage 1: Moon Seals and temporary Wisp guidance

> **Current placements and guidance:** see [Stage 1 hub redesign](stage1_hub_redesign.md).
> The layout below records the earlier linear revision. Seals are now in the
> upper Chapel, lower Root Cellar and lower Side Ruins; wisps indicate routes.

## Roles

- **Moon Lantern:** existing E animation, checkpoint and one-time heal. Lighting lanterns does not unlock the gate.
- **Moon Seal:** three required E interactions, saved independently of checkpoints. No healing or automatic proximity activation.
- **Moon Wisp:** temporary blue-white directional light with a trailing comet shape. No collection/collision behavior and no permanent following.
- **Moon Petal:** six existing optional rewards, unchanged.
- **Moon Gate:** locked at 0/3, 1/3 and 2/3; three progressive runes and awakening at 3/3. E / Up / Enter retain the existing Stage 2 transition once unlocked.

Final art has not been generated or edited. Stone/rune/orb drawings are placeholders.

## Route and placements

Stage 1 expands from 11,200 to **13,000 px**. Existing encounters, Hollow Oak, Root Cellar, burial areas and rewards keep their positions. No wolves were added.

| Object | Position | Purpose |
|---|---|---|
| Seal 1 | (3240, 500) | Quiet discovery after the Camp wolf; introduces the objective and releases the first Wisp |
| Seal 2 | (6780, 356) | Short low branch at the Hollow Oak approach; three ordinary jumps, with the canopy/cellar still optional |
| Seal 3 | (11320, 440) | Low branch above Stillwater after Heartwood; two easy jumps |
| Moon Gate | (12840, 390) | Quiet destination after Stillwater and an optional memorial nook |

Checkpoints remain at x=1100, 6500 and 10600. The final one gives a safe respawn before Stillwater discovery and the gate approach.

The additional space contains low shelves, a reflection pond below the safe path, an optional raised memorial and scenery. Main-route ground remains continuous, with the extended catch floor, recovery steps and map boundaries retained. Advanced combat and Moon Petals are never required.

## Presentation

Near Seal 1: “Three sleeping seals bind the path beneath the crimson moon.”

After E: “Moon Seals awakened: 1/3”, then 2/3 and 3/3. These use the existing temporary toast. At completion, the gate awakening message follows the final progress toast.

The first activated seal releases a Wisp: swirl → pause ahead → travel → pause at a local landmark → fade. Its origin is captured at spawn; moving Red does not pull the Wisp along. Subsequent cues appear at useful section boundaries, after 14 seconds of inactivity outside nearby combat, or when visiting the locked gate. Normal guidance has a 26-second cooldown. Locked-gate requests are limited to one every 8 seconds and never duplicate an already active Wisp.

The nearest unawakened seal is the navigation goal; once all are awake, the gate is the goal. Far goals produce only a short directional cue of approximately 270 px. Near goals can end at the local seal. No full-map marker or waypoint line is drawn. The locked gate names the region of the nearest missing seal so backtracking is purposeful.

## Save behavior

`GameSession.stage_objectives` stores completed IDs by stage scene path. Every awakening saves immediately alongside the current checkpoint without moving it. Death/retry, Continue and scene transitions preserve progress. Starting a new game clears it. Existing version-1 saves remain compatible and begin with unawakened seals if no objective field exists.

The existing F7 debug boss skip remains available for development; it bypasses normal gate progression intentionally.

## Files and Inspector controls

- `scenes/moon_seal.tscn` / `scripts/moon_seal.gd`: reusable seal, E receiver, saved appearance; `dormant_texture`, `awakened_texture`, `visual_scale` and manager path.
- `scripts/stage_objective_manager.gd`: required IDs, stage save namespace, progress signal, missing-goal selection and gate path.
- `scripts/moon_wisp_guide.gd`: `orb_texture`, `visual_scale`, cooldown, inactivity delay, travel duration and manager path. Decorative only.
- `scripts/stage_gate.gd`: manager path enables locking; empty path retains ungated behavior for other stages. `progress_textures` accepts states 0–3, plus `progress_art_scale`.
- `scripts/stage1_definition.gd`: width, gate position, stable seal IDs/regions/positions.
- `scripts/stage1_layout.gd`: seal/manager/guide instances and the additional shelves/scenery.

In Godot's **Remote** tree, open `Main → Stage1Layout` to inspect `StageObjectives`, the three named seal instances, `MoonWispGuide` and `StageTwoGate`. These nodes are currently constructed by the layout script; lasting placement/settings edits belong there or in the definition/script exports. Final animated assets can replace the visual children while retaining the interaction and progression components.

## Backup and review

Full backup made before implementation, including uncommitted source/assets and Git history, excluding only the regenerable `.godot` cache:

`C:\Users\Public\Godot Project\yuki-solz-before-moon-seals-20261011-193713`

Rendered previews:

- [First seal](previews/moon_seals_first_dormant.png)
- [First Wisp release](previews/moon_seals_first_wisp.png)
- [Hollow Oak branch](previews/moon_seals_oak_branch.png)
- [Stillwater discovery](previews/moon_seals_stillwater.png)
- [Locked gate](previews/moon_seals_gate_locked.png)
- [Awakened gate](previews/moon_seals_gate_awakened.png)

## Validation

Run `tools/tests/test_moon_seal_progression.gd` with `-- --presentation-test` for isolated saves. It covers E-only activation, checkpoint independence, 0–3 gate states, short-lived guidance, missing-region feedback, basic-jump seal access, save/retry, old-save compatibility, new-game reset, the entire expanded main-route traversal and Stage 2 entry without collecting any petals.

Results: **10 suites, 2,589 checks, 0 failures**. Existing chapter, optional-route, lantern, lighting, menu/death, platform-art, ground-combo, air-combo and Downward Slash regressions passed alongside the 52 progression checks. The full route traversal isolates terrain from enemies; combat encounters are exercised by the chapter/combo suites. Human playtesting is still needed for pacing and Wisp readability.

All **1,304 source PNGs** under `assets/` match the backup by SHA-256. Player, common-wolf and boss controllers, checkpoint/lantern animation scripts, Crescent projectile and Stage 2 scene also match the backup. The added preview images are screenshots, not new game artwork.
