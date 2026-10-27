# Teach students to build a game with AI, starting from an empty folder

## 1. Course purpose

- Build a small 2D action platformer inspired by The Silent Keep: Moonlit Oath.
- Start with no game project, source code or supplied game artwork.
- Students use Codex in their editor, Godot for running/editing the game, and an image/animation tool for their own assets.
- Start with a short playable game. Add the current project's advanced systems as separate extension lessons.
- Teach students to describe behavior, judge the result, change a value, and report a bug with evidence.
- Students create their own characters and setting. The course recreates the game's systems and development process; generated artwork will vary between students.

This guide assumes **Visual Studio Code with Codex**. Visual Studio is a different editor; confirm the classroom setup before preparing screenshots. Choose and record one Godot 4 version for the class and use matching export templates.

**Teacher boundary:** students create a NEW folder/project. These prompts are not instructions to rebuild the teacher's existing Silent Keep project.

## 2. Coaching rhythm

Use one lesson card at a time:

1. **Predict:** student explains what should change.
2. **Prompt:** student sends only the current task to Codex.
3. **Inspect:** student reads the changed-file summary and locates the relevant scene/script.
4. **Play:** student performs the checks below the prompt.
5. **Customize:** student changes one requirement or Inspector value and observes the result.
6. **Explain:** student answers the coaching question in their own words.
7. **Save:** student records the result and creates a local backup or Git commit.

Do not advance because Codex says "done." Advance when the student can demonstrate the outcome. A lesson can span more than one class; the cards are task boundaries, not time estimates.

OpenAI's milestone guidance uses small, reviewable steps and explicit completion criteria. The lesson structure here adapts that approach for teaching: [official Codex milestone guidance](https://developers.openai.com/blog/run-long-horizon-tasks-with-codex).

## 3. Progress tracking

For **every lesson**, track these separately:

- [ ] **Built:** Codex implemented the requested feature.
- [ ] **Checked:** student demonstrated every acceptance check.
- [ ] **Explained:** student answered the coaching question and made one small customization.
- [ ] **Saved:** student recorded evidence and created a named recovery point.

Suggested record, maintained in the student's `docs/student_progress.md`:

| Lesson | Built | Student checked | Explained | Saved | Evidence / issue |
| --- | --- | --- | --- | --- | --- |
| 01 Project | [ ] | [ ] | [ ] | [ ] | |
| 02 Movement | [ ] | [ ] | [ ] | [ ] | |
| 03 Jump + camera | [ ] | [ ] | [ ] | [ ] | |
| 04 Small level | [ ] | [ ] | [ ] | [ ] | |
| 05 Attack | [ ] | [ ] | [ ] | [ ] | |
| 06 Enemy | [ ] | [ ] | [ ] | [ ] | |
| 07 Health + retry | [ ] | [ ] | [ ] | [ ] | |
| 08 Boss | [ ] | [ ] | [ ] | [ ] | |
| 09 Hero design | [ ] | [ ] | [ ] | [ ] | |
| 10 Hero animation frames | [ ] | [ ] | [ ] | [ ] | |
| 11 Hero import | [ ] | [ ] | [ ] | [ ] | |
| 12 Enemy artwork | [ ] | [ ] | [ ] | [ ] | |
| 13 Boss artwork | [ ] | [ ] | [ ] | [ ] | |
| 14 Background | [ ] | [ ] | [ ] | [ ] | |
| 15 Platform artwork | [ ] | [ ] | [ ] | [ ] | |
| 16 Sound | [ ] | [ ] | [ ] | [ ] | |
| 17 Menu + completion | [ ] | [ ] | [ ] | [ ] | |
| 18 Export + friend playtest | [ ] | [ ] | [ ] | [ ] | |

Codex may mark **Built** after implementing the feature. It should record which checks it actually ran and leave the student's demonstration and explanation boxes for the student/teacher. Screenshots, observed behavior and a saved version are useful evidence; a file existing alone is insufficient.

## 4. Send this coaching prompt once

Paste into Codex in the student's NEW project folder:

