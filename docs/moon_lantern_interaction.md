# Moon Lantern checkpoints

All three Stage 1 checkpoints now use the same reusable scene:
`scenes/forest_checkpoint.tscn`. Existing checkpoint IDs, save history and
respawn positions are preserved. No boss camera setting was changed.

## Flow

- Approach a grounded, unlit lantern: Red faces it and holds
  `lantern_interact_01`. Gameplay controls are locked and the camera eases
  from the current gameplay zoom to 1.55. The shared interaction router shows
  `E — Light Moon Lantern` and `Esc — Cancel`.
- Escape cancels the preview. Red can move away; that lantern only offers the
  preview again after she leaves its interaction range and returns.
- E plays Red's frames 02–07 at 7 fps and gently aligns her to the nearest
  side's marker, by at most 16 world pixels.
- Red frame 04 starts lantern activation frame 00, registers the checkpoint,
  heals once, and plays the existing confirmation sound.
- The eight lantern activation frames play once at 10 fps, overlapping Red.
  Red holds the final pose briefly if the lantern is still finishing.
- The lantern then loops its five active frames at 4 fps. Red returns to idle,
  movement unlocks, and the exact previous camera zoom/offset is restored.
- Lit lanterns do not replay the interaction or heal again.

Escape cancels the waiting pose only. Damage, death, losing ground/range,
scene transitions and removal of a lantern release the sequence safely.
An interruption before contact leaves it unlit. An interruption after contact
preserves the saved checkpoint and lets its activation finish into active idle.

## Where to tune

| File | Controls |
| --- | --- |
| `scripts/forest_checkpoint.gd` | Camera target (1.55), zoom durations (.4/.35 s), alignment limit/speed, lantern animation fps, art scale (.06), per-frame ground lines |
| `scenes/forest_checkpoint.tscn` | `InteractionAnchor` (left side), `RightInteractionAnchor` (right side) |
| `scripts/moon_lantern_sequence.gd` | Waiting/confirmed states, contact frame (04), alignment, camera restoration, interruption cleanup |
| `scripts/red_animation_library.gd` | Red clip fps (7), fixed display scale (.04), per-frame boot anchors |
| `scripts/interaction_router.gd` | Shared E prompt/selection and preview callback, reusable for future objects |

The interaction range is centered 10 pixels right and 15 pixels above the
lantern origin, with half extents (32, 20). Preview requires Red to be grounded.
The two side markers keep her reach directed toward the off-center lamp.

## Assets

21 individual PNGs were copied **byte-for-byte**, without cropping or resizing:

- `assets/game_assets/moon_lantern/red/`: 8 Red frames (1536×1536).
- `assets/game_assets/moon_lantern/activation/`: 8 activation frames (1254×1254).
- `assets/game_assets/moon_lantern/active/`: 5 active frames (1254×1254).

Preview sheets are not used in gameplay. Rendering uses nearest filtering.
Fixed scales and authored vertical anchors accommodate the exports' differing
canvas placement; low-alpha residue is excluded when selecting boot contacts.
All source artwork remains intact. The middle lantern is drawn after its low
platform so the new taller artwork is visible; Red remains in front.
Decorative forest lamp posts/light are hidden only where they overlap an actual
checkpoint, preventing the old orange lamp from showing through the new art.

Integration file snapshots are in `.godot/moon_lantern_review/before/`.

## Verification

`tools/tests/test_moon_lantern.gd` runs in the actual Stage 1 scene with
`--presentation-test`, which isolates the user's saves/settings. It checks all
three lanterns, held/confirmed frames, both facing directions, timing, locks,
Escape, range exit, one-time healing/save, repeat inputs, looping, camera
restoration, respawn, damage before/after contact, death and transitions.
Rendered captures and logs are in `.godot/moon_lantern_review/`.

Results: 69 dedicated checks passed headless and with the renderer. Ground
combo (109), air combo (232), Downward Slash (177), chapter (54), optional
routes (37), and presentation (59) regressions also passed: 737 checks total.
The existing engine interpolation notice and test teardown resource warnings
remain; there were no script parse/runtime errors.

Existing checkpoint tests now wait for contact rather than expecting an instant
save on E. The traversal test uses Escape when passing an unlit lantern. Its
retractable-spike fixture was moved away from the preview range.

To try the entire sequence, choose **New Game**. Continue/Retry intentionally
keeps previously activated lanterns lit and does not replay their activation.
