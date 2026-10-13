# Boss arena floor and platform artwork

## Floor protection

The boss previously collided physically with Red, whose body shares terrain layer 1. Combined with the thin one-way arena floor, overlapping bodies could push the boss below the combat surface. This is a likely cause based on the controller and collision setup; the reported fall has not been reproduced in a combat playthrough.

- The boss excludes Red from movement collisions. Attack ranges and hurtboxes still handle combat damage.
- The main floor at Y = 500 is now a shared solid floor on layers 1 and 5 (mask value 17). Red collides through layer 1 and the boss includes both layers. The separate boss-only support has been replaced by this shared floor.
- Stage 2 enables the boss's `Arena Safety` settings. The boss stays within X = 28–2772. If its feet pass more than 12 pixels below the main floor, it returns just above that floor and enters recovery. Health is preserved; dead bosses remain dead.
- Normal jumps and pounces above the arena floor remain available.

Implementation: `scripts/stage2_boss_layout.gd` and `scripts/cursed_wolf_boss.gd`.

## Platform artwork

The main arena floor, lower catch floor and seven raised ledges reuse `scripts/forest_platform_art.gd` and the existing Stage 1 moss, stone and root assets. Entrance ledges use gate dressing, combat platforms use heartwood dressing, and the catch floor uses cellar dressing. Raised ledges use compact pieces to avoid visually covering the floor below them.

Platform positions and artwork are retained. The seven raised ledges retain their one-way, drop-through collision settings. The main floor and catch floor now have 80-pixel-deep solid colliders with the same top surfaces. Source PNGs are unchanged, with nearest-neighbor filtering. `platform_art_enabled` on the Stage 2 layout switches this artwork on or off.

## Red falling out of Stage 2: follow-up

Both base floors previously used the `RootedLedge_*` name and one-way collisions. Red's S + Space controller recognizes that name as droppable, so the main floor and catch floor could both be bypassed. The earlier boss-only support did not stop Red.

The base floors now use `ArenaGround_*` names and solid collisions. S + Space can still drop through raised ledges, but cannot ignore either base floor. A Stage 2 physics callback runs after Red's movement to clamp horizontal map bounds and rescue her if her feet pass 40 pixels below the main surface. Rescue cancels the current action, clears any pending drop-through exception, stops velocity and returns her above the floor at the same bounded X position. Health, boss health and ability cooldowns are retained; death presentation is excluded.

Follow-up backup: `.godot/local_backups/player-boss-floor-20261013-101251/`.

Editor import for the follow-up completed successfully (`docs/boss_player_floor_import.log`), with existing duplicate asset UID warnings. No gameplay tests were run for this follow-up.

## Backup and review

Before-change copies of the layout, boss script and Stage 2 scene are in:

`.godot/local_backups/boss-arena-platforms-20261013-095751/`

Godot editor import completed without errors. The two staged gameplay captures below completed without errors and show the artwork at the current Stage 2 camera scale. These captures freeze the actors for visual review; they do not verify combat behavior. No automated gameplay tests were added or run for this change.

- [Arena preview](previews/boss_platforms_arena.png)
- [Entrance preview](previews/boss_platforms_entrance.png)

Restart the running game to load the updated layout and boss script.
