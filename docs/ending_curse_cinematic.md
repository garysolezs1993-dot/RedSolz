# Ending curse attack cinematic

## Sequence

The Keep reaction and original warning (`Red... move!`) lead into a short automatic cinematic:

1. **Wide shot:** camera includes both the visible Keep and Red. A separate narrow curse projectile launches from the Keep's position, aimed at a snapshot of Red's upper body.
2. **Travel:** it advances only 75% toward Red in 0.78 seconds. There is no wide-shot arrival, damage or impact burst.
3. **Close side cut:** camera switches closer while the projectile is still mid-flight. Red stays stationary; the weakened brother starts behind her and lunges into the Keep-facing side of her position.
4. **Interception:** the projectile resumes for a short 0.18-second approach, ending at the brother's upper body, about 170 world pixels on the Keep-facing side of Red.
5. **Impact:** `cursed_attack_00.png` through `cursed_attack_07.png` begin playing once at that contact point, at 16 FPS. Brief shake, a small crimson-white flash and the existing impact sound emphasise the hit. The Wolf holds a forward lunge/shielding pose.
6. **Immediate sacrifice artwork:** 0.12 seconds after contact, cut directly to the blocking illustration under the flash, carrying the impact sound across it. The remaining world-space burst frames finish behind the illustration. Hold the picture for Continue, then place the Wolf in his fallen pose for the farewell, lily, Guardian and closing scenes.

Default launch-to-visible sacrifice artwork timing is approximately **1.53 seconds**, with the picture appearing **0.12 seconds after contact**. This is computed from configured timings, not measured playback. It excludes the player's manual reading pause on the warning dialogue. Continue stays disabled during travel/interception/impact and becomes available again on the stable sacrifice panel. Skip remains available throughout. Ordinary panel transitions retain their existing fades; only the impact-to-sacrifice cut is immediate.

## Separate travel and impact visuals

`scripts/ending_curse_projectile.gd` draws a compact traveling crimson lance with a short trailing streak. This is a cinematic Node2D, not a gameplay projectile. An optional Curse Strike Texture can replace the travel drawing.

The supplied eight frames are used only by a separate AnimatedSprite2D for the impact. They are not looped for travel or attached to a projectile in the wide shot. Both effects live under the ending's visual-only world node and have no collision shape, hitbox, damage callback or combat AI. The existing ending pause and invulnerability handling apply.

The close-shot Wolf is temporarily drawn behind Red so his broad sprite does not hide her. Its draw order is restored if the cinematic is aborted externally. On Skip/completion, the traveling effect is hidden and the impact is stopped/hidden before the existing scene handoff removes all ending nodes.

## Imported frames and alignment

Source ZIP: `cursed_attack_clean_for_codex.zip`.

Imported folder: `assets/cutscenes/ending/curse_impact/`.

All frames are transparent RGBA PNGs and were extracted unchanged. `docs/ending_curse_impact_manifest.json` records their dimensions and hashes.

Their canvas sizes vary from 188×558 to 438×724. Their bright-core positions also vary considerably. The controller uses measured per-frame bright-core coordinates and updates AnimatedSprite2D.offset so each core remains at the same world-space contact point. Horizontal flipping reverses the alignment correctly for an incoming attack from the right. Scale is constant across all eight frames; the PNGs are not independently resized or cropped.

**Source limitation:** some effect tips already meet/cut through the left or right source-canvas boundary. Godot alignment can remove pivot drift but cannot recover missing artwork. The supplied pack is used as requested, with no additional crop. A future replacement could export all frames onto a larger shared padded canvas with one fixed impact-core anchor.

## Inspector tuning

On the EndingCutscene root:

- Curse Travel Fraction: 0.75, constrained to the requested 0.70–0.80 range.
- Curse Travel Duration: 0.78 seconds.
- Curse Intercept Duration: 0.35 seconds.
- Curse Impact FPS: 16.
- Curse Impact Scale: 0.24.
- Sacrifice Picture Delay: 0.12 seconds after contact, tunable from 0.08–0.20 seconds.

Impact origin and actor staging are currently fixed relative to Red and the brother for this arena. The artwork assignments, manual Continue/Skip controls, and saved completion handoff are retained. Boss combat and the temporary one-hit KO mode are unchanged.

## Backup and import

Backup: `.godot/local_backups/ending-curse-cinematic-20261013-224455/` contains the pre-change controller, scene, capture helper and final-art guide.

Godot editor import completed with no reported script errors (`docs/ending_curse_cinematic_import.log`). No new gameplay test/capture was run for this revision. Existing preview GIFs predate this cinematic. The capture helper's expected phase order was updated so a future authorized playback review includes launch, interception and impact.
