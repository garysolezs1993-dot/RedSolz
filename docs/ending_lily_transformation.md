# Longer Guardian transformation with lily trails

The Guardian artwork now appears **after** the live arena transformation. Previously, the picture was shown first and hid the body fade behind it.

## New presentation

After the final farewell and brief lily transition:

1. Return to the in-engine arena and frame the fallen Wolf with Red nearby (0.5-second camera move).
2. Two animated lily ribbons circle around the still-present cursed body while soft moonlight builds (1.8 seconds).
3. The cursed body fades gradually as the silver Guardian appears in the same area (3 seconds).
4. New lily emission stops. Existing afterimages fade independently while the moonlit glow settles (1 second, or enough to complete their lifetime).
5. Transition to the assigned Guardian Birth illustration. Continue becomes available on that panel.

The configured live transformation lasts approximately **6.3 seconds**, followed by the normal panel transition. This is a timing calculation; gameplay playback has not been measured for this revision.

The full effect runs automatically once the farewell has been advanced. Continue is disabled while the transformation is playing; Skip remains available. Story dialogue, sacrifice, final artwork assignments, manual panel controls and saved completion handling are retained.

## Reused assets and behaviour

`scripts/ending_lily_transformation.gd` reuses the eight existing `lily_trail_00–07.png` files unchanged through the existing world-space afterimage pool. Two opposing ellipse paths create a soft circling/rising impression around the Wolf.

- Each emitted trail stays in world space and fades independently.
- Lifetime is 0.95 seconds, with a fade over the final 0.35 seconds.
- New pairs spawn at most every 0.14 seconds.
- Pool capacity is capped at 18; sprites are reused.
- The fixed 512×512 canvas, front pivot and authored orientation are preserved in Godot.
- These are floating symbolic lily-trail effects, not extra flowers attached to the Wolf's scarf.
- Soft moonlight is drawn in Godot beneath the body. The Guardian is placed in the same area during the body crossfade, then uses the existing later approach.
- Red remains in front of the spirit for readability.
- Skip stops emission and hides the transformation layer; scene cleanup removes its pool and remaining visual nodes.

No Wisp route logic or source PNG was changed. This is an ending-only use of the existing motif. No new Guardian gameplay behaviour or sprite animation was added.

## Inspector controls

On the EndingCutscene root:

- **Pacing → Guardian Formation Duration:** 3.0 seconds for the body/Guardian crossfade.
- **Guardian Lily Transformation → Transformation Lily Build Duration:** 1.8 seconds.
- **Transformation Linger Duration:** 1.0 second.
- **Transformation Lily Radius:** (125,55) world pixels.
- **Transformation Lily Scale:** 0.12.
- **Transformation Lily Opacity:** 0.34.

These expose the main timing and visibility choices for tuning after a live review.

## Backup and import

Pre-change files are backed up at `.godot/local_backups/ending-lily-transformation-20261013-230839/`.

Godot editor import completed successfully (`docs/ending_lily_transformation_import.log`). No gameplay tests or new capture run were performed for this revision. Existing preview GIFs predate the longer live transformation. The capture helper's future expected phase list includes `guardian_transformation` before `guardian_birth`.