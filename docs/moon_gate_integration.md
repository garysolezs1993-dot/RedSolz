# Moon Gate visual states

The gate now uses `moon_gate_all_clean_assets_for_codex.zip`. All 19 extracted
files, including the three review sheets, match the ZIP byte for byte. No PNG
was cropped, resampled, painted over, or replaced with a preview sheet.

| Moon Seals | Visual | Playback | Entry |
| --- | --- | --- | --- |
| 0/3 | `moon_gate_inactive_static_clean.png` | Static, stopped | Locked |
| 1/3 | `moon_gate_awakening1_00.png`–`04.png` | `awakening_1`, 6 FPS loop | Locked |
| 2/3 | `moon_gate_awakening2_00.png`–`04.png` | `awakening_2`, 7 FPS loop | Locked |
| 3/3 | `moon_gate_fully_awakened_00.png`–`04.png` | `fully_awakened`, 8 FPS loop | Open |

## Integration

- `scripts/stage_gate.gd` retains its objective manager, interaction router,
  E/Up/Enter entry checks, scene fade, and Stage 2 health carryover.
- `scenes/moon_gate_visual.tscn` and `scripts/moon_gate_visual.gd` provide a
  reusable visual component. Animation changes only when the seal count changes.
- The procedural placeholder arch, runes, rings, and motes have been removed.
  Dormant is genuinely static. Existing audio gives brief progress feedback,
  with a subtle brightness pulse; final activation has the stronger pulse.
- Saved progress restores the matching state without replaying activation.
- The distant glimpse uses the same visual component at a smaller, dimmer scale,
  following the same objective progress. Its existing visibility/fade behavior
  remains in `scripts/stage1_journey.gd`.
- Nearest filtering preserves the supplied art. An unshaded material keeps
  the gate's authored portal energy readable under the selective forest lighting.

## Inspector tuning and export mismatch

Select **StageTwoGate** in the running scene's Remote tree:

- `gate_art_scale`: **0.55**, a uniform overall gameplay size. This fits the
  entire gate at the existing Stage 1 camera zoom of 1.35.
- `gate_floor_offset`: **(0, 110)** relative to the existing interaction node
  at (9840, 390), placing the stone sill on the platform at **(9840, 500)**.

Select **GateStateVisual** for its playback speeds and source alignment settings.
Awakening 1 brightness starts at **0.78**, Awakening 2 at **0.90**, and the final
state uses the full authored brightness, keeping the early loops restrained.
Permanent defaults live near the top of the two scripts above; the gate is
created dynamically by `scripts/stage1_layout.gd`.

The pack does **not** have identical canvases: dormant is **1254×1254**, and
the fifteen looping frames are **512×800**. The stone sill also appears at
different source Y coordinates in the three sets. Applying identical raw
transforms would therefore cause a large dormant-to-awakening size jump and
vertical drift.

For this first pass, fixed **Godot-side** source calibration maps the dormant
gate's full width to the animated gate's approximately 432px width. The source
anchors are (627, 945), (256, 520), (256, 534), and (256, 538). Each maps to the
same world-space stone sill. No transform changes per frame; every animated
frame uses the same 0.55 scale. The dormant canvas factor is 432/1254 before
that shared overall scale. Every complete texture, including padding, is drawn.

**Artwork limitation:** the illustrated arch/tree proportions and details
change slightly between exports and within the loops. Fixed alignment removes
transform jumps but cannot make different drawings geometrically identical.
For completely immobile stonework, future exports should reuse an identical
gate base and animate the portal/glow on a separate layer, with a common canvas
and stone-sill anchor. No additional art is needed to use this implementation.

## Gameplay previews

These are actual 960×540 gameplay captures at camera zoom 1.35, with Red beside
the gate and the same camera position in every state:

- [Dormant](previews/moon_gate_00_dormant.png)
- [Awakening 1](previews/moon_gate_01_awakening_1.png)
- [Awakening 2](previews/moon_gate_02_awakening_2.png)
- [Fully awakened](previews/moon_gate_03_fully_awakened.png)
- [Animated comparison of all four states](previews/moon_gate_states.gif)

`tools/capture_moon_gate.gd` generates the four captures and a sequence of
rendered gameplay frames. Capture and tests use separate save files; they do
not modify the player's save.

## Validation

- `test_moon_gate_visual.gd`: **118 checks, 0 failures**. All sources/canvases,
  frame counts, loop playback, repeated-progress notifications, fixed floor
  anchors, locking E/Up/Enter at 0/1/2 seals, restored state, E entry at 3/3,
  and Stage 2 health preservation.
- `test_moon_seal_progression.gd`: **59 checks, 0 failures**. Existing seal,
  checkpoint, Wisp, route, save, migration, and Up-to-Stage-2 behavior.
- `test_seal_encounters.gd`: **33 checks, 0 failures**. Guard encounters,
  cinematics, later guidance, and final gate awakening.

Total: **210 checks, 0 failures**. The rendering log contains the existing
Camera2D physics interpolation warning; no script/runtime errors.

Original gate scripts were backed up before implementation at
`.godot/local_backups/moon-gate-20261012-000628/`.
