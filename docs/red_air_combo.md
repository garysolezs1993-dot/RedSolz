# Red's air combo and Rising Slash launcher

Implemented locally on 11 October 2026 from the supplied brief and
`red_air_combo_master_pack_for_codex.zip`, after reading `README_FOR_CODEX.txt`.
The existing Red player script, hitbox and ground combo remain the foundation.

## Controls and flow

- Jump, then C / left click: `air_attack_1`.
- Further presses during frames 04-06 chain into `air_attack_2` and
  `air_attack_3`. Early presses buffer for the existing 0.25 seconds.
- Up + C: Rising Slash. At strike frame 02 it launches Red upward.
- During Rising Slash, press C again; a buffered press starts Air Attack 1
  from recovery frame 04 while Red is still ascending. Holding Up does not
  prevent this follow-up.
- No next press ends the current swing and releases to normal jump/fall.
- The third hit cannot queue a fourth normal air attack, but Down + C can
  chain into Downward Slash at frames 06–07 or during finisher recovery.
- Down + C while airborne starts the new committed downward slash; during
  air hits 1/2/3 it queues the dive. See
  [Downward Slash integration](red_downward_slash.md).
- Ground combo, R Crescent, dash, double jump and damage values remain.

| Attack | FPS | Active damage frames | Damage |
| --- | --- | --- | --- |
| Air 1 | 12 | 02-04 | 20 |
| Air 2 | 12 | 02-04 | 20 |
| Air 3 | 10 | 02-05 | 20 |
| Rising Slash | existing 16 | existing 02-04 | existing 20 |

## Movement and finite airtime

Rising Slash uses Red's existing negative-Y velocity/gravity conventions.
`rising_slash_launch_speed` defaults to 440; this is an exported tuning value.
The ground launcher consumes the ground jump rather than granting another one.
The existing light-enemy launch behavior is retained.

`air_combo_hang_enabled` now defaults to true. Starting an air attack stops
vertical motion at Red's current height. All three attacks hold that height
through their animations, including the finisher. Horizontal movement is also
locked for every air attack: incoming X velocity is cleared at the start, and
held left/right input cannot steer or move Red through a combo. The lock only
applies during the air attack and its 0.16s/0.24s recovery; normal movement
returns after recovery or cancellation.
Dash (L/Shift) can cancel the attack or recovery when its 1.5s cooldown and
one-air-dash allowance permit it. Held left/right
selects dash direction, while ordinary steering remains blocked during attacks.
Normal gravity resumes after the current swing ends without a follow-up, after
the finisher, or when an attack is cancelled. Hurt retains its normal knockback.
Actual contact with a platform still cancels the air combo and enters landing.

For comparison, disabling `air_combo_hang_enabled` in the Player inspector
restores the earlier falling combo: Air 1/2 use 0.45 gravity, Air 2 gives a small
upward stall (`air_followup_stall_speed`, default 90), and Air 3 applies its
normal gravity/downward impact push. The launcher itself remains unchanged.

Only one normal air string and one Rising Slash vertical boost are available
per airborne period. Finishing or interrupting an air string does not refill
that allowance or Red's jump count. Additional aerial Rising Slash animations
still attack, but grant no extra boost until landing. Grounded Rising Slash can
launch normally again after landing.

Landing during any air step clears its hitbox, index, queued input and VFX.
Steps 1/2 use 0.16s recovery; step 3 uses 0.24s recovery, followed by the existing
landing/idle flow. Hurt and death cancel the same air state/queue/effect.

## Assets and synchronization

Character and VFX PNGs are copied byte-for-byte to:
`assets/game_assets/red_gothic_replacements/air_combo_master/`.
The pack README and manifest SHA-256 hashes preserve provenance. No cropping,
trimming, recoloring, automatic centering or individual resizing is applied.
Each character canvas remains 512x512, with a fixed pivot and scale throughout
its clip. Air 1 uses 0.10 scale; Air 2/3 use 0.09. The supplied hood/head/body
were drawn larger than the idle/jump art, so these whole-clip scales reduce the
visible size jump (previously all three used 0.105). No individual frame is
automatically fitted or resized, and body/hitbox dimensions remain unchanged.
The old standalone `attack_air` clip and legacy air effect are inactive.

Runtime hierarchy:

```text
Player
  Visual
  VFXAnchor
    AttackVFX       (ground combo)
    AirAttackVFX    (air combo)
    DownwardSlashVFX (dive and landing impact)
  AttackHitbox
  AttackEffect      (Rising/Crescent)
```

The character frame and frame progress drive matching AirAttackVFX frame N
directly. The effect has no independent playback clock and stays attached as
Red moves vertically. Only one attack effect layer is visible at a time.
Scale is initialized before entering the scene tree, and interpolation resets
after visibility changes, preserving the first-attack scale-flash fix.

| Air step | Right-facing VFX anchor | VFX canvas | VFX scale |
| --- | --- | --- | --- |
| 1 | (20, -5) | 1536x1536 | 0.035 |
| 2 | (20, -8) | 1536x1536 | 0.035 |
| 3 | (14, 12) | 1536x1536 | 0.04 |

Anchors mirror X for left-facing attacks and remain fixed through each swing.
No physics movement is applied to fit the effect artwork.

### Source limitations