```text
- Help me learn to make a small Godot 4 action platformer.
- I am starting from an empty folder and creating my own artwork.
- Work only on the lesson I send you; stop after that lesson.
- Keep implementation small and readable. Inspect existing files before changing them.
- Before implementation, briefly explain the intended result and the files involved.
- Use placeholders until I supply my own assets.
- Expose useful tuning values in the Inspector.
- Explain any editor steps I must perform myself.
- After implementation, list changed files, checks you actually ran, and checks I must perform.
- Do not claim a visual or gameplay check passed if you could not run it.
- Maintain docs/student_progress.md with separate Built, Student checked, Explained and Saved columns.
- Leave my demonstration/explanation boxes unchecked until I report the outcome.
- Finish with one question that helps me understand this lesson.
```

The teacher demonstrates how to read a diff and how to restore a backup before Lesson 02. Keep Git commits local until the student explicitly chooses to publish.

## Phase A — A playable game using placeholders

### Lesson 01 — Create the empty Godot project

**Learn:** project, scene, node, script, main scene.

**Student action:** install the chosen Godot version, open the empty course folder in the editor, and confirm Codex can access it. If the editor cannot launch Godot, locate the Godot executable together with the teacher.

**Codex prompt:**

```text
- Inspect this new folder and confirm whether it is empty.
- Create a minimal Godot 4 project using the Compatibility renderer and GDScript.
- Use a 960 x 540 reference viewport and a main scene called Game.tscn.
- Add a plain floor and a visible colored player placeholder above it.
- Add collision so the player falls onto the floor and rests there.
- Create folders for scenes, scripts, assets and docs.
- Create the lesson progress record described in the coaching prompt.
- Explain how to open the project in Godot and run the main scene.
```

**Acceptance checks:**

- [ ] Project opens in Godot without script errors.
- [ ] Running the main scene shows the player and floor.
- [ ] Player lands on the floor instead of falling through it.

**Student task:** change the placeholder's color. **Explain:** what does collision do that artwork does not?

### Lesson 02 — Move left and right

**Learn:** input actions, velocity, facing direction.

**Codex prompt:**

```text
- Add A/D and Left/Right movement using Input Map actions.
- Export a movement_speed value in the Inspector.
- Stop horizontal movement when I release the direction button.
- Track which direction the player faces.
- Keep the existing floor collision working.
```

**Acceptance checks:**

- [ ] Both key pairs work and releasing them stops movement.
- [ ] Changing movement_speed visibly changes speed.
- [ ] Player stays on the floor while moving.

**Student task:** compare two speed values and choose one. **Explain:** how is position different from velocity?

### Lesson 03 — Jump and camera

**Learn:** grounded checks, gravity, camera following.

**Codex prompt:**

```text
- Add Space to jump while grounded, using an exported jump strength.
- Keep gravity active while airborne.
- Add a Camera2D that follows the player with mild smoothing.
- Prevent repeated Space presses from creating unlimited jumps.
- Explain how gravity and jump strength affect the jump.
```

**Acceptance checks:**

- [ ] One press makes one jump and the player lands reliably.
- [ ] Repeated presses in midair do not create extra jumps.
- [ ] Camera follows without losing the player.

**Student task:** choose between a floaty jump and a quicker jump. **Explain:** why check whether the player is grounded?

### Lesson 04 — Build one short route

**Learn:** useful platform placement, safe retries, readable routes.

**Codex prompt:**

```text
- Expand this into a short test level with three broad platforms and an exit marker.
- Make every required jump possible using the current normal jump.
- Keep the route uncluttered and show a clear starting point and destination.
- Add a fall boundary that returns the player to the start and resets velocity.
- Reaching the exit should show a simple completion message.
```

**Acceptance checks:**

- [ ] Student can reach the exit without changing physics values.
- [ ] Falling always returns the player safely.
- [ ] There are no invisible required platforms or unreachable gaps.

**Student task:** move one platform and explain whether the route improves. **Explain:** what purpose does each platform serve?

### Lesson 05 — One basic attack

**Learn:** attack startup, active time, recovery, hitbox versus body collision.

