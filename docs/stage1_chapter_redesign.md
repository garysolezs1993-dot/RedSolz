# Stage 1: journey to the Moon Gate

> **Current layout:** see [Stage 1 hub redesign](stage1_hub_redesign.md).
> The coordinates and expansion below document the previous revision.

## Recovery copy

Before editing, the live Stage 1 files (including uncommitted scripts/scenes),
project settings, git status and working-tree patch were copied to:

`C:\Users\Public\Godot Project\yuki-solz-stage1-backup-20261011-140509`

The backup is outside the project, so Godot does not import duplicate scripts.
Existing art was reused and no source PNGs were changed. Work remains on
`editpower1`; this redesign has not been committed or pushed.

## Chapter layout

Width is now 13,000px after the [Moon Seal progression expansion](moon_seal_progression.md). Definition data lives in `scripts/stage1_definition.gd`.
The layout builds each section separately before adding encounters/rewards.

| Approximate x | Section | Purpose |
| --- | --- | --- |
| 0–640 | Quiet entrance | Gentle ledges; movement/jump practice; no wolves |
| 640–1100 | Fallen roots | Timed roots suggest dash; jumping/waiting also works |
| 1100 | First promise lantern | Explicit E activation before combat |
| 1250–2200 | Lone wolf clearing | One wolf at 1600; basic combo practice; raised petal |
| 2300–3400 | Abandoned camp | One wolf at 2800; cold campfire and claw-marked crate |
| 3500–5200 | Broken chapel | One wolf at 4200; launcher/air attacks; optional chapel climb |
| 5200–6400 | Winding creek | One wolf on a 424px shelf at 5800; ranged practice |
| 6500 | Second promise lantern | Rest before exploration |
| 6400–8900 | Oak trail/canopy/cellar | Existing routes shifted +1600px, not rebuilt; two petals |
| 8900–9800 | Forgotten burial ground | Existing ruined graves and optional elevated wolf/petal |
| 9800–10400 | Heartwood clearing | Two wolves at 9920/10120; coordinated combined test |
| 10400–10800 | Heartwood rest | No encounters/hazards; scarf/flower foreshadowing |
| 10800–11900 | Stillwater discovery | Third seal on a low branch, quiet pond and traversal |
| 11900–13000 | Moon Gate approach | Optional memorial nook and quiet destination glimpse |
| 10600 | Final promise lantern | Save/rest before entering the boss stage |
| 12840 | Moon Gate | E, Up Arrow or Enter opens the existing Stage 2 after all three seals |

Moon Lantern checkpoints do not count as mission progress. Three separate Moon
Seals at x=3240, 6780 and 11320 unlock the gate; temporary Wisp guidance helps
with the two short exploration branches and missing-seal backtracking.

There are eight wolves total: six on the main route and two on optional shelves.
The ordinary main floor is continuous at y=500. Ledges remain top-only; the
solid catch floor and return shelves remain available. Advanced attacks do not
unlock doors, bridge required gaps or gate progression. The six petal IDs and
their persistent collection behavior are retained.

## Checkpoints and reusable E interactions

`world_interactable.gd` is a reusable component. Attach it beneath an object that
implements `interact(player)`, optionally `can_interact(player)`. It exposes
receiver path, prompt, horizontal/vertical range and selection priority.

`interaction_router.gd`, attached by Red, chooses the nearest eligible object,
uses priority to resolve overlap, and routes one non-repeated E press to one
receiver. Dead/busy players cannot interact. Empty-space E does not play a fake
interaction. NPCs, doors and switches can use the same interface later.

Checkpoint contact has no activation signal. Nearby inactive lanterns show
`E — Activate Checkpoint`. E saves a supported respawn, heals once, lights the
lantern, plays confirmation audio and briefly animates Red. Activation history
is saved; retrying or reloading does not make a used lantern refill health again.
New Game clears that history. The Moon Gate uses the same E router while keeping
its existing Up/Enter inputs and fade/health transfer.

## Contextual lessons

