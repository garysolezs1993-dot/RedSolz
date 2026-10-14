# Cursed Wolf ending: restored original flow

[Watch the current ending with final artwork](previews/ending_final_art_full_run.gif)

The final art pack is now assigned to sacrifice, farewell, Guardian birth/touch and the closing wide shot. See [current integration and review notes](ending_final_art.md). The framework details and original capture evidence below describe the earlier sprite-only pass.

## Trigger and flow

Stage 2 now instances `scenes/EndingCutscene.tscn`. The Cursed Wolf emits `defeated` after its normal zero-HP shutdown. The ending retains the body instead of letting its collapse callback fade/free it, and suppresses the old zero-HP victory-pose handoff. Combat behaviour before zero HP is unchanged.

The full rendered sequence reaches **Prototype Complete in about 56 seconds**:

1. Lock Red and boss processing, hide HUD/region labels, pause gameplay and fade boss music.
2. Settle actors onto a snapshot of actual terrain if the final hit occurs in the air, then play all eight existing collapse frames.
3. Brief fade to safely stage the conversation on the main arena floor. Red approaches; camera moves closer.
4. Red: `Brother...`
5. Brother: `...You never listen.` / Red: `You said you'd come back.` / Brother: `You kept the light on.` / Red: `Of course I did.`
6. The Keep reacts; a crimson root strike aims toward Red. Brother: `Red... move!`
7. Existing pounce pose/tween places him between Red and the strike. A crimson-white flash gives way to the fallen wolf and safe Red.
8. Brother: `See...?` / `I came back.` / Red: `Idiot...` / Brother: `Take care of it for me.`
9. Quiet lily glow; physical wolf dissolves with moon-white petal fragments as a silver Guardian placeholder appears.
10. Guardian approaches Red, pauses near her hand, then faces the Keep with her.
11. Wide camera shot: `The curse remains.` / `And the Silent Keep still waits.`
12. Fade to `scenes/PrototypeComplete.tscn`: game title, PROTOTYPE COMPLETE, Thank you for playing, and **Return to Title**.

The completion card waits for the player; it does not immediately jump to the title. The preview selects Return to Title after a short hold to demonstrate the handoff.

## Placeholder visuals and future replacement

No final ending artwork or new Guardian gameplay mechanics were created. The framework uses existing Red/wolf sprites, collapse and pounce poses, a simple world-space Keep/moon drawing, a visual-only root line/flash, and a fixed wolf texture recoloured silver by a runtime shader. Guardian has no collision, enemy group, attack logic, summon ability or player-follow controller. The source PNGs remain untouched.

The current sprite set has no bespoke hand-reaching, lucid-eye, weakened-lunge or nuzzle animation. Existing idle/crouch/pounce poses and gentle transforms stand in for these beats while pacing is reviewed. The optional illustrations can replace them later.

Select **EndingCutscene** in `scenes/stage2_boss.tscn`, or open its own scene root. Eight optional Texture2D slots correspond to:

| Inspector slot | Optional auto-loaded file |
| --- | --- |
| Lucidity Artwork | `ending_01_lucidity.png` |
| Keep Reacts Artwork | `ending_02_keep_reacts.png` |
| Sacrifice Artwork | `ending_03_sacrifice.png` |
| Final Words Artwork | `ending_04_final_words.png` |
| Lily Artwork | `ending_05_white_lily.png` |
| Guardian Birth Artwork | `ending_06_guardian_birth.png` |
| Guardian Touch Artwork | `ending_07_guardian_touch.png` |
| Together Artwork | `ending_08_together.png` |

Default folder: `assets/cutscenes/ending/panels/`. Explicit Inspector resources take precedence; missing files retain the in-engine shot without missing-resource errors. TextureRect preserves aspect ratio. Dialogue stays in separate Godot labels.

**Guardian Texture**, **Lily Texture** and **Curse Strike Texture** are additional visual-only replacement slots. Guardian/strike display scales are Inspector controls. The current lily fragments reuse the complete existing `lily_trail_07.png`, recoloured moon-white in Godot and faded independently; this is a bounded sequence of one-off effects, not a continuous Wisp trail.

## Timing and audio

The root exposes Dialogue Hold, Collapse Hold, Approach Duration, Quiet Hold, Guardian Formation Duration, Guardian Touch Duration and Wide Hold. Defaults favour a quiet reading beat, with the existing death clip playing at the boss's exported Death Animation FPS. Fades/holds reuse `story_transitions.gd` and run during the world pause.

Boss music and existing combat SFX fade/stop initially. Quiet breathing uses `wolf_huff.wav`. The existing `promise_to_rise.wav` supplies a subdued ending context at -29 dB, then the completion card at -20 dB. Return to Title restores its existing music context. Audio still respects user volume settings; no audio files were changed.

## Skip, safety and story state

Continue uses Enter/Space/E/controller A or the bottom-left button. Dialogue and stable story-artwork beats now wait for Continue by default; Auto Advance is optional on the scene root. Skip uses Escape/controller Start/B, plus the bottom-right button. Enter/Space do not skip the ending. Skip cancels the current cinematic tween, fades to black and uses the same completion handoff as watching the scene. It goes to Prototype Complete, not straight back to gameplay or title.

During the ending, the world is paused, actor processing is gated, Red is protected from stray damage, and presentation effects have no damage receiver/attack callbacks. The boss's existing death shutdown disables its attacks/hurtbox and removes it from enemies. It is freed only at completion/Skip, under black. A simultaneous Red defeat keeps the normal game-over path instead of starting the ending.

Completion is saved through the existing objective dictionary as `prototype_complete` under Stage 2. This does not change the save format or respawn anchor. **Continue after a completed prototype opens the completion card**; **Start Game** clears objectives normally and begins a fresh journey. The ending/complete screens clear the world pause and transient ending flag during handoff.

## Rendered review evidence

Backup: `.godot/local_backups/ending-framework-20261013-184307/` (boss script, UI, GameSession, AudioDirector and Stage 2 scene).

Editor import completed without script errors. Full and Escape-Skip captures trigger the real `take_damage()` zero-HP path, using separate isolated journey files and muted capture audio. Logs record `boss HP=0; retained=true; old victory=false`, then `paused=false; story complete=true; ending flag=false; boss nodes=0`, followed by a successful Return to Title with title music. No automated tests were added or run for this framework.

Logs: `ending_framework_import.log`, `ending_framework_capture.log`, `ending_framework_skip_capture.log`. The full sequence reaches the completion screen around frame 3355 at 60 FPS; its 239-frame GIF at 4 FPS includes the completion card and Return to Title. Existing camera interpolation warnings remain.

- [Sibling exchange](previews/ending_lucidity.png)
- [Guardian birth](previews/ending_guardian_birth.png)
- [Together facing the Keep](previews/ending_together.png)
- [Prototype Complete](previews/ending_prototype_complete.png)

To review live, enter Stage 2 through the Moon Gate and defeat the Cursed Wolf. The former F7 testing shortcut has been removed.

## Restored first version

At the user's request, the original ending controller and scene were restored from `.godot/local_backups/ending-hybrid-20261013-192900/`. The restored controller matches that backup byte-for-byte. The later revision was preserved in `.godot/local_backups/ending-return-original-20261013-204659/` before restoration. Its extra recognition/memory sequence and thirteen-panel configuration are no longer used by the ending scene.

The linked original framework preview and full/Skip evidence above belong to the original version; no new playback test was run during this restoration. The old eight-panel filenames are active again.

[Detailed generation brief for the restored ending](ending_asset_generation_brief.md) includes shot compositions, shared style requirements, priorities and optional sprite/VFX exports.