**Codex prompt:**

```text
- Add C to perform one melee attack facing the current direction.
- Use a visible placeholder swing and a temporary hitbox during active time.
- Add a practice target with health and a visible hit response.
- Damage each target at most once per swing.
- Lock normal horizontal steering during the attack and restore it afterward.
- Export damage, reach and attack timing for tuning.
```

**Acceptance checks:**

- [ ] Attack hits the facing side, only while close enough.
- [ ] Holding overlap does not repeatedly damage the target in one swing.
- [ ] Player can move again after the attack finishes.

**Student task:** adjust reach while keeping damage unchanged. **Explain:** why should a sword hitbox exist for only part of an attack?

### Lesson 06 — One ordinary enemy

**Learn:** simple states and readable attack openings.

**Codex prompt:**

```text
- Replace the practice target with one placeholder enemy.
- Give it idle, approach, attack-warning, attack, recovery and defeated states.
- Keep it within a small encounter area and stop it walking off ledges.
- Let the player's melee attack damage and defeat it.
- Show the enemy attack warning clearly before its active hitbox.
- Enemy attacks should emit a damage event; player health comes next lesson.
```

**Acceptance checks:**

- [ ] Enemy approaches, warns, attacks and recovers in the expected order.
- [ ] Defeated enemy stops attacking.
- [ ] Student can see an opening to counterattack.

**Student task:** lengthen the warning and compare difficulty. **Explain:** why does the enemy need recovery time?

### Lesson 07 — Player health, death and retry

**Learn:** health, temporary invulnerability, reset state, basic HUD.

**Codex prompt:**

```text
- Add player health and a simple HP bar.
- Connect enemy attacks to player damage.
- Prevent one overlapping attack from draining health every frame.
- Add a brief readable hurt response and temporary invulnerability after damage.
- At zero HP, stop gameplay input and show a Retry button.
- Retry restores health, position, velocity, enemies and control cleanly.
```

**Acceptance checks:**

- [ ] Health changes by the expected amount per hit.
- [ ] Zero HP produces a clear death/retry state.
- [ ] Retrying several times does not duplicate enemies or leave input locked.

**Student task:** tune enemy damage so a beginner can survive several mistakes. **Explain:** which values must reset when retrying?

### Lesson 08 — A small boss stage

**Learn:** scene transitions, boss states, bounded arenas.

**Codex prompt:**

```text
- Make the level exit lead to a separate small boss arena.
- Add one larger placeholder boss with health and two attacks: a close swipe and a warned pounce.
- Stagger its attacks and give each one a readable recovery.
- Keep player and boss inside the arena with reliable floor/boundary collision.
- Show boss HP only in the boss stage.
- Defeating the boss shows a simple victory message.
```

**Acceptance checks:**

- [ ] Exit loads the boss stage correctly.
- [ ] Both attacks can be recognized and avoided.
- [ ] Neither actor falls outside the arena during the fight.
- [ ] Boss can be defeated and victory appears once.

**Student task:** tune one boss timing without increasing player damage. **Explain:** what makes a harder enemy fair?

**Milestone A:** a complete small playable game exists before polished art. Save a named recovery point.

## Phase B — Students generate and import their own art

### Asset workflow and GIF expectation

- A **GIF is a useful animation preview** for the teacher and classmates.
- For Godot, use **transparent PNG frames or a PNG sprite sheet** with `AnimatedSprite2D` / `SpriteFrames`.
- Godot documents these two frame workflows: [2D sprite animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html).
- Students request both the review preview and the usable source frames when their chosen tool supports those exports.
- An image-generation tool may produce inconsistent frames or may not export a true animated GIF. If so, use the still design as a reference in an animation tool, or start with a small set of manually corrected poses.
- Verify the files actually contain distinct, consistent frames. Renaming one PNG to `.gif` does not create animation.
- Do one character and one animation at a time. A full hero/enemy/boss/background pack in one request is difficult to review.
- Keep all frames of one character on the same canvas with the same ground line and scale. A foot pivot is a reference point, not necessarily the image center.
- Save original generations outside the runtime asset folder; put approved assets in the game.