The pack is usable, with real transparency and complete readable poses in most
frames. Air Attack 3 character frame 07 contains a small disconnected sword
fragment at the upper-right edge. Some sword tips/effect trails reach or are
cut by source canvas boundaries, notably Air 3 character frame 03. These remain
as supplied because the brief explicitly prohibits cropping/altering the PNGs.
Regenerated frames can replace them later without changing combat logic.

### Review of `air_attack_vfx_clean_cut_master_pack.zip`

The new VFX-only archive has 24 RGBA 512x512 PNGs with real alpha transparency.
It does not resolve clipping: 18 frames still have visible pixels (alpha > 32)
at a canvas edge. In particular, Air 1 frame 03 is cut on the left; Air 2
frames 04-06 have large truncated arcs at the sides; Air 3 frame 04 reaches
the top/right. The contact sheet in `.godot/red_air_review/new_vfx_review.png`
shows the complete supplied canvases. No runtime crop caused these cuts.
This archive was rejected; it is not the active source. Red's character frames
are independent of the VFX replacement.

### Active VFX: clean frames for Air 1/2, redone clean frames for Air 3

The current ZIPs replace only the 24 air VFX PNGs. The original character
frames remain active. All three current effects have 1536x1536 canvases.
Every frame has real transparency and clear outer canvas margins. All three
sets load as full PNGs, without an AtlasTexture or runtime crop. A fixed 0.035
scale compensates for the 3x larger canvases of attacks 1/2, retaining their
previous 53.76px canvas display width and avoiding oversized effects.

Attacks 1/2 use `air_attack1_vfx_clean_frames_for_codex.zip` and
`air_attack2_vfx_clean_frames_for_codex.zip`. Attack 3 now uses
`air_attack3_vfx_redone_clean_for_codex.zip`. Its eight frames have clear
transparent margins and no obvious chopped neighboring fragments in review.
The earlier 512px third pack, with hard-cut fragments, is superseded. Attack 3
uses 0.04 scale (previously 0.12 at 512px), preserving a 61.44px display canvas.
The anchor, animation timing, damage, character size and movement lock remain.
The third-pack review is `.godot/red_air_review/attack3_redone_review.png`;
`.godot/red_air_review/new_three_packs.png` records the earlier combined review.
`tools/import_red_air_vfx.py` validates all 24 files before copying and records
their archive, source size and SHA-256 hash in `source_manifest.json`.

## Verification and tuning

`tools/tests/test_red_air_combo.gd` uses the complete actual Stage 1 scene,
including its player/terrain. Checks cover jump and launcher strings, stopping
after hits 1/2, buffered ascending follow-up, both facings, mid-combo landing,
finite air/jump allowances, no repeated launcher boost, 20 damage once per
swing, moving VFX, ground attacks and hurt/death cancellation.

Twelve native Stage 1 captures show all three attacks facing both directions
from jumps and from Rising Slash. `test_red_combo_startup.gd --air-attack`
checks the first 20 rendered VFX frames at both 60 and 10 physics ticks/second.
Existing ground, movement, combat/death, directional, Crescent, crouch and
retained skill regressions pass. Logs/captures are in `.godot/red_air_review/`.
Final totals: 158 air-combo assertions passed in both headless and rendered
runs, plus 221 existing regression assertions (379 headless assertions total).
The two cold-start runs each passed 20 rendered size checks.
Existing ObjectDB/resource cleanup warnings still appear at some test exits.

### Latest VFX, movement lock and size verification

The three replacement archives pass byte/hash checks for all 24 active VFX;
all outer edge pixels are fully transparent. All 24 character PNGs still match
the original character archive. Godot imports the new dimensions successfully.
The updated actual Stage 1 air check passes 232 assertions in headless and
rendered runs, including held steering through every step in both directions,
incoming horizontal momentum, movement resuming after an attack, reviewed
character scales fixed across all frames, correct VFX canvases and frame sync.
All 221 existing regression assertions pass (453 headless assertions total).
Cold startup still passes 20 rendered size checks at both 60 and 10 physics
ticks/second. The 12 Stage 1 captures were refreshed with the new VFX/scales.

The subsequent redone Attack 3 pack also passes all 232 air assertions in
headless and rendered Stage 1 runs. All 24 current effect PNGs match their
ZIP bytes/hashes and have fully transparent outer edges. The refreshed strike
and finisher fade captures show the new diagonal effect in both directions.
Logs are `attack3_headless.log` and `attack3_render.log` in the review folder.

### Hang update verification (11 October 2026)

The updated air check covers constant height through all three swings and the
finisher recovery, attacks begun while descending, horizontal input, gravity
after cancellation, platform contact, hurt/death interruption and the optional
old falling mode. It passes 183 assertions headless; the 221 existing ground,
movement, combat/death, directional, Crescent, crouch and legacy assertions also
pass (404 total). Both cold-render checks pass 20 frames at 60 and 10 physics
ticks/second, preserving the startup scale-flash fix.

Tune in `scripts/red.gd`: launcher speed, follow-up stall, gravity scale,
hang enable switch, finisher push and combo window/buffer. Stall,
gravity scale and finisher push only affect the previous non-hanging mode.
Fixed artwork/VFX profiles and
FPS live in `scripts/red_animation_library.gd`. Reimport with
`tools/import_red_air_combo.py` for the original character bundle and then
`tools/import_red_air_vfx.py` for the three current VFX-only packs.
