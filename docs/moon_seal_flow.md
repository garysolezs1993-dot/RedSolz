# Moon Seal shrine and spirit flow

All three seals now share one interaction/animation implementation. The previous
order, guardian requirements, E interaction, saved objectives, gate states and
Stage 2 transition are preserved. Progress commits **after** the activation
animation, rather than immediately when E is pressed.

## Art and states

| Shrine state | Supplied source | Playback |
| --- | --- | --- |
| `dormant` | `Gothic Crescent Moon Shrine.png` | Static, gently darkened |
| `interact_ready` | `moon_seal_interact_00.png`–`07.png` | 8-frame loop, 6 FPS |
| `activating` | `moon_seal_activation_00.png`–`07.png` | 8 frames once, 6 FPS, about 1.33s |
| `activated_idle` | `moon_seal_idle_00.png`–`04.png` | 5-frame loop, 5 FPS |

All **25 source files** (22 runtime PNGs and 3 review sheets) match their supplied
ZIPs/static original byte for byte. Preview sheets are not used as animation
textures. No source art has been edited, resized or cropped.

The canvases differ: dormant 1122×1402, interaction 362×543, activation
1254×1254, and idle 460×614. Godot-side calibration gives the shrine a shared
**110px gameplay height** and anchors its roots/base to the existing platform.
Activation also has fixed authored frame offsets to compensate for its 30px
source floor drift. All textures retain their complete canvas and real alpha.
The illustrated proportions change slightly between sets; alignment cannot
make differing drawings geometrically identical.

The shrine artwork has physics interpolation **disabled locally**. Texture
changes happen immediately; interpolating the compensating scale separately
would briefly display the large dormant canvas at the interaction clip's scale.
The project/player physics interpolation setting is preserved.

## Local spirit and activation

- A faint local Wisp appears only near an unfinished shrine. It uses the idle
  Wisp assets, no movement trails, and does not allocate a trail pool.
- Entering the interaction range plays the shrine's interaction animation and
  makes the spirit brighter. It gently visits the crescent, rune and roots.
- Leaving before pressing E returns to dormant. Proximity never activates.
- Existing prerequisite/guardian explanations remain in the E prompt.
- E on an eligible shrine locks normal movement, jump, dash and attacks.
  Red retains her current character art. Gravity and platform collision still
  run; damage or loss of support cancels an unfinished activation safely.
- The spirit pauses, circles the rune once, then merges into the central rune
  around frames 4–5, matching the activation surge.
- On animation completion, save the objective, enter `activated_idle`, remove
  the local spirit, restore movement and wait **0.5s** before releasing guidance.
- Repeated E cannot restart the completed shrine or advance progress twice.

## Released guide

The guide appears from the shrine rune, using the existing Wisp appearance,
idle, move, arrival and world-space afterimage effects. It exposes `guide_spawn`,
`guide_move`, `guide_arrive` and `guide_disappear`; the local spirit exposes
`seal_hover` and `seal_react`.

- **Seal 1:** camera/world pause tour toward the Root Cellar entrance. The
  actual guide cinematic lasts about **5.5s**, then restores Red's camera and
  control. Escape can skip it as before.
- **Seal 2:** retains the slower short guidance cue and longer landmark hover
  toward the cellar exit / upper-ruins route. No camera takeover.
- **Seal 3:** releases a short guide along the quiet descending route toward
  the Moon Gate. The existing gate awakening remains the destination payoff.

Only one global guide runs at once. A new seal activation cancels any existing
contextual cue, and local hover spirits are hidden during global guidance.
Moving guide afterimages remain stationary where spawned, live about **0.5s**,
fade independently over their final **0.2s**, and finish naturally after the
guide stops or disappears. There is no permanent follower or map arrow.

Completed shrines restore directly into their idle loop on retry/continue,
without an orbiting spirit, activation replay or another guide release.

## Files and controls

- `scripts/moon_seal.gd`: shared shrine states, eligibility, local spirit,
  activation lock, delayed release and safe interruption.
- `scripts/moon_seal_visual.gd`: frame sources, alignment, shrine height and FPS.
- `scripts/moon_wisp_guide.gd`: released guide, configured routes/camera and
  existing contextual/chapel discovery cues.
- `scripts/stage1_layout.gd`: per-seal `full_cinematic`, `guide_route` and
  guardian configuration. `guide_target` can override a target without a path.
- `scripts/stage1_journey.gd`: discovery crest lifted above the taller new shrine;
  its smaller entrance rune stays at the same world position.
- `scripts/red.gd`: small early interaction-lock hook and cancellation cleanup.

Select a seal in the Remote Inspector for `shrine_height`, `guide_release_delay`,
`full_cinematic`, `guide_route` and `guide_target`. The child `SealVisual` exposes
playback speeds. Permanent defaults/configuration are in the scripts above.

## Gameplay previews

- [Animated first-seal flow](previews/moon_seal_connected_flow.gif)
- [Dormant](previews/moon_seal_1_dormant.png)
- [Interaction ready](previews/moon_seal_1_ready.png)
- [Activation surge](previews/moon_seal_1_activation.png)
- [Completed shrine](previews/moon_seal_1_activated.png)
- [First guide release](previews/moon_seal_1_release.png)
- [First guide flight](previews/moon_seal_1_guide.png)
- [Cellar shrine](previews/moon_seal_2_ready.png)
- [Final guide toward the gate](previews/moon_seal_3_guide.png)

`tools/capture_moon_seal_flow.gd` produces 18 gameplay captures at the existing
960×540 viewport and 1.35 zoom, plus frames for an animated first-seal preview.

## Verification

**1,242 checks, 0 failures:**

- New shrine/connected-spirit flow: **332**.
- World-space trail lifecycle and actual paused cinematic: **163**.
- Gate asset states, entry locks and Stage 2 health preservation: **118**.
- Wisp frame assets, core alignment, orientations and guide states: **537**.
- Seal progression, safe route, checkpoint/save migration and Stage 2 entry: **59**.
- Real combat/guard encounters, staggered attacks and cue restoration: **33**.

Test/capture runs use isolated save files. No player's save is overwritten.
Rendering contains the existing Camera2D interpolation warning; no script or
runtime errors. Previous scripts and affected test versions are backed up in
`.godot/local_backups/moon-seal-flow-20261012-214928/`.

### Brief size flash on range exit

Reproduced at 240 rendered frames per second with 60 physics ticks per second:
the unfixed ready-to-dormant switch grew to **290px** instead of about 110px for
several rendered frames, despite the declared scale already being correct.
This was physics interpolation using the previous source canvas's scale.

After disabling interpolation on `MoonSealVisual`, a 72-frame render regression
covering exit/reentry and all other states passes with **0 failures**, maximum
visible height **113px** including faint source effects. The complete connected
seal flow was rerun: **332 checks, 0 failures**. Source PNGs remain unchanged.
