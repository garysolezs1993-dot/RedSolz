# Stage 1: discover, fight, climb

Implemented on `editpower1`, 11 October 2026. This revision builds on the existing
forest hub; its footprint remains 10,000 px. No source PNGs or player combat
systems were changed.

## Recovery

Full working project backup before this revision:

`C:\Users\Public\Godot Project\yuki-solz-before-seal-encounters-20261011-214005`

It includes uncommitted files and assets, excluding the generated `.godot` cache.

## Topology

```text
                  BROKEN CHAPEL
                  Seal 1: discover
                 /               \
START -- LANTERN -- HUB -- HOLLOW OAK -- RUINED BRIDGE
                          |                  |
                          v                  ^
                      ROOT CELLAR       UPPER FOREST RUINS
                     Seal 2: fight      /                \
                          |       canopy lookout     hazard crossing
                     return lift   optional petal         |
                          +---- BRIDGE              ruined tower
                                                        |
                                                UPPER SANCTUARY
                                                fight -> Seal 3
                                                        |
                                                   gentle descent
                                                        v
                                      QUIET HEARTWOOD -- LANTERN -- GATE

Below the bridge: optional burial ruins, petal and separate return stairs.
```

Routes remain freely explorable. Seal activation follows **1 -> 2 -> 3**. An
early visit explains the earlier seal's region. Each guarded seal also shows
how many of its designated wolves remain; rushing past them cannot awaken it.
E is required to activate all seals and checkpoints.

| Encounter | Position | Purpose |
| --- | --- | --- |
| Seal 1 | (3900, 164) | Safe Chapel discovery with no mandatory wolf |
| Seal 2 | (4900, 740) | Protected Cellar, two staggered guardians on a broad safe floor, two escape shelves |
| Seal 3 | (8320, 126) | Climb above the bridge, broad hazard crossing, tower ascent, two staggered sanctuary guardians |

Eight wolves are retained. The former Heartwood pair now guards the Cellar;
the former Chapel and burial wolves guard the upper sanctuary. Wolves use
their existing attack/pack logic, with tunable warning/recovery and contained
leashes. No new attacks or combat requirements were added. Red can use her
current full combat kit; advanced combos are optional.

The upper route starts at (6080,450), climbs in 54 px steps, then opens into
canopy platforms at y288. Spikes at x7140 and warning roots at x7340 sit on a
stable crossing. The final combat terrace spans x7700–8540 at y126, separate
from the hazards. Optional lookout shelves reach (7240,18) and reconnect near
the tower; a petal and distant Moon Gate glimpse reward the detour.

After the final seal, eastern shelves descend gently to the quiet gate
approach. There are no enemies or hazards after the sanctuary. The familiar
Oak, Cellar, burial ruins, main trail, checkpoint positions and existing scenery
remain. Six petal IDs are preserved: the burial petal now rewards the lower
optional ruins, and the former Heartwood petal rewards the upper lookout.

## Wisp and saves

Finished Wisp visuals are now integrated through a reusable animated scene.
See [Moon Wisp integration](moon_wisp_integration.md) for scale/FPS controls,
unchanged source assets, gameplay previews, and current visual validation.

- Seal 1: about 7.5 seconds, including swirl, camera travel to the open Cellar
  entrance, fade and smooth camera return. Gameplay pauses safely; the Wisp
  and temporary camera continue. It reveals the route, not the seal inside.
- Escape skips the introduction safely. Scene interruption also restores
  the pause state and removes the temporary camera.
- Seal 2: approximately 7.3 seconds, including a three-second flight,
  three-second linger and gentle arrival; a local cue toward the lift and an
  upward-route clue. Red's camera and gameplay remain active.
- Seal 3: awakens the Moon Gate, without another tour.
- Existing contextual/inactivity Wisp cues remain available.

Existing completed seal IDs and checkpoint saves remain compatible. Retry
does not replay the first introduction, and guards of completed seals remain
cleared. Guards of unfinished seals respawn on retry. Seals never advance a
checkpoint or grant petals.

**To try the complete redesigned progression:** stop the running game, press
F5 and choose **New Game**. Continue preserves seals already awakened.

## Editing

- `scripts/stage1_definition.gd`: seal positions/order/guard lists, encounter
  locations, rewards, first Wisp route and normal guidance landmarks.
- `scripts/stage1_hub_routes.gd`: `_upper_ruins_loop()` contains the new climb,
  crossing, lookout, sanctuary terrace and quiet return. `_oak_and_cellar_loop()`
  contains the Cellar escape shelves.
- `scripts/stage1_layout.gd`: guardian warning/recovery/leash tuning and removal
  of completed guard encounters during scene construction.
- `scripts/moon_seal.gd`: local guard tracking, blocked prompts and E activation.
- `scripts/stage_objective_manager.gd`: activation order and branch guidance.
- `scripts/moon_wisp_guide.gd`: introductory camera sequence and brief cue;
  Inspector exports control tour travel and camera return durations, plus
  `brief_travel_duration`, `brief_landmark_duration` and `brief_fade_duration`
  for the second seal's cue.
- `scripts/stage1_exploration_scenery.gd`: visual-only upper ruins dressing.

## Validation and previews

Tests use isolated save files. Eleven suites cover route traversal, progression,
guardian gating and actual melee, staggered attacks, cinematic cleanup, save
reload, lanterns, scene transitions, lighting and the existing combat systems.
Before the later brief-cue timing adjustment: **2,276 checks, zero failures**.
Logs are `docs/seal_test_*.log`. The timing adjustment has not been playtested.

Ordinary movement and jumps reach all seals and all six petals. The upper
hazard crossing was traversed with damage enabled and no HP loss. Gameplay
camera remains at 1.35. All 143 platform art helpers retain readable top edges.
All **1,304 source PNGs**, player/wolf/boss scripts, lantern logic, projectile
code, GameSession and Stage 2 scene match the pre-change backup.

- [Safe Chapel](previews/seal_encounters_01_safe_chapel.png)
- [Wisp camera tour](previews/seal_encounters_02_wisp_tour.png)
- [Cellar guardians](previews/seal_encounters_03_cellar_guardians.png)
- [Upward bridge fork](previews/seal_encounters_04_upward_fork.png)
- [Upper hazard crossing](previews/seal_encounters_05_hazard_crossing.png)
- [Optional canopy lookout](previews/seal_encounters_06_canopy_lookout.png)
- [Final sanctuary](previews/seal_encounters_07_sanctuary.png)
- [Quiet descent](previews/seal_encounters_08_quiet_descent.png)

Automated checks establish reachability and state safety. A playthrough is
still needed to judge whether the pacing and challenge feel right to you.