### Lesson 09 — Design the hero as one still image

**Learn:** a usable asset brief and art direction.

**Student preparation:** choose a name, silhouette, two main colors and one memorable accessory. Sketch the character or collect a reference the student may use.

**Prompt to ChatGPT/image tool, not the coding lesson:**

```text
- Design one original hero for my side-view 2D action platformer.
- Theme: [student's chosen setting].
- Hero: [appearance, clothing, accessory and weapon].
- Use a clear silhouette and a limited palette, readable at about 64 px tall in gameplay.
- Show one full-body idle pose, facing right, in true side view.
- Use a transparent PNG background, with the entire character and weapon inside the canvas.
- No scenery, text, labels, UI or contact sheet.
- This approved design will be the reference for later animation frames.
```

**Acceptance checks:**

- [ ] Background has actual transparency and the weapon is not clipped.
- [ ] Character remains recognizable when displayed small.
- [ ] Student has chosen and explained the palette/accessory.

**Student task:** request one targeted revision. **Explain:** which part of the brief made the result usable in a game?

### Lesson 10 — Generate and review hero animation frames

**Learn:** loops, frame count, consistent alignment.

Use the approved hero image as the reference. Repeat this prompt for **one animation at a time**:

```text
- Animate the attached approved hero design without changing the outfit, proportions or weapon.
- Produce [animation name] in [frame count] distinct frames, facing right.
- Use equal 128 x 128 transparent PNG canvases.
- Keep a fixed character scale and shared alignment; for grounded animations keep the feet on the same ground line.
- Keep the whole weapon and all motion inside the canvas with safety padding.
- Export separate numbered PNG frames, or one clearly specified regular-grid sprite sheet.
- If supported, also provide an animated GIF preview for review.
- No text, labels, background or camera motion.
```

Starter set, generated in separate requests:

- [ ] `idle`: 4 frames, gentle loop.
- [ ] `walk`: 6 frames, readable loop without sliding feet.
- [ ] `jump`: 1–2 poses; keep alignment stable but allow the body to rise.
- [ ] `fall`: 1–2 poses.
- [ ] `attack`: 6 frames, clear anticipation → strike → recovery; weapon fits the canvas.
- [ ] `hurt`: 2–3 frames.
- [ ] `death`: 4–6 frames, one-shot.

Example names: `hero_walk_00.png` through `hero_walk_05.png`.

**Acceptance checks:**

- [ ] Canvas dimensions, proportions and accessory stay consistent across frames.
- [ ] Idle/walk loop without a large size or pivot jump.
- [ ] Attack has an identifiable strike moment.

**Student task:** annotate which attack frames should deal damage. **Explain:** why do we inspect the loop before integrating it?

### Lesson 11 — Import the hero without changing physics

**Learn:** visuals are replaceable; collision and gameplay scale are separate.

**Codex prompt:**

```text
- Inspect my approved hero files in [folder path] and list available animations.
- Replace the hero placeholder with AnimatedSprite2D/SpriteFrames using those files.
- Keep existing movement and collision dimensions unchanged.
- Normalize visual size and foot alignment in Godot; preserve the source PNGs.
- Select idle, walk, jump, fall, attack, hurt and death from gameplay state.
- Start an animation when its state changes, not every frame.
- Align attack damage time with the visible strike frames and keep it tunable.
- If a required asset is missing or inconsistent, identify it and use a labeled fallback.
```

**Acceptance checks:**

- [ ] Player size/ground contact remain stable when animations change.
- [ ] Left/right facing works and the attack still lands on the correct side.
- [ ] Hurt/death finish correctly and Retry still works.

**Student task:** compare two walk animation speeds. **Explain:** why should artwork size not automatically resize collision?

### Lesson 12 — Customize the ordinary enemy

**Learn:** reuse an asset workflow while preserving behavior.

**Image-tool prompt:**

