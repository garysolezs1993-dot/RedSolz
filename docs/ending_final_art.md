# Final ending artwork integration

[Previous art-pack playback](previews/ending_final_art_full_run.gif)

Guardian Birth and Together now use the two replacements documented below. This earlier GIF predates those replacements and the manual Continue controls.

## Story preserved

The restored original sequence remains:

**collapse → Red approaches → sibling conversation → Keep reacts → curse strike → brother sacrifices himself → Red rushes to him → farewell → lily/moonlight → Guardian appears → Guardian touches Red → together facing the Keep → Prototype Complete.**

No recognition/memory scenes were reintroduced. The earlier collapse, approach, lucidity and Keep reaction remain in-engine, with the original dialogue and actor choreography. The mandatory sacrifice remains a separate beat before the farewell and Guardian transformation.

## Imported assets

All six supplied PNGs are imported unchanged into `assets/cutscenes/ending/final_art_v1/`. They are each 1672×941. `ending_final_art_manifest.json` records matching source/import SHA-256 hashes. No source artwork was cropped, resized, recoloured or given baked text.

| Active Inspector slot | Assigned image |
| --- | --- |
| Sacrifice Artwork | `moonlit_wolf_s_crimson_sacrifice.png` |
| Final Words Artwork | `red_and_the_cursed_wolf_beneath_the_blood_moon.png` |
| Guardian Birth Artwork | `guardian_revision_v2/guardian_birth.png` |
| Guardian Touch Artwork | `moonlit_guardian_s_tender_farewell.png` |
| Together Artwork | `guardian_revision_v2/together_wide.png` |

`crimson_moonlit_farewell.png` is retained as an unassigned alternate farewell composition. The selected version shows the Wolf lying lower beside Red, fitting the weakened post-impact moment. Swap Final Words Artwork on the root of `scenes/EndingCutscene.tscn` to compare them.

No separate transparent Guardian sprite or lily-insert illustration was supplied. The existing world-space silver Wolf and lily transition remain available between panels; full-scene illustrations are never treated as gameplay sprites.

## Presentation changes

- Aspect-preserving TextureRects with dark backing; important faces, hand contact, scarf and attached lily remain readable.
- 3% slow zoom towards the fitted image size, without a zoom beyond it.
- 0.35-second transitions, with a two-TextureRect crossfade between adjacent illustrated shots.
- The sacrifice retains its impact choreography and gains an additional 3-second artwork hold so it cannot flash past unreadably.
- The flash is milder while sacrifice artwork is displayed, leaving its protective composition visible.
- Dialogue remains in Godot, with a dark backing for contrast over the detailed paintings.
- A brief existing execution sound emphasises the impact; existing breathing and subdued ending music remain.
- Default world-space dissolve particles are detached petal shapes rather than repeatedly spawning whole flowers. The Wolf's single attached lily and Red's own flower accessory remain separate.

The root exposes Panel Transition Duration, Panel Zoom and Sacrifice Panel Hold in addition to the original timing controls. These tune presentation, not the story order.

## Artwork review

The pack is usable for this review pass: all images are consistent in size, clean and free of baked words/numbers. The sacrifice composition clearly shows the Wolf between Red and the curse strike. Farewell and hand-touch compositions support the intended emotion, and the final image shows the pair facing the Keep.

The main remaining art-direction concern is strong crimson light/energy around the white Guardian in the transformation, touch and wide images. It can suggest lingering corruption despite the gentle pose and white fur. A future art revision could reduce those streaks and use softer silver/moon-blue glow while preserving the red scarf and exactly one attached white lily. No edits were made to compensate inside the source PNGs.

## Backup

The restored pre-art ending is preserved at `.godot/local_backups/ending-final-art-20261013-213527/` (controller, scene, capture helper, guide and panel README).

## Verified playback

Godot editor import completed successfully. Full playback confirms the original ordered phases and reaches Prototype Complete at frame 3725, about 62.1 seconds at 60 FPS. The GIF includes the subsequent completion screen and Return to Title: 264 frames at 4 FPS, about 66 seconds total.

A separate capture uses a real Red attack through her existing combat hitbox, with the previously requested temporary one-hit KO enabled. That attack defeats the boss and triggers the ending. Escape during the sacrifice safely completes the story and returns through Prototype Complete to Title.

Both runs record: world unpaused, completion saved, ending flag cleared, boss freed and title music context restored. No runtime/script errors were reported. Existing camera interpolation warnings remain.

Capture sound was muted for the preview, so subjective sound balance still needs a live listening review. Normal player save data was isolated from the capture runs. The temporary boss-stage KO switch remains enabled; original damage is still 20 per hit when disabled.

Logs: `ending_final_art_import.log`, `ending_final_art_capture.log`, `ending_final_art_skip_capture.log`.

