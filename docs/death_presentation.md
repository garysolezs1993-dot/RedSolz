# Death focus and forest fog transition

When Red reaches zero HP, the existing damage handler still updates HP and
locks actions. `GameSession.present_death()` starts the persistent controller
in `scripts/death_presentation.gd`.

## Sequence

1. Pause the SceneTree immediately: enemies, attacks, projectiles, environment
   animation and controls stop. Hide the stage HUD. Stop combat SFX and fade
   stage music down over 0.8 seconds.
2. If Red is airborne, snapshot the nearest terrain below her and settle her
   vertically onto it, playing fall. This takes up to 0.8 seconds. The world
   remains paused and no live enemy simulation is needed.
3. A temporary camera eases toward Red and zooms to 1.5x over 0.3 seconds.
4. Play the eight-frame death clip once at its existing 8fps, then hold its
   final pose for another 0.4 seconds.
5. Procedural dark blue/purple fog covers the screen over 0.85 seconds.
6. Swap to Game Over only at full opacity. Remove the temporary camera and
   resume the tree so Game Over atmosphere and music can run.
7. Reveal the Game Over forest through fog over 1 second. Fade in the heading
   and panel for 0.55 seconds, followed by buttons for 0.25 seconds. Enable
   buttons and focus Try Again only after the presentation finishes.

Grounded deaths take approximately 4.3 seconds to reach the active menu.
Airborne deaths additionally include the short settling movement.

## Implementation and tuning

- `scripts/death_presentation.gd`: zoom multiplier, focus duration, final hold,
  fog cover and reveal durations are exported at the top of the script. The
  controller is a child of the existing GameSession autoload.
- `shaders/death_fog.gdshader`: moving fog density and dark colour. Progress 0
  is transparent; progress 1 is fully opaque. No new raster art was generated.
- `scripts/game_over.gd::reveal_death_menu()`: text and button reveal timings.
- `scripts/audio_director.gd::fade_for_death()`: stage music fade and SFX stop.
- `tools/capture_death_presentation.gd`: preview/capture the real grounded or
  airborne sequence using `--presentation-test` and optional `--airborne`.
  Test-mode saves use separate paths from the player's actual journey.

Red's Visual and the temporary camera explicitly run while paused. The
controller's tweens ignore hitstop time scaling and run during pause. Death
invalidates pending hitstop callbacks. Animation display scale and authored
ground contacts remain intact; body interpolation is disabled only during
the presentation's settling movement. Retry, checkpoints, health, attacks,
assets and ordinary menu/gate fades retain their existing behavior.

GameSession blocks competing transitions throughout death. The controller
cleans up pause and overlay state if the player is removed unexpectedly.
Directly opening Game Over still displays its menu normally without waiting
for a death presentation that did not occur.

## Checked locally

Captured the real grounded and airborne flows at 960x540. Gameplay remained
paused through focus, collapse, final hold and fog cover. Red's eight frames
continued playing; airborne Red settled onto the platform below her. The
scene changed under full fog, and menu input resumed after the reveal.
The existing 25 combat/death and 58 presentation checks passed (83 total),
including checkpoint retry, Return to Title and Continue. Their death waits
were extended for the new presentation duration. Existing capture shutdown
resource warnings can still occur; no runtime script or shader errors occurred.