```text
- Design one original [enemy type] matching my attached hero's side-view art style.
- Make its silhouette distinct from the hero and readable at gameplay size.
- First deliver one transparent idle PNG for approval.
- After approval, create idle, walk, attack, hurt and death frames in separate requests.
- Keep each animation on equal-sized canvases with consistent scale and foot alignment.
- Provide numbered PNG frames/sprite sheets and GIF previews where supported.
```

**Then send to Codex:**

```text
- Inspect my enemy frames in [path].
- Replace the enemy visuals while preserving its AI, hitboxes and health values.
- Synchronize warning, attack and recovery with the artwork.
- Keep missing frames as explicit placeholders and report any asset problems.
```

**Acceptance checks:**

- [ ] Enemy still warns before damage and can be hit with the hero's melee attack.
- [ ] Visual changes do not make the enemy float, grow between states or alter behavior.
- [ ] Death ends its attacks.

**Student task:** adjust one visual timing and compare it to the active hitbox. **Explain:** what makes an attack readable?

### Lesson 13 — Customize the boss separately

**Image-tool prompt:**

```text
- Design one boss: [student's original concept]. Match the attached hero/enemy style.
- Make it larger than the ordinary enemy while preserving a clear silhouette.
- First produce one transparent idle pose for approval.
- Then create idle, movement, swipe, pounce windup, pounce, hurt and death frame sets separately.
- Keep a shared canvas, ground line and scale; include room for the largest attack pose.
- Keep the attack direction consistent. Provide PNG frames plus GIF previews if supported.
```

**Then send to Codex:**

```text
- Inspect and integrate my boss artwork from [path].
- Preserve the existing arena, boss AI, health and attack rules.
- Tune visual scale/pivot and animation timing in Godot.
- Align each attack hitbox window with the visible action.
- Keep collision readable relative to the visible body.
```

**Acceptance checks:**

- [ ] Boss can still be approached and hit with normal attacks.
- [ ] Swipe and pounce warnings are visible; transitions do not change apparent body size.
- [ ] Boss remains inside the arena and death leads to victory.

**Student task:** compare silhouette and attack readability at actual game size. **Explain:** why is a boss not simply a scaled-up ordinary enemy?

### Lesson 14 — One simple background

**Learn:** foreground/background separation and composition.

**Image-tool prompt:**

```text
- Create a 1920 x 1080 background for a side-view 2D platformer.
- Setting: [student's setting]; match the attached character palette.
- Use subdued distant shapes and leave quiet space behind the gameplay area.
- Include one clear distant landmark.
- No characters, enemies, text, UI or platforms intended to be walked on.
- Export a clean PNG. This first background does not need to tile.
```

**Then send to Codex:**

```text
- Add my background from [path] behind the existing level.
- Preserve aspect ratio and expose its scale and brightness in the Inspector.
- Keep the hero and walkable platform edges clearer than the background.
- Do not change collision or move platforms to match painted background shapes.
```

**Acceptance checks:**

- [ ] Background covers the intended camera area without stretching.
- [ ] Player, enemies and platform edges are easy to distinguish.
- [ ] No painted background object appears to promise a usable route.

**Student task:** compare two brightness values. **Explain:** where should the player's eye go first?

### Lesson 15 — Replace platform placeholders

**Learn:** modular art, contact alignment and visual restraint.

**Image-tool prompt:**

```text
- Create one reusable side-view platform piece matching my attached art.
- Use a 512 x 128 transparent PNG with a clear, flat walkable top.
- Keep decoration under the top shallow and restrained.
- No character, scenery background, text or particles.
- First deliver one piece for approval; variants can follow afterward.
```

**Then send to Codex:**

```text
- Apply my approved platform art to one test platform first.
- Align its visible top to the existing collision surface.
- Keep source art unchanged and avoid independent X/Y stretching.
- Show it at gameplay scale before applying it to the remaining platforms.
- Keep the existing simple route; do not add platforms just to display more artwork.
```

**Acceptance checks:**

- [ ] Feet rest on the visible top without floating or sinking.
- [ ] Edges are readable and decoration does not hide another landing.
- [ ] Original jumps and fall reset still work after the rollout.

**Student task:** remove one unnecessary decorative detail. **Explain:** when does more detail make navigation worse?