Stage 1 hides the permanent control list. `stage1_journey.gd` shows one small
contextual lesson at a time. Leaving a lesson hides its text but does not complete
it: returning restores the hint until the mechanic has actually been performed.

Red emits `mechanic_demonstrated` only at accepted gameplay events:

- Jump: grounded jump accepted.
- Dash: cooldown/state checks passed and dash starts.
- Ground attack: the swing reaches active damage frames.
- Rising Slash: upward launch actually happens.
- Air attack: the swing reaches active frames while airborne.
- Crescent: projectile is released, not just the button pressed.
- Downward Slash: dive reaches a real landing impact.
- Drop through: a supporting platform is actually ignored.

The optional Downward Slash hint appears after aerial combat has been demonstrated.
Standalone airborne Downward Slash, all air-finisher routes, movement locks and
dash cancels remain intact. Learned lessons persist with the journey and clear on
New Game. No new mandatory combo tutorial was added.

## Wolf tuning

Stage 1 configures per-instance exports, preserving defaults in other scenes:

- Lunge warning: 0.35s first wolf, 0.30s later; first attack pose held, amber `!`, huff.
- Actual lunge: existing burst, attack animation and attack sound.
- Stationary recovery: 0.85s first wolf, 0.70s later.
- Random leaps disabled for teaching encounters; optional canopy/Heartwood use
  5–8s intervals. Terrain-directed jumps and existing safe-ground checks remain,
  with at least 1.6–2.4s between attempts instead of rapid repeated jumps.
- Encounter leash: 280px main, 220px optional, keeping fights out of rest areas.
- Heartwood pack allows one warning/lunge at a time; next attack waits through
  at least half the first wolf's recovery. The second has an extra 0.35s windup.
- Melee knockback multiplier 0.25: the first swing no longer pushes the small
  wolf beyond stationary follow-up swings. Health 42 and damage 10 are unchanged.

Boss AI, boss damage, player dash/Crescent cooldowns and their existing i-frames
were not retuned. Gate silhouette is separate noninteractive background scenery,
visible from later exploration and fading before the real gate comes into view.

## Verification

Use isolated saves with `-- --presentation-test` for all tools/tests scripts.
`tools/tests/test_stage1_chapter.gd` exercises opening, checkpoints, actual
mechanic completion, wolf warning/recovery/containment, stationary melee,
Heartwood attack staggering, oak/cellar/burial landings, ordinary route traversal
with live hazards, retry and E gate transition. `--capture` records the sections.

Logs and screenshots: `.godot/stage1_chapter_review/` (excluded generated output).
The introductory combo regression initially failed because of the wolf's large
knockback; after the Stage 1 multiplier adjustment, all 53 headless checks passed.
The final headless chapter pass has 54 passing checks (including the actual ranged
hit from the creek shelf), and the separate ordinary-jump route pass has 37.
The rendered chapter pass has 53 passing checks; the final updated creek/chapel/
oak/approach scenes were also captured with `tools/capture_stage1_chapter.gd`.

| Regression suite | Passed | Failed |
| --- | --- | --- |
| Ground combo | 109 | 0 |
| Air combo | 232 | 0 |
| Downward Slash | 177 | 0 |
| Boss melee | 23 | 0 |
| Crescent | 12 | 0 |
| Movement/dash | 41 | 0 |
| Menu, presentation, death, retry, Continue, Up gate | 59 | 0 |
| Stage 1 chapter | 54 | 0 |
| Optional routes and six petals | 37 | 0 |

Test fixtures were updated for the redesigned practice ledge, E checkpoints and
the existing dash cooldown. Retired hazards remain covered by isolated fixtures;
they were not put back into the chapter to satisfy old tests.
Test teardown may report existing ObjectDB/resource warnings, distinct from
gameplay/script errors. Editor import also reports archived duplicate texture
UIDs and the existing Camera2D interpolation notice.

Start **New Game** from the title to experience the complete lesson flow. Continue
retains the existing journey and demonstrated lessons instead of restarting it.