- [Sacrifice](previews/ending_final_sacrifice.png)
- [Farewell with dialogue](previews/ending_final_farewell_dialogue.png)
- [Guardian touches Red](previews/ending_final_guardian_touch.png)
- [Final wide panel](previews/ending_final_together.png)
## Continue and Skip controls

The ending now has the same bottom-screen Continue/Skip controls as the opening:

- **Continue:** Enter, Space, E, controller A, or click Continue.
- **Skip ending:** Escape, controller Start/B, or click Skip ending.

Dialogue waits for Continue by default. The sacrifice artwork, lily pause, Guardian birth and Guardian touch also offer Continue after their animation/effect completes. Fades, collapse, impact and movement retain their automatic timing; Continue is disabled during these transitions. Keyboard repeat is ignored and presses during transitions are not queued, preventing one press from advancing several story beats.

**Auto Advance** on the EndingCutscene root defaults to disabled. Enable it to retain timed playback while still allowing Continue. The capture helper enables Auto Advance only for timing previews; normal gameplay keeps the manual setting.

Enter/Space are no longer Skip bindings for the ending. Skip cancels the active wait/tween and goes through the existing saved completion handoff. A pending manual Continue wait is left suspended until scene cleanup, so it cannot resume the story during Skip.

The previous final-art GIF records timed playback before these controls were added. Godot editor import passed for this change (`ending_continue_import.log`); no new gameplay test or capture was run for the controls.

Pre-change backup: `.godot/local_backups/ending-continue-controls-20261013-215522/`.
## Guardian appearance and final-wide replacements

The two approved PNGs now replace only Guardian Birth Artwork and Together Artwork in `scenes/EndingCutscene.tscn`:

- `guardian_revision_v2/guardian_birth.png`: fallen cursed body with the luminous Guardian appearing beside Red.
- `guardian_revision_v2/together_wide.png`: Red and Guardian quietly face the Keep under the pale moon.

Both remain unchanged at 1672×941. `ending_guardian_revision_v2_manifest.json` records matching source/import SHA-256 hashes. They use the existing aspect-preserving presentation and gentle zoom. The other panels, original story sequence, dialogue, manual Continue/Skip controls and temporary one-hit KO setting are retained.

The pale moon and transitional depiction of both the fallen body and Guardian are retained as supplied and approved for this pass. Earlier Guardian Touch artwork is still assigned separately.

Previous assignments and this guide were backed up to `.godot/local_backups/ending-two-panels-20261013-223530/`. Godot editor import completed; no new gameplay playback test was run for this texture-only replacement.
## Curse attack cinematic revision

The curse now uses separate traveling and impact effects: Keep launch → 75% travel toward Red → close side cut → brother intercepts → supplied eight-frame impact → sacrifice panel. The configured launch-to-panel presentation is approximately 2.8 seconds. Continue waits until the action completes; Skip remains available.

See [curse cinematic implementation and source-frame limitations](ending_curse_cinematic.md). Prior preview GIFs do not include this change. Godot import passed; no new gameplay playback was run for this revision.
## Longer live lily transformation

The fallen Wolf now has a roughly 6.3-second in-engine transformation before Guardian Birth Artwork appears: circling lily trails and moonlight build → cursed body gradually fades as the silver spirit forms → trails finish fading → picture transition. The existing eight lily frames are reused without PNG edits. Continue waits until this automatic transformation completes; Skip remains available.

See [timing and Inspector controls](ending_lily_transformation.md). Prior GIFs do not show this revision. Godot import passed; no new gameplay capture/test was run.
## Sacrifice picture cuts at impact

The sacrifice illustration now appears 0.12 seconds after projectile contact, under the impact flash and sound. The Wolf holds a forward shielding/lunge pose until the picture is shown. His fallen death pose is assigned only after the sacrifice picture has been held/advanced, leading into the farewell.

The impact-to-picture transition is immediate; the ordinary 0.35-second panel transitions remain. **Sacrifice Picture Delay** on the ending root is tunable between 0.08 and 0.20 seconds.

Pre-change backup: `.godot/local_backups/ending-impact-cut-20261013-234313/`. Godot import passed (`ending_impact_cut_import.log`); no new playback test was run for this timing change.
## Frozen projectile hit effect cleanup

A Crescent Slash killing blow could enter the ending synchronously inside its damage callback. The ending paused the gameplay tree, after which the projectile continued into its impact animation. That paused projectile could remain visible at its original world position during Red's approach and subsequent manual dialogue holds.

Ending entry now immediately hides and queues all `red_projectiles` for safe removal before pausing. Crescent's impact callback returns if the ending has already queued it for deletion, preventing impact playback or a new hitstop after that handoff. Normal non-ending projectile impacts retain their existing behaviour.

Backup: `.godot/local_backups/ending-hit-effect-cleanup-20261013-235414/`. Godot editor import passed (`ending_hit_effect_cleanup_import.log`); no gameplay reproduction/test was run for this fix.