**Milestone B:** students demonstrate a visually customized playable game with their own assets, plus their animation previews and original asset prompts.

## Phase C — Finish and share the small game

### Lesson 16 — Add a small sound set

**Learn:** feedback, volume balance and one-shot timing.

**Student preparation:** generate or record a jump sound, swing, enemy hit, boss attack and one short music loop. Record the source/tool and any usage terms. Ask for each sound separately.

**Codex prompt:**

```text
- Inspect my sound files in [path].
- Connect jump, attack, hit and boss attack sounds to their gameplay events.
- Play each one-shot once per event rather than once per frame.
- Add looping music and separate music/SFX volume controls.
- Keep a clear volume balance and use quieter audio during menu/ending screens.
```

**Acceptance checks:**

- [ ] Swing/impact sounds occur at the corresponding visible action.
- [ ] Repeated attacks do not create runaway overlapping audio.
- [ ] Music and SFX sliders work independently.

**Student task:** lower music until attack warnings are easy to hear. **Explain:** which event should trigger each sound?

### Lesson 17 — Title menu and completion screen

**Learn:** a complete start → play → finish loop.

**Codex prompt:**

```text
- Add a title menu with Start Game and Quit.
- Make Start Game begin a fresh run with reset health and enemies.
- Replace the temporary victory message with a simple completion screen.
- Add Return to Title and restore menu input correctly.
- Use Godot text and real buttons; artwork remains replaceable.
- Add a small controls reminder suitable for a first-time player.
```

**Acceptance checks:**

- [ ] Student can start, finish, return to title and start again.
- [ ] New runs do not inherit the previous boss's dead state.
- [ ] Buttons work with mouse and keyboard.

**Student task:** write one sentence introducing their own game's premise. **Explain:** what should a fresh run reset?

### Lesson 18 — Export and get feedback

**Learn:** editor versus playable build; evidence from a new player.

**Codex prompt:**

```text
- Help me prepare a Windows x86_64 release export for the Godot version installed here.
- Identify missing export templates or required editor steps.
- Keep generated builds outside the project source folder.
- Exclude documentation previews and development-only resources from the release.
- Check dynamically loaded assets before excluding anything that might be needed.
- Produce a short README with controls and launch instructions.
- Explain how to package the complete exported folder into one ZIP.
- Report build size and anything you could not verify.
```

**Acceptance checks:**

- [ ] Exported application starts outside Godot.
- [ ] A fresh playthrough can reach the boss and completion screen.
- [ ] Another student extracts the ZIP and runs it on a compatible PC.
- [ ] Student records one confusing moment and makes one focused improvement.

**Student task:** ask the player where they first felt confused; do not explain the solution during the attempt. **Explain:** how does a new player's experience differ from the developer's?

**Milestone C:** a finished small game, independently playable by someone else.

## Phase D — Extension cards toward The Silent Keep's full systems

Teach these after Milestone C. Send **one bullet prompt at a time**, using the same Built → Checked → Explained → Saved record. Generate new artwork only after a mechanic works with placeholders.

### D01 — Double jump

**Codex prompt:**

- Add one extra jump while airborne; expose the jump count and reset it only on valid landing.

**Check:** [ ] two jumps work; [ ] a third fails; [ ] landing restores them. **Explain:** when should jumps reset?

### D02 — Dash with limits

**Codex prompt:**

- Add L to dash with a cooldown, at most one air dash before landing, and a readable HUD status. Keep its movement, invulnerability and cooldown durations separately tunable.

**Check:** [ ] dash cannot be spammed; [ ] air dash refills correctly; [ ] input returns afterward. **Explain:** what stops dash replacing ordinary travel?

### D03 — Ground combo

**Codex prompt:**

- Extend melee to three attacks with buffered follow-ups. Lock horizontal steering during swings, permit the intended dash cancel, and return to idle promptly when no follow-up is queued.

**Check:** [ ] one/two/three-hit sequences work; [ ] no permanent lock; [ ] dash cancel clears stale hitboxes. **Explain:** how is input buffering different from unlimited button spam?

