# Finding the first Moon Seal

Stage 1 now gives an early visual cue at the hub before the cellar fork.

## Wisp glimpse

The existing `MoonWispGuide` triggers a single short cue when Red is grounded,
free of other actions, and within the hub approach: X 2780–3160, Y 405–520.
It waits if a living enemy is within 360px. It is available only while no
Moon Seal has been activated.

The Wisp appears 60px ahead of Red, drifts toward the chapel's first climbing
steps at **(3140, 392)** over **2.8 seconds**, hovers for **2.6 seconds**, and
plays its normal disappearance animation. Moving/idle/arrival frames and the
lingering trail come from the existing Wisp visual component.

The player keeps movement and camera control. The glimpse does not pause the
game, activate a seal, set a checkpoint, or consume a gameplay action. It runs
once per loaded Stage 1; retries may show it again until Seal 1 is activated.
The existing full cinematic after Seal 1 activation still takes priority and
replaces any active glimpse. Later seal guidance retains its established timings.

Tune the trigger, destination, flight and hover durations under **First Seal
Discovery** on `Stage1Layout/MoonWispGuide` in the Remote Inspector, or change
the defaults near the top of `scripts/moon_wisp_guide.gd`.

## Chapel landmark

`Stage1Layout/Stage1Journey/ChapelMoonLandmark` is fixed world scenery:

- a small glowing crescent at **(3080, 408)** marks the ascending entrance;
- a matching larger crescent at **(3900, 29)** sits above the new shrine artwork;
- once Seal 1 activates, the entrance beacon disappears and the chapel crest
  becomes dim and still.

The crescents use integer pixel geometry, nearest filtering, an unshaded
material, and the existing Moon Seal's silver/violet/crimson glow palette.
No PNGs are generated or edited. They have no collisions or interaction.

Tune the radius, glow and entrance offset in `scripts/chapel_moon_landmark.gd`.
Placement is set in `scripts/stage1_journey.gd`.

## Review

The Godot editor import completed without script errors. No automated tests
or gameplay playtest were run for this change.

The two modified scripts were backed up before editing at
`.godot/local_backups/chapel-discovery-20261012-005813/`.

To see the glimpse, use a Stage 1 run where the first seal is still dormant.
