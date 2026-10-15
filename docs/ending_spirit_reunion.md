# Silent Guardian ending — 2026-10-15

The original Guardian reveal is restored for Red's “Brother…?” line. The three newer illustrations follow it in order: broad hand contact, close hand contact, and the glowing wide shot. The Guardian remains silent; Red expresses uncertainty about his memories, recognizes his protective presence, and chooses to continue beside him.

## Current artwork

All four source PNGs were copied unchanged, including their aura, scarf and white lily. Matching source/imported SHA-256 hashes are recorded in [the manifest](ending_spirit_art_manifest.json).

| Source file | Active ending slot |
| --- | --- |
| Original `guardian_revision_v2/guardian_birth.png`, matching the user's corrected reveal reference | `assets/cutscenes/ending/panels/ending_06_guardian_birth.png` |
| `ChatGPT Image Oct 15, 2026, 01_16_38 AM-1.png` | `assets/cutscenes/ending/panels/ending_guardian_approach.png` |
| `ChatGPT Image Oct 15, 2026, 01_16_41 AM-2.png` | `assets/cutscenes/ending/panels/ending_07_guardian_touch.png` |
| `ChatGPT Image Oct 15, 2026, 01_16_43 AM-3.png` | `assets/cutscenes/ending/panels/ending_08_together.png` |

These paths are assigned explicitly to the four Inspector texture slots in `scenes/EndingCutscene.tscn`. The optional **Guardian Approach Artwork** slot provides the extra broad contact shot without changing the existing numbered slots. Previous images remain available in their original directories. Godot preserves aspect ratio and renders dialogue independently. No additional glow overlay or foreground particles were added; the supplied aura and existing gentle 3% zoom provide the visual treatment.

## Sequence and pacing

The sacrifice, farewell, lily trails and glowing fallen Wolf lead into the original Guardian reveal. His farewell remains “Keep the lily safe.”

1. **Original Guardian reveal:** soft flash settles over 0.25 seconds. Red: “Brother…?” Continue advances the line before any of the new pictures appear.
2. **No answer:** hold quietly for 1.2 seconds.
3. **Broad hand-contact picture, then close-up:** 0.35-second crossfade into the first new image, hold 2.3 seconds, then crossfade into the second new image and hold another 2.3 seconds. Red: “…You don’t remember me, do you?” Continue advances the line.
4. **Quiet response through presence:** 1.2-second pause, then a 0.35-second crossfade into the final wide shot.
5. **Facing the Keep:** 1.5-second camera settling beat plus the Inspector's **Wide Hold** of 3 seconds. The full glowing composition remains visible during the slow zoom.
6. Red: “…Still protecting me.”
7. Red: “Come on.”
8. Red: “This time… we go together.”
9. Pause for 1.2 seconds.
10. Narration: “The curse remains.”
11. Narration: “And the Silent Keep still waits.”
12. Fade to black for 1 second, then load Prototype Complete.

Dialogue waits for Continue in normal gameplay. Automatic preview holds are 2.3 seconds for “Brother…?”, 3 seconds for the memory question, 2.5/1.2/3 seconds for Red's wide-shot lines, and 2.5/2.8 seconds for closing narration. These preview durations do not impose a reading limit on the player.

The Guardian's looking/contact/protective presence is conveyed through the supplied still compositions and transitions. This pass does not create frame-by-frame character choreography. Red's memory question remains her interpretation, rather than a confirmed explanation from the spirit.

## Controls and validation

Continue: Enter, Space, E, controller A or the on-screen button.

Skip: Escape, controller Start/B or the on-screen button.

Full rendered playback verified all seven revised lines in order, Red-only Guardian dialogue, narration without a speaker label, the four correct texture resources, and aspect-preserving presentation. The restored reveal's rendered texture pixels match the original requested image. The phase check confirms reveal → broad contact → close contact → wide shot. It used manual Continue gates with keyboard and UI confirmation. The ending completed, saved the completion objective, cleared cinematic state, freed the boss, and returned through Prototype Complete to Title.

A second rendered run skipped while “…You don’t remember me, do you?” awaited Continue. It reached the same completion/title state with the world unpaused. Both final logs contain no runtime or shader errors; existing camera interpolation warnings remain.

Latest correction logs: `.godot/guardian_reveal_order_full.log`, `.godot/guardian_reveal_order_skip.log`, `.godot/guardian_reveal_order_import.log`. Earlier silent-reunion logs: `.godot/ending_spirit_full.log`, `.godot/ending_spirit_skip.log`, `.godot/ending_spirit_import.log`. Capture runs use isolated presentation saves.

## Previews

- [Guardian reveal](previews/ending_spirit_recognition.png)
- [Broad hand contact](previews/ending_final_guardian_approach.png)
- [Hand-touch dialogue](previews/ending_spirit_hand_touch.png)
- [Still protecting Red](previews/ending_spirit_protection.png)
- [This time, together](previews/ending_spirit_together.png)
- [Closing narration](previews/ending_spirit_keep_waits.png)

## Backup

Prior controller, scene, story notes and asset-slot README:
`.godot/local_backups/ending-spirit-reunion-20261015-012141/`

Backup before correcting the reveal order:
`.godot/local_backups/guardian-reveal-order-20261015-013426/`