### D04 — Crescent projectile

**Codex prompt:**

- Add R to launch one facing-direction crescent projectile with a visible cooldown. Remove it on expiry/appropriate collision and prevent repeated damage to the same target from one projectile.

**Check:** [ ] cooldown prevents spam; [ ] projectile lifetime ends; [ ] boss remains beatable with melee. **Explain:** what tradeoff makes this ability a choice?

### D05 — Rising Slash and aerial combo

**Codex prompt:**

- Add Up+C as a launcher, then allow three airborne attacks while ascending. Lock free horizontal steering during aerial swings, tune temporary hang time, and restore gravity/control cleanly afterward.

**Check:** [ ] launcher chains upward; [ ] no map-crossing air drift; [ ] player eventually lands. **Explain:** which motion belongs to the attack and which belongs to player steering?

### D06 — Downward Slash

**Codex prompt:**

- Add Down+C while airborne as a standalone dive and as a finisher after any aerial combo step, including step three. Ground/platform contact must end the dive, play recovery, clear hitboxes and restore control. Expose dive speed, recovery and timeout.

**Check:** [ ] standalone dive works; [ ] all three combo steps can transition; [ ] landing never clips through the floor or stays stuck. **Explain:** how does a move exit safely if its expected landing never happens?

### D07 — Reusable E interaction and checkpoint

**Codex prompt:**

- Build an interaction selector that chooses the nearest eligible object. Add an E-activated lantern checkpoint with a nearby prompt, one-time healing and clear feedback. Walking into it must not activate it; retry uses the saved checkpoint.

**Check:** [ ] walking does nothing; [ ] E activates once; [ ] retry restores the right location; [ ] one E press does not activate two objects. **Explain:** why separate interaction selection from checkpoint behavior?

### D08 — One Moon Seal first

**Codex prompt:**

- Add one optional-path Moon Seal using E interaction and explicit dormant/activating/active states. Prevent repeated activation, show objective progress, and leave the existing route completable with ordinary movement/jumps.

**Check:** [ ] activation finishes once; [ ] leaving range cannot change its size or reset progress; [ ] main route stays accessible. **Explain:** why store objective state separately from its animation?

### D09 — Three seals and a locked gate

**Codex prompt:**

- Propose a small hub layout before moving terrain: easy upper discovery seal, guarded lower cellar seal, then upper traversal/combat seal. After approval, build one section at a time. Show gate states for 0/1/2/3 seals and allow boss entry only at 3/3. Keep a quiet route after the final seal.

**Check:** [ ] each objective has a distinct purpose; [ ] gate blocks early entry; [ ] all three unlock it; [ ] no advanced combo is mandatory. **Explain:** how does the layout teach exploration without adding redundant platforms?

### D10 — Moon Wisp guidance

**Codex prompt:**

- Add a guide with separate idle, move and arrival animations. Use a full first-seal camera tour, then a slower brief directional hint after seal two. Moving trails remain at their spawn positions and fade independently after about 0.5 seconds. Restore camera and control on completion/skip.

**Check:** [ ] animation states differ; [ ] trails linger in world space; [ ] both travel directions look correct; [ ] every exit restores gameplay. **Explain:** why should a trail not remain parented to the moving guide?

### D11 — Selective lighting

**Codex prompt:**

- Expose separate background, platform and scenery brightness values. Keep hero, VFX, lanterns and UI readable. Add restrained lantern light and compare one section before applying the treatment elsewhere.

**Check:** [ ] landing edges remain readable; [ ] hero remains clear; [ ] darkening does not affect UI. **Explain:** which elements should have the strongest contrast?

### D12 — Petals and visual restraint

**Codex prompt:**

- Add pooled, sparse drifting petals with irregular spawning, mostly behind gameplay. Reduce them during combat and keep foreground petals away from the central fighting area. Show a normal-travel and combat preview before increasing density.

**Check:** [ ] no regular particle wall; [ ] attack warnings remain visible; [ ] effects have a capped population. **Explain:** when does atmosphere become visual noise?

### D13 — One reusable cinematic controller

