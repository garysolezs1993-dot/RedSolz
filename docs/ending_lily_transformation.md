# Guardian reveal through moonlight and illustrated panels

The ending now uses the existing death pose and lily trails, then cuts directly to the supplied Guardian Wolf illustration. It no longer creates an in-engine Guardian placeholder or reuses the standing Cursed Wolf sprite as a Guardian.

## Sequence

1. Focus the camera on the fallen Wolf (0.5 seconds).
2. Build the existing circling lily trails (1.8 seconds).
3. Brighten the death-pose silhouette to moonlit white while a local halo grows around it (3.0 seconds).
4. Add a brief, low-opacity soft flash (0.12 seconds), then reveal the Guardian Birth artwork immediately at peak brightness.
5. Fade the flash over 0.25 seconds. Remaining trails finish naturally behind the artwork, without delaying its reveal.
6. Continue through the existing Guardian Touch and Together illustrations, using the existing manual Continue/Skip controls.

Calculated time from camera focus to the Guardian panel is approximately 5.42 seconds. No live playback measurement was performed.

## Assets and controls

Source PNGs are unchanged. The eight existing lily-trail frames use the same bounded, world-space afterimage pool. No separate Guardian sprite is required for this version.

The new ending-only shader, shaders/ending_transformation_glow.gdshader, preserves the death pose's transparency while whitening its visible silhouette. The ending_lily_transformation helper draws the growing halo in Godot. Red's appearance is unchanged.

EndingCutscene Inspector controls retain Guardian Formation Duration for the glow buildup, Transformation Lily Build Duration, Transformation Linger Duration for the glow fade behind the panel, and the existing trail radius/scale/opacity values. Guardian Touch Duration now holds the emotional illustration rather than moving a placeholder sprite.

Skip still completes the story through the existing completion-screen path. An external interruption restores the Wolf's original material and modulation along with the previously saved actor state.

Backup: .godot/local_backups/guardian-glow-reveal-20261014-104017/
Godot editor import completed successfully. No gameplay tests or new capture run were performed. Existing preview GIFs show the earlier implementation.