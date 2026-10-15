# Stage 2 arena and rematch polish — 2026-10-15

The boss clearing now uses the existing Stage 1 environment kit, with a recessed ruined altar composition, broken arches/pillars, root formations, rubble and warm lanterns. Simple arch/root/lamp placeholder drawing is disabled when **Environment Art Enabled** is on. World-space region labels default off.

The altar is assembled from existing stone, arch, wall and root pieces. It is background dressing, rather than a new bespoke altar illustration or a playable platform. Uniform sprite scaling preserves source proportions. No source PNGs were edited.

## Scenery and lighting

- `scripts/stage2_environment_art.gd` reuses the existing measured sprite anchors and visual helper from Stage 1. All scenery stays behind Red and the Wolf, with no added bodies, collision or hazards.
- Stage 2's ForestEnvironment now uses selective background/platform grading, with a restrained vignette. Red, boss sprites, VFX and UI retain their artwork colours. Platform tops remain brighter than undersides.
- Existing warm pools at X=175/2490 align with finished lantern sprites. Two extra small lights accompany the approach lamps. Generic duplicate posts/gravestones are suppressed when either stage's environment kit is enabled.
- All original arena floor/boundary/ledge collision settings and positions remain intact, including drop-through ledges and both actor rescue paths.

## Combat readability and HUD

`scripts/boss_attack_cues.gd` is a visual-only child of the Stage 2 boss:

| Existing state | Cue |
| --- | --- |
| Slash startup, before its existing damage window | Small amber arc toward Red |
| Pounce windup | Short amber arrow in the locked travel direction |
| Howl startup, before the release frame | Amber ground bracket marking the existing 235px horizontal range |
| Recovery | Small pale-blue arc near the paws |

Cues read existing state, animation and timer values. They do not change attack selection, timing, hitboxes, health, damage or cooldowns. They hide during pause, death, scene transitions and the ending. **Attack Cues Enabled** is exposed on Stage2BossLayout; **Cues Enabled** and **Cue Opacity** are available on the generated AttackCues node during play.

The combat HUD hides the permanent full controls list and generic forest status line. Red's health and ability cooldowns remain, and **CURSED WOLF** appears above the boss health bar. Stage 1 retains its contextual lessons and exploration status.

## Sparse petals

`scripts/stage2_petals.gd` reuses the Stage 1 world-space petal system with a separate arena configuration:

- 10 pooled sprites total: 6 background, 4 midground, zero foreground.
- Entrance ambient target: 6, with irregular canopy shedding and occasional small gusts.
- During the fight: ambient target 3 and a hard cap of 5 active petals; combat additions use the background pool. Full gusts are suppressed during combat.
- Petals hide during paused cinematics, death, scene transitions and the ending.

The final rendered check observed 3 active petals in battle. Density is deliberately lower than Stage 1 so the boss's animation and warning effects remain readable.

## Faster retries

After the intro is watched or deliberately skipped:

1. Existing journey objectives record `boss_intro_seen` for Stage 2.
2. A Stage 2 retry anchor is saved near the clearing at X=1500/Y=485 for the default layout.
3. Retry/Continue on that journey bypasses the already acknowledged story, plays the short complete opening howl, and uses the same camera/HUD/input/combat handoff as the full sequence.
4. The existing one-second opening grace lets Red act before the boss resumes.

Retry rebuilds the boss at full health and restores Red's health through the existing retry system. Stage 1 seal/reward progress is preserved. First visits still play the full intro; New Game clears the acknowledgement with the rest of the journey. No new Stage 1 checkpoint activation behaviour was added.

## Review controls

- **Stage2BossLayout:** Environment Art Enabled, Platform Art Enabled, Attack Cues Enabled, Region Labels Visible.
- **ForestEnvironment:** background, moon/castle, platform top/underside and scenery brightness, plus vignette strength.
- **CrimsonPetals:** Enabled, pool sizes, opacity, wind, ambient targets and the active battle cap are editable in the Stage 2 scene Inspector, independently of Stage 1.
- **BossIntroCutscene:** existing Opening Breathing Window and Battle Spacing controls also apply to rematches.

## Verification

- Rendered Stage 2 integration after the howl/Skip update: **86 checks, 0 failures**, including all 11 floor/boundary/ledge configurations unchanged, decorative-only props, uniform scaling, HUD visibility, cue state/direction, petal pool/cap, cinematic hiding, actor rescue, one normal 20-damage hit, saved retry anchor, howl on Skip, and a real scene reload into a rematch with its own entry howl.
- Full rendered ending: all seven revised Guardian lines, original reveal and all three subsequent panels retained; Prototype Complete and Return to Title reached correctly.
- Rendered Stage 1 route regression: **93 checks, 0 failures**.
- Full first-time intro plus Skip at 14 phases after the howl update: **324 checks, 0 failures**. See [boss howl after Skip](boss_skip_howl.md).

Results: [Stage 2 JSON](previews/stage2_polish/test_result.json). Latest howl integration logs: `.godot/boss_skip_howl_arena.log`, `.godot/boss_skip_howl_intro.log`, `.godot/boss_skip_howl_ending.log`. Earlier polish logs: `.godot/stage2_polish_test.log`, `.godot/stage2_polish_intro.log`, `.godot/stage2_polish_ending.log`, `.godot/stage2_polish_stage1.log`. Tests use isolated presentation saves.

These checks verify integration and existing combat behaviour; subjective difficulty and visual feel still benefit from playing a normal fight.

## Previews

- [Arena before](previews/stage2_polish/arena_before.png) / [arena after](previews/stage2_polish/arena_after.png)
- [Entrance before](previews/stage2_polish/entrance_before.png) / [entrance after](previews/stage2_polish/entrance_after.png)
- [Sparse battle petals](previews/stage2_polish/arena_petals.png)
- [Slash cue](previews/stage2_polish/cue_slash.png)
- [Pounce cue](previews/stage2_polish/cue_pounce_windup.png)
- [Howl cue](previews/stage2_polish/cue_howl_aoe.png)
- [Recovery cue](previews/stage2_polish/cue_recovery.png)

Before images are the previous staged arena previews, rather than synchronized before/after gameplay recordings.

## Backup

Previous scripts/scenes, intro capture/test fixture and arena notes:
`.godot/local_backups/stage2-polish-20261015-123933/`