**Codex prompt:**

- Build a short two-panel placeholder cinematic with replaceable texture slots, separately rendered dialogue, fades, subtle zoom, Continue and Skip. Lock gameplay only while active and centralize safe cleanup for watched and skipped paths.

**Check:** [ ] both exits restore camera/control; [ ] dialogue is not baked into images; [ ] Skip cannot leave a frozen game. **Explain:** what must cleanup restore?

### D14 — Opening story

**Codex prompt:**

- Use the cinematic controller for a short opening before Stage 1, followed by an in-engine arrival shot and HUD reveal. Use placeholder panels first; produce an asset list and approve pacing before importing final illustrations.

**Check:** [ ] Start follows the intended order; [ ] Skip reaches playable Stage 1; [ ] HUD and controls return. **Explain:** which story beats need pictures and which can reuse gameplay?

### D15 — Boss introduction and howl

**Codex prompt:**

- Add an arena intro combining in-engine shots and replaceable illustrated reaction/memory panels. Keep the boss inactive and HUD hidden until ready. Watched, skipped and retry paths must all play one protected entry howl before enabling combat; no intro hitbox may deal damage.

**Check:** [ ] normal/Skip/retry reach the same fight state; [ ] howl plays once; [ ] repeated Skip cannot bypass the howl. **Explain:** what is shared between all three entry paths?

### D16 — Hybrid ending

**Codex prompt:**

- On boss defeat, reuse the death animation and hero walk/idle for the approach. Use placeholder illustrated panels for recognition, memory, farewell, spiritual Guardian reveal and a final wide shot. Keep dialogue separate, support Continue/Skip, then show a completion screen with Return to Title. Present the story order for approval first.

**Check:** [ ] death triggers it once; [ ] artwork/dialogue order makes sense; [ ] Skip clears all VFX/UI/input locks; [ ] title can start a fresh game. **Explain:** what image should be visible during each important line?

### D17 — Compact HUD artwork

**Codex prompt:**

- Inspect my separate health-frame, crest and ability-icon PNGs. Integrate them into a compact HUD with Godot-rendered fills, numbers and cooldowns. Preserve source art and aspect ratios, set texture minimum-size policy before sizing, and capture the result at actual gameplay resolution.

**Check:** [ ] high-resolution assets stay within their HUD bounds; [ ] cooldowns are readable; [ ] cinematics hide the entire HUD. **Explain:** why can a large source texture accidentally enlarge a UI control?

## 5. Reusable student bug-report prompt

Teach students to replace "it is broken" with this:

```text
- Lesson/feature: [name].
- Expected: [observable result].
- Actual: [observable result].
- Steps: [start state, inputs, timing].
- Evidence: [screenshot/video and exact error text, if any].
- Last working version: [backup/commit name].
- Inspect the cause and make the smallest relevant fix.
- Tell me how to reproduce the problem and verify the fix.
- Keep unrelated systems unchanged.
```

## 6. Teacher assessment

At each milestone, ask the student to:

- Demonstrate the game without Codex narrating it.
- Locate the scene and tuning value responsible for one behavior.
- Make one intentional change and predict its effect.
- Explain one generated asset's technical requirements.
- Identify one bug using steps and evidence.
- Restore a known working version.

A student who can do these is learning to direct, inspect and improve AI-assisted work. Prompt history alone is not evidence of understanding.

## 7. Recommended teaching order

- Teach Phase A first, using placeholders throughout.
- Teach Phase B as small asset workshops: hero → ordinary enemy → boss → background → platforms.
- Finish Phase C so every student has a shareable game.
- Choose Phase D cards according to class experience and time. Complete all cards for a closer match to the current project's feature set.
- Introduce saving/backups early and use them throughout; do not wait until export day.
- Keep a classroom example project at each milestone, but let students solve their own smaller changes before handing them a complete implementation.

This document is a teaching plan and prompt pack. It has not been executed from an empty folder as a validated classroom run. Before teaching, rehearse one fresh-project build with the chosen Godot/editor versions, adjust unclear prompts, and retain milestone snapshots.
