# Stage 1: forest crossroads and three exploration loops

**Historical revision:** the current [seal encounter redesign](stage1_seal_encounters.md)
moves Seal 3 into the Upper Forest Ruins, guards Seals 2/3, and adds the first
Wisp camera tour. The topology and validation below describe the earlier hub.

Implemented on `editpower1`, 11 October 2026. This was the initial hub layout;
the older chapter and Moon Seal documents describe the previous linear revision.

## Recovery copy

Full working project backup, including uncommitted files and assets:

`C:\Users\Public\Godot Project\yuki-solz-before-hub-layout-20261011-200445`

The generated `.godot` cache is excluded. No source PNGs were edited.

## Map

```text
                          BROKEN CHAPEL
                           Seal 1 (upper)
                         /              \
START -- LANTERN -- CROSSROADS ---------- \ -- RUINED BRIDGE -- JUNCTION -- HEARTWOOD -- LANTERN -- MOON GATE
                       \                                      \       /
                        HOLLOW OAK                             SIDE RUINS
                         |       \                              Seal 3
                     ROOT CELLAR -- seal-powered lift -- BRIDGE
                       Seal 2
```

Width is **10,000 px**, reduced from 13,000. The extra depth comes from connected
upper and lower routes, rather than more walking or additional enemies.

| Area | Approximate location | Connection / purpose |
| --- | --- | --- |
| Entrance, roots, first clearing | x 0–2300 | Existing opening, jump/dash/combat lessons, first lantern |
| Camp and crossroads | x 2300–3100 | Central rest point and visible upper/lower forks |
| Broken Chapel | x 3080–5240, y 452–164 | Ordinary climbing to Seal 1, eastern return into the bridge |
| Hollow Oak | x 3500–5400, main floor y 500 | Familiar oak/root scenery; optional canopy and petal |
| Root Cellar | x 3330–5270, floor y 740 | Open western descent or S + Space through root bridge; Seal 2 |
| Cellar shortcut | x 5140, y 740–500 | Lift wakes with Seal 2 and carries Red back to the bridge approach |
| Ruined Bridge / creek | x 5400–6400 | Existing water/wood dressing, ranged lesson and supported crossing |
| Side Ruins | x 6440–7880, floor y 680 | Later downward branch, burial scenery, one wolf and Seal 3 |
| Side Ruins return | x 7540–8020 | Separate east staircase rejoins before Heartwood |
| Heartwood | x 8000–8900 | Two staggered wolves; optional upper reward |
| Quiet approach | x 8900–10000 | Last lantern, scarf/flower foreshadowing and Moon Gate |

Seal positions are `(3900,164)`, `(4380,740)` and `(7160,680)`.
They are outside the normal ground route. Seal and petal IDs remain stable.

There are still eight wolves and six optional Moon Petals. The Chapel balcony,
Oak canopy, burial viewpoint and Heartwood shelves retain optional rewards.
The required routes do not need dash or advanced attacks.

## Checkpoints, interactions and saves

Three Moon Lanterns: **x 1100, 2800, 9100**. E activation, the waiting animation,
Escape cancellation, one-time healing and save behavior are unchanged.
Walking through a lantern or seal does not activate it.

Lanterns remain checkpoints only. Seals remain separate required objectives;
all three unlock E / Up / Enter at the Moon Gate. Petals remain optional.

Previous logical checkpoint IDs `forest_6500` and `forest_10600` are retained
at their new locations. Loading a pre-layout-version-2 save remaps the old
`(6500,485)` and `(10600,485)` anchors to `(2800,485)` and `(9100,485)`.
Learned mechanics, lit lantern history, petals and awakened seals are preserved.
The cellar lift restores its unlocked state from the cellar seal on retry.

**To explore all three seals from scratch:** stop the running game, press F5,
then choose New Game. Continue intentionally preserves completed objectives.

## Guidance and presentation

Wisps now indicate nearby branch entrances and return landmarks. They do not
fly directly to a seal. At the Chapel fork they lead upward; at the Cellar and
Side Ruins entrances they descend; after awakening a lower seal they suggest
its return exit. The existing temporary introduction, inactivity cues,
combat suppression and cooldown remain.

Existing environment, platform kit, oak, cellar, graves, camp and Heartwood
scenery were repositioned. Regional platform styles and background shading
follow the new rooms. Red, enemies, VFX, lantern animations, UI and the 1.35
gameplay zoom keep their existing rendering. No new final art was generated.

Tutorial hints still complete only after the actual mechanic succeeds.
Rising Slash and aerial hints belong to the upper Chapel route; Downward Slash
is an optional later hint. Walking to the destination does not complete a lesson.

## Editing

- `scripts/stage1_definition.gd`: objectives, checkpoints, rewards, encounters,
  lesson regions, map width and guidance waypoints.
- `scripts/stage1_hub_routes.gd`: section-by-section terrain and connections.
- `scripts/seal_shortcut_lift.gd`: cellar lift unlock behavior.
- `scripts/stage1_exploration_scenery.gd`: landmark dressing and area labels.
- `scripts/stage1_layout.gd`: shared terrain helpers, actors, status and gate setup.
- `scripts/stage_objective_manager.gd`: short contextual guidance destinations.

## Checks and previews

Tests use separate `presentation_test_*` save files, not the player's journey.

| Suite | Checks |
| --- | ---: |
| Actual jumps, descents, loop returns, lift ride and all six petals | 70 |
| Seal progression, guidance, gate, old-save migration and shortcut restoration | 58 |
| Chapter traversal, lessons, combat spacing and checkpoints | 54 |
| Moon Lantern interaction / cancellation / interruption | 69 |
| Selective lighting and excluded gameplay visuals | 1,220 |
| Platform art and terrain collision consistency | 36 |
| Title, hazards, moving platforms, death/retry and Stage 2 transition | 59 |
| Ground combo | 109 |
| Air combo | 232 |
| Downward Slash | 177 |

Total: **2,084 checks; zero failures**. Ten actual in-game rendered previews
are saved under `docs/previews/stage1_hub_*.png`. Source comparison against
the backup confirms all **1,304 source PNGs** are unchanged, along with the
player, common wolf, boss, lantern/checkpoint and projectile implementations
and the Stage 2 scene.

- [Crossroads](previews/stage1_hub_01_crossroads.png)
- [Upper/lower fork](previews/stage1_hub_02_upper_and_lower_fork.png)
- [Broken Chapel](previews/stage1_hub_03_chapel_seal.png)
- [Root Cellar](previews/stage1_hub_05_root_cellar.png)
- [Cellar shortcut](previews/stage1_hub_06_cellar_shortcut.png)
- [Side Ruins](previews/stage1_hub_08_side_ruins.png)
- [Heartwood](previews/stage1_hub_09_heartwood.png)
- [Moon Gate](previews/stage1_hub_10_moon_gate.png)

Automated route and visual checks establish reachability and consistency;
your playthrough will determine whether the exploration and pacing feel right.
